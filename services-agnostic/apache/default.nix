{createManagedProcess, apacheHttpd, cacheDir}:

{ instanceSuffix ? ""
, instanceName ? "apache${instanceSuffix}"
, dependencies ? []
, configFile
, initialize ? ""
, environment ? {}
, postInstall ? ""
}:

let
  user = instanceName;
  group = instanceName;
in
createManagedProcess {
  inherit instanceName initialize dependencies environment postInstall;

  process = "${apacheHttpd}/bin/httpd";
  args = [ "-f" configFile ];
  foregroundProcessExtraArgs = [ "-DFOREGROUND" ];

  credentials = {
    groups = {
      "${group}" = {};
    };
    users = {
      "${user}" = {
        inherit group;
        homeDir = "${cacheDir}/${user}";
        description = "Apache HTTP daemon user";
      };
    };
  };

  overrides = {
    sysvinit = {
      runlevels = [ 3 4 5 ];
    };
  };
}
