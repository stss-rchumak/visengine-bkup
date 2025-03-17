ODOO_DB="crm"
ODOO_DB_USER="crm"
ODOO_DB_HOST="localhost"
ODOO_DB_PASSWORD="9pS4BvGtL7cO0H!"
ODOO_DB_PORT="5432"

PATH_TO_FILESTORE="/srv/www/crm.visengine.app/htdocs/filestore/filestore"
#PATH_TO_FILESTORE="/srv/www/crm-dev.visengine.app/htdocs/filestore/filestore"

S3_BUCKET="ftp-dedibackup-dc3:./backup_crm_visengine-app"

# Retention variables
SERVER_RETENTION=5  # Number of latest backups to keep on the server
S3_RETENTION=10     # Number of latest backups to keep on AWS S3
