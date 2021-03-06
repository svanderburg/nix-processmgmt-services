{createManagedProcess, influxdb, libDir}:

{ instanceSuffix ? ""
, instanceName ? "influxdb${instanceSuffix}"
, configFile
, postInstall ? ""
}:

let
  user = instanceName;
  group = instanceName;

  influxdbStateDir = "${libDir}/${instanceName}";
in
createManagedProcess {
  inherit instanceName user postInstall;
  foregroundProcess = "${influxdb}/bin/influxd";
  args = [ "-config" configFile ];

  credentials = {
    groups = {
      "${group}" = {};
    };
    users = {
      "${user}" = {
        homeDir = influxdbStateDir;
        createHomeDir = true;
        inherit group;
        description = "InfluxDB user";
      };
    };
  };

  overrides = {
    sysvinit = {
      runlevels = [ 3 4 5 ];
    };
  };
}
