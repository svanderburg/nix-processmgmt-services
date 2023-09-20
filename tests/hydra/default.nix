{ pkgs, testService, processManagers, profiles, nix-processmgmt }:

let
  node-hydra-connector = (import ./nodepkgs {
    inherit pkgs;
    inherit (pkgs.stdenv) system;
  }).node-hydra-connector;

  loginParams = pkgs.writeTextFile {
    name = "loginparams";
    text = ''
      admin
      admin
    '';
  };

  projectParams = pkgs.writeTextFile {
    name = "projectparams";
    text = ''
      trivial
      Trivial
      Trivial project

      1
      1
    '';
  };

  generateTrivialProject = pkgs.writeScriptBin "generate-trivial-project" ''
    #! ${pkgs.stdenv.shell} -e
    mkdir -p /tmp/project
    cat > /tmp/project/release.nix <<EOF
    { trivial = derivation {
        name = "trivial";
        system = "${pkgs.stdenv.system}";
        builder = "/bin/sh";
        allowSubstitutes = false;
        preferLocalBuild = true;
        args = ["-c" "echo success > $out; exit 0"];
      };
    }
    EOF
  '';

  jobsetParams = pkgs.writeTextFile {
    name = "jobsetparams";
    text = ''
      main
      Main jobset
      projectPath
      release.nix
      admin@localhost
      1
      1
      1
      1
      1
      projectPath
      path
      /tmp/project
    '';
  };
in
testService {
  name = "hydra";
  exprFile = ../../example-deployments/hydra/processes.nix;
  extraParams = {
    inherit nix-processmgmt;
  };
  nixosConfig = {
    virtualisation.memorySize = 1024;
    virtualisation.diskSize = 8192;
    virtualisation.writableStore = true;
  };
  systemPackages = [ pkgs.hydra-unstable node-hydra-connector generateTrivialProject ];

  readiness = {instanceName, instance, ...}:
    pkgs.lib.optionalString (instanceName == "postgresql" || instanceName == "hydra-server" || instanceName == "apache") ''
      machine.wait_for_open_port(${toString instance.port})
    '';

  postTests = {...}:
    ''
      import json
      import re

      # Create admin user
      machine.succeed("su - hydra -c 'hydra-create-user admin --role admin --password admin'")

      # Login as admin user and extract session environment variable
      loginOutput = machine.succeed(
          "cat ${loginParams} | hydra-connect --url http://localhost --login"
      )

      sessionEnvVar = re.search("HYDRA_SESSION=[0-9a-zA-Z]*", loginOutput).group(0)

      # Create a project
      machine.succeed(
          "cat ${projectParams} | "
          + sessionEnvVar
          + " hydra-connect --url http://localhost --project trivial --modify >&2"
      )

      machine.succeed(sessionEnvVar + " hydra-connect --url http://localhost --projects >&2")

      # Create a jobset
      machine.succeed("generate-trivial-project")

      machine.succeed(
          "(cat ${jobsetParams}; sleep 3; echo; echo; echo) | "
          + sessionEnvVar
          + " hydra-connect --url http://localhost --project trivial --jobset main --modify >&2"
      )

      machine.succeed(
          sessionEnvVar + " hydra-connect --url http://localhost --project trivial >&2"
      )

      # Wait for an evaluation to appear

      count = 0

      while True:
          machine.succeed("sleep 1")

          evalsOutput = machine.succeed(
              sessionEnvVar
              + " hydra-connect --url http://localhost --project trivial --jobset main --evals --json"
          )
          evalsObj = json.loads(evalsOutput)

          count += 1

          if len(evalsObj["evals"]) > 0:
              break
          elif count == 10:
              raise Exception("Maximum number of 10 tries reached!")

      machine.succeed(
          sessionEnvVar
          + " hydra-connect --url http://localhost --project trivial --jobset main --evals >&2"
      )

      # Check properties of the build

      machine.succeed(
          sessionEnvVar
          + " hydra-connect --url http://localhost --project trivial --jobset main --build 1 >&2"
      )

      buildOutput = machine.succeed(
          sessionEnvVar
          + " hydra-connect --url http://localhost --project trivial --jobset main --build 1 --json"
      )
      buildObj = json.loads(buildOutput)

      if buildObj["buildoutputs"]["out"]["path"].startswith("/nix/store/"):
          print("Found output path: {}".format(buildObj["buildoutputs"]["out"]["path"]))
      else:
          raise Exception("No output path found!")

      machine.succeed(
          sessionEnvVar
          + " hydra-connect --url http://localhost --project trivial --jobset main --build 1 --raw-log >&2"
      )
    '';

  inherit processManagers;

  # We don't support unprivileged user deployments
  profiles = builtins.filter (profile: profile == "privileged") profiles;
}
