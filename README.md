unplist - bad XML begone!
---

_unplist_ dumps plist data to a boring, normalized text form. 
I built it to take spelunking through plist files. 

It's output differs from that produced by PlistBuddy in that it's designed
to be more *greppable*.

    $ ./unplist < BuildManifest.plist |head -5
    ManifestVersion=0
    ProductBuildVersion=12B411
    ProductVersion=8.1
    BuildIdentities[0].ApBoardID=0x02

Input can either be via file or piped from stdin.

### Options (hardly any)

    usage: [-v] -p PATH_TO_PLIST

where -v will dump the hex for NSData objects, without just shows 
the first 8 bytes + length info.


