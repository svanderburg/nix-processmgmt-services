{ lib, createManagedProcess, eris-go }:

{ instanceSuffix ? ""
, instanceName ? "eris-server${instanceSuffix}"
# Whether to decode ERIS content at http://…/uri-res/N2R?urn:eris:….
, decode ? false,
# Server CoAP listen address.
listenCoap ? null
# Server HTTP listen address.
, listenHttp ? null
# Server backend stores.
, storeBackends
# TODO: FUSE
}:

let
in createManagedProcess {
  inherit instanceName;
  foregroundProcess = "${eris-go}/bin/eris-go";
  foregroundProcessArgs = [ "server" ] ++ lib.optional decode "--decode"
    ++ lib.optionals (listenCoap != null) [ "--coap" listenCoap ]
    ++ lib.optionals (listenHttp != null) [ "--http" listenHttp ]
    ++ storeBackends;
    # TODO: --mountpoint

  overrides = {
    sysvinit = {
      runlevels = [ 3 4 5 ];
    };
  };
}
