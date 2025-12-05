#!/bin/bash

echo """
                    ##        .            
              ## ## ##       ==            
           ## ## ## ##      ===            
       /``````````````\___/ ===        
      {~~ ~~~~ ~~~ ~~~~ ~~ ~ / ===---  
       \______ o          __/            
        \/\/\/\ __________/
           /\/\/         /   
           \_____\______/    Dockextricate 
"""
echo " Testing for any privilage  escape potential from this container "

echo "=============  Detecting OS type and version  ============="
. /etc/os-release && echo "$PRETTY_NAME"
echo " "

echo "=========  Checking if running as root user ========="
if [ "$(id -u)" -eq 0 ]; then
    echo "OK: you are root user, enjoy :)"
else
    echo "you are not root user, proceeding with further checks..."
fi

echo " "
echo "========= checking if the container is privileged  ========="

if  find /dev/sda /dev/kmsg /dev/mem * 1>/dev/null 2>&1; then
    echo "Container appears to be privileged (has access to host devices)."
else
    echo "Container does not appear to be privileged."
fi 

echo " "
echo " ========== Checking if 'sudo' command is available =========="
if ! command -v sudo >/dev/null 2>&1; then
    echo "FAIL: 'sudo' is not installed or not in PATH."
elif sudo -n true 2>/dev/null; then
    echo "OK: 'sudo' is available and can be used without a password."
else
    echo "FAIL: 'sudo' is installed but requires a password."
    exit 1
fi

echo " "
echo "================== Checking current username & group... ==================="
user="$(whoami)"
group="$(id -gn)"
echo "Current User  : $user"
echo "Current Group or Groups : $group"

if id -nG | grep -qw sudo; then
    echo "the user is in sudoers group."
elif id -nG | grep -qw docker; then
    echo "the user is docker group."
else
    echo "the user is not in sudoers or docker group."
fi

echo " "
echo " =============== Checking for SUID/SGID files ====================="
find / -type f \( -perm -4000 -o -perm -2000 \) -exec ls -ld {} \; 2>/dev/null 

echo " "
echo " ============== Checking for process running any programm  file  which can be accesable  to current user ===================="

echo "User: $(id -un) (UID=$(id -u), GID=$(id -g))"
echo "---- Files that can be accessed by this user  ----"

for pid in $(ls /proc | grep '^[0-9]'); do
    if [ -r "/proc/$pid/comm" ]; then
        exe=$(readlink /proc/$pid/exe 2>/dev/null)
        cmdline=$(tr '\0' ' ' < /proc/$pid/cmdline 2>/dev/null)
        name=$(cat /proc/$pid/comm 2>/dev/null)

        # Only show if the command looks like a script or program (not system daemons)
        if [[ "$cmdline" =~ \.py|\.js|\.sh|\.pl|\.go|\.rb ]] || [[ "$name" =~ ^(python|node|php|go|java)$ ]]; then
            echo "PID=$pid | CMD=$name | EXE=$exe | CMDLINE=$cmdline"
        fi
    fi
done

echo " "
echo " ======== checking capabilities  of container =========="

grep Cap /proc/self/status

echo " "
echo "======= Scanning network ======="

# Get container IPs
myip=$(hostname -i)
echo "Container IPs: $myip"

while read iface destination gateway flags rest; do
  if [ "$destination" = "00000000" ]; then
    gw_hex=$gateway
    gw_ip=""
    for i in {0..3}; do
      part=$((16#${gw_hex:$((i*2)):2}))
      gw_ip="$part${gw_ip:+.$gw_ip}"
    done
  fi
done < /proc/net/route
echo "Default Gateway: $gw_ip"

check_Gateway_connect() {
    output=$(timeout 2 bash -c ">/dev/tcp/$gw_ip/80" 2>&1)
    if echo "$output" | grep -q "Connection refused"; then
        echo "Connection to $gw_ip:Gateway successful"
    else
        echo "Connection to $gw_ip:Gateway failed"
    fi
}

check_container_ports() {
    ports=(80 443 22 8080 8000 3306 5432 6379 27017)
    for port in "${ports[@]}"; do
        output=$(timeout 3 bash -c ">/dev/tcp/$myip/$port" 2>/dev/null && echo "open" || echo "closed")
        if [ "$output" = "open" ]; then
            echo "Local Port $port: listening"
        fi
    done
}

check_Gateway_connect
check_container_ports

echo " "
echo "=========== see if docker.sock  is mounted from host ============="

if ls -la /var/run/docker.sock 1>/dev/null 2>&1; then
    echo "Docker socket found at /var/run/docker.sock"
else
    echo "No Docker socket found."
fi

echo " "

echo " ========== Detecting Mounted filesystems ======= "
mounts=$(awk '{print $1}' /proc/mounts | grep -E '/dev/sda|/dev/xvda|/dev/vda' | uniq)
if [ -n "$mounts" ]; then
    echo " Mounted devices found "$mounts""
else
    echo "No device mounts found."
fi

# End of script








