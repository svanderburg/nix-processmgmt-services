{createManagedProcess, influxdb, writeTextFile, libDir}:

{ instanceSuffix ? ""
, instanceName ? "influxdb${instanceSuffix}"
, rpcBindIP ? "127.0.0.1"
, rpcPort ? 8088
, httpBindIP ? ""
, httpPort ? 8086
, extraConfig ? ""
, postInstall ? ""
}:

let
  influxdbStateDir = "${libDir}/${instanceName}";

  configFile = writeTextFile {
    name = "influxdb.conf";
    text = ''
      bind-address = "${rpcBindIP}:${toString rpcPort}"

      [meta]
      dir = "${influxdbStateDir}/meta"

      [data]
      dir = "${influxdbStateDir}/data"
      wal-dir = "${influxdbStateDir}/wal"

      [http]
      enabled = true
      bind-address = "${httpBindIP}:${toString httpPort}"

      ${extraConfig}
    '';
  };
in
import ./default.nix {
  inherit createManagedProcess influxdb libDir;
} {
  inherit instanceName configFile postInstall;
}
