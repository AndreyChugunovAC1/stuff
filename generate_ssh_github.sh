#!/bin/bash

read -p "Enter email: " email
ssh-keygen -t ed25519 -C "$email"
read -p "Enter path where you stored keys: " path
ssh-add "$path"
killall ssh-agent
ssh-agent
echo "Now try visiting https://docs.github.com/en/authentication/troubleshooting-ssh/error-host-key-verification-failed"
echo "Do not forget to add public key to Github: https://github.com/settings/keys"
