#!/usr/bin/env bash

############################################# Don't modify above this line #########################################################################################################
############################################# Don't modify above this line #########################################################################################################
############################################# Don't modify above this line #########################################################################################################
############################################# Don't modify above this line #########################################################################################################
############################################# Don't modify above this line #########################################################################################################

#=======================================================================================================================
# Before you start
#=======================================================================================================================

# For script friendly
# - All DEFAULT_ prefix option can override by env
# - All default settings has a special value for sed replacing

# For manually friendly
# - All settings has default value below scripting friendly, uncomment it will override first line

# Make sure you change DONE to yes at the end of config section !

#=======================================================================================================================
# Date Settings
#=======================================================================================================================

# Name: Choose mode for time options
# Type: Enum - days | date
# What: OpenSSL accept two form of time, Date range and number of days
#       - days: use -days, As is time. Very former and very serious.
#       - date: use -startdate/enddate, Align to 00:00:00. For pleasing looking
DEFAULT_TIME_MODE='SETTING-DEFAULT-TIME-MODE'
# DEFAULT_TIME_MODE=days

#===============================================================================

# Name: Default begin and end date
# Type: String - yyyyMMdd
# What: This settings will transform into argument:
#       -startdate '19700101000000Z'
#         -enddate '20700101000000Z'
# When: This settings Apply when those ENV absent:
#       DATE_START='20420101'
#       DATE_CLOSE='20770101'
DEFAULT_DATE_START='SETTING-DEFAULT-DATE-START'
DEFAULT_DATE_CLOSE='SETTING-DEFAULT-DATE-CLOSE'
# DEFAULT_DATE_START='19700101'
# DEFAULT_DATE_CLOSE='20700101'

# Also: You can change suffix in date mode
DEFAULT_DATE_SUFFIX='000000Z'

#===============================================================================

# Name: Default days when sign a cert
# Type: Number
# What: This settings will transform into those argument:
#       -days '30'
# When: This settings Apply when those ENV absent:
#       DAYS='30'
DEFAULT_DAYS='SETTING-DEFAULT-DAYS'
#DEFAULT_DAYS=30

#=======================================================================================================================
# Distinguished Name Settings
#=======================================================================================================================

# NOTICE: Because for people in social media location and nation really no matter but email

# Name: PKI info
# Type: String
# What: This settings will transform into distinguished_name and alternate_names(Email)
# Warn: Those settings will apply to config file and signed into PKI. Modify take no effect
# Note: PKI_CRL will write to Anchor and Inter CA
PKI_C='SETTING-PKI-C'
PKI_O='SETTING-PKI-O'
#PKI_C='US'
#PKI_O='example org'

#===============================================================================

# Name: Anchor CA info, Placed in data/anchor
# Type: String
# What: This settings will transform into root-ca distinguished_name
# Warn: Those settings will apply to config file and signed into PKI. ReModify take no effect

ANCHOR_E='SETTING-PKI-E'
ANCHOR_OU='SETTING-ANCHOR-OU'
ANCHOR_CN='SETTING-ANCHOR-CN'

ANCHOR_CRL='SETTING-ANCHOR-CRL'
ANCHOR_OCSP='SETTING-ANCHOR-OCSP'
ANCHOR_FQDN='SETTING-ANCHOR-FQDN'

#===============================================================================

# Name: Default Intermediate SSL CA Info, Placed in data/middle-ssl-authority
# Type: String
# What: This settings will transform into intermediate-ca distinguished_name
# Warn: Those settings will apply to config file and signed into PKI. ReModify take no effect
MIDDLE_SSL_OU='SETTING-MIDDLE-SSL-OU'
MIDDLE_SSL_CN='SETTING-MIDDLE-SSL-CN'

MIDDLE_SSL_CRL='SETTING-MIDDLE-SSL-CRL'
MIDDLE_SSL_OCSP='SETTING-MIDDLE-SSL-OCSP'
MIDDLE_SSL_FQDN='SETTING-MIDDLE-SSL-FQDN'

#===============================================================================

# Name: Default Intermediate VPN CA Info, Placed in data/middle-vpn-authority
# Type: String
# What: This settings will transform into intermediate-ca distinguished_name
# Warn: Those settings will apply to config file and signed into PKI. ReModify take no effect
MIDDLE_VPN_OU='SETTING-MIDDLE-VPN-OU'
MIDDLE_VPN_CN='SETTING-MIDDLE-VPN-CN'

MIDDLE_VPN_CRL='SETTING-MIDDLE-VPN-CRL'
MIDDLE_VPN_OCSP='SETTING-MIDDLE-VPN-OCSP'
MIDDLE_VPN_FQDN='SETTING-MIDDLE-VPN-FQDN'

#=======================================================================================================================
# Other Settings
#=======================================================================================================================

# Name: Choose mode for VPN certificate key
# Type: Enum - ECC | RSA
# What: Use  ECDSA-prime256v1 or RSA4096
DEFAULT_VPN_KEY_MODE='SETTING-VPN_KEY_MODE'
#DEFAULT_VPN_KEY_MODE='ECC'

#=======================================================================================================================
# Safety lock
#=======================================================================================================================

# Change this to 'yes', When all settings is done.

DONE="SETTING-DONE"

#=======================================================================================================================
# SED mode setting
#=======================================================================================================================

# Use
# sed -i '/#SED-INSERT/e cat foo-bar.txt' 'pki.sh'
# To batch insert, Avoiding a sed hell

# ↓ Don't modify this if you still want use sed-insert

#SED-INSERT

# ↑ Don't modify this if you still want use sed-insert

############################################# Don't modify below this line #########################################################################################################
############################################# Don't modify below this line #########################################################################################################
############################################# Don't modify below this line #########################################################################################################
############################################# Don't modify below this line #########################################################################################################
############################################# Don't modify below this line #########################################################################################################

if command -v openssl &> /dev/null; then
  :
else
  echo '[FATAL] openssl not exist in PATH'
  exit 1
fi

if [ -n "$DEBUG" ] || [ "yes" = "$DONE" ]; then
  :
else
  echo '[FATAL] DONE not set to yes. Use --help for help.'
  exit 1
fi

#=======================================================================================================================

CST_KU='# keyUsage               = critical'
CST_EK='# extendedKeyUsage       = critical'
SSL_KU='keyUsage               = critical,digitalSignature,keyEncipherment'
SSL_EK='extendedKeyUsage       = critical,serverAuth'
VPN_KU='keyUsage               = critical,digitalSignature'
VPN_EK='extendedKeyUsage       = critical,clientAuth'

P_BASE='.'

P_DATA="$P_BASE/data"
P_SIGN="$P_BASE/sign"
P_TEMP="$P_BASE/temp"

P_DATA_META="$P_DATA/operate-log.txt"

mkdir -p "$P_DATA"
mkdir -p "$P_SIGN"
mkdir -p "$P_TEMP"

#=======================================================================================================================

[ -z "$TIME_MODE" ] && TIME_MODE=$DEFAULT_TIME_MODE
[ -z "$DATE_START" ] && DATE_START=$DEFAULT_DATE_START
[ -z "$DATE_CLOSE" ] && DATE_CLOSE=$DEFAULT_DATE_CLOSE
[ -z "$DATE_SUFFIX" ] && DATE_SUFFIX=$DEFAULT_DATE_SUFFIX
[ -z "$DAYS" ] && DAYS=$DEFAULT_DAYS

[ -z "$VPN_KEY_MODE" ] && VPN_KEY_MODE=$DEFAULT_VPN_KEY_MODE

case $TIME_MODE in
'days') X_ARGS_VALID_TIME="-days $DAYS" ;;
'date') X_ARGS_VALID_TIME="-startdate ${DATE_START}${DATE_SUFFIX} -enddate ${DATE_CLOSE}${DATE_SUFFIX}" ;;
*)
  echo "[FATAL] TIME-MODE must be days or date, But got -> $TIME_MODE"
  exit 1
  ;;
esac

#===================================================================================================================================================================================
#===================================================================================================================================================================================
#===================================================================================================================================================================================

