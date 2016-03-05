VIMDIR=$(DESTDIR)/usr/share/vim
ADDONS=${VIMDIR}/addons

all:

install:
	mkdir -pv ${ADDONS}/ftdetect
	cp -v ftdetect/pajema.vim ${ADDONS}/ftdetect/
	mkdir -pv ${ADDONS}/ftplugin
	cp -v ftplugin/markdown.vim ${ADDONS}/ftplugin/

test: build/vader.vim
	tests/run-tests.sh >tests.log 2>&1
.PHONY: test

build/vader.vim: | build
	git clone https://github.com/junegunn/vader.vim build/vader.vim

build:
	mkdir -p build

