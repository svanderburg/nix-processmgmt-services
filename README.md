Nix-based process management framework service repository
=========================================================
This repository contains a collection of services that can be deployed with the
experimental
[Nix process management framework](https://github.com/svanderburg/nix-processmgmt).

You can deploy systems that are constructed from running process instances
managed by a process manager of choice, use them as an unprivileged user, and run
multiple process instances on the same machine.

Constructor functions
=====================
Process instances that are deployed by the Nix process management framework are
typically constructed from *constructor functions*:

* `services-agnostic/` folder contains constructor functions for all kinds of
  commonly used services.
* `service-containers-agnostic/` extends a subset of the constructor functions
  with [Dysnomia](https://github.com/svanderburg/dysnomia) container
  configuration files so that these services can become containers (deployment
  targets) for [Disnix](https://github.com/svanderburg/disnix) deployments.

Example deployments
===================
The `example-deployments/` folder contains deployment specifications for example
systems that consist of multiple processes:

* `services`: demonstrates how to deploy many kinds of commonly used services:
  MySQL, PostgreSQL, Nginx, the Apache HTTP server, `svnserve`, Docker etc.
* `hydra`: demonstrates how to deploy [Hydra](https://nixos.org/hydra): the
  Nix-based continuous integration system

Deploying the example systems
=============================
The above examples can be deployed by running any of the `nixproc-*-switch`
tools provided by the Nix process management framework. Each process manager
backend has its own implementation.

For example, to deploy the system as sysvinit scripts, use:

```bash
$ nixproc-sysvinit-switch processes.nix
```

The above command needs to be run as root user, so that unprivileged users can
be created for each service.

To deploy a system as an unprivileged user, use:

```bash
$ nixproc-sysvinit-switch --state-dir $HOME/var --force-disable-user-change processes.nix
```

The above command-line parameters have the following purposes:
* The `--state-dir` parameter changes the global state directory to the `var`
  folder in the user's home directory.
* `--force-disable-user-change` disables all user operations (e.g. creating
  users, changing ownership), which an unprivileged user typically is not
  allowed to do.

To do a stateless deployment of the system with supervisord as an unprivileged
user, use:

```bash
$ nixproc-supervisord-deploy-stateless --state-dir $HOME/var --force-disable-user-change processes.nix
```

The above command activates the system as a whole and keeps `supervisord`
running in the foreground. Terminating `supervisord` causes the entire system
to get deactivated.

License
=======
The contents of this package is available under the same license as Nixpkgs --
the [MIT](https://opensource.org/licenses/MIT) license.
