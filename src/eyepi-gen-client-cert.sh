#!/bin/bash

if [ "$(id -u)" -ne "0" ]
then
	echo "You must be root"
	echo "Try sudo $0"
	exit 1
fi

if [ -z "${1}" ]
then
	echo "Please provide a common name"
	echo "Example: $0 foo"
	exit 1
fi

CN=${1}
FILE_DIR=/root/${CN}_secrets

CA_PRIV_KEY=/etc/ipsec.d/private/strongswan_key.pem
CA_CERT=/etc/ipsec.d/cacerts/strongswan_cert.pem

echo "=== Generating ${CN} certifcate =="

echo "-- Private key --"

FILE_KEY=${FILE_DIR}/private/${CN}_key.pem

[ ! -d $(dirname ${FILE_KEY}) ] && mkdir -p $(dirname ${FILE_KEY})
if ! ipsec pki --gen --type rsa --size 4096 \
	       --outform pem \
	       > ${FILE_KEY}
then
	echo "Error while generating ${CN} private key"
	[ -e ${FILE_KEY} ] && rm ${FILE_KEY}
	exit 1
fi

if ! chmod 600 ${FILE_KEY}
then
	echo "Error while setting rights fo ${CN} private key"
	[ -e ${FILE_KEY} ] && rm ${FILE_KEY}
	exit 1
fi
echo "-- Done --"

echo "-- Certificate --"

FILE_CERT=${FILE_DIR}/certs/${CN}_cert.pem

[ ! -d $(dirname ${FILE_CERT}) ] && mkdir -p $(dirname ${FILE_CERT})
if ! ipsec pki --pub --in ${FILE_KEY} --type rsa | \
	   ipsec pki --issue --lifetime 365 \
		     --cacert ${CA_CERT} \
		     --cakey ${CA_PRIV_KEY} \
		     --dn "C=FR, O=eyepibot, CN=${CN}" \
		     --san ${CN} \
		     --outform pem > ${FILE_CERT}
then
	echo "Error while generating ${CN} certificate"
	[ -e ${FILE_KEY} ] && rm ${FILE_KEY}
	[ -e ${FILE_CERT} ] && rm ${FILE_CERT}
	exit 1
fi
echo "-- Done --"

echo "-- ipsec secret file --"

FILE_SEC=${FILE_DIR}/ipsec.secrets

cat > ${FILE_SEC} << EOF
# This file holds shared secrets or RSA private keys for authentication.

# RSA private key for this host, authenticating it to any other host
# which knows the public part.

# this file is managed with debconf and will contain the automatically created private key

 : RSA ${CN}_key.pem

EOF

if ! chmod 600 ${FILE_SEC}
then
	echo "Error while setting rights fo ${CN} ipsec secrets file"
	[ -e ${FILE_KEY} ] && rm ${FILE_KEY}
	[ -e ${FILE_CERT} ] && rm ${FILE_CERT}
	[ -e ${FILE_SEC} ] && rm ${FILE_SEC}
	exit 1
fi
echo "-- Done --"

echo "=== ${CN} certificate generated ==="

exit 0
