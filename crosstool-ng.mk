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
