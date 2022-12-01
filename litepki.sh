#!/usr/bin/env bash

# Common OID, if you using ocserv this will helpful
# givenName --------------- 2.5.4.42"
# commonName -------------- 2.5.4.3"
# userID ------------------ 0.9.2342.19200300.100.1.1"

# ===============================================================================================================================

# Don't modify above this line

# Default signature expire date

[ -z "$DAYS" ] && DAYS="360"

# Common part

[ -z "$DIST_C" ] && DIST_C='CN'
[ -z "$DIST_ST" ] && DIST_ST='Beijing'
[ -z "$DIST_L" ] && DIST_L='Beijing'
[ -z "$DIST_O" ] && DIST_O='NoWhere'

# For Root CA

[ -z "$DIST_OU" ] && DIST_OU='NoWhere'
[ -z "$DIST_CN" ] && DIST_CN='NoWhere Root CA'
[ -z "$DIST_GN" ] && DIST_GN='NoWhere Root CA'

# For Intermediate CA Server

[ -z "$DIST_OU_S" ] && DIST_OU_S='NoWhere'
[ -z "$DIST_CN_S" ] && DIST_CN_S='NoWhere Intermediate CA For HTTP-SSL'

# For Intermediate CA Client

[ -z "$DIST_OU_C" ] && DIST_OU_C='NoWhere'
[ -z "$DIST_CN_C" ] && DIST_CN_C='NoWhere Intermediate CA For HTTP-SSL'

# Uncomment those line and change it to you CRL server address to enable crlDistributionPoints

X509_ROOT_CRL='URI:http://NoWhere.com/root.crl,URI:http://NoWhere.org/root.crl'
X509_SERV_CRL='URI:http://NoWhere.com/serv.crl,URI:http://NoWhere.org/serv.crl'

# Client Intermediate CA has no crlDistributionPoints support

# Don't modify after this line

# ===============================================================================================================================

# Common OID, if you using ocserv this will helpful
# givenName --------------- 2.5.4.42"
# commonName -------------- 2.5.4.3"
# userID ------------------ 0.9.2342.19200300.100.1.1"

if [ "$DIST_O" == "BlackTechStudio" ] || [ "$DIST_OU" == "BlackTechStudio IT Dept" ]; then
  echo '================================================================================'
  echo '         !!! REMEMBER MODIFY DEFAULT DN SETTING IN THE SCRIPT !!!'
  echo '================================================================================'
  echo ' ERROR: Default DN setting found!'
  echo ' ERROR: You should make a copy for each PKI system (directory)'
  echo ' ERROR: Then modify those copy DN section with your requirement'
  echo ' ERROR: LitePKI wont let you do any thing before you modify DN section'
  [ -z "$DEBUG" ] && exit 1
fi

# ===============================================================================================================================

function help() {
  echo '================================================================================'
  echo ' LitePKI help, for more help "sh litepki.sh help"'
  echo '================================================================================'
  echo 'sh litepki.sh i ----------------------- Generate PKI system in working directory'
  echo 'sh litepki.sh c <name> ------------------------------ Create Client CA with name'
  echo 'sh litepki.sh r <name> ------------------------------ Revoke Client CA with name'
  echo 'sh litepki.sh ur <name> -------------------------------------- Update RootCA CRL'
  echo 'sh litepki.sh us <name> ------------------------------------ Update ServerCA CRL'
  echo 'sh litepki.sh uc {name} ------------------------------------ Update ClientCA CRL'
  echo 'sh litepki.sh ms <name> -------------------------- Use ServerCA Sign CSR request'
  echo 'sh litepki.sh vs <name> ------------------------------ Create Server certificate'
  echo 'sh litepki.sh rs <name> ------------------------------ Revoke Server certificate'
  echo 'sh litepki.sh vc <name> <user>------------------------ Create Client certificate'
  echo 'sh litepki.sh rc <name> <user>------------------------ Revoke Client certificate'
  echo '================================================================================'
}

