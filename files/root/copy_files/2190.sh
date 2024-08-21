#!/bin/bash

# Source directories:
SOURCE_DIRS='/storage/earth_data/soee2190/TimeSeriesPracticals'

# Get course users:
COURSE_GROUP='jh_users_soee2190'
COURSE_USERS=$(getent group ${COURSE_GROUP} | \
                 awk -F ':' '{print $NF}' | \
                 tr ',' '\n' | \
                 egrep -v '^(earhbu|earjacr|earmgr|lmkk419|snnn998)$')

# Loop through source directories:
for SOURCE_DIR in ${SOURCE_DIRS}
do
  # Get directory name:
  DIR_NAME=$(basename ${SOURCE_DIR})
  # Loop through users:
  for COURSE_USER in ${COURSE_USERS}
  do
    # Create directory, if it does not exist:
    if [ ! -e "/home/${COURSE_USER}/${DIR_NAME}" ] ; then
      mkdir -p /home/${COURSE_USER}/${DIR_NAME}
      chown ${COURSE_USER}:${COURSE_USER} /home/${COURSE_USER}/${DIR_NAME}
    fi
    # Copy files which do not exist:
    rsync -a --ignore-existing \
      ${SOURCE_DIR}/ /home/${COURSE_USER}/${DIR_NAME}/
    chown -R ${COURSE_USER}:${COURSE_USER} /home/${COURSE_USER}/${DIR_NAME}
  done
done
