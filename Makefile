CROSS_COMPILE	?= arm-linux-gnueabi-
BOARD		?= at91-sama5d3_xplained
BOARDTYPE	?= $(shell echo $(BOARD) | sed -e 's,^at91-,at91,' -e 's,_.*$$,x-ek,')
BOARDFAMILY	?= $(shell echo $(BOARD) | sed -e 's,_.*$$,,')
BOARDSUFFIX	?= $(shell echo $(BOARD) | sed -e 's,^.*_,_,')

board		:= $(shell echo $(BOARD) | sed -e 's,^at91-,at91,' -e '/sama[0-9]/s,^at91-*,,')
DEFCONFIG	?= $(board)nf_linux_zimage_dt_defconfig

LINUXDIR	?= linux
IMAGE		?= zImage
DTB		?= $(BOARD)

MKFSUBIFSOPTS	?= --leb-size 0x1f000 --min-io-size 0x800 --max-leb-cnt 2048
UBINIZEOPTS	?= --peb-size 0x20000 --min-io-size 0x800 --sub-page-size 0x800

DEVICE		?= /dev/ttyACM0

export CROSS_COMPILE

.PHONY: all clean mrproper

all: bootstrap ubi

at91bootstrap/.config: at91bootstrap/board/$(board)/$(DEFCONFIG)
	@echo -e "\e[1mConfiguring at91bootstrap using $<...\e[0m"
	make -C at91bootstrap $(DEFCONFIG) \
 CONFIG_UBI=y CONFIG_UBI_CRC=y \
 CONFIG_IMG_UBI_VOLNAME="kernel" CONFIG_IMG_SPARE_UBI_VOLNAME="kernel-spare" \
 CONFIG_OF_UBI_VOLNAME="dtb" CONFIG_OF_SPARE_UBI_VOLNAME="dtb-spare"

at91bootstrap/binaries/at91bootstrap.bin: at91bootstrap/.config
	@echo -e "\e[1mCompiling $@...\e[0m"
	make -C at91bootstrap
	touch $@

$(IMAGE):
	@echo -e "\e[1mGenerating $@...\e[0m"
	make -C initramfs kernel
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

$(BOARD)-mtd0.bin: at91bootstrap/binaries/at91bootstrap.bin

$(BOARD)-mtd1.bin: $(BOARD).ubi

bootstrap: $(BOARD)-mtd0.bin

ubi: $(BOARD)-mtd1.bin

$(BOARD)-nandflash4sam-ba.tcl: board-nandflash4sam-ba.tcl.in $(BOARD)-mtd0.bin $(BOARD)-mtd1.bin
	sed -e "s,@BOOTSTRAPFILE@,$(BOARD)-mtd0.bin," \
	    -e "s,@UBIFILE@,$(BOARD)-mtd1.bin," \
	    -e "s,@BOARDFAMILY@,$(BOARDFAMILY)," \
	    -e "s,@BOARDSUFFIX@,$(BOARDSUFFIX)," \
	    $< >$@

sam-ba: $(BOARD)-nandflash4sam-ba.tcl $(BOARD).ubi
	@echo -e "\e[1mFlashing $@ $(DEVICE) using script $< ...\e[0m"
	$@ $(DEVICE) $(BOARDTYPE) $<

%.bin:
	ln -sf $< $@

clean:
	make -C at91bootstrap clean
	make -C initramfs clean
	rm -f $(BOARD).ubi $(BOARD)-mtd*.bin $(BOARD)-nandflash4sam-ba.tcl

mrproper: clean
	make -C at91bootstrap mrproper
	make -C initramfs mrproper
	rm -f $(IMAGE) kernel *.dtb dtb persistant.ubifs *.ubi *.bin
	rm -Rf persistant
