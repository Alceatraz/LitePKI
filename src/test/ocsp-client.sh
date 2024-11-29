openssl ocsp \
  -resp_text \
  -url http://127.0.0.1:8080 \
  -CAfile 'data/anchor/data/authority.crt' \
  -issuer 'data/anchor/data/authority.crt' \
  -cert 'data/middle-ssl-facility-t2/authority.crt'
