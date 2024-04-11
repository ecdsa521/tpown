# TP own
Simple script for hacking your TP-Link M7350 LTE modem/router

# Usage:
    $ ruby tp.rb -t [ip] -p [password] 
        Options:
        -s, --ssh                  Install dropbear SSH server
        -a, --adb                  Enable ADBD service
        -k, --keep                 Keep the telnetd payload
        -p, --pass=<s>             Web interface password
        -t, --target=<s>           Target IP
        -r, --rce=<i>              RCE version, 1, 5 or autodetect if left empty
        -d, --dropbear-bin=<s>     Dropbear binary location (default:
                                    https://raw.githubusercontent.com/ecdsa521/tpown/main/dropbearmulti)
        -o, --dropbear-init=<s>    Dropbear init script location (default:
                                    https://raw.githubusercontent.com/ecdsa521/tpown/main/dropbearserver.sh)
        -h, --help                 Show this message



# How does it work
First user is logged in, token is saved, then used to launch RCE in one of two versions. RCE spawns telnet server and payload is deleted

Telnet server is used to enable adb and/or ssh server


Thanks to [4pda.to](https://4pda.to/forum/index.php?showtopic=669936) and [m0veax](https://github.com/m0veax/tplink_m7350) for RCE and research
