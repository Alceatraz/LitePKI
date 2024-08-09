# LitePKI

A easy script to create PKI infrastructure in 3 seconds!

# Install

1. Choose a folder as your foundation, Don't let anyone else touch it.
2. Make sure you have bash shell, `Git for Windows` is recommended with windows.
3. Install OpenSSL and make sure it in PATH.
4. Copy `litepki.sh` into folder. And modify it, Details on comment.
5. run `sh +x litepki.sh i` to initialization PKI. This will generate Root CA.

# Config

Notice:

Intermediate CA Server: A CA for CSR signature (For https). Single.
Intermediate CA Client: A CA for client auth like OpenVPN/OCServ/Nginx. Multi.

# Usage

All usage show in `sh litepki.sh help`

---

# Tested on

- Debian + bash
- Windows + git for windows

> RHEL/Centos/Fedora and any CtOS copy won't test.
