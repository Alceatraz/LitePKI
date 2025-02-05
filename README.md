# LitePKI

--- 

```code
!!!!!!!!!!!WARNING!!!!!!!!!!!!
ALL PRIVATE KEY STORE LOCALLY!
KEY COMPROMISE IS IRREPARABLE!
DO NOT LET ANYONE TOUCHING IT!
!!!!!!!!!!!WARNING!!!!!!!!!!!!
```

---

Build your PKI in 30 seconds!

## Install

1. Copy `pki.sh` to your PKI folder
2. Modify `pki.sh` settings
    1. Manually edit
    2. Use sed replace one by one `sed -i 's/SETTING-DEFAULT-TIME-MODE/date/g' 'pki.sh'`
    3. Use sed replace placeholder `sed -i '/#SED-INSERT/e cat foo-bar.txt' 'pki.sh'`
3. Invoke `sh +x pki.sh i` to generate Root CA and default Intermediate CA

## Usage

See testing.sh for demos

---

# Extra

## OpenVPN

### Service

Systemd service file location `/usr/lib/systemd/system/ovpn.service`

```text
[Unit]
Description=ovpn - OpenVPN
Requires=network.target
Wants=nss-lookup.target
Before=nss-lookup.target
After=network.target

[Service]
Type=simple
PrivateTmp=true
WorkingDirectory=/etc/openvpn/server
ExecStart=openvpn --config server.conf
ExecReload=/bin/kill -HUP

[Install]
WantedBy=multi-user.target
```

### Server-Config

- `server.key` -> `server-ssl-key`
- `server.crt` -> `server-ssl` + `inter-ca` + `root-ca`
- `client.pem` -> `client-crl`
- `client.crt` -> `client-ca + root-ca`

```text
group nogroup
user nobody

port       443
proto      tcp-server
tls-server
tls-cipher TLS-ECDHE-ECDSA-WITH-AES-128-GCM-SHA256
cipher      AES-128-GCM
ncp-ciphers AES-128-GCM
dh         none
ca         cert/client.crt
crl-verify cert/client.pem
key        cert/server.key
cert       cert/server.crt

dev tun
topology subnet
client-to-client
persist-key
persist-tun
ifconfig-pool-persist ipp.data
server 1.2.3.4 255.255.255.0
status /var/log/openvpn/status.log
push "dhcp-option DNS 1.2.3.4"
push "route 1.2.3.4 255.255.255.0"
```

### Client-Config

```text
remote <host> <port>
client
dev        tun
proto      tcp-client
auth       SHA256
cipher     AES-128-GCM
tls-cipher TLS-ECDHE-ECDSA-WITH-AES-128-GCM-SHA256
<ca>
-----BEGIN CERTIFICATE-----

-----END CERTIFICATE-----
</ca>
<cert>
-----BEGIN CERTIFICATE-----

-----END CERTIFICATE-----
</cert>
<key>
-----BEGIN PRIVATE KEY-----

-----END PRIVATE KEY-----
</key>
```
