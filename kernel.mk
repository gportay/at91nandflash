OUTPUTDIR	?= output

ifeq (sama5,$(findstring sama5,$(BOARD)))
karch		:= cortex-a5
kdefconfig	:= sama5_defconfig
KEXTRACFG	+= CONFIG_ARCH_MULTI_V7=y
KEXTRACFG	+= CONFIG_SOC_SAM_V7=y
ifeq (sama5d3,$(findstring sama5d3,$(BOARD)))
ksoc		+= sama5d3
KEXTRACFG	+= CONFIG_SOC_SAMA5D3=y
else
ksoc		+= sama5d4
KEXTRACFG	+= CONFIG_SOC_SAMA5D4=y
endif
else
kdefconfig	:= at91_dt_defconfig
KEXTRACFG	+= CONFIG_SOC_SAM_V4_V5=y
ifeq (sam9,$(findstring sam9,$(BOARD)))
karch		:= arm926
ksoc		+= sam9
KEXTRACFG	+= CONFIG_ARCH_MULTI_V4T=n
KEXTRACFG	+= CONFIG_SOC_AT91RM9200=n
else
ifeq (rm920,$(findstring rm920,$(BOARD)))
karch		:= arm920
ksoc		+= rm92000
KEXTRACFG	+= CONFIG_ARCH_MULTI_V5=n
KEXTRACFG	+= CONFIG_SOC_AT91SAM9=n
else
$(error linux: Unsupported board '$(BOARD)'!)
endif
endif
endif

KIMAGE		?= zImage
KDEFCONFIG	?= $(kdefconfig)
DTB		?= $(shell echo $(BOARD) | sed -e '/at91-sam9/s,at91-,at91,' -e '/at91-sama5d3[1-6]ek/s,at91-,,')
KOUTPUT		?= $(OUTPUTDIR)/linux-$(karch)-$(ksoc)

SILENT:: linux/Makefile

linux/Makefile:
	echo "You need to provide your own kernel sources into the $(CURDIR)/$(@D) directory!" >&2
	echo "Have a look at https://www.kernel.org! or run the command below:" >&2
	echo "$$ git clone git@github.com:torvalds/linux.git $(CURDIR)/$(@D)" >&2
	exit 1

$(KOUTPUT)/.config: linux/Makefile
	@echo "Configuring $(@D) using $(KDEFCONFIG)..."
	install -d $(@D)
	echo "# Generated by at91nandflash." >$(@D)/$(karch)-$(ksoc)_defconfig
	for cfg in $(KEXTRACFG); do echo $$cfg >>$(KOUTPUT)/$(karch)-$(ksoc)_defconfig; done
	make -C linux O=$(CURDIR)/$(KOUTPUT) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) $(KDEFCONFIG)
	cd linux && ARCH=arm scripts/kconfig/merge_config.sh -O $(CURDIR)/$(KOUTPUT) $(CURDIR)/$@ $(CURDIR)/$(KOUTPUT)/$(karch)-$(ksoc)_defconfig
	for cfg in $(KEXTRACFG); do grep -E "$$cfg" $(KOUTPUT)/$(karch)-$(ksoc)_defconfig; done

$(KOUTPUT)/arch/arm/boot/$(KIMAGE): initramfs.cpio $(KOUTPUT)/.config
	@echo "Compiling $(@F)..."
	make -C linux O=$(CURDIR)/$(KOUTPUT) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) CONFIG_INITRAMFS_SOURCE=$(CURDIR)/$< $(KIMAGE)

$(KIMAGE)-initramfs-$(BOARD).bin: $(KOUTPUT)/arch/arm/boot/$(KIMAGE)
	cp $< $@

kernel: $(KIMAGE)-initramfs-$(BOARD).bin

kernel_% linux_%:
	make -C linux O=$(CURDIR)/$(KOUTPUT) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) $*

$(KOUTPUT)/arch/arm/boot/dts/%.dtb:
	make -C linux O=$(CURDIR)/$(KOUTPUT) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) $(<F)

$(DTB).dtb: $(KOUTPUT)/arch/arm/boot/dts/$(DTB).dtb
	cp $< .

dtb: $(DTB).dtb

dtbs: linux_dtbs

kernel_configure linux_configure:
	make -f Makefile $(KOUTPUT)/.config

kernel_compile linux_compile:
	make -f Makefile $(KOUTPUT)/arch/arm/boot/$(KIMAGE)

kernel_clean linux_clean:
	make -C linux mrproper

clean::
	rm -f $(KIMAGE)-initramfs-$(BOARD).bin $(DTB).dtb

cleanall::
	rm -rf $(KOUTPUT)/

mrproper::
	rm -f $(KIMAGE)-initramfs-*.bin *.dtb
	rm -rf $(OUTPUTDIR)/linux-*/
