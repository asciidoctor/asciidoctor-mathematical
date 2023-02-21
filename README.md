# asciidoctor-mathematical
Alternative stem processor for asciidoctor based on
[Mathematical](https://github.com/gjtorikian/mathematical).

## Features

asciidoctor-mathematical processes `latexmath` and `stem` blocks and inline
macros and replaces them with generated SVG or PNG images, thus enables `stem`
contents on a much wider range of asciidoctor backends. Currently, it is
tested to works well with the html, docbook, pdf and latex backends. For
`stem` blocks and macros, only the `latexmath` type is supported.

### Package Specific Attributes

These attributes can be set to tweak behaviors of this package:

| attribute           | description                                                           | valid values        | default value |
| ---------           | -----------                                                           | -------------       | ------------- |
| mathematical-format | format of generated images                                            | svg, png            | png           |
| mathematical-ppi    | ppi of generated images, only valid for png files                     | any positive number | 300.0         |
| mathematical-inline | if present will inline equations as svg (only useful for HTML output) | true/false          | false         |

## Usage
`asciidoctor-pdf -r asciidoctor-mathematical -o test.pdf sample.adoc`

## Installation
asciidoctor-mathematical is now available on RubyGems.  Installation is done
by `gem install asciidoctor-mathematical`. Install dependencies first.

### Dependencies
make, gobject, glib, gio, gdk-pixbuf, gdk, cairo, pangocairo, libxml, bison, flex

For the runtime, the following ttf fonts should be installed: cmr10, cmmi10,
cmex10 and cmsy10. They are provided by the lyx-fonts package in fedora, and the
fonts-lyx (or previously ttf-lyx) package in debian/ubuntu. In Arch Linux you can
install the [ttf-computer-modern-fonts](https://aur.archlinux.org/packages/ttf-computer-modern-fonts/)
package from AUR, you also have the [lyx](https://www.archlinux.org/packages/extra/x86_64/lyx/)
package in _extra_ repo though; both are providing required Computer Modern fonts.

#### OS X
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

#### Ubuntu
`sudo apt-get -qq -y install bison flex libffi-dev libxml2-dev libgdk-pixbuf2.0-dev libcairo2-dev libpango1.0-dev libzstd-dev fonts-lyx cmake`

#### Fedora 28

```
sudo dnf --setopt=install_weak_deps=False install -y \
  bison \
  cairo-devel \
  cmake \
  flex \
  gcc-c++ \
  gdk-pixbuf2-devel \
  libffi-devel \
  libxml2-devel \
  make \
  lyx-fonts \
  pango-devel \
  redhat-rpm-config \
  ruby-devel
```

The mathematical gem cannot currently be installed on Fedora 29.

### Trouble Shooting

The `mathematical` gem, which is a hard dependency of
`asciidoctor-mathematical`, may fail to build because of its over-writing of
`strdup`. Whether it fail depends on the system. In case it fails, use the
following command to install `mathematical` (see
[gjtorikian/mathematical#64](https://github.com/gjtorikian/mathematical/issues/64)
for the details):

```
MATHEMATICAL_SKIP_STRDUP=1 gem install mathematical
```

