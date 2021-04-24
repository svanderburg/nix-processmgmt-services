{tomcatConstructorFun, lib, tomcat, libmatthew_java, dbus_java, DisnixWebService, dysnomia, stateDir, processManager}:

{dbus-daemon, ...}@args:

let
  instanceArgs = removeAttrs args [ "dbus-daemon" ];
in
import ./simple-appserving-tomcat.nix {
  inherit tomcatConstructorFun lib tomcat dysnomia stateDir;
} (instanceArgs // {
  javaOpts = lib.optionalString (instanceArgs ? javaOpts) "${instanceArgs.javaOpts} " + "-Djava.library.path=${libmatthew_java}/lib/jni";
  sharedLibs = instanceArgs.sharedLibs or [] ++ [
   "${DisnixWebService}/share/java/DisnixConnection.jar"
   "${dbus_java}/share/java/dbus.jar"
  ];
  webapps = instanceArgs.webapps or [ tomcat.webapps ] ++ [ DisnixWebService ];
  dependencies = instanceArgs.dependencies or []
    # If we use systemd, we should not add dbus-daemon as a dependency. It causes infinite recursion.
    # Moreover, since D-Bus is already enabled for systemd, there is no reason to wait for it anyway.
    ++ lib.optional (dbus-daemon != null && processManager != "systemd") dbus-daemon.pkg;
})
