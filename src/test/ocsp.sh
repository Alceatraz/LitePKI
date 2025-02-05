openssl ocsp \
  -CA 'data/anchor/data/authority.crt' \
  -rkey 'data/anchor/ocsp/authority.key' \
  -rsigner 'data/anchor/ocsp/authority.crt' \
  -index 'data/anchor/meta/database' \
  -port 8080
