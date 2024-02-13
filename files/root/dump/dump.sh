#!/bin/bash

# dump most recent backup to a compressed tar file

# error function:
error() {
  echo "* ${1}"
  echo "END : $(date)"
  exit
}

# start message:
echo "START : $(date)"

# parent backup directory:
BACKUP_DIR='/storage/backup/alpha.0'
# directory within parent backup directory to tar:
SRC_DIR='localhost'
# outpu directory:
OUT_DIR='/storage/backup/dump'

# get time stamp of most recent backup:
BACKUP_TIME=$(date -d @$(stat -c '%Y' ${BACKUP_DIR}) +'%Y%m%d-%H%M')
# output file name and path:
OUT_FILE="${OUT_DIR}/${SRC_DIR}_${BACKUP_TIME}.tar.gz"

# make output directory:
mkdir -p "${OUT_DIR}" || error "failed to create directory ${OUT_DIR}"
# clear out any existing files:
\rm -f ${OUT_DIR}/${SRC_DIR}_*.tar.gz

# change to backup dir:
cd "${BACKUP_DIR}" || error "failed to change to directory ${BACKUP_DIR}"
# create tar file:
nice -n +20 \
tar \
  czf "${OUT_FILE}" \
  --exclude='*/week*.tar.gz' \
  --exclude='*/*.nc' \
  --exclude='*/*.nc4' \
  --exclude='*/*.zip' \
  --exclude='*/datadrivedirectory.tar.gz' \
  --exclude='*/homedirectory.tar.gz' \
  --exclude='*/.local/lib/python3.11/*' \
  --exclude='*/.cache/pip/*' \
  "${SRC_DIR}"

# end message:
echo "END : $(date)"
