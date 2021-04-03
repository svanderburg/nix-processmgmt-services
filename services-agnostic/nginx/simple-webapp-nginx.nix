{createManagedProcess, lib, writeTextFile, nginx, runtimeDir, stateDir, cacheDir, forceDisableUserChange}:

{ port ? 80
, instanceSuffix ? ""
, instanceName ? "nginx${instanceSuffix}"
, documentRoot ? ../http-server-common/webapp
, workerConnections ? 190000
}:

let
  user = instanceName;
  group = instanceName;

  nginxStateDir = "${stateDir}/${instanceName}";
  nginxCacheDir = "${cacheDir}/${instanceName}";
  nginxLogDir = "${nginxStateDir}/logs";
in
import ./default.nix {
  inherit createManagedProcess lib nginx stateDir forceDisableUserChange runtimeDir cacheDir;
} {
  inherit instanceName;

  configFile = writeTextFile {
    name = "nginx.conf";
    text = ''
      pid ${runtimeDir}/${instanceName}.pid;
      error_log ${nginxLogDir}/error.log;

      ${lib.optionalString (!forceDisableUserChange) ''
        user ${user} ${group};
      ''}

      events {
        worker_connections ${toString workerConnections};
      }

      http {
        access_log ${nginxLogDir}/access.log;
        error_log ${nginxLogDir}/error.log;

        proxy_temp_path ${nginxCacheDir}/proxy;
        client_body_temp_path ${nginxCacheDir}/client_body;
        fastcgi_temp_path ${nginxCacheDir}/fastcgi;
        uwsgi_temp_path ${nginxCacheDir}/uwsgi;
        scgi_temp_path ${nginxCacheDir}/scgi;

        server {
          listen ${toString port};
          root ${documentRoot};
        }
      }
    '';
  };
}
