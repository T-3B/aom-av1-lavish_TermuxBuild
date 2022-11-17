# aom-av1-lavish_Endless_Merging

An automated script to build [aom-av1-psy Endless_Merging](https://github.com/Clybius/aom-av1-lavish/tree/Endless_Merging) in Termux (Android), with possible [LibVMAF](https://github.com/Netflix/vmaf/tree/master/libvmaf) and [butteraugli](https://github.com/libjxl/libjxl) support.
The resulting binary will be static, optimized, stripped, and finally installed.

**Make sure you are connected to the Internet until the script says you're done with it!**\
The script can run in background without any issue.

### Run the script
Once downloaded, run `chmod +x build.sh` (the script should not be in `~/storage/*`! ).\
Then simply `./build.sh`. It will create folder to clone the repo.\
To build aom-av1-lavish with LibVMAF, just add the arg "--enable-libvmaf": `./build.sh --enable-livmaf`.\
To build aom-av1-lavish with butteraugli, just add the arg "--enable-butteraugli": `./build.sh --enable-butteraugli`.\
The script will **only** compile (and install) `aomenc`, but not the decoder (nor any tools).\
You have to download **manually** the [VMAF models](https://github.com/Netflix/vmaf/tree/master/model). They are needed when using VMAF tunes with `aomenc`: `--vmaf-model-path`.


### Automatisation to its max
Don't want to do anything but just copy-paste ? Here you go:\
`pkg i -y wget && wget https://raw.githubusercontent.com/T-3B/aom-av1-lavish_TermuxBuild/main/build.sh && chmod +x build.sh && ./build.sh --enable-libvmaf --enable-butteraugli`\
I recommend using VMAF tunes when using aomenc (you still need to download the VMAF models), but you're the boss ≧◡≦



Happy encoding!
