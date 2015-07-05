initramfs_%:
	make -C initramfs $*

initramfs.cpio%:
	make -C initramfs initramfs.cpio$*
	mv initramfs/$@ .

reallyclean::
	make -C initramfs clean

mrproper::
	make -C initramfs mrproper
