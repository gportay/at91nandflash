.SECONDARY:: at91bootstrap/binaries/at91bootstrap.bin at91bootstrap/.config

at91version	:= $(shell if test -e at91bootstrap/Makefile; then sed -ne "/^VERSION/s,.*=\s*,,p" at91bootstrap/Makefile; fi)
at91revision	:= $(shell if test -e at91bootstrap/Makefile; then sed -ne "/^REVISION/s,.*=\s*,,p" at91bootstrap/Makefile; fi)
ifeq ($(at91revision),)
at91release	:= $(at91version)
else
at91release	:= $(at91version)-$(at91revision)
endif
at91suffix	?= $(shell echo $(at91defconfig) | sed -e 's,nf_,nandflashboot-,' -e 's,_defconfig,-$(at91release),' -e 's,_,-,g')

ubi_defconfig: ubi_defconfig.in
	sed -e "s#@CMDLINE@#$(CMDLINE)#" \
	    -e "s#@KERNEL_VOLNAME@#$(KERNEL_VOLNAME)#" \
	    -e "s#@KERNEL_SPARE_VOLNAME@#$(KERNEL_SPARE_VOLNAME)#" \
	    -e "s#@DTB_VOLNAME@#$(DTB_VOLNAME)#" \
	    -e "s#@DTB_SPARE_VOLNAME@#$(DTB_SPARE_VOLNAME)#" \
	    $< >$@

ifeq (,$(findstring ubi,$(AT91DEFCONFIG)))
at91bootstrap/board/sama5d4_xplained/sama5d4_xplainednf_uboot_defconfig: at91bootstrap/board/sama5d4_xplained/sama5d4_xplainednf_uboot_secure_defconfig

at91bootstrap/board/$(at91board)/%_defconfig:
	ln -sf $(<F) $@

at91bootstrap/board/$(at91board)/$(AT91DEFCONFIG): at91bootstrap/board/$(at91board)/$(at91board)nf_uboot_defconfig
	sed -e '/CONFIG_LOAD_UBOOT/d' \
	    -e '$$aCONFIG_LOAD_LINUX=y' \
	    $< >$@
endif

at91bootstrap/.config: at91bootstrap/board/$(at91board)/$(AT91DEFCONFIG) ubi_defconfig
	@echo "Configuring at91bootstrap using $<..."
	make -C at91bootstrap $(AT91DEFCONFIG)
	cd at91bootstrap && config/merge_config.sh $(@F) ../ubi_defconfig
	if ! grep -qE "CONFIG_UBI=y" $@; then echo "at91bootstrap: Mismatch configuration!" >&2; rm $@; exit 1; fi

at91bootstrap/binaries/at91bootstrap.bin: at91bootstrap/.config
	@echo "Compiling at91bootstrap..."
	make -C at91bootstrap
	rm $@

at91bootstrap/binaries/$(at91board)-$(at91suffix).bin: at91bootstrap/binaries/at91bootstrap.bin
	cp at91bootstrap/.config at91bootstrap/.config-$(BOARD)

$(at91board)-$(at91suffix).bin: at91bootstrap/binaries/$(at91board)-$(at91suffix).bin
	cp $< $@

at91bootstrap_menuconfig at91bootstrap_clean at91bootstrap_mrproper:

at91bootstrap_configure: at91bootstrap/.config

at91bootstrap_reconfigure:
	rm -f at91bootstrap/.config
	make -f Makefile at91bootstrap/.config

at91bootstrap_compile: at91bootstrap/binaries/at91bootstrap.bin

at91bootstrap_recompile: at91bootstrap/.config
	touch $<
	make -C at91bootstrap

at91bootstrap_%:
	make -C at91bootstrap $*

reallyclean::
	make -C at91bootstrap clean

mrproper::
	make -C at91bootstrap mrproper
