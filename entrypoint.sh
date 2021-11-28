#!/bin/sh -e

# google authenticator
if [ "$1" = "ga" ]; then
  google-authenticator -f -s /tmp/ga
  echo
  cat /tmp/ga
  echo
  exit 0
fi

# restore
rm -f /run/group* /run/passwd* /run/shadow*
cp -p /bak/* /run
echo " -> /etc/alpine-release: $(cat /etc/alpine-release)"

# create groups
while :; do
  gid="$(shuf -i 2000-4000 -n 1)" && [[ "$(getent group $gid)" = "" ]] && break
done
addgroup -g $gid sshjmp

# create users
[ "$(ls -A /config/home)" ] && for p in /config/home/*/ ; do
  [ -d "$f" ] && continue
  u="$(basename $p)"
  while :; do
    uid="$(shuf -i 10000-20000 -n 1)" && [[ "$(getent passwd $uid)" = "" ]] && break
  done
  h="/run/home/$u"
  mkdir -p "$h/.ssh/"
  adduser "$u" -D -h "$h" -s /bin/false -g "$u" -u $uid
  addgroup "$u" sshjmp
  echo " -> $h: $(id $u)"
  chmod -R 2755 "$h"
  chmod -R 0700 "$h"/.ssh
  f="/config/home/$u/.ssh/authorized_keys"
  if [ -f "$f" ]; then
    cp -v "$f" "$h/.ssh"
    chmod 0400 "$h/.ssh/authorized_keys"
  fi
  f="/config/home/$u/.google_authenticator"
  if [ -f "$f" ]; then
    cp -v "$f" "$h"
    chmod 0400 "$h/.google_authenticator"
  fi
  chown -R "$u:$u" "$h"
done

# setup sshd
rm -Rf /run/ssh
mkdir -p /run/ssh
[ -d /config/ssh ] && cp -R /config/ssh /run
f="/run/ssh/ssh_host_rsa_key" && echo " -> $f: $(ssh-keygen -E md5 -lf $f)"
f="/run/ssh/ssh_host_ed25519_key" && echo " -> $f: $(ssh-keygen -E sha512 -lf $f)"
chown -R root:root /run/ssh /run/sshd
chmod -R 0400 /run/ssh /run/sshd

# start sshd
cmd="/usr/sbin/sshd.pam -p $PORT -De -u0"
if [ "$1" = "debug" ]; then
  $cmd -T
  exec $cmd -d
elif [ -z "$1" ]; then
  exec $cmd
else
  exec "$@"
fi