function helpAll() {
  echo '================================================================================'
  echo '> Install:'
  echo '    sh litepki.sh i'
  echo '--------------------------------------------------------------------------------'
  echo '> Create Client CA: Create new Intermediate CA for client SSL issuance'
  echo '    sh litepki.sh c dev'
  echo '    sh litepki.sh c ops'
  echo '--------------------------------------------------------------------------------'
  echo '> Revoke Client CA: Revoke the Intermediate CA for client SSL issuance'
  echo '    sh litepki.sh r dev'
  echo '    sh litepki.sh r ops'
  echo '--------------------------------------------------------------------------------'
  echo '> Manual Server Issue: Sign CSR'
  echo '    sh litepki.sh ms path/to/server.csr   Argument is path to file'
  echo '--------------------------------------------------------------------------------'
  echo '> Create Server Cert: User Server CA create a HTTPS certificate'
  echo '    O="Example Inc." \                    Env - DN Organization'
  echo '    OU="Dev of example Inc." \            Env - DN Organization Unit'
  echo '    CN="www.example.com,jenkins.a.xyz" \  Env - DN CommonName, Null for name'
  echo '    AN="www.example.com,jenkins.a.xyz" \  Env - SAN DNS List, Null for CN'
  echo '    IP="1.1.1.1,2.2.2.2,3.3.3.3" \        Env - SAN IP list, Null for nothing'
  echo '    sh litepki.sh vs www.example.com      Argument is folder name'
  echo '--------------------------------------------------------------------------------'
  echo '> Create Client Cert: Use Client CA called dev, Sign a cert for bob'
  echo '    O="Example Inc." \                    Env - DN Organization'
  echo '    OU="Dev of example Inc." \            Env - DN Organization Unit'
  echo '    CN="bob" \                            Env - DN CommonName, Null for name'
  echo '    GN="bob the big guy" \                Env - DN GivenName, Null for nothing'
  echo '    sh litepki.sh vc dev bob              Argument is folder name'
  echo '--------------------------------------------------------------------------------'
  echo '> Revoke Server Cert'
  echo '    sh litepki.sh vs www.example.com      Argument is folder name'
  echo '--------------------------------------------------------------------------------'
  echo '> Revoke Client Cert'
  echo '    sh litepki.sh vc dev bob              Argument is folder name'
  echo '--------------------------------------------------------------------------------'
  echo '> Update CRL for CAs'
  echo '    sh litepki.sh ur                      Update RootCA CRL file'
  echo '    sh litepki.sh us                      Update ServerCA CRL file'
  echo '    sh litepki.sh uc                      Update ClientCA CRL file, all ca'
  echo '    sh litepki.sh uc <name>               Update ClientCA CRL file, with name'
  echo '--------------------------------------------------------------------------------'
}

