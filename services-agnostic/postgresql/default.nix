{createManagedProcess, lib, postgresql, su, stateDir, runtimeDir, forceDisableUserChange}:

{ port ? 5432
, instanceSuffix ? ""
, instanceName ? "postgresql${instanceSuffix}"
, configFile ? null
, postInstall ? ""
}:

let
  postgresqlStateDir = "${stateDir}/db/${instanceName}";
  dataDir = "${postgresqlStateDir}/data";
  socketDir = "${runtimeDir}/${instanceName}";

  user = instanceName;
  group = instanceName;
in
createManagedProcess rec {
  name = instanceName;
  inherit instanceName user postInstall;
  path = [ postgresql su ];
  initialize = ''
    mkdir -m0755 -p ${socketDir}
    mkdir -m0700 -p ${dataDir}

    ${lib.optionalString (!forceDisableUserChange) ''
      chown ${user}:${group} ${socketDir}
      chown ${user}:${group} ${dataDir}
    ''}

    if [ ! -e "${dataDir}/PG_VERSION" ]
    then
        ${lib.optionalString (!forceDisableUserChange) "su ${user} -c '"}${postgresql}/bin/initdb -D ${dataDir} --no-locale${lib.optionalString (!forceDisableUserChange) "'"}
    fi

    ${lib.optionalString (configFile != null) ''
      ln -sfn ${configFile} ${dataDir}/postgresql.conf
    ''}
  '';

  foregroundProcess = "${postgresql}/bin/postgres";
  args = [ "-D" dataDir "-p" port "-k" socketDir ];
  environment = {
    PGDATA = dataDir;
  };

  credentials = {
    groups = {
      "${group}" = {};
    };
    users = {
      "${user}" = {
        homeDir = postgresqlStateDir;
        createHomeDir = true;
        inherit group;
        description = "PostgreSQL user";
      };
    };
  };

  overrides = {
    sysvinit = {
      runlevels = [ 3 4 5 ];
    };
  };
}
