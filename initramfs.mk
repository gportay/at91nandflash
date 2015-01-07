initramfs_%:
	make -C initramfs $*

initramfs.cpio:
	make -C initramfs
	ln -sf initramfs/$@

reallyclean::
	make -C initramfs clean

mrproper::
	make -C initramfs mrproper
