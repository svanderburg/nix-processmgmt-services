{createManagedProcess, xinetd, runtimeDir, tmpDir, libDir, forceDisableUserChange, writeTextFile}:

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
    text = ''
      includedir ${libDir}/${instanceName}/xinetd.d
    ''
    + extraConfig;
  };
}
