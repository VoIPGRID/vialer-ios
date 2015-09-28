#!/bin/bash

# Checks if the config_site.h is located in the correct directory and otherwise
# create a symbolic link to it. 

if [ -e "${PROJECT_DIR}/pjsip/src/pjlib/include/pj/config_site.h" ]
then
    echo "${PROJECT_DIR}/pjsip/src/pjlib/include/pj/config_site.h file exists"
else
    echo "No config_site.h in ${PROJECT_DIR}/pjsip/src/pjlib/include/pj/ sym linking...."
    ln -s "${PROJECT_DIR}/pjsip/config_site.h" "${PROJECT_DIR}/pjsip/src/pjlib/include/pj/"
fi
