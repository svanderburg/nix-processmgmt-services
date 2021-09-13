{createManagedProcess, vsftpd}:
{instanceSuffix ? "", instanceName ? "vsftpd${instanceSuffix}", initialize ? "", configFile}:

let
  user = instanceName;
  group = instanceName;
in
createManagedProcess {
  inherit instanceName initialize;

  foregroundProcess = "${vsftpd}/bin/vsftpd";
  args = [ configFile ];

  credentials = {
    groups = {
      "${group}" = {};
    };
    users = {
      "${user}" = {
        inherit group;
        description = "vsftpd user";
      };
    };
  };

  overrides = {
    sysvinit = {
      runlevels = [ 3 4 5 ];
    };
  };
}
