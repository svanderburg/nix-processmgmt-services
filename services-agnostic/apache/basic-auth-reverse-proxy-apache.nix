{createManagedProcess, stdenv, lib, runCommand, apacheHttpd, php, writeTextFile, logDir, runtimeDir, cacheDir, forceDisableUserChange}:

{ instanceSuffix ? ""
, instanceName ? "apache${instanceSuffix}"
, port ? 80
, serverName ? "localhost"
, serverAdmin
, documentRoot ? ../http-server-common/webapp
, enablePHP ? false
, enableCGI ? false
, targetProtocol ? "http"
, portPropertyName ? "port"
, dependency
, modules ? []
, authName
, authUserFile ? null
, authGroupFile ? null
, requireUser ? null
, requireGroup ? null
, extraConfig ? ""
, postInstall ? ""
}:

import ./reverse-proxy-apache.nix {
  inherit createManagedProcess stdenv lib runCommand apacheHttpd php writeTextFile logDir runtimeDir cacheDir forceDisableUserChange;
} {
  inherit instanceSuffix instanceName port serverName serverAdmin documentRoot enablePHP enableCGI targetProtocol portPropertyName dependency modules extraConfig postInstall;
  extraProxySettings = ''
    AuthType basic
    AuthName "${authName}"
    AuthBasicProvider file
  ''
  + lib.optionalString (authUserFile != null) ''
    AuthUserFile ${authUserFile}
  ''
  + lib.optionalString (authGroupFile != null) ''
    AuthGroupFile ${authGroupFile}
  ''
  + lib.optionalString (requireUser != null) ''
    Require user ${requireUser}
  ''
  + lib.optionalString (requireGroup != null) ''
    Require group ${requireGroup}
  '';
}
