#!/bin/sh -e

run() {
	board=$1
	shift

	case $board in
	# It's too big to fit into SRAM area. the support maxium size is 4096
	at91-sam9260ek)
		echo "[blacklisted] $board: It's too big to fit into SRAM area. the support maxium size is 4096" >&2
		return 0
		;;
	# Not yet suppported
	at91-sam9g20ek_2mmc|at91-sama5d3x_cmp)
		echo "[blacklisted] $board: Not yet supported!" >&2
		return 0
		;;
	*)
		make BOARD=$board $*
		;;
	esac >/dev/null
	echo "$board: done"
}

for board in at91-sam9260ek at91-sam9261ek at91-sam9263ek at91-sam9m10g45ek at91-sam9n12ek at91-sam9rlek at91-sam9g20ek at91-sam9g20ek_2mmc at91-sam9g15ek at91-sam9g25ek at91-sam9g35ek at91-sam9x25ek at91-sam9x35ek at91-sama5d31ek at91-sama5d33ek at91-sama5d34ek at91-sama5d35ek at91-sama5d36ek at91-sama5d3x_cmp at91-sama5d3_xplained at91-sama5d4ek at91-sama5d4_xplained; do
	run $board $*
done
