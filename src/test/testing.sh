function lines() {
  echo '' && echo '' && echo '' && echo '' && echo ''
  echo '' && echo '' && echo '' && echo '' && echo ''
}

rm -rf data && rm -rf sign

cp '../main/pki.sh' 'pki.sh'

cat > 'temp.txt' << 'EOF'
DEFAULT_TIME_MODE='date'

DEFAULT_DATE_START='19700101'
DEFAULT_DATE_CLOSE='20700101'

DEFAULT_DATE_SUFFIX='000000Z'

DEFAULT_DAYS='90'

PKI_C='US'
PKI_O='Example Group'

ANCHOR_E='infra-admin@example.com'
ANCHOR_OU='Example Group Global'
ANCHOR_CN='Example Group Trust Anchor'
ANCHOR_CRL='URI:https://trust.example.com/root'
ANCHOR_OCSP='OCSP;URI:http://root.ts2.example.com'
ANCHOR_FQDN='root.ts2.example.com'

MIDDLE_SSL_OU='Example Group Facility'
MIDDLE_SSL_CN='Example Group Intermediate SSL Authority'
MIDDLE_SSL_CRL='URI:https://trust.example.com/ssl'
MIDDLE_SSL_OCSP='OCSP;URI:http://ssl.ts2.example.com'
MIDDLE_SSL_FQDN='ssl.ts2.example.com'

MIDDLE_VPN_OU='Example Group Facility'
MIDDLE_VPN_CN='Example Group Intermediate VPN Authority'
MIDDLE_VPN_CRL='URI:https://trust.example.com/vpn'
MIDDLE_VPN_OCSP='OCSP;URI:http://vpn.ts2.example.com'
MIDDLE_VPN_FQDN='vpn.ts2.example.com'

DEFAULT_VPN_KEY_MODE='ECC'
EOF

sed -i '/#SED-INSERT/e cat temp.txt' 'pki.sh'

rm -rf 'temp.txt'

lines

DEBUG=true \
  sh +x pki.sh i

lines

DEBUG=true \
  OU='Example Group Infrastructure Dept' \
  CN='Example Group Global Facility Intermediate CA T1' \
  CRL='URI:https://trust.example.com/middle-ssl-facility-t1.crl' \
  FQDN='t1.t.example.com' \
  OCSP='OCSP;URI:http://t1.t.example.com' \
  sh +x pki.sh is facility-t1

lines

DEBUG=true \
  OU='Example Group Infrastructure Dept' \
  CN='Example Group Global Facility Intermediate CA T2' \
  CRL='URI:https://trust.example.com/middle-ssl-facility-t2.crl' \
  FQDN='t2.t.example.com' \
  OCSP='OCSP;URI:http://t2.t.example.com' \
  sh +x pki.sh is facility-t2

lines

DEBUG=true \
  OU='Example Group Infrastructure Dept' \
  CN='Example Group Global Facility Intermediate CA T3' \
  CRL='URI:https://trust.example.com/middle-ssl-facility-t3.crl' \
  OCSP='OCSP;URI:http://t3.t.example.com' \
  FQDN='t3.t.example.com' \
  sh +x pki.sh is facility-t3

lines

DEBUG=true \
  OU='Example Group Global Facility' \
  CN='Example Group INFRA01-NETSEC-POP' \
  CRL='URI:https://trust.example.com/middle-vpn-infra01-netsec-pop.crl' \
  OCSP='OCSP;URI:http://v01nspa.t.example.com' \
  FQDN='v01nspa.t.example.com' \
  sh +x pki.sh iv infra01-netsec-pop

lines

DEBUG=true \
  sh +x pki.sh rs facility-t2

lines

DEBUG=true YES=ture \
  OU='ExampleGroup RD Dept' \
  CN='EXP305253' \
  GN='Tom Lee' \
  E='tom-lee@example.com' \
  sh +x pki.sh vc tom-lee

lines

DEBUG=true YES=ture \
  OU='Example Group Facility Maintenance Dept' \
  CN='example.com' \
  DNS='*.example.com,*.*.example.com' \
  IP='10.0.0.1,192.168.10.2' \
  sh +x pki.sh sc main

lines

DEBUG=true YES=ture \
  OU='EXAMPLE Entertainment ' \
  CN='example-entertainment.local' \
  DNS='*.example-entertainment.local' \
  sh +x pki.sh sc entertainment

lines

DEBUG=true \
  sh +x pki.sh sr entertainment

lines

DEBUG=true YES=ture \
  sh +x pki.sh si foobar foobar.csr

lines

DEBUG=true \
  OU='ExampleGroup Infrastructure Dept' \
  CN='ExampleGroup Service Desk and Security Lab' \
  CRL='https://trust.example.com/x278.crl' \
  sh +x pki.sh ic service-desk

lines
