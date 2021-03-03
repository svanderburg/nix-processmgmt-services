{createManagedProcess, writeTextFile, lib, fcron, stateDir, runtimeDir, tmpDir, spoolDir, forceDisableUserChange}:

{ instanceSuffix ? ""
, instanceName ? "fcron${instanceSuffix}"
, initialize ? ""
, fcrontabPerUser
}:

let
  fcronSpoolDir = "${spoolDir}/${instanceName}";
in
import ./default.nix {
  inherit createManagedProcess writeTextFile lib fcron stateDir runtimeDir tmpDir spoolDir forceDisableUserChange;
} {
  inherit instanceSuffix instanceName;

  initialize = ''
    ${lib.concatMapStrings (user:
      let
        fcrontab = builtins.getAttr user fcrontabPerUser;
        fcrontabFile = writeTextFile {
          name = "fcrontab-${user}";
          text = fcrontab;
        };
      in
      ''
        cp ${fcrontabFile} ${fcronSpoolDir}/${user}.orig
      ''
    ) (builtins.attrNames fcrontabPerUser)}
    ${initialize}
  '';
}
