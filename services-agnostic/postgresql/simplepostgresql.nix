{createManagedProcess, stdenv, writeTextFile, postgresql, su, stateDir, runtimeDir, forceDisableUserChange}:

{ port ? 5432
, instanceSuffix ? ""
, instanceName ? "postgresql${instanceSuffix}"
, configFile ? null
, postInstall ? ""
, authentication ? null
, identMap ? null
, enableTCPIP ? false
, settings ? {}
}:

let
  hbaFile = writeTextFile {
    name = "hba.conf";
    text = authentication + ''

      # TYPE  DATABASE   USER   ADDRESS       METHOD
      local   all        all                  peer
      host    all        all    127.0.0.1/32  md5
      host    all        all    ::1/128       md5
    '';
  };

  identFile = writeTextFile {
    name = "ident.conf";
    text = identMap;
  };

  toConfigValue = value:
    if true == value then "yes"
    else if false == value then "no"
    else if builtins.isString value then "'${stdenv.lib.replaceStrings ["'"] ["''"] value}'"
    else toString value;
in
import ./default.nix {
  inherit createManagedProcess stdenv postgresql su stateDir runtimeDir forceDisableUserChange;
} {
  inherit port instanceSuffix instanceName postInstall;
  configFile = writeTextFile {
    name = "";
    text =
      stdenv.lib.optionalString (authentication != null) ''
        hba_file = '${hbaFile}'
      ''
      + stdenv.lib.optionalString (identMap != null) ''
        ident_file = '${identFile}'
      ''
      + ''
        listen_addresses = '${if enableTCPIP then "*" else "localhost"}'
      ''
      + stdenv.lib.concatMapStrings (name:
        let
          value = builtins.getAttr name settings;
        in
        ''
          ${name} = ${toConfigValue value}
        '') (builtins.attrNames settings);
  };
}
