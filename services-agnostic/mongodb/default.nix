{createManagedProcess, mongodb, tmpDir}:

{ instanceSuffix ? ""
, instanceName ? "mongodb${instanceSuffix}"
, configFile
, initialize ? ""
, postInstall ? ""
}:

let
  user = instanceName;
  group = instanceName;
  pidFile = "${tmpDir}/${instanceName}.pid";
in
createManagedProcess {
  inherit instanceName initialize pidFile postInstall;

  process = "${mongodb}/bin/mongod";
  args = [ "--config" configFile ];
  daemonExtraArgs = [ "--fork" "--pidfilepath" pidFile ];
  user = instanceName;

  credentials = {
    groups = {
      "${group}" = {};
    };
    users = {
      "${user}" = {
        inherit group;
        description = "MongoDB user";
      };
    };
  };

  overrides = {
    sysvinit = {
      runlevels = [ 3 4 5 ];
    };
  };
}
