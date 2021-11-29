#!/bin/bash

# simple script to dump a path to a compressed tar file
# e.g.:
#   dump.sh /path/to/dir /path/to/dir.tar.gz

# usage function:
usage() {
  echo "$(basename ${0}) source_path out_file"
}

# error function:
error() {
  echo "* ${1}"
  echo "END : $(date)"
  exit
}

# start message:
echo "START : $(date)"

# check number of arguments:
if [ "${#}" != "2" ] ; then
  usage
  error "incorrect number of argments"
fi

# get arguments:
SRC_PATH="${1}"
OUT_FILE="${2}"

# check source exists:
if [ ! -e "${SRC_PATH}" ] ; then
  error "${SRC_PATH} does not appear to exist"
fi

# directory containing source directory:
SRC_DIR="$(dirname "${SRC_PATH}")"
# source file / directory:
SRC_NAME="$(basename "${SRC_PATH}")"
# directory which will contain output file:
OUT_DIR="$(dirname ${OUT_FILE})"

# make output directory:
mkdir -p "${OUT_DIR}" || error "failed to create directory ${OUT_DIR}"
# change to working dir:
cd "${SRC_DIR}" || error "failed to change to directory ${SRC_DIR}"
# create tar file:
tar \
  czf "${OUT_FILE}" \
  --exclude='*/week0*.tar.gz' \
  --exclude='*/coursework/ancillaries/*.nc' \
  --exclude='*/coursework/tead*/*/*.nc' \
  --exclude='*/SOEE1443-Python/Data/*.nc' \
  --exclude='*/SOEE5920/*.nc' \
  "${SRC_NAME}"

# end message:
echo "END : $(date)"
