VERSION		 = 0
PATCHLEVEL	 = 0
SUBLEVEL	 = 0
EXTRAVERSION	 = .1
NAME		 = Charlie Hebdo

CROSS_COMPILE	?= arm-linux-gnueabi-
BOARD		?= at91-sama5d3_xplained
board		:= $(shell echo $(BOARD) | sed -e '/sama5d/s,d3[13456],d3x,')
BOARDTYPE	?= $(shell echo $(board) | sed -e 's,^at91-,at91,' -e '/m10g45/s,m10g45,m10-g45,' -e '/sam9rl/s,rl,rl64,' -e 's,ek$$,-ek,' -e 's,_xplained.*$$,x-ek,' -e '/sama5.*[^x]-ek/s,-ek,x-ek,')
BOARDTYPES	:= at91sam9260-ek at91sam9261-ek at91sam9263-ek at91sam9g10-ek at91sam9g20-ek at91sam9g45-ekes at91sam9m10-ekes at91sam9m10-g45-ek at91sam9n12-ek at91sam9rl64-ek at91sam9g15-ek at91sam9g25-ek at91sam9g35-ek at91sam9x25-ek at91sam9x35-ek at91sama5d3x-xplained at91sama5d3x-ek at91sama5d4x-ek

at91board	:= $(shell echo $(board) | sed -e '/sam9[gx][123]5/s,[gx][123]5,x5,' -e '/sam9/s,^at91-,at91,' -e '/sama5/s,^at91-*,,')
at91defconfig	:= nf_linux_image_dt_defconfig
AT91DEFCONFIG	?= $(at91board)$(at91defconfig)

CMDLINE			?= console=ttyS0,115200 mtdparts=atmel_nand:128k(bootstrap)ro,-(UBI) ubi.mtd=UBI
KERNEL_VOLNAME		?= kernel
KERNEL_SPARE_VOLNAME	?= $(KERNEL_VOLNAME)-spare
DTB_VOLNAME		?= dtb
DTB_SPARE_VOLNAME	?= $(DTB_VOLNAME)-spare

MKFSUBIFSOPTS	?= --leb-size 0x1f000 --min-io-size 0x800 --max-leb-cnt 2048
UBINIZEOPTS	?= --peb-size 0x20000 --min-io-size 0x800 --sub-page-size 0x800

DEVICE		?= /dev/ttyACM0
PREFIX		?= /opt/at91/nandflash

sam_ba_bin	?= $(shell uname -m | sed -e 's,^[a-zA-Z0-9+-]*,sam-ba,')
at91version	:= $(shell if test -e at91bootstrap/Makefile; then sed -ne "/^VERSION/s,.*=\s*,,p" at91bootstrap/Makefile; fi)
at91revision	:= $(shell if test -e at91bootstrap/Makefile; then sed -ne "/^REVISION/s,.*=\s*,,p" at91bootstrap/Makefile; fi)
ifeq ($(at91revision),)
at91release	:= $(at91version)
else
at91release	:= $(at91version)-$(at91revision)
endif
at91suffix	?= $(shell echo $(at91defconfig) | sed -e 's,nf_,nandflashboot-,' -e 's,_defconfig,-ubi-$(at91release),' -e 's,_,-,g')

export CROSS_COMPILE

.PHONY:: all clean reallyclean mrproper sam-ba

.SILENT:: check

.SECONDARY:: at91bootstrap/binaries/at91bootstrap.bin at91bootstrap/.config

all:: bootstrap ubi

check::
	echo -n "$(BOARD): "
	for board in $(BOARDTYPES); do if test "$$board" = "$(BOARDTYPE)"; then exit 0; fi; done \
		&& ( echo "sam-ba: Mismatch board-type '$(BOARDTYPE)'!" >&2; exit 1 )
	echo "checked!"

include at91bootstrap.mk initramfs.mk kernel.mk

persistent:
	install -d $@

persistent.ubifs: persistent
	@echo "Generating persistent.ubifs..."
	mkfs.ubifs $(MKFSUBIFSOPTS) --root $< --output $@

$(BOARD).ini: ubi.ini.in
	sed -e "s,@KERNEL@,$(KIMAGE)-initramfs-$(BOARD).bin," \
	    -e "s,@DTB@,$(DTB).dtb," \
	    $< >$@

$(BOARD).ubi: $(BOARD).ini kernel dtb persistent.ubifs
	@echo "Generating $@..."
	ubinize $(UBINIZEOPTS) --output $@ $<

$(BOARD)-mtd0.bin: $(at91board)-$(at91suffix).bin

$(BOARD)-mtd1.bin: $(BOARD).ubi

bootstrap: $(BOARD)-mtd0.bin

ubi: $(BOARD)-mtd1.bin

$(BOARD)-nandflash4sam-ba.tcl: board-nandflash4sam-ba.tcl.in
	sed -e "s,@BOOTSTRAPFILE@,$(BOARD)-mtd0.bin," \
	    -e "s,@UBIFILE@,$(BOARD)-mtd1.bin," \
	    $< >$@

sam-ba: $(BOARD)-nandflash4sam-ba.tcl $(BOARD)-mtd0.bin $(BOARD)-mtd1.bin
	@echo "Flashing $@ board $(BOARDTYPE) available at $(DEVICE) using script $< ..."
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

clean::
	rm -f $(at91board)-$(at91suffix).bin initramfs.cpio $(BOARD).ubi $(BOARD).ini $(BOARD)-mtd*.bin $(BOARD)-nandflash4sam-ba.tcl $(BOARD)-sam-ba.sh $(BOARD)-sam-ba.bat

reallyclean:: clean
	rm -f persistent.ubifs *.ubi *.ini *-mtd*.bin *-linux-image*-ubi-*.bin *-nandflash4sam-ba.tcl *-sam-ba.sh *-sam-ba.bat *.tar *.tgz *.zip
	rm -Rf persistent

mrproper:: reallyclean
