#!/data/data/com.termux/files/usr/bin/bash

### This script will download and build aom-av1-lavish_Endless_Merging, with possibly
### --enable-libvmaf and --enable-butteraugli. One folder will be created to clone the repo, and a python script will be downloaded.
### Only the encoder (aomenc) will be installed, no decoder nor tools.
### This script won't update things, just install. So if you want to "update",
### first change the current directory (or delete old files/folders), and the script will override existing binaries (if any).

set -e


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
echo 'You can now let the program run in background.' && sleep 1
flags='-O3 -flto -static'
pkg upgrade -y
pkg i -y libcpufeatures perl cmake doxygen yasm ndk-multilib-native-static git wget binutils-bin

aomArgs='-DENABLE_TOOLS=0 -DCONFIG_AV1_DECODER=0 -DENABLE_DOCS=0 -DENABLE_TESTS=0'
if [ "$1" = --enable-libvmaf ] || [ "$2" = --enable-libvmaf ]
then
	echo 'Will build aomenc with libvmaf.' && sleep 1
	aomArgs+=' -DCONFIG_TUNE_VMAF=1'
	pkg i -y libvmaf-static
fi

if [ "$1" = --enable-butteraugli ] || [ "$2" = --enable-butteraugli ]
then
	echo 'Will build aomenc with butteraugli.' && sleep 1
  aomArgs+=' -DCONFIG_TUNE_BUTTERAUGLI=1'
  pkg i -y libjxl-static
fi

echo 'Building aom-av1-lavish_Endless_Merging...'
git clone https://github.com/Clybius/aom-av1-lavish -b Endless_Merging aom-av1-lavish_em
wget -4 https://raw.githubusercontent.com/Lzhiyong/termux-ndk/master/patches/align_fix.py
echo 'You can now disconnect your device from the Internet.' && sleep 1
mkdir aom-av1-lavish_em/mybuild
cd aom-av1-lavish_em/mybuild
cmake .. -DCMAKE_BUILD_TYPE=Release $aomArgs -DCMAKE_C_FLAGS="$flags" -DCMAKE_CXX_FLAGS="$flags" -DBUILD_SHARED_LIBS=0 --install-prefix $PREFIX
make -kj$(nproc)
aomCompile
[ -f aomenc ] || { echo 'Could not compile aom-av1-lavish.'; exit 1;}
find . -type f -executable -not -path "./CMakeFiles/*" -exec python3 ../../align_fix.py {}\; -exec strip {} \;
make install
cd ../..
rm -rf align_fix.py aom-av1-lavish_em
echo -e '\033[0;32mAom-av1-lavish installed successfully! Congratulations!\033[0m'
termux-toast -g bottom -b green -c black 'Aom-av1-lavish installed successfully!' &> /dev/null
termux-wake-unlock
