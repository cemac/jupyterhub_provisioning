#!/bin/bash

# Error function:
error() {
  echo "* ${1}"
  exit 1
}

# Check number of arguments:
if [ "${#}" != "5" ] ; then
  error "incorrect number of arguments"
fi

# Arguments ... user group:
USER_GROUP="${1}"
SUBMIT_DIR="${2}"
MARKER_USERS="${3}"
MARKER_GROUP="${4}"
MARKER_DIR="${5}"

# Start message:
echo "START: $(date)"

# File extensions (including '.') to look for. All other files will be ignored:
FILE_EXTS='.ipynb .pdf'

# Name of directory within the SUBMIT_DIR to which submitted files will be
# moved:
SUBMITTED_DIR='submitted'
# Name of directory within SUBMIT_DIR to which marked files will be returned:
RETURNED_DIR='marked'

# Files must be at least this many seconds old before being collected, to
# allow for students to change their minds / correct things:
FILE_MIN_AGE='1800'

# Name of directory within MARKER_DIR from which marked files will be
# collected:
MARKED_DIR='marked'
# Name of directory within MARKER_DIR to which marked files will be moved,
# once returned:
DONE_DIR='returned'

# Display message:
echo "Checking for submitted files ..."

# Loop through users in group:
for USER in $(getent group ${USER_GROUP} | awk -F ':' '{print $4}' | \
                tr ',' ' ')
do
  # Get USER primary group:
  USER_GROUP=$(id -gn ${USER})
  # Get USER HOME:
  USER_HOME=$(getent passwd ${USER} | awk -F ':' '{print $6}')
  # Check if SUBMIT_DIR exists:
  if [ -d "${USER_HOME}/${SUBMIT_DIR}" ] ; then
    # For each file extension:
    for FILE_EXT in ${FILE_EXTS}
    do
      # Find files in SUBMIT_DIR:
      find ${USER_HOME}/${SUBMIT_DIR} -maxdepth 1 -type f -name "*${FILE_EXT}" | \
        while read USER_FILE
      do
        # Current date in seconds and %Y%m%d_%H%M%S:
        CURRENT_TIME=$(date +%s)
        CURRENT_DATE=$(date +%Y%m%d_%H%M%S)
        # Get file modification date:
        FILE_TIME=$(stat -c %Y "${USER_FILE}")
        FILE_AGE=$((${CURRENT_TIME} - ${FILE_TIME}))
        # If file age is greater than FILE_MIN_AGE:
        if [ ${FILE_AGE} -gt ${FILE_MIN_AGE} ] ; then
          # Work out new file name:
          IN_FILE="$(basename "${USER_FILE}")"
          OUT_FILE="${USER}_${CURRENT_DATE}_${IN_FILE}"
          # For each marker:
          for MARKER_USER in ${MARKER_USERS}
          do
            # Marker's HOME:
            MARKER_HOME=$(getent passwd ${MARKER_USER} | awk -F ':' '{print $6}')
            # Check for / created submitted directory in marker's HOME:
            if [ ! -d "${MARKER_HOME}/${MARKER_DIR}" ] ; then
              mkdir "${MARKER_HOME}/${MARKER_DIR}"
              if [ "${?}" != 0 ] ; then
                echo "* failed to create directory ${MARKER_HOME}/${MARKER_DIR}."
                echo "* exiting ..."
                exit
              fi
              chown ${MARKER_USER}:${MARKER_GROUP} \
                "${MARKER_HOME}/${MARKER_DIR}"
            fi
            cp -p "${USER_FILE}" "${MARKER_HOME}/${MARKER_DIR}/${OUT_FILE}"
            chown ${MARKER_USER}:${MARKER_GROUP} \
              "${MARKER_HOME}/${MARKER_DIR}/${OUT_FILE}"
            chmod g+w "${MARKER_HOME}/${MARKER_DIR}/${OUT_FILE}"
          done
          # Check for / created submitted directory in user's directory:
          if [ ! -d "${USER_HOME}/${SUBMIT_DIR}/${SUBMITTED_DIR}" ] ; then
            mkdir "${USER_HOME}/${SUBMIT_DIR}/${SUBMITTED_DIR}"
            chown ${USER}:${USER_GROUP} \
              "${USER_HOME}/${SUBMIT_DIR}/${SUBMITTED_DIR}"
          fi
          # Move file to submitted directory and make read only:
          mv "${USER_FILE}" \
            "${USER_HOME}/${SUBMIT_DIR}/${SUBMITTED_DIR}/${IN_FILE}"
          chmod 444 "${USER_HOME}/${SUBMIT_DIR}/${SUBMITTED_DIR}/${IN_FILE}"
        fi
      done
    done
  fi
