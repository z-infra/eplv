{ pkgs }:
with pkgs;
with builtins;

mkShell {
  buildInputs = [ elixir_1_15 nodejs_20 postgresql_15 git fish ]
    ++ (if stdenv.isLinux then [ inotify-tools ] else [ ]);
  shellHook = ''
    # Artifacts folder
    mkdir -p .nix-shell
    export NIX_SHELL_DIR=$PWD/.nix-shell

    # PG data folder
    export PGDATA=$NIX_SHELL_DIR/db

    # Export psql envs default
    PGDATABASE=postgres
    PGHOST=$PGDATA

    # Mix files
    export MIX_HOME="$NIX_SHELL_DIR/.mix"
    export MIX_ARCHIVES="$MIX_HOME/archives"

    # Stop postgres and clean up on exit
    trap \
      "
        echo 'stoping postgres ...'
        pg_ctl -D $PGDATA stop
        cd $PWD
        echo 'removing $NIX_SHELL_DIR ...'
        rm -rf $NIX_SHELL_DIR
        echo 'end of cleaning'
      " \
      EXIT

    # initialize postgres if it's not created
    if ! test -d $PGDATA
    then
      pg_ctl initdb -D  $PGDATA
      # sed -i "s|^#port.*$|port = 5433|" $PGDATA/postgresql.conf
    fi

    # start postgres
    host_common="host\s\+all\s\+all"
    sed -i "s|^$host_common.*127.*$|host all all 0.0.0.0/0 trust|" $PGDATA/pg_hba.conf
    sed -i "s|^$host_common.*::1.*$|host all all ::/0 trust|"      $PGDATA/pg_hba.conf

    pg_ctl                                                  \
      -D $PGDATA                                            \
      -l $PGDATA/postgres.log                               \
      -o "-c unix_socket_directories='$PGDATA'"             \
      -o "-c listen_addresses='*'"                          \
      -o "-c log_destination='stderr'"                      \
      -o "-c logging_collector=on"                          \
      -o "-c log_directory='log'"                           \
      -o "-c log_filename='postgresql-%y-%m-%d_%h%m%s.log'" \
      -o "-c log_min_messages=info"                         \
      -o "-c log_min_error_statement=info"                  \
      -o "-c log_connections=on"                            \
      start


    # nodejs dependencies
    if test -d "$PWD/assets/" && ! test -d "$PWD/assets/node_modules/"
    then
      (cd assets && npm install)
    fi

    # ensure $MIX_HOME is created
    if ! test -d $MIX_HOME
    then
      # verify if it has backup folder
      if test -d "$PWD/_backup"
      then
        cp -r _backup/.mix .nix-shell/
      else
        yes | mix local.hex
        yes | mix archive.install hex phx_new
      fi
    fi

    if test -f "mix.exs"
    then
      mix deps.get
      mix ecto.setup
    fi

    # use fish as default shell
    ${pkgs.fish}/bin/fish
  '';

  LOCALE_ARCHIVE = if pkgs.stdenv.isLinux then
    "${pkgs.glibcLocales}/lib/locale/locale-archive"
  else
    "";
}
