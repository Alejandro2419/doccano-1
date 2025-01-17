#!/usr/bin/env bash

set -o errexit

apt-get update
apt-get install unixodbc-dev unixodbc -y
echo "apt-get <<<<<<<<<<<<<<<<<<<<<<<<"

root="$(dirname "$0")/.."
app="${root}/app"
venv="${root}/venv"

if [[ ! -f "${venv}/bin/python" ]]; then
  echo "Creating virtualenv"
  mkdir -p "${venv}"
  python3 -m venv "${venv}"
  "${venv}/bin/pip" install --upgrade pip setuptools
fi

echo "Installing dependencies"
"${venv}/bin/pip" install -r "${root}/requirements.txt"

echo "Initializing database"
"${venv}/bin/python" "${app}/manage.py" wait_for_db
"${venv}/bin/python" "${app}/manage.py" migrate

if [[ -n "${ADMIN_USERNAME}" ]] && [[ -n "${ADMIN_PASSWORD}" ]] && [[ -n "${ADMIN_EMAIL}" ]]; then
  "${venv}/bin/python" "${app}/manage.py" create_admin \
    --username "${ADMIN_USERNAME}" \
    --password "${ADMIN_PASSWORD}" \
    --email "${ADMIN_EMAIL}" \
    --noinput \
  || true
fi

echo "Starting django"
"${venv}/bin/python" -u "${app}/manage.py" runserver "$@"
