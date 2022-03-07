#!/bin/bash

username="root"
server_name="cdn-5.runonflux.io"
home_dir="root"                                        
upload_dir="fluxshare/ZelApps/ZelShare"
source_url="cdn-4.runonflux.io/apps/fluxshare/getfile"

function setup(){

if ! jq --version > /dev/null 2>&1
then
echo -e "Installing system dependencies..."
sudo apt install -y gzip jq curl wget > /dev/null 2>&1
fi

if [[ ! -f /$home_dir/bootstrap_mirror_server/discord.sh ]]; then
echo -e "Downloading discord script..."
wget https://raw.githubusercontent.com/ChaoticWeg/discord.sh/master/discord.sh -O /$home_dir/bootstrap_mirror_server/discord.sh > /dev/null 2>&1 
sudo chmod +x /$home_dir/bootstrap_mirror_server/discord.sh

echo -e "Creating crone jobe..."
(crontab -l -u "$username" 2>/dev/null; echo "*/30 * * * * bash /$home_dir/bootstrap_mirror_server/update_bootstrap.sh >> /$home_dir/bootstrap_mirror_server/bootstrap_debug.log 2>&1") | crontab -
fi

if [[ ! -d /$home_dir/$upload_dir ]]; then
echo -e "Creating upload directory..."
sudo mkdir -p /$home_dir/$upload_dir
fi

if [[ ! -f /$home_dir/$upload_dir/flux_explorer_bootstrap.json ]]; then
echo -e "Creating bootstrap info file..."
mv /$home_dir/bootstrap_mirror_server/flux_explorer_bootstrap.json /$home_dir/$upload_dir
mv /$home_dir/bootstrap_mirror_server/daemon_bootstrap.json /$home_dir/$upload_dir
fi

}


function check_tar()
{
    echo -e "Checking  bootstrap file integration..."
    if gzip -t "$1" &>/dev/null; then
        echo -e "Bootstrap file is valid!"
    else
        echo -e "Bootstrap file is corrupted!"
        rm -rf $1
    fi
}

#install dependencies
setup

if [[ `pgrep -f $0` != "$$" ]]; then
 data=$(date -u)
 echo -e "Another instance of shell already exist! Exiting"
 echo -e "======================================================[$data][END]"
 exit
fi

if [[ -f /$home_dir/$upload_dir/daemon_bootstrap.json ]]; then

data=$(date -u)
local_bootstrap_height=$(cat /$home_dir/$upload_dir/daemon_bootstrap.json | jq -r .block_height)
bootstrap_server_height=$(curl -SsL -m 10 https://cdn-4.runonflux.io/apps/fluxshare/getfile/daemon_bootstrap.json | jq -r .block_height)

echo -e ""
echo -e "Local bootstrap height = $local_bootstrap_height"
echo -e "Server bootstrap height = $bootstrap_server_height"

if [[ "$local_bootstrap_height" != "" && "$bootstrap_server_height" != "" ]]; then

  if [[ "$local_bootstrap_height" == "$bootstrap_server_height" ]]; then

    echo -e "Bootstrap is up to date!"

  else

   bash /$home_dir/bootstrap_mirror_server/discord.sh \
  --webhook-url="https://discord.com/api/webhooks/948287566069792840/IGJMvQiGOeDemIvX7bhK4bqgtGvXeScry1sAAxQsbw18qwiu15EbQWI-u-uBKt6JN6-A" \
  --username "Notification" \
  --title " :loudspeaker: \u200b  Bootstrap Update Notification" \
  --color "0xFFFFFF" \
  --field "Server;$server_name" \
  --field "Status;Downloading..."

    echo -e "Bootstrap is outdate!"
    echo -e "Cleaning...."
    rm -rf /$home_dir/daemon_bootstrap.tar.gz > /dev/null 2>&1
    rm -rf /$home_dir/daemon_bootstrap.json > /dev/null 2>&1
    rm -rf /$home_dir/flux_explorer_bootstrap.tar.gz > /dev/null 2>&1
    rm -rf /$home_dir/flux_explorer_bootstrap.json > /dev/null 2>&1
    echo -e "Downloading...."
    wget https://$source_url/daemon_bootstrap.json -O /$home_dir/daemon_bootstrap.json > /dev/null 2>&1
    wget https://$source_url/daemon_bootstrap.tar.gz -O /$home_dir/daemon_bootstrap.tar.gz > /dev/null 2>&1
    check_tar /$home_dir/daemon_bootstrap.tar.gz

    wget https://$source_url/flux_explorer_bootstrap.json -O /$home_dir/flux_explorer_bootstrap.json > /dev/null 2>&1
    wget https://$source_url/flux_explorer_bootstrap.tar.gz -O /$home_dir/flux_explorer_bootstrap.tar.gz > /dev/null 2>&1
    check_tar /$home_dir/flux_explorer_bootstrap.tar.gz


    if [[ -f /$home_dir/daemon_bootstrap.tar.gz && -f /$home_dir/flux_explorer_bootstrap.tar.gz ]]; then

       rm -rf /$home_dir/$upload_dir/daemon_bootstrap.json
       rm -rf /$home_dir/$upload_dir/daemon_bootstrap.tar.gz
       mv /$home_dir/daemon_bootstrap.json /$home_dir/$upload_dir
       mv /$home_dir/daemon_bootstrap.tar.gz /$home_dir/$upload_dir
       rm -rf /$home_dir/$upload_dir/flux_explorer_bootstrap.json
       rm -rf /$home_dir/$upload_dir/flux_explorer_bootstrap.tar.gz
       mv /$home_dir/flux_explorer_bootstrap.json /$home_dir/$upload_dir
       mv /$home_dir/flux_explorer_bootstrap.tar.gz /$home_dir/$upload_dir
       echo -e "Bootstrap created successful! Files updated..."

  bash /$home_dir/bootstrap_mirror_server/discord.sh \
  --webhook-url="https://discord.com/api/webhooks/948287566069792840/IGJMvQiGOeDemIvX7bhK4bqgtGvXeScry1sAAxQsbw18qwiu15EbQWI-u-uBKt6JN6-A" \
  --username "Notification" \
  --title " :loudspeaker: \u200b  Bootstrap Update Notification" \
  --color "0xFFFFFF" \
  --field "Server;$server_name" \
  --field "Status;Complited"

    else

     echo -e "Bootstrap was not created!"

    fi

  fi
  
else
echo -e "Creating bootstrap skipped! Block height not reachable..."
fi

echo  -e "======================================================[$data][END]"

fi
