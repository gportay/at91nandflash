#
# Atmel SAMA5 boards
ifeq (sama5,$(findstring sama5,$(BOARD)))
ifeq (sama5d3,$(findstring sama5d3,$(BOARD)))
ksoc		+= sama5d3
else
ksoc		+= sama5d4
endif
#
# Atmel SAM9 boards
else
ifeq (sam9,$(findstring sam9,$(BOARD)))
ksoc		+= sam9
else
ifeq (rm920,$(findstring rm920,$(BOARD)))
ksoc		+= rm92000
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
# Atmel SAMA5 SoC Familly
ifeq (sama5,$(findstring sama5,$(ksoc)))
karch		:= cortex-a5
kdefconfig	:= sama5_defconfig
KEXTRACFG	+= CONFIG_ARCH_MULTI_V7=y
KEXTRACFG	+= CONFIG_SOC_SAM_V7=y
# Atmel SAMA5D3 SoC
ifeq (sama5d3,$(ksoc))
KEXTRACFG	+= CONFIG_SOC_SAMA5D3=y
KEXTRACFG	+= CONFIG_SOC_SAMA5D4=n
# Atmel SAMA5D4 SoC
else
KEXTRACFG	+= CONFIG_SOC_SAMA5D3=n
KEXTRACFG	+= CONFIG_SOC_SAMA5D4=y
endif
#
# Atmel SAM9 SoC Familly
else
kdefconfig	:= at91_dt_defconfig
KEXTRACFG	+= CONFIG_SOC_SAM_V4_V5=y
ifeq (sam9,$(findstring sam9,$(ksoc)))
karch		:= arm926
KEXTRACFG	+= CONFIG_ARCH_MULTI_V4T=n
KEXTRACFG	+= CONFIG_SOC_AT91RM9200=n
else
ifeq (rm920,$(findstring rm920,$(ksoc)))
karch		:= arm920
KEXTRACFG	+= CONFIG_ARCH_MULTI_V5=n
KEXTRACFG	+= CONFIG_SOC_AT91SAM9=n
endif
endif
endif

KDEFCONFIG	?= $(kdefconfig)

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
