###############################################################################
# locals.tf - parsiranje CSV-a i izvedene vrijednosti (Azure)
#
# Isti CSV (ime;prezime;rola) kao za OpenStack -> jedinstveni izvor istine.
# Skripta prima putanju do .csv i kreira infrastrukturu za varijabilan broj
# korisnika u jednom "terraform apply" pozivu.
###############################################################################

locals {
  csv_raw    = file(var.users_csv)
  csv_lines  = [for l in split("\n", replace(local.csv_raw, "\r", "")) : trimspace(l) if trimspace(l) != ""]
  data_lines = slice(local.csv_lines, 1, length(local.csv_lines))

  users = [
    for line in local.data_lines : {
      ime      = trimspace(split(";", line)[0])
      prezime  = trimspace(split(";", line)[1])
      rola     = lower(trimspace(split(";", line)[2]))
      username = lower(format("%s.%s", trimspace(split(";", line)[0]), trimspace(split(";", line)[1])))
    }
  ]

  developers = { for u in local.users : u.username => u if u.rola == "developer" }
  leads      = { for u in local.users : u.username => u if u.rola == "devops_lead" }

  # Indeks programera -> deterministicki adresni prostor VNeta (10.<10+idx>.0.0/16).
  dev_names  = sort(keys(local.developers))
  dev_index  = { for i, name in local.dev_names : name => i }
  vnet_cidr  = { for name, idx in local.dev_index : name => format("10.%d.0.0/16", 10 + idx) }
  snet_cidr  = { for name, idx in local.dev_index : name => format("10.%d.1.0/24", 10 + idx) }

  # Hub (shared) adresni prostor za Bastion i DevOps Lead.
  hub_cidr          = "10.0.0.0/16"
  hub_bastion_cidr  = "10.0.0.0/27" # AzureBastionSubnet (obvezan naziv/velicina)
  hub_mgmt_cidr     = "10.0.1.0/24"

  # Mapa Moodle cvorova (2 po programeru).
  moodle_nodes = merge([
    for name, idx in local.dev_index : {
      "${name}-01" = { dev = name, node = "01" }
      "${name}-02" = { dev = name, node = "02" }
    }
  ]...)

  # Storage account naziv: globalno jedinstven, <=24 znaka, samo mala slova/brojke.
  sa_name = {
    for name, idx in local.dev_index :
    name => substr(lower(replace("stts${replace(name, ".", "")}", "-", "")), 0, 18)
  }

  ssh_public_key = file(pathexpand(var.ssh_public_key_path))
}
