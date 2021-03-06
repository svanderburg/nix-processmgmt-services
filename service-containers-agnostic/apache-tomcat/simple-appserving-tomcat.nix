{tomcatConstructorFun, lib, tomcat, dysnomia, stateDir}:

{ instanceSuffix ? ""
, instanceName ? "tomcat${instanceSuffix}"
, containerName ? "tomcat-webapplication${instanceSuffix}"
, serverPort ? 8005
, httpPort ? 8080, httpsPort ? 8443, ajpPort ? 8009
, javaOpts ? ""
, catalinaOpts ? ""
, commonLibs ? []
, sharedLibs ? []
, webapps ? [ tomcat.webapps ]
, enableAJP ? false
, type ? null
, dependencies ? []
, properties ? {}
}:

let
  catalinaBaseDir = "${stateDir}/${instanceName}";

  pkg = tomcatConstructorFun {
    inherit instanceName serverPort httpPort httpsPort ajpPort javaOpts catalinaOpts commonLibs sharedLibs webapps enableAJP dependencies;

    postInstall = ''
      # Add Dysnomia container configuration file for a Tomcat web application
      mkdir -p $out/etc/dysnomia/containers
      cat > $out/etc/dysnomia/containers/${containerName} <<EOF
      tomcatPort=${toString httpPort}
      catalinaBaseDir=${catalinaBaseDir}
      ${lib.optionalString enableAJP "ajpPort=${toString ajpPort}"}
      EOF

      # Copy the Dysnomia module that manages MySQL database
      mkdir -p $out/libexec/dysnomia
      ln -s ${dysnomia}/libexec/dysnomia/tomcat-webapplication $out/libexec/dysnomia
    '';
  };
in
rec {
  name = instanceName;

  inherit pkg catalinaBaseDir ajpPort;
  tomcatPort = httpPort;

  providesContainer = containerName;
} // lib.optionalAttrs (type != null) {
  inherit type;
} // properties
