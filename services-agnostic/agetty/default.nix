{createManagedProcess, util-linux}:
{port, instanceName ? "agetty-${port}", baudrate ? 9600, extraOptions ? []}:

createManagedProcess {
  inherit instanceName;
  foregroundProcess = "${util-linux}/bin/agetty";
  args = extraOptions ++ [ port baudrate ];

  overrides = {
    sysvinit = {
      runlevels = [ 2 3 4 5 ];
    };
  };
}
