#!/usr/bin/bash

set -e
function sudocheck {
user=$(whoami)
if [ "$user" != "root" ]; then
echo "Use Sudo su"
exit 1
fi
}
select option in Install_Docker Install_SoftEther Install_v2ray Exit; do
	case $option in
##Install Docker Code
		"Install_Docker")
#check linux version
			if grep -i ubuntu /etc/os-release > /dev/null; then
			echo "Your Distro is Ubuntu"
			else
			exit 1
			echo "You can Just use Ubuntu"
			fi
#check user
			sudocheck
#Update apt & Install dependency
			apt-get update && apt-get install \
				ca-certificates \
				curl \
				gnupg \
				lsb-release -y
#Create key directory
			sed -i '1 i\nameserver 178.22.122.100' /etc/resolv.conf
			mkdir -m 0755 -p /etc/apt/keyrings
			curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg \
			--dearmor -o /etc/apt/keyrings/docker.gpg
#echo key
			echo \
			"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
			$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
			apt-get update
			apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose -y
				;;
## Softether Installation Code
		"Install_SoftEther")
			sudocheck
			if grep -i 20.04 /etc/os-release > /dev/null; then
			echo "Your Distro Ubuntu 20.04"
                        else
                          echo "You can just use Ubuntu 20.04"
			  exit 1
                        fi
			apt-get update -y
			apt-get install build-essential gnupg2 gcc make -y
			uname -a | grep -i x86_64 > /dev/null
			if [ $(echo $?) -eq 0 ] ; then
			echo "Your Arch is OK!"
			else
			   echo "This script is just for Intel x64 arch we'll update soon :)"
			exit 1  
			fi
			ls | grep -i softether > /dev/null
			if [ $(echo $?) -ne 0 ]; then
			wget http://www.softether-download.com/files/softether/v4.38-9760-rtm-2021.08.17-tree/Linux/SoftEther_VPN_Server/64bit_-_Intel_x64_or_AMD64/softether-vpnserver-v4.38-9760-rtm-2021.08.17-linux-x64-64bit.tar.gz
			fi
			tar -xvzf softether-vpnserver-v4.38-9760-rtm-2021.08.17-linux-x64-64bit.tar.gz
			cd vpnserver
			make
			cd ..
			mv vpnserver /usr/local/
			cd /usr/local/vpnserver/
			chmod 600 *
			chmod 700 vpnserver
			chmod 700 vpncmd
			touch /etc/init.d/vpnserver
			cd -
			cat service > /etc/init.d/vpnserver
			chmod 755 /etc/init.d/vpnserver
			/etc/init.d/vpnserver start
			update-rc.d vpnserver defaults
			systemctl daemon-reload
			systemctl start vpnserver
			systemctl enable vpnserver
				;;
		"Exit")
			echo "Have a nice day :)"
			exit 1
			;;
		"Install_v2ray")
			which docker > /dev/null
			if [ $(echo $?) -ne 0 ]; then
			echo "Install Docker First!"
                        exit 1
                        fi
			select role in Bridge-server Upstream-server Exit; do
				case $role in
				"Bridge-server")
					sudocheck
					sed -i '1 i\nameserver 178.22.122.100' /etc/resolv.conf
					read -p "Enter Your Upstream IP: " UIP
					read -p "Enter Your Upstream Port: " Uport
					read -p "Enter Your UpstreamUUID: " UPuuid
					read -p "Enter Your Bridge Port: " Bport
					read -p "Server name: " name
					cd  ./v2ray/v2ray-bridge-server
					sed -i "s/Bport/$Bport/g" docker-compose.yml
					sed -i "s/Name/$name/g" docker-compose.yml
					sed -i "s/BRIDGE-PORT/$Bport/g" ./config/config.json
					sed -i "s/UPSTREAM-IP/$UIP/g" ./config/config.json
					sed -i "s/UPSTREAM-PORT/$Uport/g" ./config/config.json
					sed -i "s/BRIDGE-UUID/$(uuidgen)/g" ./config/config.json
					sed -i "s/UPSTREAM-UUID/$UPuuid/g" ./config/config.json
					docker-compose up -d
					python3 clients.py
					;;
				"Exit")
					echo "Have a nice day :)"
						exit 1
					;;
				"Upstream-server")
					sudocheck
					read -p "Enter Your UpstreamUUID: " UPuuid
					read -p "Enter Your Upstream Port: " Uport
					read -p "Server name: " name
					cd  ./v2ray/v2ray-upstream-server
					sed -i "s/Uport/$Uport/g" docker-compose.yml
					sed -i "s/Name/$name/g" docker-compose.yml
					sed -i "s/UPSTREAM-PORT/$Uport/g" ./config/config.json
					sed -i "s/UPSTREAM-UUID/$UPuuid/g" ./config/config.json
					docker-compose up -d
					;;
				esac
			done
	esac
done



