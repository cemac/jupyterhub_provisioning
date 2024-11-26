#!/bin/bash

# Directories to make:
MAKE_DIRS='LGM_coursework_submission level5_timed_assessment_submission'

# Get course users:
COURSE_GROUP='jh_users_soee5710'
COURSE_USERS=$(getent group ${COURSE_GROUP} | \
                 awk -F ':' '{print $NF}' | \
                 tr ',' '\n' | \
                 egrep -v '^(earhbu|earjacr|earmgr|lmkk419|snnn998|sgtc615)$')

# Loop through directories to make:
for MAKE_DIR in ${MAKE_DIRS}
do
  # Loop through users:
  for COURSE_USER in ${COURSE_USERS}
  do
    # Create directory, if it does not exist:
    if [ ! -e "/home/${COURSE_USER}/${MAKE_DIR}" ] ; then
      mkdir -p /home/${COURSE_USER}/${MAKE_DIR}
      chown ${COURSE_USER}:${COURSE_USER} /home/${COURSE_USER}/${MAKE_DIR}
    fi
  done
done
