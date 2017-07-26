.PNONY: mbr bin clean

mbr:
	dd if=pmtest.bin of=a.img bs=512 count=1 conv=notrunc

bin:
	nasm pmtest.asm -o pmtest.bin

clean:
	rm *.txt