function install() {

  mkdir cert

  mkdir cert/ca-root
  mkdir cert/sub-server
  mkdir cert/sub-client

  mkdir cert/ca-root/output
  mkdir cert/sub-server/output

  touch cert/ca-root/index.txt
  touch cert/sub-server/index.txt

  echo '01' > cert/ca-root/serial.txt
  echo '01' > cert/sub-server/serial.txt

  cat > cert/ca-root/config-req.ini << EOF
HOME = .
[ ca ]
default_ca = @default_ca
[ default_ca ]
preserve         = no
default_days     = 30
default_crl_days = 30
default_md       = sha256
x509_extensions  = x509_extensions
email_in_dn      = no
copy_extensions  = copy
[ req ]
default_bits       = 2048
string_mask        = utf8only
x509_extensions    = x509_extensions
distinguished_name = distinguished_name
[ x509_extensions ]
subjectKeyIdentifier   = hash
basicConstraints       = critical, CA:true
authorityKeyIdentifier = keyid:always, issuer:always
keyUsage               = keyCertSign, cRLSign
crlDistributionPoints  = $X509_ROOT_CRL
[ distinguished_name ]
countryName                    = Country Name (2 letter code)
stateOrProvinceName            = State or Province Name (full name)
localityName                   = Locality Name (eg, city)
organizationName               = Organization Name (eg, company)
organizationalUnitName         = Organizational Unit (eg, division)
commonName                     = Common Name (e.g. sub-server FQDN or YOUR name)
countryName_default            = $DIST_C
stateOrProvinceName_default    = $DIST_ST
localityName_default           = $DIST_L
organizationName_default       = $DIST_O
organizationalUnitName_default = $DIST_OU
commonName_default             = $DIST_CN
EOF

  cat > cert/ca-root/config-sig.ini << EOF
HOME = .
[ ca ]
default_ca = default_ca
[ default_ca ]
preserve         = no
default_days     = 30
default_crl_days = 30
default_md       = sha256
email_in_dn      = no
unique_subject   = no
copy_extensions  = copy
x509_extensions  = x509_extensions
base_dir         = .
certificate      = cert/ca-root/cert.crt
private_key      = cert/ca-root/cert.key
new_certs_dir    = cert/ca-root/output
database         = cert/ca-root/index.txt
serial           = cert/ca-root/serial.txt
[ signing_policy ]
countryName            = supplied
stateOrProvinceName    = supplied
localityName           = supplied
organizationName       = supplied
organizationalUnitName = supplied
commonName             = supplied
[ x509_extensions ]
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always, issuer:always
basicConstraints       = critical, CA:true, pathlen:0
keyUsage               = keyCertSign, cRLSign
crlDistributionPoints  = $X509_SERV_CRL
EOF

  cat > cert/sub-server/config-req.ini << EOF
HOME = .
[ req ]
default_bits       = 2048
string_mask        = utf8only
req_extensions     = req_extensions
distinguished_name = distinguished_name
[ distinguished_name ]
countryName                    = Country Name (2 letter code)
stateOrProvinceName            = State or Province Name (full name)
localityName                   = Locality Name (eg, city)
organizationName               = Organization Name (eg, company)
organizationalUnitName         = Organizational Unit (eg, division)
commonName                     = Common Name (e.g. sub-server FQDN or YOUR name)
countryName_default            = $DIST_C
stateOrProvinceName_default    = $DIST_ST
localityName_default           = $DIST_L
organizationName_default       = $DIST_O
organizationalUnitName_default = $DIST_OU_S
commonName_default             = $DIST_CN_S
[ req_extensions ]
subjectKeyIdentifier = hash
basicConstraints     = critical, CA:true, pathlen:0
keyUsage             = keyCertSign, cRLSign
EOF

  cat > cert/sub-server/config-sig.ini << EOF
HOME = .
[ ca ]
default_ca = default_ca
[ default_ca ]
preserve         = no
default_days     = 30
default_crl_days = 30
default_md       = sha256
x509_extensions  = x509_extensions
email_in_dn      = no
unique_subject   = no
copy_extensions  = copy
base_dir         = .
certificate      = cert/sub-server/cert.crt
private_key      = cert/sub-server/cert.key
new_certs_dir    = cert/sub-server/output
database         = cert/sub-server/index.txt
serial           = cert/sub-server/serial.txt
[ signing_policy ]
countryName            = supplied
stateOrProvinceName    = supplied
localityName           = supplied
organizationName       = supplied
organizationalUnitName = supplied
commonName             = supplied
givenName              = optional
emailAddress           = optional
[ x509_extensions ]
subjectKeyIdentifier = hash
basicConstraints     = critical, CA:false
keyUsage             = digitalSignature, keyEncipherment
EOF

  if [ -z "$X509_ROOT_CRL" ]; then
    grep -v 'crlDistributionPoints' cert/ca-root/config-req.ini > cert/ca-root/config-req.ini-temp
    cat cert/ca-root/config-req.ini-temp > cert/ca-root/config-req.ini
    rm -rf cert/ca-root/config-req.ini-temp
  fi

  if [ -z "$X509_SERV_CRL" ]; then
    grep -v 'crlDistributionPoints' cert/ca-root/config-sig.ini > cert/ca-root/config-sig.ini-temp
    cat cert/ca-root/config-sig.ini-temp > cert/ca-root/config-sig.ini
    rm -rf cert/ca-root/config-sig.ini-temp
  fi

  openssl req -batch -nodes -sha256 -outform PEM -newkey rsa -x509 \
    -out cert/ca-root/cert.crt \
    -keyout cert/ca-root/cert.key \
    -config cert/ca-root/config-req.ini

  openssl req -batch -nodes -sha256 -outform PEM -newkey rsa \
    -out cert/sub-server/cert.csr \
    -keyout cert/sub-server/cert.key \
    -config cert/sub-server/config-req.ini

  openssl ca -batch -days "$DAYS" \
    -extensions x509_extensions \
    -policy signing_policy \
    -out cert/sub-server.crt \
    -config cert/ca-root/config-sig.ini \
    -infiles cert/sub-server/cert.csr

  if [ -n "$X509_SERV_CRL" ]; then
    grep -v 'crlDistributionPoints' cert/ca-root/config-sig.ini > cert/ca-root/config-sig.ini-temp
    cat cert/ca-root/config-sig.ini-temp > cert/ca-root/config-sig.ini
    rm -rf cert/ca-root/config-sig.ini-temp
  fi

  openssl x509 -in cert/sub-server.crt > cert/sub-server/cert.crt

  rm -rf cert/sub-server.crt

  {
    cat "cert/sub-server/cert.crt"
    cat "cert/ca-root/cert.crt"
  } > cert/sub-server/server.crt

  echo 'This file is a flag. Deny reinstall PKI when exist.' > cert/lock.txt

}

