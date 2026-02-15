Here's a comprehensive list of all commands and configurations we used during this PostgreSQL + AppArmor troubleshooting session:

## Initial AppArmor Profile Creation & Fixes

```bash
# Initial error - fixing malformed profile
sudo nano /etc/apparmor.d/usr.lib.postgresql.16.main
sudo apparmor_parser -r /etc/apparmor.d/usr.lib.postgresql.16.main

# Fixed duplicate content in profile
sudo cat -n /etc/apparmor.d/usr.lib.postgresql.16.main
sudo nano /etc/apparmor.d/usr.lib.postgresql.16.main

# Removed broken backup file
sudo rm /etc/apparmor.d/usr.lib.postgresql.16.main.BROKEN.20260214T190135Z

# Check AppArmor status and errors
sudo systemctl status apparmor
sudo journalctl -xeu apparmor.service
sudo apparmor_parser -R /etc/apparmor.d/ 2>&1 | head -20
sudo aa-status
sudo aa-status | grep postgres
```

## PostgreSQL Service Diagnostics

```bash
# Check PostgreSQL status
sudo systemctl status postgresql
sudo systemctl status postgresql@16-main.service

# Check PostgreSQL processes
ps aux | grep postgres

# Check PostgreSQL logs
sudo tail -n 50 /var/log/postgresql/postgresql-16-main.log
sudo journalctl -u postgresql@16-main.service -n 50

# Check socket directory
ls -la /var/run/postgresql/

# Manual PostgreSQL start attempts
sudo -u postgres /usr/lib/postgresql/16/bin/postgres -D /var/lib/postgresql/16/main
sudo -u postgres /usr/lib/postgresql/16/bin/postgres -D /data/postgres --config-file=/etc/postgresql/16/main/postgresql.conf

# Using Ubuntu's PostgreSQL management tools
sudo pg_ctlcluster 16 main start
sudo pg_ctlcluster 16 main status
sudo pg_lsclusters
```

## Data Directory Configuration

```bash
# Check data directory
ls -la /data/
ls -la /data/postgres/
sudo -u postgres ls -la /data/postgres/
sudo -u postgres cat /data/postgres/PG_VERSION

# Fix data directory permissions
sudo chown -R postgres:postgres /data/postgres
sudo chmod 700 /data/postgres
sudo chmod 755 /data

# Edit PostgreSQL configuration
sudo nano /etc/postgresql/16/main/postgresql.conf
sudo grep data_directory /etc/postgresql/16/main/postgresql.conf
```

## SSL Certificate Fixes

```bash
# Add postgres to ssl-cert group
sudo gpasswd -a postgres ssl-cert
groups postgres
id postgres

# Check SSL key permissions
sudo ls -la /etc/ssl/private/ssl-cert-snakeoil.key
sudo -u postgres cat /etc/ssl/private/ssl-cert-snakeoil.key > /dev/null 2>&1 && echo "Can read" || echo "Cannot read"

# Fix SSL key permissions
sudo chown root:ssl-cert /etc/ssl/private/ssl-cert-snakeoil.key
sudo chmod 640 /etc/ssl/private/ssl-cert-snakeoil.key

# Alternative: Disable SSL in PostgreSQL config
sudo nano /etc/postgresql/16/main/postgresql.conf
# Change ssl = on to ssl = off
```

## Shared Memory Fixes

```bash
# Check /dev/shm permissions
ls -ld /dev/shm
sudo chmod 1777 /dev/shm
df -h /dev/shm
sudo mount -o remount /dev/shm

# Check shared memory segments
sudo ipcs -m | grep postgres

# Create systemd override for RemoveIPC
sudo mkdir -p /etc/systemd/system/postgresql@16-main.service.d/
sudo nano /etc/systemd/system/postgresql@16-main.service.d/override.conf
# Added: [Service]\nRemoveIPC=no
sudo systemctl daemon-reload

# Change dynamic shared memory type
sudo nano /etc/postgresql/16/main/postgresql.conf
# Added: dynamic_shared_memory_type = mmap
```

