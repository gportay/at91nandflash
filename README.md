at91nandflash
=============
**[at91nandflash](https://github.com/gazoo74/at91nandflash)** is a *minimalist* and *ready-to-use* build-system for **[AT91-boards](http://www.at91.com/linux4sam/bin/view/Linux4SAM/)**. It builds from scratch [a91bootstrap](https://github.com/linux4sam/at91bootstrap), a [linux kernel](https://github.com/torvalds/linux) and its *tiny-appended* [initramfs](https://github.com/gazoo74/initramfs) that give you access to the *DBGU* port. Do not forget to provide your own *cross-compiler*.
Prerequisites...
-------------------
First, clone the repository...

    $ git clone git@github.com:gazoo74/at91nandflash.git && cd at91nandflash
... *init* and *update* recursively project *submodules*:

    $ git submodule update --init --recursive
Then fetch [linux](https://github.com/torvalds/linux) sources into the *linux* directory either by cloning one of the multiple git repository...

    $ git clone git@github.com:torvalds/linux.git linux
... or by getting and unarchiving a [kernel](https://www.kernel.org/) archive, pick up a version above 4.1:

    $ wget https://www.kernel.org/pub/linux/kernel/v4.x/linux-4.1.tar.xz && tar xJf linux-4.1.tar.xz && ln -sf linux-4.1 linux
Finally, get a copy of [SAM-BA](http://www.atmel.com/System/BaseForm.aspx?target=tcm:26-42279) and make it available into your *PATH*.
...Ready to go!
--------------
Your are now ready to build and flash your *AT91-board* using *SAM-BA*!

    $ make && make sam-ba
Enjoy!
