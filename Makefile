VERSION		 = 0
PATCHLEVEL	 = 0
SUBLEVEL	 = 0
EXTRAVERSION	 = .0
NAME		 = Charlie Hebdo

CROSS_COMPILE	?= arm-linux-gnueabi-
BOARD		?= at91-sama5d3_xplained
BOARDTYPE	?= $(shell echo $(BOARD) | sed -e 's,^at91-,at91,' -e 's,_.*$$,x-ek,')

board		:= $(shell echo $(BOARD) | sed -e 's,^at91-,at91,' -e '/sama[0-9]/s,^at91-*,,')
DEFCONFIG	?= $(board)nf_linux_zimage_dt_defconfig

LINUXDIR	?= linux
IMAGE		?= zImage
DTB		?= $(BOARD)

MKFSUBIFSOPTS	?= --leb-size 0x1f000 --min-io-size 0x800 --max-leb-cnt 2048
UBINIZEOPTS	?= --peb-size 0x20000 --min-io-size 0x800 --sub-page-size 0x800

DEVICE		?= /dev/ttyACM0
PREFIX		?= /opt/at91/nandflash

sam_ba_bin	?= $(shell uname -m | sed -e 's,^[a-zA-Z0-9+-]*,sam-ba,')

export CROSS_COMPILE

at91bootstrap_version	?= $(shell if test -e at91bootstrap/.git; then cd at91bootstrap && git describe | sed -e 's,-[0-9]\+-[0-9a-z]\+,,' -e 's,^v,,'; fi)
at91bootstrap_output	?= $(shell echo $(DEFCONFIG) | sed -e 's,.*nf_,-nandflashboot-,' -e 's,_defconfig,-$(at91bootstrap_version),' -e 's,_,-,g' -e 's,^,$(board)',)

include $(BOARD).inc

.PHONY: all clean mrproper sam-ba

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

$(BOARD)-mtd0.bin: $(at91bootstrap_output).bin

$(BOARD)-mtd1.bin: $(BOARD).ubi

bootstrap: $(BOARD)-mtd0.bin

ubi: $(BOARD)-mtd1.bin

$(BOARD)-nandflash4sam-ba.tcl: board-nandflash4sam-ba.tcl.in
	sed -e "s,@BOOTSTRAPFILE@,$(BOARD)-mtd0.bin," \
	    -e "s,@UBIFILE@,$(BOARD)-mtd1.bin," \
	    $< >$@

sam-ba: $(BOARD)-nandflash4sam-ba.tcl $(BOARD)-mtd0.bin $(BOARD)-mtd1.bin
	@echo -e "\e[1mFlashing $@ board $(BOARDTYPE) available at $(DEVICE) using script $< ...\e[0m"
	$(sam_ba_bin) $(DEVICE) $(BOARDTYPE) $< || true

$(BOARD)-sam-ba.sh:
	echo "#!/bin/sh" >$@
	echo "sam_ba_bin=\$$(uname -m | sed -e 's,^[a-zA-Z0-9+-]*,sam-ba,')" >>$@
	echo "\$$sam_ba_bin \$${1:-$(DEVICE)} $(BOARDTYPE) $(BOARD)-nandflash4sam-ba.tcl" >>$@
	chmod a+x $@

$(BOARD)-sam-ba.bat:
	echo "sam-ba.exe \\usb\\ARM0 $(BOARDTYPE) $(BOARD)-nandflash4sam-ba.tcl" >$@
	chmod a+x $@


%.bin:
	ln -sf $< $@

tar: $(BOARD)-nandflash4sam-ba.tcl $(BOARD)-mtd0.bin $(BOARD)-mtd1.bin nandflash4sam-ba.tcl $(BOARD)-sam-ba.sh $(BOARD)-sam-ba.bat
	tar hcf $(BOARD).$@ $?

tgz: $(BOARD)-nandflash4sam-ba.tcl $(BOARD)-mtd0.bin $(BOARD)-mtd1.bin nandflash4sam-ba.tcl $(BOARD)-sam-ba.sh $(BOARD)-sam-ba.bat
	tar hczf $(BOARD).$@ $?

zip: $(BOARD)-nandflash4sam-ba.tcl $(BOARD)-mtd0.bin $(BOARD)-mtd1.bin nandflash4sam-ba.tcl $(BOARD)-sam-ba.sh $(BOARD)-sam-ba.bat
	zip -9 $(BOARD).$@ $?

install: $(BOARD)-nandflash4sam-ba.tcl $(BOARD)-mtd0.bin $(BOARD)-mtd1.bin nandflash4sam-ba.tcl $(BOARD)-sam-ba.sh $(BOARD)-sam-ba.bat
	install -d $(DESTDIR)$(PREFIX)/$(BOARD)
	for file in $?; do install $$file $(DESTDIR)/$(PREFIX)/$(BOARD); done

clean:
	make -C at91bootstrap clean
	make -C initramfs clean
	rm -f $(at91bootstrap_output).bin initramfs.cpio $(IMAGE) kernel *.dtb dtb $(BOARD).ubi $(BOARD)-mtd*.bin $(BOARD)-nandflash4sam-ba.tcl $(BOARD)-sam-ba.sh $(BOARD)-sam-ba.bat

mrproper: clean
	make -C at91bootstrap mrproper
	make -C initramfs mrproper
	rm -f persistant.ubifs *.ubi *-mtd*.bin *-nandflash4sam-ba.tcl *-sam-ba.sh *-sam-ba.bat *.tar *.tgz *.zip
	rm -Rf persistant
