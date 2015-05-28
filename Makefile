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
defconfig	:= nf_linux_image_dt_defconfig
DEFCONFIG	?= $(at91board)$(defconfig)

CMDLINE			?= console=ttyS0,115200 mtdparts=atmel_nand:128k(bootstrap)ro,-(UBI) ubi.mtd=UBI
KERNEL_VOLNAME		?= kernel
KERNEL_SPARE_VOLNAME	?= $(KERNEL_VOLNAME)-spare
DTB_VOLNAME		?= dtb
DTB_SPARE_VOLNAME	?= $(DTB_VOLNAME)-spare

LINUXDIR	?= linux
IMAGE		?= zImage
DTB		?= $(shell echo $(BOARD) | sed -e '/at91-sam9/s,at91-,at91,' -e '/at91-sama5d3[1-6]ek/s,at91-,,')

MKFSUBIFSOPTS	?= --leb-size 0x1f000 --min-io-size 0x800 --max-leb-cnt 2048
UBINIZEOPTS	?= --peb-size 0x20000 --min-io-size 0x800 --sub-page-size 0x800

DEVICE		?= /dev/ttyACM0
PREFIX		?= /opt/at91/nandflash

sam_ba_bin	?= $(shell uname -m | sed -e 's,^[a-zA-Z0-9+-]*,sam-ba,')
at91version	?= $(shell if test -e at91bootstrap/Makefile; then sed -ne "/^VERSION/s,[^0-9.]*,,p" at91bootstrap/Makefile; fi)
at91suffix	?= $(shell echo $(defconfig) | sed -e 's,nf_,nandflashboot-,' -e 's,_defconfig,-ubi-$(at91version),' -e 's,_,-,g')

export CROSS_COMPILE

.PHONY: all clean mrproper sam-ba

.SILENT: check

.SECONDARY: at91bootstrap/binaries/at91bootstrap.bin at91bootstrap/.config

all: bootstrap ubi

check:
	echo -n "$(BOARD): "
	for board in $(BOARDTYPES); do if test "$$board" = "$(BOARDTYPE)"; then exit 0; fi; done \
		&& ( echo "sam-ba: Mismatch board-type '$(BOARDTYPE)'!" >&2; exit 1 )
	echo "checked!"

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

at91bootstrap/board/$(at91board)/$(DEFCONFIG): at91bootstrap/board/$(at91board)/$(at91board)nf_uboot_defconfig
	sed -e '/CONFIG_LOAD_UBOOT/d' \
	    -e '$$aCONFIG_LOAD_LINUX=y' \
	    $< >$@

at91bootstrap/.config: at91bootstrap/board/$(at91board)/$(DEFCONFIG) ubi_defconfig
	@echo "Configuring at91bootstrap using $<..."
	make -C at91bootstrap $(DEFCONFIG)
	cd at91bootstrap && config/merge_config.sh $(@F) ../ubi_defconfig
	if ! grep -qE "CONFIG_UBI=y" $@; then echo "at91bootstrap: Mismatch configuration!" >&2; rm $@; exit 1; fi

at91bootstrap/binaries/at91bootstrap.bin: at91bootstrap/.config
	@echo "Compiling at91bootstrap..."
	make -C at91bootstrap
	rm $@

at91bootstrap/binaries/$(at91board)-$(at91suffix).bin: at91bootstrap/binaries/at91bootstrap.bin
	mv at91bootstrap/.config at91bootstrap/.config-$(BOARD)

$(at91board)-$(at91suffix).bin: at91bootstrap/binaries/$(at91board)-$(at91suffix).bin
	cp $< $@

at91bootstrap_%:
	make -C at91bootstrap $*

initramfs.cpio:
	make -C initramfs
	ln -sf initramfs/$@

$(IMAGE): initramfs.cpio
	@echo "Generating $@..."
	make -C initramfs kernel LINUXDIR=$(LINUXDIR)
	ln -sf initramfs/$@

kernel: $(IMAGE)
	ln -sf initramfs/$< $@

%.dtb:
	@echo "Generating $@..."
	make -C initramfs $@
	ln -sf initramfs/$@

dtb: $(DTB).dtb
	ln -sf initramfs/$< $@

persistant:
	install -d $@

persistant.ubifs: persistant
	@echo "Generating persistant.ubifs..."
	mkfs.ubifs $(MKFSUBIFSOPTS) --root $< --output $@

$(BOARD).ubi: ubi.ini kernel dtb persistant.ubifs
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

clean:
	make -C at91bootstrap clean
	make -C initramfs clean
	rm -f $(at91board)-$(at91suffix).bin initramfs.cpio $(IMAGE) kernel *.dtb dtb $(BOARD).ubi $(BOARD)-mtd*.bin $(BOARD)-nandflash4sam-ba.tcl $(BOARD)-sam-ba.sh $(BOARD)-sam-ba.bat

mrproper: clean
	make -C at91bootstrap mrproper
	make -C initramfs mrproper
	rm -f persistant.ubifs *.ubi *-mtd*.bin *-linux-image*-ubi-*.bin *-nandflash4sam-ba.tcl *-sam-ba.sh *-sam-ba.bat *.tar *.tgz *.zip
	rm -Rf persistant
