{createManagedProcess, lib, nix, disnix, dysnomia}:
{dbus-daemon ? null}:

let
  group = "disnix";
in
createManagedProcess {
  name = "disnix-service";
  process = "${disnix}/bin/disnix-service";
  path = [ nix dysnomia disnix ];
  daemonExtraArgs = [ "--daemon" ];
  dependencies = lib.optional (dbus-daemon != null) dbus-daemon.pkg;

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