function createAnchor() {

  if [ "$ANCHOR_CRL" ]; then
    ENABLE_CRL='true'
  else
    ENABLE_CRL='false'
  fi

  if [ "$ANCHOR_OCSP" ] && [ "$ANCHOR_FQDN" ]; then
    ENABLE_OCSP='true'
  else
    ENABLE_OCSP='false'
  fi

  P_DATA_ANCHOR="$P_DATA/anchor"

  P_DATA_ANCHOR_CONF="$P_DATA_ANCHOR/conf"
  P_DATA_ANCHOR_DATA="$P_DATA_ANCHOR/data"
  P_DATA_ANCHOR_META="$P_DATA_ANCHOR/meta"
  P_DATA_ANCHOR_OCSP="$P_DATA_ANCHOR/ocsp"
  P_DATA_ANCHOR_SIGN="$P_DATA_ANCHOR/sign"

  P_DATA_ANCHOR_ROOT_CRT="$P_DATA_ANCHOR/authority.crt"

  P_DATA_ANCHOR_CONF_INIT="$P_DATA_ANCHOR_CONF/config-init.ini"
  P_DATA_ANCHOR_CONF_SELF="$P_DATA_ANCHOR_CONF/config-self.ini"
  P_DATA_ANCHOR_CONF_SIGN="$P_DATA_ANCHOR_CONF/config-sign.ini"

  P_DATA_ANCHOR_DATA_KEY="$P_DATA_ANCHOR_DATA/authority.key"
  P_DATA_ANCHOR_DATA_CSR="$P_DATA_ANCHOR_DATA/authority.csr"
  P_DATA_ANCHOR_DATA_CRT="$P_DATA_ANCHOR_DATA/authority.crt"

  P_DATA_ANCHOR_META_DATABASE="$P_DATA_ANCHOR_META/database"
  P_DATA_ANCHOR_META_SERIAL="$P_DATA_ANCHOR_META/serial"

  mkdir -p "$P_DATA_ANCHOR"
  mkdir -p "$P_DATA_ANCHOR_CONF"
  mkdir -p "$P_DATA_ANCHOR_DATA"
  mkdir -p "$P_DATA_ANCHOR_META"
  mkdir -p "$P_DATA_ANCHOR_SIGN"

  touch "$P_DATA_ANCHOR_META_DATABASE"
  touch "$P_DATA_ANCHOR_META_SERIAL"

  echo '00' > "$P_DATA_ANCHOR_META_SERIAL"

  if [ "$ANCHOR_E" ]; then
    cat > "$P_DATA_ANCHOR_CONF_INIT" << EOF
[ req ]
prompt             = no
req_extensions     = req_extensions
distinguished_name = distinguished_name
[ distinguished_name ]
C                  = $PKI_C
O                  = $PKI_O
OU                 = $ANCHOR_OU
CN                 = $ANCHOR_CN
[ req_extensions ]
subjectAltName     = @alternate_names
[ alternate_names ]
email              = $ANCHOR_E
EOF
  else
    cat > "$P_DATA_ANCHOR_CONF_INIT" << EOF
[ req ]
prompt             = no
distinguished_name = distinguished_name
[ distinguished_name ]
C                  = $PKI_C
O                  = $PKI_O
OU                 = $ANCHOR_OU
CN                 = $ANCHOR_CN
EOF
  fi

  cat > "$P_DATA_ANCHOR_CONF_SELF" << EOF
[ ca ]
default_ca             = default_ca
[ default_ca ]
private_key            = $P_DATA_ANCHOR_DATA_KEY
certificate            = $P_DATA_ANCHOR_DATA_CRT
new_certs_dir          = $P_DATA_ANCHOR_SIGN
database               = $P_DATA_ANCHOR_META_DATABASE
serial                 = $P_DATA_ANCHOR_META_SERIAL
default_md             = sha256
default_days           = 30
default_crl_days       = 30
preserve               = no
email_in_dn            = no
copy_extensions        = copy
policy                 = signing_policy
x509_extensions        = x509_extensions
[ signing_policy ]
countryName            = match
stateOrProvinceName    = optional
localityName           = optional
organizationName       = match
organizationalUnitName = match
commonName             = match
givenName              = optional
emailAddress           = optional
[ x509_extensions ]
subjectKeyIdentifier   = hash
basicConstraints       = critical,CA:true
authorityKeyIdentifier = keyid:always,issuer:always
keyUsage               = critical,keyCertSign,cRLSign
EOF

  [ "$ENABLE_OCSP" ] && cat >> "$P_DATA_ANCHOR_CONF_SELF" << EOF
authorityInfoAccess    = $ANCHOR_OCSP
EOF

  [ "$ENABLE_CRL" ] && cat >> "$P_DATA_ANCHOR_CONF_SELF" << EOF
crlDistributionPoints  = crlDistributionPoints
[ crlDistributionPoints ]
fullname  = $ANCHOR_CRL
CRLissuer = dirName:CRLissuer
reasons   = keyCompromise,CACompromise,affiliationChanged,superseded,cessationOfOperation,certificateHold,privilegeWithdrawn,AACompromise
[ CRLissuer ]
C  = $PKI_C
O  = $PKI_O
OU = $ANCHOR_OU
CN = $ANCHOR_CN
EOF

  cat > "$P_DATA_ANCHOR_CONF_SIGN" << EOF
[ ca ]
default_ca             = default_ca
[ default_ca ]
private_key            = $P_DATA_ANCHOR_DATA_KEY
certificate            = $P_DATA_ANCHOR_DATA_CRT
new_certs_dir          = $P_DATA_ANCHOR_SIGN
database               = $P_DATA_ANCHOR_META_DATABASE
serial                 = $P_DATA_ANCHOR_META_SERIAL
default_md             = sha256
default_days           = 30
default_crl_days       = 30
preserve               = no
email_in_dn            = no
copy_extensions        = none
policy                 = signing_policy
x509_extensions        = x509_extensions
[ signing_policy ]
countryName            = optional
stateOrProvinceName    = optional
localityName           = optional
organizationName       = optional
organizationalUnitName = optional
commonName             = supplied
givenName              = optional
emailAddress           = optional
[ x509_extensions ]
subjectKeyIdentifier   = hash
basicConstraints       = critical,CA:true,pathlen:0
authorityKeyIdentifier = keyid:always,issuer:always
keyUsage               = critical,keyCertSign,cRLSign
EOF

  [ "$ENABLE_OCSP" == 'true' ] && cat >> "$P_DATA_ANCHOR_CONF_SIGN" << EOF
authorityInfoAccess    = $ANCHOR_OCSP
EOF

  [ "$ENABLE_CRL" == 'true' ] && cat >> "$P_DATA_ANCHOR_CONF_SIGN" << EOF
crlDistributionPoints  = crlDistributionPoints
[ crlDistributionPoints ]
fullname  = $ANCHOR_CRL
CRLissuer = dirName:CRLissuer
reasons   = keyCompromise,CACompromise,affiliationChanged,superseded,cessationOfOperation,certificateHold,privilegeWithdrawn,AACompromise
[ CRLissuer ]
C  = $PKI_C
O  = $PKI_O
OU = $ANCHOR_OU
CN = $ANCHOR_CN
EOF

  openssl ecparam -genkey -name prime256v1 -out "$P_DATA_ANCHOR_DATA_KEY"

  openssl req -utf8 -batch -nodes -new \
    -key "$P_DATA_ANCHOR_DATA_KEY" \
    -out "$P_DATA_ANCHOR_DATA_CSR" \
    -config "$P_DATA_ANCHOR_CONF_INIT"

  # shellcheck disable=SC2086
  openssl ca -utf8 -batch -selfsign $X_ARGS_VALID_TIME \
    -in "$P_DATA_ANCHOR_DATA_CSR" \
    -out "$P_DATA_ANCHOR_DATA_CRT" \
    -config "$P_DATA_ANCHOR_CONF_SELF"

  openssl x509 \
    -in "$P_DATA_ANCHOR_DATA_CRT" \
    -out "$P_DATA_ANCHOR_ROOT_CRT" \
    -outform PEM

  [ ! "$ENABLE_OCSP" == 'true' ] && return

  mkdir -p "$P_DATA_ANCHOR_OCSP"

  P_DATA_ANCHOR_OCSP_INIT="$P_DATA_ANCHOR_OCSP/config-init.ini"
  P_DATA_ANCHOR_OCSP_SIGN="$P_DATA_ANCHOR_OCSP/config-sign.ini"

  P_DATA_ANCHOR_OCSP_KEY="$P_DATA_ANCHOR_OCSP/authority.key"
  P_DATA_ANCHOR_OCSP_CSR="$P_DATA_ANCHOR_OCSP/authority.csr"
  P_DATA_ANCHOR_OCSP_CRT="$P_DATA_ANCHOR_OCSP/authority.crt"
  P_DATA_ANCHOR_OCSP_CRT_PLAIN="$P_DATA_ANCHOR_OCSP/authority-plain.crt"
  P_DATA_ANCHOR_OCSP_CRT_CHAIN="$P_DATA_ANCHOR_OCSP/authority-chain.crt"

  cat > "$P_DATA_ANCHOR_OCSP_INIT" << EOF
[ req ]
prompt             = no
distinguished_name = distinguished_name
[ distinguished_name ]
C                  = $PKI_C
O                  = $PKI_O
OU                 = $ANCHOR_OU
CN                 = $ANCHOR_FQDN
EOF

  cat > "$P_DATA_ANCHOR_OCSP_SIGN" << EOF
[ ca ]
default_ca = default_ca
[ default_ca ]
base_dir               = .
private_key            = $P_DATA_ANCHOR_DATA_KEY
certificate            = $P_DATA_ANCHOR_DATA_CRT
new_certs_dir          = $P_DATA_ANCHOR_SIGN
database               = $P_DATA_ANCHOR_META_DATABASE
serial                 = $P_DATA_ANCHOR_META_SERIAL
default_md             = sha256
default_days           = 30
default_crl_days       = 30
preserve               = no
email_in_dn            = no
copy_extensions        = none
policy                 = signing_policy
x509_extensions        = x509_extensions
[ signing_policy ]
countryName            = match
stateOrProvinceName    = optional
localityName           = optional
organizationName       = match
organizationalUnitName = match
commonName             = supplied
givenName              = optional
emailAddress           = optional
[ x509_extensions ]
subjectKeyIdentifier   = hash
basicConstraints       = critical,CA:false
authorityKeyIdentifier = keyid:always,issuer:always
keyUsage               = critical,digitalSignature
extendedKeyUsage       = critical,OCSPSigning
EOF

  openssl ecparam -genkey -name prime256v1 -out "$P_DATA_ANCHOR_OCSP_KEY"

  openssl req -utf8 -batch -nodes -new \
    -key "$P_DATA_ANCHOR_OCSP_KEY" \
    -out "$P_DATA_ANCHOR_OCSP_CSR" \
    -config "$P_DATA_ANCHOR_OCSP_INIT"

  # shellcheck disable=SC2086
  openssl ca -utf8 -batch $X_ARGS_VALID_TIME \
    -in "$P_DATA_ANCHOR_OCSP_CSR" \
    -out "$P_DATA_ANCHOR_OCSP_CRT" \
    -config "$P_DATA_ANCHOR_OCSP_SIGN"

  openssl x509 \
    -in "$P_DATA_ANCHOR_OCSP_CRT" \
    -out "$P_DATA_ANCHOR_OCSP_CRT_PLAIN" \
    -outform PEM

  {
    cat "$P_DATA_ANCHOR_OCSP_CRT_PLAIN"
    cat "$P_DATA_ANCHOR_ROOT_CRT"
  } > "$P_DATA_ANCHOR_OCSP_CRT_CHAIN"

}

