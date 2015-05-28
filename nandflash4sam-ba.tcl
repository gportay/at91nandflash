# ----------------------------------------------------------------------------
#         ATMEL Microcontroller
# ----------------------------------------------------------------------------
# Copyright (c) 2014-2015, Gaël PORTAY <gael.portay@gmail.com>
#                    2014, Atmel Corporation
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# - Redistributions of source code must retain the above copyright notice,
# this list of conditions and the disclaimer below.
#
# Atmel's name may not be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# DISCLAIMER: THIS SOFTWARE IS PROVIDED BY ATMEL "AS IS" AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT ARE
# DISCLAIMED. IN NO EVENT SHALL ATMEL BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
# OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
# EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# ----------------------------------------------------------------------------

################################################################################
#  Main script: Load the Linux UBI RAMFS based System into NandFlash
################################################################################

################################################################################

## Now check for the needed files
if {! [file exists $bootstrapFile]} {
   puts "-E- === AT91Bootstrap file not found ==="
   exit
}

if {! [file exists $ubiFile]} {
   puts "-E- === UBI file not found ==="
   exit
}

set pmeccConfig 0xc0902405

puts "-I- === Initialize the NAND access ==="
NANDFLASH::Init

if {$pmeccConfig != "none"} {
   puts "-I- === Enable PMECC OS Parameters ==="
   NANDFLASH::NandHeaderValue HEADER $pmeccConfig
}

puts "-I- === Erase all the NAND flash blocs and test the erasing ==="
NANDFLASH::EraseAllNandFlash

puts "-I- === Load the bootstrap in the first sector ==="
if {$pmeccConfig != "none"} {
   NANDFLASH::SendBootFilePmeccCmd $bootstrapFile
} else {
   NANDFLASH::sendBootFile $bootstrapFile
}

if {$pmeccConfig != "none"} {
   puts "-I- === Enable trimffs ==="
   NANDFLASH::NandSetTrimffs 1
}

puts "-I- === Load the UBI partition ==="
send_file {NandFlash} "$ubiFile" 0x00020000 0

puts "-I- === DONE. ==="
