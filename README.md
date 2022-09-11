# aom-av1-psy_TermuxBuild

An automated script to build [aom-av1-psy Ebdless_Possibility](https://github.com/BlueSwordM/aom-av1-psy/tree/Endless_Possibility) in Termux (Android), with possible [LibVMAF](https://github.com/Netflix/vmaf/tree/master/libvmaf) support.\
Under the hood, it will also compile [cpu_features](https://github.com/google/cpu_features).

**Make sure you are connected to the Internet until the script says you're done with it!**\
The script can run in background without any issue.

### Run the script
Once downloaded, run `chmod +x build.sh` (the script should not be in `~/storage/*`! ).\
Then simply `./build.sh`. It will create a temporary folder for each GitHub repo cloned (all folders and files are deleted when the installation is done).\
To build aom-av1-psy with LibVMAF, just add the arg "--enable-libvmaf": `./build.sh --enable-livmaf`.
The default behavior is to **only** compile (and install) `aomenc`, if you want to install every aom-tools, add the arg `--install-all` to the script.\
The VMAF models will be located to `$PREFIX/share/model/*`. They are needed when using VMAF tunes with `aomenc`: `--vmaf-model-path`.

### Automatisation to its max
Don't want to do anything but just copy-paste ? Here you go:\
`pkg i -y wget && wget https://raw.githubusercontent.com/T-3B/aom-av1-psy_TermuxBuild/main/build.sh && chmod +x build.sh && ./build.sh --enable-libvmaf`\
I recommend using vmaf tunes when using aomenc, but you're the boss ≧◡≦



Happy encoding!
