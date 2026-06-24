# Konvencija imenovanja resursa - TechSprint

Cilj: predvidljiva, strojno čitljiva i ljudski razumljiva imena koja jednoznačno
nose **organizaciju**, **okolinu**, **tip resursa** i **vlasnika (programera)**.
Konvencija je usklađena s Microsoft Cloud Adoption Framework (CAF) preporukama
za Azure i prilagođena OpenStacku.

## Opći obrazac

```
<prefiks-org>-<okolina>-<tip>-<vlasnik>[-<indeks>]
```

| Segment       | Vrijednost              | Objašnjenje                                   |
|---------------|-------------------------|-----------------------------------------------|
| prefiks-org   | `ts`                    | TechSprint                                    |
| okolina       | `tst`                   | testing (testna okolina)                      |
| tip           | npr. `vm`, `net`, `lb`  | tip resursa (kratica)                         |
| vlasnik       | `ime.prezime`           | programer; `hub` za dijeljene resurse         |
| indeks        | `01`, `02`              | redni broj kod više identičnih resursa (HA)   |

Zajednički prefiks za sve resurse: **`ts-tst`**.

## Azure (CAF kratice tipova)

| Resurs                         | Kratica  | Primjer                              |
|--------------------------------|----------|--------------------------------------|
| Resource Group                 | `rg`     | `rg-ts-tst-dev-luka.lukic`           |
| Virtual Network                | `vnet`   | `vnet-ts-tst-luka.lukic`             |
| Subnet                         | `snet`   | `snet-ts-tst-app-luka.lukic`         |
| Network Security Group         | `nsg`    | `nsg-ts-tst-app-luka.lukic`          |
| Application Security Group     | `asg`    | `asg-ts-tst-moodle-luka.lukic`       |
| Virtual Machine                | `vm`     | `vm-ts-tst-moodle-luka.lukic-01`     |
| Managed Disk                   | `disk`   | `disk-ts-tst-moodle-luka.lukic-01-data` |
| Load Balancer                  | `lb`     | `lb-ts-tst-luka.lukic`               |
| Public IP                      | `pip`    | `pip-ts-tst-bastion`                 |
| Azure Bastion                  | `bas`    | `bas-ts-tst-hub`                     |
| NAT Gateway                    | `nat`    | `nat-ts-tst-luka.lukic`              |
| User-assigned Identity         | `id`     | `id-ts-tst-moodle-luka.lukic`        |
| Storage Account*               | `st`     | `sttstlukalukic1234`                 |

\* Storage Account ime mora biti globalno jedinstveno, 3–24 znaka, isključivo
mala slova i brojke (bez crtica). Stoga se koristi sažeti oblik
`st` + okolina + vlasnik (bez točaka) + nasumični sufiks.

## OpenStack

| Resurs                   | Kratica | Primjer                          |
|--------------------------|---------|----------------------------------|
| Projekt (tenant)         | `prj`   | `ts-tst-prj-luka.lukic`          |
| Mreža                    | `net`   | `ts-tst-net-luka.lukic`          |
| Subnet                   | `subnet`| `ts-tst-subnet-luka.lukic`       |
| Router                   | `rtr`   | `ts-tst-rtr-luka.lukic`          |
| Security group           | `sg`    | `ts-tst-sg-app-luka.lukic`       |
| Port                     | `port`  | `ts-tst-port-moodle-luka.lukic-01` |
| Instanca (VM)            | `vm`    | `ts-tst-vm-moodle-luka.lukic-01` |
| Cinder volume (disk)     | `vol`   | `ts-tst-vol-data-luka.lukic-01`  |
| Load balancer (Octavia)  | `lb`    | `ts-tst-lb-luka.lukic`           |
| Swift kontejner (objekt) | `obj`   | `ts-tst-obj-luka.lukic`          |
| Manila share (datoteke)  | `file`  | `ts-tst-file-luka.lukic`         |

## Dijeljeni (hub) resursi

Resursi koje koriste svi (jump host / Bastion, DevOps Lead VM, hub mreža)
koriste vlasnika `hub`: `ts-tst-vm-jump`, `ts-tst-vm-lead`, `vnet-ts-tst-hub`.

## Obvezni tagovi

Svi resursi nose tagove:

```
project     = techsprint
environment = testing
```

Dodatno, resursi vezani uz pojedinog programera nose `owner = ime.prezime`,
a HA cvorovi `ha_node = 01|02`.
