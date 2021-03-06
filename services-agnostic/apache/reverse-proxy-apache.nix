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
, extraProxySettings ? ""
, extraConfig ? ""
, postInstall ? ""
}:

import ./simple-webapp-apache.nix {
  inherit createManagedProcess lib runCommand apacheHttpd php writeTextFile logDir runtimeDir cacheDir forceDisableUserChange;
} {
  inherit instanceSuffix instanceName port serverName serverAdmin documentRoot enablePHP enableCGI postInstall;
  dependencies = [ dependency.pkg ];

  modules = [
    "cache"
    "proxy"
    "proxy_ajp"
    "proxy_balancer"
    "proxy_connect"
    "proxy_express"
    "proxy_fcgi"
    "proxy_fdpass"
    "proxy_ftp"
    "proxy_hcheck"
    "proxy_html"
    "proxy_http"
    "proxy_scgi"
    "proxy_uwsgi"
    "proxy_wstunnel"
    "slotmem_shm"
    "xml2enc"
    "watchdog"
  ] ++ modules;
  extraConfig = ''
    <Proxy *>
      Order deny,allow
      Allow from all
      ${extraProxySettings}
    </Proxy>

    ProxyRequests     Off
    ProxyPreserveHost On
    ProxyPass         /apache-errors !
    ErrorDocument 503 /apache-errors/503.html
    ProxyPass         /       ${targetProtocol}://127.0.0.1:${toString dependency.${portPropertyName}}/ retry=5 disablereuse=on
    ProxyPassReverse  /       ${targetProtocol}://127.0.0.1:${toString dependency.${portPropertyName}}/
    ${extraConfig}
  '';
}
