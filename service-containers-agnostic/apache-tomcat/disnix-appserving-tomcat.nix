{tomcatConstructorFun, lib, tomcat, libmatthew_java, dbus_java, DisnixWebService, dysnomia, stateDir}:

args:

import ./simple-appserving-tomcat.nix {
  inherit tomcatConstructorFun lib tomcat dysnomia stateDir;
} (args // {
  javaOpts = lib.optionalString (args ? javaOpts) "${args.javaOpts} " + "-Djava.library.path=${libmatthew_java}/lib/jni";
  sharedLibs = args.sharedLibs or [] ++ [
   "${DisnixWebService}/share/java/DisnixConnection.jar"
   "${dbus_java}/share/java/dbus.jar"
  ];
  webapps = args.webapps or [ tomcat.webapps ]
    ++ [ DisnixWebService ];
})
