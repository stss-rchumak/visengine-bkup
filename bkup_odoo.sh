#!/bin/bash

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )""/"

# Source the configuration file
source "${SCRIPTPATH}bkup_odoo_conf.inc.sh"

# vars
BKUP_DATE=$(date +"%Y-%m-%d_%H-%M-%S")
BKUP_DIR="${SCRIPTPATH}${BKUP_DATE}/"
BKUP_FILE="${ODOO_DB}.${BKUP_DATE}.zip"
LOG_FILE="/var/log/backups/${ODOO_DB}_${BKUP_DATE}.log"
S3_PATH="/${BKUP_FILE}"

# create a backup directory
mkdir -p ${BKUP_DIR}

# create log directory if not exists
mkdir -p /var/log/backups/

echo "Backup directory created at: ${BKUP_DIR}" | tee -a ${LOG_FILE}

# Create dump.sql with custom name
PGPASSWORD=$ODOO_DB_PASSWORD pg_dump -h $ODOO_DB_HOST -U $ODOO_DB_USER -p $ODOO_DB_PORT $ODOO_DB --no-owner > ${BKUP_DIR}dump.sql
DUMP_EXIT_CODE=$?

if [ $DUMP_EXIT_CODE -eq 0 ]; then
    echo "Database dump successful" | tee -a ${LOG_FILE}

    # 1) Copy your generate_manifest.py into the container
    docker cp generate_manifest.py "${ODOO_CONTAINER}:${TMP_SCRIPT_PATH}"
    if [ $? -ne 0 ]; then
        echo "Failed copying generate_manifest.py to container" | tee -a "${LOG_FILE}"
        exit 1
    fi

    # 2) Run the script in the container and capture the manifest locally
    docker exec -i "${ODOO_CONTAINER}" bash -c \
      "cat ${TMP_SCRIPT_PATH} | odoo shell -d ${ODOO_DB} --no-http" > "${BKUP_DIR}/manifest.json"

    MANIFEST_EXIT_CODE=$?

    if [ $MANIFEST_EXIT_CODE -ne 0 ]; then
        echo "Error generating manifest.json (docker/odoo shell exit code: $MANIFEST_EXIT_CODE)" | tee -a "${LOG_FILE}"
        exit 1
    fi

    echo "Manifest successfully created at ${BKUP_DIR}/manifest.json" | tee -a "${LOG_FILE}"

    mkdir -p "${BKUP_DIR}/filestore"

    # Copy all files & subfolders from PATH_TO_FILESTORE/db_name/* => BKUP_DIR/filestore/
    cp -a "${PATH_TO_FILESTORE}/${ODOO_DB}/." "${BKUP_DIR}/filestore/"

    # Create a zip archive with dump.sql and filestore
    7z a -tzip "${SCRIPTPATH}data/${BKUP_FILE}" \
        "${BKUP_DIR}/dump.sql" \
        "${BKUP_DIR}/manifest.json" \
        "${BKUP_DIR}/filestore" 2>&1 | tee -a "${LOG_FILE}"

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
