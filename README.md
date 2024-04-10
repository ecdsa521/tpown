# TP own
Simple script for hacking your TP-Link M7350 LTE modem/router

# Usage:
    $ ruby tp.rb -t [ip] -p [password] [--adb] [--ssh] [-5/-1] 

- -1 switch is for older board revision, uses language RCE
- -5 switch is for v5 board or newer, uses PortForward RCE
- --ssh will automatically download and install dropbear ssh server. Dropbear build from https://bitfab.org/dropbear-static-builds/
- --adb will automatically enable adbd so you can use adb shell

# How does it work
First user is logged in, token is saved, then used to launch RCE in one of two versions. RCE spawns telnet server and payload is deleted

Telnet server is used to enable adb and/or ssh server


Thanks to [4pda.to](https://4pda.to/forum/index.php?showtopic=669936) and [m0veax](https://github.com/m0veax/tplink_m7350) for RCE and research
