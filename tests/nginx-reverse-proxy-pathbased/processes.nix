{ pkgs ? import <nixpkgs> { inherit system; }
, system ? builtins.currentSystem
, stateDir ? "/var"
, runtimeDir ? "${stateDir}/run"
, logDir ? "${stateDir}/log"
, spoolDir ? "${stateDir}/spool"
, cacheDir ? "${stateDir}/cache"
, libDir ? "${stateDir}/lib"
, tmpDir ? (if stateDir == "/var" then "/tmp" else "${stateDir}/tmp")
, forceDisableUserChange ? false
, processManager
}:

let
  constructors = import ../../services-agnostic/constructors.nix {
    inherit pkgs stateDir runtimeDir logDir tmpDir cacheDir libDir spoolDir forceDisableUserChange processManager;
  };

  webappStatic = pkgs.stdenv.mkDerivation {
    name = "webapp-static";
    buildCommand = ''
      mkdir -p $out
      cat > $out/index.html <<EOF
      <!DOCTYPE html>

      <html>
          <head>
              <title>Hello</title>
          </head>

          <body>
              <h1>Hello world!</h1>
          </body>
      </html>
      EOF
    '';
  };
in
rec {
  nginx-webapp = rec {
    name = "nginx-webapp";
    port = if forceDisableUserChange then 8082 else 82;
    baseURL = "/";

    pkg = constructors.simpleWebappNginx {
      inherit port;
      instanceSuffix = "-webapp";
      documentRoot = webappStatic;
    };
  };

  nginx-revproxy1 = rec {
    port = if forceDisableUserChange then 8080 else 80;

    pkg = constructors.nginxReverseProxyPathBased {
      inherit port;
      instanceSuffix = "-revproxy1";
      webapps = [ nginx-webapp ];
    } {};
  };

  # Second instance has caching of the output of the forwarded requests enabled
  nginx-revproxy2 = rec {
    port = if forceDisableUserChange then 8081 else 81;

    pkg = constructors.nginxReverseProxyPathBased {
      inherit port;
      instanceSuffix = "-revproxy2";
      enableCache = true;
      webapps = [ nginx-webapp ];
    } {};
  };
}