function createMiddle() {

  P_DATA_ANCHOR="$P_DATA/anchor"
  P_DATA_ANCHOR_CONF="$P_DATA_ANCHOR/conf"
  P_DATA_ANCHOR_ROOT_CRT="$P_DATA_ANCHOR/authority.crt"
  P_DATA_ANCHOR_CONF_SIGN="$P_DATA_ANCHOR_CONF/config-sign.ini"

  FOLDER=$1
  OU=$2
  CN=$3
  KU=$4
  EK=$5

  if [ "$CRL" ]; then
    ENABLE_CRL='true'
  else
    ENABLE_CRL='false'
  fi

  if [ "$OCSP" ] && [ "$FQDN" ]; then
    ENABLE_OCSP='true'
  else
    ENABLE_OCSP='false'
  fi

  #  echo "DN - OU -> $2"
  #  echo "DN - CN -> $3"
  #  echo "CRL -> $CRL"
  #  echo "OCSP -> $OCSP"
  #  echo "FQDN -> $FQDN"
  #
  #  echo "ENABLE_CRL -> $ENABLE_CRL"
  #  echo "ENABLE_OCSP -> $ENABLE_OCSP"
  #
  #  echo "$OCSP" | wc -L
  #  echo "$FQDN" | wc -L

  P_DATA_MIDDLE="$P_DATA/$FOLDER"

  P_DATA_MIDDLE_CONF="$P_DATA_MIDDLE/conf"
  P_DATA_MIDDLE_DATA="$P_DATA_MIDDLE/data"
  P_DATA_MIDDLE_META="$P_DATA_MIDDLE/meta"
  P_DATA_MIDDLE_OCSP="$P_DATA_MIDDLE/ocsp"
  P_DATA_MIDDLE_SIGN="$P_DATA_MIDDLE/sign"

  P_DATA_MIDDLE_ROOT_CRT="$P_DATA_MIDDLE/authority.crt"

  P_DATA_MIDDLE_CONF_INIT="$P_DATA_MIDDLE_CONF/config-init.ini"
  P_DATA_MIDDLE_CONF_SIGN="$P_DATA_MIDDLE_CONF/config-sign.ini"

  P_DATA_MIDDLE_DATA_KEY="$P_DATA_MIDDLE_DATA/authority.key"
  P_DATA_MIDDLE_DATA_CSR="$P_DATA_MIDDLE_DATA/authority.csr"
  P_DATA_MIDDLE_DATA_CRT="$P_DATA_MIDDLE_DATA/authority.crt"

  P_DATA_MIDDLE_META_DATABASE="$P_DATA_MIDDLE_META/database"
  P_DATA_MIDDLE_META_SERIAL="$P_DATA_MIDDLE_META/serial"

  P_DATA_MIDDLE_OCSP_INIT="$P_DATA_MIDDLE_OCSP/config-init.ini"
  P_DATA_MIDDLE_OCSP_SIGN="$P_DATA_MIDDLE_OCSP/config-sign.ini"

  P_DATA_MIDDLE_OCSP_KEY="$P_DATA_MIDDLE_OCSP/authority.key"
  P_DATA_MIDDLE_OCSP_CSR="$P_DATA_MIDDLE_OCSP/authority.csr"
  P_DATA_MIDDLE_OCSP_CRT="$P_DATA_MIDDLE_OCSP/authority.crt"
  P_DATA_MIDDLE_OCSP_CRT_PLAIN="$P_DATA_MIDDLE_OCSP/authority-plain.crt"
  P_DATA_MIDDLE_OCSP_CRT_CHAIN="$P_DATA_MIDDLE_OCSP/authority-chain.crt"

  mkdir -p "$P_DATA_MIDDLE"
  mkdir -p "$P_DATA_MIDDLE_CONF"
  mkdir -p "$P_DATA_MIDDLE_DATA"
  mkdir -p "$P_DATA_MIDDLE_META"
  mkdir -p "$P_DATA_MIDDLE_SIGN"

  touch "$P_DATA_MIDDLE_META_DATABASE"
  touch "$P_DATA_MIDDLE_META_SERIAL"

  echo '00' > "$P_DATA_MIDDLE_META_SERIAL"

  cat > "$P_DATA_MIDDLE_CONF_INIT" << EOF
[ req ]
prompt             = no
distinguished_name = distinguished_name
[ distinguished_name ]
C                  = $PKI_C
O                  = $PKI_O
OU                 = $OU
CN                 = $CN
EOF

  cat > "$P_DATA_MIDDLE_CONF_SIGN" << EOF
[ ca ]
default_ca             = default_ca
[ default_ca ]
base_dir               = .
private_key            = $P_DATA_MIDDLE_DATA_KEY
certificate            = $P_DATA_MIDDLE_DATA_CRT
new_certs_dir          = $P_DATA_MIDDLE_SIGN
database               = $P_DATA_MIDDLE_META_DATABASE
serial                 = $P_DATA_MIDDLE_META_SERIAL
default_md             = sha256
default_days           = 30
default_crl_days       = 30
preserve               = no
email_in_dn            = no
copy_extensions        = copy
policy                 = signing_policy
x509_extensions        = x509_extensions
[ signing_policy ]
countryName            = optional
stateOrProvinceName    = optional
localityName           = optional
organizationName       = optional
organizationalUnitName = optional
commonName             = supplied
givenName              = optional
emailAddress           = optional
[ x509_extensions ]
subjectKeyIdentifier   = hash
basicConstraints       = critical,CA:false
authorityKeyIdentifier = keyid:always,issuer:always
$KU
$EK
EOF

  [ "$ENABLE_OCSP" == 'true' ] && cat >> "$P_DATA_MIDDLE_CONF_SIGN" << EOF
authorityInfoAccess    = $OCSP
EOF

  [ "$ENABLE_CRL" == 'true' ] && cat >> "$P_DATA_MIDDLE_CONF_SIGN" << EOF
crlDistributionPoints  = crlDistributionPoints
[ crlDistributionPoints ]
fullname  = $CRL
CRLissuer = dirName:CRLissuer
reasons   = keyCompromise,CACompromise,affiliationChanged,superseded,cessationOfOperation,certificateHold,privilegeWithdrawn,AACompromise
[ CRLissuer ]
C  = $PKI_C
O  = $PKI_O
OU = $OU
CN = $CN
EOF

  openssl ecparam -genkey -name prime256v1 -out "$P_DATA_MIDDLE_DATA_KEY"

  openssl req -utf8 -batch -nodes -new \
    -key "$P_DATA_MIDDLE_DATA_KEY" \
    -out "$P_DATA_MIDDLE_DATA_CSR" \
    -config "$P_DATA_MIDDLE_CONF_INIT"

  # shellcheck disable=SC2086
  openssl ca -utf8 -batch $X_ARGS_VALID_TIME \
    -in "$P_DATA_MIDDLE_DATA_CSR" \
    -out "$P_DATA_MIDDLE_DATA_CRT" \
    -config "$P_DATA_ANCHOR_CONF_SIGN"

  openssl x509 \
    -in "$P_DATA_MIDDLE_DATA_CRT" \
    -out "$P_DATA_MIDDLE_ROOT_CRT" \
    -outform PEM

  [ ! "$ENABLE_OCSP" == 'true' ] && return

  mkdir -p "$P_DATA_MIDDLE_OCSP"

  cat > "$P_DATA_MIDDLE_OCSP_INIT" << EOF
[ req ]
prompt             = no
distinguished_name = distinguished_name
[ distinguished_name ]
C                  = $PKI_C
O                  = $PKI_O
OU                 = $OU
CN                 = $FQDN
EOF

  cat > "$P_DATA_MIDDLE_OCSP_SIGN" << EOF
[ ca ]
default_ca             = default_ca
[ default_ca ]
private_key            = $P_DATA_MIDDLE_DATA_KEY
certificate            = $P_DATA_MIDDLE_DATA_CRT
new_certs_dir          = $P_DATA_MIDDLE_SIGN
database               = $P_DATA_MIDDLE_META_DATABASE
serial                 = $P_DATA_MIDDLE_META_SERIAL
default_md             = sha256
default_days           = 30
default_crl_days       = 30
preserve               = no
email_in_dn            = no
copy_extensions        = copy
policy                 = signing_policy
x509_extensions        = x509_extensions
[ signing_policy ]
countryName            = optional
stateOrProvinceName    = optional
localityName           = optional
organizationName       = optional
organizationalUnitName = optional
commonName             = supplied
givenName              = optional
emailAddress           = optional
[ x509_extensions ]
subjectKeyIdentifier   = hash
basicConstraints       = critical,CA:false
authorityKeyIdentifier = keyid:always,issuer:always
keyUsage               = critical,digitalSignature
extendedKeyUsage       = critical,OCSPSigning
EOF

  openssl ecparam -genkey -name prime256v1 -out "$P_DATA_MIDDLE_OCSP_KEY"

  openssl req -utf8 -batch -nodes -new \
    -key "$P_DATA_MIDDLE_OCSP_KEY" \
    -out "$P_DATA_MIDDLE_OCSP_CSR" \
    -config "$P_DATA_MIDDLE_OCSP_INIT"

  # shellcheck disable=SC2086
  openssl ca -utf8 -batch $X_ARGS_VALID_TIME \
    -in "$P_DATA_MIDDLE_OCSP_CSR" \
    -out "$P_DATA_MIDDLE_OCSP_CRT" \
    -config "$P_DATA_MIDDLE_OCSP_SIGN"

  openssl x509 \
    -in "$P_DATA_MIDDLE_OCSP_CRT" \
    -out "$P_DATA_MIDDLE_OCSP_CRT_PLAIN" \
    -outform PEM

  {
    cat "$P_DATA_MIDDLE_OCSP_CRT_PLAIN"
    cat "$P_DATA_MIDDLE_ROOT_CRT"
    cat "$P_DATA_ANCHOR_ROOT_CRT"
  } > "$P_DATA_MIDDLE_OCSP_CRT_CHAIN"

}

