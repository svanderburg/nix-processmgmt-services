{createManagedProcess, lib, writeTextFile, dbus, stateDir, runtimeDir, ids ? {}}:
{extraConfig ? "", busType ? "system", services ? []}:

let
  user = "messagebus";
  group = "messagebus";

  dbusRuntimeDir = "${runtimeDir}/dbus";

  configFile = writeTextFile {
    name = "system.conf";
    text = ''
      <!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-Bus Bus Configuration 1.0//EN"
        "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">

      <busconfig>
        <!-- Our well-known bus type, do not change this -->
        <type>${busType}</type>

        <!-- Run as special user -->
        <user>${user}</user>

        <!-- Write a pid file -->
        <pidfile>${runtimeDir}/dbus-daemon.pid</pidfile>

        <!-- Only allow socket-credentials-based authentication -->
        <auth>EXTERNAL</auth>

        <!-- Only listen on a local socket. (abstract=/path/to/socket
             means use abstract namespace, don't really create filesystem
             file; only Linux supports this. Use path=/whatever on other
             systems.) -->

        <listen>unix:path=${dbusRuntimeDir}/system_bus_socket</listen>

        <policy context="default">
          <!-- All users can connect to system bus -->
          <allow user="*"/>

          <!-- Holes must be punched in service configuration files for
               name ownership and sending method calls -->
          <deny own="*"/>
          <deny send_type="method_call"/>

          <!-- Signals and reply messages (method returns, errors) are allowed
               by default -->
          <allow send_type="signal"/>
          <allow send_requested_reply="true" send_type="method_return"/>
          <allow send_requested_reply="true" send_type="error"/>

          <!-- All messages may be received by default -->
          <allow receive_type="method_call"/>
          <allow receive_type="method_return"/>
          <allow receive_type="error"/>
          <allow receive_type="signal"/>

          <!-- Allow anyone to talk to the message bus -->
          <allow send_destination="org.freedesktop.DBus" send_interface="org.freedesktop.DBus"/>
          <allow send_destination="org.freedesktop.DBus" send_interface="org.freedesktop.DBus.Introspectable"/>
          <allow send_destination="org.freedesktop.DBus" send_interface="org.freedesktop.DBus.Properties"/>
          <!-- But disallow some specific bus services -->
          <deny send_destination="org.freedesktop.DBus" send_interface="org.freedesktop.DBus" send_member="UpdateActivationEnvironment"/>
          <deny send_destination="org.freedesktop.DBus" send_interface="org.freedesktop.DBus.Debug.Stats"/>
          <deny send_destination="org.freedesktop.DBus" send_interface="org.freedesktop.systemd1.Activator"/>
        </policy>

        <!-- Only systemd, which runs as root, may report activation failures. -->
        <policy user="root">
          <allow send_destination="org.freedesktop.DBus" send_interface="org.freedesktop.systemd1.Activator"/>
        </policy>

        <!-- root may monitor the system bus. -->
        <policy user="root">
          <allow send_destination="org.freedesktop.DBus" send_interface="org.freedesktop.DBus.Monitoring"/>
        </policy>

        <!-- If the Stats interface was enabled at compile-time, root may use it.
             Copy this into system.local.conf or system.d/*.conf if you want to
             enable other privileged users to view statistics and debug info -->
        <policy user="root">
          <allow send_destination="org.freedesktop.DBus" send_interface="org.freedesktop.DBus.Debug.Stats"/>
        </policy>

        <!-- Generate service and include directories for each package -->
        ${lib.concatMapStrings (service:
          let
            inherit (service) pkg;
          in
          ''
            <servicedir>${pkg}/share/dbus-1/system-services</servicedir>
            <includedir>${pkg}/etc/dbus-1/system.d</includedir>
            <includedir>${pkg}/share/dbus-1/system.d</includedir>
          '') services}

        <!-- Extra configuration options -->
        ${extraConfig}
      </busconfig>
    '';
  };
in
createManagedProcess {
  name = "dbus-daemon";
  initialize = ''
    mkdir -p ${stateDir}/lib/dbus
    mkdir -p ${dbusRuntimeDir}
    ${dbus}/bin/dbus-uuidgen --ensure
  '';
  process = "${dbus}/bin/dbus-daemon";
  args = [ "--config-file" configFile ];
  foregroundProcessExtraArgs = [ "--nofork" "--nopidfile" ];
  daemonExtraArgs = [ "--fork" ];

  credentials = {
    groups = {
      "${group}" = lib.optionalAttrs (ids ? gids && ids.gids ? dbus-daemon) {
        gid = ids.gids.dbus-daemon;
      };
    };
    users = {
      "${user}" = {
        inherit group;
        homeDir = dbusRuntimeDir;
        description = "D-Bus system message bus daemon user";
      } // lib.optionalAttrs (ids ? uids && ids.uids ? dbus-daemon) {
        uid = ids.uids.dbus-daemon;
      };
    };
  };

  overrides = {
    sysvinit = {
      runlevels = [ 2 3 4 5 ];
    };
  };
}
