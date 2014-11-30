CROSS_COMPILE	?= arm-linux-gnueabi-
BOARD		?= at91-sama5d3_xplained

board		:= $(shell echo $(BOARD) | sed -e 's,^at91-,at91,' -e '/sama[0-9]/s,^at91-*,,')
DEFCONFIG	?= $(board)nf_linux_zimage_dt_defconfig

LINUXDIR	?= linux
IMAGE		?= zImage
DTB		?= $(BOARD)

MKFSUBIFSOPTS	?= --leb-size 0x1f000 --min-io-size 0x800 --max-leb-cnt 2048
UBINIZEOPTS	?= --peb-size 0x20000 --min-io-size 0x800 --sub-page-size 0x800

export CROSS_COMPILE

at91bootstrap_version	?= $(shell if test -e at91bootstrap/.git; then cd at91bootstrap && git describe | sed -e 's,-[0-9]\+-[0-9a-z]\+,,' -e 's,^v,,'; fi)
at91bootstrap_output	?= $(shell echo $(DEFCONFIG) | sed -e 's,.*nf_,-nandflashboot-,' -e 's,_defconfig,-$(at91bootstrap_version),' -e 's,_,-,g' -e 's,^,$(board)',)

include $(BOARD).inc

.PHONY: all clean mrproper

all: bootstrap ubi

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

initramfs.cpio:
	make -C initramfs
	ln -sf initramfs/$@

$(IMAGE): initramfs.cpio
	@echo -e "\e[1mGenerating $@...\e[0m"
	make -C initramfs kernel LINUXDIR=$(LINUXDIR)
	ln -sf initramfs/$@

kernel: $(IMAGE)
	ln -sf initramfs/$< $@

%.dtb:
	@echo -e "\e[1mGenerating $@...\e[0m"
	make -C initramfs $@
	ln -sf initramfs/$@

dtb: $(DTB).dtb
	ln -sf initramfs/$< $@

persistant:
	install -d $@

persistant.ubifs: persistant
	@echo -e "\e[1mGenerating persistant.ubifs...\e[0m"
	mkfs.ubifs $(MKFSUBIFSOPTS) --root $< --output $@

$(BOARD).ubi: ubi.ini kernel dtb persistant.ubifs
	@echo -e "\e[1mGenerating $@...\e[0m"
	ubinize $(UBINIZEOPTS) --output $@ $<

ubi: $(BOARD).ubi

clean:
	make -C at91bootstrap clean
	make -C initramfs clean
	rm -f $(at91bootstrap_output).bin initramfs.cpio $(IMAGE) kernel *.dtb dtb $(BOARD).ubi

mrproper: clean
	make -C at91bootstrap mrproper
	make -C initramfs mrproper
	rm -f persistant.ubifs *.ubi
	rm -Rf persistant
