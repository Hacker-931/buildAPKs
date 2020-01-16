#!/usr/bin/env bash
# Copyright 2017-2020 (c) all rights reserved by S D Rausty 
# Adapted from https://github.com/fx-adi-lima/android-tutorials
#####################################################################
set -Eeuo pipefail
shopt -s nullglob globstar

_SBOTRPERROR_() { # run on script error
	local RV="$?"
	echo $RV build.one.bash  
	printf "\\e[?25h\\e[1;7;38;5;0mbuildAPKs %s build.one.bash ERROR:  Signal %s received!  More information in \`%s/var/log/stnderr.%s.log\` file.\\e[0m\\n" "${0##*/}" "$RV" "$RDR" "$JID" 
	[ "$RV" = 255 ] && printf "\\e[?25h\\e[1;7;38;5;0mOn Signal 255 try running %s again if the error includes R.java and similar; This error might have been corrected by clean up.  More information in \`%s/var/log/stnderr.%s.log\` file.\\e[0m\\n" "${0##*/}" "$RDR" "$JID" 
 	_CLEANUP_
	exit 160
}

_SBOTRPEXIT_() { # run on exit
	local RV="$?"
	[ "$RV" != 0 ] && [ "$RV" != 224 ] && printf "\\e[?25h\\e[1;7;38;5;0mbuildAPKs signal %s received by %s in %s by build.one.bash.  More information in \`%s/var/log/stnderr.%s.log\` file.\\n\\n" "$RV" "${0##*/}" "$PWD" "$RDR" "$JID" && (printf "%s\\e[0m\\n" "Running: VAR=\"\$(grep -C 2 -ie error -ie errors \"$RDR/var/log/stnderr.$JID.log\")\" && VAR=\"\$(grep -v \\-\\- <<< \$VAR)\" && head <<< \$VAR && tail <<< \$VAR ") && VAR="$(grep -C 2 -ie error -ie errors "$RDR/var/log/stnderr.$JID.log")" && VAR="$(grep -v \\-\\- <<< $VAR)" && head <<< $VAR && tail <<< $VAR && printf "\\n\\n" 
	[ "$RV" = 223 ] && printf "\\e[?25h\\e[1;7;38;5;0mSignal 223 generated in %s; Try running %s again; This error can be resolved by running %s in a directory that has an \`AndroidManifest.xml\` file.  More information in \`stnderr*.log\` files.\\n\\nRunning \`ls\`:\\e[0m\\n" "$PWD" "${0##*/}" "${0##*/}" && ls
	[ "$RV" = 224 ] && printf "\\e[?25h\\e[1;7;38;5;0mSignal 224 generated in %s;  Cannot run in folder %s; %s exiting...\\e[0m\\n" "$PWD" "$PWD" "${0##*/} build.one.bash"
	[ "$RV" != 224 ] &&  _CLEANUP_
	printf "\\e[?25h\\e[0m"
	set +Eeuo pipefail 
	exit 0
}

_SBOTRPSIGNAL_() { # run on signal
	printf "\\e[?25h\\e[1;7;38;5;0mbuildAPKs %s WARNING:  Signal %s received by build.one.bash!\\e[0m\\n" "${0##*/}" "$?" 
 	exit 161 
}

_SBOTRPQUIT_() { # run on quit
	printf "\\e[?25h\\e[1;7;38;5;0mbuildAPKs %s WARNING:  Quit signal %s received by build.one.bash!\\e[0m\\n" "${0##*/}" "$?"
 	_CLEANUP_
 	exit 162 
}

trap '_SBOTRPERROR_ $LINENO $BASH_COMMAND $?' ERR 
trap _SBOTRPEXIT_ EXIT
trap _SBOTRPSIGNAL_ HUP INT TERM 
trap _SBOTRPQUIT_ QUIT 

