#!/bin/bash

# Get inverse users:
INVERSE_USERS=$(getent group jupyterhub_users_inverse | \
                awk -F ':' '{print $NF}' | \
                tr ',' '\n' | \
                egrep -v '^(chmcsy|earhbu|earmgr|eartdj)$')

# Practicals source directory:
PRACTICALS_DIR='/storage/earth_data/inverse/Practicals'

# Loop through users:
for INVERSE_USER in ${INVERSE_USERS}
do
  # Copy Example_scripts, if it does not exist:
  if [ ! -e "/home/${INVERSE_USER}/Example_scripts" ] ; then
    cp -r \
      /storage/earth_data/inverse/Example_scripts \
      /home/${INVERSE_USER}/
    chown -R ${INVERSE_USER}:${INVERSE_USER} \
      /home/${INVERSE_USER}/Example_scripts
  fi
  # Create Practicals directory, if it does not exist:
  if [ ! -e "/home/${INVERSE_USER}/Practicals" ] ; then
    mkdir -p /home/${INVERSE_USER}/Practicals
    chown ${INVERSE_USER}:${INVERSE_USER} /home/${INVERSE_USER}/Practicals
  fi
  # Copy Practicals files which do not exist:
  for PRACTICALS_FILE in $(find ${PRACTICALS_DIR} -maxdepth 1 -mindepth 1 -type f -name '*.ipynb' | \
                           awk -F '/' '{print $NF}')
  do
    if [ ! -e "/home/${INVERSE_USER}/Practicals/${PRACTICALS_FILE}" ] ; then
      cp ${PRACTICALS_DIR}/${PRACTICALS_FILE} \
        /home/${INVERSE_USER}/Practicals/
      chown ${INVERSE_USER}:${INVERSE_USER} /home/${INVERSE_USER}/Practicals/${PRACTICALS_FILE}
    fi
  done
done
