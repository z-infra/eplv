#!/usr/bin/env sh

# initialize postgres if it's not created
if ! test -d $PGDATA; then
    pg_ctl initdb -D $PGDATA
    # sed -i "s|^#port.*$|port = 5433|" $PGDATA/postgresql.conf
else
    exit 0
fi

# Artifacts folder
mkdir -p .nix-shell

# start postgres
host_common="host\s\+all\s\+all"
sed -i "s|^$host_common.*127.*$|host all all 0.0.0.0/0 trust|" $PGDATA/pg_hba.conf
sed -i "s|^$host_common.*::1.*$|host all all ::/0 trust|" $PGDATA/pg_hba.conf

pg_ctl \
    -D $PGDATA \
    -l $PGDATA/postgres.log \
    -o "-c unix_socket_directories='$PGDATA'" \
    -o "-c listen_addresses='*'" \
    -o "-c log_destination='stderr'" \
    -o "-c logging_collector=on" \
    -o "-c log_directory='log'" \
    -o "-c log_filename='postgresql-%y-%m-%d_%h%m%s.log'" \
    -o "-c log_min_messages=info" \
    -o "-c log_min_error_statement=info" \
    -o "-c log_connections=on" \
    start

# nodejs dependencies
if test -d "$PWD/assets/" && ! test -d "$PWD/assets/node_modules/"; then
    (cd assets && npm install)
fi

# ensure $MIX_HOME is created
if ! test -d $MIX_HOME; then
    # verify if it has backup folder
    if test -d "$PWD/_backup"; then
        cp -r _backup/.mix .nix-shell/
    else
        yes | mix local.hex
        yes | mix archive.install hex phx_new
    fi
fi

if test -f "mix.exs"; then
    mix deps.get
    mix ecto.setup
fi
