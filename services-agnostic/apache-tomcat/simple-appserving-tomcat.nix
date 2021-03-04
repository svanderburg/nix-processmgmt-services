{createManagedProcess, stdenv, lib, tomcat, jre, stateDir, runtimeDir, tmpDir, forceDisableUserChange}:

{ instanceSuffix ? ""
, instanceName ? "tomcat${instanceSuffix}"
, serverPort ? 8005
, httpPort ? 8080
, httpsPort ? 8443
, ajpPort ? 8009
, javaOpts ? ""
, catalinaOpts ? ""
, commonLibs ? []
, sharedLibs ? []
, webapps ? [ tomcat.webapps ]
, enableAJP ? false
, postInstall ? ""
}:

let
  tomcatConfigFiles = stdenv.mkDerivation {
    name = "tomcat-config-files";
    buildCommand = ''
      mkdir -p $out
      cd $out

      # Generate Tomcat configuration
      mkdir conf
      cp ${tomcat}/conf/* conf
      sed -i \
        -e 's|<Server port="8005" shutdown="SHUTDOWN">|<Server port="${toString serverPort}" shutdown="SHUTDOWN">|' \
        -e 's|<Connector port="8080" protocol="HTTP/1.1"|<Connector port="${toString httpPort}" protocol="HTTP/1.1"|' \
        -e 's|redirectPort="8443"|redirectPort="${toString httpsPort}"|' \
        conf/server.xml

      ${lib.optionalString enableAJP ''
        sed -i \
          -e '/<Service name="Catalina">/a <Connector protocol="AJP/1.3" address="127.0.0.1" port="${toString ajpPort}" redirectPort="8443" secretRequired="false" />' \
          conf/server.xml
      ''}

      # Create a modified catalina.properties file
      # Change all references from CATALINA_HOME to CATALINA_BASE to support loading files from our mutable state directory
      # and add support for shared libraries
      chmod 644 conf/catalina.properties
      sed -i \
          -e 's|''${catalina.home}|''${catalina.base}|g' \
          -e 's|shared.loader=|shared.loader=''${catalina.base}/shared/lib/*.jar|' \
        conf/catalina.properties

      # Symlink all shared libraries
      ${lib.optionalString (sharedLibs != []) ''
        mkdir -p shared/lib

        for i in ${toString sharedLibs}
        do
            if [ -f "$i" ]
            then
                ln -sfn "$i" shared/lib
            elif [ -d "$i" ]
            then
                for j in $i/shared/lib/*
                do
                    ln -sfn $i/shared/lib/$(basename "$j") shared/lib
                done
            fi
        done
      ''}

      # Symlink all configured webapps
      mkdir -p webapps
      for i in ${toString webapps}
      do
          if [ -f "$i" ]
          then
              ln -sfn "$i" webapps
          elif [ -d "$i" ]
          then
              for j in $i/webapps/*
              do
                  ln -sfn $i/webapps/$(basename "$j") webapps

                  # Also symlink the configuration files if they are included
                  if [ -d $i/conf/Catalina ]
                  then
                      for j in $i/conf/Catalina/*
                      do
                          mkdir -p $out/conf/Catalina/localhost
                          ln -sfn $j $out/conf/Catalina/localhost/`basename $j`
                      done
                  fi
              done
          fi
      done
    '';
  };
in
import ./default.nix {
  inherit createManagedProcess lib tomcat jre stateDir runtimeDir tmpDir forceDisableUserChange;
} {
  inherit tomcatConfigFiles instanceName javaOpts catalinaOpts commonLibs postInstall;
}
