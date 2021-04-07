{baseDir, hydraDatabase ? null, hydraUser ? null, dbi ? null}:

let
  _dbi = if dbi == null then "dbi:Pg:dbname=${hydraDatabase};user=${hydraUser};" else dbi;
in
{
  HYDRA_DBI = _dbi;
  HYDRA_CONFIG = "${baseDir}/hydra.conf";
  HYDRA_DATA = baseDir;
  NIX_REMOTE = "daemon";
  HOME = baseDir; # Add this to prevent the evaluator and queue runner to read from /root/.nix-defexpr
  PGPASSFILE = "${baseDir}/pgpass";
}
