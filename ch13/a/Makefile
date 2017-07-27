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

pmtest3:
	nasm pmtest3.asm -o pmtest3.com
	sudo mount -o loop pm.img /mnt/floppy
	sudo cp pmtest3.com /mnt/floppy
	sudo umount /mnt/floppy

pmtest4:
	nasm pmtest4.asm -o pmtest4.com
	sudo mount -o loop pm.img /mnt/floppy
	sudo cp pmtest4.com /mnt/floppy
	sudo umount /mnt/floppy

clean:
	rm *.txt
