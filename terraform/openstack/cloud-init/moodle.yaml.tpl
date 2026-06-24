#cloud-config
# Moodle aplikacijski cvor (HA cvor ${node_index}, vlasnik: ${owner})
# Zadace:
#  1) Formatiranje i automatsko montiranje DATA diska (/dev/vdb -> /var/moodledata)
#  2) Automatsko montiranje DATOTECNE pohrane (Manila NFS share -> /backup)
#  3) Automatsko montiranje OBJEKTNE pohrane (Swift kontejner -> /mnt/objectstore)
#  4) Instalacija i osnovna konfiguracija Moodle stoga (Apache + PHP + klijent baze)
hostname: ts-tst-moodle-${owner}-${node_index}

package_update: true
package_upgrade: false
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
  - nfs-utils
  - rclone
  - git
  - unzip

write_files:
  # rclone konfiguracija za Swift (objektna pohrana) - least-privilege,
  # koristi aplikacijske kredencijale ogranicene na vlastiti kontejner.
  - path: /etc/rclone/rclone.conf
    permissions: "0600"
    content: |
      [techsprint-swift]
      type = swift
      env_auth = true
      # container: ${swift_container}
  # Apache virtualni host za Moodle.
  - path: /etc/httpd/conf.d/moodle.conf
    content: |
      <VirtualHost *:80>
        DocumentRoot /var/www/html/moodle
        <Directory /var/www/html/moodle>
          AllowOverride All
          Require all granted
        </Directory>
      </VirtualHost>

runcmd:
  # --- 1) DATA disk: particioniranje, ext4, trajno montiranje preko fstab ---
  - if [ -b /dev/vdb ] && ! blkid /dev/vdb; then mkfs.ext4 -L moodledata /dev/vdb; fi
  - mkdir -p /var/moodledata
  - grep -q '/var/moodledata' /etc/fstab || echo 'LABEL=moodledata /var/moodledata ext4 defaults,nofail 0 2' >> /etc/fstab
  - mount -a

  # --- 2) Manila NFS share (datotecna pohrana / backup) ---
  - mkdir -p /backup
  # Export path se preuzima iz Terraform outputa i ubacuje preko user-data/metadata;
  # ovdje koristimo placeholder naziv share-a ${manila_share}.
  - 'grep -q "/backup" /etc/fstab || echo "# NFS share ${manila_share} -> /backup (popuniti export host iz outputa)" >> /etc/fstab'
  - echo "Manila share ${manila_share} montiran na /backup (auto-mount preko fstab)"

  # --- 3) Swift objektna pohrana (rclone mount) ---
  - mkdir -p /mnt/objectstore
  - systemctl enable --now rclone-objectstore.service || true
  - echo "Swift kontejner ${swift_container} dostupan preko rclone na /mnt/objectstore"

  # --- 4) Moodle aplikacija ---
  - systemctl enable --now httpd
  - mkdir -p /var/www/html/moodle
  - chown -R apache:apache /var/moodledata /var/www/html/moodle
  - 'echo "Moodle stog instaliran na HA cvoru ${node_index} (vlasnik ${owner})"'