function revokeMiddle() {

  P_DATA_ANCHOR="$P_DATA/anchor"
  P_DATA_ANCHOR_CONF="$P_DATA_ANCHOR/conf"
  P_DATA_ANCHOR_CONF_SIGN="$P_DATA_ANCHOR_CONF/config-sign.ini"

  FOLDER=$1

  P_DATA_MIDDLE="$P_DATA/$FOLDER"
  P_DATA_MIDDLE_ROOT_CRT="$P_DATA_MIDDLE/authority.crt"

  openssl ca \
    -revoke "$P_DATA_MIDDLE_ROOT_CRT" \
    -config "$P_DATA_ANCHOR_CONF_SIGN"

}

function updateRevoke() {

  FOLDER=$1

  P_DATA_FOOBAR="$P_DATA/$FOLDER"

  P_DATA_FOOBAR_CONF="$P_DATA_FOOBAR/conf"
  P_DATA_FOOBAR_DATA="$P_DATA_FOOBAR/data"

  P_DATA_FOOBAR_ROOT_CRL="$P_DATA_FOOBAR/authority.crl"

  P_DATA_FOOBAR_CONF_SIGN="$P_DATA_FOOBAR_CONF/config-sign.ini"

  P_DATA_FOOBAR_DATA_CRL="$P_DATA_FOOBAR_DATA/certificate.crl"

  openssl ca -gencrl \
    -out "$P_DATA_FOOBAR_DATA_CRL" \
    -config "$P_DATA_FOOBAR_CONF_SIGN"

  openssl crl \
    -in "$P_DATA_FOOBAR_DATA_CRL" \
    -out "$P_DATA_FOOBAR_ROOT_CRL" \
    -inform PEM -outform DER

}

#===================================================================================================================================================================================
#===================================================================================================================================================================================
#===================================================================================================================================================================================

function importCertificate() {

  FOLDER=$1
  NAME=$2
  FILE=$3

  P_DATA_ANCHOR="$P_DATA/anchor"
  P_DATA_ANCHOR_ROOT_CRT="$P_DATA_ANCHOR/authority.crt"

  P_DATA_MIDDLE="$P_DATA/$FOLDER"
  P_DATA_MIDDLE_CONF="$P_DATA_MIDDLE/conf"
  P_DATA_MIDDLE_ROOT_CRT="$P_DATA_MIDDLE/authority.crt"
  P_DATA_MIDDLE_CONF_SIGN="$P_DATA_MIDDLE_CONF/config-sign.ini"

  P_SIGN_IMPORT="$P_SIGN/$FOLDER/$NAME"

  P_SIGN_IMPORT_CSR="$P_SIGN_IMPORT/certificate.csr"
  P_SIGN_IMPORT_CRT="$P_SIGN_IMPORT/certificate.crt"
  P_SIGN_IMPORT_CRT_PLAIN="$P_SIGN_IMPORT/certificate-plain.crt"
  P_SIGN_IMPORT_CRT_CHAIN="$P_SIGN_IMPORT/certificate-chain.crt"

  mkdir -p "$P_SIGN_IMPORT"

  openssl req -in "$FILE" -out "$P_SIGN_IMPORT_CSR"

  if [ -z "$YES" ]; then
    echo '================================================================================'
    openssl req -in "$P_SIGN_IMPORT_CSR" -text -noout
    echo '================================================================================'
    echo '>> Is this OK? Press Enter to sign this CSR'
    read -r
  fi

  # shellcheck disable=SC2086
  openssl ca -utf8 -batch $X_ARGS_VALID_TIME \
    -in "$P_SIGN_IMPORT_CSR" \
    -out "$P_SIGN_IMPORT_CRT" \
    -config "$P_DATA_MIDDLE_CONF_SIGN"

  openssl x509 \
    -in "$P_SIGN_IMPORT_CRT" \
    -out "$P_SIGN_IMPORT_CRT_PLAIN" \
    -outform PEM

  {
    cat "$P_SIGN_IMPORT_CRT_PLAIN"
    cat "$P_DATA_MIDDLE_ROOT_CRT"
    cat "$P_DATA_ANCHOR_ROOT_CRT"
  } > "$P_SIGN_IMPORT_CRT_CHAIN"

}

