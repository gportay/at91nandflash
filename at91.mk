#
# Atmel SAMA5 boards
ifeq (sama5,$(findstring sama5,$(BOARD)))
karch		:= cortex-a5
kdefconfig	:= sama5_defconfig
KEXTRACFG	+= CONFIG_ARCH_MULTI_V7=y
KEXTRACFG	+= CONFIG_SOC_SAM_V7=y
ifeq (sama5d3,$(findstring sama5d3,$(BOARD)))
ksoc		+= sama5d3
KEXTRACFG	+= CONFIG_SOC_SAMA5D3=y
KEXTRACFG	+= CONFIG_SOC_SAMA5D4=n
else
ksoc		+= sama5d4
KEXTRACFG	+= CONFIG_SOC_SAMA5D3=n
KEXTRACFG	+= CONFIG_SOC_SAMA5D4=y
endif
#
# Atmel SAM9 boards
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
#
# Other manufacturer boards based on Atmel SoC
else
ifeq (at91-,$(findstring at91-,$(BOARD)))
include boards/*.mk
#
# Unknown board!
else
$(error linux: Unsupported board '$(BOARD)'!)
endif
endif
endif
endif

#
# Atmel AT91 boards
ifeq (,$(at91board))
board		:= $(shell echo $(BOARD) | sed -e '/sama5d/s,d3[13456],d3x,')
at91board	:= $(shell echo $(board) | sed -e '/sam9[gx][123]5/s,[gx][123]5,x5,' -e '/sam9/s,^at91-,at91,' -e '/sama5/s,^at91-*,,')
at91defconfig	:= nf_linux_image_dt_defconfig
AT91DEFCONFIG	?= $(at91board)$(at91defconfig)
endif

ifeq (,$(kboard))
kboard		:= $(subst _,-,$(at91board))
endif