function createClientCA() {

  name=$1

  if [ -e "cert/sub-client/$name" ]; then
    echo "Cancel: Folder with $name exist, Delete it if you want to recreate."
    exit 1
  fi

  mkdir "cert/sub-client/$name"
  mkdir "cert/sub-client/$name/output"
  touch "cert/sub-client/$name/index.txt"
  echo '01' > "cert/sub-client/$name/serial.txt"

  cat > "cert/sub-client/$name/config-req.ini" << EOF
HOME = .
[ req ]
default_bits       = 2048
string_mask        = utf8only
req_extensions     = req_extensions
distinguished_name = distinguished_name
[ distinguished_name ]
countryName                    = Country Name (2 letter code)
stateOrProvinceName            = State or Province Name (full name)
localityName                   = Locality Name (eg, city)
organizationName               = Organization Name (eg, company)
organizationalUnitName         = Organizational Unit (eg, division)
commonName                     = Common Name (e.g. sub-server FQDN or YOUR name)
countryName_default            = $DIST_C
stateOrProvinceName_default    = $DIST_ST
localityName_default           = $DIST_L
organizationName_default       = $DIST_O
organizationalUnitName_default = $DIST_OU_C
commonName_default             = $DIST_CN_C
[ req_extensions ]
subjectKeyIdentifier = hash
basicConstraints     = critical, CA:true, pathlen:0
keyUsage             = keyCertSign, cRLSign
EOF

  cat > "cert/sub-client/$name/config-sig.ini" << EOF
HOME = .
[ ca ]
default_ca = default_ca
[ default_ca ]
preserve         = no
default_days     = 30
default_crl_days = 30
default_md       = sha256
x509_extensions  = x509_extensions
email_in_dn      = no
unique_subject   = no
copy_extensions  = copy
base_dir         = .
certificate      = cert/sub-client/$name/cert.crt
private_key      = cert/sub-client/$name/cert.key
new_certs_dir    = cert/sub-client/$name/output
database         = cert/sub-client/$name/index.txt
serial           = cert/sub-client/$name/serial.txt
[ signing_policy ]
countryName            = supplied
stateOrProvinceName    = supplied
localityName           = supplied
organizationName       = supplied
organizationalUnitName = supplied
commonName             = supplied
givenName              = optional
emailAddress           = optional
[ x509_extensions ]
subjectKeyIdentifier = hash
basicConstraints     = critical, CA:false
keyUsage             = digitalSignature, keyEncipherment
extendedKeyUsage     = clientAuth
EOF

  openssl req -batch -nodes -sha256 -outform PEM -newkey rsa \
    -out "cert/sub-client/$name/cert.csr" \
    -keyout "cert/sub-client/$name/cert.key" \
    -config "cert/sub-client/$name/config-req.ini"

  openssl ca -batch -days $DAYS \
    -policy signing_policy \
    -extensions x509_extensions \
    -config cert/ca-root/config-sig.ini \
    -out "cert/sub-client/$name/default.crt" \
    -infiles "cert/sub-client/$name/cert.csr"

  openssl x509 -in "cert/sub-client/$name/default.crt" > "cert/sub-client/$name/cert.crt"

  rm -rf "cert/sub-client/$name/default.crt"

  {
    cat "cert/sub-client/$name/cert.crt"
    cat "cert/ca-root/cert.crt"
  } > "cert/sub-client/$name/chain.crt"

  echo "================================================================================"
  echo " Create Client intermediate CA"
  echo "================================================================================"
  echo "> NAME --------- $name"
  echo "> KEY ---------- cert/sub-client/$name/cert.key"
  echo "> CRT ---------- cert/sub-client/$name/cert.crt"
  echo "================================================================================"
}

