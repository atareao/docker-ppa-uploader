#!/bin/bash -e

# This script is executed within the container as root.  It assumes
# that source code with debian packaging files can be found at
# /source-ro and that resulting packages are written to /output after
# succesful build.  These directories are mounted as docker volumes to
# allow files to be exchanged between the host and the container.

# Install extra dependencies that were provided for the build (if any)
#   Note: dpkg can fail due to dependencies, ignore errors, and use
#   apt-get to install those afterwards
eval "$(cat .env)"
change_explorer(){
    SRC="$1"
    DST="$2"
    MAIN_DIR="/build/source"
    SRCDIR="$MAIN_DIR/src"
    PODIR="$MAIN_DIR/po"
    DEBIANDIR="$MAIN_DIR/debian"
    grep -Rli "$SRC" "$SRCDIR" | while IFS= read -r line
    do
        sed -i -e "s/${SRC^}/${DST^}/g" "$line"
        sed -i -e "s/$SRC/$DST/g" "$line"
    done
    grep -Rli "$SRC" "$PODIR" | while IFS= read -r line
    do
        sed -i -e "s/${SRC^}/${DST^}/g" "$line"
        sed -i -e "s/$SRC/$DST/g" "$line"
    done
    grep -Rli "$SRC" "$DEBIANDIR" | while IFS= read -r line
    do
        sed -i -e "s/${SRC^}/${DST^}/g" "$line"
        sed -i -e "s/$SRC/$DST/g" "$line"
    done
}
mybuilder() {
    echo '=== STARTING ==='
    MAIN_DIR="/build/source"
    SRCDIR="$MAIN_DIR/src"
    LOCALE="$MAIN_DIR/locale"
    CHANGELOG="$MAIN_DIR/debian/changelog"
    PARENDIR="$(dirname "$MAIN_DIR")"
    PYCACHEDIR=$SRCDIR'/__pycache__'
    if [ ! -f "${CHANGELOG}" ]
    then
        echo "Esto no es para empaquetar"
        return 1
    fi
    if [[ -d "$PYCACHEDIR" ]]; then
        echo '====================================='
        echo "Removing cache directory: $PYCACHEDIR"
        rm -rf "$PYCACHEDIR"
    fi
    if [ -d "$LOCALE" ]; then
        echo '====================================='
        echo "Removing locale directory: $LOCALE"
        rm -rf "$LOCALE"
    fi
    firstline=$(head -n 1 "$CHANGELOG")
    app=$(echo "$firstline" | grep -oP "^[^\s]*")
    app=${app:l} #lowercase
    version=$(echo "$firstline" | grep -oP "\s\(\K[^\)]*")
    #
    echo '=========================='
    echo 'Building debian package...'
    debuild --no-tgz-check -S -sa -d -k"$KEY"
    package="${PARENDIR}/${app}_${version}_source.changes"
    if [ -f "$package" ]; then
        echo '==========================='
        echo "Uploading debian package..."
        dput ppa:"$PPA" "${PARENDIR}/${app}_${version}_source.changes"
    else
        echo "Error: package not build"
    fi
}

echo "=== INSTALLING DEPENDENCIES ==="
[[ -d /dependencies ]] && dpkg -i /dependencies/*.deb || apt-get -f install -y --no-install-recommends

# Make read-write copy of source code
mkdir -p /build
cp -a /source-ro /build/source
cd /build/source
mkdir -p /root
cp -a /gnupg-ro /root/.gnupg
chown -R root:root /root/.gnupg
ls -la /root/.gnupg/

# Install build dependencies
mk-build-deps -ir -t "apt-get -o Debug::pkgProblemResolver=yes -y --no-install-recommends"

# Build packages
mybuilder
grep -Ri python3-nautilus /build/source/debian/control
rs=$?
if [[ $rs -eq 0 ]]
then
    change_explorer nautilus nemo
    mybuilder
    change_explorer nemo caja
    mybuilder
fi
