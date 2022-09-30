#!/bin/bash

# purpose of this script is to set the permissions for selected folders

GROUP="_group_"
BASE_FOLDER="_base_folder_"
SUBFOLDERS=downloads,tv,movies


echo "$(date "+%d.%m.%Y %T") INFO: ${0} started."


for subFolder in ${SUBFOLDERS//,/ }
do
    chgrp -R ${GROUP} ${BASE_FOLDER}/${subFolder}
    chmod g+s ${BASE_FOLDER}/${subFolder}
    setfacl -d -R -m g::rwx ${BASE_FOLDER}/${subFolder}
done


echo "$(date "+%d.%m.%Y %T") INFO: ${0} complete."
