{createManagedProcess, xinetd, runtimeDir, tmpDir, forceDisableUserChange, lib, writeTextFile}:

{ instanceSuffix ? ""
, instanceName ? "xinetd${instanceSuffix}"
, services ? {}
, extraConfig ? ""
}:

import ./default.nix {
  inherit createManagedProcess xinetd runtimeDir tmpDir forceDisableUserChange;
} {
  inherit instanceSuffix instanceName;

  configFile = writeTextFile {
    name = "xinetd.conf";
    text = lib.concatMapStrings (serviceName:
      let
        service = builtins.getAttr serviceName services;
      in
      ''
        service ${serviceName}
        {
          ''
          + lib.concatMapStrings (propertyName:
            let
              propertyValue = builtins.getAttr propertyName service;
            in
            "    ${propertyName} = ${toString propertyValue}\n") (builtins.attrNames service)
          + ''
        }

      ''
    ) (builtins.attrNames services);
  }
  + extraConfig;
}
