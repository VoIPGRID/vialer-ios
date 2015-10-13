#PJSIP for Vialer

We are using the Gossip wrapper a bit different then currently available on github.

Sources used are:
* https://github.com/chakrit/gossip
* https://github.com/troya2/gossip

But instead of including the project in our project, we link against the pre-build libGossip and have a copy of the Gossip sources in our project.

######The current situation:
1. The Vialer project compiles the *Gossip* (wrapper) sources, and links the produced object files to the application binary.
2. The Vialer project adds/overrides functionality using the categories implemented in Gossip+Extra.
3. The Vialer project links agains a precompiled libGossip (different architectures linked in different files) static libraries

> The libraries from 3. actually contains also compiled Gossip sources! (inspect with _otool -o libGossip7.a_)

######Updates:
I have added x86_64 support, so we can now also run the simulator iPhone 5s and upwards.
The intention is to replace the libGossip*.a files with our own build version (like I added the x86_64 version), and not include the linked Gossip binaries. Unfortunately doing so for the iPhone 5 simulator causes unexpected behaviours, so I suggest we investigate this after the first release.

######Building the x86_64 (stripped) libGossipx86_64.a:
in our Vialer project folder navigate to the folder `pjsip` this contains a little helper script `pjsip` to compile the pjsip libraries.

Build the libraries for x86 64 architecture
```Shell
./pjsip x86_64
```
Combine all static libs into one libGossipx86_64.a, taking all libs from lib/x86_64 folder
```Shell
libtool -o libGossipx86_64.a `find lib/x86_64/*.a -exec printf "%s " {} +`
```
This now includes only the pjsip library and not the Gossip files anymore!
Copy the libGossipx86_64.a next to the other existing libGossip files, and add it to the Vialer project in Xcode.

######Building the PJSIP sources:
First checkout the PJSIP sources from SVN
```Shell
svn co http://svn.pjsip.org/repos/pjproject/trunk/
```
**copy the config_site.h from Vialer to pjlib/include/pj/**
```Shell
cd trunk
cp ~/vialer/pjsip/config_site.h pjlib/include/pj/.
```
Build armv7 example (default architecture)
```Shell
./configure-iphone [add config options if wanted (for future)]
make dep && make clean && make
```
Magic to combine the output libs
```Shell
libtool -o libpjsip-armv7.a `find -name *armv7-apple-darwin_ios.a -exec printf '%s ' {} +`
```

Simulator builds (i386 & x86_64) need some extra
```Shell
export DEVPATH=/Applications/XCode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer
export CFLAGS="-O2 -m32 -mios-simulator-version-min=5.0"
export LDFLAGS="-O2 -m32 -mios-simulator-version-min=5.0"
ARCH="-arch i386" ./configure-iphone
```
Magic to combine the output libs
```Shell
libtool -o libpjsip-i386.a `find -name *i386-apple-darwin_ios.a -exec printf '%s ' {} +`
```

Now we could use those instead of the libGossip*.a files.

As a final touch, we can combine the architectures to one lib file.
