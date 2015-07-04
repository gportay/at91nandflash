initramfs_%:
	make -C initramfs $*

initramfs.cpio% initrd.%:
	make -C initramfs $@
	mv initramfs/$@ .

initrd.cpio initrd.cpio.gz initrd.squashfs:

reallyclean::
	make -C initramfs clean

mrproper::
	make -C initramfs mrproper