function revokeClientCA() {
  name=$1
  openssl ca -config cert/ca-root/config-sig.ini -revoke "cert/sub-client/$name/cert.crt"
}

function updateRootCRL() {
  openssl ca -gencrl -config cert/ca-root/config-sig.ini -out cert/ca-root/crl.pem
  openssl crl -inform PEM -outform DER -in cert/ca-root/crl.pem -out cert/ca-root/cert.crl
}

function updateServerCRL() {
  openssl ca -gencrl -config cert/sub-server/config-sig.ini -out cert/sub-server/crl.pem
  openssl crl -inform PEM -outform DER -in cert/sub-server/crl.pem -out cert/sub-server/cert.crl
}

function updateClientCRL() {
  name=$1
  openssl ca -gencrl -config "cert/sub-client/$name/config-sig.ini" -out "cert/sub-client/$name/crl.pem"
  openssl crl -inform PEM -outform DER -in "cert/sub-client/$name/crl.pem" -out "cert/sub-client/$name/cert.crl"
}

function manualServer() {

  file=$1

  if [ ! -e "$file" ]; then
    echo "Input CSR file not exist"
    exit 1
  fi

  if [ -z "$NAME" ]; then
    base=$(basename "$file")
    name="${base%.*}"
  else
    name=$NAME
  fi

  folder="manual/$name"
  plain="$folder/ssl.crt"
  chain="$folder/chain.crt"

  mkdir -p 'manual'

  if [ -e "$folder" ]; then
    echo "Output folder already exist. Rename CSR file if you need to."$
    exit 1
  fi

  mkdir -p "$folder"

  openssl ca -batch \
    -config cert/sub-server/config-sig.ini \
    -policy signing_policy \
    -extensions x509_extensions \
    -out "$plain-temp" \
    -infiles "$file"

  openssl x509 -in "$plain-temp" > "$plain"

  rm -f "$plain-temp"

  {
    cat "$plain"
    cat "cert/sub-server/cert.crt"
    cat "cert/ca-root/cert.crt"
  } > "$chain"

  echo "================================================================================"
  echo " Server SSL certificate generated, CSR name $name"
  echo "================================================================================"
  echo "> SSL Plain ---- $plain"
  echo "> SSL Chain ---- $chain"
  echo "================================================================================"
}

