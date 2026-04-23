# Odoo 19 macOS Development Setup

This guide sets up **Odoo 19 Community Edition** from GitHub on macOS.

If the `19.0` branch is not available yet, use `18.0` exactly the same way.

## 1. Prerequisites

1. Install [Homebrew](https://brew.sh/) if you do not already have it.
2. Install Xcode Command Line Tools:
   ```bash
   xcode-select --install
   ```
3. Install Git and confirm it works:
   ```bash
   git --version
   ```

## 2. Install Python

Install Python 3.12 or newer with Homebrew:

```bash
brew install python@3.12
python3 --version
pip3 --version
```

If `python3` still points to the system Python, use:

```bash
python3.12 --version
```

## 3. Install PostgreSQL

Odoo works well with PostgreSQL 15 or 16.

```bash
brew install postgresql@15
brew services start postgresql@15
psql -U postgres
```

If `postgres` does not exist yet, create it and set a password:

```bash
createuser -s postgres
psql postgres -c "ALTER USER postgres WITH PASSWORD 'postgres';"
```

Create an Odoo database user:

```bash
psql postgres -c "CREATE ROLE odoouser WITH LOGIN SUPERUSER PASSWORD 'odoo123';"
```

## 4. Install wkhtmltopdf

Odoo needs `wkhtmltopdf` for PDF reports.

```bash
brew install --cask wkhtmltopdf
```

On Apple Silicon, the binary is usually at `/opt/homebrew/bin/wkhtmltopdf`.
On Intel Macs, it is usually at `/usr/local/bin/wkhtmltopdf`.

## 5. Clone Odoo

```bash
mkdir -p ~/Development
cd ~/Development
git clone https://github.com/odoo/odoo.git odoo19
cd odoo19
git checkout 19.0
```

If `19.0` is not available yet:

```bash
git checkout 18.0
```

## 6. Create a virtual environment

```bash
python3.12 -m venv odoo19env
source odoo19env/bin/activate
python -m pip install --upgrade pip setuptools wheel
```

## 7. Install Python dependencies

```bash
pip install psycopg2-binary
pip install -r requirements.txt
```

If `psycopg2` compilation still gives you trouble, `psycopg2-binary` is usually enough for local development on macOS.

## 8. Create `odoo.conf`

Create `~/Development/odoo19/odoo.conf` with:

```ini
[options]
admin_passwd = admin

db_host = localhost
db_port = 5432
db_name = odoodata
db_user = odoouser
db_password = odoo123

addons_path = addons,odoo/addons,myaddons
http_port = 8069
bin_path = /opt/homebrew/bin/wkhtmltopdf
logfile = odoo.log
```

If you are on Intel Mac, change `bin_path` to `/usr/local/bin/wkhtmltopdf`.

## 9. Add custom addons

Create a folder for your custom modules:

```bash
mkdir -p myaddons
```

## 10. Run Odoo

From inside the Odoo folder with the virtual environment activated:

```bash
python odoo-bin -c odoo.conf
```

## 11. Open Odoo

Visit:

```text
http://localhost:8069
```

Developer mode:

```text
http://localhost:8069/web?debug=1
```

## Common fixes

1. If a package fails to build, make sure Xcode Command Line Tools are installed.
2. If PostgreSQL is not running, restart it with:
   ```bash
   brew services restart postgresql@15
   ```
3. If `wkhtmltopdf` is missing, reinstall it with:
   ```bash
   brew install --cask wkhtmltopdf
   ```

## Official reference

Odoo’s source-install docs for Mac, Python, PostgreSQL, and `wkhtmltopdf` are here:

- [Odoo 19 source install](https://www.odoo.com/documentation/19.0/administration/on_premise/source.html)

