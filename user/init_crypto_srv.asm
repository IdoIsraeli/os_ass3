
user/init_crypto_srv.o:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <start>:
#include "syscall.h"

# exec(crypto_srv, argv)
.globl start
start:
        la a0, crypto_srv
   0:	00000517          	auipc	a0,0x0
   4:	00050513          	mv	a0,a0
        la a1, argv
   8:	00000597          	auipc	a1,0x0
   c:	00058593          	mv	a1,a1
        li a7, SYS_exec
  10:	00700893          	li	a7,7
        ecall
  14:	00000073          	ecall

0000000000000018 <exit>:

# for(;;) exit();
exit:
        li a7, SYS_exit
  18:	00200893          	li	a7,2
        ecall
  1c:	00000073          	ecall
        jal exit
  20:	ff9ff0ef          	jal	ra,18 <exit>

0000000000000024 <crypto_srv>:
  24:	7972632f          	0x7972632f
  28:	7470                	ld	a2,232(s0)
  2a:	72735f6f          	jal	t5,35f50 <argv+0x35f1f>
  2e:	0076                	c.slli	zero,0x1d
	...

0000000000000031 <argv>:
	...
