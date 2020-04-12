{createManagedProcess, stdenv, apacheHttpd, writeTextFile, logDir, runtimeDir, forceDisableUserChange}:
{instanceSuffix ? "", port ? 80, modules ? [], serverName ? "localhost", serverAdmin, documentRoot ? ./webapp, extraConfig ? "", postInstall ? ""}:

let
  instanceName = "httpd${instanceSuffix}";
  user = instanceName;
  group = instanceName;

  baseModules = [
    "mpm_prefork"
    "authn_file"
    "authn_core"
    "authz_host"
    "authz_groupfile"
    "authz_user"
    "authz_core"
    "access_compat"
    "auth_basic"
    "reqtimeout"
    "filter"
    "mime"
    "log_config"
    "env"
    "headers"
    "setenvif"
    "version"
    "unixd"
    "status"
    "autoindex"
    "alias"
    "dir"
  ];

  apacheLogDir = "${logDir}/${instanceName}";
in
import ./apache.nix {
  inherit createManagedProcess apacheHttpd;
} {
  inherit instanceSuffix postInstall;

  initialize = ''
    mkdir -m0700 -p ${apacheLogDir}

    ${stdenv.lib.optionalString (!forceDisableUserChange) ''
      chown ${user}:${group} ${apacheLogDir}
    ''}

    if [ ! -e "${documentRoot}" ]
    then
        mkdir -p "${documentRoot}"
        ${stdenv.lib.optionalString (!forceDisableUserChange) ''
          chown ${user}:${group} ${documentRoot}
        ''}
    fi
  '';

  configFile = writeTextFile {
    name = "httpd.conf";
    text = ''
      ErrorLog "${apacheLogDir}/error_log"
      PidFile "${runtimeDir}/${instanceName}.pid"

      ${stdenv.lib.optionalString (!forceDisableUserChange) ''
        User ${user}
        Group ${group}
      ''}

      ServerName ${serverName}
      ServerRoot ${apacheHttpd}

      Listen ${toString port}

      ${stdenv.lib.concatMapStrings (module: ''
        LoadModule ${module}_module ${apacheHttpd}/modules/mod_${module}.so
      '') baseModules}
      ${stdenv.lib.concatMapStrings (module: ''
        LoadModule ${module.name}_module ${module.module}
      '') modules}

      ServerAdmin ${serverAdmin}

      DocumentRoot "${documentRoot}"

      ${extraConfig}
    '';
  };
}