#!/bin/bash

if [ "$(id -u)" -ne "0" ]
then
	echo "You must be root"
	echo "Try sudo $0"
	exit 1
fi


read -p "Enter Gateway IP : " GATEWAY

echo ""
echo "Using [${GATEWAY}] has Gateway IP"
echo ""

CA_PRIV_KEY=/etc/ipsec.d/private/strongswan_key.pem
CA_CERT=/etc/ipsec.d/cacerts/strongswan_cert.pem

echo "=== Generating Gateway certifcate =="

echo "-- Private key --"

FILE_KEY=/etc/ipsec.d/private/eyepi_key.pem

if ! ipsec pki --gen --type rsa --size 4096 \
	       --outform pem \
	       > ${FILE_KEY}
then
	echo "Error while generating Gateway private key"
	[ -e ${FILE_KEY} ] && rm ${FILE_KEY}
	exit 1
fi

if ! chmod 600 ${FILE_KEY}
then
	echo "Error while setting rights fo Gateway private key"
	[ -e ${FILE_KEY} ] && rm ${FILE_KEY}
	exit 1
fi
echo "-- Done --"

echo "-- Certificate --"

FILE_CERT=/etc/ipsec.d/certs/eyepi_cert.pem

if ! ipsec pki --pub --in ${FILE_KEY} --type rsa | \
	   ipsec pki --issue --lifetime 365 \
		     --cacert ${CA_CERT} \
		     --cakey ${CA_PRIV_KEY} \
		     --dn "C=FR, O=eyepibot, CN=eyepi" \
		     --san eyepi \
		     --san ${GATEWAY} \
		     --outform pem > ${FILE_CERT}
then
	echo "Error while generating Gateway certificate"
	[ -e ${FILE_KEY} ] && rm ${FILE_KEY}
	[ -e ${FILE_CERT} ] && rm ${FILE_CERT}
	exit 1
fi
echo "-- Done --"

echo "-- ipsec secret file --"

FILE_SEC=/etc/ipsec.secrets

echo "" >> ${FILE_SEC}
echo " : RSA eyepi_key.pem" >> ${FILE_SEC}

if ! chmod 600 ${FILE_SEC}
then
	echo "Error while setting rights fo Gateway ipsec secrets file"
	[ -e ${FILE_KEY} ] && rm ${FILE_KEY}
	[ -e ${FILE_CERT} ] && rm ${FILE_CERT}
	[ -e ${FILE_SEC} ] && rm ${FILE_SEC}
	exit 1
fi
echo "-- Done --"

echo "=== Gateway certificate generated ==="

exit 0
