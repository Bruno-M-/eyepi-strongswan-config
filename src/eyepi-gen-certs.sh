#!/bin/bash

# Generate CA certificate and key
eyepi-gen-ca-cert.sh

# Generate Gateway certificate and key
eyepi-gen-gtw-cert.sh

# Generate roadwarior clients certificates and keys
while true; do
	read -p "Do you want to generate a client certificate ? " yn
	case $yn in
		[Yy]* ) eyepi-gen-client-cert.sh;;
		[Nn]* ) exit;;
		* ) echo "Please answer yes or no.";;
	esac
done
