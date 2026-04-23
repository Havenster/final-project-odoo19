#!/usr/bin/env bash
set -euo pipefail

readonly BASE_DIR="$HOME/Development"
readonly ODOO_DIR="$BASE_DIR/odoo19"
readonly VENV_DIR="$ODOO_DIR/odoo19env"
readonly CONFIG_FILE="$ODOO_DIR/odoo.conf"
readonly ADDONS_DIR="$ODOO_DIR/myaddons"
readonly PG_VERSION="postgresql@15"
readonly PG_PORT="5433"
readonly PYTHON_FORMULA="python@3.12"
readonly DEFAULT_DB_USER="odoouser"
readonly DEFAULT_DB_PASS="odoo123"

function ensure_homebrew() {
  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew is missing. Install it from https://brew.sh/ first."
    exit 1
  fi
}

function install_formula() {
  local formula=$1
  if ! brew list --formula | grep -Fq "${formula}"; then
    brew install "${formula}"
  else
    brew upgrade "${formula}" || true
  fi
}

function install_cask() {
  local cask=$1
  if ! brew list --cask | grep -Fq "${cask}"; then
    brew install --cask "${cask}"
  fi
}

function ensure_postgres() {
  install_formula "${PG_VERSION}"
  local prefix data_dir bin_dir
  prefix=$(brew --prefix "${PG_VERSION}")
  data_dir="${prefix}/var/postgres"
  bin_dir="${prefix}/bin"
  if [[ ! -d "${data_dir}" ]]; then
    "${bin_dir}/initdb" -D "${data_dir}"
  fi
  if ! "${bin_dir}/pg_isready" -h localhost -p "${PG_PORT}" >/dev/null 2>&1; then
    echo "PostgreSQL is not reachable on port ${PG_PORT}."
    echo "Start it on port ${PG_PORT} and rerun this script."
    exit 1
  fi
  "${bin_dir}/createuser" -h localhost -p "${PG_PORT}" -s postgres || true
  "${bin_dir}/psql" -h localhost -p "${PG_PORT}" postgres -c "ALTER USER postgres WITH PASSWORD 'postgres';"
  "${bin_dir}/psql" -h localhost -p "${PG_PORT}" postgres -c "CREATE ROLE ${DEFAULT_DB_USER} WITH LOGIN SUPERUSER PASSWORD '${DEFAULT_DB_PASS}'" || true
  install_cask pgadmin4
}

function ensure_python() {
  install_formula "${PYTHON_FORMULA}"
  brew link --force --overwrite "${PYTHON_FORMULA}"
}

function ensure_wkhtmltopdf() {
  install_cask wkhtmltopdf
}

function clone_odoo() {
  mkdir -p "${BASE_DIR}"
  if [[ -d "${ODOO_DIR}" ]]; then
    echo "${ODOO_DIR} already exists; skipping git clone."
  else
    git clone https://github.com/odoo/odoo.git "${ODOO_DIR}"
  fi
  pushd "${ODOO_DIR}" >/dev/null
  git fetch --all --prune
  git checkout 19.0 || git checkout 18.0
  popd >/dev/null
}

function bootstrap_virtualenv() {
  pushd "${ODOO_DIR}" >/dev/null
  if [[ ! -d "${VENV_DIR}" ]]; then
    python3.12 -m venv "${VENV_DIR}"
  fi
  # shellcheck disable=SC1090
  source "${VENV_DIR}/bin/activate"
  python -m pip install --upgrade pip setuptools wheel
  pip install psycopg2-binary
  pip install -r requirements.txt
  deactivate
  popd >/dev/null
}

function create_config() {
  local wk_path
  wk_path=$(command -v wkhtmltopdf || true)
  if [[ -z "${wk_path}" ]]; then
    echo "wkhtmltopdf not found in PATH; install it before running odoo."
    exit 1
  fi
  cat <<EOF > "${CONFIG_FILE}"
[options]
db_host = localhost
db_port = ${PG_PORT}
db_user = ${DEFAULT_DB_USER}
db_password = ${DEFAULT_DB_PASS}
db_name = odoodata
http_port = 8069
addons_path = addons,odoo/addons,myaddons
log_level = info
bin_path = ${wk_path}
EOF
}

function create_addons_dir() {
  mkdir -p "${ADDONS_DIR}"
}

function show_next_steps() {
  cat <<EOF
Odoo prerequisites are satisfied. Continue with:
  1. source "${VENV_DIR}/bin/activate"
  2. python odoo-bin --config odoo.conf
  3. Visit http://localhost:8069 and set your master password / database settings
EOF
}

ensure_homebrew
ensure_postgres
ensure_python
ensure_wkhtmltopdf
clone_odoo
create_addons_dir
bootstrap_virtualenv
create_config
show_next_steps
