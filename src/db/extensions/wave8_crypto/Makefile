# Wave 8 Crypto Extension Makefile
# PGXS-only build contract for TSK-P2-W8-SEC-002
# PostgreSQL 18 + libsodium hardening flags

EXTENSION = wave8_crypto
MODULE_big = wave8_crypto
OBJS = wave8_crypto.o
DATA = wave8_crypto--1.0.sql

# Pinned PostgreSQL 18 configuration
PG_CONFIG = /usr/lib/postgresql/18/bin/pg_config

# Compiler hardening flags (no manual -I/usr/include - let PGXS handle include paths)
PG_CPPFLAGS += -Wall -Wextra -Werror -O2 -fPIC

# Linker hardening flags with libsodium (dynamic linking)
# Force DT_NEEDED for libsodium by requiring sodium_init symbol
SHLIB_LINK += -Wl,-u,sodium_init -Wl,--no-as-needed -lsodium -Wl,-z,relro -Wl,-z,now

# PGXS build system
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
