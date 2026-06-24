# TechSprint - izolirane testne okoline za Moodle (IRUO projekt)

Autor: **Juraj Herceg** · Kolegij: *Implementacija računarstva u oblaku* ·
Sveučilište Algebra Bernays

Automatizirano (IaC) kreiranje sigurnih, međusobno izoliranih testnih okolina
za programere koji testiraju aplikaciju **Moodle**, implementirano paralelno na
**OpenStacku** i **Microsoft Azureu**. Cijela se okolina za varijabilan broj
korisnika gradi iz jedne `.csv` datoteke jednim pokretanjem skripte.

## Struktura repozitorija

```
IRUO/
├─ README.md                      # ovaj dokument
├─ NAMING_CONVENTION.md           # konvencija imenovanja resursa
├─ .gitignore
├─ scripts/
│  ├─ users.csv                   # primjer: 1 voditelj + 2 programera
│  ├─ deploy.ps1                  # jedinstvena deployment skripta (Windows)
│  └─ deploy.sh                   # jedinstvena deployment skripta (Linux)
├─ terraform/
│  ├─ openstack/                  # OpenStack IaC (Keystone, Neutron, Nova, Cinder, Octavia, Swift, Manila)
│  └─ azure/                      # Azure IaC (RG, VNet, NSG/ASG, VM, Disk, LB, Storage, Entra ID, RBAC)
├─ diagrams/                      # dijagrami arhitekture (PNG)
└─ dokumentacija/
   └─ IRUO_Projekt_Juraj_Herceg.docx
```

## Pokretanje (jedan poziv)

OpenStack:
```bash
source terraform/openstack/openrc.sh        # cloud-admin kredencijali
./scripts/deploy.sh -c scripts/users.csv -t openstack
```

Azure:
```powershell
az login
./scripts/deploy.ps1 -CsvPath scripts/users.csv -Cloud azure
```

> Napomena: u sklopu kolegija okolina se **ne deploya** (nisu dodijeljeni
> resursi - nema Red Hat Academy ni lokalnog OpenStacka). Skripte i Terraform
> kod su napisani tako da izvršavaju tražene funkcije; provjera se radi
> `terraform validate` / `terraform plan` (parametar `-p` / `-PlanOnly`).

## CSV format

```
ime;prezime;rola
ana;anic;devops_lead
luka;lukic;developer
marko;maric;developer
```

Role: `developer` (vlastita izolirana okolina, kontrola samo svojih VM-ova) i
`devops_lead` (centralni VM, pristup i upravljanje svim instancama).
