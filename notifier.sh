#!/bin/bash
sudo apt update
sudo apt install curl -y < "/dev/null"
cat << 'EOT' > $HOME/agoric_notifier.sh
#!/bin/bash
while true 
do
	VOTING_POWER=`curl -s localhost:26660 | awk '/tendermint_consensus_validator_power{.*} (.*)/{print $2}'`
	echo "Current VP: ${VOTING_POWER}"
	if [[ "${VOTING_POWER}" -eq "0"  ]]; then
		echo 'Jailed, send notify...';
		curl -X POST https://textbelt.com/text \
		   --data-urlencode phone='79112223344' \
		   --data-urlencode message='[Agoric] Your validator in jail!📱' \
		   -d key=textbelt
		echo 'Sended';
		sleep 1800
	else
		echo 'Not in jail';
	fi
	sleep 10
done
EOT
chmod +x $HOME/agoric_notifier.sh
sudo tee <<EOF >/dev/null /etc/systemd/system/agoric-notifier.service
[Unit]
Description=Agoric jail monitor daemon
After=network-online.target
[Service]
User=$USER
ExecStart=/bin/bash $HOME/agoric_notifier.sh
Restart=on-failure
RestartSec=3
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable agoric-notifier
sudo service agoric-notifier restart
sudo service agoric-notifier status
