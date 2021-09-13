{createManagedProcess, stdenv, vsftpd, writeTextFile, lib, logDir, libDir, forceDisableUserChange, callingUser, callingGroup}:

{ instanceSuffix ? ""
, instanceName ? "vsftpd${instanceSuffix}"
, dataPort ? 20
, listenPort ? dataPort + 1
, options ? {}
, enableAnonymousUser ? false
, anonymousUsername ? "ftp"
, anonymousRoot ? if forceDisableUserChange then "/home/${callingUser}" else "/home/${anonymousUsername}"
}:

let
  user = instanceName;
  group = instanceName;

  vsftpdLogDir = "${logDir}/${instanceName}";

  configFile = writeTextFile {
    name = "vsftpd.conf";
    text =
      lib.optionalString (stdenv.isLinux) ''
        seccomp_sandbox=NO
      ''
      +
      ''
        vsftpd_log_file=${vsftpdLogDir}/vsftpd.log
        xferlog_file=${vsftpdLogDir}/xferlog
      '' +
      (if forceDisableUserChange then ''
        run_as_launching_user=YES
        ftp_username=${callingUser}
      '' else ''
        nopriv_user=${user}
        ftp_username=${if enableAnonymousUser then anonymousUsername else "nobody"}
        pam_service_name=vsftpd
        secure_chroot_dir=/var/empty
      '')
      + ''
        ftp_data_port=${toString dataPort}
        listen_port=${toString listenPort}
      ''
      + lib.optionalString enableAnonymousUser ''
        anon_root=${anonymousRoot}
      ''
      + lib.concatMapStrings (name:
        let
          value = builtins.getAttr name options;
        in
        "${name}=${toString value}\n"
      ) (builtins.attrNames options);
  };
in
import ./default.nix {
  inherit createManagedProcess vsftpd;
} {
  inherit instanceSuffix instanceName;

  # When running as unprivileged user, we need to make a copy of the config file and make the calling user the owner
  configFile = if forceDisableUserChange then "${libDir}/${instanceName}/vsftpd.conf" else configFile;

  initialize =
    ''
      mkdir -p ${vsftpdLogDir}
    ''
    +
    # Make the unprivileged user the owner of the config file
    lib.optionalString forceDisableUserChange
      (let
        dynamicConfigFile = "${libDir}/${instanceName}/vsftpd.conf";
      in
      ''
        mkdir -p ${libDir}/${instanceName}
        cp ${configFile} ${dynamicConfigFile}
        chmod u+w ${dynamicConfigFile}
        chown ${callingUser}:${callingGroup} ${dynamicConfigFile}
      '');
}
