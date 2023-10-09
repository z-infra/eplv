{ pkgs }:
with pkgs;
with builtins;

mkShell {
  buildInputs = [ elixir_1_15 nodejs_20 postgresql_15 git ]
    ++ (if stdenv.isLinux || stdenv.isCygwin then [ inotify-tools ] else [ ]);
  shellHook = ''
    # Artifacts folder
    export NIX_SHELL_DIR=$PWD/.nix-shell

    # PG data folder
    export PGDATA=$NIX_SHELL_DIR/db

    # Export psql envs default
    export PGUSER=$USER
    # export PGPASSWORD=postgres
    export PGDATABASE=postgres
    export PGHOST=$PGDATA

    # Mix files
    export MIX_HOME="$NIX_SHELL_DIR/.mix"
    export MIX_ARCHIVES="$MIX_HOME/archives"

    $PWD/setup.sh
  '';

  LOCALE_ARCHIVE = if pkgs.stdenv.isLinux then
    "${pkgs.glibcLocales}/lib/locale/locale-archive"
  else
    "";
}
