{dockerConstructorFun, lib, dysnomia}:

{ instanceSuffix ? ""
, instanceName ? "docker${instanceSuffix}"
, containerName ? "docker-container${instanceSuffix}"
, postInstall ? ""
, type ? null
, properties ? {}
}:

let
  pkg = dockerConstructorFun {
    inherit instanceName;

    postInstall = ''
      # Add Dysnomia container configuration file for a Docker container
      mkdir -p $out/etc/dysnomia/containers
      cat > $out/etc/dysnomia/containers/${containerName} <<EOF
      EOF

      # Copy the Dysnomia module that manages a docker-container
      mkdir -p $out/libexec/dysnomia
      ln -s ${dysnomia}/libexec/dysnomia/docker-container $out/libexec/dysnomia
    '';
  };
in
{
  name = instanceName;
  inherit pkg;
  providesContainer = containerName;
} // lib.optionalAttrs (type != null) {
  inherit type;
} // properties
