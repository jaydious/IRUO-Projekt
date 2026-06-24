###############################################################################
# locals.tf - parsiranje CSV-a i izvedene vrijednosti / konvencija imenovanja
#
# CSV format (separator ";"):
#   ime;prezime;rola
#   ana;anic;devops_lead
#   luka;lukic;developer
#
# Terraform-ov ugradeni csvdecode() podrzava samo zarez kao separator, pa
# CSV s ";" parsiramo rucno (split po retku, pa po ";"). Time skripta prima
# putanju do .csv i automatski kreira infrastrukturu za varijabilan broj
# korisnika - pokrece se jednom (terraform apply), bez visestrukih skripti.
###############################################################################

locals {
  # 1) Ucitavanje datoteke i ciscenje praznih redova / CR znakova (Windows).
  csv_raw   = file(var.users_csv)
  csv_lines = [for l in split("\n", replace(local.csv_raw, "\r", "")) : trimspace(l) if trimspace(l) != ""]

  # 2) Prvi red je zaglavlje -> preskace se.
  data_lines = slice(local.csv_lines, 1, length(local.csv_lines))

  # 3) Mapiranje svakog reda u strukturirani objekt.
  users = [
    for line in local.data_lines : {
      ime      = trimspace(split(";", line)[0])
      prezime  = trimspace(split(";", line)[1])
      rola     = lower(trimspace(split(";", line)[2]))
      username = lower(format("%s.%s", trimspace(split(";", line)[0]), trimspace(split(";", line)[1])))
    }
  ]

  # 4) Razdvajanje po rolama u mape kljucane usernameom (stabilni for_each kljucevi).
  developers = { for u in local.users : u.username => u if u.rola == "developer" }
  leads      = { for u in local.users : u.username => u if u.rola == "devops_lead" }

  # 5) Indeks programera -> deterministicki /24 segment (10.10.<idx+1>.0/24).
  dev_names   = sort(keys(local.developers))
  dev_index   = { for i, name in local.dev_names : name => i + 1 }
  dev_cidrs   = { for name, idx in local.dev_index : name => format("10.10.%d.0/24", idx) }
  dev_gateway = { for name, idx in local.dev_index : name => format("10.10.%d.1", idx) }

  # Fiksne adrese unutar svake dev podmreze (least-privilege SSH izvori).
  bastion_ip_in_dev = { for name, idx in local.dev_index : name => format("10.10.%d.10", idx) }
  lead_ip_in_dev    = { for name, idx in local.dev_index : name => format("10.10.%d.11", idx) }
  moodle_ips = {
    for name, idx in local.dev_index : name => {
      node1 = format("10.10.%d.21", idx)
      node2 = format("10.10.%d.22", idx)
      vip   = format("10.10.%d.100", idx)
    }
  }

  # Hub (management) mreza za jump host i DevOps Lead VM.
  hub_cidr    = "10.0.0.0/24"
  hub_gateway = "10.0.0.1"

  # Naziv prema konvenciji: <prefix>-<tip>-<programer>[-<index>]
  ssh_public_key = file(pathexpand(var.ssh_public_key_path))
}
