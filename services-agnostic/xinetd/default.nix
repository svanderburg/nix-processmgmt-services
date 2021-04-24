{createManagedProcess, xinetd, runtimeDir, tmpDir, forceDisableUserChange}:
{instanceSuffix ? "", instanceName ? "xinetd${instanceSuffix}", initialize ? "", configFile}:

createManagedProcess {
  inherit instanceName initialize;
  process = "${xinetd}/bin/xinetd";

  args = [ "-f" configFile "-pidfile" "${runtimeDir}/${instanceName}.pid" ];
  foregroundProcessExtraArgs = [ "-dontfork" ];

  overrides = {
    sysvinit = {
      runlevels = [ 3 4 5 ];
    };
  };
}
