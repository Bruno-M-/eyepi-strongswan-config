#!/bin/bash

CLIENT_LIST="eyepi Debian"

# Generate CA certificate and key
eyepi-gen-ca-cert.sh

# Generate clients certificates and keys
for client in ${CLIENT_LIST}
do
	eyepi-gen-client-cert.sh ${client}
done
