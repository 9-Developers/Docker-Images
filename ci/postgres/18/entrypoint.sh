#!/bin/sh
set -eu

if [ "$1" != postgres ]; then
	exec "$@"
fi

if [ ! -s "$PGDATA/PG_VERSION" ]; then
	: "${POSTGRES_USER:=postgres}" "${POSTGRES_PASSWORD:?Set POSTGRES_PASSWORD for first startup}"
	: "${POSTGRES_DB:=$POSTGRES_USER}"
	pwfile=$(mktemp)
	trap 'rm -f "$pwfile"' EXIT
	printf '%s\n' "$POSTGRES_PASSWORD" >"$pwfile"
	initdb -D "$PGDATA" \
		--username="$POSTGRES_USER" --pwfile="$pwfile" \
		--auth-local=trust --auth-host=scram-sha-256 --locale=C --encoding=UTF8
	rm -f "$pwfile"
	trap - EXIT

	if [ "$POSTGRES_DB" != postgres ]; then
		# Bootstrap over a private socket before accepting network connections.
		socket=$(mktemp -d)
		pg_ctl -D "$PGDATA" -o "-k $socket -c listen_addresses=''" -w start
		trap 'pg_ctl -D "$PGDATA" -m fast -w stop; rmdir "$socket"' EXIT
		createdb -h "$socket" -U "$POSTGRES_USER" -- "$POSTGRES_DB"
		pg_ctl -D "$PGDATA" -m fast -w stop
		trap - EXIT
		rmdir "$socket"
	fi
	printf '\nhost all all all scram-sha-256\n' >>"$PGDATA/pg_hba.conf"
fi

shift
exec postgres -D "$PGDATA" -c 'listen_addresses=*' "$@"
