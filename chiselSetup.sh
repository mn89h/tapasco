#!/bin/bash
DIR=$PWD/chisel3
URL=https://github.com/freechipsproject
REPOS="firrtl firrtl-interpreter chisel3 chisel-testers"
REPO_URLS=`for r in $REPOS; do echo $URL/$r.git; done`

echo "Installing Chisel3 dependencies in $DIR ..."

if [ "$1" = "clean" ]; then
	rm -rf $DIR
else
	mkdir -p $DIR
	pushd $DIR &&
	for r in $REPOS; do
		if [ ! -e $r ]; then
			git clone "$URL/$r.git" &&
			pushd $r &&
			sbt publishLocal &&
			popd
		else
			echo "$r already exists in $DIR/$r"
		fi
	done &&
	popd
fi
