.PNONY: pmtest1 pmtest2 clean

pmtest1:
	nasm pmtest1.asm -o pmtest1.bin
	dd if=pmtest1.bin of=a.img bs=512 count=1 conv=notrunc

pmtest2:
	nasm pmtest2.asm -o pmtest2.bin
	dd if=pmtest2.bin of=a.img bs=512 count=1 conv=notrunc

pmtest3:
	nasm pmtest3.asm -o pmtest3.bin
	dd if=pmtest3.bin of=a.img bs=512 count=1 conv=notrunc

pmtest4:
	nasm pmtest4.asm -o pmtest4.bin
	dd if=pmtest4.bin of=a.img bs=512 count=1 conv=notrunc
clean:
	rm *.txt
