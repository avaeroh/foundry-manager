#!/bin/bash
ENV="environment.properties"

function check_tools() {
  for tool in "$@"; do
    if ! type -P "$tool" &>/dev/null; then
      echo "Cannot find the required '${tool}' binary in PATH"
      exit 1
    fi
  done
}

check_tools "rclone"

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
BACKUP_LOCATION=$(prop 'BACKUP_LOCATION')
RCLONE=$(which rclone)
checkEnvVarDefined "${RCLONE}" "${BACKUP_LOCATION}" "${PROJECT_DIR}"
FILE_NAME="foundry_backup_$(date +"%d-%m-%Y").tar.tgz"

echo "creating & compressing archive with name ${FILE_NAME} at ${PROJECT_DIR}..."
tar -C "${PROJECT_DIR}" -cvzf "${FILE_NAME}" Data/
$RCLONE copy --update --ignore-existing --verbose --checkers 1 --contimeout 60s --timeout 300s --retries 3 --low-level-retries 10 --stats 5s "$FILE_NAME" "${BACKUP_LOCATION}"
echo "backup uploaded, removing local file..."
rm "${FILE_NAME}"
read -rn1
