ODOO_CONFIG_FILE="/srv/www/crm.visengine.app/htdocs/odoo_conf/odoo.conf"

ODOO_DB_HOST="$(grep -Po '(?<=db_host\s=\s).*' "$ODOO_CONFIG_FILE")"
ODOO_DB_PORT="$(grep -Po '(?<=db_port\s=\s).*' "$ODOO_CONFIG_FILE")"
ODOO_DB_USER="$(grep -Po '(?<=db_user\s=\s).*' "$ODOO_CONFIG_FILE")"
ODOO_DB_PASSWORD="$(grep -Po '(?<=db_password\s=\s).*' "$ODOO_CONFIG_FILE")"
ODOO_DB="$(grep -Po '(?<=db_name\s=\s).*' "$ODOO_CONFIG_FILE")"
PATH_TO_FILESTORE="$(grep -Po '(?<=data_dir\s=\s).*' "$ODOO_CONFIG_FILE")"

ODOO_DB="crm"
#ODOO_DB_USER="crm"
ODOO_DB_HOST="localhost"
#ODOO_DB_PASSWORD="9pS4BvGtL7cO0H!"
#ODOO_DB_PORT="5432"
PATH_TO_FILESTORE="/srv/www/crm.visengine.app/htdocs/filestore/filestore"
#PATH_TO_FILESTORE="/srv/www/crm-dev.visengine.app/htdocs/filestore/filestore"

#echo "Host: $ODOO_DB_HOST"
#echo "Port: $ODOO_DB_PORT"
#echo "User: $ODOO_DB_USER"
#echo "Pass: $ODOO_DB_PASSWORD"
#echo "DB Name: $ODOO_DB"
#echo "Filestore: $PATH_TO_FILESTORE"

# Docker-related variables (you can also put them in bkup_odoo_conf.inc.sh if you prefer)
ODOO_CONTAINER="crm-visengine-app"
TMP_SCRIPT_PATH="/tmp/generate_manifest.py"

S3_BUCKET="ftp-dedibackup-dc3:./backup_crm_visengine-app"

# Retention variables
SERVER_RETENTION=5  # Number of latest backups to keep on the server
S3_RETENTION=10     # Number of latest backups to keep on AWS S3
