#!/bin/bash -e

# Delete user 'pi' (not needed)
log "    INFO -- on_chroot > Locking account for user 'pi'"
on_chroot << EOF
if (id -u pi 2>/dev/null); then
    passwd -l pi
fi
EOF

log "    INFO -- on_chroot > setupcon"
on_chroot << EOF
setupcon --force --save-only -v
EOF

