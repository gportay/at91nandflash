ubi_defconfig: ubi_defconfig.in
	sed -e "s#@CMDLINE@#$(CMDLINE)#" \
	    -e "s#@KERNEL_VOLNAME@#$(KERNEL_VOLNAME)#" \
	    -e "s#@KERNEL_SPARE_VOLNAME@#$(KERNEL_SPARE_VOLNAME)#" \
	    -e "s#@DTB_VOLNAME@#$(DTB_VOLNAME)#" \
	    -e "s#@DTB_SPARE_VOLNAME@#$(DTB_SPARE_VOLNAME)#" \
	    $< >$@

at91bootstrap/board/sama5d4_xplained/sama5d4_xplainednf_uboot_defconfig: at91bootstrap/board/sama5d4_xplained/sama5d4_xplainednf_uboot_secure_defconfig

at91bootstrap/board/$(at91board)/%_defconfig:
	ln -sf $(<F) $@

at91bootstrap/board/$(at91board)/$(AT91DEFCONFIG): at91bootstrap/board/$(at91board)/$(at91board)nf_uboot_defconfig
	sed -e '/CONFIG_LOAD_UBOOT/d' \
	    -e '$$aCONFIG_LOAD_LINUX=y' \
	    $< >$@

at91bootstrap/.config: at91bootstrap/board/$(at91board)/$(AT91DEFCONFIG) ubi_defconfig
	@echo -e "\e[1mConfiguring at91bootstrap using $<...\e[0m"
	make -C at91bootstrap $(AT91DEFCONFIG)
	cd at91bootstrap && config/merge_config.sh $(@F) ../ubi_defconfig
	if ! grep -qE "CONFIG_UBI=y" $@; then echo "at91bootstrap: Mismatch configuration!" >&2; rm $@; exit 1; fi

at91bootstrap/binaries/at91bootstrap.bin: at91bootstrap/.config
	@echo -e "\e[1mCompiling at91bootstrap...\e[0m"
	make -C at91bootstrap
	rm $@

at91bootstrap/binaries/$(at91board)-$(at91suffix).bin: at91bootstrap/binaries/at91bootstrap.bin
	mv at91bootstrap/.config at91bootstrap/.config-$(BOARD)

$(at91board)-$(at91suffix).bin: at91bootstrap/binaries/$(at91board)-$(at91suffix).bin
	cp $< $@

at91bootstrap_%:
	make -C at91bootstrap $*

reallyclean::
	make -C at91bootstrap clean

mrproper::
	make -C at91bootstrap mrproper
