#!/data/data/com.termux/files/usr/bin/bash

### This script will download and build aom-av1-lavish_Endless_Merging, with possibly
### --enable-libvmaf and --enable-butteraugli. One folder will be created to clone the repo, and a python script will be downloaded.
### Only the encoder (aomenc) will be installed, no decoder nor tools.
### This script won't update things, just install. So if you want to "update",
### first change the current directory (or delete old files/folders), and the script will override existing binaries (if any).

errorBuilding() {
	echo -e "\033[0;31m${1}\033[0m"
	termux-wake-unlock
	exit 1
}

aomCompile() {
	local match cmd percent="$(tail -1 cmd.log | cut -c 2-4)"
	echo a > err.log
	until [ -z "$(cat err.log)" ]
	do
		make VERBOSE=1 2> err.log | awk -v a="$percent" '/%/ {if (substr($0,2,3)+0 > a+0) {a=substr($0,2,3); printf "%s\r",substr($0,1,6)} next} {print > "cmd.log"}'
		cmd="$(grep -e bin/cc -e bin/c++ cmd.log | tail -1)"
		percent="$(grep % cmd.log | tail -1 | cut -c 2-4)"
		if grep cpu-features.h err.log > /dev/null
		then
			match=/data/data/com.termux/files/usr/bin/cc
			cmd="$match -I/data/data/com.termux/files/usr/include/ndk_compat ${cmd##*$match}"
			eval $cmd
		elif grep android_getCpuFeatures err.log > /dev/null
		then
			match=libaom.a
			eval "${cmd%%${match}*} /data/data/com.termux/files/usr/lib/libndk_compat.a $match ${cmd##*$match}"
		fi
	done
}

termux-wake-lock
echo 'You can now let the program run in background.'
flags='-O3 -flto -static'
pkg upgrade -y &> /dev/null
pkg i -y libcpufeatures perl cmake doxygen yasm ndk-multilib git wget &> /dev/null

aomArgs='-DENABLE_TOOLS=0 -DCONFIG_AV1_DECODER=0 -DENABLE_DOCS=0 -DENABLE_TESTS=0'
if [ "$1" = '--enable-libvmaf' ] || [ "$2" = '--enable-libvmaf' ]
then
	aomArgs+=' -DCONFIG_TUNE_VMAF=1'
	pkg i -y libvmaf-static &> /dev/null
fi

if [ "$1" = '--enable-butteraugli' ] || [ "$2" = '--enable-butteraugli' ]
then
  aomArgs+=' -DCONFIG_TUNE_BUTTERAUGLI=1'
  pkg i -y libjxl-static &> /dev/null
fi

echo 'Building aom-av1-lavish_Endless_Merging...'
git clone https://github.com/Clybius/aom-av1-lavish -b Endless_Merging aom-av1-lavish_em &> /dev/null || errorBuilding 'Could not clone aom-av1-lavish, check your Internet connection.'
wget https://raw.githubusercontent.com/Lzhiyong/termux-ndk/master/patches/align_fix.py &> /dev/null  || errorBuilding 'Could not get a python script, check your Internet connection.'
echo 'You can now disconnect your device from the Internet.'
mkdir aom-av1-lavish_em/mybuild
cd aom-av1-lavish_em/mybuild
cmake .. -DCMAKE_BUILD_TYPE=Release $aomArgs -DCMAKE_C_FLAGS="$flags" -DCMAKE_CXX_FLAGS="$flags" -DBUILD_SHARED_LIBS=0 --install-prefix $PREFIX &> /dev/null || errorBuilding "Could not compile aom-av1-psy."
make -kj$(nproc) 2> /dev/null | awk '/%/ {printf "%s\r",substr($0,1,6); print > "cmd.log"}'
aomCompile
[ -f aomenc ] || errorBuilding 'Could not compile aom-av1-lavish.'
find . -type f -executable -not -path "./CMakeFiles/*" -exec python3 ../../align_fix.py {} &> /dev/null \; -exec strip {} \;
make install &> /dev/null
cd ../..
# rm -rf align_fix.py aom-av1-lavish_em
echo -e '\033[0;32mAom-av1-lavish installed successfully! Congratulations!\033[0m'
termux-toast -g bottom -b green -c black 'Aom-av1-lavish installed successfully!' &> /dev/null
termux-wake-unlock
