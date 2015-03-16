#!/bin/bash

if [ "$(id -u)" -ne "0" ]
then
	echo "You must be root"
	echo "Try sudo $0"
	exit 1
fi

echo "=== Generating client certifcate ==="
echo ""
read -p "Please provide a common name: " CN

if [ -z "${CN}" ]
then
	echo "Error empty common name"
	exit 1
fi

FILE_DIR=/root/${CN}_secrets

CA_PRIV_KEY=/etc/ipsec.d/private/strongswan_key.pem
CA_CERT=/etc/ipsec.d/cacerts/strongswan_cert.pem

echo ""
echo "=== Generating ${CN} certifcate ==="

echo "-- Private key --"

FILE_KEY=${FILE_DIR}/ipsec.d/private/${CN}_key.pem

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

FILE_CERT=${FILE_DIR}/ipsec.d/certs/${CN}_cert.pem

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
#Copy client certificate to Gateway certs directory
cp ${FILE_CERT} /etc/ipsec.d/certs/

echo "-- Done --"

echo "-- Convert to PKCS#12 --"

FILE_P12=${FILE_DIR}/${CN}_cert.p12

openssl pkcs12 -export -inkey ${FILE_KEY} -in ${FILE_CERT} -name "${CN}" -certfile ${CA_CERT} -caname "strongswan" -out ${FILE_P12}

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

read -p "Please provide a login: " LOGIN
echo ""
read -p "Please provide a password: " PASSWD

echo "${LOGIN} : EAP \"${PASSWD}\"" >> /etc/ipsec.secrets

if ! chmod 600 ${FILE_SEC}
then
	echo "Error while setting rights fo ${CN} ipsec secrets file"
	[ -e ${FILE_KEY} ] && rm ${FILE_KEY}
	[ -e ${FILE_CERT} ] && rm ${FILE_CERT}
	[ -e ${FILE_SEC} ] && rm ${FILE_SEC}
	exit 1
fi
echo "-- Done --"

echo "-- Save strongswan CA --"

DIR_CA=${FILE_DIR}/ipsec.d/cacerts

[ ! -d ${DIR_CA} ] && mkdir -p ${DIR_CA}
cp ${CA_CERT} ${DIR_CA}

echo "-- Done --"

echo "=== ${CN} certificate generated ==="

exit 0
