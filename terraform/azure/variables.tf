###############################################################################
# variables.tf - ulazne varijable za Azure okolinu
###############################################################################

variable "subscription_id" {
  description = "ID Azure pretplate u koju se deploya okolina."
  type        = string
  default     = "00000000-0000-0000-0000-000000000000"
}

variable "location" {
  description = "Azure regija (npr. westeurope) - koristi se za procjenu troskova."
  type        = string
  default     = "westeurope"
}

variable "users_csv" {
  description = "Putanja do CSV datoteke s korisnicima (ime;prezime;rola)."
  type        = string
  default     = "../../scripts/users.csv"
}

variable "aad_domain" {
  description = "Verificirana Entra ID (Azure AD) domena za UPN korisnika."
  type        = string
  default     = "techsprintexample.onmicrosoft.com"
}

variable "vm_size" {
  description = "Velicina aplikacijske VM (2 vCPU / 4 GB). B2s je troskovno najpovoljniji izbor."
  type        = string
  default     = "Standard_B2s"
}

variable "infra_vm_size" {
  description = "Velicina DevOps Lead VM-a."
  type        = string
  default     = "Standard_B1ms"
}

variable "data_disk_size_gb" {
  description = "Velicina Managed data diska po instanci."
  type        = number
  default     = 32
}

variable "os_disk_size_gb" {
  description = "Velicina OS Managed diska."
  type        = number
  default     = 32
}

variable "admin_username" {
  description = "Administratorski korisnik na Linux VM-ovima."
  type        = string
  default     = "azureadmin"
}

variable "ssh_public_key_path" {
  description = "Putanja do javnog SSH kljuca za pristup VM-ovima."
  type        = string
  default     = "~/.ssh/techsprint_id_rsa.pub"
}

variable "create_management_group" {
  description = "Kreirati Management Group hijerarhiju (zahtijeva prava na tenant root)."
  type        = bool
  default     = false
}

# Kreiranje novih Entra ID (Azure AD) korisnika i grupa zahtijeva administratorske
# ovlasti nad imenikom. U institucijskom tenantu (npr. studentski racun) toga nema,
# pa se postavlja na false: tada se preskace kreiranje AAD korisnika/grupa i njihove
# dodjele rola, a custom rola se demonstrira dodjelom prijavljenom korisniku.
# Puni dizajn (korisnici iz CSV-a) ostaje u kodu i koristi se uz tenant-admin ovlasti.
variable "enable_aad_users" {
  description = "Kreirati Entra ID korisnike/grupe iz CSV-a (true) ili preskociti (false)."
  type        = bool
  default     = true
}

# Azure Bastion je spor (~10 min create/destroy) i najskuplji dio. Za brze/jeftine
# testne deploymente moze se iskljuciti; u dizajnu je zadano ukljucen (jedini javni ulaz).
variable "enable_bastion" {
  description = "Kreirati Azure Bastion (jedini javni ulaz). false za brze/jeftine testove."
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Tagovi koji se primjenjuju na sve resurse."
  type        = map(string)
  default = {
    project     = "techsprint"
    environment = "testing"
  }
}

variable "name_prefix" {
  description = "Prefiks za konvenciju imenovanja (CAF stil)."
  type        = string
  default     = "ts-tst"
}
