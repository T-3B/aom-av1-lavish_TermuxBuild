# aom-av1-psy_TermuxBuild
An automated script to build aom-av1-psy full_build-alpha-4 in Termux, with possible LibVMAF support.

### Run the script
Once downloaded, run `chmod +x build.sh` (the script should not be in `~/storage/*` ! ).
Then simply `./build.sh`. It will create a folder for each GitHub repo cloned.
To build aom-av1-psy with LibVMAF, just add the arg "--enable-libvmaf" : `./build.sh --enable-livmaf`.

### Automatisation to its max
Don't want to do anything but just copy-paste ? Here you go :
`echo y | pkg i wget && wget https://raw.githubusercontent.com/T-3B/aom-av1-psy_TermuxBuild/main/build.sh && chmod +x build.sh && ./build.sh --enable-libvmaf`
Again, if you don't want LibVMAF just remove "--enable-libvmaf".
