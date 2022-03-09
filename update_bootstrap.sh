#!/bin/bash

#config file
source /root/bootstrap_mirror_server/bootstrap_config

function setup(){

if ! jq --version > /dev/null 2>&1
then
echo -e "Installing system dependencies..."
sudo apt install -y gzip jq pigz curl wget > /dev/null 2>&1
fi

if [[ ! -f /$home_dir/bootstrap_mirror_server/discord.sh ]]; then
echo -e "Downloading Discord script..."
wget https://raw.githubusercontent.com/ChaoticWeg/discord.sh/master/discord.sh -O /$home_dir/bootstrap_mirror_server/discord.sh > /dev/null 2>&1 
sudo chmod +x /$home_dir/bootstrap_mirror_server/discord.sh

echo -e "Creating Cron job..."
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
    echo -e "Checking bootstrap file integration..."
    if pigz -t "$1" &>/dev/null; then
        echo -e "Bootstrap file is valid!"
    else
        echo -e "Bootstrap file is corrupt!"
        rm -rf $1
    fi
}

#install dependencies
setup

if [[ -f /$home_dir/bootstrap_update_lock ]]; then
 data=$(date -u)
 echo -e "Another instance of this script already exist! Exiting"
 echo -e "======================================================[$data][END]"
 exit
fi

echo 'Running' >> /$home_dir/bootstrap_update_lock

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
  --webhook-url="$web_hook_url" \
  --username "Notification" \
  --title " :loudspeaker: \u200b  Bootstrap Update Notification" \
  --color "0xFFFFFF" \
  --field "Server;$server_name" \
  --field "Status;Downloading..."

    echo -e "Bootstrap is outdated!"
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
  --webhook-url="$web_hook_url" \
  --username "Notification" \
  --title " :loudspeaker: \u200b  Bootstrap Update Notification" \
  --color "0xFFFFFF" \
  --field "Server;$server_name" \
  --field "Status;Completed"

    else

     echo -e "Bootstrap was not created!"

    fi

  fi
  
else
echo -e "Creating bootstrap skipped! Block height not reachable..."
fi

echo  -e "======================================================[$data][END]"

fi

rm -rf /$home_dir/bootstrap_update_lock > /dev/null 2>&1
