#!/bin/bash
set -eu pipefail

ENV="environment.properties"

function check_tools() {
  for tool in "$@"; do
    if ! type -P "$tool" &>/dev/null; then
      echo "Cannot find the required '${tool}' binary in PATH"
      exit 1
    fi
  done
}

check_tools "rclone" "docker" "docker-compose"

#pull vars from env property
function prop {
  grep "${1}" "${ENV}" | cut -d'=' -f2
}

function checkEnvVarDefined {
  if [[ -z ${1} ]]; then
    echo "ERROR: Please configure env property ${1} bin dir in ${ENV}"
    exit 1
  fi
}

FOUNDRY_TEMP_TAR="_tempfoundrybackup.tar.tgz"
PROJECT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
echo "Project & Foundry home dir will be $PROJECT_DIR"
BACKUP_LOCATION=$(prop 'BACKUP_LOCATION')
checkEnvVarDefined "${BACKUP_LOCATION}"
echo "Backup location defined as ${BACKUP_LOCATION}, finding latest backup..."

# extract modtimes from rclone lsl and from Data dir 
LATEST_BACKUP_INFO=$(rclone lsl --order-by modtime $(prop 'BACKUP_LOCATION') | head -1 | grep "foundry_backup.*" | cut -d " " -f 2,3,4)
LATEST_BACKUP_TS=$(echo "${LATEST_BACKUP_INFO}" | cut -d " " -f 1,2)
LATEST_BACKUP_NAME=$(echo "${LATEST_BACKUP_INFO}" | cut -d " " -f 3)
DATA_DIR_DATETIME=$(stat Data | grep "Change" | cut -d ' ' -f 2,3)
echo "Latest remote modification date: ${LATEST_BACKUP_TS}"
echo "Local Data dir modification datetime: ${DATA_DIR_DATETIME}"

# check if pulling is neccessary beforehand
if [[ $LATEST_BACKUP_TS > $DATA_DIR_DATETIME ]]; then
  echo "remote is newer than local Data dir, update required"
  echo "Pulling ${LATEST_BACKUP_NAME} from ${BACKUP_LOCATION}..."
  rclone copy --update --ignore-existing --verbose --checkers 1 --contimeout 60s --timeout 300s --retries 3 --low-level-retries 10 --stats 5s "$(prop 'BACKUP_LOCATION')/${LATEST_BACKUP_NAME}" "$PROJECT_DIR"
  echo "Extracting Data dir from backup..."
  tar -xvf "${LATEST_BACKUP_NAME}"
  echo "Removing archive..."
  rm "${LATEST_BACKUP_NAME}"
  echo "Pull complete! Press any key to close..."
  read -rn1
else
  echo "remote is older than local Data dir, update not required. Press any key to close..."
  read -rn1
  exit 1
fi