function createServer() {

  name=$1

  if [ -e 'output-server' ] && [ -e "output-server/$name" ]; then
    echo "Cancel: Folder with $name exist, Delete it if you want to recreate. Which is bad idea."
    exit 1
  fi

  mkdir -p "output-server/$name"

  [ -z "$O" ] && O="$DIST_O"
  [ -z "$OU" ] && OU="$DIST_OU_S"
  [ -z "$CN" ] && CN="$name"

  cat > "output-server/$name/req.ini" << EOF
HOME = .
[ req ]
default_bits       = 2048
string_mask        = utf8only
req_extensions     = req_extensions
distinguished_name = distinguished_name
[ req_extensions ]
subjectKeyIdentifier = hash
basicConstraints     = critical, CA:false
keyUsage             = digitalSignature, keyEncipherment
subjectAltName       = @alternate_names
[ distinguished_name ]
countryName                    = Country Name (2 letter code)
stateOrProvinceName            = State or Province Name (full name)
localityName                   = Locality Name (eg, city)
organizationName               = Organization Name (eg, company)
organizationalUnitName         = Organizational Unit (eg, division)
commonName                     = Common Name (e.g. sub-server FQDN or YOUR name)
countryName_default            = $DIST_C
stateOrProvinceName_default    = $DIST_ST
localityName_default           = $DIST_L
organizationName_default       = $O
organizationalUnitName_default = $OU
commonName_default             = $CN
[ alternate_names ]
EOF

  if [ -z "$AN" ] && [ -z "$IP" ]; then

    echo "WARNING: No SAN define, Using CN as SAN" && LIST_AN="$name"
    echo "DNS.1=$name" >> "output-server/$name/req.ini"

  else

    LIST_AN=$(echo "$AN" | tr "," "\n")
    LIST_IP=$(echo "$IP" | tr "," "\n")

    COUNT_AN=1
    COUNT_IP=1

    for i in $LIST_AN; do
      echo "DNS.$COUNT_AN=$i" >> "output-server/$name/req.ini"
      ((COUNT_AN++))
    done

    for i in $LIST_IP; do
      echo "IP.$COUNT_IP=$i" >> "output-server/$name/req.ini"
      ((COUNT_IP++))
    done

  fi

  openssl req -batch -newkey rsa -sha256 -nodes -outform PEM \
    -out "output-server/$name/ssl.csr" \
    -keyout "output-server/$name/ssl.key" \
    -config "output-server/$name/req.ini"

  openssl ca -batch -days "$DAYS" \
    -config cert/sub-server/config-sig.ini \
    -policy signing_policy \
    -extensions x509_extensions \
    -out "output-server/$name/ssl-temp.crt" \
    -infiles "output-server/$name/ssl.csr"

  openssl x509 -in "output-server/$name/ssl-temp.crt" > "output-server/$name/ssl.crt"

  rm -f "output-server/$name/ssl-temp.crt"

  {
    cat "output-server/$name/ssl.crt"
    cat "cert/sub-server/cert.crt"
    cat "cert/ca-root/cert.crt"
  } > "output-server/$name/chain.crt"

  openssl pkcs12 -export \
    -inkey "output-server/$name/ssl.key" \
    -in "output-server/$name/chain.crt" \
    -out "output-server/$name/ssl.pfx" \
    -passout pass:

  echo "================================================================================"
  echo " Server SSL certificate generated"
  echo "================================================================================"
  echo "> KEY ---------- output-server/$name/ssl.key"
  echo "> PFX ---------- output-server/$name/ssl.pfx"
  echo "> SSL Plain ---- output-server/$name/ssl.crt"
  echo "> SSL Chain ---- output-server/$name/chain.crt"
  echo "================================================================================"
}

function createClient() {

  name=$1
  user=$2

  if [ -e 'output-client' ] && [ -e "output-client/$name" ] && [ -e "output-client/$name/$user" ]; then
    echo "Cancel: Folder with $name/$user exist, Delete it if you want to recreate. Which is bad idea."
    exit 1
  fi

  [ -z "$O" ] && O="$DIST_O"
  [ -z "$OU" ] && OU="$DIST_OU_C"
  [ -z "$CN" ] && CN="$name" && echo "WARNING: CN not define, Using name"
  [ -z "$GN" ] && GN="$name" && echo "WARNING: GN not define, Using name"

  mkdir -p "output-client/$name/$user"

  cat > "output-client/$name/$user/req.ini" << EOF
HOME = .
[ req ]
default_bits       = 2048
string_mask        = utf8only
req_extensions     = req_extensions
distinguished_name = distinguished_name
[ req_extensions ]
subjectKeyIdentifier = hash
basicConstraints     = critical, CA:false
keyUsage             = digitalSignature, keyEncipherment
extendedKeyUsage     = clientAuth
[ distinguished_name ]
countryName                    = Country Name (2 letter code)
stateOrProvinceName            = State or Province Name (full name)
localityName                   = Locality Name (eg, city)
organizationName               = Organization Name (eg, company)
organizationalUnitName         = Organizational Unit (eg, division)
commonName                     = Common Name (e.g. sub-server FQDN or YOUR name)
givenName                      = Given Name
countryName_default            = $DIST_C
stateOrProvinceName_default    = $DIST_ST
localityName_default           = $DIST_L
organizationName_default       = $O
organizationalUnitName_default = $OU
commonName_default             = $CN
givenName_default              = $GN
EOF

  openssl req -batch -newkey rsa -sha256 -nodes -outform PEM \
    -keyout "output-client/$name/$user/ssl.key" \
    -config "output-client/$name/$user/req.ini" \
    -out "output-client/$name/$user/ssl.csr"

  openssl ca -batch -days "$DAYS" \
    -policy signing_policy \
    -extensions x509_extensions \
    -config "cert/sub-client/$name/config-sig.ini" \
    -out "output-client/$name/$user/ssl.crt-temp" \
    -infiles "output-client/$name/$user/ssl.csr"

  openssl x509 -in "output-client/$name/$user/ssl.crt-temp" > "output-client/$name/$user/ssl.crt"

  rm -f "output-client/$name/$user/ssl.crt-temp"

  {
    cat "output-client/$name/$user/ssl.crt"
    cat "cert/sub-client/$name/cert.crt"
    cat "cert/ca-root/cert.crt"
  } > "output-client/$name/$user/chain.crt"

  openssl pkcs12 -export \
    -inkey "output-client/$name/$user/ssl.key" \
    -in "output-client/$name/$user/chain.crt" \
    -out "output-client/$name/$user/ssl.pfx" \
    -passout pass:

  echo "================================================================================"
  echo " Client SSL certificate generated, namespace: $name"
  echo "================================================================================"
  echo "> KEY ---------- output-client/$name/$user/ssl.key"
  echo "> PFX ---------- output-client/$name/$user/ssl.pfx"
  echo "> SSL Plain ---- output-client/$name/$user/ssl.crt"
  echo "> SSL Chain ---- output-client/$name/$user/chain.crt"
  echo "================================================================================"
}

