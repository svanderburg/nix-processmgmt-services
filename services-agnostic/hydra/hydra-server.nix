{createManagedProcess, lib, writeTextFile, hydra, postgresql, su, libDir, forceDisableUserChange}:

{ instanceSuffix ? ""
, instanceName ? "hydra-server${instanceSuffix}"

, hydraInstanceName ? "hydra${instanceSuffix}"
, hydraDatabase ? hydraInstanceName
, hydraUser ? hydraInstanceName
, hydraGroup ? hydraInstanceName

, user ? "hydra-www${instanceSuffix}"
, listenHost ? "*"
, port ? 3000
, baseDir ? "${libDir}/${hydraInstanceName}"
, dbi ? null
, gcRootsDir ? "/nix/var/nix/gcroots/${hydraInstanceName}"
, hydraURL ? "http://localhost"
, notificationSender ? "root@localhost"
, logo ? null
, useSubstitutes ? true

, postgresqlDBMS ? null
, nix-daemon ? null
}:

let
  hydraConf = writeTextFile {
    name = "hydra.conf";
    text = ''
      using_frontend_proxy = 1
      base_uri = ${hydraURL}
      notification_sender = ${notificationSender}
      max_servers = 25
      compress_num_threads = 0
    ''
    + lib.optionalString (logo != null) ''
      hydra_logo = ${logo}
    ''
    + ''
      gc_roots_dir = ${gcRootsDir}
      use-substitutes = ${if useSubstitutes then "1" else "0"}
    '';
  };
in
createManagedProcess {
  inherit instanceName user;

  path = [ postgresql su ];

  initialize = ''
    ln -sfn ${hydraConf} ${baseDir}/hydra.conf
    chmod 750 ${baseDir}

    mkdir -m 0700 -p ${baseDir}/www
    mkdir -p ${gcRootsDir}
  ''
  + lib.optionalString (!forceDisableUserChange) ''
    chown ${user}:${hydraGroup} ${baseDir}/www
    chown ${hydraUser}:${hydraGroup} ${gcRootsDir}
  ''
  + ''
    chmod 2775 ${gcRootsDir}
  ''
  # Initialize the database if a PostgreSQL DBMS is provided as a (local) process dependency
  + lib.optionalString (postgresqlDBMS != null) ''
    if [ ! -e ${baseDir}/.db-created ]
    then
        count=1

        while [ ! -e ${postgresqlDBMS.socketFile} ] && [ $count -lt 10 ]
        do
            sleep 1
            ((count++))
        done

        ${lib.optionalString (!forceDisableUserChange) "su ${postgresqlDBMS.postgresqlUsername} -c '"}${postgresql}/bin/createuser ${hydraUser}${lib.optionalString (!forceDisableUserChange) "'"}
        ${lib.optionalString (!forceDisableUserChange) "su ${postgresqlDBMS.postgresqlUsername} -c '"}${postgresql}/bin/createdb -O ${hydraUser} ${hydraDatabase}${lib.optionalString (!forceDisableUserChange) "'"}
        echo "create extension if not exists pg_trgm" | ${lib.optionalString (!forceDisableUserChange) "su ${postgresqlDBMS.postgresqlUsername} -c '"}${postgresql}/bin/psql ${hydraDatabase}${lib.optionalString (!forceDisableUserChange) "'"}
        touch ${baseDir}/.db-created
    fi
  ''
  + ''
    ${hydra}/bin/hydra-init
  '';
  foregroundProcess = "${hydra}/bin/hydra-server";
  args = [ "hydra-server" "-f" "-h" listenHost "-p" port "--max_spare_servers" 5 "--max_servers" 25 ];

  environment = import ./generate-env-vars.nix {
    inherit baseDir dbi hydraDatabase hydraUser;
  };

  dependencies = lib.optional (nix-daemon != null) nix-daemon.pkg
    ++ lib.optional (postgresqlDBMS != null) postgresqlDBMS.pkg;

  credentials = {
    groups = {
      "${hydraGroup}" = {};
    };
    users = {
      "${hydraUser}" = {
        group = hydraGroup;
        description = "Hydra user";
        createHomeDir = true;
        homeDir = baseDir;
        shell = "/bin/sh";
      };
      "${user}" = {
        group = hydraGroup;
        description = "Hydra server user";
      };
    };
  };

  overrides = {
    sysvinit = {
      runlevels = [ 3 4 5 ];
    };
    systemd = {
      Service.Restart = "always";
    };
  };
}
