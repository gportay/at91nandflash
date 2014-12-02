CROSS_COMPILE	?= arm-linux-gnueabi-
BOARD		?= at91-sama5d3_xplained

board		:= $(shell echo $(BOARD) | sed -e 's,^at91-,at91,' -e '/sama[0-9]/s,^at91-*,,')
DEFCONFIG	?= $(board)nf_linux_zimage_dt_defconfig

export CROSS_COMPILE

at91bootstrap_version	?= $(shell if test -e at91bootstrap/.git; then cd at91bootstrap && git describe | sed -e 's,-[0-9]\+-[0-9a-z]\+,,' -e 's,^v,,'; fi)
at91bootstrap_output	?= $(shell echo $(DEFCONFIG) | sed -e 's,.*nf_,-nandflashboot-,' -e 's,_defconfig,-$(at91bootstrap_version),' -e 's,_,-,g' -e 's,^,$(board)',)

include $(BOARD).inc

.PHONY: all clean mrproper

all: bootstrap

at91bootstrap/.config: at91bootstrap/board/$(board)/$(DEFCONFIG)
	@echo -e "\e[1mConfiguring at91bootstrap using $<...\e[0m"
	make -C at91bootstrap $(DEFCONFIG)

at91bootstrap/binaries/at91bootstrap.bin: at91bootstrap/.config
	@echo -e "\e[1mCompiling $@...\e[0m"
	make -C at91bootstrap
	touch $@

$(at91bootstrap_output).bin: at91bootstrap/binaries/at91bootstrap.bin
	ln -sf at91bootstrap/binaries/$@

bootstrap: $(at91bootstrap_output).bin

clean:
	make -C at91bootstrap clean
	rm -f $(at91bootstrap_output).bin

mrproper: clean
	make -C at91bootstrap mrproper
