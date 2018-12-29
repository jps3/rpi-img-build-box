#!/bin/bash -e

# Delete user 'pi' (not needed)
on_chroot << EOF
if (id -u pi 2>/dev/null); then
    echo "# WARN # Locking account for user 'pi'"
    passwd -l pi
fi
EOF

on_chroot << EOF
setupcon --force --save-only -v
EOF

