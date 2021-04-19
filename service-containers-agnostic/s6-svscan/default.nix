{s6-svscanConstructorFun, lib, dysnomia, libDir, runtimeDir}:

{ instanceSuffix ? ""
, instanceName ? "s6-svscan${instanceSuffix}"
, containerName ? "s6-rc-service${instanceSuffix}"
, scanDir ? "${runtimeDir}/service${instanceSuffix}"
, postInstall ? ""
, type ? null
, properties ? {}
}:

let
  serviceDir = "${libDir}/${instanceName}/sv";

  pkg = s6-svscanConstructorFun {
    inherit instanceName scanDir serviceDir;

    postInstall = ''
      # Add Dysnomia container configuration file for s6-svscan
      mkdir -p $out/etc/dysnomia/containers
      cat > $out/etc/dysnomia/containers/${containerName} <<EOF
      serviceDir="${serviceDir}"
      scanDir="${scanDir}"
      EOF

      # Copy the Dysnomia module that manages a s6-rc service
      mkdir -p $out/libexec/dysnomia
      ln -s ${dysnomia}/libexec/dysnomia/supervisord-program $out/libexec/dysnomia
    '';
  };
in
{
  name = instanceName;
  inherit pkg serviceDir scanDir;
  providesContainer = containerName;
} // lib.optionalAttrs (type != null) {
  inherit type;
} // properties
