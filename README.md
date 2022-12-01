# LitePKI

You can create your own PKI infrastructure in 3 seconds!

## Why bother using SSL ?

Good question! So why bother your money in the bank or safety, Let's just brun them to oblivion!

## TL;DR

- Install openssl
- Create folder, Copy script, Modify variables.
- `sh litepki.sh help` to show usage.
- `sh litepki.sh i` to generate your infrastructure.

## Setup step

### Step 0

Install OpenSSL

### Step 1

> This script design to be easy use, So some parameters move to setup stage.

Create folder in safe place. Then copy `litepki.sh` into it.  
Only modify content between `# Don't modify above this line` and `# Don't modify after this line`

### Step 2

Change the default days you like. I like set it to 36500 -- Just because, It's not safe!

```shell
[ -z "$DAYS" ] && DAYS="360"
```

### Step 3

Change the basic setting of all certs, Its standard extern parts.

```shell
[ -z "$DIST_C" ] && DIST_C='CN'
[ -z "$DIST_ST" ] && DIST_ST='example'
[ -z "$DIST_L" ] && DIST_L='example'
[ -z "$DIST_O" ] && DIST_O='example'
```

### Step 4

Change your ROOT-CA name, Its standard extern parts.

```shell
[ -z "$DIST_OU" ] && DIST_OU='example'
[ -z "$DIST_CN" ] && DIST_CN='example Root CA'
[ -z "$DIST_GN" ] && DIST_GN='example Root CA'
```

### Step 5

Change your Intermediate-CA name for server https

```shell
[ -z "$DIST_OU_S" ] && DIST_OU_S='example'
[ -z "$DIST_CN_S" ] && DIST_CN_S='example Intermediate CA For HTTP-SSL'
```

### Step 6

Change your Intermediate-CA name for client cert auth

```shell
[ -z "$DIST_OU_S" ] && DIST_OU_S='example'
[ -z "$DIST_CN_S" ] && DIST_CN_S='example Intermediate CA For HTTP-SSL'
```

### Step 7

Modify CRL setting, Or comment it if you don't need CRL.

```shell
X509_ROOT_CRL='URI:http://example.com/root.crl,URI:http://example.org/root.crl'
X509_SERV_CRL='URI:http://example.com/serv.crl,URI:http://example.org/serv.crl'
```

## Usage and Demo

### Step 0

Create your own empire

```shell
sh litepki.sh i
```

### Step 1

And trust your Root-CA in all system:

- Copy root-ca to `/usr/local/share/ca-certificates/xxx.crt`
- Run command `update-ca-certificates`

**Notice: This works on debian. And who the Fxxk want CentOS anymore?**

### Step 2

All usage show in `sh litepki.sh help`
