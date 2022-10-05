#!/data/data/com.termux/files/usr/bin/bash

### This script will download and build aom-av1-psy_build-alpha4, with possibly
### --enable-libvmaf. One folder will be created for each cloned repo (+ a python script).
### Execute with --install-all if you want to install every aom-tools (otherwise only aomenc will be installed).
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
		else
			if grep lpthread <<< $cmd > /dev/null
			then
				match=-lpthread
				cmd="${cmd%%${match}*} ${cmd##*$match}"
				grep lpthread err.log > /dev/null && eval $cmd 2>> err.log
			fi
			if grep android_getCpuFeatures err.log > /dev/null
			then
				match=libaom.a
				eval "${cmd%%${match}*} /data/data/com.termux/files/usr/lib/libndk_compat.a $match ${cmd##*$match}"
			fi
		fi
	done
}

termux-wake-lock
flags="-O3 -flto" #meson does not support -static in cflags/cppflags
pkg upgrade -y &> /dev/null
pkg i -y perl cmake doxygen yasm ndk-multilib git wget &> /dev/null

echo -n "Building CPU-Features..."
git clone https://github.com/google/cpu_features cpu_features &> /dev/null || errorBuilding "Could not clone cpu_features, check your Internet connection."
wget https://raw.githubusercontent.com/Lzhiyong/termux-ndk/master/patches/align_fix.py &> /dev/null  || errorBuilding "Could not get a python script, check your Internet connection."
mkdir cpu_features/mybuild
cd cpu_features/mybuild
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS="-static $flags" -DCMAKE_CXX_FLAGS="-static $flags" -DBUILD_SHARED_LIBS=0 --install-prefix $PREFIX &> /dev/null
make -j$(nproc) &> /dev/null || errorBuilding "Could not compile cpu_features."
find . -type f -executable -not -path "./CMakeFiles/*" -exec python3 ../../align_fix.py {} &> /dev/null \; -exec strip {} \;
make install &> /dev/null
cd ../..
echo -e "\033[0;32m Installed successfully!\033[0m"

[ "$1" = "--install-all" ] || [ "$2" = "--install-all" ] || aomArgs="-DENABLE_TOOLS=0 -DCONFIG_AV1_DECODER=0 -DENABLE_DOCS=0 -DENABLE_TESTS=0 -DENABLE_EXAMPLES=0"
if [ "$1" = "--enable-libvmaf" ] || [ "$2" = "--enable-libvmaf" ]
then
	aomArgs+=" -DCONFIG_TUNE_VMAF=1"
	pkg i -y ninja &> /dev/null
	pip install -U meson &> /dev/null
	echo -n "Building LibVMAF..."
	git clone https://github.com/Netflix/vmaf vmaf &> /dev/null || errorBuilding "Could not clone libvmaf, check your Internet connection."
	mkdir vmaf/libvmaf/mybuild
	cd vmaf/libvmaf/mybuild
	meson .. --buildtype=release --default-library=static --prefer-static --strip -Db_lto=true -Dc_args="$flags" -Dcpp_args="$flags" -Dprefix=$PREFIX &> /dev/null
	ninja install &> /dev/null || errorBuilding "Could not compile libvmaf."
	cd ../../..
	rm -rf $PREFIX/share/model #remove old vmaf models
	mv -f vmaf/model $PREFIX/share
	echo -e '\033[0;32m Installed successfully!\033[0m\nThe VMAF models are located here : `$PREFIX/share/model/*`.'
fi

echo "Building aom-av1-psy_Endless-Possibility..."
git clone https://github.com/BlueSwordM/aom-av1-psy -b Endless_Possibility aom-av1-psy_ep &> /dev/null || errorBuilding "Could not clone aom-av1-psy, check your Internet connection."
echo "You can now disconnect your device from the Internet."
mkdir aom-av1-psy_ep/mybuild
cd aom-av1-psy_ep/mybuild
cmake .. -DCMAKE_BUILD_TYPE=Release $aomArgs -DCMAKE_C_FLAGS="-static $flags" -DCMAKE_CXX_FLAGS="-static $flags" -DBUILD_SHARED_LIBS=0 --install-prefix $PREFIX &> /dev/null || errorBuilding "Could not compile aom-av1-psy."
make -j$(nproc) -k 2> /dev/null | awk '/%/ {printf "%s\r",substr($0,1,6); print > "cmd.log"}'
aomCompile
[ -f aomenc ] || errorBuilding "Could not compile aom-av1-psy."
find . -type f -executable -not -path "./CMakeFiles/*" -exec python3 ../../align_fix.py {} &> /dev/null \; -exec strip {} \;
make install &> /dev/null
cd ../..
# rm -rf align_fix.py vmaf aom-av1-psy_ep cpu_features
echo -e "\033[0;32mAom-av1-psy installed successfully! Congratulations!\033[0m"
termux-toast -g bottom -b green -c black "Aom-av1-psy installed successfully!" &> /dev/null
termux-wake-unlock