function revokeServer() {
  name=$1
  openssl ca -config "cert/sub-server/config-sig.ini" -revoke "output-server/$name/ssl.crt"
}

function revokeClient() {
  name=$1
  user=$2
  openssl ca -config "cert/sub-client/$name/config-sig.ini" -revoke "output-client/$name/$user/ssl.crt"
}

[ -z "$1" ] && help && exit 1

case $1 in

'i' | 'install')
  if [ -e 'cert' ] && [ -e 'cert/lock.txt' ]; then
    echo 'Cancel: File lock.txt exist, Delete ca folder if you want to recreate.'
    exit 1
  fi
  install
  ;;

'c' | 'create')
  [ -z "$2" ] && echo "No argument 'name' specified" && help && exit 1
  createClientCA "$2"
  ;;

'r' | 'revoke')
  [ -z "$2" ] && echo "No argument 'name' specified" && help && exit 1
  revokeClientCA "$2"
  ;;

'ur')
  echo "================================================================================"
  echo " Update Root CA CRL"
  echo "================================================================================"
  updateRootCRL
  echo "================================================================================"
  ;;

'us')
  echo "================================================================================"
  echo " Update Server intermediate CA CRL"
  echo "================================================================================"
  updateServerCRL
  echo "================================================================================"
  ;;

'uc')
  echo "================================================================================"
  echo " Update all Client intermediate CA CRL"
  echo "================================================================================"
  if [ -z "$2" ]; then
    CAS=$(ls "cert/sub-client")
    for i in $CAS; do
      updateClientCRL "$i"
    done
  else
    updateClientCRL "$2"
  fi
  ;;

'ms')
  [ -z "$2" ] && echo "No argument 'file path' specified" && help && exit 1
  echo "================================================================================"
  echo " Create Server SSL Certificate from CSR"
  echo "================================================================================"
  manualServer "$2"
  ;;

'vs')
  [ -z "$2" ] && echo "No argument 'commonName' specified" && help && exit 1
  echo "================================================================================"
  echo " Create Server SSL Certificate"
  echo "================================================================================"
  createServer "$2"
  ;;

'vc')
  [ -z "$2" ] && echo "No argument 'name' specified" && help && exit 1
  [ -z "$3" ] && echo "No argument 'user' specified" && help && exit 1
  echo "================================================================================"
  echo " Create Client SSL Certificate"
  echo "================================================================================"
  createClient "$2" "$3"
  ;;

'rs')
  [ -z "$2" ] && echo "No argument 'name' specified" && help && exit 1
  echo "================================================================================"
  echo " Revoke Server SSL Certificate"
  echo "================================================================================"
  revokeServer "$2"
  echo "Certificate revoked, Remember update CRL list"
  echo "================================================================================"
  ;;

'rc')
  [ -z "$2" ] && echo "No argument 'name' specified" && help && exit 1
  [ -z "$3" ] && echo "No argument 'user' specified" && help && exit 1
  echo "================================================================================"
  echo " Revoke Client SSL Certificate"
  echo "================================================================================"
  revokeClient "$2" "$3"
  echo "Certificate revoked, Remember update CRL list"
  echo "================================================================================"
  ;;

'?' | 'h' | 'help')
  helpAll
  ;;

*)
  help
  ;;

esac
