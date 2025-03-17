#!/bin/bash

# Set variables
ODOO_CONTAINER="crm-visengine-app"
ODOO_DB="crm"
LOCAL_OUTPUT_FILE="./manifest.json"
TMP_SCRIPT_PATH="/tmp/generate_manifest.py"

# Copy the Python script to the container
docker cp generate_manifest.py "$ODOO_CONTAINER":"$TMP_SCRIPT_PATH"

# Run the script inside the container and capture output
docker exec -i "$ODOO_CONTAINER" bash -c "cat $TMP_SCRIPT_PATH | odoo shell -d $ODOO_DB --no-http" > "$LOCAL_OUTPUT_FILE"

# Verify success
if [ $? -eq 0 ]; then
    echo "Manifest saved to $LOCAL_OUTPUT_FILE"
else
    echo "Error generating manifest" >&2
    exit 1
fi
