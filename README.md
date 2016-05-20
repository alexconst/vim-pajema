# About

*pa·je·ma  (pə-jĕ′mə, -jăm′ə): Pandoc + Jekyll + Markdown for great success*

vim-pajema aims to make life easier for those using the above mentioned tools. Basically it allows you to:
- convert a markdown file to html and open it in firefox
- convert a markdown file to a Jekyll suitable markdown file

**NOTE: consider this alpha version. My first vim plugin: it's ugly and messy but gets things done. It's for my own personal use, but maybe it's useful to you too.**

# Features

With `,` being the leader key:

**Preview**
Type `,h` and the file gets converted to html.
Type `,p` and the html opens in your browser.
Enable the option and everytime you save the markdown file a new html file is generated.
Tile vim and firefox side by side and you can now live edit your markdown file.

**Conversion**
Type `,j` and the sensible Pandoc markdown gets converted to a Jekyll compatible markdown.
Bonus: references to other markdown files, such as `[Vagrant](Vagrant.md)` get converted to `[Vagrant]({% post_url 2016-01-28-vagrant %})`. Yes! It reads the YAML header and uses the date metadata.
Note: for this to work you need to have your `.md` files in the `_drafts` folder and it will generate a `.markdown` file in the `_posts` folder.

**Latex**

It supports LatexMathML syntax via Pandoc.

# Configuration options

TODO

# Installation

```bash
cd $HOME/.vim/bundle
git clone https://github.com/alexconst/vim-pajema
```


# Development

To run the tests: `make test`


# Motivation / story time

I wanted to start a blog (because nowadays that is your CV *\*sigh\**). But I also wanted to sort out the dozens *(yikes Scoob! make that hundreds)* of text files notes I've been taking throughout the years (most of them using Zim) into something more usable.
While initially inclined to move to some wiki-based solution, given GitHub's influence, Markdown seemed like best solution. However GH's (the default?) Markdown limitations and quirks made it quite a pain.
*Worry not! Pandoc to the rescue!*
Anyway, fast forward and this script just kept on growing and growing.


# Acknowledgements and Credits

The initial version of this script was based on [this awesome gist](https://gist.github.com/natesilva/960015) (maybe it even fits your bill better than this one). But as time went by all traces of it faded, except for the utf handling snippet.

Also thank you John MacFarlane and other Pandoc contributors. I just love Pandoc. It really is a life saver when it comes to handling documentation.

And the people working on vim-markdown as well. For making markdown editing a great experience.




# TODO

- pay technical debt
- add configuration options
- add information on https://github.com/jgm/pandocfilters (probably most if not all could have been done using filters)
- fix shortcuts so that they only work with markdown files


