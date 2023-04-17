#!/bin/bash

# /****************** SELF SIGNED CERTIFICATE GENERATOR ******************/
# /* Generate signing keys, self-signed certificated using given type
#  * (RSA, ECSDA, ED25519), RootCA certs using SAN attribute and web
#  * server certs.
#  * Usage example : self-signed_certs.sh -t RSA -o ./certs \
#  -d euphoria-laxis.com -e webmaster@euphoria-laxis.com -C FR \
#  -S IDF -O EuphoriaLaxis -U EuphoriaLaxis -L FR
# * will generate self-signed certs and signing keys for domain
# * euphoria-laxis.com with email address webmaster@euphoria-laxis.com,
# * country FRANCE, state Île de France (IDF), Local FR, for
# * organization Euphoria Laxis unit Euphoria Laxis using RSA
# * encryption into directory ./certs.
#  */

while getopts ":o:t:d:e:C:S:O:U:L:" option; do
    case "${option}" in
        o)
            output=${OPTARG}
            ;;
        t)
            type=${OPTARG}
            ((type == "RSA" || type == "ECDSA" || type == "ED25519")) || usage
            ;;
        d)
            domain=${OPTARG}
            ;;
        e)
            email=${OPTARG}
            ;;
        C)
            country=${OPTARG}
            ;;
        S)
            countryState=${OPTARG}
            ;;
        O)
            organization=${OPTARG}
            ;;
        U)
            organizationUnit=${OPTARG}
            ;;
        L)
            local=${OPTARG}
            ;;
        :)
            echo "$OPTARG option require arguments"
            usage
            exit 1
            ;;
        \?)
            echo "$OPTARG : invalid option"
            exit 1
            ;;
    esac
done

usage () {
    echo "o   output:       Output directory"
    echo "t   type:         Encryption type [RSA,ECDSA,ED25519]. Default: RSA"
    echo "d   domain:       Server domain"
    echo "e   email:        Email given in certificate cnf file"
    echo "C   country:      Country where the organization is located"
    echo "S   state:        State where the organization is located"
    echo "O   organization: Name of the organization"
    echo "U   unit:         Organization unit"
    echo "L   local:        Local of the organization"
    echo Bye!
}

generateCsrConf () {
cat << 'EOF' > $output/domain.csr.cnf
[req]
prompt = no
default_md = sha256
distinguished_name = dn
[dn]
EOF
echo "C= $country" >> "$output"/domain.csr.cnf
echo "ST= $countryState" >> "$output"/domain.csr.cnf
echo "L= $local" >> "$output"/domain.csr.cnf
echo "O= $organization" >> "$output"/domain.csr.cnf
echo "OU= $organizationUnit" >> "$output"/domain.csr.cnf
echo "emailAddress= $email" >> "$output"/domain.csr.cnf
echo "CN= $domain" >> "$output"/domain.csr.cnf
}

generateV3 () {
# Create an X.509 v3 extension config file for the cert request (SAN required to make Chrome happy)
# shellcheck disable=SC2046
cat << 'EOF' > $output/domain.v3.ext
# v3.ext
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName= @alt_names
# SAN
[alt_names]
EOF
echo "DNS.1 = $domain" >> "$output"/domain.v3.ext
}

# Generate RSA signing keys for RSA certs
generateRsaSigningKeys () {
    printf "
Generate RSA signing keys
"
    openssl genrsa -out "$output"/rootCA.key 4096
    openssl genrsa -out "$output"/server.key 4096
}

# Generate ECC signing keys for ECDSA certs
generateEcdsaSigningKeys () {
    printf "
Generate ECDSA signing keys
"
    openssl ecparam -genkey -name prime256v1 -out "$output"/rootCA.key
    openssl ecparam -genkey -name prime256v1 -out "$output"/server.key
}

# Generate ED25519 signing keys for ECC certs
generateEd25519SigningKeys () {
    printf "
Generate ED25519 signing keys
"
    openssl genpkey -algorithm ED25519 -out "$output"/rootCA.key
    openssl genpkey -algorithm ED25519 -out "$output"/server.key
}

# Generate self-signed root CA cert
generateSelfSignedRootCaCert () {
    printf "
Generate self-signed root CA
"
    openssl req -x509 -new -key "$output"/rootCA.key -sha256 -days 3650 \
    -subj '/O=Cert-O-Matic/OU=You get a cert and YOU get a cert/C=US/CN=Certs R Us' \
    -out "$output"/rootCA.pem
}

# Create domain name certificate request, signed with our server key
createDomainNameCertRequest () {
    printf "
Create domain name certificate request signed with our server key
"
    openssl req -new -sha256 -nodes -out "$output"/domain.csr -key "$output"/server.key \
    -config "$output"/domain.csr.cnf
}

# Generate a public web server cert (cert.pem) with the SAN attributes, signed by our root CA
generatePublicServerCert () {
    printf "
Generate a public web server cert (cert.pem) with the SAN attributes, signed by our root CA
"
    openssl x509 -req -in "$output"/domain.csr -CA "$output"/rootCA.pem -CAkey \
    "$output"/rootCA.key -CAcreateserial -out "$output"/cert.pem -days 183 -sha256 \
    -extfile "$output"/domain.v3.ext
}

if [[ $type == "RSA" ]];then
    generateRsaSigningKeys
elif [[ $type == "ECDSA" ]]; then
    generateEcdsaSigningKeys
elif [[ $type == "ED25519" ]]; then
    generateEd25519SigningKeys
else
    # This should never happen
    printf "
An error occurred, requested type is incorrect. Valid types : [RSA,ECDSA,ED25519]
"
exit 130
fi

generateCsrConf
generateV3
generateSelfSignedRootCaCert
createDomainNameCertRequest
generatePublicServerCert

printf "
Certificate and Key were created successfully.
"
