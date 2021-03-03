{influxdbConstructorFun, lib, dysnomia}:

{ instanceSuffix ? ""
, instanceName ? "influxdb${instanceSuffix}"
, containerName ? "influx-database${instanceSuffix}"
, rpcBindIP ? "127.0.0.1"
, rpcPort ? 8088
, httpBindIP ? ""
, httpPort ? 8086
, extraConfig ? ""
, type ? null
, properties ? {}
}:

let
  pkg = influxdbConstructorFun {
    inherit instanceName rpcBindIP rpcPort httpBindIP httpPort extraConfig;
    postInstall = ''
      # Add Dysnomia container configuration file for InfluxDB
      mkdir -p $out/etc/dysnomia/containers
      cat > $out/etc/dysnomia/containers/${containerName} <<EOF
      influxdbUsername=${instanceName}
      influxdbHttpPort=${toString httpPort}
      EOF

      # Copy the Dysnomia module that manages an InfluxDB database
      mkdir -p $out/libexec/dysnomia
      ln -s ${dysnomia}/libexec/dysnomia/influx-database $out/libexec/dysnomia
    '';
  };
in
rec {
  name = instanceName;
  inherit pkg;
  influxdbUsername = instanceName;
  influxdbHttpPort = httpPort;
  providesContainer = containerName;
} // lib.optionalAttrs (type != null) {
  inherit type;
} // properties
