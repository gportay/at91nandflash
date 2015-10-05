#!/usr/bin/gmake -rf
#
# The MIT License (MIT)
#
# Copyright (c) 2015 Gaël PORTAY <gael.portay@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

all::

ifneq (,$(CROSS_COMPILE))
tuple		:= $(patsubst %-,%,$(CROSS_COMPILE))
builddir	:= build-ct-ng-$(tuple)
PATH		:= $(HOME)/x-tools/$(tuple)/bin:$(PWD)/bin:$(PATH)

ifeq (,$(shell which $(CROSS_COMPILE)$(CC) 2>/dev/null))
all:: toolchain
endif

.PHONY:: toolchain

toolchain: $(HOME)/x-tools/$(tuple)/bin/$(CROSS_COMPILE)$(CC)

$(HOME)/x-tools/$(tuple)/bin/$(CROSS_COMPILE)$(CC): $(builddir)/.config
	( cd $(builddir) && ct-ng build )

$(builddir)/.config: bin/ct-ng
	test -d $(builddir) || install -d $(builddir)
	( cd $(builddir) && ct-ng $(tuple) )

ct-ng_%:
	test -d $(builddir) || install -d $(builddir)
	( cd $(builddir) && ct-ng $* )

ct-ng_build ct-ng_list-samples ct-ng_show-tuple:

ct-ng_menuconfig: $(builddir)/.config

ct-ng_configure:
	make -f crosstool-ng.mk $(builddir)/.config

ct-ng_install:
	make -f crosstool-ng.mk $(HOME)/x-tools/$(tuple)/bin/$(CROSS_COMPILE)$(CC)

reallyclean::
	rm -Rf $(builddir)/.build

mrproper::
	-make -C crosstool-ng uninstall MAKELEVEL=0
	rm -Rf $(builddir)/

bin/ct-ng: crosstool-ng/ct-ng
	-make -C crosstool-ng install MAKELEVEL=0

crosstool-ng/ct-ng: crosstool-ng/Makefile
	-make -C crosstool-ng MAKELEVEL=0

crosstool-ng/Makefile: crosstool-ng/configure
	( cd crosstool-ng && ./configure --prefix=$(PWD) )

crosstool-ng/configure: crosstool-ng/configure.ac
	( cd crosstool-ng && autoreconf -vif )

crosstool-ng_%:
	make -C crosstool-ng $* MAKELEVEL=0

crosstool-ng_configure: crosstool-ng/configure

crosstool-ng_install: bin/ct-ng

reallyclean::
	-make -C crosstool-ng uninstall MAKELEVEL=0
	-make -C crosstool-ng clean MAKELEVEL=0

mrproper::
	-make -C crosstool-ng mrproper MAKELEVEL=0

endif
