#!/usr/bin/env zsh

current_time=$(date +%d-%m-%y)
current_year=$(date +%Y)
current_week=$(date +%V)

#BDD a sauvegarder
BDD_to_save="my_bdd"
tables_to_save=()

##configuration des acces
#connection au server a backuper
mysql_user="root"
mysql_pass="root"
mysql_server="Your_ip_server"
mysql_port="8888"

#Connection au server ftp en ssh
ssh_user="user_ssh"
ssh_domain="ssh_domain_name"
ssh_port="8080"
#evite de demander le mot de passe
export SSHPASS='pass_ssh'

#Connection au server de stockage des Backups
ssh_depo_user="user_ssh_depot"
ssh_depot_domain="ssh_depot_domain_name"

#recuperation des BDD sur le server
if [ $mysql_pass ]
then
#Pour Installer sshpass et evite de demander le mot de passe
#brew install https://raw.githubusercontent.com/kadwanev/bigboybrew/master/Library/Formula/sshpass.rb
sshpass -p "$SSHPASS" ssh -T "$ssh_user"@"$ssh_domain" -p "$ssh_port" << EOF

mkdir "BDD_$current_year"
cd "BDD_$current_year"

#Pour chaque base cree un sql compresse
mysqldump --opt -u"$mysql_user" -p"$mysql_pass" -h"$mysql_server" -P"$mysql_port" --databases "$BDD_to_save" --tables $tables_to_save | gzip -9 > "$BDD_to_save"_"$current_time.sql.gz"

EOF

#cree arborescance des Backups
#recupere les Backups stocker sur le ftp, export des backups en local puis aussi sur le server de Stockage (et supprime les fichiers sur le FTP pour ne pas le surcharger)
cd ../
mkdir "BDD/$current_year/"
mkdir "BDD/$current_year/$current_week"
scp -P "$ssh_port" "$ssh_user"@"$ssh_domain: BDD_$current_year/*.gz" "BDD/$current_year/$current_week/"
ssh -T "$ssh_user"@"$ssh_domain" -p "$ssh_port" "rm -rf BDD_$current_year"
ssh -T "$ssh_depo_user"@"$ssh_depot_domain" "mkdir /share/Dev/Backup/databases/$current_year /share/Dev/Backup/databases/$current_year/$current_week"
scp -r BDD/$current_year/$current_week/*.gz "$ssh_depo_user"@"$ssh_depot_domain: /share/Dev/Backup/databases/$current_year/$current_week/"
fi
