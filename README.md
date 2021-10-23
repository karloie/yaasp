# karloie/yaasp

**Y**et **A**nother **A**lpine **S**SH **P**roxy.


## Why?

Because Linux + Docker is fun and I wanted a SSH proxy jump server that can be run in read-only mode.

### Features:

- Alpine Linux for minimal attack surface.
- Read only container for better security.
- Randomized user and group ids.
- Public key authentication.
- Google Authenticator 2FA.
- Easy configuration.

### Algorithm hardening:

Weak and obsolete algorithms have been disabled and tested with these tools.

- [Evict SSHScan](https://github.com/evict/SSHScan)
- [Operous SSH test](https://sshcheck.operous.dev/)
- [Rebex SSH Test](https://sshcheck.com/)


## Building

Check out the project and build the container image:

```sh
docker build . -t karloie/yaasp
```

The resulting image comes in at about 10MB in size and contains no host or user secrets.

```sh
REPOSITORY      TAG       IMAGE ID       CREATED          SIZE
karloie/yaasp   latest    2dd9c4307472   3 seconds ago    10.3MB
```


## Configuration

Configuration is done by mounting files to the */config* directory of the container.

Example with banner, host keys and two users named *karl* and *khamphat*:

```sh
/config
├── ssh
│   ├── banner
│   ├── ssh_host_ecdsa_key
│   ├── ssh_host_ecdsa_key.pub
│   ├── ssh_host_rsa_key
│   └── ssh_host_rsa_key.pub
└── home
    ├── karl
    │   ├── .google_authenticator
    │   └── .ssh
    │       └── authorized_keys
    └── khamphat
        ├── .google_authenticator
        └── .ssh
            └── authorized_keys
```


### Configure the host keys:

Generate server keys:

```sh
ssh-keygen -t rsa -f config/ssh/ssh_host_rsa_key
ssh-keygen -t ed25519 -f config/ssh/ssh_host_ed25519_key
```

### Configure authorized_keys:

Copy public keys to *config/home/<USER_NAME>/.ssh/authorized_keys*

```sh
cat ~/.ssh/id_ed25519.pub >> config/home/karl/.ssh/authorized_keys
```

### Configure Google Authenticator 2FA:

Run the image with the ga command and configure 2FA for your device(s):

```sh
docker run --rm -ti karloie/yaasp ga
```

After configuration copy the result to *config/home/<USER_NAME>/.google_authenticator*.

```sh
ORARBPFV6CBRSYZYYK5STNOAVE
" TOTP_AUTH
71538830
17395986
37311778
12263066
70661614
```


## Running

Run with config:

```sh
docker run \
    --rm \
    --init \
    --name yaasp \
    --read-only \
    --tmpfs /run \
    --tmpfs /tmp \
    -p 2222:2222 \
    -v $(pwd)/config:/config:ro \
    -t karloie/yaasp
```

Running with docker-compose:

```sh
  yaasp:
    image: karloie/yaasp
    read_only: true
    ports:
      - 2222:2222
    tmpfs:
      - /run
      - /tmp
    volumes:
      - ./config:/config:ro
```

## Feedback

If you have questions, feature requests or a bug you want to report, please click [here](https://github.com/karloie/yaasp/issues) to file an issue.

## Author

* **Karl-Bjørnar Øie**

Copyright (c) 2021 Karl-Bjørnar Øie.

## License

This project is licensed under the MIT License
