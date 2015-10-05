initramfs/.config:
	make -C initramfs allnoconfig

initramfs_%: initramfs/.config
	make -C initramfs $*

initramfs.cpio: initramfs/.config
	make -C initramfs
	mv initramfs/$@ .

reallyclean::
	make -C initramfs clean

mrproper::
	make -C initramfs mrproper
