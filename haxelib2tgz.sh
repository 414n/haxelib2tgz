#!/bin/bash

usage() {
	cat << EOF
Usage:
	$(basename $0) package
will download package with haxelib and prepare a Slackware package for it.
EOF
}

run_haxelib() {
	mkdir -p "$HAXELIB_PATH"
	haxelib "$@"
}

write_slack_desc_line() {
	echo "${PRGNAM}: $*" >> "$PKG/install/slack-desc"
}

write_empty_slack_desc_line() {
	write_slack_desc_line " "
}

print_info() {
	run_haxelib info "$PRGNAM"
}

print_version() {
	print_info | awk '/Version:/ {$1=""; gsub(/^[ \t]+/, "", $0); print $0}'
}

print_description() {
	print_info | awk '/Desc:/ {$1=""; gsub(/^[ \t]+/, "", $0); print $0}'
}

print_website() {
	print_info | awk '/Website:/ {$1=""; gsub(/^[ \t]+/, "", $0); print $0}'
}

if [ $# -ne 1 ]
then
	usage
	exit 1
fi

# Automatically determine the architecture we're building on:
if [ -z "$ARCH" ]; then
  case "$( uname -m )" in
    i?86) ARCH=i586 ;;
    arm*) ARCH=arm ;;
    # Unless $ARCH is already set, use uname -m for all other archs:
       *) ARCH=$( uname -m ) ;;
  esac
fi


if [ "$ARCH" = "x86_64" ]; then
  LIBDIRSUFFIX="64"
fi

PRGNAM="$1"
BUILD=${BUILD:-1}
TAG=${TAG:-_SBo}

PKGARCH=haxelib

TMP=${TMP:-/tmp/SBo}
PKG=$TMP/package-$PRGNAM
OUTPUT=${OUTPUT:-/tmp}
# This overrides the default haxelib path when running haxelib
export HAXELIB_PATH="$PKG/usr/lib${LIBDIRSUFFIX}/haxe/lib"

set -e

if ! INFO="$(print_info)"
then
	echo "Error retrieving info for package $PRGNAM: $INFO"
	exit 1
fi

if ! VERSION="$(print_version)"
then
	echo "Error retrieving version info on $PRGNAM!"
	exit 1
fi

echo "Going to package $PRGNAM-$VERSION"

rm -rf $PKG
mkdir -p $TMP $PKG $OUTPUT

run_haxelib install "$PRGNAM"

cd $PKG
chown -R root.root .
find -L . \
 \( -perm 777 -o -perm 775 -o -perm 750 -o -perm 711 -o -perm 555 \
  -o -perm 511 \) -exec chmod 755 {} \; -o \
 \( -perm 666 -o -perm 664 -o -perm 640 -o -perm 600 -o -perm 444 \
  -o -perm 440 -o -perm 400 \) -exec chmod 644 {} \;

#mkdir -p $PKG/usr/{bin,doc/$PRGNAM-$VERSION}
#cp haxelib2tgz $PKG/usr/bin
#chmod +x $PKG/usr/bin/haxelib2tgz

#cp README LICENSE $PKG/usr/doc/$PRGNAM-$VERSION
#cat $CWD/$PRGNAM.SlackBuild > $PKG/usr/doc/$PRGNAM-$VERSION/$PRGNAM.SlackBuild

mkdir -p $PKG/install

# 1st line of slack desc
write_slack_desc_line "$PRGNAM"
# 2nd line (empty)
write_empty_slack_desc_line
# Number of lines that the description would take when wrapped at 72 chars
# length (as in slack-desc files). Actual length would be 73, but here we
# consider an extra space char put after every ':' char.
desc_lines="$(print_description | fmt --width=72 | wc -l)"
# 3rd-9th line - description and empty lines
for ((i = 1; i <= 7; i++))
do
	if [ "$i" -le "$desc_lines" ]
	then
		write_slack_desc_line "$(print_description | fmt --width=72 | sed -n "$i"p)"
	else
		write_empty_slack_desc_line
	fi
done
# 10th line
write_slack_desc_line "Homepage:"
# 11th (last) line
write_slack_desc_line "$(print_website)"

cd $PKG
/sbin/makepkg -l y -c n $OUTPUT/$PRGNAM-$VERSION-$PKGARCH-$BUILD$TAG.${PKGTYPE:-tgz}
