CROSS_COMPILE	?= arm-linux-gnueabi-
BOARD		?= at91-sama5d3_xplained

board		:= $(shell echo $(BOARD) | sed -e 's,^at91-,at91,' -e '/sama[0-9]/s,^at91-*,,')
DEFCONFIG	?= $(board)nf_linux_zimage_dt_defconfig

LINUXDIR	?= linux
IMAGE		?= zImage

export CROSS_COMPILE

.PHONY: all clean mrproper

all: bootstrap kernel

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

bootstrap: at91bootstrap/binaries/at91bootstrap.bin

$(IMAGE):
	@echo -e "\e[1mGenerating $@...\e[0m"
	make -C initramfs kernel
	ln -sf initramfs/$@

kernel: $(IMAGE)
	ln -sf initramfs/$< $@

clean:
	make -C at91bootstrap clean
	make -C initramfs clean

mrproper: clean
	make -C at91bootstrap mrproper
	make -C initramfs mrproper
	rm -f $(IMAGE) kernel
