{createManagedProcess, writeTextFile, lib, fcron, utillinux, stateDir, runtimeDir, tmpDir, spoolDir, forceDisableUserChange, callingUser, callingGroup}:

{ instanceSuffix ? ""
, instanceName ? "fcron${instanceSuffix}"
, initialize ? ""
, fcrontabPerUser
}:

let
  fcronSpoolDir = "${spoolDir}/${instanceName}";
  fcronEtcDir = "${stateDir}/etc/${instanceName}";
in
import ./default.nix {
  inherit createManagedProcess writeTextFile lib fcron stateDir runtimeDir tmpDir spoolDir forceDisableUserChange callingUser callingGroup;
} {
  inherit instanceSuffix instanceName;

  initialize =
    lib.concatMapStrings (user:
      let
        fcrontab = builtins.getAttr user fcrontabPerUser;
        fcrontabFile = writeTextFile {
          name = "fcrontab-${user}";
          text = fcrontab;
        };
      in
      ''
        cp ${fcrontabFile} ${fcronSpoolDir}/${user}.orig
        ${lib.optionalString (!forceDisableUserChange) "${utillinux}/bin/runuser -u root -g ${instanceName} --"} fcrontab -c ${fcronEtcDir}/fcron.conf -u systab -z
      ''
    ) (builtins.attrNames fcrontabPerUser)
    + initialize;
}