function createCertificateCST() {

  [ -z "$CN" ] && echo '[USAGE] Env CN missing' && exit 1

  FOLDER=$1
  NAME=$2

  P_DATA_ANCHOR="$P_DATA/anchor"
  P_DATA_ANCHOR_ROOT_CRT="$P_DATA_ANCHOR/authority.crt"

  P_DATA_MIDDLE="$P_DATA/$FOLDER"
  P_DATA_MIDDLE_CONF="$P_DATA_MIDDLE/conf"
  P_DATA_MIDDLE_ROOT_CRT="$P_DATA_MIDDLE/authority.crt"
  P_DATA_MIDDLE_CONF_SIGN="$P_DATA_MIDDLE_CONF/config-sign.ini"

  P_SIGN_CUSTOM="$P_SIGN/$FOLDER/$NAME"

  P_SIGN_CUSTOM_CFG="$P_SIGN_CUSTOM/certificate.ini"
  P_SIGN_CUSTOM_KEY="$P_SIGN_CUSTOM/certificate.key"
  P_SIGN_CUSTOM_CSR="$P_SIGN_CUSTOM/certificate.csr"
  P_SIGN_CUSTOM_CRT="$P_SIGN_CUSTOM/certificate.crt"
  P_SIGN_CUSTOM_CRT_PLAIN="$P_SIGN_CUSTOM/certificate-plain.crt"
  P_SIGN_CUSTOM_CRT_CHAIN="$P_SIGN_CUSTOM/certificate-chain.crt"

  mkdir -p "$P_SIGN_CUSTOM"

  cat > "$P_SIGN_SERVER_CFG" << EOF
[ req ]
prompt             = no
string_mask        = utf8only
req_extensions     = req_extensions
distinguished_name = distinguished_name
[ distinguished_name ]
C                  = $PKI_C
O                  = $PKI_O
CN                 = $CN
EOF

  [ "$OU" ] && echo "OU                 = $OU" >> "$P_SIGN_CUSTOM_CFG"
  [ "$GN" ] && echo "GN                 = $GN" >> "$P_SIGN_CUSTOM_CFG"
  [ "$E" ] && echo "emailAddress       = $E" >> "$P_SIGN_CUSTOM_CFG"

  echo '[ req_extensions ]' >> "$P_SIGN_CUSTOM_CFG"

  openssl ecparam -genkey -name prime256v1 -out "$P_SIGN_CUSTOM_KEY"

  openssl req -utf8 -batch -nodes -new \
    -key "$P_SIGN_CUSTOM_KEY" \
    -out "$P_SIGN_CUSTOM_CSR" \
    -config "$P_DATA_MIDDLE_CONF_SIGN"

  if [ -z "$YES" ]; then
    echo '================================================================================'
    openssl req -in "$P_SIGN_CUSTOM_CSR" -text -noout
    echo '================================================================================'
    echo '>> Is this OK? Press Enter to sign this CSR'
    read -r
  fi

  # shellcheck disable=SC2086
  openssl ca -utf8 -batch $X_ARGS_VALID_TIME \
    -in "$P_SIGN_CUSTOM_CSR" \
    -out "$P_SIGN_CUSTOM_CRT" \
    -config "$P_DATA_MIDDLE_CONF_SIGN"

  openssl x509 \
    -in "$P_SIGN_CUSTOM_CRT" \
    -out "$P_SIGN_CUSTOM_CRT_PLAIN" \
    -outform PEM

  {
    cat "$P_SIGN_CUSTOM_CRT_PLAIN"
    cat "$P_DATA_MIDDLE_ROOT_CRT"
    cat "$P_DATA_ANCHOR_ROOT_CRT"
  } > "$P_SIGN_CUSTOM_CRT_CHAIN"

  {
    echo ''
    echo "$(date '+%Y-%M-%d %H:%m:%S.%N') - Create Certificate CST"
    echo ''
    echo "CA-TYPE -------------- CST"
    echo "CA-NAME -------------- $FOLDER"
    echo ''
    openssl req -in "$P_SIGN_CUSTOM_CSR" -text -noout
    echo ''
    openssl x509 -in "$P_SIGN_CUSTOM_CRT" -text -noout
  } >> "$P_DATA_META"

}

function createCertificateSSL() {

  [ -z "$CN" ] && echo '[USAGE] Env CN missing' && exit 1

  FOLDER=$1
  NAME=$2

  P_DATA_ANCHOR="$P_DATA/anchor"
  P_DATA_ANCHOR_ROOT_CRT="$P_DATA_ANCHOR/authority.crt"

  P_DATA_MIDDLE="$P_DATA/$FOLDER"
  P_DATA_MIDDLE_CONF="$P_DATA_MIDDLE/conf"
  P_DATA_MIDDLE_ROOT_CRT="$P_DATA_MIDDLE/authority.crt"
  P_DATA_MIDDLE_CONF_SIGN="$P_DATA_MIDDLE_CONF/config-sign.ini"

  P_SIGN_SERVER="$P_SIGN/$FOLDER/$NAME"

  P_SIGN_SERVER_CFG="$P_SIGN_SERVER/certificate.ini"
  P_SIGN_SERVER_KEY="$P_SIGN_SERVER/certificate.key"
  P_SIGN_SERVER_CSR="$P_SIGN_SERVER/certificate.csr"
  P_SIGN_SERVER_CRT="$P_SIGN_SERVER/certificate.crt"
  P_SIGN_SERVER_CRT_PLAIN="$P_SIGN_SERVER/certificate-plain.crt"
  P_SIGN_SERVER_CRT_CHAIN="$P_SIGN_SERVER/certificate-chain.crt"

  mkdir -p "$P_SIGN_SERVER"

  cat > "$P_SIGN_SERVER_CFG" << EOF
[ req ]
prompt             = no
string_mask        = utf8only
req_extensions     = req_extensions
distinguished_name = distinguished_name
[ distinguished_name ]
C                  = $PKI_C
O                  = $PKI_O
CN                 = $CN
EOF

  [ "$OU" ] && echo "OU                 = $OU" >> "$P_SIGN_SERVER_CFG"
  [ "$GN" ] && echo "GN                 = $GN" >> "$P_SIGN_SERVER_CFG"
  [ "$E" ] && echo "emailAddress       = $E" >> "$P_SIGN_SERVER_CFG"

  cat >> "$P_SIGN_SERVER_CFG" << EOF
[ req_extensions ]
subjectAltName     = @alternate_names
[ alternate_names ]
DNS                = $CN
EOF

  DNS_LIST=$(echo "$DNS" | tr "," "\n")
  DNS_COUNT=1
  for i in $DNS_LIST; do
    echo "DNS.$DNS_COUNT=$i" >> "$P_SIGN_SERVER_CFG"
    ((DNS_COUNT++))
  done

  IP_LIST=$(echo "$IP" | tr "," "\n")
  IP_COUNT=1
  for i in $IP_LIST; do
    echo "IP.$IP_COUNT=$i" >> "$P_SIGN_SERVER_CFG"
    ((IP_COUNT++))
  done

  openssl ecparam -genkey -name prime256v1 -out "$P_SIGN_SERVER_KEY"

  openssl req -utf8 -batch -nodes -new \
    -key "$P_SIGN_SERVER_KEY" \
    -out "$P_SIGN_SERVER_CSR" \
    -config "$P_SIGN_SERVER_CFG"

  if [ -z "$YES" ]; then
    echo '================================================================================'
    openssl req -in "$P_SIGN_SERVER_CSR" -text -noout
    echo '================================================================================'
    echo '>> Is this OK? Press Enter to sign this CSR'
    read -r
  fi

  # shellcheck disable=SC2086
  openssl ca -utf8 -batch $X_ARGS_VALID_TIME \
    -in "$P_SIGN_SERVER_CSR" \
    -out "$P_SIGN_SERVER_CRT" \
    -config "$P_DATA_MIDDLE_CONF_SIGN"

  openssl x509 \
    -in "$P_SIGN_SERVER_CRT" \
    -out "$P_SIGN_SERVER_CRT_PLAIN" \
    -outform PEM

  {
    cat "$P_SIGN_SERVER_CRT_PLAIN"
    cat "$P_DATA_MIDDLE_ROOT_CRT"
    cat "$P_DATA_ANCHOR_ROOT_CRT"
  } > "$P_SIGN_SERVER_CRT_CHAIN"

  {
    echo ''
    echo "$(date '+%Y-%M-%d %H:%m:%S.%N') - Create Certificate SSL"
    echo ''
    echo "CA-TYPE -------------- SSL"
    echo "CA-NAME -------------- $FOLDER"
    echo ''
    openssl req -in "$P_SIGN_SERVER_CSR" -text -noout
    echo ''
    openssl x509 -in "$P_SIGN_SERVER_CRT" -text -noout
  } >> "$P_DATA_META"

}

