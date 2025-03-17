#!/usr/bin/env python3
import odoo
import shutil
import tempfile
import json
import os
import logging
from odoo import sql_db
from odoo.service.db import dump_db_manifest

_logger = logging.getLogger(__name__)

def generate_manifest():
    # Get database name from Odoo config
    db_name = odoo.tools.config['db_name']

    # Create a temporary directory
    with tempfile.TemporaryDirectory() as dump_dir:
        # Generate and save the manifest file
        manifest_path = os.path.join(dump_dir, 'manifest.json')
        with open(manifest_path, 'w') as fh:
            db = sql_db.db_connect(db_name)
            with db.cursor() as cr:
                json.dump(dump_db_manifest(cr), fh, indent=4)

        # Read and print the file content so Bash can capture it
        with open(manifest_path, 'r') as fh:
            print(fh.read())  # This will send the JSON content to stdout

if __name__ == "__main__":
    generate_manifest()
