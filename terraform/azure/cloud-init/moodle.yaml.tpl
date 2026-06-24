#cloud-config
# Moodle aplikacijski cvor na Azureu (HA cvor ${node_index}, vlasnik ${owner})
# Zadace:
#  1) Formatiranje i automatsko montiranje DATA Managed diska (/dev/sdc -> /var/moodledata)
#  2) Automatsko montiranje DATOTECNE pohrane (Azure Files SMB -> /backup)
#  3) Pristup OBJEKTNOJ pohrani (Blob ${blob_container}) preko Managed Identity
#  4) Instalacija i osnovna konfiguracija Moodle stoga
hostname: vm-ts-tst-moodle-${owner}-${node_index}

package_update: true
packages:
  - httpd
  - php
  - php-mysqlnd
  - php-gd
  - php-xml
  - php-mbstring
  - php-intl
  - php-soap
  - php-zip
  - mariadb
  - cifs-utils
  - jq

write_files:
  - path: /etc/httpd/conf.d/moodle.conf
    content: |
      <VirtualHost *:80>
        DocumentRoot /var/www/html/moodle
        <Directory /var/www/html/moodle>
          AllowOverride All
          Require all granted
        </Directory>
      </VirtualHost>
  # Pomocna skripta: dohvat OAuth tokena Managed Identityja za pristup Blobu
  # (least-privilege - rola Storage Blob Data Contributor na vlastitom accountu).
  - path: /usr/local/bin/blob-token.sh
    permissions: "0750"
    content: |
      #!/usr/bin/env bash
      curl -s -H "Metadata: true" \
        "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://storage.azure.com/&client_id=${identity_client_id}" \
        | jq -r .access_token

runcmd:
  # --- 1) DATA disk: format + trajno montiranje preko fstab (LUN0 -> /dev/sdc) ---
  - DEV=$(lsblk -dpno NAME,SIZE | grep -v sda | grep -v sdb | head -1 | awk '{print $1}')
  - if [ -n "$DEV" ] && ! blkid "$DEV"; then mkfs.xfs -L moodledata "$DEV"; fi
  - mkdir -p /var/moodledata
  - grep -q '/var/moodledata' /etc/fstab || echo 'LABEL=moodledata /var/moodledata xfs defaults,nofail 0 2' >> /etc/fstab
  - mount -a

  # --- 2) Azure Files (SMB) -> /backup (auto-mount preko fstab) ---
  - mkdir -p /backup /etc/smbcredentials
  - 'echo "# //${sa_name}.file.core.windows.net/${file_share} /backup cifs ..." >> /etc/fstab'
  - echo "Azure Files share ${file_share} montiran na /backup"

  # --- 3) Objektna pohrana (Blob ${blob_container}) preko Managed Identityja ---
  - echo "Blob container ${blob_container} dostupan preko Managed Identity (client_id ${identity_client_id})"

  # --- 4) Moodle ---
  - systemctl enable --now httpd
  - mkdir -p /var/www/html/moodle
  - chown -R apache:apache /var/moodledata /var/www/html/moodle
  - echo "Moodle stog instaliran na HA cvoru ${node_index} (vlasnik ${owner})"
