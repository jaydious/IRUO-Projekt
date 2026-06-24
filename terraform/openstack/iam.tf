###############################################################################
# iam.tf - Keystone identiteti: projekti (tenanti), korisnici, grupe, role
#
# Model:
#  - Svaki programer dobiva VLASTITI projekt (tenant) -> potpuna izolacija
#    resursa i kvota (zahtjev: "Kreirani odvojeni projekti/tenanti za izolaciju").
#  - Programer dobiva ulogu "member" ISKLJUCIVO na svom projektu -> moze
#    paliti/gasiti/restartati samo svoje VM-ove (project-scoped Nova akcije).
#  - DevOps Lead dobiva ulogu "member" na SVIM projektima programera + na hub
#    projektu -> upravlja stanjem svih instanci, ali nije cloud-admin
#    (least-privilege: nema prava nad tudim domenama/kvotama).
###############################################################################

# --- Hub (management) projekt za infrastrukturne VM-ove (jump host + lead) ---
resource "openstack_identity_project_v3" "hub" {
  name        = "${var.name_prefix}-prj-hub"
  description = "TechSprint management/hub projekt (jump host + DevOps Lead)."
  tags        = [for k, v in var.common_tags : "${k}=${v}"]
}

# --- Projekt po programeru ---
resource "openstack_identity_project_v3" "dev" {
  for_each = local.developers

  name        = "${var.name_prefix}-prj-${each.value.username}"
  description = "Izolirani projekt za programera ${each.value.ime} ${each.value.prezime}."
  tags        = [for k, v in var.common_tags : "${k}=${v}"]
}

# --- Grupe (IAM struktura) ---
resource "openstack_identity_group_v3" "developers" {
  name        = "${var.name_prefix}-grp-developers"
  description = "Grupa svih programera (developer rola)."
}

resource "openstack_identity_group_v3" "devops_leads" {
  name        = "${var.name_prefix}-grp-devops-leads"
  description = "Grupa voditelja tima (devops_lead rola)."
}

# --- Korisnici programera ---
resource "openstack_identity_user_v3" "dev" {
  for_each = local.developers

  name               = each.value.username
  description        = "Programer ${each.value.ime} ${each.value.prezime}."
  default_project_id = openstack_identity_project_v3.dev[each.key].id
  password           = random_password.user[each.key].result
  # Korisnik je clan grupe programera.
  ignore_change_password_upon_first_use = true
}

# --- Korisnici voditelja ---
resource "openstack_identity_user_v3" "lead" {
  for_each = local.leads

  name               = each.value.username
  description        = "DevOps Lead ${each.value.ime} ${each.value.prezime}."
  default_project_id = openstack_identity_project_v3.hub.id
  password           = random_password.lead[each.key].result
  ignore_change_password_upon_first_use = true
}

# --- Pocetne lozinke (u praksi se isporucuju kroz tajni kanal / vault) ---
resource "random_password" "user" {
  for_each = local.developers
  length   = 20
  special  = true
}

resource "random_password" "lead" {
  for_each = local.leads
  length   = 20
  special  = true
}

# --- Dohvat ugradene role "member" ---
data "openstack_identity_role_v3" "member" {
  name = "member"
}

# --- Programer: member na VLASTITOM projektu (i nigdje drugdje) ---
resource "openstack_identity_role_assignment_v3" "dev_on_own_project" {
  for_each = local.developers

  user_id    = openstack_identity_user_v3.dev[each.key].id
  project_id = openstack_identity_project_v3.dev[each.key].id
  role_id    = data.openstack_identity_role_v3.member.id
}

# --- Voditelj: member na SVAKOM projektu programera ---
resource "openstack_identity_role_assignment_v3" "lead_on_dev_projects" {
  # Kartezijev produkt: svaki lead x svaki dev projekt.
  for_each = {
    for pair in setproduct(keys(local.leads), keys(local.developers)) :
    "${pair[0]}__${pair[1]}" => { lead = pair[0], dev = pair[1] }
  }

  user_id    = openstack_identity_user_v3.lead[each.value.lead].id
  project_id = openstack_identity_project_v3.dev[each.value.dev].id
  role_id    = data.openstack_identity_role_v3.member.id
}

# --- Voditelj: member na hub projektu (jump host + lead VM) ---
resource "openstack_identity_role_assignment_v3" "lead_on_hub" {
  for_each = local.leads

  user_id    = openstack_identity_user_v3.lead[each.key].id
  project_id = openstack_identity_project_v3.hub.id
  role_id    = data.openstack_identity_role_v3.member.id
}

# --- Role na razini grupa (struktura IAM-a, dokumentacija pristupa) ---
resource "openstack_identity_role_assignment_v3" "grp_dev_member" {
  for_each = local.developers

  group_id   = openstack_identity_group_v3.developers.id
  project_id = openstack_identity_project_v3.dev[each.key].id
  role_id    = data.openstack_identity_role_v3.member.id
}

resource "openstack_identity_role_assignment_v3" "grp_lead_member_hub" {
  group_id   = openstack_identity_group_v3.devops_leads.id
  project_id = openstack_identity_project_v3.hub.id
  role_id    = data.openstack_identity_role_v3.member.id
}
