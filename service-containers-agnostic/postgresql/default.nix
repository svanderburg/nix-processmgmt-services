{postgresqlConstructorFun, lib, dysnomia, runtimeDir}:

{ instanceSuffix ? "", instanceName ? "postgresql${instanceSuffix}"
, containerName ? "postgresql-database${instanceSuffix}"
, port ? 5432
, type ? null
, properties ? {}
}:

let
  username = instanceName;

  pkg = postgresqlConstructorFun {
    inherit instanceName instanceSuffix port;
    postInstall = ''
      # Add Dysnomia container configuration file for PostgreSQL
      mkdir -p $out/etc/dysnomia/containers
      cat > $out/etc/dysnomia/containers/${containerName} <<EOF
      postgresqlPort=${toString port}
      postgresqlRuntimeDir=${runtimeDir}/${instanceName}
      postgresqlUsername=${username}
      EOF

      # Copy the Dysnomia module that manages a PostgreSQL database
      mkdir -p $out/libexec/dysnomia
      ln -s ${dysnomia}/libexec/dysnomia/postgresql-database $out/libexec/dysnomia
    '';
  };
in
rec {
  name = instanceName;
  postgresqlPort = port;
  postgresqlRuntimeDir = "${runtimeDir}/${instanceName}";
  postgresqlUsername = username;

  inherit pkg;

  providesContainer = containerName;
} // lib.optionalAttrs (type != null) {
  inherit type;
} // properties