## AppArmor Profile Development (Final Version)

```bash
# Edit AppArmor profile
sudo nano /etc/apparmor.d/usr.lib.postgresql.16.main

# Reload AppArmor
sudo systemctl reload apparmor
sudo apparmor_parser -R /etc/apparmor.d/usr.lib.postgresql.16.main
sudo apparmor_parser -a /etc/apparmor.d/usr.lib.postgresql.16.main

# Switch between enforce/complain modes
sudo aa-complain /usr/lib/postgresql/16/bin/postgres
sudo aa-enforce /usr/lib/postgresql/16/bin/postgres

# Check AppArmor denials
sudo journalctl -u apparmor | grep -i postgres | grep -i denied
sudo dmesg | grep -i apparmor | grep -i postgres
sudo tail -f /var/log/syslog | grep -i apparmor
```

## Final PostgreSQL Commands

```bash
# Start PostgreSQL manually
sudo -u postgres /usr/lib/postgresql/16/bin/postgres -D /data/postgres --config-file=/etc/postgresql/16/main/postgresql.conf

# Start via systemd
sudo systemctl start postgresql
sudo systemctl restart postgresql
sudo systemctl status postgresql

# Connect to PostgreSQL
sudo -u postgres psql -c "SHOW data_directory;"
sudo -u postgres psql -c "SELECT current_database();"
sudo -u postgres psql -h 127.0.0.1 -p 5432 -c "SHOW data_directory;"
```

## Final AppArmor Profile Content

```apparmor
#include <tunables/global>

/usr/lib/postgresql/16/bin/postgres {
    #include <abstractions/base>
    #include <abstractions/nameservice>
    #include <abstractions/ssl_certs>
    
    # Data directory access
    /data/ r,
    /data/postgres/ r,
    /data/postgres/** rwk,
    
    # PostgreSQL binaries and libraries
    /usr/lib/postgresql/16/bin/postgres mr,
    /usr/lib/postgresql/16/lib/*.so mr,
    
    # Configuration files
    /etc/postgresql/** r,
    /etc/postgresql/16/main/postgresql.conf r,
    /etc/postgresql/16/main/pg_hba.conf r,
    
    # SSL certificates
    /etc/ssl/private/ssl-cert-snakeoil.key r,
    /etc/ssl/private/ r,
    /etc/ssl/certs/ssl-cert-snakeoil.pem r,
    
    # System directories
    /usr/share/postgresql/** r,
    /usr/share/postgresql/16/** r,
    /usr/share/postgresql/16/timezonesets/** r,
    /usr/share/zoneinfo/** r,
    /usr/share/locale/** r,
    /usr/lib/locale/** r,
    
    # Lock file and socket permissions
    /var/run/postgresql/ rw,
    /var/run/postgresql/** rwk,
    /var/run/postgresql/.s.PGSQL.5432 rw,
    /var/run/postgresql/.s.PGSQL.5432.lock rwk,
    
    # Logs
    /var/log/postgresql/** rw,
    
    # Temporary files
    /tmp/.s.PGSQL.* rw,
    /tmp/** rw,
    
    # System resources
    /dev/urandom r,
    /dev/random r,
    /dev/null rw,
    /dev/pts/* rw,
    
    # Allow execution of helper programs
    /usr/bin/** rix,
}
```

## Systemd Override File Content

```ini
# File: /etc/systemd/system/postgresql@16-main.service.d/override.conf
[Service]
RemoveIPC=no
```

## Key Configuration Files Modified

1. **AppArmor Profile**: `/etc/apparmor.d/usr.lib.postgresql.16.main`
2. **PostgreSQL Config**: `/etc/postgresql/16/main/postgresql.conf`
3. **Systemd Override**: `/etc/systemd/system/postgresql@16-main.service.d/override.conf`

## Packages/Tools Used (All built-in to Ubuntu Server 24.04)

- `apparmor-utils` (aa-complain, aa-enforce, aa-status)
- `postgresql-16`
- `systemd`
- `openssl` (for SSL certificates)