function createCertificateVPN() {

  [ -z "$CN" ] && echo '[USAGE] Env CN missing' && exit 1

  FOLDER=$1
  NAME=$2

  P_DATA_ANCHOR="$P_DATA/anchor"
  P_DATA_ANCHOR_ROOT_CRT="$P_DATA_ANCHOR/authority.crt"

  P_DATA_MIDDLE="$P_DATA/$FOLDER"
  P_DATA_MIDDLE_CONF="$P_DATA_MIDDLE/conf"
  P_DATA_MIDDLE_ROOT_CRT="$P_DATA_MIDDLE/authority.crt"
  P_DATA_MIDDLE_CONF_SIGN="$P_DATA_MIDDLE_CONF/config-sign.ini"

  P_SIGN_CLIENT="$P_SIGN/$FOLDER/$NAME"

  P_SIGN_CLIENT_CFG="$P_SIGN_CLIENT/certificate.ini"
  P_SIGN_CLIENT_KEY="$P_SIGN_CLIENT/certificate.key"
  P_SIGN_CLIENT_CSR="$P_SIGN_CLIENT/certificate.csr"
  P_SIGN_CLIENT_CRT="$P_SIGN_CLIENT/certificate.crt"
  P_SIGN_CLIENT_PFX="$P_SIGN_CLIENT/certificate.pfx"
  P_SIGN_CLIENT_CRT_PLAIN="$P_SIGN_CLIENT/certificate-plain.crt"
  P_SIGN_CLIENT_CRT_CHAIN="$P_SIGN_CLIENT/certificate-chain.crt"

  mkdir -p "$P_SIGN_CLIENT"

  cat > "$P_SIGN_CLIENT_CFG" << EOF
[ req ]
prompt             = no
string_mask        = utf8only
distinguished_name = distinguished_name
[ distinguished_name ]
C                  = $PKI_C
O                  = $PKI_O
CN                 = $CN
EOF

  [ "$OU" ] && echo "OU                 = $OU" >> "$P_SIGN_CLIENT_CFG"
  [ "$GN" ] && echo "givenName          = $GN" >> "$P_SIGN_CLIENT_CFG"
  [ "$E" ] && echo "emailAddress       = $E" >> "$P_SIGN_CLIENT_CFG"

  case "$VPN_KEY_MODE" in
  'RSA') openssl genrsa -out "$P_SIGN_CLIENT_KEY" 4096 ;;
  'ECC') openssl ecparam -genkey -name prime256v1 -out "$P_SIGN_CLIENT_KEY" ;;
  *)
    echo "[ERROR] VPN_KEY_MODE must be RSA or ECC, But got -> $VPN_KEY_MODE"
    exit 1
    ;;
  esac

  openssl req -utf8 -batch -nodes -new \
    -key "$P_SIGN_CLIENT_KEY" \
    -out "$P_SIGN_CLIENT_CSR" \
    -config "$P_SIGN_CLIENT_CFG"

  if [ -z "$YES" ]; then
    echo '================================================================================'
    openssl req -in "$P_SIGN_CLIENT_CSR" -text -noout
    echo '================================================================================'
    echo '>> Is this OK? Press Enter to sign this CSR'
    read -r
  fi

  # shellcheck disable=SC2086
  openssl ca -utf8 -batch $X_ARGS_VALID_TIME \
    -in "$P_SIGN_CLIENT_CSR" \
    -out "$P_SIGN_CLIENT_CRT" \
    -config "$P_DATA_MIDDLE_CONF_SIGN"

  openssl x509 \
    -in "$P_SIGN_CLIENT_CRT" \
    -out "$P_SIGN_CLIENT_CRT_PLAIN" \
    -outform PEM

  {
    cat "$P_SIGN_CLIENT_CRT_PLAIN"
    cat "$P_DATA_MIDDLE_ROOT_CRT"
    cat "$P_DATA_ANCHOR_ROOT_CRT"
  } > "$P_SIGN_CLIENT_CRT_CHAIN"

  openssl pkcs12 -export \
    -inkey "$P_SIGN_CLIENT_KEY" \
    -in "$P_SIGN_CLIENT_CRT_CHAIN" \
    -out "$P_SIGN_CLIENT_PFX" \
    -passout pass:

  {
    echo ''
    echo "$(date '+%Y-%M-%d %H:%m:%S.%N') - Create Certificate VPN"
    echo ''
    echo "CA-TYPE -------------- VPN"
    echo "CA-NAME -------------- $FOLDER"
    echo ''
    openssl req -in "$P_SIGN_CLIENT_CSR" -text -noout
    echo ''
    openssl x509 -in "$P_SIGN_CLIENT_CRT" -text -noout
  } >> "$P_DATA_META"

}

function revokeCertificate() {

  FOLDER=$1
  NAME=$2

  P_DATA_MIDDLE="$P_DATA/$FOLDER"
  P_DATA_MIDDLE_CONF="$P_DATA_MIDDLE/conf"
  P_DATA_MIDDLE_ROOT_CRT="$P_DATA_MIDDLE/authority.crt"
  P_DATA_MIDDLE_CONF_SIGN="$P_DATA_MIDDLE_CONF/config-sign.ini"

  P_SIGN_FOOBAR="$P_SIGN/$FOLDER/$NAME"

  P_SIGN_FOOBAR_CRT="$P_SIGN_FOOBAR/certificate.crt"

  openssl ca \
    -revoke "$P_SIGN_FOOBAR_CRT" \
    -config "$P_DATA_MIDDLE_CONF_SIGN"

}

#===================================================================================================================================================================================
#===================================================================================================================================================================================
#===================================================================================================================================================================================

function w_createMiddle() {
  [ -z "$2" ] && echo '[USAGE] Required arg absent <name>' && exit 1
  NAME=$2
  valid='0-9a-zA-Z_'
  if [[ ! $NAME =~ [$valid] ]]; then
    echo '[ERROR] Name can only be [0-9a-zA-Z_]'
    exit 1
  fi
  [ -z "$OU" ] && echo '[USAGE] Env OU missing' && exit 1
  [ -z "$CN" ] && echo '[USAGE] Env CN missing' && exit 1
  TYPE=$1
  case $TYPE in
  'cst')
    FOLDER="custom-$NAME"
    KU="$CST_KU"
    EK="$CST_EK"
    ;;
  'ssl')
    FOLDER="middle-ssl-$NAME"
    KU="$SSL_KU"
    EK="$SSL_EK"
    ;;
  'vpn')
    FOLDER="middle-vpn-$NAME"
    KU="$VPN_KU"
    EK="$VPN_EK"
    ;;
  esac
  echo '================================================================================'
  echo '>>> LitePKI - Create Intermediate CA'
  echo '================================================================================'
  createMiddle "$FOLDER" "$OU" "$CN" "$KU" "$EK"
  updateRevoke "$FOLDER"
  echo '================================================================================'
  echo '>>> Done'
  echo '================================================================================'

  {
    echo ''
    echo "$(date '+%Y-%M-%d %H:%m:%S.%N') - Create Intermediate CA"
    echo ''
    echo "NAME ----------------- $NAME"
    echo "TYPE ----------------- $TYPE"
    echo "FOLDER --------------- $FOLDER"
    echo "OU ------------------- $OU"
    echo "CN ------------------- $CN"
    echo ''
    openssl x509 -in "$P_DATA/$FOLDER/authority.crt" -text -noout
  } >> "$P_DATA_META"

}

