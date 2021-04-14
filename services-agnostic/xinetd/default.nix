{createManagedProcess, xinetd, runtimeDir, tmpDir, forceDisableUserChange}:
{instanceSuffix ? "", instanceName ? "xinetd${instanceSuffix}", configFile}:

let
  pidFile = if forceDisableUserChange then "${tmpDir}/${instanceName}.pid" else "${runtimeDir}/${instanceName}.pid";
in
createManagedProcess {
  inherit instanceName;
  process = "${xinetd}/bin/xinetd";

  args = [ "-f" configFile "-pidfile" pidFile ];
  foregroundProcessExtraArgs = [ "-dontfork" ];

  overrides = {
    sysvinit = {
      runlevels = [ 3 4 5 ];
    };
  };
}
