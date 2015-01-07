.PHONY:: kconfig-frontends_install kconfig-frontends_uninstall kconfig-frontends_cleanall

.PRECIOUS:: $(obj)/kconfig-%

initramfs/bin/kconfig-%: kconfig-frontends_install
	make -C initramfs bin/$(*F)

$(obj)/kconfig-%:
	make kconfig-frontends_install

$(obj)/%: $(obj)/kconfig-%
	echo -e '#!/bin/sh\nLD_LIBRARY_PATH=$(PWD)/lib $(PWD)/$< $$*' >$@
	chmod a+x $@

kconfig-frontends_%:
	make -C initramfs kconfig-frontends_$*

kconfig-frontends_install:
	make -C initramfs kconfig-frontends_install DESTDIR=$(PWD)

kconfig-frontends_uninstall:
	-make -C initramfs kconfig-frontends_uninstall DESTDIR=$(PWD)

kconfig-frontends_cleanall::
	-make -f Makefile kconfig-frontends_clean
	for bin in $(obj)/*; do if test -x $$bin && grep -qE kconfig- $$bin; then rm $$bin; fi; done

reallyclean::
	-make kconfig-frontends_cleanall

mrproper::
	-make kconfig-frontends_uninstall
	-make kconfig-frontends_distclean
