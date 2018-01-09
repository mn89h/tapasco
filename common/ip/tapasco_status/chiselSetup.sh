#!/bin/bash
DIR=$PWD/chisel3
URL=https://github.com/freechipsproject
REPOS="firrtl firrtl-interpreter chisel3 chisel-testers"
REPO_URLS=`for r in $REPOS; do echo $URL/$(echo $r | cut -d: -f1).git; done`

if [ "$1" = "clean" ]; then
	echo "Removing Chisel3 dependencies in $DIR ..."
	rm -rf $DIR
else
	echo "Installing Chisel3 dependencies in $DIR ..."
	mkdir -p $DIR
	pushd $DIR
	for r in $REPOS; do
		if [ ! -e $r ]; then
			R=`echo $r | cut -d: -f1`
			V=`echo $r | cut -d: -s -f2`
			C=${V:+"-b $V"}
			echo "$R $V $C $URL/$R.git"
			if git clone "$URL/$R.git" $C; then
				pushd $R
				if sbt publishLocal; then
					popd
				else
					echo "could not build $r - check log" >&2
					exit 1
				fi
			else
				echo "could not clone $URL/$r.git - check log" >&2
				exit 1
			fi
			echo "================================================"
			echo "$R finished."
			echo "================================================"
		else
			echo "$r already exists in $DIR/$r"
		fi
		if [[ $? -ne 0 ]]; then exit 1; fi
	done
	popd
fi
