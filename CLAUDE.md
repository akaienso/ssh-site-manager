# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A single-file bash CLI (`ssh-site-manager`) that stores SSH credentials in a local SQLite database (`~/.sites/credentials.db`), encrypts passwords with AES-256-CBC via openssl, and generates per-site `expect` scripts so users can connect with a short alias instead of typing credentials.

`install.sh` symlinks the script to `/usr/local/bin/sites` and runs `sites init`.

## Data flow

1. `add` → encrypts password with key at `~/.sites/encryption.key` → stores in SQLite → calls `generate_expect_script`
2. `generate_expect_script` → writes `~/.sites/scripts/<alias>.exp` (an expect script that spawns ssh, sends the password, and optionally `cd`s to `working_dir`)
3. `update_aliases` → writes `~/.sites/aliases` (one shell alias per site pointing at the expect script) → appends `source ~/.sites/aliases` to `~/.bash_aliases`

## Key constraints

- The script relies on `openssl`, `sqlite3`, and `expect` being present — no package management or dependency checks beyond that.
- Passwords are stored in expect scripts **in plaintext** after decryption — the security boundary is file permissions (700 on `.exp` files, 600 on the DB and key).
- The `show_site` function embeds the decrypted password directly in a SQL string, which would break if the password contains a single quote.

## Running / testing manually

```bash
# Initialize
./ssh-site-manager init

# Add a site
./ssh-site-manager add mysite example.com user1 'pass123' /var/www/html

# List / inspect
./ssh-site-manager list
./ssh-site-manager show mysite

# Connect (after sourcing aliases)
source ~/.sites/aliases
mysite
```

No automated test suite exists. Manual testing requires a real SSH target or mocking `expect`.
