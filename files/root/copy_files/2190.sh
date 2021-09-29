#!/bin/bash

# Get inverse users:
INVERSE_USERS=$(getent group jupyterhub_users_soee2190 | \
                awk -F ':' '{print $NF}' | \
                tr ',' '\n' | \
                egrep -v '^(chmcsy|earhbu|earmgr|eartdj)$')

# Source directory:
SOURCE_DIR='/storage/earth_data/soee2190/TimeSeriesPracticals'

# Loop through users:
for INVERSE_USER in ${INVERSE_USERS}
do
  # Create TimeSeriesPracticals directory, if it does not exist:
  if [ ! -e "/home/${INVERSE_USER}/TimeSeriesPracticals" ] ; then
    mkdir -p /home/${INVERSE_USER}/TimeSeriesPracticals
    chown ${INVERSE_USER}:${INVERSE_USER} /home/${INVERSE_USER}/TimeSeriesPracticals
  fi
  # Copy TimeSeriesPracticals files which do not exist:
  rsync -a --ignore-existing \
    ${SOURCE_DIR}/ /home/${INVERSE_USER}/TimeSeriesPracticals/
  chown -R ${INVERSE_USER}:${INVERSE_USER} /home/${INVERSE_USER}/TimeSeriesPracticals
done
