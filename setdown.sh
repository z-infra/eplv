#!/usr/bin/env sh

echo 'stoping postgres ...'
pg_ctl -D $PGDATA stop
cd $PWD
echo 'removing $NIX_SHELL_DIR ...'
rm -rf $NIX_SHELL_DIR
echo 'end of cleaning'
