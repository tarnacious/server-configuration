## Local Backup

This role configures are Raspberry Pi running on my home network as a backup
server. The Raspberry Pi has a WIFI adaptor and a 1TB disk attached via USB.

The backup job mounts the local disk and a remote CIFS share and uses rsync to
synchronize the local disk with the remote CIFS share which contains backup
volume.

The backup job is scheduled to run daily at 2am and then email me on
completion.
