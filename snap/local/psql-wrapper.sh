#!/bin/sh
#xec "$SNAP/usr/bin/psql" "$@"
exec "$SNAP/usr/lib/postgresql/17/bin/psql" "$@"
