.PNONY: pmtest1 pmtest2 clean

pmtest1:
	nasm pmtest1.asm -o pmtest1.com
	sudo mount -o loop pm.img /mnt/floppy
	sudo cp pmtest1.com /mnt/floppy
	sudo umount /mnt/floppy

pmtest2:
	nasm pmtest2.asm -o pmtest2.com
	sudo mount -o loop pm.img /mnt/floppy
	sudo cp pmtest2.com /mnt/floppy
	sudo umount /mnt/floppy

clean:
	rm *.txt
