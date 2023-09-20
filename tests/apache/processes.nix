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
, nix-processmgmt ? ../../../nix-processmgmt
}:

let
  constructors = import ../../services-agnostic/constructors.nix {
    inherit pkgs stateDir runtimeDir logDir tmpDir cacheDir libDir spoolDir forceDisableUserChange processManager nix-processmgmt;
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

  webappPHP = pkgs.stdenv.mkDerivation {
    name = "webapp-php";
    buildCommand = ''
      mkdir -p $out
      cat > $out/index.php <<EOF
      <!DOCTYPE html>

      <html>
          <head>
              <title>Hello</title>
          </head>

          <body>
              <h1><?php print("Hello world from PHP!"); ?></h1>
          </body>
      </html>
      EOF
    '';
  };
in
rec {
  # The first instance only serves static web apps
  apache-primary = rec {
    port = if forceDisableUserChange then 8080 else 80;

    pkg = constructors.simpleWebappApache {
      inherit port;
      instanceSuffix = "-primary";
      serverAdmin = "root@localhost";
      documentRoot = webappStatic;
    };
  };

  # The second instance is PHP enabled
  apache-secondary = rec {
    port = if forceDisableUserChange then 8081 else 81;

    pkg = constructors.simpleWebappApache {
      inherit port;
      instanceSuffix = "-secondary";
      serverAdmin = "root@localhost";
      documentRoot = webappPHP;
      enablePHP = true;
    };
  };
}
