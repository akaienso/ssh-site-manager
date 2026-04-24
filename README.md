# SSH Site Manager

![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20WSL-blue)
![Shell](https://img.shields.io/badge/shell-bash%204%2B-4EAA25?logo=gnubash&logoColor=white)
![SQLite](https://img.shields.io/badge/database-SQLite3-003B57?logo=sqlite&logoColor=white)
![OpenSSL](https://img.shields.io/badge/encryption-AES--256--CBC-721412?logo=openssl&logoColor=white)
![Expect](https://img.shields.io/badge/automation-expect-orange)
![Auth](https://img.shields.io/badge/auth-password-lightgrey)

A command-line tool for managing SSH connections to multiple sites. Credentials are stored in an encrypted local SQLite database and each site gets a short shell alias so you can connect with a single word.

---

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
  - [Initialize the database](#initialize-the-database)
  - [Add a site](#add-a-site)
  - [Connect to a site](#connect-to-a-site)
  - [List sites](#list-sites)
  - [Show site details](#show-site-details)
  - [Delete a site](#delete-a-site)
  - [Export sites](#export-sites)
  - [Import sites from CSV](#import-sites-from-csv)
- [File locations](#file-locations)
- [Contributing](#contributing)
  - [Architecture overview](#architecture-overview)
  - [Development setup](#development-setup)
  - [Known issues and limitations](#known-issues-and-limitations)

---

## Requirements

- **bash** 4+
- **sqlite3**
- **openssl**
- **expect**

---

## Installation

Clone the repository and run the installer:

```bash
git clone https://github.com/your-username/ssh-site-manager.git
cd ssh-site-manager
./install.sh
```

The installer:

1. Symlinks `ssh-site-manager` to `/usr/local/bin/sites` so the `sites` command is available system-wide.
2. Creates `~/.sites/scripts/` for generated expect scripts.
3. Runs `sites init` to create the credentials database.

To uninstall, remove the symlink and data directory:

```bash
sudo rm /usr/local/bin/sites
rm -rf ~/.sites
```

---

## Usage

All commands are invoked as `sites <command> [options]`, or as `./ssh-site-manager <command>` if running directly from the repository.

### Initialize the database

Creates `~/.sites/credentials.db` and sets restrictive file permissions. Safe to run multiple times.

```bash
sites init
```

### Add a site

```bash
sites add <alias> <hostname> <username> <password> <working_dir>
```

| Argument | Description |
|---|---|
| `alias` | Short name used to connect (e.g. `mysite`) |
| `hostname` | SSH hostname or IP address |
| `username` | SSH username |
| `password` | SSH password (wrap in quotes if it contains special characters) |
| `working_dir` | Directory to `cd` into immediately after connecting |

**Example:**

```bash
sites add mysite example.com deploy 'p@ssw0rd!' /var/www/html
```

If the alias already exists, you will be prompted to confirm before overwriting.

### Connect to a site

After adding a site, load the aliases into your current shell session:

```bash
source ~/.sites/aliases
```

To have aliases available in every new terminal, add the following to your `~/.bashrc` or `~/.zshrc`:

```bash
[ -f ~/.sites/aliases ] && source ~/.sites/aliases
```

> **Note:** `sites add` and `sites update` automatically append a `source ~/.sites/aliases` line to your shell config file (`~/.zshrc` on zsh, `~/.bash_profile` on bash). Open a new terminal — or run `source ~/.zshrc` / `source ~/.bash_profile` — to pick up the change in your current session.

Then connect using the alias:

```bash
mysite
```

This opens an SSH session and automatically `cd`s to the configured working directory.

To connect without changing directory (useful for running a one-off command):

```bash
mysite some-argument
```

Any argument passed to the alias bypasses the `cd` step.

### List sites

```bash
sites list
```

Prints all stored aliases in alphabetical order.

### Show site details

```bash
sites show <alias>
```

Displays the hostname, username, password, and working directory for the given alias.

### Delete a site

```bash
sites delete <alias>
```

Removes the site from the database and deletes its expect script.

### Export sites

```bash
sites export
```

Creates two files in the current directory:

- `sites_export.csv` — alias, hostname, username, and working directory (no passwords)
- `sites_passwords.csv` — alias and plaintext password

Keep `sites_passwords.csv` secure and delete it when no longer needed.

### Import sites from CSV

```bash
sites import <sites_csv>
```

The importer accepts two formats:

**Combined format** (single file, header row required):

```
alias,hostname,username,password,working_dir
mysite,example.com,deploy,p@ssw0rd!,/var/www/html
staging,staging.example.com,admin,hunter2,/home/admin
```

**Split format** (the two files produced by `sites export`):

```bash
sites import sites_export.csv
# automatically looks for sites_passwords.csv in the same directory
```

If the passwords file has a different name or lives elsewhere, pass it explicitly:

```bash
sites import sites_export.csv /path/to/sites_passwords.csv
```

The format is detected automatically from the header row.

---

## File locations

| Path | Purpose |
|---|---|
| `~/.sites/credentials.db` | SQLite database (mode 600) |
| `~/.sites/encryption.key` | AES-256 key used to encrypt stored passwords (mode 600) |
| `~/.sites/scripts/<alias>.exp` | Generated expect scripts (mode 700) |
| `~/.sites/aliases` | Generated shell aliases file |

> **Backup:** To move your sites to another machine, copy `~/.sites/credentials.db` and `~/.sites/encryption.key` together — the key is required to decrypt the passwords stored in the database.

---

## Contributing

### Architecture overview

The tool is a single bash script (`ssh-site-manager`) with no external build step. The data flow for each site is:

1. **Store** — `add_site` encrypts the password with `openssl enc -aes-256-cbc` using the key at `~/.sites/encryption.key`, then inserts or replaces a row in the SQLite `sites` table.
2. **Generate** — `generate_expect_script` reads the site row, decrypts the password, and writes a per-site `expect` script to `~/.sites/scripts/<alias>.exp`. The expect script spawns `ssh`, sends the password, waits for a shell prompt, and optionally runs `cd`.
3. **Alias** — `update_aliases` queries all aliases from SQLite and writes a shell alias for each one to `~/.sites/aliases`, pointing at the corresponding expect script.

This means the decrypted password lives in the expect script on disk. Security relies entirely on the `700` file permission on `.exp` files and `600` on the database and key.

### Development setup

No build tools or package managers are required. Clone the repo and work directly on `ssh-site-manager`:

```bash
git clone https://github.com/your-username/ssh-site-manager.git
cd ssh-site-manager
```

Run commands directly from the repo root during development:

```bash
./ssh-site-manager init
./ssh-site-manager add testsite example.com user pass /tmp
./ssh-site-manager list
./ssh-site-manager show testsite
./ssh-site-manager delete testsite
```

Use [ShellCheck](https://www.shellcheck.net/) to lint changes before submitting:

```bash
shellcheck ssh-site-manager
shellcheck install.sh
```

### Known issues and limitations

- **Passwords with single quotes** — `show_site` interpolates the decrypted password directly into a SQL string. A password containing `'` will break the query. The same issue exists in `add_site`'s duplicate-check query for aliases.
- **No SSH key support** — the tool only handles password authentication. Sites that use key-based auth cannot be added.
- **Prompt matching** — the expect scripts wait for `"$ "` as the shell prompt. Non-standard prompts (e.g. those with colour codes, or prompts not ending in `$ `) will cause the connection to hang.
- **Shell detection** — `update_aliases` detects the shell via `$SHELL` and writes to `~/.zshrc`, `~/.bash_profile`, or `~/.profile`. If your shell config lives elsewhere, add `source ~/.sites/aliases` to it manually.