_CLEANUP_ () {
	sleep 0.032 # add device latency support 
	printf "\\e[1;38;5;151m%s\\n\\e[0m" "Completing tasks..."
	rm -f *-debug.key 
 	rm -rf ./bin ./gen ./obj 
	find . -name R.java -exec rm -f { } \;
	printf "\\e[1;38;5;151mCompleted tasks in %s\\n\\n\\e[0m" "$PWD"
}
# if root directory is undefined, define the root directory as ~/buildAPKs 
[ -z "${RDR:-}" ] && RDR="$HOME/buildAPKs"
. "$RDR"/scripts/bash/shlibs/buildAPKs/copy.apk.bash
# if working directory is $HOME or buildAPKs exit 
[ "$PWD" = "$HOME" ] || [ "${PWD##*/}" = buildAPKs ] && exit 224
printf "\\e[0m\\n\\e[1;38;5;116mBeginning build in %s\\n\\e[0m" "$PWD"
# if variables are undefined, then define these variables
[ -z "${DAY:-}" ] && DAY="$(date +%Y%m%d)"
[ -z "${2:-}" ] && JDR="$PWD"
[ -z "${JID:-}" ] && JID="${PWD##*/}" # https://www.tldp.org/LDP/abs/html/parameter-substitution.html 
[ -z "${NUM:-}" ] && NUM=""
# if it does not exist, then create it 
[ ! -e "./assets" ] && mkdir -p ./assets
[ ! -e "./bin" ] && mkdir -p ./bin
[ ! -e "./gen" ] && mkdir -p ./gen
[ ! -e "./obj" ] && mkdir -p ./obj
[ ! -e "./res" ] && mkdir -p ./res
LIBAU="$(awk 'NR==1' "$RDR/.conf/LIBAUTH")" # load true/false from $RDR/.conf/LIBAUTH file, see the LIBAUTH file for more information to enable loading of artifacts and libraries into the build process. 
if [[ "$LIBAU" == true ]]
then # load artifacts and libraries into the build process.
	printf "\\e[1;34m%s" "Loading artifacts and libraries into the compilation:  "
	BOOTCLASSPATH=""
	SYSJCLASSPATH=""
	JSJCLASSPATH=""
	DIRLIST=""
	LIBDIRPATH=("$JDR/../../../lib" "$JDR/../../../libraries" "$JDR/../../../library" "$JDR/../../../libs" "$JDR/../../lib" "$JDR/../../libraries" "$JDR/../../library" "$JDR/../../libs" "$JDR/../lib" "$JDR/../libraries" "$JDR/../library" "$JDR/../libs" "$JDR/lib" "$JDR/libraries" "$JDR/library" "$JDR/libs" "$RDR/var/cache/lib" "/system") # modify array LIBDIRPATH to suit the projects artifact needs.  
	for LIBDIR in ${LIBDIRPATH[@]} # every element in array LIBDIRPATH 
	do	# directory path check
	 	if [[ -d "$LIBDIR" ]] # library directory exists
		then	# search directory for artifacts and libraries
			DIRLIS="$(find -L "$LIBDIR" -type f -name "*.aar" -or -type f -name "*.jar" -or -type f -name "*.vdex" 2>/dev/null)"||:
			DIRLIST="$DIRLIST $DIRLIS"
			NUMIA=$(wc -l <<< $DIRLIST)
	 		if [[ $DIRLIS == "" ]] # nothing was found 
			then	# adjust ` wc -l ` count to zero
				NUMIA=0
			fi
			printf "\\e[1;34m%s" "Adding $NUMIA artifacts and libraries from directory "$LIBDIR" into build "${PWD##*/}":  "
		fi
	done
	for LIB in $DIRLIST
	do
		BOOTCLASSPATH=${LIB}:${BOOTCLASSPATH};
		SYSJCLASSPATH="-I $LIB $SYSJCLASSPATH"
		JSJCLASSPATH="-j $LIB $SYSJCLASSPATH"
	done
	BOOTCLASSPATH=${BOOTCLASSPATH%%:}
 	AAPTENT=" $SYSJCLASSPATH " 
	[ -e "./libs/res-appcompat" ] && AAPTENT=" -S libs/res-appcompat $AAPTENT"
	[ -e "./libs/res-cardview" ] && AAPTENT=" -S libs/res-cardview $AAPTENT"
	[ -e "./libs/res-design" ] && AAPTENT=" -S libs/res-design $AAPTENT"
	[ -e "./libs/res-recyclerview" ] && AAPTENT=" -S libs/res-recyclerview $AAPTENT"
 	AAPTENT=" --auto-add-overlay $SYSJCLASSPATH " # add 500K 
 	ECJENT=" -classpath $BOOTCLASSPATH "
	printf "\\e[1;32m\\bDONE\\e[0m\\n"
else # do not load artifacts and libraries into the build process.
 	AAPTENT=""
 	ECJENT=""
	JSJCLASSPATH=""
fi
NOW=$(date +%s)
PKGNAM="$(grep -o "package=.*" AndroidManifest.xml | cut -d\" -f2)"
PKGNAME="$PKGNAM.$NOW"
COMMANDIF="$(command -v getprop)" ||:
if [[ "$COMMANDIF" = "" ]]
then
	MSDKVERSION="14"
 	PSYSLOCAL="en"
	TSDKVERSION="23"
else
	MSDKVERSION="$(getprop ro.build.version.min_supported_target_sdk)" || printf "%s" "signal ro.build.version.min_supported_target_sdk ${0##*/} build.one.bash generated; Continuing...  " && MSDKVERSION="14"
 	PSYSLOCAL="$(getprop persist.sys.locale|awk -F- '{print $1}')" || printf "%s" "Signal persist.sys.locale ${0##*/} build.one.bash generated; Continuing...  " && PSYSLOCAL="en"
	TSDKVERSION="$(getprop ro.build.version.sdk)" || printf "%s" "Signal ro.build.version.sdk ${0##*/} build.one.bash generated; Continuing...  " && TSDKVERSION="23"
fi
sed -i "s/minSdkVersion\=\"[0-9]\"/minSdkVersion\=\"$MSDKVERSION\"/g" AndroidManifest.xml 
sed -i "s/minSdkVersion\=\"[0-9][0-9]\"/minSdkVersion\=\"$MSDKVERSION\"/g" AndroidManifest.xml 
sed -i "s/targetSdkVersion\=\"[0-9]\"/targetSdkVersion\=\"$TSDKVERSION\"/g" AndroidManifest.xml 
sed -i "s/targetSdkVersion\=\"[0-9][0-9]\"/targetSdkVersion\=\"$TSDKVERSION\"/g" AndroidManifest.xml 
printf "\\e[1;38;5;115m%s\\n\\e[0m" "aapt: started..."
aapt package -f \
 	--min-sdk-version "$MSDKVERSION" --target-sdk-version "$TSDKVERSION" --version-code "$NOW" --version-name "$PKGNAM" -c "$PSYSLOCAL" \
	-M AndroidManifest.xml \
 	$AAPTENT \
	-J gen \
	-S res
printf "\\e[1;38;5;148m%s;  \\e[1;38;5;114m%s\\n\\e[0m" "aapt: done" "ecj: begun..."
ecj $ECJENT -d ./obj -sourcepath . $(find . -type f -name "*.java") 
printf "\\e[1;38;5;149m%s;  \\e[1;38;5;113m%s\\n\\e[0m" "ecj: done" "dx: started..."
dx --dex --output=bin/classes.dex obj
printf "\\e[1;38;5;148m%s;  \\e[1;38;5;112m%s\\n\\e[0m" "dx: done" "Making $PKGNAM.apk..."
aapt package -f \
 	--min-sdk-version "$MSDKVERSION" --target-sdk-version "$TSDKVERSION" \
	-M AndroidManifest.xml \
 	$JSJCLASSPATH \
	-S res \
	-A assets \
	-F bin/"$PKGNAM".apk 
printf "\\e[1;38;5;113m%s\\e[1;38;5;107m\\n" "Adding classes.dex to $PKGNAM.apk..."
cd bin 
aapt add -f "$PKGNAM.apk" classes.dex 
printf "\\e[1;38;5;114m%s\\e[1;38;5;108m\\n" "Signing $PKGNAM.apk..."
apksigner ../"$PKGNAM-debug.key" "$PKGNAM.apk" ../"$PKGNAM.apk"
cd ..
_COPYAPK_ || printf "%s\\n" "Unable to copy APK file ${0##*/} build.one.bash; Continuing..." 
printf "\\e[?25h\\e[1;7;38;5;34mShare %s everwhere%s!\\e[0m\\n" "https://wiki.termux.com/wiki/Development" "🌎🌍🌏🌐"
# build.one.bash EOF
