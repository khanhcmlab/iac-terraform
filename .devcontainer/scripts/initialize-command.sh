#!/bin/bash
set -Eeuo pipefail

SCRIPTDIR=$(realpath $(dirname "$0"))
REPO_URL=$(git config --get remote.origin.url)
REPO_NAME=$(basename -s .git "${REPO_URL}")
REPO_NAME_SLUG=$(echo ${REPO_NAME} | tr -d '.')
REPO_PROJECT=$(echo "${REPO_URL}" | awk -F'/' '{print $(NF-1)}' | awk '{print tolower($0)}')
REPO_PATH=$(dirname "${SCRIPTDIR}")
ENV_FILE_PATH="${SCRIPTDIR}/../.env"

error() {
    echo "Error during initialization"
    exit 1
}

trap error ERR

create_directories() {
    echo "Creating directories mounted in docker for persistent data..."
    mkdir -p "${HOME}/.ssh/"
    mkdir -p "${HOME}/.local/"
    mkdir -p "${HOME}/.gnupg/"
    mkdir -p "${HOME}/.${REPO_PROJECT}/pre-commit-cache/"
    mkdir -p "${HOME}/.${REPO_PROJECT}/commandhistory.d"
    mkdir -p "${HOME}/.${REPO_PROJECT}/commandhistory.d/${REPO_NAME}/"
}

create_files() {
    echo "Creating files mounted in docker ..."
    touch "${HOME}/.${REPO_PROJECT}/zsh-history"
    touch "${HOME}/.gitconfig"
    touch "${HOME}/.netrc"
    chmod 600 "${HOME}/.netrc"
}

define_docker_args() {
    echo "Defining Docker Args ..."
    cat <<EOT > "$ENV_FILE_PATH"
    USER=$(whoami)
    HOME=/home/$(whoami)
    REPO_NAME=${REPO_NAME}
    PROJECT_DIR=${REPO_PATH}
    CONTAINER_USER=$(whoami)
    CONTAINER_UID=$(id -u)
    CONTAINER_GID=$(id -g)
    HOST_IP=$(awk '/wsl-proxy/ {print $1}' /etc/hosts)
EOT
}

main() {
    echo "Initialization started..."
    create_directories
    create_files
    define_docker_args
    echo "Initialization completed."
}

main "$@"