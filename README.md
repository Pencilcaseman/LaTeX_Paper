# LaTeX Paper Template

This is my personal LaTeX template, which I use for various papers, writeups and
other documents. Feel free to use it for your own projects.

Take a look at the GitHub Actions page for automatically built documents. They
run automatically when you push changes to the repository, so you can always
have an up-to-date version of the document.

## Dependencies

I'm not 100% sure which packages you need to build this template, so an
installation of TeXLive-Full is recommended (and is probably a good idea more
generally).

`make`,  `latexmk` and `lualatex` are also required. `make` should be available
by default on most *nix systems, and `latexmk` and `lualatex` are available in
most modern TeXLive installations.

## Building

To build the document, run `make` in the root directory. This will build the
'release' version of the document -- you can use `make draft` to build the draft
version, which includes a watermar and line numbers down the sides of the page.

You can run `make clean` to remove most of the generated files, or
`make distclean` to remove everything.

I find a full `distclean` is useful if something breaks strangely, but generally
running `make clean` is enough.

## Contributing

If you use this template and find it useful, please consider starring the
repository on GitHub or even contributing any improvements you have! Any help is
greatly appreciated.

## License

This template is licensed under the LaTeX Project Public License (LPPL), version
1.3c. See the `LICENSE` file for more information.

