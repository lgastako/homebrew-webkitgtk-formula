# homebrew-webkitgtk-formula

*This is highly experimental and no warranty is expressed or implied.*

This is an attempt to solve the problem of installing a version of webkitgtk
that suffices to make get full GHCJS working on OS X as described
[in this stackoverflow post](https://stackoverflow.com/questions/34774356/installing-webkitgtk3-for-ghcjs-on-osx).

Currently it's just
[this gist](https://gist.githubusercontent.com/cpiro/0ea18227b251b26f94c645dd62b3f9a7/raw/48ce12108237760e08c058a62c08ed32a0cf6817/webkitgtk@2.4.11.rb)
exposed so it's directly useable as a tap.

To use it:

    $ brew tap lgastako/webkitgtk-formula git@github.com:lgastako/homebrew-webkitgtk-formula.git
    $ brew install lgastako/webkitgtk-formula/webkitgtk@2.4.11

Current status:

It builds and install fine for me on Yosemite but then fails on specific webkit
APIs missing when I try to use it.

Any tips/tricks/info/pull requests appreciated :)
