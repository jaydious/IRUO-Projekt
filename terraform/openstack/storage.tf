###############################################################################
# storage.tf - Objektna (Swift) i datotecna (Manila) pohrana po programeru
#
#  - Swift kontejner: objektna pohrana za Moodle datoteke (moodledata, media).
#  - Manila NFS share: datotecna pohrana za sigurnosne kopije (backup).
#  - Obje se automatski montiraju na Moodle instance putem cloud-inita
#    (moodle.yaml.tpl) uz least-privilege pristup (read-write samo vlastiti
#    kontejner/share, ACL ogranicen na dev podmrezu).
###############################################################################

# ---------------------------- OBJEKTNA POHRANA -----------------------------
resource "openstack_objectstorage_container_v1" "moodle" {
  for_each = local.developers

  name          = "${var.name_prefix}-obj-${each.key}"
  content_type  = "application/octet-stream"
  force_destroy = true

  metadata = {
    project     = var.common_tags["project"]
    environment = var.common_tags["environment"]
    owner       = each.key
  }
}

# Temp-URL kljuc za least-privilege pristup objektnoj pohrani (umjesto
# dijeljenja punih kredencijala). Koristi se za potpisane URL-ove.
resource "random_password" "swift_temp_url_key" {
  for_each = local.developers
  length   = 32
  special  = false
}

# ---------------------------- DATOTECNA POHRANA ----------------------------
resource "openstack_sharedfilesystem_share_v2" "backup" {
  for_each = local.developers

  name             = "${var.name_prefix}-file-${each.key}"
  description      = "Datotecna pohrana (backup) za programera ${each.key}."
  share_proto      = var.share_proto
  size             = 10
  metadata = {
    project     = var.common_tags["project"]
    environment = var.common_tags["environment"]
    owner       = each.key
  }
}

# ACL (least-privilege): NFS -> pristup po IP-u ogranicen na dev podmrezu;
# CEPHFS -> pristup preko cephx korisnika (po programeru).
resource "openstack_sharedfilesystem_share_access_v2" "backup" {
  for_each = local.developers

  share_id     = openstack_sharedfilesystem_share_v2.backup[each.key].id
  access_type  = var.share_proto == "CEPHFS" ? "cephx" : "ip"
  access_to    = var.share_proto == "CEPHFS" ? "ts-${replace(each.key, ".", "-")}" : local.dev_cidrs[each.key]
  access_level = "rw"
}
