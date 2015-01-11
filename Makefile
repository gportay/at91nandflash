VERSION		 = 0
PATCHLEVEL	 = 0
SUBLEVEL	 = 0
EXTRAVERSION	 = .0
NAME		 = Charlie Hebdo

cross_compile	?= $(CONFIG_CROSS_COMPILE)
CROSS_COMPILE	?= $(if $(cross_compile),$(cross_compile),arm-linux-gnueabi-)
BOARD		?= at91-sama5d3_xplained
BOARDTYPE	?= $(shell echo $(BOARD) | sed -e 's,^at91-,at91,' -e 's,_.*$$,x-ek,')
BOARDFAMILY	?= $(shell echo $(BOARD) | sed -e 's,_.*$$,,')
BOARDSUFFIX	?= $(shell echo $(BOARD) | sed -e 's,^.*_,_,')

board		:= $(shell echo $(BOARD) | sed -e 's,^at91-,at91,' -e '/sama[0-9]/s,^at91-*,,')
defconfig	:= $(CONFIG_AT91BOOTSTRAP_DEFCONFIG)
AT91BOOTSTRAP_DEFCONFIG	?= $(if $(defconfig),$(defconfig),$(board)nf_linux_zimage_dt_defconfig)

LINUXDIR	?= linux
IMAGE		?= zImage
DTB		?= $(BOARD)
defconfig	:= $(CONFIG_LINUX_DEFCONFIG)
LINUX_DEFCONFIG	?= $(if $(defconfig),$(defconfig),at91_dt_defconfig)

opts		:= $(CONFIG_MKFSUBIFSOPTS)
MKFSUBIFSOPTS	?= $(if $(opts),$(shell echo $(opts)),--leb-size 0x1f000 --min-io-size 0x800 --max-leb-cnt 2048)
opts		:= $(CONFIG_UBINIZEOPTS)
UBINIZEOPTS	?= $(if $(opts),$(shell echo $(opts)),--peb-size 0x20000 --min-io-size 0x800 --sub-page-size 0x800)

DEVICE		?= /dev/ttyACM0
PREFIX		?= /opt/at91/nandflash

sam_ba_bin	?= $(shell uname -m | sed -e 's,^[a-zA-Z0-9+-]*,sam-ba,')

export CROSS_COMPILE

at91bootstrap_version	?= $(shell if test -e at91bootstrap/.git; then cd at91bootstrap && git describe | sed -e 's,-[0-9]\+-[0-9a-z]\+,,' -e 's,^v,,'; fi)
at91bootstrap_output	?= $(shell echo $(AT91BOOTSTRAP_DEFCONFIG) | sed -e 's,.*nf_,-nandflashboot-,' -e 's,dt_defconfig,dt_ubi_defconfig,' -e 's,_defconfig,-$(at91bootstrap_version),' -e 's,_,-,g' -e 's,^,$(board)',)

.PHONY::

.PRECIOUS::

all::

include kconfig.mk

kconfig.mk:
	ln -sf initramfs/$@

include $(BOARD).inc

.PHONY:: all clean reallyclean mrproper sam-ba

include at91bootstrap.mk initramfs.mk

all:: bootstrap ubi

initramfs.cpio:
	make -C initramfs
	ln -sf initramfs/$@

$(IMAGE): initramfs.cpio
	@echo -e "\e[1mGenerating $@...\e[0m"
	make -C initramfs kernel LINUXDIR=$(LINUXDIR) LINUX_DEFCONFIG=$(LINUX_DEFCONFIG)
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

ubi.ini: at91bootstrap/.config $(KCONFIG_CONFIG)
	@echo -e "\e[1mGenerating $@...\e[0m"
	$(obj)/ubi.sh $(KCONFIG_CONFIG) >$@

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
	    -e "s,@BOARDFAMILY@,$(BOARDFAMILY)," \
	    -e "s,@BOARDSUFFIX@,$(BOARDSUFFIX)," \
	    $< >$@

sam-ba: $(BOARD)-nandflash4sam-ba.tcl $(BOARD)-mtd0.bin $(BOARD)-mtd1.bin
	@echo -e "\e[1mFlashing $@ board $(BOARDTYPE) available at $(DEVICE) using script $< ...\e[0m"
	$(sam_ba_bin) $(DEVICE) $(BOARDTYPE) $< || true

$(BOARD)-sam-ba.sh:
	echo "#!/bin/sh" >$@
	echo "sam_ba_bin=$(uname -m | sed -e 's,^[a-zA-Z0-9+-]*,sam-ba,')" >>$@
	echo "$$sam_ba_bin \$${1:-$(DEVICE)} $(BOARDTYPE) $(BOARD)-nandflash4sam-ba.tcl" >>$@
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

clean::
	rm -f $(at91bootstrap_output).bin initramfs.cpio $(IMAGE) kernel *.dtb dtb $(BOARD).ubi $(BOARD)-mtd*.bin $(BOARD)-nandflash4sam-ba.tcl $(BOARD)-sam-ba.sh $(BOARD)-sam-ba.bat

reallyclean:: clean
	rm -f persistant.ubifs *.ubi *-mtd*.bin *-nandflash4sam-ba.tcl *-sam-ba.sh *-sam-ba.bat *.tar *.tgz *.zip
	rm -Rf persistant

mrproper:: reallyclean
	rm -f kconfig.mk