function w_revokeMiddle() {
  [ -z "$2" ] && echo '[USAGE] Required <name> absent' && exit 1
  case $1 in
  'cst') FOLDER="custom-$2" ;;
  'ssl') FOLDER="middle-ssl-$2" ;;
  'vpn') FOLDER="middle-vpn-$2" ;;
  esac
  X_FOLDER=$FOLDER
  echo '================================================================================'
  echo '>>> LitePKI - Revoke Intermediate CA'
  echo '================================================================================'
  revokeMiddle "$FOLDER"
  updateRevoke 'anchor'
  echo '================================================================================'
  echo '>>> Done - Remember upload CRL to your distribution server'
  echo '================================================================================'

  {
    echo ''
    echo "$(date '+%Y-%M-%d %H:%m:%S.%N') - Revoke Intermediate CA"
    echo ''
    echo "FOLDER --------------- $X_FOLDER"
  } >> "$P_DATA_META"

}

function w_updateRevoke() {
  if [ -z "$1" ]; then
    FOLDER="anchor"
  else
    [ -z "$2" ] && echo '[USAGE] Required <name> absent' && exit 1
    case $1 in
    'cst') FOLDER="custom-$2" ;;
    'ssl') FOLDER="middle-ssl-$2" ;;
    'vpn') FOLDER="middle-vpn-$2" ;;
    esac
  fi
  X_FOLDER=$FOLDER
  echo '================================================================================'
  echo '>>> LitePKI - Update CA Revoke'
  echo '================================================================================'
  updateRevoke "$FOLDER"
  echo '================================================================================'
  echo '>>> Done - Remember upload CRL to your distribution server'
  echo '================================================================================'

  {
    echo ''
    echo "$(date '+%Y-%M-%d %H:%m:%S.%N') - Update CRL"
    echo ''
    echo "FOLDER --------------- $X_FOLDER"
  } >> "$P_DATA_META"

}

function w_importCertificate() {
  if [ -z "$2" ] && [ -z "$2" ] || [ -z "$3" ]; then
    echo '[USAGE] sh pki.sh ci/si/vi <CSR-NAME> <CSR-FILE>'
    echo '[USAGE] sh pki.sh ci/si/vi <CA-NAME> <CSR-NAME> <CSR-FILE>'
    exit 1
  fi
  P_DATA_ANCHOR="$P_DATA/anchor"
  P_DATA_ANCHOR_ROOT_CRT="$P_DATA_ANCHOR/authority.crt"
  TYPE=$1
  if [ -z "$4" ]; then
    if [ 'cst' == "$TYPE" ]; then
      echo '[USAGE] Custom (CST) CA <name> required'
      exit 1
    fi
    NAME='authority'
    CSR_NAME="$2"
    CSR_FILE="$3"
  else
    NAME=$2
    CSR_NAME=$3
    CSR_FILE=$4
  fi
  case $1 in
  'cst') FOLDER="custom-$NAME" ;;
  'ssl') FOLDER="middle-ssl-$NAME" ;;
  'vpn') FOLDER="middle-vpn-$NAME" ;;
  esac
  X_FOLDER=$FOLDER
  X_CA_TYPE=$TYPE
  X_CA_NAME=$NAME
  X_CSR_NAME=$CSR_NAME
  X_CSR_FILE=$CSR_FILE
  echo '================================================================================'
  echo ">>> LitePKI - Import $1 certificate"
  echo '================================================================================'
  importCertificate "$FOLDER" "$CSR_NAME" "$CSR_FILE"
  echo '================================================================================'
  echo '>>> Done'
  echo '================================================================================'

  {
    echo ''
    echo "$(date '+%Y-%M-%d %H:%m:%S.%N') - Import Certificate"
    echo ''
    echo "CA-TYPE ------------- $X_CA_TYPE"
    echo "CA-NAME ------------- $X_CA_NAME"
    echo "CA-FOLDER ----------- $X_FOLDER"
    echo "CSR-NAME ------------ $X_CSR_NAME"
    echo "CSR-FILE ------------ $X_CSR_FILE"
    echo ''
    openssl req -in "$CSR_FILE" -text -noout
    echo ''
    openssl x509 -in "$P_SIGN/$FOLDER/$CSR_NAME/certificate.crt" -text -noout
  } >> "$P_DATA_META"

}

function w_createCertificate() {
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo '[USAGE] sh pki.sh ci/si/vi <CSR-NAME> <CSR-FILE>'
    echo '[USAGE] sh pki.sh ci/si/vi <CA-NAME> <CSR-NAME> <CSR-FILE>'
    exit 1
  fi
  TYPE=$1
  if [ -z "$3" ]; then
    NAME='authority'
    CSR_NAME="$2"
  else
    NAME=$2
    CSR_NAME=$3
  fi
  echo '================================================================================'
  echo ">>> LitePKI - Create $1 certificate"
  echo '================================================================================'
  case $1 in
  'cst')
    FOLDER="custom-$NAME"
    createCertificateCST "$FOLDER" "$CSR_NAME"
    ;;
  'ssl')
    FOLDER="middle-ssl-$NAME"
    createCertificateSSL "$FOLDER" "$CSR_NAME"
    ;;
  'vpn')
    FOLDER="middle-vpn-$NAME"
    createCertificateVPN "$FOLDER" "$CSR_NAME"
    ;;
  esac
  echo '================================================================================'
  echo '>>> Done'
  echo '================================================================================'

}

function w_revokeCertificate() {
  TYPE=$1
  if [ -z "$4" ]; then
    if [ 'cst' == "$TYPE" ]; then
      echo '[USAGE] Custom (CST) CA <name> required'
      exit 1
    fi
    NAME='authority'
    CERT=$2
  else
    NAME=$2
    CERT=$3
  fi
  case $1 in
  'cst') FOLDER="custom-$NAME" ;;
  'ssl') FOLDER="middle-ssl-$NAME" ;;
  'vpn') FOLDER="middle-vpn-$NAME" ;;
  esac
  x_TYPE=$TYPE
  X_NAME=$FOLDER
  X_CERT=$CERT
  echo '================================================================================'
  echo ">>> LitePKI - Revoke $1 certificate"
  echo '================================================================================'
  revokeCertificate "$FOLDER" "$CERT"
  updateRevoke "$FOLDER"
  echo '================================================================================'
  echo '>>> Done - Remember upload CRL to your distribution server'
  echo '================================================================================'

  {
    echo ''
    echo "$(date '+%Y-%M-%d %H:%m:%S.%N') - Revoke Certificate"
    echo ''
    echo "TYPE -------------- $x_TYPE"
    echo "NAME -------------- $X_NAME"
    echo "CERT -------------- $X_CERT"
  } >> "$P_DATA_META"

}

#===================================================================================================================================================================================
#===================================================================================================================================================================================
#===================================================================================================================================================================================

