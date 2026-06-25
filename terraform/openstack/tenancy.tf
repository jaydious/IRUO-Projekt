###############################################################################
# tenancy.tf - izvedeni tenant_id ovisno o var.use_tenant_isolation
#
# Vidi opis varijable use_tenant_isolation u variables.tf. Kada je false,
# tenant_id postaje null (resurs se kreira u projektu autenticiranog korisnika).
###############################################################################

locals {
  hub_tenant_id = var.use_tenant_isolation ? openstack_identity_project_v3.hub.id : null
  dev_tenant_id = {
    for k, p in openstack_identity_project_v3.dev : k => (var.use_tenant_isolation ? p.id : null)
  }
}
