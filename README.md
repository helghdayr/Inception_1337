# Inception

> A Docker-based infrastructure project using NGINX, WordPress, and MariaDB — built from scratch with custom Dockerfiles and orchestrated via Docker Compose.

---

## Table of Contents

- [Overview](#overview)
- [Project Structure](#project-structure)
- [Architecture](#architecture)
- [Services](#services)
  - [NGINX](#nginx)
  - [WordPress](#wordpress)
  - [MariaDB](#mariadb)
- [Prerequisites](#prerequisites)
- [Environment Variables](#environment-variables)
- [Setup & Usage](#setup--usage)
- [Volumes & Networks](#volumes--networks)
- [Security Notes](#security-notes)
- [Mandatory Rules](#mandatory-rules)

---

## Overview

**Inception** is a system administration project from 42 School. The goal is to set up a small but complete web infrastructure using **Docker** and **Docker Compose**. Each service runs in its own container, built from a **custom Dockerfile** based on the **penultimate stable version of Alpine or Debian**.

The full stack includes:

- **NGINX** — the sole entry point, handling HTTPS (TLSv1.2/1.3 only)
- **WordPress + php-fpm** — the web application (no pre-built image, no NGINX inside)
- **MariaDB** — the database backend (no pre-built image, no MySQL)

---

## Project Structure

```
inception/
├── Makefile
├── srcs/
│   ├── .env
│   ├── docker-compose.yml
│   └── requirements/
│       ├── nginx/
│       │   ├── Dockerfile
│       │   └── conf/
│       │       └── nginx.conf
│       ├── wordpress/
│       │   ├── Dockerfile
│       │   └── conf/
│       │       └── www.conf
│       └── mariadb/
│           ├── Dockerfile
│           └── conf/
│               └── init.sql
└── README.md
```

---

## Architecture

```
                    ┌─────────────────────────────────┐
                    │         Docker Network           │
                    │                                  │
  HTTPS :443        │  ┌────────┐      ┌───────────┐  │
  ──────────────────┼─►│ NGINX  │─────►│ WordPress │  │
                    │  │        │      │ (php-fpm) │  │
                    │  └────────┘      └─────┬─────┘  │
                    │                        │         │
                    │                  ┌─────▼─────┐  │
                    │                  │  MariaDB  │  │
                    │                  └───────────┘  │
                    └─────────────────────────────────┘
```

- All containers communicate over a **custom Docker bridge network**.
- NGINX is the **only exposed port** (443/HTTPS). Port 80 is not used.
- WordPress connects to MariaDB via the internal network.
- Data is persisted via **Docker volumes**.

---

## Services

### NGINX

| Property | Value |
|----------|-------|
| Base image | `debian:bullseye` or `alpine:3.18` |
| Port | `443` (HTTPS only) |
| Protocols | TLSv1.2 and TLSv1.3 |
| Role | Reverse proxy / SSL termination |

**Key configuration points:**
- Only TLSv1.2 and TLSv1.3 are allowed — no HTTP, no older TLS.
- SSL certificate and key are generated inside the container (self-signed for local use).
- Forwards PHP requests to the WordPress container via FastCGI (`fastcgi_pass wordpress:9000`).

**Example `nginx.conf` snippet:**

```nginx
server {
    listen 443 ssl;
    server_name <your_login>.42.fr;

    ssl_certificate     /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    ssl_protocols       TLSv1.2 TLSv1.3;

    root /var/www/html;
    index index.php;

    location ~ \.php$ {
        fastcgi_pass wordpress:9000;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}
```

---

### WordPress

| Property | Value |
|----------|-------|
| Base image | `debian:bullseye` or `alpine:3.18` |
| Port | `9000` (FastCGI, internal only) |
| Role | PHP application server |

**Key configuration points:**
- Runs `php-fpm` — **no NGINX inside the WordPress container**.
- WordPress core files are downloaded with `wp-cli` or `curl` during image build.
- `wp-config.php` is configured with MariaDB credentials from environment variables.
- Two WordPress users are created at startup: one admin and one regular user.
  - The admin username must **not** contain "admin", "Admin", or "administrator".

**`wp-config.php` relevant environment bindings:**

```php
define('DB_NAME',     getenv('MYSQL_DATABASE'));
define('DB_USER',     getenv('MYSQL_USER'));
define('DB_PASSWORD', getenv('MYSQL_PASSWORD'));
define('DB_HOST',     'mariadb:3306');
```

---

### MariaDB

| Property | Value |
|----------|-------|
| Base image | `debian:bullseye` or `alpine:3.18` |
| Port | `3306` (internal only) |
| Role | Relational database |

**Key configuration points:**
- No `mysql` image — built from scratch.
- Database and users are created during the container's first startup via an init script.
- The `root` password is set and secured (no empty password).
- The MariaDB port is **not exposed** to the host.

**Example init script:**

```sql
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
```

---

## Prerequisites

- **Docker** >= 20.10
- **Docker Compose** >= 1.29 (or Compose v2 via `docker compose`)
- **Make**
- A valid domain configured in `/etc/hosts` pointing to `127.0.0.1`:

```bash
# /etc/hosts
127.0.0.1   <your_login>.42.fr
```

---

## Environment Variables

Create a `.env` file at `srcs/.env`. **Never commit this file to Git.**

```env
# Domain
DOMAIN_NAME=<your_login>.42.fr

# MariaDB
MYSQL_ROOT_PASSWORD=your_root_password
MYSQL_DATABASE=wordpress
MYSQL_USER=wp_user
MYSQL_PASSWORD=your_db_password

# WordPress
WP_TITLE=My Inception Site
WP_ADMIN_USER=myadmin
WP_ADMIN_PASSWORD=adminpass
WP_ADMIN_EMAIL=admin@example.com
WP_USER=regularuser
WP_USER_PASSWORD=userpass
WP_USER_EMAIL=user@example.com
```

> ⚠️ All passwords and sensitive values must be stored in the `.env` file — **never hardcoded** in Dockerfiles or configuration files.

---

## Setup & Usage

### Build and start all services

```bash
make
```

This will:
1. Build all Docker images from their respective Dockerfiles.
2. Create Docker volumes and the internal network.
3. Start all containers via `docker-compose up --build`.

### Stop all services

```bash
make down
```

### Remove all containers, volumes, and images

```bash
make fclean
```

### Rebuild from scratch

```bash
make re
```

### Access the site

Open your browser and navigate to:

```
https://<your_login>.42.fr
```

Accept the self-signed certificate warning to proceed.

---

## Volumes & Networks

### Volumes

| Volume | Mount Path | Purpose |
|--------|------------|---------|
| `wp_data` | `/var/www/html` | WordPress files |
| `db_data` | `/var/lib/mysql` | MariaDB database files |

Volumes are stored on the host at `/home/<your_login>/data/` and persist across container restarts.

### Network

A single custom bridge network named `inception` connects all three containers. No container uses the `host` network or `--network=host`.

---

## Security Notes

- **No passwords in Dockerfiles** — all secrets come from the `.env` file.
- **NGINX is the only public-facing container** — MariaDB and WordPress are never directly reachable from outside.
- **TLS only** — HTTP traffic on port 80 is not accepted.
- **Self-signed SSL** — generated at build time for `localhost`/`<login>.42.fr`. For production use, replace with a CA-signed certificate.
- **`.env` is gitignored** — ensure it is listed in `.gitignore`.

---

## Mandatory Rules

As per the Inception subject requirements:

- [x] Each service runs in a **dedicated container**.
- [x] Containers are built from the **penultimate stable version** of Debian or Alpine.
- [x] **No `latest` tag** in FROM instructions.
- [x] **No pre-built images** (no pulling `nginx`, `wordpress`, or `mysql` from Docker Hub).
- [x] **No infinite loops** (`tail -f`, `sleep infinity`, `while true` etc. as entrypoints).
- [x] Containers **restart automatically** on crash (`restart: on-failure` or `unless-stopped`).
- [x] NGINX uses **TLSv1.2 or TLSv1.3 only**.
- [x] WordPress is configured with **php-fpm** and runs without NGINX.
- [x] MariaDB is used — **not MySQL**.
- [x] Volumes are configured for **WordPress files** and **database data**.
- [x] A **custom Docker network** connects the containers.
- [x] All credentials are in the **`.env` file** and never hardcoded.
- [x] WordPress has **two users**: one admin (username must not contain "admin") and one regular user.

---

## Author

**Login:** `hael-ghd`  
**School:** 42  
**Project:** Inception
