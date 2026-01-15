
uppercase.bin:     file format elf32-littleriscv


Disassembly of section .text:

00010074 <_start>:
   10074:	ffff2517          	auipc	a0,0xffff2
   10078:	f8c50513          	addi	a0,a0,-116 # 2000 <__DATA_BEGIN__>
   1007c:	00050293          	mv	t0,a0

00010080 <loop>:
   10080:	0002c303          	lbu	t1,0(t0)
   10084:	02030263          	beqz	t1,100a8 <end_program>
   10088:	06100393          	li	t2,97
   1008c:	00734a63          	blt	t1,t2,100a0 <next_char>
   10090:	07a00393          	li	t2,122
   10094:	0063c663          	blt	t2,t1,100a0 <next_char>
   10098:	fe030313          	addi	t1,t1,-32
   1009c:	00628023          	sb	t1,0(t0)

000100a0 <next_char>:
   100a0:	00128293          	addi	t0,t0,1
   100a4:	fddff06f          	j	10080 <loop>

000100a8 <end_program>:
   100a8:	0000006f          	j	100a8 <end_program>
