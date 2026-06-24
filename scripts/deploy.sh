#!/usr/bin/env bash
###############################################################################
# deploy.sh - TechSprint jedinstvena deployment skripta (Bash / Linux)
#
# Prima putanju do .csv (ime;prezime;rola) i u JEDNOM pokretanju kreira
# kompletnu izoliranu okolinu za varijabilan broj korisnika na odabranom
# oblaku. Terraform for_each nad CSV-om obavlja cijeli posao - skripta se
# pokrece jednom.
#
# Uporaba:
#   ./deploy.sh -c ../scripts/users.csv -t azure          # apply na Azure
#   ./deploy.sh -c ../scripts/users.csv -t openstack -p   # samo plan
#   ./deploy.sh -c ../scripts/users.csv -t both           # oba oblaka
###############################################################################
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLOUD="both"
PLAN_ONLY=0
CSV=""

usage() { grep '^#' "$0" | sed 's/^#//'; exit 1; }

while getopts ":c:t:ph" opt; do
  case "$opt" in
    c) CSV="$OPTARG" ;;
    t) CLOUD="$OPTARG" ;;
    p) PLAN_ONLY=1 ;;
    h) usage ;;
    *) usage ;;
  esac
done

[ -n "$CSV" ] || { echo "GRESKA: putanja do CSV-a je obavezna (-c)"; usage; }

# ---------------------------- validacija CSV-a -----------------------------
validate_csv() {
  local path="$1"
  [ -f "$path" ] || { echo "GRESKA: CSV nije pronaden: $path"; exit 1; }

  local header
  header="$(head -n1 "$path" | tr -d '\r')"
  [ "$header" = "ime;prezime;rola" ] || {
    echo "GRESKA: neispravno zaglavlje '$header' (ocekivano 'ime;prezime;rola')"; exit 1; }

  local devs=0 leads=0
  while IFS= read -r line; do
    line="$(echo "$line" | tr -d '\r')"
    [ -z "$line" ] && continue
    IFS=';' read -r ime prezime rola <<< "$line"
    [ -n "${ime:-}" ] && [ -n "${prezime:-}" ] && [ -n "${rola:-}" ] || {
      echo "GRESKA: neispravan redak: '$line'"; exit 1; }
    case "$(echo "$rola" | tr '[:upper:]' '[:lower:]')" in
      developer)   devs=$((devs+1)) ;;
      devops_lead) leads=$((leads+1)) ;;
      *) echo "GRESKA: nepoznata rola '$rola' u retku '$line'"; exit 1 ;;
    esac
  done < <(tail -n +2 "$path")

  echo "[OK] CSV validan: $devs programer(a), $leads voditelj(a)."
}

# ------------------------------ terraform ----------------------------------
run_tf() {
  local dir="$1" csv="$2"
  echo "==> terraform init ($dir)"
  terraform -chdir="$dir" init -input=false

  if [ "$PLAN_ONLY" -eq 1 ]; then
    echo "==> terraform plan ($dir)"
    terraform -chdir="$dir" plan -input=false -var "users_csv=$csv"
  else
    echo "==> terraform apply ($dir)"
    terraform -chdir="$dir" apply -input=false -auto-approve -var "users_csv=$csv"
  fi
}

CSV_ABS="$(cd "$(dirname "$CSV")" && pwd)/$(basename "$CSV")"
validate_csv "$CSV_ABS"

if [ "$CLOUD" = "openstack" ] || [ "$CLOUD" = "both" ]; then
  run_tf "$ROOT/terraform/openstack" "$CSV_ABS"
fi
if [ "$CLOUD" = "azure" ] || [ "$CLOUD" = "both" ]; then
  run_tf "$ROOT/terraform/azure" "$CSV_ABS"
fi

echo ""
echo "[GOTOVO] Okolina kreirana iz '$CSV_ABS' (cloud: $CLOUD)."
