#!/data/data/com.termux/files/usr/bin/bash

### This script will download and build aom-av1-psy_build-alpha4, with possibly
### --enable-libvmaf. One folder will be created for each cloned repo.
### Execute with --install-all if you want to install every aom-tools (otherwise only aomenc will be installed).
### This script won't update things, just install. So if you want to "update",
### first change the current directory (or delete old files/folders), and the script will override existing binaries (if any).

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
FLAGS="-static -O3 -flto --target=$(llc --version | grep "Default target:" | tail -c +19) -mtune=$(llc --version | grep "Host CPU:" | tail -c +13)"
pkg up -y &> /dev/null
pkg i -y perl cmake doxygen yasm ndk-multilib git wget &> /dev/null

echo -n "Compiling CPU-Features..."
git clone https://github.com/google/cpu_features cpu_features &> /dev/null
wget https://raw.githubusercontent.com/Lzhiyong/termux-ndk/master/patches/align_fix.py &> /dev/null
mkdir cpu_features/mybuild
cd cpu_features/mybuild
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS="$FLAGS" -DCMAKE_CXX_FLAGS="$FLAGS" -DBUILD_SHARED_LIBS=OFF --install-prefix $PREFIX &> /dev/null
make -j$(nproc) &> /dev/null
find . -type f -executable -not -path "./CMakeFiles/*" -exec python3 ../../align_fix.py {} &> /dev/null \; -exec strip {} \;
make install &> /dev/null
cd ../..
echo -e "\033[0;32m Installed successfully!\033[0m"

[ "$1" = "--install-all" ] || [ "$2" = "--install-all" ] || aomArgs="-DENABLE_TOOLS=0 -DCONFIG_AV1_DECODER=0 -DENABLE_DOCS=0 -DENABLE_TESTS=0 -DENABLE_EXAMPLES=0"
if [ "$1" = "--enable-libvmaf" ] || [ "$2" = "--enable-libvmaf" ]
then
	aomArgs+="-DCONFIG_TUNE_VMAF=1"
	pkg i -y ninja &> /dev/null
	pip install -U meson &> /dev/null
	echo -n "Compiling LibVMAF..."
	git clone https://github.com/Netflix/vmaf vmaf &> /dev/null
	mkdir vmaf/libvmaf/mybuild
	cd vmaf/libvmaf/mybuild
	meson .. --buildtype=release --default-library=static --prefer-static --strip -Db_lto=true -Dc_args="$FLAGS" -Dcpp_args="$FLAGS" -Dprefix=$PREFIX &> /dev/null
	ninja install &> /dev/null
	cd ../../..
	mv -f vmaf/model $PREFIX/share
	echo -e '\033[0;32m Installed successfully!\033[0m The VMAF models are located here : `$PREFIX/share/model/*`.'
fi

echo "Compiling aom-av1-psy-build_alpha4..."
git clone https://github.com/BlueSwordM/aom-av1-psy -b full_build-alpha-4 aom-av1-psy-ba4 &> /dev/null
echo "You can now disconnect your device from the Internet."
mkdir aom-av1-psy-ba4/mybuild
cd aom-av1-psy-ba4/mybuild
cmake .. -DCMAKE_BUILD_TYPE=Release $aomArgs -DCMAKE_C_FLAGS="$FLAGS" -DCMAKE_CXX_FLAGS="$FLAGS" -DBUILD_SHARED_LIBS=0 --install-prefix $PREFIX &> /dev/null
make -j$(nproc) -k 2> /dev/null | awk '/%/ {printf "%s\r",substr($0,1,6); print > "cmd.log"}'
aomCompile
find . -type f -executable -not -path "./CMakeFiles/*" -exec python3 ../../align_fix.py {} &> /dev/null \; -exec strip {} \;
make install &> /dev/null
cd ../..
rm -rf align_fix.py vmaf aom-av1-psy-ba4 cpu_features
echo -e "\033[0;32mAom-av1-psy installed successfully! Congratulations!\033[0m"
termux-toast -g bottom -b green -c black "Aom-av1-psy installed successfully!" &> /dev/null
termux-wake-unlock
