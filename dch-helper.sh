#!/bin/bash -e

# This script is executed within the container as root.  It assumes
# that source code with debian packaging files can be found at
# /source-ro and that resulting packages are written to /output after
# succesful build.  These directories are mounted as docker volumes to
# allow files to be exchanged between the host and the container.

# Install extra dependencies that were provided for the build (if any)
#   Note: dpkg can fail due to dependencies, ignore errors, and use
#   apt-get to install those afterwards

eval "$(cat /.env)"
echo "====================="
cat /.env
echo "====================="
cd source
if [[ -f debian/changelog.dch ]]
then
    rm debian/changelog.dch
fi
dch -i
dch -r jammy
