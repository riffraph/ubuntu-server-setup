#!/bin/bash

# purpose of this script is to set the permissions for selected folders

GROUP="_group_"
DOWNLOADS_DIR="_downloads_"
TV_DIR="_tv_"
MOVIES_DIR="_movies_"

chgrp -R ${GROUP} ${DOWNLOADS_DIR}
chgrp -R ${GROUP} ${TV_DIR}
chgrp -R ${GROUP} ${MOVIES_DIR}