done

# Display message:
echo "Checking for marked files ..."

# For each marker:
for MARKER_USER in ${MARKER_USERS}
do
  # Marker's primary group:
  MARKER_GROUP=$(id -gn ${MARKER_USER})
  # Marker's HOME:
  MARKER_HOME=$(getent passwd ${MARKER_USER} | awk -F ':' '{print $6}')
  # If MARKER_DIR does not exist nothing has been submitted, so move on:
  if [ ! -d "${MARKER_HOME}/${MARKER_DIR}" ] ; then
    continue
  fi
  # Check for / created marked directory in marker's HOME:
  if [ ! -d "${MARKER_HOME}/${MARKER_DIR}/${MARKED_DIR}" ] ; then
    mkdir "${MARKER_HOME}/${MARKER_DIR}/${MARKED_DIR}"
    chown ${MARKER_USER}:${MARKER_GROUP} \
      "${MARKER_HOME}/${MARKER_DIR}/${MARKED_DIR}"
  fi
  # For each file extension:
  for FILE_EXT in ${FILE_EXTS}
  do
    # Check for marked files:
    find ${MARKER_HOME}/${MARKER_DIR}/${MARKED_DIR} -maxdepth 1 -type f \
      -name "*${FILE_EXT}" | while read USER_FILE
    do
      # Remove metadata from file name:
      IN_FILE="$(basename "${USER_FILE}")"
      # Check for username in file name:
      USER=$(echo "${IN_FILE}" | awk -F '_' '{print $1}')
      USER_GROUP=$(id -gn ${USER})
      USER_HOME=$(getent passwd ${USER} | awk -F ':' '{print $6}')
      if [ -z "${USER_HOME}" ] ; then
        echo "* failed to find user home directory for file ${USER_FILE}"
        echo "* skipping ..."
      else
        # Output file name:
        OUT_FILE="$(echo "${IN_FILE}" | sed 's|[a-z0-9]\+_[0-9]\+_[0-9]\+_||g')"
        # Check for / create directory for marked files in user directory:
        if [ ! -d "${USER_HOME}/${SUBMIT_DIR}" ] ; then
          mkdir "${USER_HOME}/${SUBMIT_DIR}"
          chown ${USER}:${USER_GROUP} "${USER_HOME}/${SUBMIT_DIR}"
        fi
        if [ ! -d "${USER_HOME}/${SUBMIT_DIR}/${RETURNED_DIR}" ] ; then
          mkdir "${USER_HOME}/${SUBMIT_DIR}/${RETURNED_DIR}"
          chown ${USER}:${USER_GROUP} \
            "${USER_HOME}/${SUBMIT_DIR}/${RETURNED_DIR}"
        fi
        # Check if output / returned file already exists ... :
        if [ -e "${USER_HOME}/${SUBMIT_DIR}/${RETURNED_DIR}/${OUT_FILE}" ] ; then
          # Add current time stamp to returned file name:
          CURRENT_DATE=$(date +%Y%m%d%H%M%S)
          OUT_FILE="${OUT_FILE/${FILE_EXT}/}_${CURRENT_DATE}${FILE_EXT}"
        fi
        # Copy file back to USER dir:
        cp -p "${USER_FILE}" \
          "${USER_HOME}/${SUBMIT_DIR}/${RETURNED_DIR}/${OUT_FILE}"
        chown ${USER}:${USER_GROUP} \
          "${USER_HOME}/${SUBMIT_DIR}/${RETURNED_DIR}/${OUT_FILE}"
        # Make returned file read only:
        chmod 444  "${USER_HOME}/${SUBMIT_DIR}/${RETURNED_DIR}/${OUT_FILE}"
        # Check for / create returned directory in marker's directory:
        if [ ! -d "${MARKER_HOME}/${MARKER_DIR}/${DONE_DIR}" ] ; then
          mkdir "${MARKER_HOME}/${MARKER_DIR}/${DONE_DIR}"
          chown ${MARKER_USER}:${MARKER_GROUP} \
            "${MARKER_HOME}/${MARKER_DIR}/${DONE_DIR}"
        fi
        # Move file to DONE_DIR:
        mv "${USER_FILE}" "${MARKER_HOME}/${MARKER_DIR}/${DONE_DIR}/"
      fi
    done
  done
done

# End message:
echo "END: $(date)"
