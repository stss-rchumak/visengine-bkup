#!/bin/bash

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )""/"

# Source the configuration file
source "${SCRIPTPATH}bkup_odoo_conf.inc.sh"

# vars
BKUP_DATE=$(date +"%Y-%m-%d_%H-%M-%S")
BKUP_DIR="${SCRIPTPATH}${BKUP_DATE}/"
BKUP_FILE="${ODOO_DB}.${BKUP_DATE}.7z"
LOG_FILE="/var/log/backups/${ODOO_DB}_${BKUP_DATE}.log"
S3_PATH="/${BKUP_FILE}"

# create a backup directory
mkdir -p ${BKUP_DIR}

# create log directory if not exists
mkdir -p /var/log/backups/

echo "Backup directory created at: ${BKUP_DIR}" | tee -a ${LOG_FILE}

# Create dump.sql with custom name
PGPASSWORD=$ODOO_DB_PASSWORD pg_dump -h $ODOO_DB_HOST -U $ODOO_DB_USER -p $ODOO_DB_PORT $ODOO_DB --no-owner > ${BKUP_DIR}dump_${ODOO_DB}_${BKUP_DATE}.sql
DUMP_EXIT_CODE=$?

if [ $DUMP_EXIT_CODE -eq 0 ]; then
    echo "Database dump successful" | tee -a ${LOG_FILE}

    # Create a 7z archive with dump.sql and filestore
    7z a -mx0 -t7z ${SCRIPTPATH}data/${BKUP_FILE} ${BKUP_DIR}/dump_${ODOO_DB}_${BKUP_DATE}.sql $PATH_TO_FILESTORE/$ODOO_DB | tee -a ${LOG_FILE}
    ZIP_EXIT_CODE=$?

    if [ $ZIP_EXIT_CODE -eq 0 ]; then
        echo "Backup 7z archive created successfully as ${BKUP_FILE}" | tee -a ${LOG_FILE}

        # Check 7z archive integrity
        7z t ${SCRIPTPATH}data/${BKUP_FILE} | tee -a ${LOG_FILE}
        UNZIP_EXIT_CODE=$?

        if [ $UNZIP_EXIT_CODE -eq 0 ]; then
            echo "Backup 7z archive is valid" | tee -a ${LOG_FILE}

            # Upload to FTP bucket
            echo "Uploading backup to FTP: ${S3_BUCKET}" | tee -a ${LOG_FILE}
            rclone copy "${SCRIPTPATH}data/${BKUP_FILE}" "${S3_BUCKET}" >>"${LOG_FILE}" 2>&1
            FTP_EXIT_CODE=$?

            if [ $FTP_EXIT_CODE -eq 0 ]; then
                echo "Backup successfully uploaded to FTP" | tee -a ${LOG_FILE}
            else
                echo "Failed to upload backup to FTP" | tee -a ${LOG_FILE}
            fi
        else
            echo "Backup 7z archive is corrupted" | tee -a ${LOG_FILE}
        fi
    else
        echo "Failed to create 7z archive" | tee -a ${LOG_FILE}
    fi
else
    echo "Database dump failed" | tee -a ${LOG_FILE}
fi

# Clean up the created backup directory
rm -rf ${BKUP_DIR} | tee -a ${LOG_FILE}
