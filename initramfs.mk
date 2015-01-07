initramfs_%:
	make -C initramfs $*

reallyclean::
	make -C initramfs clean

mrproper::
	make -C initramfs mrproper
