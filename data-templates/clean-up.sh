#!/bin/bash

# forked from https://github.com/BinsonBuzz/unraid_rclone_mount.git

# Clean up locks and other control files

SCRIPT_FOLDER=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo "$(date "+%d.%m.%Y %T") INFO: ${0} started."


echo "$(date "+%d.%m.%Y %T") INFO: Removing locks and control files."

rm ${SCRIPT_FOLDER}/*.lock


echo "$(date "+%d.%m.%Y %T") INFO: ${0} complete."

exit
