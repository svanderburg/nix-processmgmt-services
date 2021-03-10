{ stdenv
, lib
, writeTextFile
, nix-processmgmt

, processManager
, dysnomiaProperties
, dysnomiaContainers

, containerProviders
, extraDysnomiaContainersPath
, processManagerContainerSettings
}:

let
  # Take some default system properties, override them with the specified Dysnomia properties
  _dysnomiaProperties = {
    hostname = "$(hostname)";
    system = stdenv.system;
  } // dysnomiaProperties;

  printProperties = properties:
    lib.concatMapStrings (propertyName:
      let
        property = properties.${propertyName};
      in
      if builtins.isList property then "${propertyName}=(${lib.concatMapStrings (elem: "\"${toString elem}\" ") (properties.${propertyName})})\n"
      else "${propertyName}=\"${toString property}\"\n"
    ) (builtins.attrNames properties);


  dysnomiaPropertiesFile = writeTextFile {
    name = "dysnomia-properties";
    text = printProperties _dysnomiaProperties;
  };

  # For process managers that manages the disnix-service, expose it as a container
  processManagerDysnomiaModule = import "${nix-processmgmt}/nixproc/derive-dysnomia-process-type.nix" {
    inherit processManager;
  };

  processManagerContainer = lib.recursiveUpdate (stdenv.lib.optionalAttrs (processManager == "supervisord") {
    supervisord-program = {
      supervisordTargetDir = "/etc/supervisor/conf.d";
    };
  }) {
    "${processManagerDysnomiaModule}" = processManagerContainerSettings.${processManager} or {};
  };

  _dysnomiaContainers = lib.recursiveUpdate ({
    # Expose the standard Dysnomia modules as a container
    echo = {};
    fileset = {};
    process = {};
    wrapper = {};
  } // processManagerContainer) dysnomiaContainers;

  containerProvidersContainerPath = map (containerProvider: "${containerProvider.pkg}/etc/dysnomia/containers") containerProviders;

  containerProvidersModulesPath = map (containerProvider: "${containerProvider.pkg}/libexec/dysnomia") containerProviders;

  # Generate container configuration files
  containersDir = stdenv.mkDerivation {
    name = "dysnomia-containers";
    buildCommand = ''
      mkdir -p $out
      cd $out

      ${lib.concatMapStrings (containerName:
        let
          containerProperties = _dysnomiaContainers.${containerName};
        in
        ''
          cat > ${containerName} <<EOF
          ${printProperties containerProperties}
          type=${containerName}
          EOF
        ''
      ) (builtins.attrNames _dysnomiaContainers)}
    '';
  };
in
{
  DYSNOMIA_PROPERTIES = dysnomiaPropertiesFile;
  DYSNOMIA_CONTAINERS_PATH = builtins.concatStringsSep ":" ([containersDir] ++ containerProvidersContainerPath ++ extraDysnomiaContainersPath);
  DYSNOMIA_MODULES_PATH = builtins.concatStringsSep ":" containerProvidersModulesPath;
}
