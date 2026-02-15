# PostgreSQL 18 Installation and Configuration on Ubuntu Server 24.04
## Complete Documentation with Troubleshooting Guide

---

## Quick Summary of Your Setup

| Component | Value |
|-----------|-------|
| **PostgreSQL Version** | 18.2 |
| **Data Directory** | `/data/postgres-18` |
| **Port** | 5432 |
| **Configuration File** | `/etc/postgresql/18/main/postgresql.conf` |
| **AppArmor Profile** | `/etc/apparmor.d/usr.lib.postgresql.18.main` |
| **AppArmor Mode** | Enforce |
| **Socket Directory** | `/var/run/postgresql` |
| **Database User** | `symphony_admin` |
| **Database Name** | `symphony` |
| **Connection URL** | `postgresql://symphony_admin:symphony_pass@localhost:5432/symphony` |

---

## Table of Contents
1. [Initial Installation](#1-initial-installation)
2. [Custom Data Directory Setup](#2-custom-data-directory-setup)
3. [Cluster Creation and Management](#3-cluster-creation-and-management)
4. [SSL and Permission Fixes](#4-ssl-and-permission-fixes)
5. [Shared Memory Configuration](#5-shared-memory-configuration)
6. [AppArmor Configuration](#6-apparmor-configuration)
7. [Port Configuration](#7-port-configuration)
8. [User and Database Creation](#8-user-and-database-creation)
9. [Environment Variable Setup](#9-environment-variable-setup)
10. [Troubleshooting Gotchas](#10-troubleshooting-gotchas)
11. [Complete AppArmor Profile](#11-complete-apparmor-profile)
12. [Command Reference](#12-command-reference)
13. [Final Verification](#13-final-verification)

---

## 1. Initial Installation

### Add the Official PostgreSQL Repository

```bash
# Import the repository signing key
sudo install -d /usr/share/postgresql-common/pgdg
sudo curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc

# Create the repository configuration file
sudo sh -c 'echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

# Update package lists
sudo apt update
```

### Install PostgreSQL 18

```bash
sudo apt install -y postgresql-18 postgresql-contrib-18
```

**⚠️ GOTCHA:** After installation, PostgreSQL 18 may not automatically create a cluster. Always verify with `pg_lsclusters`.

---

## 2. Custom Data Directory Setup

### Create and Prepare Custom Data Directory

```bash
# Create the data directory
sudo mkdir -p /data/postgres-18

# Set proper ownership and permissions
sudo chown postgres:postgres /data/postgres-18
sudo chmod 700 /data/postgres-18

# Verify the directory is ready
ls -ld /data/postgres-18
```

### Initialize the Database Cluster

```bash
sudo -u postgres /usr/lib/postgresql/18/bin/initdb -D /data/postgres-18
```

**⚠️ GOTCHA:** The `postgres` user must own the data directory. If you get "Permission denied" errors, check parent directory permissions:
```bash
ls -ld /data
# Should show drwxr-xr-x with root ownership - this is fine as long as postgres owns the subdirectory
```

---

## 3. Cluster Creation and Management

### Create and Register the Cluster

```bash
# Create a new cluster with custom data directory
sudo pg_createcluster 18 main -d /data/postgres-18

# Check cluster status
pg_lsclusters
```

### Start and Stop the Cluster

```bash
# Start the cluster
sudo pg_ctlcluster 18 main start

# Stop the cluster
sudo pg_ctlcluster 18 main stop

# Restart the cluster
sudo pg_ctlcluster 18 main restart

# Check detailed status
sudo systemctl status postgresql@18-main
```

### If the Cluster Won't Start

```bash
# Check the logs
sudo tail -n 50 /var/log/postgresql/postgresql-18-main.log

# Try manual start to see errors
sudo -u postgres /usr/lib/postgresql/18/bin/postgres -D /data/postgres-18

# Remove stale lock files if needed
sudo rm -f /data/postgres-18/postmaster.pid
sudo rm -f /var/run/postgresql/.s.PGSQL.*
sudo rm -f /var/run/postgresql/18-main.pid
```

**⚠️ GOTCHA:** If you get "could not open file PG_VERSION: Permission denied" even with correct permissions, it's likely an AppArmor issue (see Section 6).

---

## 4. SSL and Permission Fixes

### Add PostgreSQL User to SSL Certificate Group

```bash
sudo gpasswd -a postgres ssl-cert
groups postgres
```

### Verify SSL Key Permissions

```bash
# Check permissions
sudo ls -la /etc/ssl/private/ssl-cert-snakeoil.key

# Should show: -rw-r----- 1 root ssl-cert

# Fix if needed
sudo chown root:ssl-cert /etc/ssl/private/ssl-cert-snakeoil.key
sudo chmod 640 /etc/ssl/private/ssl-cert-snakeoil.key
```

### Test SSL Key Access

```bash
# Test if postgres can read the key
sudo -u postgres cat /etc/ssl/private/ssl-cert-snakeoil.key > /dev/null 2>&1 && echo "Can read" || echo "Cannot read"
```

**⚠️ GOTCHA:** Even with correct filesystem permissions, AppArmor may block SSL key access. You'll need to add rules to the AppArmor profile (see Section 11).

### Alternative: Disable SSL (Quick Fix)

If you don't need SSL encryption:

```bash
sudo nano /etc/postgresql/18/main/postgresql.conf
# Change: ssl = on  to  ssl = off
```

---

## 5. Shared Memory Configuration

### Fix Shared Memory Issues

PostgreSQL may fail with "could not open shared memory segment" errors.

#### Solution A: Check /dev/shm Permissions

```bash
# Check current permissions
ls -ld /dev/shm

# Fix if needed (should be 1777)
sudo chmod 1777 /dev/shm
df -h /dev/shm
```

#### Solution B: Disable RemoveIPC in systemd

```bash
sudo mkdir -p /etc/systemd/system/postgresql@18-main.service.d/
sudo tee /etc/systemd/system/postgresql@18-main.service.d/override.conf << 'EOF'
[Service]
RemoveIPC=no
EOF

sudo systemctl daemon-reload
```

#### Solution C: Change dynamic_shared_memory_type

```bash
sudo nano /etc/postgresql/18/main/postgresql.conf
# Add or change:
dynamic_shared_memory_type = mmap
```

**⚠️ GOTCHA:** On Ubuntu, systemd's `RemoveIPC=yes` can delete PostgreSQL's shared memory segments. This is a common cause of mysterious failures.

---

## 6. AppArmor Configuration

### The Critical Issue: Conflicting Profiles

The most common problem is having old PostgreSQL 16 AppArmor profiles still loaded:

```bash
# Check for conflicting profiles
sudo aa-status | grep postgres
```

If you see both version 16 and 18 profiles, remove the old one:

```bash
# Remove PostgreSQL 16 AppArmor profile
sudo apparmor_parser -R /etc/apparmor.d/usr.lib.postgresql.16.main 2>/dev/null
sudo rm -f /etc/apparmor.d/usr.lib.postgresql.16.main
```

### Create PostgreSQL 18 AppArmor Profile

```bash
sudo tee /etc/apparmor.d/usr.lib.postgresql.18.main << 'EOF'
#include <tunables/global>

/usr/lib/postgresql/18/bin/postgres {
    #include <abstractions/base>
    #include <abstractions/nameservice>
    #include <abstractions/ssl_certs>
    
    # Capabilities
    capability dac_override,
    capability dac_read_search,
    capability ipc_lock,
    capability ipc_owner,
    capability setgid,
    capability setuid,
    capability sys_resource,
    capability sys_nice,
    
    # Data directory
    /data/ r,
    /data/postgres-18/ r,
    /data/postgres-18/** rwk,
    
    # PostgreSQL binaries and libraries
    /usr/lib/postgresql/18/bin/** mr,
    /usr/lib/postgresql/18/lib/*.so mr,
    
    # Configuration files
    /etc/postgresql/** r,
    /etc/postgresql/18/** r,
    /etc/postgresql/18/main/postgresql.conf r,
    /etc/postgresql/18/main/pg_hba.conf r,
    
    # SSL certificate access - CRITICAL
    /etc/ssl/private/ssl-cert-snakeoil.key r,
    /etc/ssl/private/ r,
    /etc/ssl/certs/ssl-cert-snakeoil.pem r,
    
    # Socket directory - CRITICAL for startup
    /run/postgresql/ rw,
    /run/postgresql/** rwk,
    /var/run/postgresql/ rw,
    /var/run/postgresql/** rwk,
    /run/postgresql/.s.PGSQL.5432 rw,
    /run/postgresql/.s.PGSQL.5432.lock rwk,
    
    # System directories
    /sys/devices/system/node/ r,
    /usr/share/postgresql/** r,
    /usr/share/zoneinfo/** r,
    /usr/share/locale/** r,
    /usr/lib/locale/** r,
    
    # Logs
    /var/log/postgresql/** rw,
    
    # Temporary files and shared memory
    /tmp/** rw,
    /dev/shm/** rw,
    
    # System resources
    /dev/urandom r,
    /dev/random r,
    /dev/null rw,
    /dev/pts/* rw,
}
EOF
```

### Load and Test the Profile

```bash
# Load the profile
sudo apparmor_parser -r /etc/apparmor.d/usr.lib.postgresql.18.main

# First set to complain mode (logs but doesn't block)
sudo aa-complain /usr/lib/postgresql/18/bin/postgres

# Verify it's loaded
sudo aa-status | grep postgres

# Restart PostgreSQL
sudo systemctl restart postgresql@18-main

# Check for any denials
sudo journalctl -u apparmor | grep -i postgres | grep -i denied | tail -n 30
```

### Switch to Enforce Mode

If no denials appear in complain mode:

```bash
sudo aa-enforce /usr/lib/postgresql/18/bin/postgres
sudo systemctl restart postgresql@18-main
```

**⚠️ GOTCHA:** Always test in complain mode first. The profile works in complain mode but fails in enforce mode if any paths are missing.

**⚠️ GOTCHA:** If you change PostgreSQL's port, update the socket lines in the profile (`.s.PGSQL.5432`) to match your port.

---

## 7. Port Configuration

### Check Current Port

```bash
# Check what port your cluster is using
pg_lsclusters

# Check PostgreSQL's actual port
sudo -u postgres psql -c "SHOW port;"
```

### Change the Port

```bash
# Stop the cluster
sudo pg_ctlcluster 18 main stop

# Edit the configuration
sudo nano /etc/postgresql/18/main/postgresql.conf
# Find and change: port = 5433  to  port = 5432
```

### Update AppArmor Profile for New Port

If you change the port, update the AppArmor profile:

```bash
sudo nano /etc/apparmor.d/usr.lib.postgresql.18.main
# Change socket lines to match new port:
# /run/postgresql/.s.PGSQL.5432 rw,
# /run/postgresql/.s.PGSQL.5432.lock rwk,

sudo apparmor_parser -r /etc/apparmor.d/usr.lib.postgresql.18.main
```

### Start with New Port

```bash
sudo pg_ctlcluster 18 main start
pg_lsclusters
```

**⚠️ GOTCHA:** After changing the port, the service may fail to start if the AppArmor profile still has rules for the old port. Always update both together.

---

## 8. User and Database Creation

### Create Database User

```bash
sudo -u postgres psql -c "CREATE USER symphony_admin WITH PASSWORD 'symphony_pass';"
```

### Create Database

```bash
sudo -u postgres psql -c "CREATE DATABASE symphony OWNER symphony_admin;"
```

### Grant Privileges

```bash
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE symphony TO symphony_admin;"
```

### Verify Creation

```bash
# List users
sudo -u postgres psql -c "\du"

# List databases
sudo -u postgres psql -c "\l"
```

---

## 9. Environment Variable Setup

### Create .env File

```bash
cd ~/workspace/Symphony  # or your project directory
nano .env
```

Add these lines:
```env
# Database configuration for PostgreSQL 18
DATABASE_URL=postgresql://symphony_admin:symphony_pass@localhost:5432/symphony

# Application settings
CI=false
PHASE=1
```

### Secure the .env File

```bash
# Restrict permissions
chmod 600 .env

# Add to .gitignore
echo ".env" >> .gitignore
```

### Load and Test Environment Variables

```bash
# Load the .env file
set -a
source .env
set +a

# Test the connection
psql "$DATABASE_URL" << EOF
SELECT 'Connection from .env file successful!' as message;
EOF
```

### Bash History Expansion Issue

The `!` character in SQL queries can cause "event not found" errors. Use these workarounds:

```bash
# Fix 1: Disable history expansion temporarily
set +H
psql "$DATABASE_URL" -c "SELECT 'Connection successful!' as message;"
set -H

# Fix 2: Use heredoc (recommended)
psql "$DATABASE_URL" << EOF
SELECT 'Connection successful!' as message;
EOF

# Fix 3: Escape the exclamation mark
psql "$DATABASE_URL" -c "SELECT 'Connection successful\!' as message;"

# Fix 4: Add to .bashrc permanently
echo "set +H" >> ~/.bashrc
source ~/.bashrc
```

---

## 10. Troubleshooting Gotchas

### Gotcha 1: "Permission denied" on Data Directory

**Problem:** `initdb` or PostgreSQL fails with permission denied.
**Solution:** Check parent directory permissions and ownership:
```bash
sudo chown postgres:postgres /data/postgres-18
sudo chmod 700 /data/postgres-18
ls -ld /data  # Should be readable by postgres
```

### Gotcha 2: "Assertion failed on job" when starting service

**Problem:** systemd fails to start PostgreSQL with assertion error.
**Solution:** The cluster doesn't exist or is misconfigured:
```bash
pg_lsclusters  # Check if cluster exists
sudo pg_createcluster 18 main  # Create if missing
```

### Gotcha 3: Conflicting AppArmor Profiles

**Problem:** AppArmor errors or PostgreSQL fails in enforce mode.
**Solution:** Remove old PostgreSQL 16 profiles:
```bash
sudo aa-status | grep postgres
sudo apparmor_parser -R /etc/apparmor.d/usr.lib.postgresql.16.main
sudo rm -f /etc/apparmor.d/usr.lib.postgresql.16.main
```

### Gotcha 4: "could not load private key file" SSL Errors

**Problem:** PostgreSQL can't read SSL certificate key.
**Solution:** Add postgres to ssl-cert group AND update AppArmor:
```bash
sudo gpasswd -a postgres ssl-cert
# Add to AppArmor profile:
# /etc/ssl/private/ssl-cert-snakeoil.key r,
```

### Gotcha 5: Socket File Permission Denied

**Problem:** PostgreSQL can't create `/var/run/postgresql/.s.PGSQL.5432.lock`.
**Solution:** Fix directory permissions and AppArmor:
```bash
sudo chown postgres:postgres /var/run/postgresql/
sudo chmod 775 /var/run/postgresql/
# Ensure AppArmor has: /run/postgresql/** rwk,
```

### Gotcha 6: Port Mismatch After Change

**Problem:** After changing port in postgresql.conf, service fails.
**Solution:** Update AppArmor profile to match new port:
```bash
# Edit AppArmor profile, change 5433 to 5432 in socket lines
sudo apparmor_parser -r /etc/apparmor.d/usr.lib.postgresql.18.main
```

### Gotcha 7: Bash "event not found" with Exclamation Marks

**Problem:** `!` in SQL queries causes history expansion errors.
**Solution:** Use heredoc or disable history expansion:
```bash
psql "$DATABASE_URL" << EOF
SELECT 'Connection successful!' as message;
EOF
```

### Gotcha 8: Cluster Shows "online" but PostgreSQL Not Running

**Problem:** `pg_lsclusters` shows online but `ps aux | grep postgres` shows nothing.
**Solution:** Force stop and restart:
```bash
sudo pg_ctlcluster 18 main stop --force
sudo pg_ctlcluster 18 main start
```

---

## 11. Complete AppArmor Profile

Here's the complete, working AppArmor profile for PostgreSQL 18 (port 5432):

```apparmor
#include <tunables/global>

/usr/lib/postgresql/18/bin/postgres {
    #include <abstractions/base>
    #include <abstractions/nameservice>
    #include <abstractions/ssl_certs>
    
    # Capabilities
    capability dac_override,
    capability dac_read_search,
    capability ipc_lock,
    capability ipc_owner,
    capability setgid,
    capability setuid,
    capability sys_resource,
    capability sys_nice,
    
    # Data directory
    /data/ r,
    /data/postgres-18/ r,
    /data/postgres-18/** rwk,
    
    # PostgreSQL binaries and libraries
    /usr/lib/postgresql/18/bin/** mr,
    /usr/lib/postgresql/18/lib/*.so mr,
    
    # Configuration files
    /etc/postgresql/** r,
    /etc/postgresql/18/** r,
    /etc/postgresql/18/main/postgresql.conf r,
    /etc/postgresql/18/main/pg_hba.conf r,
    
    # SSL certificate access - CRITICAL
    /etc/ssl/private/ssl-cert-snakeoil.key r,
    /etc/ssl/private/ r,
    /etc/ssl/certs/ssl-cert-snakeoil.pem r,
    
    # Socket directory - CRITICAL for startup
    /run/postgresql/ rw,
    /run/postgresql/** rwk,
    /var/run/postgresql/ rw,
    /var/run/postgresql/** rwk,
    /run/postgresql/.s.PGSQL.5432 rw,
    /run/postgresql/.s.PGSQL.5432.lock rwk,
    
    # System directories
    /sys/devices/system/node/ r,
    /usr/share/postgresql/** r,
    /usr/share/zoneinfo/** r,
    /usr/share/locale/** r,
    /usr/lib/locale/** r,
    
    # Logs
    /var/log/postgresql/** rw,
    
    # Temporary files and shared memory
    /tmp/** rw,
    /dev/shm/** rw,
    
    # System resources
    /dev/urandom r,
    /dev/random r,
    /dev/null rw,
    /dev/pts/* rw,
}
```

**⚠️ GOTCHA:** If you change your PostgreSQL port, update the socket lines (`.s.PGSQL.5432`) to match your new port number.

---

## 12. Command Reference

| **Task** | **Command** |
|----------|-------------|
| Check PostgreSQL version | `pg_lsclusters` |
| Check cluster status | `sudo pg_ctlcluster 18 main status` |
| Start cluster | `sudo pg_ctlcluster 18 main start` |
| Stop cluster | `sudo pg_ctlcluster 18 main stop` |
| Restart cluster | `sudo pg_ctlcluster 18 main restart` |
| Create new cluster | `sudo pg_createcluster 18 main -d /path/to/data` |
| Drop cluster | `sudo pg_dropcluster 18 main --stop` |
| Connect to PostgreSQL | `sudo -u postgres psql` |
| Connect as specific user | `psql -h localhost -p 5432 -U username -d dbname` |
| Check AppArmor status | `sudo aa-status \| grep postgres` |
| Set AppArmor to complain | `sudo aa-complain /usr/lib/postgresql/18/bin/postgres` |
| Set AppArmor to enforce | `sudo aa-enforce /usr/lib/postgresql/18/bin/postgres` |
| Reload AppArmor profile | `sudo apparmor_parser -r /etc/apparmor.d/usr.lib.postgresql.18.main` |
| Check PostgreSQL logs | `sudo tail -f /var/log/postgresql/postgresql-18-main.log` |
| Check AppArmor denials | `sudo journalctl -u apparmor \| grep -i denied` |
| List databases | `sudo -u postgres psql -c "\l"` |
| List users | `sudo -u postgres psql -c "\du"` |
| Create database | `sudo -u postgres createdb dbname` |
| Create user | `sudo -u postgres psql -c "CREATE USER username WITH PASSWORD 'password';"` |
| Test connection with .env | `psql "$DATABASE_URL" -c "SELECT current_database();"` |

---

## 13. Final Verification

Run these commands to confirm your PostgreSQL 18 installation is fully functional:

```bash
# 1. Check cluster status
pg_lsclusters
# Expected: 18  main    5432 online postgres /data/postgres-18 /var/log/postgresql/postgresql-18-main.log

# 2. Check PostgreSQL is running
sudo systemctl status postgresql@18-main --no-pager -l

# 3. Check PostgreSQL version
sudo -u postgres psql -c "SELECT version();"

# 4. Check data directory
sudo -u postgres psql -c "SHOW data_directory;"

# 5. Check port
sudo -u postgres psql -c "SHOW port;"

# 6. List databases
sudo -u postgres psql -c "\l"

# 7. List users
sudo -u postgres psql -c "\du"

# 8. Check AppArmor status
sudo aa-status | grep -A5 "postgres"

# 9. Test connection with your user
PGPASSWORD=symphony_pass psql -h localhost -p 5432 -U symphony_admin -d symphony -c "SELECT 'Connection successful!' as message;" << EOF
SELECT 'Connection successful!' as message;
EOF

# 10. Test with DATABASE_URL from .env
set -a
source .env 2>/dev/null || echo "No .env file found"
set +a
psql "$DATABASE_URL" << EOF
SELECT 'DATABASE_URL connection successful!' as message;
EOF
```

---

## Final Working Configuration

After following this guide, your working setup should be:

| Component | Value |
|-----------|-------|
| **PostgreSQL Version** | 18.2 |
| **Data Directory** | `/data/postgres-18` |
| **Port** | 5432 |
| **Configuration File** | `/etc/postgresql/18/main/postgresql.conf` |
| **AppArmor Profile** | `/etc/apparmor.d/usr.lib.postgresql.18.main` |
| **AppArmor Mode** | Enforce |
| **Socket Directory** | `/var/run/postgresql` |
| **Database User** | `symphony_admin` |
| **Database Name** | `symphony` |
| **Connection URL** | `postgresql://symphony_admin:symphony_pass@localhost:5432/symphony` |

All major "gotchas" have been addressed and documented for future reference!