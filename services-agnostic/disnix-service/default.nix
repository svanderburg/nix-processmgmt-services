{createManagedProcess, stdenv, disnix, nix}:
{dbus-daemon ? null}:

let
  group = "disnix";
in
createManagedProcess {
  name = "disnix-service";
  process = "${disnix}/bin/disnix-service";
  path = [ nix ];
  daemonExtraArgs = [ "--daemon" ];
  dependencies = stdenv.lib.optional (dbus-daemon != null) dbus-daemon.pkg;

  credentials = {
    groups = {
      "${group}" = {};
    };
  };

  overrides = {
    sysvinit = {
      runlevels = [ 2 3 4 5 ];
    };
  };
}
