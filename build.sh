### This script will create and build aomenc-psy, with possibly
### --enable-libvmaf. One folder will be created for each cloned repo.
### Execute with --install-all if you want to install every aom-tools (default is to copy only aomenc to $PREFIX/bin)
### This script won't update things, just create. So if you want to update,
### first change the current directory (or delete old files)

aomCompile () {
  local match cmd condition percent=-1
  if [ "$1" = "--install-all" ] || [ "$2" = "--install-all" ]
  then
    condition='[ -z "$(cat err.log)" ]'
  else
    condition="[ -f aomenc ]"
  fi
  echo a > err.log
  until eval $condition
  do
    make VERBOSE=1 2> err.log | awk -v a="$percent" '/%/ {if (substr($0,2,3)+0 > a+0) {a=substr($0,2,3); printf "%s\r",substr($0,1,6)}} {print > "cmd.log"}'
    cmd="$(grep -e bin/cc -e bin/c++ cmd.log | tail -1)"
    percent="$(grep % cmd.log | tail -1 | cut -c 2-4)"
    if grep cpu-features.h err.log > /dev/null
    then
      match="/data/data/com.termux/files/usr/bin/cc"
      cmd="$match -I/data/data/com.termux/files/usr/include/ndk_compat ${cmd##*$match}"
      eval $cmd
    else
      if echo "$cmd" | grep lpthread > /dev/null
      then
        match="-lpthread"
        cmd="${cmd%%${match}*} ${cmd##*$match}"
        if grep lpthread err.log > /dev/null
        then
          eval $cmd 2>> err.log
        fi
      fi
      if grep android_getCpuFeatures err.log > /dev/null
      then
        match="libaom.a"
        eval "${cmd%%${match}*} /data/data/com.termux/files/usr/lib/libndk_compat.a $match ${cmd##*$match}"
      fi
    fi
  done
  rm err.log cmd.log
}

termux-wake-lock
FLAGS="-O3 -flto --target=$(llc --version | grep "Default target:" | tail -c +19) -mtune=$(llc --version | grep "Host CPU:" | tail -c +13)"
echo y | pkg up &> /dev/null
echo y | pkg i perl cmake doxygen yasm ndk-multilib git wget &> /dev/null

echo -n "Compiling CPU-Features..."
git clone https://github.com/google/cpu_features cpu_features &> /dev/null
wget https://raw.githubusercontent.com/Lzhiyong/termux-ndk/master/patches/align_fix.py &> /dev/null
mkdir cpu_features/mybuild
cd cpu_features/mybuild
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS="$FLAGS" -DCMAKE_CXX_FLAGS="$FLAGS" -DBUILD_SHARED_LIBS=OFF --install-prefix "$PREFIX" &> /dev/null
cmake --build . -- -j$(nproc) &> /dev/null
find . -type f -executable -not -path "./CMakeFiles/*" -exec python3 ../../align_fix.py {} &> /dev/null \; -exec strip -s {} \;
make install &> /dev/null
echo -e "\033[0;32m Installed successfully!\033[0m"
cd ../..
if [ "$1" = "--enable-libvmaf" ] || [ "$2" = "--enable-libvmaf" ]
then
  cmakeArgs+="-DCONFIG_TUNE_VMAF=1"
  echo y | pkg i ninja &> /dev/null
  pip install meson &> /dev/null
  echo -n "Compiling LibVMAF..."
  git clone https://github.com/Netflix/vmaf vmaf &> /dev/null
  mkdir vmaf/libvmaf/mybuild
  cd vmaf/libvmaf/mybuild
  meson .. --buildtype=release --default-library=static --prefer-static --strip -Db_lto=true -Dc_args="$FLAGS" -Dcpp_args="$FLAGS" -Dprefix="$PREFIX" &> /dev/null
  ninja &> /dev/null
  ninja install &> /dev/null
  echo -e "\033[0;32m Installed successfully!\033[0m"
  cd ../../..
fi

echo "Compiling aom-av1-psy-build_alpha4..."
git clone https://github.com/BlueSwordM/aom-av1-psy -b full_build-alpha-4 aom-av1-psy-ba4 &> /dev/null
echo "You can now disconnect your device from the Internet."
mkdir aom-av1-psy-ba4/mybuild &> /dev/null
cd aom-av1-psy-ba4/mybuild &> /dev/null
cmake .. -DCMAKE_BUILD_TYPE=Release $cmakeArgs -DCMAKE_C_FLAGS="$FLAGS" -DCMAKE_CXX_FLAGS="$FLAGS" -DBUILD_SHARED_LIBS=OFF --install-prefix "$PREFIX" &> /dev/null
aomCompile $1 $2
find . -type f -executable -not -path "./CMakeFiles/*" -exec python3 ../../align_fix.py {} &> /dev/null \; -exec strip -s {} \;
if [ "$1" = "--install-all" ] || [ "$2" = "--install-all" ]
then
  make install
else
  cp -f aomenc $PREFIX/bin
fi
echo -e "\033[0;32mAom-av1-psy installed successfully! Congratulations!\033[0m"
termux-toast -g bottom -b green -c black "Aom-av1-psy installed successfully!"
termux-wake-unlock
