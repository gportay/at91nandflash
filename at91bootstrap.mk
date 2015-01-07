at91bootstrap_%:
	make -C at91bootstrap $*

at91bootstrap/.config: at91bootstrap.cfg at91bootstrap/board/$(board)/$(AT91BOOTSTRAP_DEFCONFIG)
	@echo -e "\e[1mConfiguring at91bootstrap using $<...\e[0m"
	make -C at91bootstrap $(AT91BOOTSTRAP_DEFCONFIG)

at91bootstrap/binaries/at91bootstrap.bin: at91bootstrap/.config
	@echo -e "\e[1mCompiling $@...\e[0m"
	make -C at91bootstrap
	touch $@

$(at91bootstrap_output).bin: at91bootstrap/binaries/at91bootstrap.bin
	ln -sf at91bootstrap/binaries/$@

reallyclean::
	make -C at91bootstrap clean

mrproper::
	make -C at91bootstrap mrproper
