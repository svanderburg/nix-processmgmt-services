{xinetdConstructorFun, lib, dysnomia, libDir}:

{ instanceSuffix ? ""
, instanceName ? "xinetd${instanceSuffix}"
, containerName ? "xinetd-service${instanceSuffix}"
, postInstall ? ""
, type ? null
, properties ? {}
}:

let
  xinetdTargetDir = "${libDir}/${instanceName}/xinetd.d";

  pkg = xinetdConstructorFun {
    inherit instanceName;
    postInstall = ''
      # Add Dysnomia container configuration file for xinetd
      mkdir -p $out/etc/dysnomia/containers
      cat > $out/etc/dysnomia/containers/${containerName} <<EOF
      xinetdTargetDir="${xinetdTargetDir}"
      EOF

      # Copy the Dysnomia module that manages a xinetd service
      mkdir -p $out/libexec/dysnomia
      ln -s ${dysnomia}/libexec/dysnomia/xinetd-service $out/libexec/dysnomia
    ''
    + postInstall;
  };
in
{
  name = instanceName;
  inherit pkg xinetdTargetDir;
  providesContainer = containerName;
} // lib.optionalAttrs (type != null) {
  inherit type;
} // properties
