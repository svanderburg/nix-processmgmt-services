{createManagedProcess, lib, xinetd, writeTextFile, runtimeDir, tmpDir, libDir, forceDisableUserChange, callingUser}:

{ instanceSuffix ? ""
, instanceName ? "xinetd${instanceSuffix}"
, services ? {}
, extraConfig ? ""
# If there are no services, then xinetd refuses to launch. An echo service prevents this from happening so that we can initially bootstrap it
, includeEchoService ? true
, echoPort ? 1024
}:

let
  xinetdIncludeDir = "${libDir}/${instanceName}/xinetd.d";
in
import ./default.nix {
  inherit createManagedProcess xinetd runtimeDir tmpDir forceDisableUserChange;
} {
  inherit instanceSuffix instanceName;

  initialize = ''
    mkdir -p ${xinetdIncludeDir}
  ''
  + lib.optionalString includeEchoService ''
    cat > ${xinetdIncludeDir}/echo <<EOF
    service echo
    {
        socket_type = dgram
        protocol = udp
        bind = 127.0.0.1
        wait = yes
        user = ${if forceDisableUserChange then callingUser else "nobody"}
        type = INTERNAL${lib.optionalString forceDisableUserChange " UNLISTED"}
  ''
  + lib.optionalString forceDisableUserChange ''
    port = ${toString echoPort}
  ''
  + ''
    }
    EOF
  '';

  configFile = writeTextFile {
    name = "xinetd.conf";
    text = ''
      includedir ${xinetdIncludeDir}
    ''
    + extraConfig;
  };
}
