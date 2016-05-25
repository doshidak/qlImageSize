## qlImageSize

This is a fork of Nyx0uf's  [qlImageSize](https://github.com/Nyx0uf/qlImageSize). There are only minor visual modifications made to `qlImageSize` and no modifications made to `mdImageSize`.

To be consistent with other files in OS X, the extension label in the thumbnail was changed into all uppercase:

Before | After
--- | ---
![before](http://i53.photobucket.com/albums/g67/xtreamsoulx/gh_qlimgsize/thumb_before_zps4svt9dfp.png) | ![after](http://i53.photobucket.com/albums/g67/xtreamsoulx/gh_qlimgsize/thumb_after_zpsp30jytvw.png)

Additionally, the title of the QuickLook window was changed to be more consistent with the information style in the *Get Info* panel:

![title](http://i53.photobucket.com/albums/g67/xtreamsoulx/gh_qlimgsize/preview_title_zps3ue4ksw6.png)

### Installation

1. Open `qlImageSize.xcodeproj` and compile.
2. Move `qlImageSize.qlgenerator` to `~/Library/QuickLook`.
3. Run `qlmanage -r` in Terminal.
4. Optionally, run `killall Finder` to see immediate changes.
5. ???
6. Profit!

### License

**qlImageSize** is released under the *Simplified BSD license*.
