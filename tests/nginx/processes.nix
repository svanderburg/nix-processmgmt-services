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

  webappStatic = from: pkgs.stdenv.mkDerivation {
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
              <h1>Hello world from ${from}!</h1>
          </body>
      </html>
      EOF
    '';
  };
in
rec {
  nginx-primary = rec {
    port = if forceDisableUserChange then 8080 else 80;
    from = "primary";

    pkg = constructors.simpleWebappNginx {
      inherit port;
      instanceSuffix = "-primary";
      documentRoot = webappStatic from;
    };
  };

  nginx-secondary = rec {
    port = if forceDisableUserChange then 8081 else 81;
    from = "secondary";

    pkg = constructors.simpleWebappNginx {
      inherit port;
      instanceSuffix = "-secondary";
      documentRoot = webappStatic from;
    };
  };
}
