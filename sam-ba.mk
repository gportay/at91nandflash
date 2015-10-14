sam_ba_bin	?= $(shell uname -m | sed -e 's,^[a-zA-Z0-9+-]*,sam-ba,')

board		:= $(shell echo $(BOARD) | sed -e '/sama5d/s,d3[13456],d3x,')
BOARDTYPE	?= $(shell echo $(board) | sed -e 's,^at91-,at91,' -e '/m10g45/s,m10g45,m10-g45,' -e '/sam9rl/s,rl,rl64,' -e 's,ek$$,-ek,' -e 's,_xplained.*$$,x-ek,' -e '/sama5.*[^x]-ek/s,-ek,x-ek,')
BOARDTYPES	:= at91sam9260-ek at91sam9261-ek at91sam9263-ek at91sam9g10-ek at91sam9g20-ek at91sam9g45-ekes at91sam9m10-ekes at91sam9m10-g45-ek at91sam9n12-ek at91sam9rl64-ek at91sam9g15-ek at91sam9g25-ek at91sam9g35-ek at91sam9x25-ek at91sam9x35-ek at91sama5d3x-xplained at91sama5d3x-ek at91sama5d4x-ek
DEVICE		?= /dev/ttyACM0

.PHONY:: sam-ba

check::
	echo -n "$(BOARD): "
	for board in $(BOARDTYPES); do if test "$$board" = "$(BOARDTYPE)"; then exit 0; fi; done \
		&& ( echo "sam-ba: Mismatch board-type '$(BOARDTYPE)'!" >&2; exit 1 )
	echo "checked!"

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

$(BOARD)-nandflash.tar $(BOARD)-nandflash.tgz $(BOARD)-nandflash.zip: $(BOARD)-mtd0.bin $(BOARD)-mtd1.bin $(BOARD)-nandflash4sam-ba.tcl nandflash4sam-ba.tcl $(BOARD)-sam-ba.sh $(BOARD)-sam-ba.bat

install:: $(BOARD)-nandflash4sam-ba.tcl $(BOARD)-mtd0.bin $(BOARD)-mtd1.bin nandflash4sam-ba.tcl $(BOARD)-sam-ba.sh $(BOARD)-sam-ba.bat

clean::
	rm -f $(BOARD)-nandflash4sam-ba.tcl $(BOARD)-sam-ba.sh $(BOARD)-sam-ba.bat

reallyclean:: clean
	rm -f *-nandflash4sam-ba.tcl *-sam-ba.sh *-sam-ba.bat