function main {

  [ -z "$1" ] && help && exit 1

  case $1 in

  'i')
    if [ -f "$P_DATA_META" ]; then
      echo '================================================================================'
      echo '>>> LitePKI - Install'
      echo '================================================================================'
      echo '> Already installed, Abort'
      echo '================================================================================'
      exit 1
    fi
    echo '================================================================================'
    echo '>>> LitePKI - Install'
    echo '================================================================================'
    echo '> Generate Root CA'
    echo '================================================================================'
    createAnchor
    updateRevoke 'anchor'
    echo '================================================================================'
    echo '> Generate Intermediate SSL CA'
    echo '================================================================================'
    CRL="$MIDDLE_SSL_CRL"
    OCSP="$MIDDLE_SSL_OCSP"
    FQDN="$MIDDLE_SSL_FQDN"
    createMiddle 'middle-ssl-authority' "$MIDDLE_SSL_OU" "$MIDDLE_SSL_CN" "$SSL_KU" "$SSL_EK"
    updateRevoke 'middle-ssl-authority'
    echo '================================================================================'
    echo '> Generate Intermediate VPN CA'
    echo '================================================================================'
    CRL="$MIDDLE_VPN_CRL"
    OCSP="$MIDDLE_VPN_OCSP"
    FQDN="$MIDDLE_VPN_FQDN"
    createMiddle 'middle-vpn-authority' "$MIDDLE_VPN_OU" "$MIDDLE_VPN_CN" "$VPN_KU" "$VPN_EK"
    updateRevoke 'middle-vpn-authority'
    echo '================================================================================'
    echo '>>> Done'
    echo '================================================================================'

    {
      echo 'LitePKI - DATABASE'
      echo ''
      echo "$(date '+%Y-%M-%d %H:%m:%S.%N') - Install"
      echo ''
      echo "PKI_C ---------------- $PKI_C"
      echo "PKI_O ---------------- $PKI_O"
      echo ''
      echo "ANCHOR_OU ------------ $ANCHOR_OU"
      echo "ANCHOR_CN ------------ $ANCHOR_CN"
      echo "ANCHOR_CRL ----------- $ANCHOR_CRL"
      echo "ANCHOR_OCSP ---------- $ANCHOR_OCSP"
      echo "ANCHOR_FQDN ---------- $ANCHOR_FQDN"
      echo ''
      openssl x509 -in "$P_DATA/anchor/authority.crt" -text -noout
      echo ''
      echo "MIDDLE_SSL_OU -------- $MIDDLE_SSL_OU"
      echo "MIDDLE_SSL_CN -------- $MIDDLE_SSL_CN"
      echo "MIDDLE_SSL_CRL ------- $MIDDLE_SSL_CRL"
      echo "MIDDLE_SSL_OCSP ------ $MIDDLE_SSL_OCSP"
      echo "MIDDLE_SSL_FQDN ------ $MIDDLE_SSL_FQDN"
      echo ''
      openssl x509 -in "$P_DATA/middle-ssl-authority/authority.crt" -text -noout
      echo ''
      echo "MIDDLE_VPN_OU -------- $MIDDLE_VPN_OU"
      echo "MIDDLE_VPN_CN -------- $MIDDLE_VPN_CN"
      echo "MIDDLE_VPN_CRL ------- $MIDDLE_VPN_CRL"
      echo "MIDDLE_VPN_OCSP ------ $MIDDLE_VPN_OCSP"
      echo "MIDDLE_VPN_FQDN ------ $MIDDLE_VPN_FQDN"
      echo ''
      openssl x509 -in "$P_DATA/middle-vpn-authority/authority.crt" -text -noout
    } >> "$P_DATA_META"

    ;;

  'u')
    FILES=$(ls 'data')
    echo '================================================================================'
    echo '>>> LitePKI - Update All CA Revoke'
    echo '================================================================================'
    echo ''
    for IT in $FILES; do
      echo "Update -> $IT"
      updateRevoke "$IT"
      echo ''
    done
    echo '================================================================================'
    echo '>>> Done - Remember upload CRL to your distribution server'
    echo '================================================================================'

    {
      echo ''
      echo '================================================================================'
      echo ''
      echo "$(date '+%Y-%M-%d %H:%m:%S.%N') - Update all revoke list"
      echo ''
      for IT in $FILES; do
        echo "$IT"
      done
    } >> "$P_DATA_META"

    ;;

  'ic') w_createMiddle 'cst' "$2" ;;
  'is') w_createMiddle 'ssl' "$2" ;;
  'iv') w_createMiddle 'vpn' "$2" ;;

  'rc') w_revokeMiddle 'cst' "$2" ;;
  'rs') w_revokeMiddle 'ssl' "$2" ;;
  'rv') w_revokeMiddle 'vpn' "$2" ;;

  'cu') w_updateRevoke 'cst' "$2" ;;
  'su') w_updateRevoke 'ssl' "$2" ;;
  'vu') w_updateRevoke 'vpn' "$2" ;;

  'ci') w_importCertificate 'cst' "$2" "$3" "$4" ;;
  'si') w_importCertificate 'ssl' "$2" "$3" "$4" ;;

  'cc') w_createCertificate 'cst' "$2" "$3" ;;
  'sc') w_createCertificate 'ssl' "$2" "$3" ;;
  'vc') w_createCertificate 'vpn' "$2" "$3" ;;

  'cr') w_revokeCertificate 'cst' "$2" "$3" ;;
  'sr') w_revokeCertificate 'ssl' "$2" "$3" ;;
  'vr') w_revokeCertificate 'vpn' "$2" "$3" ;;

  '--help') helpAll ;;

  *) help ;;

  esac

}

#===================================================================================================================================================================================
#===================================================================================================================================================================================
#===================================================================================================================================================================================

function help() {
  echo '[USAGE] Use --help for help'
}

function helpAll() {
  echo '================================================================================'
  echo '= LitePKI 2.0 - Create your own PKI in 30 seconds'
  echo '================================================================================'
  echo '= How to'
  echo '= 1. Choose a folder for your PKI.'
  echo '= 2. Copy this script into that folder, Any name is OK.'
  echo '= 3. Modify settings in this script, Document in comment.'
  echo '= 4. Run sh +x foo-bar.sh i, Command i mean install to generate PKI'
  echo '================================================================================'
  echo '= Basic'
  echo '= 1. Intermediate CA has three type CST/SSL/VPN'
  echo '= 2. CST (Custom) CA meant for advance users, modify required'
  echo '= 3. SSL (Server) CA meant for quick generate https certificate'
  echo '= 4. VPN (Client) CA meant for quick generate openvpn certificate'
  echo '================================================================================'
  echo '= Basic Operation'
  echo '= sh pki.sh i ------------------------------------------------------- Create PKI'
  echo '= sh pki.sh u --------------------------------------------------- Update All CRL'
  echo '================================================================================'
  echo '= Anchor CA Operation'
  echo '= sh pki.sh ic -------------------------------------- Create Intermediate CA CST'
  echo '= sh pki.sh is -------------------------------------- Create Intermediate CA SSL'
  echo '= sh pki.sh iv -------------------------------------- Create Intermediate CA VPN'
  echo '= sh pki.sh rc -------------------------------------- Revoke Intermediate CA CST'
  echo '= sh pki.sh rs -------------------------------------- Revoke Intermediate CA SSL'
  echo '= sh pki.sh rv -------------------------------------- Revoke Intermediate CA VPN'
  echo '= A Example Usage'
  echo '= # OU=Example Group Infrastructure Dept'
  echo '= # CN=Example Group Global Facility Intermediate CA SSL T1'
  echo '= # CRL=URI:https://trust.example.com/ssl-t1.crl'
  echo '= # OCSP=OCSP;URI:http://ssl-t1.t.example.com'
  echo '= # FQDN=ssl-t1.t.example.com'
  echo '= # sh +x pki.sh is facility-t1'
  echo '================================================================================'
  echo '= Intermediate CA Operation'
  echo '= sh pki.sh cu <name> ---------------------------------------- Update CST-CA CRL'
  echo '= sh pki.sh su <name> ---------------------------------------- Update SSL-CA CRL'
  echo '= sh pki.sh vu <name> ---------------------------------------- Update VPN-CA CRL'
  echo '= sh pki.sh su --------------------------------- Update middle-ssl-authority CRL'
  echo '= sh pki.sh vu --------------------------------- Update middle-vpn-authority CRL'
  echo '================================================================================'
  echo '= CST Certificate Operation'
  echo '= sh pki.sh ci <ca> <name> <file> ------------------------ Import and sign a CSR'
  echo '= sh pki.sh cc <ca> <name> ------------------------------- Create and sign a CRT'
  echo '= sh pki.sh cr <ca> <name> ---------------------------------------- Revoke a CRT'
  echo '================================================================================'
  echo '= SSL Certificate Operation ----------------- Omit <ca> for middle-ssl-authority'
  echo '= sh pki.sh si <ca> <name> <file> ------------------------ Import and sign a CSR'
  echo '= sh pki.sh sc <ca> <name> ------------------------------- Create and sign a CRT'
  echo '= sh pki.sh sr <ca> <name> ---------------------------------------- Revoke a CRT'
  echo '= A Example Usage'
  echo '= # USE YES=ture to skip confirm'
  echo '= # OU=Example Group Facility Maintenance Dept'
  echo '= # CN=example.com'
  echo '= # DNS=*.example.com,*.*.example.com'
  echo '= # IP=10.0.0.1,192.168.10.2'
  echo '= # sh +x pki.sh sc main'
  echo '================================================================================'
  echo '= VPN Certificate Operation ----------------- Omit <ca> for middle-vpn-authority'
  echo '= sh pki.sh vc <ca> <name> ------------------------------- Create and sign a CRT'
  echo '= sh pki.sh vr <ca> <name> ---------------------------------------- Revoke a CRT'
  echo '= A Example Usage'
  echo '= # USE YES=ture to skip confirm'
  echo '= # OU=ExampleGroup RD Dept'
  echo '= # CN=EXP305253'
  echo '= # GN=Tom Lee'
  echo '= # E=tom-lee@example.com'
  echo '= # sh +x pki.sh vc tom-lee'
  echo '================================================================================'
  echo '= Read More: LitePKI@github/Alceatraz'
  echo '================================================================================'
}

#===================================================================================================================================================================================
#===================================================================================================================================================================================
#===================================================================================================================================================================================

main "$@"

# unset "${!HAS_@}"
