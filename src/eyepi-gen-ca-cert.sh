#!/bin/bash 

if [ "$(id -u)" -ne "0" ]
then
	echo "You must be root"
	echo "Try sudo $0"
	exit 1
fi

echo "=== Generating Strongswan CA =="

echo "-- Private key --"

CA_PRIV_KEY=/etc/ipsec.d/private/strongswan_key.pem

if ! ipsec pki --gen --type rsa --size 4096 \
	       --outform pem \
	       > ${CA_PRIV_KEY}
then
	echo "Error while generating CA private key"
	[ -e ${CA_PRIV_KEY} ] && rm ${CA_PRIV_KEY}
	exit 1
fi

if ! chmod 600 ${CA_PRIV_KEY}
then
	echo "Error while setting rights fo CA private key"
	[ -e ${CA_PRIV_KEY} ] && rm ${CA_PRIV_KEY}
	exit 1
fi
echo "-- Done --"

echo "-- Certificate --"

CA_CERT=/etc/ipsec.d/cacerts/strongswan_cert.pem

if ! ipsec pki --self --ca --lifetime 365 \
	       --in ${CA_PRIV_KEY} --type rsa \
	       --dn "C=FR, O=eyepibot, CN=strongSwan Root CA" \
	       --outform pem \
	       > ${CA_CERT}
then
	echo "Error while generating CA certificate"
	[ -e ${CA_PRIV_KEY} ] && rm ${CA_PRIV_KEY}
	[ -e ${CA_CERT} ] && rm ${CA_CERT}
	exit 1
fi
echo "-- Done --"

echo "=== Strongswan CA generated ==="

for client in Debian eyepi
do
	eyepi-gen-client-cert.sh ${client}
done

exit 0
