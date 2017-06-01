# homebrew-webkitgtk-formula

*This is highly experimental and no warranty is expressed or implied.*

This is an attempt to solve the problem of installing a version of webkitgtk
that suffices to make get full GHCJS working on OS X as described
[in this stackoverflow post](https://stackoverflow.com/questions/34774356/installing-webkitgtk3-for-ghcjs-on-osx).

To use it:

    $ brew tap lgastako/webkitgtk-formula git@github.com:lgastako/homebrew-webkitgtk-formula.git
    $ brew install lgastako/webkitgtk-formula

Current status:

It builds and install fine for me on Yosemite but then fails on specific webkit
APIs missing when I try to use it.

Any tips/tricks/info/pull requests appreciated :)
