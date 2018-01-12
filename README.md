# db4s-build-ppa-packages
script to upload packages to ppa for nightly builds.

place a script in the same folder 'debuild.xp'

```
#!/usr/bin/expect
spawn debuild -S -k<key id>
expect "Enter passphrase: "
send "mypassphrase\r"
expect "Enter passphrase: "
send "mypassphrase\r"
interact

```
