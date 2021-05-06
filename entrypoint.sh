#!/usr/bin/env bash
set -e

# Entrypoint that overrides spark entrypoint, adding github fetch of the source code
# All the others params from spark-submit for drivers and executors, are the same from 
# the original entrypoint.

# Copy id rsa from temp config path to ssh directory with the correct permissions
function config_ssh() {
  FILE=/root/.ssh/id_rsa
  cp "${GIT_DEPLOY_KEY_PATH}/id_rsa" "${FILE}"
  chmod 600 "${FILE}"
  if ! test -f "$FILE"; then
    echo "Missing git authentication file: ${FILE}"
    exit 1
  fi
}

# Clones only one directory from a github repository (sparse checkout)
function clone_repo() {

  cd ${PYTHONPATH}

  git init
  git remote add origin -f "${REPOSITORY_URL}"
  git config core.sparsecheckout true

  echo "Pulling code from ${REPOSITORY_URL}..."
  if [[ -n "${REPOSITORY_DIRECTORY}" ]]; then
    echo "${REPOSITORY_DIRECTORY}" >> .git/info/sparse-checkout
    echo "Sparse checkout only the directory: ${REPOSITORY_DIRECTORY}"
  fi

  git pull --depth=1 origin "${REPOSITORY_BRANCH}"
  ls -lah ${PYTHONPATH}
}

function install_requirements() {
  
  if [[ "${REQUIREMENTS}" == "True" ]]; then
    pip install -r ${PYTHONPATH}/${REPOSITORY_DIRECTORY}/requirements.txt
  fi
}

function gcloud_auth_at_start() {
  if [[ "${GCLOUD_AUTH_AT_START}" == "True" ]]; then
    gcloud auth activate-service-account --key-file "${GOOGLE_APPLICATION_CREDENTIALS}"
  fi
}

# Calls original entrypoint
function run() {
  if [[ "${1}" == "spark-submit" ]] && [[ "${DEV_MODE}" == "False" ]]; then
    mkdir -p /tmp/spark
    x=$(source /opt/entrypoint.sh "${@}" &> /tmp/spark/output)
    if [ -f "/tmp/spark/output" ]; then
      echo "Logging from spark >>>"
      cat /tmp/spark/output
      exit $(cat /tmp/spark/output | grep -oP -m1 "exit[ ]?code: \K\d+")
    else
      echo "No output file... Job did not execute!"
      exit 1
    fi
  else
    gcloud_auth_at_start
    source /opt/entrypoint.sh "${@}"
  fi
}

REPOSITORY_URL=${REPOSITORY_URL:-""}
REPOSITORY_DIRECTORY=${REPOSITORY_DIRECTORY:-""}
REPOSITORY_BRANCH=${REPOSITORY_BRANCH:-"main"}
REQUIREMENTS=${REQUIREMENTS:-"False"}
GCLOUD_AUTH_AT_START=${GCLOUD_AUTH_AT_START:-"False"}
DEV_MODE=${DEV_MODE:-"False"}

if [[ -n "${REPOSITORY_URL}" ]]; then
  if [[ -z "${REPOSITORY_URL}" ]] || [[ -z "${GIT_DEPLOY_KEY_PATH}" ]] || [[ -z "${REPOSITORY_DIRECTORY}" ]] || [[ -z "${REPOSITORY_BRANCH}" ]]; then
    printf "To perform git clone we need at least the environment variables \n"
    printf "'REPOSITORY_URL', 'REPOSITORY_DIRECTORY', 'REPOSITORY_BRANCH', 'GIT_DEPLOY_KEY_PATH' \n"
    exit 1
  fi
  config_ssh
  clone_repo
  install_requirements
fi
run "${@}"
