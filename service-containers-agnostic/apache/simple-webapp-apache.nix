{apacheConstructorFun, lib, dysnomia, forceDisableUserChange}:

{ instanceSuffix ? "", instanceName ? "apache${instanceSuffix}"
, containerName ? "apache-webapplication${instanceSuffix}"
, port ? 80
, modules ? [], serverName ? "localhost"
, serverAdmin
, documentRoot ? ../../services-agnostic/http-server-common/webapp
, extraConfig ? ""
, enableCGI ? false
, enablePHP ? false
, filesetOwner ? null
, type ? null
, properties ? {}
}:

let
  pkg = apacheConstructorFun {
    inherit instanceName port modules serverName serverAdmin documentRoot extraConfig enableCGI enablePHP;
    postInstall = ''
      # Add Dysnomia container configuration file for the Apache HTTP server
      mkdir -p $out/etc/dysnomia/containers
      cat > $out/etc/dysnomia/containers/${containerName} <<EOF
      httpPort=${toString port}
      documentRoot=${documentRoot}
      EOF

      # Copy the Dysnomia module that manages an Apache web application
      mkdir -p $out/libexec/dysnomia
      ln -s ${dysnomia}/libexec/dysnomia/apache-webapplication $out/libexec/dysnomia
    '';
  };
in
{
  name = instanceName;
  inherit pkg port documentRoot;
  providesContainer = containerName;
} // lib.optionalAttrs (type != null) {
  inherit type;
} // (if forceDisableUserChange || filesetOwner == null then {} else {
  inherit filesetOwner;
}) // properties
