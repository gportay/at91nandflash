VERSION		 = 0
PATCHLEVEL	 = 0
SUBLEVEL	 = 0
EXTRAVERSION	 = .2
NAME		 = Charlie Hebdo
RELEASE		 = $(VERSION)$(if $(PATCHLEVEL),.$(PATCHLEVEL)$(if $(SUBLEVEL),.$(SUBLEVEL)))$(EXTRAVERSION)

SSHOPTS		?=
WGETOPTS	?= --no-check-certificate
CURLOPTS	?= --insecure

CROSS_COMPILE	?= arm-unknown-linux-gnueabi-
BOARD		?= at91-sama5d3_xplained

all::

include at91.mk sam-ba.mk

CMDLINE			?= console=ttyS0,115200 mtdparts=atmel_nand:128k(bootstrap)ro,-(UBI) ubi.mtd=UBI
KERNEL_VOLNAME		?= kernel
KERNEL_SPARE_VOLNAME	?= $(KERNEL_VOLNAME)-spare
DTB_VOLNAME		?= dtb
DTB_SPARE_VOLNAME	?= $(DTB_VOLNAME)-spare

MKFSUBIFSOPTS	?= --leb-size 0x1f000 --min-io-size 0x800 --max-leb-cnt 2048
UBINIZEOPTS	?= --peb-size 0x20000 --min-io-size 0x800 --sub-page-size 0x800

PREFIX		?= /opt/at91/nandflash

export CROSS_COMPILE

.PHONY:: all clean reallyclean mrproper

.SILENT:: version help check

.SECONDARY:: at91bootstrap/binaries/at91bootstrap.bin at91bootstrap/.config

include crosstool-ng.mk

all:: bootstrap ubi

version:
	echo "$(RELEASE)"

help::
	echo -e "\$$ make version\t\t\t\tto display version."
	echo -e "\$$ make help\t\t\t\tto display this message."
	echo -e "\$$ make kernel [KIMAGE=zImage]\t\tto build a kernel image."
	echo -e "\$$ make dtb|dtbs\t\t\t\tto build a dtb or all dbts images."
	echo -e "\$$ make kernel|linux_xxx\t\t\tto run linux kernel xxx rule."
	echo -e "\$$ make at91boostrap_xxx\t\t\tto run at91bootstrap xxx rule."
	echo -e "\$$ make [BOARD=$(BOARD)]\t\tto build the NAND image (without OOB)."
	echo -e "\$$ make install [DESTDIR=\$$PWD]\t\tto install output into \$$DESTDIR."
	echo -e "\$$ make tar|tgz|zip [DESTDIR=\$$PWD]\tto make an archive of outputs into \$$DESTDIR."
	echo -e "\$$ make sam-ba [DEVICE=$(DEVICE)]\tto flash the NAND image (without OOB) into device $(DEVICE)."
	echo -e "\$$ make clean [BOARD=$(BOARD)]\tto clean workspace from $(BOARD) outputs."
	echo -e "\$$ make reallyclean\t\t\tto clean workspace from all board outputs."
	echo -e "\$$ make mrproper\t\t\t\tto clean workspace from everything."
	echo -e ""
	echo -e "Extra variables:"
	echo -e "CMDLINE:                                Overwrite the kernel command-line (bootstrap)."
	echo -e "CROSS_COMPILE:                          Sets the cross-compiler (bootstrap and kernel)."
	echo -e "KIMAGE:                                 Set kernel image type (kernel)."
	echo -e "KDEFCONFIG:                             Specifies defconfig (kernel)."
	echo -e "AT91DEFCONFIG:                          Specifies defconfig (bootstrap)."
	echo -e "BOARD:                                  Specifies the target."
	echo -e "BOARDTYPE:                              Specifies the board setup (sam-ba)."
	echo -e "MKFSUBIFSOPTS:                          Set mkfs.ubifs options (output)."
	echo -e "UBINIZEOPTS:                            Set ubinize options (output)."

check::

include at91bootstrap.mk initramfs.mk kernel.mk

kernelimage	:= $(KIMAGE)-initramfs-$(BOARD).bin
dtbimage	:= $(DTB).dtb

persistent:
	install -d $@

persistent.ubifs: persistent
	@echo "Generating persistent.ubifs..."
	mkfs.ubifs $(MKFSUBIFSOPTS) --root $< --output $@

$(BOARD).ini: ubi.ini.in
	sed -e "s,@KERNEL@,$(kernelimage)," \
	    -e "s,@DTB@,$(dtbimage)," \
	    $< >$@

$(BOARD).ubi: $(BOARD).ini $(kernelimage) $(dtbimage) persistent.ubifs
	@echo "Generating $@..."
	ubinize $(UBINIZEOPTS) --output $@ $<

$(BOARD)-mtd0.bin: $(at91board)-$(at91suffix).bin

$(BOARD)-mtd1.bin: $(BOARD).ubi

bootstrap: $(BOARD)-mtd0.bin

ubi: $(BOARD)-mtd1.bin

tar tgz zip:
	make -f Makefile $(BOARD)-nandflash.$@

install::
	install -d $(DESTDIR)$(PREFIX)/$(BOARD)
	for file in $?; do install $$file $(DESTDIR)/$(PREFIX)/$(BOARD); done

clean::
	rm -f $(at91board)-$(at91suffix).bin initramfs.cpio* $(BOARD).ubi $(BOARD).ini $(BOARD)-mtd*.bin $(BOARD)-nandflash4sam-ba.tcl $(BOARD)-sam-ba.sh $(BOARD)-sam-ba.bat

reallyclean:: clean
	rm -f persistent.ubifs *.ubi *.ini *-mtd*.bin *-linux-image*-ubi-*.bin *.tar *.tgz *.zip
	rm -Rf persistent

mrproper:: reallyclean

file\://%:
	@echo "Copying $(@F)..."
	uri=$@; cp $${uri##*://} .

ssh\://%:
	@echo "Copying $(@F)..."
	uri=$@; scp $(SSHOPTS) $${uri##*://} .

https\://% http\://%:
	@echo "Downloading $(@F)..."
	wget $(WGETOPTS) $@

%.tar:
	tar hcf $@ $?

%.tar.gz %.tgz:
	tar hczf $@ $?

%.zip:
	zip -9 $@ $?

%.bin:
	cp $< $@
