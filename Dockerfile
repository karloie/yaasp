FROM alpine:3.13

LABEL maintainer="karloie@gmail.com"

RUN set -ex && \
    apk add --no-cache openssh-server openssh-server-pam google-authenticator libqrencode && \
    apk del alpine-keys apk-tools openssh-keygen && \
    rm -rf /var/cache/apk/*

ENV CFG="/etc/ssh/sshd_config"

RUN set -ex && \
    # general
    sed -ri 's/^#?Port\s+.*/Protocol 2/' $CFG && \
    sed -ri 's/^#?Banner\s+.*/Banner \/run\/ssh\/\/banner/' $CFG && \
    # host keys
    sed -ri 's/^#HostKey\s+.*ssh_host_rsa_key/HostKey \/run\/ssh\/ssh_host_rsa_key/' $CFG && \
    sed -ri 's/^#HostKey\s+.*ssh_host_ed25519_key/HostKey \/run\/ssh\/ssh_host_ed25519_key/' $CFG && \
    # client keys
    sed -ri 's/^#?PermitRootLogin\s+.*/PermitRootLogin no/' $CFG && \
    sed -ri 's/^#?PubkeyAuthentication\s+.*/PubkeyAuthentication yes/' $CFG && \
    sed -ri 's/^#?PermitEmptyPasswords\s+.*/PermitEmptyPasswords no/' $CFG && \
    sed -ri 's/^#?PasswordAuthentication\s+.*/PasswordAuthentication no/' $CFG

ADD sshd /etc/pam.d/
RUN set -ex && \
    # google authentication
    sed -ri 's/^#?UseDNS\s+.*/UseDNS no/' $CFG && \
    sed -ri 's/^#?UsePAM\s+.*/UsePAM yes/' $CFG && \
    sed -ri 's/^#?ChallengeResponseAuthentication\s+.*/ChallengeResponseAuthentication yes/' $CFG && \
    echo "" >> $CFG && \
    echo "AuthenticationMethods publickey,keyboard-interactive" >> $CFG

RUN set -ex && \
    # user allowances
    sed -ri 's/^#?PermitTunnel\s+.*/PermitTunnel yes/' $CFG && \
    sed -ri 's/^#?AllowTcpForwarding\s+.*/AllowTcpForwarding yes/' $CFG && \
    sed -ri 's/^#?AllowAgentForwarding\s+.*/AllowAgentForwarding yes/' $CFG && \
    # user restrictions
    echo "" >> $CFG && \
    echo "AllowGroups sshjmp" >> $CFG && \
    echo "ForceCommand /sbin/nologin" >> $CFG

RUN set -ex && \
    # algorithm hardening
    echo "" >> $CFG && \
    echo "HostKeyAlgorithms \
        ecdsa-sha2-nistp256-cert-v01@openssh.com, \
        ecdsa-sha2-nistp256, \
        ecdsa-sha2-nistp384-cert-v01@openssh.com, \
        ecdsa-sha2-nistp384, \
        ecdsa-sha2-nistp521-cert-v01@openssh.com, \
        ecdsa-sha2-nistp521, \
        rsa-sha2-256-cert-v01@openssh.com, \
        rsa-sha2-256, \
        rsa-sha2-512-cert-v01@openssh.com, \
        rsa-sha2-512, \
        ssh-ed25519-cert-v01@openssh.com, \
        ssh-ed25519, \
#        ssh-rsa, \
        ssh-rsa-cert-v01@openssh.com \
    " | sed 's/,\s*/,/g' >> $CFG && \
    echo "KexAlgorithms \
        curve25519-sha256, \
        curve25519-sha256@libssh.org, \
        diffie-hellman-group-exchange-sha256, \
#        diffie-hellman-group14-sha1, \
#        diffie-hellman-group14-sha256, \
        diffie-hellman-group16-sha512, \
        diffie-hellman-group18-sha512, \
#        ecdh-sha2-nistp256, \
#        ecdh-sha2-nistp384, \
#        ecdh-sha2-nistp521 \
    " | sed 's/,\s*/,/g' >> $CFG && \
    echo "Ciphers \
        aes128-ctr, \
        aes192-ctr, \
        aes128-gcm@openssh.com, \
        aes256-ctr, \
        aes256-gcm@openssh.com, \
        chacha20-poly1305@openssh.com \
    " | sed 's/,\s*/,/g' >> $CFG && \
    echo "MACs \
#        hmac-sha1-etm@openssh.com, \
        hmac-sha2-256-etm@openssh.com, \
#        hmac-sha2-256, \
        hmac-sha2-512-etm@openssh.com, \
#        hmac-sha2-512, \
#        hmac-sha1, \
        umac-128-etm@openssh.com, \
#        umac-128@openssh.com, \
#        umac-64-etm@openssh.com, \
#        umac-64@openssh.com \
    " | sed 's/,\s*/,/g' >> $CFG

RUN set -ex && \
    mkdir /bak && chmod 0400 /bak && \
    cp -p /etc/group /bak && ln -fs /run/group /etc/group && \
    cp -p /etc/passwd /bak && ln -fs /run/passwd /etc/passwd && \
    cp -p /etc/shadow /bak && ln -fs /run/shadow /etc/shadow

ENV PORT="2222"

EXPOSE 2222

WORKDIR /run/sshd

COPY entrypoint.sh /
ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
