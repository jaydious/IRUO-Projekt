#!/usr/bin/env bash
###############################################################################
# cleanup.sh - brise sve ts-tst resurse iz CL110 overclouda
#
# Zasto: reset workstationa gubi Terraform state, ali overcloud zadrzi vec
# deployane resurse (postaju "orphani"). Prije cistog ponovnog deploya treba ih
# ukloniti, inace 'terraform apply' javlja konflikte (ime vec postoji).
#
# Pokretanje:  source ~/admin-rc && bash lab/cl110/cleanup.sh
###############################################################################
set +e
echo "== serveri (instance + amphora) =="
for id in $(openstack server list --all-projects -f value -c ID -c Name | grep -E 'ts-tst|amphora' | awk '{print $1}'); do
  openstack server delete "$id"
done
sleep 5
echo "== floating IP =="
for id in $(openstack floating ip list -f value -c ID); do openstack floating ip delete "$id"; done
echo "== volumes (data diskovi) =="
for id in $(openstack volume list --all-projects -f value -c ID -c Name | grep ts-tst | awk '{print $1}'); do
  openstack volume delete "$id"
done
echo "== load balanceri =="
for id in $(openstack loadbalancer list -f value -c id 2>/dev/null); do openstack loadbalancer delete "$id" --cascade; done
echo "== routeri =="
for n in $(openstack router list -f value -c Name | grep ts-tst); do
  openstack router unset --external-gateway "$n" 2>/dev/null
  for p in $(openstack port list --router "$n" -f value -c ID 2>/dev/null); do
    openstack router remove port "$n" "$p" 2>/dev/null
  done
  openstack router delete "$n"
done
echo "== portovi =="
for id in $(openstack port list -f value -c ID -c Name | grep ts-tst | awk '{print $1}'); do openstack port delete "$id"; done
echo "== mreze =="
for n in $(openstack network list -f value -c Name | grep ts-tst); do openstack network delete "$n"; done
echo "== security grupe =="
for n in $(openstack security group list -f value -c Name | grep ts-tst); do openstack security group delete "$n"; done
echo "== swift kontejneri =="
for c in $(openstack container list -f value 2>/dev/null | grep ts-tst); do openstack container delete "$c" --recursive; done
echo "== manila shareovi =="
for s in $(openstack share list -f value -c Name 2>/dev/null | grep ts-tst); do openstack share delete "$s"; done
echo "== korisnici / grupe / projekti =="
for u in $(openstack user list -f value -c Name | grep -E 'luka.lukic|marko.maric|ana.anic'); do openstack user delete "$u"; done
for g in $(openstack group list -f value -c Name | grep ts-tst); do openstack group delete "$g"; done
for p in $(openstack project list -f value -c Name | grep ts-tst); do openstack project delete "$p"; done
echo ""
echo "CLEANUP DONE - preostalo: serveri=$(openstack server list --all-projects -f value -c Name 2>/dev/null | grep -c ts-tst) projekti=$(openstack project list -f value -c Name 2>/dev/null | grep -c ts-tst)"
