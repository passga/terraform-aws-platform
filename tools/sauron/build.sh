#!/bin/bash

set -euo pipefail

SAURON_VERSION=1.0.0

print_error() {
  RED='\033[0;31m'
  NC='\033[0m' # No Color
  printf "${RED}ERROR - $1\n${NC}"
}

exit_with_usage() {
  SCRIPT_NAME=$(basename "$0")
  [ -n "$1" ] && print_error "$1" >&2
  echo ""
  echo "Usage: ./$SCRIPT_NAME [options] "
  echo ""
  echo "Options:"
  echo "  -t tag_name  tag the using using this name - by default bonitasoft/sauron:latest"
  echo ""
  echo "Examples:"
  echo "  $> ./$SCRIPT_NAME "
  echo ""
  exit 1
}


# parse command line arguments
no_cache="true"
TAG_NAME=""
while [ "$#" -gt 0 ]; do
  # process next argument
  case $1 in
  -t)
    shift
     TAG_NAME=$1
     if [ -z "$TAG_NAME" ]; then
       exit_with_usage "Option -t requires an argument."
     fi
     ;;
  --)
    break
    ;;
  *)
    exit_with_usage "Unrecognized option: $1"
    ;;
  esac
  if [ "$#" -gt 0 ]; then
    shift
  fi
done

if [ -z "$TAG_NAME" ]; then
  TAG_NAME="bonitasoft/sauron:latest"
fi

echo ". Building image <${TAG_NAME}>"
mkdir build
build_cmd="docker build -t  ${TAG_NAME} ."
echo "Running command: '$build_cmd'"
eval "$build_cmd"
rm -rf build
echo ". Done!"




