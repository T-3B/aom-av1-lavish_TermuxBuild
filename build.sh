### This script will create and build aomenc-psy, with possibly
### --enable-libvmaf. One folder will be created for each cloned repo
### This script won't update things, just create. So if you want to update,
### first change the current directory (or delete old files)

aomCompile () {
  local match
  local cmd
  echo a > err.log
  until [ -z "$(cat err.log)" ]
  do
    make VERBOSE=1 2> err.log | tee cmd.log | grep %
    cmd="$(grep -e bin/cc -e bin/c++ cmd.log | tail -1)"
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
          eval $cmd 2> err.log
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

FLAGS="-O3 -flto -mtune=$(llc --version | grep "Host CPU:" | tail -c +13) --target=$(llc --version | grep "Default target:" | tail -c +19)"
baseDir="$PWD"
echo y | pkg i perl cmake doxygen yasm ndk-multilib git wget
git clone https://github.com/google/cpu_features cpu_features
mkdir cpu_features/mybuild
cd cpu_features/mybuild
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS="$FLAGS" -DCMAKE_CXX_FLAGS="$FLAGS" --install-prefix "$PREFIX"
cmake --build . -- -j$(nproc)
make install
echo -e "\n\033[0;32mCPU-Features installed correctly !\033[0m\n"
cd "$baseDir"
if [ "$1" = "--enable-libvmaf" ]
then
  cmakeArgs+="-DCONFIG_TUNE_VMAF=1"
  echo y | pkg i ninja
  pip install meson
  git clone https://github.com/Netflix/vmaf vmaf
  mkdir vmaf/libvmaf/mybuild
  cd vmaf/libvmaf/mybuild
  meson .. --buildtype=release --default-library=both -Db_lto=true -Dc_args="$FLAGS" -Dcpp_args="$FLAGS" -Dprefix="$PREFIX"
  ninja
  ninja install
  cd "$baseDir"
  echo -e "\n\033[0;32mLibVMAF installed correctly !\033[0m\n"
fi

git clone https://github.com/BlueSwordM/aom-av1-psy -b full_build-alpha-4 aom-av1-psy-ba4
mkdir aom-av1-psy-ba4/mybuild
cd aom-av1-psy-ba4/mybuild
cmake .. -DCMAKE_BUILD_TYPE=Release $cmakeArgs -DCMAKE_C_FLAGS="$FLAGS" -DCMAKE_CXX_FLAGS="$FLAGS" --install-prefix "$PREFIX"
aomCompile
wget https://raw.githubusercontent.com/Lzhiyong/termux-ndk/master/patches/align_fix.py
find . -type f -executable -not -path "./CMakeFiles/*" -exec python3 align_fix.py {} \;
make install
echo -e "\n\033[0;32mAom-av1-psy installed correctly ! Congratulations !\033[0m\n"
