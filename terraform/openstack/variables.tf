###############################################################################
# variables.tf - ulazne varijable za OpenStack okolinu
###############################################################################

variable "region" {
  description = "OpenStack regija (RegionOne na vecini deploymenta)."
  type        = string
  default     = "RegionOne"
}

variable "users_csv" {
  description = "Putanja do CSV datoteke s korisnicima (ime;prezime;rola)."
  type        = string
  default     = "../../scripts/users.csv"
}

variable "external_network_name" {
  description = "Naziv vanjske (provider) mreze za floating IP i SNAT izlaz na Internet."
  type        = string
  default     = "public"
}

variable "dns_servers" {
  description = "DNS posluzitelji koji se dodjeljuju subnetima programera."
  type        = list(string)
  default     = ["1.1.1.1", "8.8.8.8"]
}

variable "image_name" {
  description = "Naziv Glance imagea (cloud distribucija). Koristi se Rocky Linux 9 GenericCloud."
  type        = string
  default     = "Rocky-9-GenericCloud"
}

variable "flavor_app" {
  description = "Flavor za aplikacijske (Moodle) instance - mora biti 2 vCPU / 4 GB RAM."
  type        = string
  default     = "m1.medium"
}

variable "flavor_infra" {
  description = "Flavor za jump host i DevOps Lead VM (manji, 1 vCPU / 2 GB)."
  type        = string
  default     = "m1.small"
}

variable "os_disk_size_gb" {
  description = "Velicina OS diska (boot volume) u GB."
  type        = number
  default     = 20
}

variable "data_disk_size_gb" {
  description = "Velicina data diska (Cinder volume) u GB."
  type        = number
  default     = 20
}

variable "ssh_public_key_path" {
  description = "Putanja do javnog SSH kljuca koji se ubacuje u sve instance."
  type        = string
  default     = "~/.ssh/techsprint_id_rsa.pub"
}

variable "admin_cidr" {
  description = "CIDR s kojeg je dozvoljen SSH na jump host (radi sigurnosti ogranicen). 0.0.0.0/0 samo za demo."
  type        = string
  default     = "0.0.0.0/0"
}

# Obvezni tagovi prema zahtjevu projekta.
variable "common_tags" {
  description = "Tagovi koji se primjenjuju na sve resurse."
  type        = map(string)
  default = {
    project     = "techsprint"
    environment = "testing"
  }
}

variable "name_prefix" {
  description = "Prefiks za konvenciju imenovanja resursa (organizacija + okolina)."
  type        = string
  default     = "ts-tst"
}
