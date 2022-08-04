# aom-av1-psy_TermuxBuild
An automated script to build [aom-av1-psy full_build-alpha-4](https://github.com/BlueSwordM/aom-av1-psy/tree/full_build-alpha-4) in Termux (Android), with possible [LibVMAF](https://github.com/Netflix/vmaf/tree/master/libvmaf) support.\
Under the hood, it will also compile [cpu_features](https://github.com/google/cpu_features).

**Make sure you are connected to the Internet until the script is completely finished!**

### Run the script
Once downloaded, run `chmod +x build.sh` (the script should not be in `~/storage/*` ! ).\
Then simply `./build.sh`. It will create a folder for each GitHub repo cloned.\
To build aom-av1-psy with LibVMAF, just add the arg "--enable-libvmaf": `./build.sh --enable-livmaf`.
The default behavior is to **only** copy `aomenc` to `$PREFIX/bin`, if you want to install every aom-tools, add the arg `--install-all`.\
The VMAF models will be located to `./vmaf/model/*.json`. They are needed when using VMAF tunes with `aomenc`: `--vmaf-model-path`.

### Automatisation to its max
Don't want to do anything but just copy-paste ? Here you go:\
`echo y | pkg i wget && wget https://raw.githubusercontent.com/T-3B/aom-av1-psy_TermuxBuild/main/build.sh && chmod +x build.sh && ./build.sh --enable-libvmaf`\
Again, if you don't want LibVMAF just remove "--enable-libvmaf"; and if you want to install every aom-tools, add the arg `--install-all`.\
The VMAF models will be located to `~/vmaf/model/*.json`. They are needed when using VMAF tunes with `aomenc`: `--vmaf-model-path`.



Happy encoding!
