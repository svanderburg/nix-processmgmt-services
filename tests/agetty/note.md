This test is for setting up a connection with a null modem cable that works
to link up my PC with my Commodore Amiga 500.

It cannot be automated with the NixOS test driver, but you can manually deploy
it by running the following command as root user:

```bash
nixproc-supervisord-deploy-stateless processes.nix
```
