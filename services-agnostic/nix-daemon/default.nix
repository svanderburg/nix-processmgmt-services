{createManagedProcess, nix}:

createManagedProcess {
  name = "nix-daemon";
  foregroundProcess = "${nix}/bin/nix-daemon";
  path = [ nix ];

  overrides = {
    sysvinit = {
      runlevels = [ 2 3 4 5 ];
    };
  };
}
