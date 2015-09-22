# asciidoctor-mathematical
Library wrapper of [Mathematical](https://github.com/gjtorikian/mathematical) for Asciidoctor

## Dependencies
make, gobject, glib, gio, gdk-pixbuf, gdk, cairo, pangocairo, libxml, bison, flex

For the runtime, the following ttf fonts should be installed: cmr10, cmmi10, cmex10 and cmsy10.
They are provided by the lyx-fonts package in fedora, and the ttf-lyx package in debian/ubuntu.

### OS X
Make sure you `brew install glib gdk-pixbuf cairo pango cmake`

You can install the font dependencies by using
```
cd ~/Library/Fonts
curl -LO http://mirrors.ctan.org/fonts/cm/ps-type1/bakoma/ttf/cmex10.ttf \
     -LO http://mirrors.ctan.org/fonts/cm/ps-type1/bakoma/ttf/cmmi10.ttf \
     -LO http://mirrors.ctan.org/fonts/cm/ps-type1/bakoma/ttf/cmr10.ttf \
     -LO http://mirrors.ctan.org/fonts/cm/ps-type1/bakoma/ttf/cmsy10.ttf \
     -LO http://mirrors.ctan.org/fonts/cm/ps-type1/bakoma/ttf/esint10.ttf \
     -LO http://mirrors.ctan.org/fonts/cm/ps-type1/bakoma/ttf/eufm10.ttf \
     -LO http://mirrors.ctan.org/fonts/cm/ps-type1/bakoma/ttf/msam10.ttf \
     -LO http://mirrors.ctan.org/fonts/cm/ps-type1/bakoma/ttf/msbm10.ttf
```
If you experience any compilation errors (caused by Mathematical) try running:
`brew link gettext --force` (you can unlink the libraries later if you want).

### Ubuntu
`sudo apt-get -qq -y install bison flex libffi-dev libxml2-dev libgdk-pixbuf2.0-dev libcairo2-dev libpango1.0-dev ttf-lyx`

## Installation
asciidoctor-mathematical is now available on RubyGems.
Installation is done by `gem install asciidoctor-mathematical`.
