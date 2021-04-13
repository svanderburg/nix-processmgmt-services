{createManagedProcess, stdenv, lib, writeTextFile, nix, disnix, dysnomia, inetutils, findutils, processManager, nix-processmgmt, ids ? {}}:

{ dbus-daemon ? null
, dysnomiaProperties ? {}
, dysnomiaContainers ? {}
, containerProviders ? []
, extraDysnomiaContainersPath ? []
, processManagerContainerSettings ? {}
, authorizedUsers ? []
}:

let
  group = "disnix";

  dysnomiaFlags =
    if processManager == "supervisord" then {
      enableSupervisordProgram = true;
    } else {};

  dysnomiaPkg = dysnomia.override dysnomiaFlags;
in
createManagedProcess {
  name = "disnix-service";
  process = "${disnix}/bin/disnix-service";
  path = [ nix dysnomiaPkg disnix inetutils findutils ];
  environment = import ./dysnomia-env.nix {
    inherit stdenv lib writeTextFile nix-processmgmt processManager dysnomiaProperties dysnomiaContainers containerProviders extraDysnomiaContainersPath processManagerContainerSettings;
  };
  daemonExtraArgs = [ "--daemon" ];
  dependencies =
    # If we use systemd, we should not add dbus-daemon as a dependency. It causes infinite recursion.
    # Moreover, since D-Bus is already enabled for systemd, there is no reason to wait for it anyway.
    lib.optional (dbus-daemon != null && processManager != "systemd") dbus-daemon.pkg
    ++ map (containerProvider: containerProvider.pkg) containerProviders;

  credentials = {
    groups = {
      "${group}" = lib.optionalAttrs (ids ? gids && ids.gids ? disnix-service) {
        gid = ids.gids.disnix-service;
      };
    };
  };

  overrides = {
    sysvinit = {
      runlevels = [ 2 3 4 5 ];
    };
  };

  # Add dbus service configuration file
  postInstall = ''
    mkdir -p $out/share/dbus-1/system.d
    cat > $out/share/dbus-1/system.d/disnix.conf <<EOF
    <!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN" "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
    <busconfig>
        <policy user="root">
            <allow own="org.nixos.disnix.Disnix"/>
            <allow send_destination="org.nixos.disnix.Disnix"/>
            <allow send_interface="org.nixos.disnix.Disnix"/>
        </policy>

        <policy group="disnix">
            <deny own="org.nixos.disnix.Disnix"/>
            <allow send_destination="org.nixos.disnix.Disnix"/>
            <allow send_interface="org.nixos.disnix.Disnix"/>
        </policy>

        <policy context="default">
            <deny own="org.nixos.disnix.Disnix"/>
            <deny send_destination="org.nixos.disnix.Disnix"/>
            <deny send_interface="org.nixos.disnix.Disnix"/>
        </policy>

        ${lib.concatMapStrings (authorizedUser: ''
          <policy user="${authorizedUser}">
            <allow own="org.nixos.disnix.Disnix"/>
            <allow send_destination="org.nixos.disnix.Disnix"/>
            <allow send_interface="org.nixos.disnix.Disnix"/>
          </policy>
        '') authorizedUsers}
    </busconfig>
    EOF
  '';
}
