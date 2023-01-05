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
PROJECT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
echo "Project & Foundry home dir will be $PROJECT_DIR"
BACKUP_LOCATION=$(prop 'BACKUP_LOCATION')
checkEnvVarDefined "${BACKUP_LOCATION}"
echo "Backup location defined as ${BACKUP_LOCATION}, finding latest backup..."
LATEST_BACKUP=$(rclone lsl $(prop 'BACKUP_LOCATION') | head -1 | grep "foundry_backup.*" | cut -d " " -f 4)
echo "latest backup is ${LATEST_BACKUP}, pulling from ${BACKUP_LOCATION}..."
rclone copy --update --ignore-existing --verbose --checkers 1 --contimeout 60s --timeout 300s --retries 3 --low-level-retries 10 --stats 5s "$(prop 'BACKUP_LOCATION')/${LATEST_BACKUP}" "$PROJECT_DIR"
echo "Extracting Data dir from backup..."
tar -xvf "${LATEST_BACKUP}"
echo "Removing archive..."
rm $LATEST_BACKUP
echo ls
echo "Pull complete! Press any key to close..."
read -rn1
