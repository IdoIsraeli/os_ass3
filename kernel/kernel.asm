
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	94013103          	ld	sp,-1728(sp) # 80008940 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r"(x));
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	95e70713          	addi	a4,a4,-1698 # 800089b0 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r"(x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r"(x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	29c78793          	addi	a5,a5,668 # 80006300 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r"(x));
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r"(x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r"(x));
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r"(x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r"(x));
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc80f>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r"(x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r"(x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dca78793          	addi	a5,a5,-566 # 80000e78 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r"(x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r"(x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r"(x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r"(x));
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r"(x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r"(x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r"(x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r"(x));
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r"(x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	3d8080e7          	jalr	984(ra) # 80002504 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	780080e7          	jalr	1920(ra) # 800008bc <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	96650513          	addi	a0,a0,-1690 # 80010af0 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	95648493          	addi	s1,s1,-1706 # 80010af0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	9e690913          	addi	s2,s2,-1562 # 80010b88 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	81c080e7          	jalr	-2020(ra) # 800019dc <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	186080e7          	jalr	390(ra) # 8000234e <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	ed0080e7          	jalr	-304(ra) # 800020a6 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	29c080e7          	jalr	668(ra) # 800024ae <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	8ca50513          	addi	a0,a0,-1846 # 80010af0 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	8b450513          	addi	a0,a0,-1868 # 80010af0 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	90f72b23          	sw	a5,-1770(a4) # 80010b88 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	55e080e7          	jalr	1374(ra) # 800007ea <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54c080e7          	jalr	1356(ra) # 800007ea <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	540080e7          	jalr	1344(ra) # 800007ea <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	536080e7          	jalr	1334(ra) # 800007ea <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	82450513          	addi	a0,a0,-2012 # 80010af0 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	268080e7          	jalr	616(ra) # 8000255a <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	7f650513          	addi	a0,a0,2038 # 80010af0 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	7d270713          	addi	a4,a4,2002 # 80010af0 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	7a878793          	addi	a5,a5,1960 # 80010af0 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	8127a783          	lw	a5,-2030(a5) # 80010b88 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	76670713          	addi	a4,a4,1894 # 80010af0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	75648493          	addi	s1,s1,1878 # 80010af0 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	71a70713          	addi	a4,a4,1818 # 80010af0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	7af72223          	sw	a5,1956(a4) # 80010b90 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	6de78793          	addi	a5,a5,1758 # 80010af0 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	74c7ab23          	sw	a2,1878(a5) # 80010b8c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	74a50513          	addi	a0,a0,1866 # 80010b88 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	cc4080e7          	jalr	-828(ra) # 8000210a <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	69050513          	addi	a0,a0,1680 # 80010af0 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32a080e7          	jalr	810(ra) # 8000079a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	9e078793          	addi	a5,a5,-1568 # 80020e58 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00010797          	auipc	a5,0x10
    8000054e:	6607a323          	sw	zero,1638(a5) # 80010bb0 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00008717          	auipc	a4,0x8
    80000582:	3ef72123          	sw	a5,994(a4) # 80008960 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00010d97          	auipc	s11,0x10
    800005be:	5f6dad83          	lw	s11,1526(s11) # 80010bb0 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	14050f63          	beqz	a0,80000734 <printf+0x1ac>
    800005da:	4981                	li	s3,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b93          	li	s7,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b17          	auipc	s6,0x8
    800005ea:	a5ab0b13          	addi	s6,s6,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00010517          	auipc	a0,0x10
    800005fc:	5a050513          	addi	a0,a0,1440 # 80010b98 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5d6080e7          	jalr	1494(ra) # 80000bd6 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2985                	addiw	s3,s3,1
    80000624:	013a07b3          	add	a5,s4,s3
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050463          	beqz	a0,80000734 <printf+0x1ac>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2985                	addiw	s3,s3,1
    80000636:	013a07b3          	add	a5,s4,s3
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000642:	cbed                	beqz	a5,80000734 <printf+0x1ac>
    switch(c){
    80000644:	05778a63          	beq	a5,s7,80000698 <printf+0x110>
    80000648:	02fbf663          	bgeu	s7,a5,80000674 <printf+0xec>
    8000064c:	09978863          	beq	a5,s9,800006dc <printf+0x154>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79563          	bne	a5,a4,8000071e <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	09578f63          	beq	a5,s5,80000712 <printf+0x18a>
    80000678:	0b879363          	bne	a5,s8,8000071e <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c95793          	srli	a5,s2,0x3c
    800006c6:	97da                	add	a5,a5,s6
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0912                	slli	s2,s2,0x4
    800006d6:	34fd                	addiw	s1,s1,-1
    800006d8:	f4ed                	bnez	s1,800006c2 <printf+0x13a>
    800006da:	b7a1                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006dc:	f8843783          	ld	a5,-120(s0)
    800006e0:	00878713          	addi	a4,a5,8
    800006e4:	f8e43423          	sd	a4,-120(s0)
    800006e8:	6384                	ld	s1,0(a5)
    800006ea:	cc89                	beqz	s1,80000704 <printf+0x17c>
      for(; *s; s++)
    800006ec:	0004c503          	lbu	a0,0(s1)
    800006f0:	d90d                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f2:	00000097          	auipc	ra,0x0
    800006f6:	b8a080e7          	jalr	-1142(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fa:	0485                	addi	s1,s1,1
    800006fc:	0004c503          	lbu	a0,0(s1)
    80000700:	f96d                	bnez	a0,800006f2 <printf+0x16a>
    80000702:	b705                	j	80000622 <printf+0x9a>
        s = "(null)";
    80000704:	00008497          	auipc	s1,0x8
    80000708:	91c48493          	addi	s1,s1,-1764 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070c:	02800513          	li	a0,40
    80000710:	b7cd                	j	800006f2 <printf+0x16a>
      consputc('%');
    80000712:	8556                	mv	a0,s5
    80000714:	00000097          	auipc	ra,0x0
    80000718:	b68080e7          	jalr	-1176(ra) # 8000027c <consputc>
      break;
    8000071c:	b719                	j	80000622 <printf+0x9a>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b5c080e7          	jalr	-1188(ra) # 8000027c <consputc>
      consputc(c);
    80000728:	8526                	mv	a0,s1
    8000072a:	00000097          	auipc	ra,0x0
    8000072e:	b52080e7          	jalr	-1198(ra) # 8000027c <consputc>
      break;
    80000732:	bdc5                	j	80000622 <printf+0x9a>
  if(locking)
    80000734:	020d9163          	bnez	s11,80000756 <printf+0x1ce>
}
    80000738:	70e6                	ld	ra,120(sp)
    8000073a:	7446                	ld	s0,112(sp)
    8000073c:	74a6                	ld	s1,104(sp)
    8000073e:	7906                	ld	s2,96(sp)
    80000740:	69e6                	ld	s3,88(sp)
    80000742:	6a46                	ld	s4,80(sp)
    80000744:	6aa6                	ld	s5,72(sp)
    80000746:	6b06                	ld	s6,64(sp)
    80000748:	7be2                	ld	s7,56(sp)
    8000074a:	7c42                	ld	s8,48(sp)
    8000074c:	7ca2                	ld	s9,40(sp)
    8000074e:	7d02                	ld	s10,32(sp)
    80000750:	6de2                	ld	s11,24(sp)
    80000752:	6129                	addi	sp,sp,192
    80000754:	8082                	ret
    release(&pr.lock);
    80000756:	00010517          	auipc	a0,0x10
    8000075a:	44250513          	addi	a0,a0,1090 # 80010b98 <pr>
    8000075e:	00000097          	auipc	ra,0x0
    80000762:	52c080e7          	jalr	1324(ra) # 80000c8a <release>
}
    80000766:	bfc9                	j	80000738 <printf+0x1b0>

0000000080000768 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000768:	1101                	addi	sp,sp,-32
    8000076a:	ec06                	sd	ra,24(sp)
    8000076c:	e822                	sd	s0,16(sp)
    8000076e:	e426                	sd	s1,8(sp)
    80000770:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000772:	00010497          	auipc	s1,0x10
    80000776:	42648493          	addi	s1,s1,1062 # 80010b98 <pr>
    8000077a:	00008597          	auipc	a1,0x8
    8000077e:	8be58593          	addi	a1,a1,-1858 # 80008038 <etext+0x38>
    80000782:	8526                	mv	a0,s1
    80000784:	00000097          	auipc	ra,0x0
    80000788:	3c2080e7          	jalr	962(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078c:	4785                	li	a5,1
    8000078e:	cc9c                	sw	a5,24(s1)
}
    80000790:	60e2                	ld	ra,24(sp)
    80000792:	6442                	ld	s0,16(sp)
    80000794:	64a2                	ld	s1,8(sp)
    80000796:	6105                	addi	sp,sp,32
    80000798:	8082                	ret

000000008000079a <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079a:	1141                	addi	sp,sp,-16
    8000079c:	e406                	sd	ra,8(sp)
    8000079e:	e022                	sd	s0,0(sp)
    800007a0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a2:	100007b7          	lui	a5,0x10000
    800007a6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007aa:	f8000713          	li	a4,-128
    800007ae:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b2:	470d                	li	a4,3
    800007b4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007bc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c0:	469d                	li	a3,7
    800007c2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007ca:	00008597          	auipc	a1,0x8
    800007ce:	88e58593          	addi	a1,a1,-1906 # 80008058 <digits+0x18>
    800007d2:	00010517          	auipc	a0,0x10
    800007d6:	3e650513          	addi	a0,a0,998 # 80010bb8 <uart_tx_lock>
    800007da:	00000097          	auipc	ra,0x0
    800007de:	36c080e7          	jalr	876(ra) # 80000b46 <initlock>
}
    800007e2:	60a2                	ld	ra,8(sp)
    800007e4:	6402                	ld	s0,0(sp)
    800007e6:	0141                	addi	sp,sp,16
    800007e8:	8082                	ret

00000000800007ea <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ea:	1101                	addi	sp,sp,-32
    800007ec:	ec06                	sd	ra,24(sp)
    800007ee:	e822                	sd	s0,16(sp)
    800007f0:	e426                	sd	s1,8(sp)
    800007f2:	1000                	addi	s0,sp,32
    800007f4:	84aa                	mv	s1,a0
  push_off();
    800007f6:	00000097          	auipc	ra,0x0
    800007fa:	394080e7          	jalr	916(ra) # 80000b8a <push_off>

  if(panicked){
    800007fe:	00008797          	auipc	a5,0x8
    80000802:	1627a783          	lw	a5,354(a5) # 80008960 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000806:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080a:	c391                	beqz	a5,8000080e <uartputc_sync+0x24>
    for(;;)
    8000080c:	a001                	j	8000080c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000812:	0207f793          	andi	a5,a5,32
    80000816:	dfe5                	beqz	a5,8000080e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000818:	0ff4f513          	andi	a0,s1,255
    8000081c:	100007b7          	lui	a5,0x10000
    80000820:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000824:	00000097          	auipc	ra,0x0
    80000828:	406080e7          	jalr	1030(ra) # 80000c2a <pop_off>
}
    8000082c:	60e2                	ld	ra,24(sp)
    8000082e:	6442                	ld	s0,16(sp)
    80000830:	64a2                	ld	s1,8(sp)
    80000832:	6105                	addi	sp,sp,32
    80000834:	8082                	ret

0000000080000836 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000836:	00008797          	auipc	a5,0x8
    8000083a:	1327b783          	ld	a5,306(a5) # 80008968 <uart_tx_r>
    8000083e:	00008717          	auipc	a4,0x8
    80000842:	13273703          	ld	a4,306(a4) # 80008970 <uart_tx_w>
    80000846:	06f70a63          	beq	a4,a5,800008ba <uartstart+0x84>
{
    8000084a:	7139                	addi	sp,sp,-64
    8000084c:	fc06                	sd	ra,56(sp)
    8000084e:	f822                	sd	s0,48(sp)
    80000850:	f426                	sd	s1,40(sp)
    80000852:	f04a                	sd	s2,32(sp)
    80000854:	ec4e                	sd	s3,24(sp)
    80000856:	e852                	sd	s4,16(sp)
    80000858:	e456                	sd	s5,8(sp)
    8000085a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000860:	00010a17          	auipc	s4,0x10
    80000864:	358a0a13          	addi	s4,s4,856 # 80010bb8 <uart_tx_lock>
    uart_tx_r += 1;
    80000868:	00008497          	auipc	s1,0x8
    8000086c:	10048493          	addi	s1,s1,256 # 80008968 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000870:	00008997          	auipc	s3,0x8
    80000874:	10098993          	addi	s3,s3,256 # 80008970 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000878:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087c:	02077713          	andi	a4,a4,32
    80000880:	c705                	beqz	a4,800008a8 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	01f7f713          	andi	a4,a5,31
    80000886:	9752                	add	a4,a4,s4
    80000888:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088c:	0785                	addi	a5,a5,1
    8000088e:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000890:	8526                	mv	a0,s1
    80000892:	00002097          	auipc	ra,0x2
    80000896:	878080e7          	jalr	-1928(ra) # 8000210a <wakeup>
    
    WriteReg(THR, c);
    8000089a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089e:	609c                	ld	a5,0(s1)
    800008a0:	0009b703          	ld	a4,0(s3)
    800008a4:	fcf71ae3          	bne	a4,a5,80000878 <uartstart+0x42>
  }
}
    800008a8:	70e2                	ld	ra,56(sp)
    800008aa:	7442                	ld	s0,48(sp)
    800008ac:	74a2                	ld	s1,40(sp)
    800008ae:	7902                	ld	s2,32(sp)
    800008b0:	69e2                	ld	s3,24(sp)
    800008b2:	6a42                	ld	s4,16(sp)
    800008b4:	6aa2                	ld	s5,8(sp)
    800008b6:	6121                	addi	sp,sp,64
    800008b8:	8082                	ret
    800008ba:	8082                	ret

00000000800008bc <uartputc>:
{
    800008bc:	7179                	addi	sp,sp,-48
    800008be:	f406                	sd	ra,40(sp)
    800008c0:	f022                	sd	s0,32(sp)
    800008c2:	ec26                	sd	s1,24(sp)
    800008c4:	e84a                	sd	s2,16(sp)
    800008c6:	e44e                	sd	s3,8(sp)
    800008c8:	e052                	sd	s4,0(sp)
    800008ca:	1800                	addi	s0,sp,48
    800008cc:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ce:	00010517          	auipc	a0,0x10
    800008d2:	2ea50513          	addi	a0,a0,746 # 80010bb8 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	300080e7          	jalr	768(ra) # 80000bd6 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	0827a783          	lw	a5,130(a5) # 80008960 <panicked>
    800008e6:	e7c9                	bnez	a5,80000970 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e8:	00008717          	auipc	a4,0x8
    800008ec:	08873703          	ld	a4,136(a4) # 80008970 <uart_tx_w>
    800008f0:	00008797          	auipc	a5,0x8
    800008f4:	0787b783          	ld	a5,120(a5) # 80008968 <uart_tx_r>
    800008f8:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00010997          	auipc	s3,0x10
    80000900:	2bc98993          	addi	s3,s3,700 # 80010bb8 <uart_tx_lock>
    80000904:	00008497          	auipc	s1,0x8
    80000908:	06448493          	addi	s1,s1,100 # 80008968 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00008917          	auipc	s2,0x8
    80000910:	06490913          	addi	s2,s2,100 # 80008970 <uart_tx_w>
    80000914:	00e79f63          	bne	a5,a4,80000932 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000918:	85ce                	mv	a1,s3
    8000091a:	8526                	mv	a0,s1
    8000091c:	00001097          	auipc	ra,0x1
    80000920:	78a080e7          	jalr	1930(ra) # 800020a6 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000924:	00093703          	ld	a4,0(s2)
    80000928:	609c                	ld	a5,0(s1)
    8000092a:	02078793          	addi	a5,a5,32
    8000092e:	fee785e3          	beq	a5,a4,80000918 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000932:	00010497          	auipc	s1,0x10
    80000936:	28648493          	addi	s1,s1,646 # 80010bb8 <uart_tx_lock>
    8000093a:	01f77793          	andi	a5,a4,31
    8000093e:	97a6                	add	a5,a5,s1
    80000940:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000944:	0705                	addi	a4,a4,1
    80000946:	00008797          	auipc	a5,0x8
    8000094a:	02e7b523          	sd	a4,42(a5) # 80008970 <uart_tx_w>
  uartstart();
    8000094e:	00000097          	auipc	ra,0x0
    80000952:	ee8080e7          	jalr	-280(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    80000956:	8526                	mv	a0,s1
    80000958:	00000097          	auipc	ra,0x0
    8000095c:	332080e7          	jalr	818(ra) # 80000c8a <release>
}
    80000960:	70a2                	ld	ra,40(sp)
    80000962:	7402                	ld	s0,32(sp)
    80000964:	64e2                	ld	s1,24(sp)
    80000966:	6942                	ld	s2,16(sp)
    80000968:	69a2                	ld	s3,8(sp)
    8000096a:	6a02                	ld	s4,0(sp)
    8000096c:	6145                	addi	sp,sp,48
    8000096e:	8082                	ret
    for(;;)
    80000970:	a001                	j	80000970 <uartputc+0xb4>

0000000080000972 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000972:	1141                	addi	sp,sp,-16
    80000974:	e422                	sd	s0,8(sp)
    80000976:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000978:	100007b7          	lui	a5,0x10000
    8000097c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000980:	8b85                	andi	a5,a5,1
    80000982:	cb91                	beqz	a5,80000996 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000984:	100007b7          	lui	a5,0x10000
    80000988:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000098c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000990:	6422                	ld	s0,8(sp)
    80000992:	0141                	addi	sp,sp,16
    80000994:	8082                	ret
    return -1;
    80000996:	557d                	li	a0,-1
    80000998:	bfe5                	j	80000990 <uartgetc+0x1e>

000000008000099a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    8000099a:	1101                	addi	sp,sp,-32
    8000099c:	ec06                	sd	ra,24(sp)
    8000099e:	e822                	sd	s0,16(sp)
    800009a0:	e426                	sd	s1,8(sp)
    800009a2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a4:	54fd                	li	s1,-1
    800009a6:	a029                	j	800009b0 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	916080e7          	jalr	-1770(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009b0:	00000097          	auipc	ra,0x0
    800009b4:	fc2080e7          	jalr	-62(ra) # 80000972 <uartgetc>
    if(c == -1)
    800009b8:	fe9518e3          	bne	a0,s1,800009a8 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009bc:	00010497          	auipc	s1,0x10
    800009c0:	1fc48493          	addi	s1,s1,508 # 80010bb8 <uart_tx_lock>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	210080e7          	jalr	528(ra) # 80000bd6 <acquire>
  uartstart();
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	e68080e7          	jalr	-408(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    800009d6:	8526                	mv	a0,s1
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	2b2080e7          	jalr	690(ra) # 80000c8a <release>
}
    800009e0:	60e2                	ld	ra,24(sp)
    800009e2:	6442                	ld	s0,16(sp)
    800009e4:	64a2                	ld	s1,8(sp)
    800009e6:	6105                	addi	sp,sp,32
    800009e8:	8082                	ret

00000000800009ea <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009ea:	1101                	addi	sp,sp,-32
    800009ec:	ec06                	sd	ra,24(sp)
    800009ee:	e822                	sd	s0,16(sp)
    800009f0:	e426                	sd	s1,8(sp)
    800009f2:	e04a                	sd	s2,0(sp)
    800009f4:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f6:	03451793          	slli	a5,a0,0x34
    800009fa:	ebb9                	bnez	a5,80000a50 <kfree+0x66>
    800009fc:	84aa                	mv	s1,a0
    800009fe:	00021797          	auipc	a5,0x21
    80000a02:	5f278793          	addi	a5,a5,1522 # 80021ff0 <end>
    80000a06:	04f56563          	bltu	a0,a5,80000a50 <kfree+0x66>
    80000a0a:	47c5                	li	a5,17
    80000a0c:	07ee                	slli	a5,a5,0x1b
    80000a0e:	04f57163          	bgeu	a0,a5,80000a50 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a12:	6605                	lui	a2,0x1
    80000a14:	4585                	li	a1,1
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	2bc080e7          	jalr	700(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1e:	00010917          	auipc	s2,0x10
    80000a22:	1d290913          	addi	s2,s2,466 # 80010bf0 <kmem>
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	1ae080e7          	jalr	430(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a30:	01893783          	ld	a5,24(s2)
    80000a34:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a36:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	24e080e7          	jalr	590(ra) # 80000c8a <release>
}
    80000a44:	60e2                	ld	ra,24(sp)
    80000a46:	6442                	ld	s0,16(sp)
    80000a48:	64a2                	ld	s1,8(sp)
    80000a4a:	6902                	ld	s2,0(sp)
    80000a4c:	6105                	addi	sp,sp,32
    80000a4e:	8082                	ret
    panic("kfree");
    80000a50:	00007517          	auipc	a0,0x7
    80000a54:	61050513          	addi	a0,a0,1552 # 80008060 <digits+0x20>
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	ae6080e7          	jalr	-1306(ra) # 8000053e <panic>

0000000080000a60 <freerange>:
{
    80000a60:	7179                	addi	sp,sp,-48
    80000a62:	f406                	sd	ra,40(sp)
    80000a64:	f022                	sd	s0,32(sp)
    80000a66:	ec26                	sd	s1,24(sp)
    80000a68:	e84a                	sd	s2,16(sp)
    80000a6a:	e44e                	sd	s3,8(sp)
    80000a6c:	e052                	sd	s4,0(sp)
    80000a6e:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a70:	6785                	lui	a5,0x1
    80000a72:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a76:	94aa                	add	s1,s1,a0
    80000a78:	757d                	lui	a0,0xfffff
    80000a7a:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3a>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5e080e7          	jalr	-162(ra) # 800009ea <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x28>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	13650513          	addi	a0,a0,310 # 80010bf0 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00021517          	auipc	a0,0x21
    80000ad2:	52250513          	addi	a0,a0,1314 # 80021ff0 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f8a080e7          	jalr	-118(ra) # 80000a60 <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	10048493          	addi	s1,s1,256 # 80010bf0 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	0e850513          	addi	a0,a0,232 # 80010bf0 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	0bc50513          	addi	a0,a0,188 # 80010bf0 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e50080e7          	jalr	-432(ra) # 800019c0 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r"(x));
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r"(x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	e1e080e7          	jalr	-482(ra) # 800019c0 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	e12080e7          	jalr	-494(ra) # 800019c0 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	dfa080e7          	jalr	-518(ra) # 800019c0 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	dba080e7          	jalr	-582(ra) # 800019c0 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91c080e7          	jalr	-1764(ra) # 8000053e <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d8e080e7          	jalr	-626(ra) # 800019c0 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r"(x));
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r"(x));
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r"(x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8cc080e7          	jalr	-1844(ra) # 8000053e <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8bc080e7          	jalr	-1860(ra) # 8000053e <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	874080e7          	jalr	-1932(ra) # 8000053e <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	fff6c793          	not	a5,a3
    80000e0c:	9fb9                	addw	a5,a5,a4
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	b30080e7          	jalr	-1232(ra) # 800019b0 <cpuid>
    userinit();      // first user process
    crypto_srv_init(); // crypto server process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	af070713          	addi	a4,a4,-1296 # 80008978 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	b14080e7          	jalr	-1260(ra) # 800019b0 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6da080e7          	jalr	1754(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0e8080e7          	jalr	232(ra) # 80000f9e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	bf4080e7          	jalr	-1036(ra) # 80002ab2 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	47a080e7          	jalr	1146(ra) # 80006340 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	026080e7          	jalr	38(ra) # 80001ef4 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88a080e7          	jalr	-1910(ra) # 80000768 <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69a080e7          	jalr	1690(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68a080e7          	jalr	1674(ra) # 80000588 <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67a080e7          	jalr	1658(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	336080e7          	jalr	822(ra) # 80001254 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	078080e7          	jalr	120(ra) # 80000f9e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	9b6080e7          	jalr	-1610(ra) # 800018e4 <procinit>
    shmem_queue_init(); // shared memory queue
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	8a4080e7          	jalr	-1884(ra) # 800027da <shmem_queue_init>
    trapinit();      // trap vectors
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	b4c080e7          	jalr	-1204(ra) # 80002a8a <trapinit>
    trapinithart();  // install kernel trap vector
    80000f46:	00002097          	auipc	ra,0x2
    80000f4a:	b6c080e7          	jalr	-1172(ra) # 80002ab2 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	3dc080e7          	jalr	988(ra) # 8000632a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f56:	00005097          	auipc	ra,0x5
    80000f5a:	3ea080e7          	jalr	1002(ra) # 80006340 <plicinithart>
    binit();         // buffer cache
    80000f5e:	00002097          	auipc	ra,0x2
    80000f62:	58c080e7          	jalr	1420(ra) # 800034ea <binit>
    iinit();         // inode table
    80000f66:	00003097          	auipc	ra,0x3
    80000f6a:	c30080e7          	jalr	-976(ra) # 80003b96 <iinit>
    fileinit();      // file table
    80000f6e:	00004097          	auipc	ra,0x4
    80000f72:	bce080e7          	jalr	-1074(ra) # 80004b3c <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f76:	00005097          	auipc	ra,0x5
    80000f7a:	4d2080e7          	jalr	1234(ra) # 80006448 <virtio_disk_init>
    userinit();      // first user process
    80000f7e:	00001097          	auipc	ra,0x1
    80000f82:	d58080e7          	jalr	-680(ra) # 80001cd6 <userinit>
    crypto_srv_init(); // crypto server process
    80000f86:	00002097          	auipc	ra,0x2
    80000f8a:	4e2080e7          	jalr	1250(ra) # 80003468 <crypto_srv_init>
    __sync_synchronize();
    80000f8e:	0ff0000f          	fence
    started = 1;
    80000f92:	4785                	li	a5,1
    80000f94:	00008717          	auipc	a4,0x8
    80000f98:	9ef72223          	sw	a5,-1564(a4) # 80008978 <started>
    80000f9c:	bf0d                	j	80000ece <main+0x56>

0000000080000f9e <kvminithart>:
}

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void kvminithart()
{
    80000f9e:	1141                	addi	sp,sp,-16
    80000fa0:	e422                	sd	s0,8(sp)
    80000fa2:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fa4:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000fa8:	00008797          	auipc	a5,0x8
    80000fac:	9d87b783          	ld	a5,-1576(a5) # 80008980 <kernel_pagetable>
    80000fb0:	83b1                	srli	a5,a5,0xc
    80000fb2:	577d                	li	a4,-1
    80000fb4:	177e                	slli	a4,a4,0x3f
    80000fb6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r"(x));
    80000fb8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fbc:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fc0:	6422                	ld	s0,8(sp)
    80000fc2:	0141                	addi	sp,sp,16
    80000fc4:	8082                	ret

0000000080000fc6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc6:	7139                	addi	sp,sp,-64
    80000fc8:	fc06                	sd	ra,56(sp)
    80000fca:	f822                	sd	s0,48(sp)
    80000fcc:	f426                	sd	s1,40(sp)
    80000fce:	f04a                	sd	s2,32(sp)
    80000fd0:	ec4e                	sd	s3,24(sp)
    80000fd2:	e852                	sd	s4,16(sp)
    80000fd4:	e456                	sd	s5,8(sp)
    80000fd6:	e05a                	sd	s6,0(sp)
    80000fd8:	0080                	addi	s0,sp,64
    80000fda:	84aa                	mv	s1,a0
    80000fdc:	89ae                	mv	s3,a1
    80000fde:	8ab2                	mv	s5,a2
  if (va >= MAXVA)
    80000fe0:	57fd                	li	a5,-1
    80000fe2:	83e9                	srli	a5,a5,0x1a
    80000fe4:	4a79                	li	s4,30
    panic("walk");

  for (int level = 2; level > 0; level--)
    80000fe6:	4b31                	li	s6,12
  if (va >= MAXVA)
    80000fe8:	04b7f263          	bgeu	a5,a1,8000102c <walk+0x66>
    panic("walk");
    80000fec:	00007517          	auipc	a0,0x7
    80000ff0:	0e450513          	addi	a0,a0,228 # 800080d0 <digits+0x90>
    80000ff4:	fffff097          	auipc	ra,0xfffff
    80000ff8:	54a080e7          	jalr	1354(ra) # 8000053e <panic>
    {
      pagetable = (pagetable_t)PTE2PA(*pte);
    }
    else
    {
      if (!alloc || (pagetable = (pde_t *)kalloc()) == 0)
    80000ffc:	060a8663          	beqz	s5,80001068 <walk+0xa2>
    80001000:	00000097          	auipc	ra,0x0
    80001004:	ae6080e7          	jalr	-1306(ra) # 80000ae6 <kalloc>
    80001008:	84aa                	mv	s1,a0
    8000100a:	c529                	beqz	a0,80001054 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100c:	6605                	lui	a2,0x1
    8000100e:	4581                	li	a1,0
    80001010:	00000097          	auipc	ra,0x0
    80001014:	cc2080e7          	jalr	-830(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001018:	00c4d793          	srli	a5,s1,0xc
    8000101c:	07aa                	slli	a5,a5,0xa
    8000101e:	0017e793          	ori	a5,a5,1
    80001022:	00f93023          	sd	a5,0(s2)
  for (int level = 2; level > 0; level--)
    80001026:	3a5d                	addiw	s4,s4,-9
    80001028:	036a0063          	beq	s4,s6,80001048 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102c:	0149d933          	srl	s2,s3,s4
    80001030:	1ff97913          	andi	s2,s2,511
    80001034:	090e                	slli	s2,s2,0x3
    80001036:	9926                	add	s2,s2,s1
    if (*pte & PTE_V)
    80001038:	00093483          	ld	s1,0(s2)
    8000103c:	0014f793          	andi	a5,s1,1
    80001040:	dfd5                	beqz	a5,80000ffc <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001042:	80a9                	srli	s1,s1,0xa
    80001044:	04b2                	slli	s1,s1,0xc
    80001046:	b7c5                	j	80001026 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001048:	00c9d513          	srli	a0,s3,0xc
    8000104c:	1ff57513          	andi	a0,a0,511
    80001050:	050e                	slli	a0,a0,0x3
    80001052:	9526                	add	a0,a0,s1
}
    80001054:	70e2                	ld	ra,56(sp)
    80001056:	7442                	ld	s0,48(sp)
    80001058:	74a2                	ld	s1,40(sp)
    8000105a:	7902                	ld	s2,32(sp)
    8000105c:	69e2                	ld	s3,24(sp)
    8000105e:	6a42                	ld	s4,16(sp)
    80001060:	6aa2                	ld	s5,8(sp)
    80001062:	6b02                	ld	s6,0(sp)
    80001064:	6121                	addi	sp,sp,64
    80001066:	8082                	ret
        return 0;
    80001068:	4501                	li	a0,0
    8000106a:	b7ed                	j	80001054 <walk+0x8e>

000000008000106c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if (va >= MAXVA)
    8000106c:	57fd                	li	a5,-1
    8000106e:	83e9                	srli	a5,a5,0x1a
    80001070:	00b7f463          	bgeu	a5,a1,80001078 <walkaddr+0xc>
    return 0;
    80001074:	4501                	li	a0,0
    return 0;
  if ((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001076:	8082                	ret
{
    80001078:	1141                	addi	sp,sp,-16
    8000107a:	e406                	sd	ra,8(sp)
    8000107c:	e022                	sd	s0,0(sp)
    8000107e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001080:	4601                	li	a2,0
    80001082:	00000097          	auipc	ra,0x0
    80001086:	f44080e7          	jalr	-188(ra) # 80000fc6 <walk>
  if (pte == 0)
    8000108a:	c105                	beqz	a0,800010aa <walkaddr+0x3e>
  if ((*pte & PTE_V) == 0)
    8000108c:	611c                	ld	a5,0(a0)
  if ((*pte & PTE_U) == 0)
    8000108e:	0117f693          	andi	a3,a5,17
    80001092:	4745                	li	a4,17
    return 0;
    80001094:	4501                	li	a0,0
  if ((*pte & PTE_U) == 0)
    80001096:	00e68663          	beq	a3,a4,800010a2 <walkaddr+0x36>
}
    8000109a:	60a2                	ld	ra,8(sp)
    8000109c:	6402                	ld	s0,0(sp)
    8000109e:	0141                	addi	sp,sp,16
    800010a0:	8082                	ret
  pa = PTE2PA(*pte);
    800010a2:	00a7d513          	srli	a0,a5,0xa
    800010a6:	0532                	slli	a0,a0,0xc
  return pa;
    800010a8:	bfcd                	j	8000109a <walkaddr+0x2e>
    return 0;
    800010aa:	4501                	li	a0,0
    800010ac:	b7fd                	j	8000109a <walkaddr+0x2e>

00000000800010ae <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010ae:	715d                	addi	sp,sp,-80
    800010b0:	e486                	sd	ra,72(sp)
    800010b2:	e0a2                	sd	s0,64(sp)
    800010b4:	fc26                	sd	s1,56(sp)
    800010b6:	f84a                	sd	s2,48(sp)
    800010b8:	f44e                	sd	s3,40(sp)
    800010ba:	f052                	sd	s4,32(sp)
    800010bc:	ec56                	sd	s5,24(sp)
    800010be:	e85a                	sd	s6,16(sp)
    800010c0:	e45e                	sd	s7,8(sp)
    800010c2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if (size == 0)
    800010c4:	c639                	beqz	a2,80001112 <mappages+0x64>
    800010c6:	8aaa                	mv	s5,a0
    800010c8:	8b3a                	mv	s6,a4
    panic("mappages: size");

  a = PGROUNDDOWN(va);
    800010ca:	77fd                	lui	a5,0xfffff
    800010cc:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d0:	15fd                	addi	a1,a1,-1
    800010d2:	00c589b3          	add	s3,a1,a2
    800010d6:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010da:	8952                	mv	s2,s4
    800010dc:	41468a33          	sub	s4,a3,s4
    if (*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if (a == last)
      break;
    a += PGSIZE;
    800010e0:	6b85                	lui	s7,0x1
    800010e2:	012a04b3          	add	s1,s4,s2
    if ((pte = walk(pagetable, a, 1)) == 0)
    800010e6:	4605                	li	a2,1
    800010e8:	85ca                	mv	a1,s2
    800010ea:	8556                	mv	a0,s5
    800010ec:	00000097          	auipc	ra,0x0
    800010f0:	eda080e7          	jalr	-294(ra) # 80000fc6 <walk>
    800010f4:	cd1d                	beqz	a0,80001132 <mappages+0x84>
    if (*pte & PTE_V)
    800010f6:	611c                	ld	a5,0(a0)
    800010f8:	8b85                	andi	a5,a5,1
    800010fa:	e785                	bnez	a5,80001122 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010fc:	80b1                	srli	s1,s1,0xc
    800010fe:	04aa                	slli	s1,s1,0xa
    80001100:	0164e4b3          	or	s1,s1,s6
    80001104:	0014e493          	ori	s1,s1,1
    80001108:	e104                	sd	s1,0(a0)
    if (a == last)
    8000110a:	05390063          	beq	s2,s3,8000114a <mappages+0x9c>
    a += PGSIZE;
    8000110e:	995e                	add	s2,s2,s7
    if ((pte = walk(pagetable, a, 1)) == 0)
    80001110:	bfc9                	j	800010e2 <mappages+0x34>
    panic("mappages: size");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fc650513          	addi	a0,a0,-58 # 800080d8 <digits+0x98>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	424080e7          	jalr	1060(ra) # 8000053e <panic>
      panic("mappages: remap");
    80001122:	00007517          	auipc	a0,0x7
    80001126:	fc650513          	addi	a0,a0,-58 # 800080e8 <digits+0xa8>
    8000112a:	fffff097          	auipc	ra,0xfffff
    8000112e:	414080e7          	jalr	1044(ra) # 8000053e <panic>
      return -1;
    80001132:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001134:	60a6                	ld	ra,72(sp)
    80001136:	6406                	ld	s0,64(sp)
    80001138:	74e2                	ld	s1,56(sp)
    8000113a:	7942                	ld	s2,48(sp)
    8000113c:	79a2                	ld	s3,40(sp)
    8000113e:	7a02                	ld	s4,32(sp)
    80001140:	6ae2                	ld	s5,24(sp)
    80001142:	6b42                	ld	s6,16(sp)
    80001144:	6ba2                	ld	s7,8(sp)
    80001146:	6161                	addi	sp,sp,80
    80001148:	8082                	ret
  return 0;
    8000114a:	4501                	li	a0,0
    8000114c:	b7e5                	j	80001134 <mappages+0x86>

000000008000114e <kvmmap>:
{
    8000114e:	1141                	addi	sp,sp,-16
    80001150:	e406                	sd	ra,8(sp)
    80001152:	e022                	sd	s0,0(sp)
    80001154:	0800                	addi	s0,sp,16
    80001156:	87b6                	mv	a5,a3
  if (mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001158:	86b2                	mv	a3,a2
    8000115a:	863e                	mv	a2,a5
    8000115c:	00000097          	auipc	ra,0x0
    80001160:	f52080e7          	jalr	-174(ra) # 800010ae <mappages>
    80001164:	e509                	bnez	a0,8000116e <kvmmap+0x20>
}
    80001166:	60a2                	ld	ra,8(sp)
    80001168:	6402                	ld	s0,0(sp)
    8000116a:	0141                	addi	sp,sp,16
    8000116c:	8082                	ret
    panic("kvmmap");
    8000116e:	00007517          	auipc	a0,0x7
    80001172:	f8a50513          	addi	a0,a0,-118 # 800080f8 <digits+0xb8>
    80001176:	fffff097          	auipc	ra,0xfffff
    8000117a:	3c8080e7          	jalr	968(ra) # 8000053e <panic>

000000008000117e <kvmmake>:
{
    8000117e:	1101                	addi	sp,sp,-32
    80001180:	ec06                	sd	ra,24(sp)
    80001182:	e822                	sd	s0,16(sp)
    80001184:	e426                	sd	s1,8(sp)
    80001186:	e04a                	sd	s2,0(sp)
    80001188:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t)kalloc();
    8000118a:	00000097          	auipc	ra,0x0
    8000118e:	95c080e7          	jalr	-1700(ra) # 80000ae6 <kalloc>
    80001192:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001194:	6605                	lui	a2,0x1
    80001196:	4581                	li	a1,0
    80001198:	00000097          	auipc	ra,0x0
    8000119c:	b3a080e7          	jalr	-1222(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a0:	4719                	li	a4,6
    800011a2:	6685                	lui	a3,0x1
    800011a4:	10000637          	lui	a2,0x10000
    800011a8:	100005b7          	lui	a1,0x10000
    800011ac:	8526                	mv	a0,s1
    800011ae:	00000097          	auipc	ra,0x0
    800011b2:	fa0080e7          	jalr	-96(ra) # 8000114e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b6:	4719                	li	a4,6
    800011b8:	6685                	lui	a3,0x1
    800011ba:	10001637          	lui	a2,0x10001
    800011be:	100015b7          	lui	a1,0x10001
    800011c2:	8526                	mv	a0,s1
    800011c4:	00000097          	auipc	ra,0x0
    800011c8:	f8a080e7          	jalr	-118(ra) # 8000114e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011cc:	4719                	li	a4,6
    800011ce:	004006b7          	lui	a3,0x400
    800011d2:	0c000637          	lui	a2,0xc000
    800011d6:	0c0005b7          	lui	a1,0xc000
    800011da:	8526                	mv	a0,s1
    800011dc:	00000097          	auipc	ra,0x0
    800011e0:	f72080e7          	jalr	-142(ra) # 8000114e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext - KERNBASE, PTE_R | PTE_X);
    800011e4:	00007917          	auipc	s2,0x7
    800011e8:	e1c90913          	addi	s2,s2,-484 # 80008000 <etext>
    800011ec:	4729                	li	a4,10
    800011ee:	80007697          	auipc	a3,0x80007
    800011f2:	e1268693          	addi	a3,a3,-494 # 8000 <_entry-0x7fff8000>
    800011f6:	4605                	li	a2,1
    800011f8:	067e                	slli	a2,a2,0x1f
    800011fa:	85b2                	mv	a1,a2
    800011fc:	8526                	mv	a0,s1
    800011fe:	00000097          	auipc	ra,0x0
    80001202:	f50080e7          	jalr	-176(ra) # 8000114e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP - (uint64)etext, PTE_R | PTE_W);
    80001206:	4719                	li	a4,6
    80001208:	46c5                	li	a3,17
    8000120a:	06ee                	slli	a3,a3,0x1b
    8000120c:	412686b3          	sub	a3,a3,s2
    80001210:	864a                	mv	a2,s2
    80001212:	85ca                	mv	a1,s2
    80001214:	8526                	mv	a0,s1
    80001216:	00000097          	auipc	ra,0x0
    8000121a:	f38080e7          	jalr	-200(ra) # 8000114e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000121e:	4729                	li	a4,10
    80001220:	6685                	lui	a3,0x1
    80001222:	00006617          	auipc	a2,0x6
    80001226:	dde60613          	addi	a2,a2,-546 # 80007000 <_trampoline>
    8000122a:	040005b7          	lui	a1,0x4000
    8000122e:	15fd                	addi	a1,a1,-1
    80001230:	05b2                	slli	a1,a1,0xc
    80001232:	8526                	mv	a0,s1
    80001234:	00000097          	auipc	ra,0x0
    80001238:	f1a080e7          	jalr	-230(ra) # 8000114e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123c:	8526                	mv	a0,s1
    8000123e:	00000097          	auipc	ra,0x0
    80001242:	610080e7          	jalr	1552(ra) # 8000184e <proc_mapstacks>
}
    80001246:	8526                	mv	a0,s1
    80001248:	60e2                	ld	ra,24(sp)
    8000124a:	6442                	ld	s0,16(sp)
    8000124c:	64a2                	ld	s1,8(sp)
    8000124e:	6902                	ld	s2,0(sp)
    80001250:	6105                	addi	sp,sp,32
    80001252:	8082                	ret

0000000080001254 <kvminit>:
{
    80001254:	1141                	addi	sp,sp,-16
    80001256:	e406                	sd	ra,8(sp)
    80001258:	e022                	sd	s0,0(sp)
    8000125a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125c:	00000097          	auipc	ra,0x0
    80001260:	f22080e7          	jalr	-222(ra) # 8000117e <kvmmake>
    80001264:	00007797          	auipc	a5,0x7
    80001268:	70a7be23          	sd	a0,1820(a5) # 80008980 <kernel_pagetable>
}
    8000126c:	60a2                	ld	ra,8(sp)
    8000126e:	6402                	ld	s0,0(sp)
    80001270:	0141                	addi	sp,sp,16
    80001272:	8082                	ret

0000000080001274 <uvmunmap>:

// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001274:	715d                	addi	sp,sp,-80
    80001276:	e486                	sd	ra,72(sp)
    80001278:	e0a2                	sd	s0,64(sp)
    8000127a:	fc26                	sd	s1,56(sp)
    8000127c:	f84a                	sd	s2,48(sp)
    8000127e:	f44e                	sd	s3,40(sp)
    80001280:	f052                	sd	s4,32(sp)
    80001282:	ec56                	sd	s5,24(sp)
    80001284:	e85a                	sd	s6,16(sp)
    80001286:	e45e                	sd	s7,8(sp)
    80001288:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if ((va % PGSIZE) != 0)
    8000128a:	03459793          	slli	a5,a1,0x34
    8000128e:	e795                	bnez	a5,800012ba <uvmunmap+0x46>
    80001290:	8a2a                	mv	s4,a0
    80001292:	892e                	mv	s2,a1
    80001294:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    80001296:	0632                	slli	a2,a2,0xc
    80001298:	00b609b3          	add	s3,a2,a1
  {
    if ((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if ((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if (PTE_FLAGS(*pte) == PTE_V)
    8000129c:	4b85                	li	s7,1
  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    8000129e:	6b05                	lui	s6,0x1
    800012a0:	0735e963          	bltu	a1,s3,80001312 <uvmunmap+0x9e>
      uint64 pa = PTE2PA(*pte);
      kfree((void *)pa);
    }
    *pte = 0;
  }
}
    800012a4:	60a6                	ld	ra,72(sp)
    800012a6:	6406                	ld	s0,64(sp)
    800012a8:	74e2                	ld	s1,56(sp)
    800012aa:	7942                	ld	s2,48(sp)
    800012ac:	79a2                	ld	s3,40(sp)
    800012ae:	7a02                	ld	s4,32(sp)
    800012b0:	6ae2                	ld	s5,24(sp)
    800012b2:	6b42                	ld	s6,16(sp)
    800012b4:	6ba2                	ld	s7,8(sp)
    800012b6:	6161                	addi	sp,sp,80
    800012b8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e4650513          	addi	a0,a0,-442 # 80008100 <digits+0xc0>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27c080e7          	jalr	636(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e4e50513          	addi	a0,a0,-434 # 80008118 <digits+0xd8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26c080e7          	jalr	620(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e4e50513          	addi	a0,a0,-434 # 80008128 <digits+0xe8>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25c080e7          	jalr	604(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ea:	00007517          	auipc	a0,0x7
    800012ee:	e5650513          	addi	a0,a0,-426 # 80008140 <digits+0x100>
    800012f2:	fffff097          	auipc	ra,0xfffff
    800012f6:	24c080e7          	jalr	588(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fa:	83a9                	srli	a5,a5,0xa
      kfree((void *)pa);
    800012fc:	00c79513          	slli	a0,a5,0xc
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	6ea080e7          	jalr	1770(ra) # 800009ea <kfree>
    *pte = 0;
    80001308:	0004b023          	sd	zero,0(s1)
  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    8000130c:	995a                	add	s2,s2,s6
    8000130e:	f9397be3          	bgeu	s2,s3,800012a4 <uvmunmap+0x30>
    if ((pte = walk(pagetable, a, 0)) == 0)
    80001312:	4601                	li	a2,0
    80001314:	85ca                	mv	a1,s2
    80001316:	8552                	mv	a0,s4
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	cae080e7          	jalr	-850(ra) # 80000fc6 <walk>
    80001320:	84aa                	mv	s1,a0
    80001322:	d545                	beqz	a0,800012ca <uvmunmap+0x56>
    if ((*pte & PTE_V) == 0)
    80001324:	611c                	ld	a5,0(a0)
    80001326:	0017f713          	andi	a4,a5,1
    8000132a:	db45                	beqz	a4,800012da <uvmunmap+0x66>
    if (PTE_FLAGS(*pte) == PTE_V)
    8000132c:	3ff7f713          	andi	a4,a5,1023
    80001330:	fb770de3          	beq	a4,s7,800012ea <uvmunmap+0x76>
    if (do_free && (PTE_FLAGS(*pte) & PTE_S) == 0)
    80001334:	fc0a8ae3          	beqz	s5,80001308 <uvmunmap+0x94>
    80001338:	1007f713          	andi	a4,a5,256
    8000133c:	f771                	bnez	a4,80001308 <uvmunmap+0x94>
    8000133e:	bf75                	j	800012fa <uvmunmap+0x86>

0000000080001340 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001340:	1101                	addi	sp,sp,-32
    80001342:	ec06                	sd	ra,24(sp)
    80001344:	e822                	sd	s0,16(sp)
    80001346:	e426                	sd	s1,8(sp)
    80001348:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t)kalloc();
    8000134a:	fffff097          	auipc	ra,0xfffff
    8000134e:	79c080e7          	jalr	1948(ra) # 80000ae6 <kalloc>
    80001352:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001354:	c519                	beqz	a0,80001362 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001356:	6605                	lui	a2,0x1
    80001358:	4581                	li	a1,0
    8000135a:	00000097          	auipc	ra,0x0
    8000135e:	978080e7          	jalr	-1672(ra) # 80000cd2 <memset>
  return pagetable;
}
    80001362:	8526                	mv	a0,s1
    80001364:	60e2                	ld	ra,24(sp)
    80001366:	6442                	ld	s0,16(sp)
    80001368:	64a2                	ld	s1,8(sp)
    8000136a:	6105                	addi	sp,sp,32
    8000136c:	8082                	ret

000000008000136e <uvmfirst>:

// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    8000136e:	7179                	addi	sp,sp,-48
    80001370:	f406                	sd	ra,40(sp)
    80001372:	f022                	sd	s0,32(sp)
    80001374:	ec26                	sd	s1,24(sp)
    80001376:	e84a                	sd	s2,16(sp)
    80001378:	e44e                	sd	s3,8(sp)
    8000137a:	e052                	sd	s4,0(sp)
    8000137c:	1800                	addi	s0,sp,48
  char *mem;

  if (sz >= PGSIZE)
    8000137e:	6785                	lui	a5,0x1
    80001380:	04f67863          	bgeu	a2,a5,800013d0 <uvmfirst+0x62>
    80001384:	8a2a                	mv	s4,a0
    80001386:	89ae                	mv	s3,a1
    80001388:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    8000138a:	fffff097          	auipc	ra,0xfffff
    8000138e:	75c080e7          	jalr	1884(ra) # 80000ae6 <kalloc>
    80001392:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001394:	6605                	lui	a2,0x1
    80001396:	4581                	li	a1,0
    80001398:	00000097          	auipc	ra,0x0
    8000139c:	93a080e7          	jalr	-1734(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W | PTE_R | PTE_X | PTE_U);
    800013a0:	4779                	li	a4,30
    800013a2:	86ca                	mv	a3,s2
    800013a4:	6605                	lui	a2,0x1
    800013a6:	4581                	li	a1,0
    800013a8:	8552                	mv	a0,s4
    800013aa:	00000097          	auipc	ra,0x0
    800013ae:	d04080e7          	jalr	-764(ra) # 800010ae <mappages>
  memmove(mem, src, sz);
    800013b2:	8626                	mv	a2,s1
    800013b4:	85ce                	mv	a1,s3
    800013b6:	854a                	mv	a0,s2
    800013b8:	00000097          	auipc	ra,0x0
    800013bc:	976080e7          	jalr	-1674(ra) # 80000d2e <memmove>
}
    800013c0:	70a2                	ld	ra,40(sp)
    800013c2:	7402                	ld	s0,32(sp)
    800013c4:	64e2                	ld	s1,24(sp)
    800013c6:	6942                	ld	s2,16(sp)
    800013c8:	69a2                	ld	s3,8(sp)
    800013ca:	6a02                	ld	s4,0(sp)
    800013cc:	6145                	addi	sp,sp,48
    800013ce:	8082                	ret
    panic("uvmfirst: more than a page");
    800013d0:	00007517          	auipc	a0,0x7
    800013d4:	d8850513          	addi	a0,a0,-632 # 80008158 <digits+0x118>
    800013d8:	fffff097          	auipc	ra,0xfffff
    800013dc:	166080e7          	jalr	358(ra) # 8000053e <panic>

00000000800013e0 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013e0:	1101                	addi	sp,sp,-32
    800013e2:	ec06                	sd	ra,24(sp)
    800013e4:	e822                	sd	s0,16(sp)
    800013e6:	e426                	sd	s1,8(sp)
    800013e8:	1000                	addi	s0,sp,32
  if (newsz >= oldsz)
    return oldsz;
    800013ea:	84ae                	mv	s1,a1
  if (newsz >= oldsz)
    800013ec:	00b67d63          	bgeu	a2,a1,80001406 <uvmdealloc+0x26>
    800013f0:	84b2                	mv	s1,a2

  if (PGROUNDUP(newsz) < PGROUNDUP(oldsz))
    800013f2:	6785                	lui	a5,0x1
    800013f4:	17fd                	addi	a5,a5,-1
    800013f6:	00f60733          	add	a4,a2,a5
    800013fa:	767d                	lui	a2,0xfffff
    800013fc:	8f71                	and	a4,a4,a2
    800013fe:	97ae                	add	a5,a5,a1
    80001400:	8ff1                	and	a5,a5,a2
    80001402:	00f76863          	bltu	a4,a5,80001412 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001406:	8526                	mv	a0,s1
    80001408:	60e2                	ld	ra,24(sp)
    8000140a:	6442                	ld	s0,16(sp)
    8000140c:	64a2                	ld	s1,8(sp)
    8000140e:	6105                	addi	sp,sp,32
    80001410:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001412:	8f99                	sub	a5,a5,a4
    80001414:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001416:	4685                	li	a3,1
    80001418:	0007861b          	sext.w	a2,a5
    8000141c:	85ba                	mv	a1,a4
    8000141e:	00000097          	auipc	ra,0x0
    80001422:	e56080e7          	jalr	-426(ra) # 80001274 <uvmunmap>
    80001426:	b7c5                	j	80001406 <uvmdealloc+0x26>

0000000080001428 <uvmalloc>:
  if (newsz < oldsz)
    80001428:	0ab66563          	bltu	a2,a1,800014d2 <uvmalloc+0xaa>
{
    8000142c:	7139                	addi	sp,sp,-64
    8000142e:	fc06                	sd	ra,56(sp)
    80001430:	f822                	sd	s0,48(sp)
    80001432:	f426                	sd	s1,40(sp)
    80001434:	f04a                	sd	s2,32(sp)
    80001436:	ec4e                	sd	s3,24(sp)
    80001438:	e852                	sd	s4,16(sp)
    8000143a:	e456                	sd	s5,8(sp)
    8000143c:	e05a                	sd	s6,0(sp)
    8000143e:	0080                	addi	s0,sp,64
    80001440:	8aaa                	mv	s5,a0
    80001442:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001444:	6985                	lui	s3,0x1
    80001446:	19fd                	addi	s3,s3,-1
    80001448:	95ce                	add	a1,a1,s3
    8000144a:	79fd                	lui	s3,0xfffff
    8000144c:	0135f9b3          	and	s3,a1,s3
  for (a = oldsz; a < newsz; a += PGSIZE)
    80001450:	08c9f363          	bgeu	s3,a2,800014d6 <uvmalloc+0xae>
    80001454:	894e                	mv	s2,s3
    if (mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R | PTE_U | xperm) != 0)
    80001456:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000145a:	fffff097          	auipc	ra,0xfffff
    8000145e:	68c080e7          	jalr	1676(ra) # 80000ae6 <kalloc>
    80001462:	84aa                	mv	s1,a0
    if (mem == 0)
    80001464:	c51d                	beqz	a0,80001492 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001466:	6605                	lui	a2,0x1
    80001468:	4581                	li	a1,0
    8000146a:	00000097          	auipc	ra,0x0
    8000146e:	868080e7          	jalr	-1944(ra) # 80000cd2 <memset>
    if (mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R | PTE_U | xperm) != 0)
    80001472:	875a                	mv	a4,s6
    80001474:	86a6                	mv	a3,s1
    80001476:	6605                	lui	a2,0x1
    80001478:	85ca                	mv	a1,s2
    8000147a:	8556                	mv	a0,s5
    8000147c:	00000097          	auipc	ra,0x0
    80001480:	c32080e7          	jalr	-974(ra) # 800010ae <mappages>
    80001484:	e90d                	bnez	a0,800014b6 <uvmalloc+0x8e>
  for (a = oldsz; a < newsz; a += PGSIZE)
    80001486:	6785                	lui	a5,0x1
    80001488:	993e                	add	s2,s2,a5
    8000148a:	fd4968e3          	bltu	s2,s4,8000145a <uvmalloc+0x32>
  return newsz;
    8000148e:	8552                	mv	a0,s4
    80001490:	a809                	j	800014a2 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001492:	864e                	mv	a2,s3
    80001494:	85ca                	mv	a1,s2
    80001496:	8556                	mv	a0,s5
    80001498:	00000097          	auipc	ra,0x0
    8000149c:	f48080e7          	jalr	-184(ra) # 800013e0 <uvmdealloc>
      return 0;
    800014a0:	4501                	li	a0,0
}
    800014a2:	70e2                	ld	ra,56(sp)
    800014a4:	7442                	ld	s0,48(sp)
    800014a6:	74a2                	ld	s1,40(sp)
    800014a8:	7902                	ld	s2,32(sp)
    800014aa:	69e2                	ld	s3,24(sp)
    800014ac:	6a42                	ld	s4,16(sp)
    800014ae:	6aa2                	ld	s5,8(sp)
    800014b0:	6b02                	ld	s6,0(sp)
    800014b2:	6121                	addi	sp,sp,64
    800014b4:	8082                	ret
      kfree(mem);
    800014b6:	8526                	mv	a0,s1
    800014b8:	fffff097          	auipc	ra,0xfffff
    800014bc:	532080e7          	jalr	1330(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014c0:	864e                	mv	a2,s3
    800014c2:	85ca                	mv	a1,s2
    800014c4:	8556                	mv	a0,s5
    800014c6:	00000097          	auipc	ra,0x0
    800014ca:	f1a080e7          	jalr	-230(ra) # 800013e0 <uvmdealloc>
      return 0;
    800014ce:	4501                	li	a0,0
    800014d0:	bfc9                	j	800014a2 <uvmalloc+0x7a>
    return oldsz;
    800014d2:	852e                	mv	a0,a1
}
    800014d4:	8082                	ret
  return newsz;
    800014d6:	8532                	mv	a0,a2
    800014d8:	b7e9                	j	800014a2 <uvmalloc+0x7a>

00000000800014da <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void freewalk(pagetable_t pagetable)
{
    800014da:	7179                	addi	sp,sp,-48
    800014dc:	f406                	sd	ra,40(sp)
    800014de:	f022                	sd	s0,32(sp)
    800014e0:	ec26                	sd	s1,24(sp)
    800014e2:	e84a                	sd	s2,16(sp)
    800014e4:	e44e                	sd	s3,8(sp)
    800014e6:	e052                	sd	s4,0(sp)
    800014e8:	1800                	addi	s0,sp,48
    800014ea:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for (int i = 0; i < 512; i++)
    800014ec:	84aa                	mv	s1,a0
    800014ee:	6905                	lui	s2,0x1
    800014f0:	992a                	add	s2,s2,a0
  {
    pte_t pte = pagetable[i];
    if ((pte & PTE_V) && (pte & (PTE_R | PTE_W | PTE_X)) == 0)
    800014f2:	4985                	li	s3,1
    800014f4:	a821                	j	8000150c <freewalk+0x32>
    {
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014f6:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014f8:	0532                	slli	a0,a0,0xc
    800014fa:	00000097          	auipc	ra,0x0
    800014fe:	fe0080e7          	jalr	-32(ra) # 800014da <freewalk>
      pagetable[i] = 0;
    80001502:	0004b023          	sd	zero,0(s1)
  for (int i = 0; i < 512; i++)
    80001506:	04a1                	addi	s1,s1,8
    80001508:	03248163          	beq	s1,s2,8000152a <freewalk+0x50>
    pte_t pte = pagetable[i];
    8000150c:	6088                	ld	a0,0(s1)
    if ((pte & PTE_V) && (pte & (PTE_R | PTE_W | PTE_X)) == 0)
    8000150e:	00f57793          	andi	a5,a0,15
    80001512:	ff3782e3          	beq	a5,s3,800014f6 <freewalk+0x1c>
    }
    else if (pte & PTE_V)
    80001516:	8905                	andi	a0,a0,1
    80001518:	d57d                	beqz	a0,80001506 <freewalk+0x2c>
    {
      panic("freewalk: leaf");
    8000151a:	00007517          	auipc	a0,0x7
    8000151e:	c5e50513          	addi	a0,a0,-930 # 80008178 <digits+0x138>
    80001522:	fffff097          	auipc	ra,0xfffff
    80001526:	01c080e7          	jalr	28(ra) # 8000053e <panic>
    }
  }
  kfree((void *)pagetable);
    8000152a:	8552                	mv	a0,s4
    8000152c:	fffff097          	auipc	ra,0xfffff
    80001530:	4be080e7          	jalr	1214(ra) # 800009ea <kfree>
}
    80001534:	70a2                	ld	ra,40(sp)
    80001536:	7402                	ld	s0,32(sp)
    80001538:	64e2                	ld	s1,24(sp)
    8000153a:	6942                	ld	s2,16(sp)
    8000153c:	69a2                	ld	s3,8(sp)
    8000153e:	6a02                	ld	s4,0(sp)
    80001540:	6145                	addi	sp,sp,48
    80001542:	8082                	ret

0000000080001544 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001544:	1101                	addi	sp,sp,-32
    80001546:	ec06                	sd	ra,24(sp)
    80001548:	e822                	sd	s0,16(sp)
    8000154a:	e426                	sd	s1,8(sp)
    8000154c:	1000                	addi	s0,sp,32
    8000154e:	84aa                	mv	s1,a0
  if (sz > 0)
    80001550:	e999                	bnez	a1,80001566 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz) / PGSIZE, 1);
  freewalk(pagetable);
    80001552:	8526                	mv	a0,s1
    80001554:	00000097          	auipc	ra,0x0
    80001558:	f86080e7          	jalr	-122(ra) # 800014da <freewalk>
}
    8000155c:	60e2                	ld	ra,24(sp)
    8000155e:	6442                	ld	s0,16(sp)
    80001560:	64a2                	ld	s1,8(sp)
    80001562:	6105                	addi	sp,sp,32
    80001564:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz) / PGSIZE, 1);
    80001566:	6605                	lui	a2,0x1
    80001568:	167d                	addi	a2,a2,-1
    8000156a:	962e                	add	a2,a2,a1
    8000156c:	4685                	li	a3,1
    8000156e:	8231                	srli	a2,a2,0xc
    80001570:	4581                	li	a1,0
    80001572:	00000097          	auipc	ra,0x0
    80001576:	d02080e7          	jalr	-766(ra) # 80001274 <uvmunmap>
    8000157a:	bfe1                	j	80001552 <uvmfree+0xe>

000000008000157c <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for (i = 0; i < sz; i += PGSIZE)
    8000157c:	c679                	beqz	a2,8000164a <uvmcopy+0xce>
{
    8000157e:	715d                	addi	sp,sp,-80
    80001580:	e486                	sd	ra,72(sp)
    80001582:	e0a2                	sd	s0,64(sp)
    80001584:	fc26                	sd	s1,56(sp)
    80001586:	f84a                	sd	s2,48(sp)
    80001588:	f44e                	sd	s3,40(sp)
    8000158a:	f052                	sd	s4,32(sp)
    8000158c:	ec56                	sd	s5,24(sp)
    8000158e:	e85a                	sd	s6,16(sp)
    80001590:	e45e                	sd	s7,8(sp)
    80001592:	0880                	addi	s0,sp,80
    80001594:	8b2a                	mv	s6,a0
    80001596:	8aae                	mv	s5,a1
    80001598:	8a32                	mv	s4,a2
  for (i = 0; i < sz; i += PGSIZE)
    8000159a:	4981                	li	s3,0
  {
    if ((pte = walk(old, i, 0)) == 0)
    8000159c:	4601                	li	a2,0
    8000159e:	85ce                	mv	a1,s3
    800015a0:	855a                	mv	a0,s6
    800015a2:	00000097          	auipc	ra,0x0
    800015a6:	a24080e7          	jalr	-1500(ra) # 80000fc6 <walk>
    800015aa:	c531                	beqz	a0,800015f6 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if ((*pte & PTE_V) == 0)
    800015ac:	6118                	ld	a4,0(a0)
    800015ae:	00177793          	andi	a5,a4,1
    800015b2:	cbb1                	beqz	a5,80001606 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015b4:	00a75593          	srli	a1,a4,0xa
    800015b8:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015bc:	3ff77493          	andi	s1,a4,1023
    if ((mem = kalloc()) == 0)
    800015c0:	fffff097          	auipc	ra,0xfffff
    800015c4:	526080e7          	jalr	1318(ra) # 80000ae6 <kalloc>
    800015c8:	892a                	mv	s2,a0
    800015ca:	c939                	beqz	a0,80001620 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char *)pa, PGSIZE);
    800015cc:	6605                	lui	a2,0x1
    800015ce:	85de                	mv	a1,s7
    800015d0:	fffff097          	auipc	ra,0xfffff
    800015d4:	75e080e7          	jalr	1886(ra) # 80000d2e <memmove>
    if (mappages(new, i, PGSIZE, (uint64)mem, flags) != 0)
    800015d8:	8726                	mv	a4,s1
    800015da:	86ca                	mv	a3,s2
    800015dc:	6605                	lui	a2,0x1
    800015de:	85ce                	mv	a1,s3
    800015e0:	8556                	mv	a0,s5
    800015e2:	00000097          	auipc	ra,0x0
    800015e6:	acc080e7          	jalr	-1332(ra) # 800010ae <mappages>
    800015ea:	e515                	bnez	a0,80001616 <uvmcopy+0x9a>
  for (i = 0; i < sz; i += PGSIZE)
    800015ec:	6785                	lui	a5,0x1
    800015ee:	99be                	add	s3,s3,a5
    800015f0:	fb49e6e3          	bltu	s3,s4,8000159c <uvmcopy+0x20>
    800015f4:	a081                	j	80001634 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015f6:	00007517          	auipc	a0,0x7
    800015fa:	b9250513          	addi	a0,a0,-1134 # 80008188 <digits+0x148>
    800015fe:	fffff097          	auipc	ra,0xfffff
    80001602:	f40080e7          	jalr	-192(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    80001606:	00007517          	auipc	a0,0x7
    8000160a:	ba250513          	addi	a0,a0,-1118 # 800081a8 <digits+0x168>
    8000160e:	fffff097          	auipc	ra,0xfffff
    80001612:	f30080e7          	jalr	-208(ra) # 8000053e <panic>
    {
      kfree(mem);
    80001616:	854a                	mv	a0,s2
    80001618:	fffff097          	auipc	ra,0xfffff
    8000161c:	3d2080e7          	jalr	978(ra) # 800009ea <kfree>
    }
  }
  return 0;

err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001620:	4685                	li	a3,1
    80001622:	00c9d613          	srli	a2,s3,0xc
    80001626:	4581                	li	a1,0
    80001628:	8556                	mv	a0,s5
    8000162a:	00000097          	auipc	ra,0x0
    8000162e:	c4a080e7          	jalr	-950(ra) # 80001274 <uvmunmap>
  return -1;
    80001632:	557d                	li	a0,-1
}
    80001634:	60a6                	ld	ra,72(sp)
    80001636:	6406                	ld	s0,64(sp)
    80001638:	74e2                	ld	s1,56(sp)
    8000163a:	7942                	ld	s2,48(sp)
    8000163c:	79a2                	ld	s3,40(sp)
    8000163e:	7a02                	ld	s4,32(sp)
    80001640:	6ae2                	ld	s5,24(sp)
    80001642:	6b42                	ld	s6,16(sp)
    80001644:	6ba2                	ld	s7,8(sp)
    80001646:	6161                	addi	sp,sp,80
    80001648:	8082                	ret
  return 0;
    8000164a:	4501                	li	a0,0
}
    8000164c:	8082                	ret

000000008000164e <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void uvmclear(pagetable_t pagetable, uint64 va)
{
    8000164e:	1141                	addi	sp,sp,-16
    80001650:	e406                	sd	ra,8(sp)
    80001652:	e022                	sd	s0,0(sp)
    80001654:	0800                	addi	s0,sp,16
  pte_t *pte;

  pte = walk(pagetable, va, 0);
    80001656:	4601                	li	a2,0
    80001658:	00000097          	auipc	ra,0x0
    8000165c:	96e080e7          	jalr	-1682(ra) # 80000fc6 <walk>
  if (pte == 0)
    80001660:	c901                	beqz	a0,80001670 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001662:	611c                	ld	a5,0(a0)
    80001664:	9bbd                	andi	a5,a5,-17
    80001666:	e11c                	sd	a5,0(a0)
}
    80001668:	60a2                	ld	ra,8(sp)
    8000166a:	6402                	ld	s0,0(sp)
    8000166c:	0141                	addi	sp,sp,16
    8000166e:	8082                	ret
    panic("uvmclear");
    80001670:	00007517          	auipc	a0,0x7
    80001674:	b5850513          	addi	a0,a0,-1192 # 800081c8 <digits+0x188>
    80001678:	fffff097          	auipc	ra,0xfffff
    8000167c:	ec6080e7          	jalr	-314(ra) # 8000053e <panic>

0000000080001680 <copyout>:
// Return 0 on success, -1 on error.
int copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while (len > 0)
    80001680:	c6bd                	beqz	a3,800016ee <copyout+0x6e>
{
    80001682:	715d                	addi	sp,sp,-80
    80001684:	e486                	sd	ra,72(sp)
    80001686:	e0a2                	sd	s0,64(sp)
    80001688:	fc26                	sd	s1,56(sp)
    8000168a:	f84a                	sd	s2,48(sp)
    8000168c:	f44e                	sd	s3,40(sp)
    8000168e:	f052                	sd	s4,32(sp)
    80001690:	ec56                	sd	s5,24(sp)
    80001692:	e85a                	sd	s6,16(sp)
    80001694:	e45e                	sd	s7,8(sp)
    80001696:	e062                	sd	s8,0(sp)
    80001698:	0880                	addi	s0,sp,80
    8000169a:	8b2a                	mv	s6,a0
    8000169c:	8c2e                	mv	s8,a1
    8000169e:	8a32                	mv	s4,a2
    800016a0:	89b6                	mv	s3,a3
  {
    va0 = PGROUNDDOWN(dstva);
    800016a2:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016a4:	6a85                	lui	s5,0x1
    800016a6:	a015                	j	800016ca <copyout+0x4a>
    if (n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016a8:	9562                	add	a0,a0,s8
    800016aa:	0004861b          	sext.w	a2,s1
    800016ae:	85d2                	mv	a1,s4
    800016b0:	41250533          	sub	a0,a0,s2
    800016b4:	fffff097          	auipc	ra,0xfffff
    800016b8:	67a080e7          	jalr	1658(ra) # 80000d2e <memmove>

    len -= n;
    800016bc:	409989b3          	sub	s3,s3,s1
    src += n;
    800016c0:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016c2:	01590c33          	add	s8,s2,s5
  while (len > 0)
    800016c6:	02098263          	beqz	s3,800016ea <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016ca:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016ce:	85ca                	mv	a1,s2
    800016d0:	855a                	mv	a0,s6
    800016d2:	00000097          	auipc	ra,0x0
    800016d6:	99a080e7          	jalr	-1638(ra) # 8000106c <walkaddr>
    if (pa0 == 0)
    800016da:	cd01                	beqz	a0,800016f2 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016dc:	418904b3          	sub	s1,s2,s8
    800016e0:	94d6                	add	s1,s1,s5
    if (n > len)
    800016e2:	fc99f3e3          	bgeu	s3,s1,800016a8 <copyout+0x28>
    800016e6:	84ce                	mv	s1,s3
    800016e8:	b7c1                	j	800016a8 <copyout+0x28>
  }
  return 0;
    800016ea:	4501                	li	a0,0
    800016ec:	a021                	j	800016f4 <copyout+0x74>
    800016ee:	4501                	li	a0,0
}
    800016f0:	8082                	ret
      return -1;
    800016f2:	557d                	li	a0,-1
}
    800016f4:	60a6                	ld	ra,72(sp)
    800016f6:	6406                	ld	s0,64(sp)
    800016f8:	74e2                	ld	s1,56(sp)
    800016fa:	7942                	ld	s2,48(sp)
    800016fc:	79a2                	ld	s3,40(sp)
    800016fe:	7a02                	ld	s4,32(sp)
    80001700:	6ae2                	ld	s5,24(sp)
    80001702:	6b42                	ld	s6,16(sp)
    80001704:	6ba2                	ld	s7,8(sp)
    80001706:	6c02                	ld	s8,0(sp)
    80001708:	6161                	addi	sp,sp,80
    8000170a:	8082                	ret

000000008000170c <copyin>:
// Return 0 on success, -1 on error.
int copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while (len > 0)
    8000170c:	caa5                	beqz	a3,8000177c <copyin+0x70>
{
    8000170e:	715d                	addi	sp,sp,-80
    80001710:	e486                	sd	ra,72(sp)
    80001712:	e0a2                	sd	s0,64(sp)
    80001714:	fc26                	sd	s1,56(sp)
    80001716:	f84a                	sd	s2,48(sp)
    80001718:	f44e                	sd	s3,40(sp)
    8000171a:	f052                	sd	s4,32(sp)
    8000171c:	ec56                	sd	s5,24(sp)
    8000171e:	e85a                	sd	s6,16(sp)
    80001720:	e45e                	sd	s7,8(sp)
    80001722:	e062                	sd	s8,0(sp)
    80001724:	0880                	addi	s0,sp,80
    80001726:	8b2a                	mv	s6,a0
    80001728:	8a2e                	mv	s4,a1
    8000172a:	8c32                	mv	s8,a2
    8000172c:	89b6                	mv	s3,a3
  {
    va0 = PGROUNDDOWN(srcva);
    8000172e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001730:	6a85                	lui	s5,0x1
    80001732:	a01d                	j	80001758 <copyin+0x4c>
    if (n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001734:	018505b3          	add	a1,a0,s8
    80001738:	0004861b          	sext.w	a2,s1
    8000173c:	412585b3          	sub	a1,a1,s2
    80001740:	8552                	mv	a0,s4
    80001742:	fffff097          	auipc	ra,0xfffff
    80001746:	5ec080e7          	jalr	1516(ra) # 80000d2e <memmove>

    len -= n;
    8000174a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000174e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001750:	01590c33          	add	s8,s2,s5
  while (len > 0)
    80001754:	02098263          	beqz	s3,80001778 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001758:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000175c:	85ca                	mv	a1,s2
    8000175e:	855a                	mv	a0,s6
    80001760:	00000097          	auipc	ra,0x0
    80001764:	90c080e7          	jalr	-1780(ra) # 8000106c <walkaddr>
    if (pa0 == 0)
    80001768:	cd01                	beqz	a0,80001780 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000176a:	418904b3          	sub	s1,s2,s8
    8000176e:	94d6                	add	s1,s1,s5
    if (n > len)
    80001770:	fc99f2e3          	bgeu	s3,s1,80001734 <copyin+0x28>
    80001774:	84ce                	mv	s1,s3
    80001776:	bf7d                	j	80001734 <copyin+0x28>
  }
  return 0;
    80001778:	4501                	li	a0,0
    8000177a:	a021                	j	80001782 <copyin+0x76>
    8000177c:	4501                	li	a0,0
}
    8000177e:	8082                	ret
      return -1;
    80001780:	557d                	li	a0,-1
}
    80001782:	60a6                	ld	ra,72(sp)
    80001784:	6406                	ld	s0,64(sp)
    80001786:	74e2                	ld	s1,56(sp)
    80001788:	7942                	ld	s2,48(sp)
    8000178a:	79a2                	ld	s3,40(sp)
    8000178c:	7a02                	ld	s4,32(sp)
    8000178e:	6ae2                	ld	s5,24(sp)
    80001790:	6b42                	ld	s6,16(sp)
    80001792:	6ba2                	ld	s7,8(sp)
    80001794:	6c02                	ld	s8,0(sp)
    80001796:	6161                	addi	sp,sp,80
    80001798:	8082                	ret

000000008000179a <copyinstr>:
int copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while (got_null == 0 && max > 0)
    8000179a:	c6c5                	beqz	a3,80001842 <copyinstr+0xa8>
{
    8000179c:	715d                	addi	sp,sp,-80
    8000179e:	e486                	sd	ra,72(sp)
    800017a0:	e0a2                	sd	s0,64(sp)
    800017a2:	fc26                	sd	s1,56(sp)
    800017a4:	f84a                	sd	s2,48(sp)
    800017a6:	f44e                	sd	s3,40(sp)
    800017a8:	f052                	sd	s4,32(sp)
    800017aa:	ec56                	sd	s5,24(sp)
    800017ac:	e85a                	sd	s6,16(sp)
    800017ae:	e45e                	sd	s7,8(sp)
    800017b0:	0880                	addi	s0,sp,80
    800017b2:	8a2a                	mv	s4,a0
    800017b4:	8b2e                	mv	s6,a1
    800017b6:	8bb2                	mv	s7,a2
    800017b8:	84b6                	mv	s1,a3
  {
    va0 = PGROUNDDOWN(srcva);
    800017ba:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017bc:	6985                	lui	s3,0x1
    800017be:	a035                	j	800017ea <copyinstr+0x50>
    char *p = (char *)(pa0 + (srcva - va0));
    while (n > 0)
    {
      if (*p == '\0')
      {
        *dst = '\0';
    800017c0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017c4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if (got_null)
    800017c6:	0017b793          	seqz	a5,a5
    800017ca:	40f00533          	neg	a0,a5
  }
  else
  {
    return -1;
  }
}
    800017ce:	60a6                	ld	ra,72(sp)
    800017d0:	6406                	ld	s0,64(sp)
    800017d2:	74e2                	ld	s1,56(sp)
    800017d4:	7942                	ld	s2,48(sp)
    800017d6:	79a2                	ld	s3,40(sp)
    800017d8:	7a02                	ld	s4,32(sp)
    800017da:	6ae2                	ld	s5,24(sp)
    800017dc:	6b42                	ld	s6,16(sp)
    800017de:	6ba2                	ld	s7,8(sp)
    800017e0:	6161                	addi	sp,sp,80
    800017e2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017e4:	01390bb3          	add	s7,s2,s3
  while (got_null == 0 && max > 0)
    800017e8:	c8a9                	beqz	s1,8000183a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017ea:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017ee:	85ca                	mv	a1,s2
    800017f0:	8552                	mv	a0,s4
    800017f2:	00000097          	auipc	ra,0x0
    800017f6:	87a080e7          	jalr	-1926(ra) # 8000106c <walkaddr>
    if (pa0 == 0)
    800017fa:	c131                	beqz	a0,8000183e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017fc:	41790833          	sub	a6,s2,s7
    80001800:	984e                	add	a6,a6,s3
    if (n > max)
    80001802:	0104f363          	bgeu	s1,a6,80001808 <copyinstr+0x6e>
    80001806:	8826                	mv	a6,s1
    char *p = (char *)(pa0 + (srcva - va0));
    80001808:	955e                	add	a0,a0,s7
    8000180a:	41250533          	sub	a0,a0,s2
    while (n > 0)
    8000180e:	fc080be3          	beqz	a6,800017e4 <copyinstr+0x4a>
    80001812:	985a                	add	a6,a6,s6
    80001814:	87da                	mv	a5,s6
      if (*p == '\0')
    80001816:	41650633          	sub	a2,a0,s6
    8000181a:	14fd                	addi	s1,s1,-1
    8000181c:	9b26                	add	s6,s6,s1
    8000181e:	00f60733          	add	a4,a2,a5
    80001822:	00074703          	lbu	a4,0(a4)
    80001826:	df49                	beqz	a4,800017c0 <copyinstr+0x26>
        *dst = *p;
    80001828:	00e78023          	sb	a4,0(a5)
      --max;
    8000182c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001830:	0785                	addi	a5,a5,1
    while (n > 0)
    80001832:	ff0796e3          	bne	a5,a6,8000181e <copyinstr+0x84>
      dst++;
    80001836:	8b42                	mv	s6,a6
    80001838:	b775                	j	800017e4 <copyinstr+0x4a>
    8000183a:	4781                	li	a5,0
    8000183c:	b769                	j	800017c6 <copyinstr+0x2c>
      return -1;
    8000183e:	557d                	li	a0,-1
    80001840:	b779                	j	800017ce <copyinstr+0x34>
  int got_null = 0;
    80001842:	4781                	li	a5,0
  if (got_null)
    80001844:	0017b793          	seqz	a5,a5
    80001848:	40f00533          	neg	a0,a5
}
    8000184c:	8082                	ret

000000008000184e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    8000184e:	7139                	addi	sp,sp,-64
    80001850:	fc06                	sd	ra,56(sp)
    80001852:	f822                	sd	s0,48(sp)
    80001854:	f426                	sd	s1,40(sp)
    80001856:	f04a                	sd	s2,32(sp)
    80001858:	ec4e                	sd	s3,24(sp)
    8000185a:	e852                	sd	s4,16(sp)
    8000185c:	e456                	sd	s5,8(sp)
    8000185e:	e05a                	sd	s6,0(sp)
    80001860:	0080                	addi	s0,sp,64
    80001862:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001864:	00010497          	auipc	s1,0x10
    80001868:	80c48493          	addi	s1,s1,-2036 # 80011070 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    8000186c:	8b26                	mv	s6,s1
    8000186e:	00006a97          	auipc	s5,0x6
    80001872:	792a8a93          	addi	s5,s5,1938 # 80008000 <etext>
    80001876:	04000937          	lui	s2,0x4000
    8000187a:	197d                	addi	s2,s2,-1
    8000187c:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    8000187e:	00015a17          	auipc	s4,0x15
    80001882:	1f2a0a13          	addi	s4,s4,498 # 80016a70 <shmem_queue>
    char *pa = kalloc();
    80001886:	fffff097          	auipc	ra,0xfffff
    8000188a:	260080e7          	jalr	608(ra) # 80000ae6 <kalloc>
    8000188e:	862a                	mv	a2,a0
    if (pa == 0)
    80001890:	c131                	beqz	a0,800018d4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001892:	416485b3          	sub	a1,s1,s6
    80001896:	858d                	srai	a1,a1,0x3
    80001898:	000ab783          	ld	a5,0(s5)
    8000189c:	02f585b3          	mul	a1,a1,a5
    800018a0:	2585                	addiw	a1,a1,1
    800018a2:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018a6:	4719                	li	a4,6
    800018a8:	6685                	lui	a3,0x1
    800018aa:	40b905b3          	sub	a1,s2,a1
    800018ae:	854e                	mv	a0,s3
    800018b0:	00000097          	auipc	ra,0x0
    800018b4:	89e080e7          	jalr	-1890(ra) # 8000114e <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800018b8:	16848493          	addi	s1,s1,360
    800018bc:	fd4495e3          	bne	s1,s4,80001886 <proc_mapstacks+0x38>
  }
}
    800018c0:	70e2                	ld	ra,56(sp)
    800018c2:	7442                	ld	s0,48(sp)
    800018c4:	74a2                	ld	s1,40(sp)
    800018c6:	7902                	ld	s2,32(sp)
    800018c8:	69e2                	ld	s3,24(sp)
    800018ca:	6a42                	ld	s4,16(sp)
    800018cc:	6aa2                	ld	s5,8(sp)
    800018ce:	6b02                	ld	s6,0(sp)
    800018d0:	6121                	addi	sp,sp,64
    800018d2:	8082                	ret
      panic("kalloc");
    800018d4:	00007517          	auipc	a0,0x7
    800018d8:	90450513          	addi	a0,a0,-1788 # 800081d8 <digits+0x198>
    800018dc:	fffff097          	auipc	ra,0xfffff
    800018e0:	c62080e7          	jalr	-926(ra) # 8000053e <panic>

00000000800018e4 <procinit>:

// initialize the proc table.
void procinit(void)
{
    800018e4:	7139                	addi	sp,sp,-64
    800018e6:	fc06                	sd	ra,56(sp)
    800018e8:	f822                	sd	s0,48(sp)
    800018ea:	f426                	sd	s1,40(sp)
    800018ec:	f04a                	sd	s2,32(sp)
    800018ee:	ec4e                	sd	s3,24(sp)
    800018f0:	e852                	sd	s4,16(sp)
    800018f2:	e456                	sd	s5,8(sp)
    800018f4:	e05a                	sd	s6,0(sp)
    800018f6:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8e858593          	addi	a1,a1,-1816 # 800081e0 <digits+0x1a0>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	31050513          	addi	a0,a0,784 # 80010c10 <pid_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001910:	00007597          	auipc	a1,0x7
    80001914:	8d858593          	addi	a1,a1,-1832 # 800081e8 <digits+0x1a8>
    80001918:	0000f517          	auipc	a0,0xf
    8000191c:	31050513          	addi	a0,a0,784 # 80010c28 <wait_lock>
    80001920:	fffff097          	auipc	ra,0xfffff
    80001924:	226080e7          	jalr	550(ra) # 80000b46 <initlock>
  initsleeplock(&fsinit_lock, "fsinit_lock");
    80001928:	00007597          	auipc	a1,0x7
    8000192c:	8d058593          	addi	a1,a1,-1840 # 800081f8 <digits+0x1b8>
    80001930:	0000f517          	auipc	a0,0xf
    80001934:	31050513          	addi	a0,a0,784 # 80010c40 <fsinit_lock>
    80001938:	00003097          	auipc	ra,0x3
    8000193c:	0da080e7          	jalr	218(ra) # 80004a12 <initsleeplock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001940:	0000f497          	auipc	s1,0xf
    80001944:	73048493          	addi	s1,s1,1840 # 80011070 <proc>
  {
    initlock(&p->lock, "proc");
    80001948:	00007b17          	auipc	s6,0x7
    8000194c:	8c0b0b13          	addi	s6,s6,-1856 # 80008208 <digits+0x1c8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001950:	8aa6                	mv	s5,s1
    80001952:	00006a17          	auipc	s4,0x6
    80001956:	6aea0a13          	addi	s4,s4,1710 # 80008000 <etext>
    8000195a:	04000937          	lui	s2,0x4000
    8000195e:	197d                	addi	s2,s2,-1
    80001960:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001962:	00015997          	auipc	s3,0x15
    80001966:	10e98993          	addi	s3,s3,270 # 80016a70 <shmem_queue>
    initlock(&p->lock, "proc");
    8000196a:	85da                	mv	a1,s6
    8000196c:	8526                	mv	a0,s1
    8000196e:	fffff097          	auipc	ra,0xfffff
    80001972:	1d8080e7          	jalr	472(ra) # 80000b46 <initlock>
    p->state = UNUSED;
    80001976:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    8000197a:	415487b3          	sub	a5,s1,s5
    8000197e:	878d                	srai	a5,a5,0x3
    80001980:	000a3703          	ld	a4,0(s4)
    80001984:	02e787b3          	mul	a5,a5,a4
    80001988:	2785                	addiw	a5,a5,1
    8000198a:	00d7979b          	slliw	a5,a5,0xd
    8000198e:	40f907b3          	sub	a5,s2,a5
    80001992:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001994:	16848493          	addi	s1,s1,360
    80001998:	fd3499e3          	bne	s1,s3,8000196a <procinit+0x86>
  }
}
    8000199c:	70e2                	ld	ra,56(sp)
    8000199e:	7442                	ld	s0,48(sp)
    800019a0:	74a2                	ld	s1,40(sp)
    800019a2:	7902                	ld	s2,32(sp)
    800019a4:	69e2                	ld	s3,24(sp)
    800019a6:	6a42                	ld	s4,16(sp)
    800019a8:	6aa2                	ld	s5,8(sp)
    800019aa:	6b02                	ld	s6,0(sp)
    800019ac:	6121                	addi	sp,sp,64
    800019ae:	8082                	ret

00000000800019b0 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    800019b0:	1141                	addi	sp,sp,-16
    800019b2:	e422                	sd	s0,8(sp)
    800019b4:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r"(x));
    800019b6:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019b8:	2501                	sext.w	a0,a0
    800019ba:	6422                	ld	s0,8(sp)
    800019bc:	0141                	addi	sp,sp,16
    800019be:	8082                	ret

00000000800019c0 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    800019c0:	1141                	addi	sp,sp,-16
    800019c2:	e422                	sd	s0,8(sp)
    800019c4:	0800                	addi	s0,sp,16
    800019c6:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019c8:	2781                	sext.w	a5,a5
    800019ca:	079e                	slli	a5,a5,0x7
  return c;
}
    800019cc:	0000f517          	auipc	a0,0xf
    800019d0:	2a450513          	addi	a0,a0,676 # 80010c70 <cpus>
    800019d4:	953e                	add	a0,a0,a5
    800019d6:	6422                	ld	s0,8(sp)
    800019d8:	0141                	addi	sp,sp,16
    800019da:	8082                	ret

00000000800019dc <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019dc:	1101                	addi	sp,sp,-32
    800019de:	ec06                	sd	ra,24(sp)
    800019e0:	e822                	sd	s0,16(sp)
    800019e2:	e426                	sd	s1,8(sp)
    800019e4:	1000                	addi	s0,sp,32
  push_off();
    800019e6:	fffff097          	auipc	ra,0xfffff
    800019ea:	1a4080e7          	jalr	420(ra) # 80000b8a <push_off>
    800019ee:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019f0:	2781                	sext.w	a5,a5
    800019f2:	079e                	slli	a5,a5,0x7
    800019f4:	0000f717          	auipc	a4,0xf
    800019f8:	21c70713          	addi	a4,a4,540 # 80010c10 <pid_lock>
    800019fc:	97ba                	add	a5,a5,a4
    800019fe:	73a4                	ld	s1,96(a5)
  pop_off();
    80001a00:	fffff097          	auipc	ra,0xfffff
    80001a04:	22a080e7          	jalr	554(ra) # 80000c2a <pop_off>
  return p;
}
    80001a08:	8526                	mv	a0,s1
    80001a0a:	60e2                	ld	ra,24(sp)
    80001a0c:	6442                	ld	s0,16(sp)
    80001a0e:	64a2                	ld	s1,8(sp)
    80001a10:	6105                	addi	sp,sp,32
    80001a12:	8082                	ret

0000000080001a14 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001a14:	1141                	addi	sp,sp,-16
    80001a16:	e406                	sd	ra,8(sp)
    80001a18:	e022                	sd	s0,0(sp)
    80001a1a:	0800                	addi	s0,sp,16
  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a1c:	00000097          	auipc	ra,0x0
    80001a20:	fc0080e7          	jalr	-64(ra) # 800019dc <myproc>
    80001a24:	fffff097          	auipc	ra,0xfffff
    80001a28:	266080e7          	jalr	614(ra) # 80000c8a <release>

  acquiresleep(&fsinit_lock);
    80001a2c:	0000f517          	auipc	a0,0xf
    80001a30:	21450513          	addi	a0,a0,532 # 80010c40 <fsinit_lock>
    80001a34:	00003097          	auipc	ra,0x3
    80001a38:	018080e7          	jalr	24(ra) # 80004a4c <acquiresleep>

  if (!fs_initialized)
    80001a3c:	00007797          	auipc	a5,0x7
    80001a40:	f4c7a783          	lw	a5,-180(a5) # 80008988 <fs_initialized>
    80001a44:	c38d                	beqz	a5,80001a66 <forkret+0x52>
    // be run from main().
    fs_initialized = 1;
    fsinit(ROOTDEV);
  }

  releasesleep(&fsinit_lock);
    80001a46:	0000f517          	auipc	a0,0xf
    80001a4a:	1fa50513          	addi	a0,a0,506 # 80010c40 <fsinit_lock>
    80001a4e:	00003097          	auipc	ra,0x3
    80001a52:	054080e7          	jalr	84(ra) # 80004aa2 <releasesleep>

  usertrapret();
    80001a56:	00001097          	auipc	ra,0x1
    80001a5a:	074080e7          	jalr	116(ra) # 80002aca <usertrapret>
}
    80001a5e:	60a2                	ld	ra,8(sp)
    80001a60:	6402                	ld	s0,0(sp)
    80001a62:	0141                	addi	sp,sp,16
    80001a64:	8082                	ret
    fs_initialized = 1;
    80001a66:	4785                	li	a5,1
    80001a68:	00007717          	auipc	a4,0x7
    80001a6c:	f2f72023          	sw	a5,-224(a4) # 80008988 <fs_initialized>
    fsinit(ROOTDEV);
    80001a70:	4505                	li	a0,1
    80001a72:	00002097          	auipc	ra,0x2
    80001a76:	0a4080e7          	jalr	164(ra) # 80003b16 <fsinit>
    80001a7a:	b7f1                	j	80001a46 <forkret+0x32>

0000000080001a7c <allocpid>:
{
    80001a7c:	1101                	addi	sp,sp,-32
    80001a7e:	ec06                	sd	ra,24(sp)
    80001a80:	e822                	sd	s0,16(sp)
    80001a82:	e426                	sd	s1,8(sp)
    80001a84:	e04a                	sd	s2,0(sp)
    80001a86:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a88:	0000f917          	auipc	s2,0xf
    80001a8c:	18890913          	addi	s2,s2,392 # 80010c10 <pid_lock>
    80001a90:	854a                	mv	a0,s2
    80001a92:	fffff097          	auipc	ra,0xfffff
    80001a96:	144080e7          	jalr	324(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a9a:	00007797          	auipc	a5,0x7
    80001a9e:	e1678793          	addi	a5,a5,-490 # 800088b0 <nextpid>
    80001aa2:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001aa4:	0014871b          	addiw	a4,s1,1
    80001aa8:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001aaa:	854a                	mv	a0,s2
    80001aac:	fffff097          	auipc	ra,0xfffff
    80001ab0:	1de080e7          	jalr	478(ra) # 80000c8a <release>
}
    80001ab4:	8526                	mv	a0,s1
    80001ab6:	60e2                	ld	ra,24(sp)
    80001ab8:	6442                	ld	s0,16(sp)
    80001aba:	64a2                	ld	s1,8(sp)
    80001abc:	6902                	ld	s2,0(sp)
    80001abe:	6105                	addi	sp,sp,32
    80001ac0:	8082                	ret

0000000080001ac2 <proc_pagetable>:
{
    80001ac2:	1101                	addi	sp,sp,-32
    80001ac4:	ec06                	sd	ra,24(sp)
    80001ac6:	e822                	sd	s0,16(sp)
    80001ac8:	e426                	sd	s1,8(sp)
    80001aca:	e04a                	sd	s2,0(sp)
    80001acc:	1000                	addi	s0,sp,32
    80001ace:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ad0:	00000097          	auipc	ra,0x0
    80001ad4:	870080e7          	jalr	-1936(ra) # 80001340 <uvmcreate>
    80001ad8:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001ada:	c121                	beqz	a0,80001b1a <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001adc:	4729                	li	a4,10
    80001ade:	00005697          	auipc	a3,0x5
    80001ae2:	52268693          	addi	a3,a3,1314 # 80007000 <_trampoline>
    80001ae6:	6605                	lui	a2,0x1
    80001ae8:	040005b7          	lui	a1,0x4000
    80001aec:	15fd                	addi	a1,a1,-1
    80001aee:	05b2                	slli	a1,a1,0xc
    80001af0:	fffff097          	auipc	ra,0xfffff
    80001af4:	5be080e7          	jalr	1470(ra) # 800010ae <mappages>
    80001af8:	02054863          	bltz	a0,80001b28 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001afc:	4719                	li	a4,6
    80001afe:	05893683          	ld	a3,88(s2)
    80001b02:	6605                	lui	a2,0x1
    80001b04:	020005b7          	lui	a1,0x2000
    80001b08:	15fd                	addi	a1,a1,-1
    80001b0a:	05b6                	slli	a1,a1,0xd
    80001b0c:	8526                	mv	a0,s1
    80001b0e:	fffff097          	auipc	ra,0xfffff
    80001b12:	5a0080e7          	jalr	1440(ra) # 800010ae <mappages>
    80001b16:	02054163          	bltz	a0,80001b38 <proc_pagetable+0x76>
}
    80001b1a:	8526                	mv	a0,s1
    80001b1c:	60e2                	ld	ra,24(sp)
    80001b1e:	6442                	ld	s0,16(sp)
    80001b20:	64a2                	ld	s1,8(sp)
    80001b22:	6902                	ld	s2,0(sp)
    80001b24:	6105                	addi	sp,sp,32
    80001b26:	8082                	ret
    uvmfree(pagetable, 0);
    80001b28:	4581                	li	a1,0
    80001b2a:	8526                	mv	a0,s1
    80001b2c:	00000097          	auipc	ra,0x0
    80001b30:	a18080e7          	jalr	-1512(ra) # 80001544 <uvmfree>
    return 0;
    80001b34:	4481                	li	s1,0
    80001b36:	b7d5                	j	80001b1a <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b38:	4681                	li	a3,0
    80001b3a:	4605                	li	a2,1
    80001b3c:	040005b7          	lui	a1,0x4000
    80001b40:	15fd                	addi	a1,a1,-1
    80001b42:	05b2                	slli	a1,a1,0xc
    80001b44:	8526                	mv	a0,s1
    80001b46:	fffff097          	auipc	ra,0xfffff
    80001b4a:	72e080e7          	jalr	1838(ra) # 80001274 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b4e:	4581                	li	a1,0
    80001b50:	8526                	mv	a0,s1
    80001b52:	00000097          	auipc	ra,0x0
    80001b56:	9f2080e7          	jalr	-1550(ra) # 80001544 <uvmfree>
    return 0;
    80001b5a:	4481                	li	s1,0
    80001b5c:	bf7d                	j	80001b1a <proc_pagetable+0x58>

0000000080001b5e <proc_freepagetable>:
{
    80001b5e:	1101                	addi	sp,sp,-32
    80001b60:	ec06                	sd	ra,24(sp)
    80001b62:	e822                	sd	s0,16(sp)
    80001b64:	e426                	sd	s1,8(sp)
    80001b66:	e04a                	sd	s2,0(sp)
    80001b68:	1000                	addi	s0,sp,32
    80001b6a:	84aa                	mv	s1,a0
    80001b6c:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b6e:	4681                	li	a3,0
    80001b70:	4605                	li	a2,1
    80001b72:	040005b7          	lui	a1,0x4000
    80001b76:	15fd                	addi	a1,a1,-1
    80001b78:	05b2                	slli	a1,a1,0xc
    80001b7a:	fffff097          	auipc	ra,0xfffff
    80001b7e:	6fa080e7          	jalr	1786(ra) # 80001274 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b82:	4681                	li	a3,0
    80001b84:	4605                	li	a2,1
    80001b86:	020005b7          	lui	a1,0x2000
    80001b8a:	15fd                	addi	a1,a1,-1
    80001b8c:	05b6                	slli	a1,a1,0xd
    80001b8e:	8526                	mv	a0,s1
    80001b90:	fffff097          	auipc	ra,0xfffff
    80001b94:	6e4080e7          	jalr	1764(ra) # 80001274 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b98:	85ca                	mv	a1,s2
    80001b9a:	8526                	mv	a0,s1
    80001b9c:	00000097          	auipc	ra,0x0
    80001ba0:	9a8080e7          	jalr	-1624(ra) # 80001544 <uvmfree>
}
    80001ba4:	60e2                	ld	ra,24(sp)
    80001ba6:	6442                	ld	s0,16(sp)
    80001ba8:	64a2                	ld	s1,8(sp)
    80001baa:	6902                	ld	s2,0(sp)
    80001bac:	6105                	addi	sp,sp,32
    80001bae:	8082                	ret

0000000080001bb0 <freeproc>:
{
    80001bb0:	1101                	addi	sp,sp,-32
    80001bb2:	ec06                	sd	ra,24(sp)
    80001bb4:	e822                	sd	s0,16(sp)
    80001bb6:	e426                	sd	s1,8(sp)
    80001bb8:	1000                	addi	s0,sp,32
    80001bba:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001bbc:	6d28                	ld	a0,88(a0)
    80001bbe:	c509                	beqz	a0,80001bc8 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001bc0:	fffff097          	auipc	ra,0xfffff
    80001bc4:	e2a080e7          	jalr	-470(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001bc8:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001bcc:	68a8                	ld	a0,80(s1)
    80001bce:	c511                	beqz	a0,80001bda <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001bd0:	64ac                	ld	a1,72(s1)
    80001bd2:	00000097          	auipc	ra,0x0
    80001bd6:	f8c080e7          	jalr	-116(ra) # 80001b5e <proc_freepagetable>
  p->pagetable = 0;
    80001bda:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bde:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001be2:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001be6:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bea:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bee:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bf2:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bf6:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bfa:	0004ac23          	sw	zero,24(s1)
}
    80001bfe:	60e2                	ld	ra,24(sp)
    80001c00:	6442                	ld	s0,16(sp)
    80001c02:	64a2                	ld	s1,8(sp)
    80001c04:	6105                	addi	sp,sp,32
    80001c06:	8082                	ret

0000000080001c08 <allocproc>:
{
    80001c08:	1101                	addi	sp,sp,-32
    80001c0a:	ec06                	sd	ra,24(sp)
    80001c0c:	e822                	sd	s0,16(sp)
    80001c0e:	e426                	sd	s1,8(sp)
    80001c10:	e04a                	sd	s2,0(sp)
    80001c12:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001c14:	0000f497          	auipc	s1,0xf
    80001c18:	45c48493          	addi	s1,s1,1116 # 80011070 <proc>
    80001c1c:	00015917          	auipc	s2,0x15
    80001c20:	e5490913          	addi	s2,s2,-428 # 80016a70 <shmem_queue>
    acquire(&p->lock);
    80001c24:	8526                	mv	a0,s1
    80001c26:	fffff097          	auipc	ra,0xfffff
    80001c2a:	fb0080e7          	jalr	-80(ra) # 80000bd6 <acquire>
    if (p->state == UNUSED)
    80001c2e:	4c9c                	lw	a5,24(s1)
    80001c30:	cf81                	beqz	a5,80001c48 <allocproc+0x40>
      release(&p->lock);
    80001c32:	8526                	mv	a0,s1
    80001c34:	fffff097          	auipc	ra,0xfffff
    80001c38:	056080e7          	jalr	86(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001c3c:	16848493          	addi	s1,s1,360
    80001c40:	ff2492e3          	bne	s1,s2,80001c24 <allocproc+0x1c>
  return 0;
    80001c44:	4481                	li	s1,0
    80001c46:	a889                	j	80001c98 <allocproc+0x90>
  p->pid = allocpid();
    80001c48:	00000097          	auipc	ra,0x0
    80001c4c:	e34080e7          	jalr	-460(ra) # 80001a7c <allocpid>
    80001c50:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c52:	4785                	li	a5,1
    80001c54:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c56:	fffff097          	auipc	ra,0xfffff
    80001c5a:	e90080e7          	jalr	-368(ra) # 80000ae6 <kalloc>
    80001c5e:	892a                	mv	s2,a0
    80001c60:	eca8                	sd	a0,88(s1)
    80001c62:	c131                	beqz	a0,80001ca6 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c64:	8526                	mv	a0,s1
    80001c66:	00000097          	auipc	ra,0x0
    80001c6a:	e5c080e7          	jalr	-420(ra) # 80001ac2 <proc_pagetable>
    80001c6e:	892a                	mv	s2,a0
    80001c70:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c72:	c531                	beqz	a0,80001cbe <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c74:	07000613          	li	a2,112
    80001c78:	4581                	li	a1,0
    80001c7a:	06048513          	addi	a0,s1,96
    80001c7e:	fffff097          	auipc	ra,0xfffff
    80001c82:	054080e7          	jalr	84(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c86:	00000797          	auipc	a5,0x0
    80001c8a:	d8e78793          	addi	a5,a5,-626 # 80001a14 <forkret>
    80001c8e:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c90:	60bc                	ld	a5,64(s1)
    80001c92:	6705                	lui	a4,0x1
    80001c94:	97ba                	add	a5,a5,a4
    80001c96:	f4bc                	sd	a5,104(s1)
}
    80001c98:	8526                	mv	a0,s1
    80001c9a:	60e2                	ld	ra,24(sp)
    80001c9c:	6442                	ld	s0,16(sp)
    80001c9e:	64a2                	ld	s1,8(sp)
    80001ca0:	6902                	ld	s2,0(sp)
    80001ca2:	6105                	addi	sp,sp,32
    80001ca4:	8082                	ret
    freeproc(p);
    80001ca6:	8526                	mv	a0,s1
    80001ca8:	00000097          	auipc	ra,0x0
    80001cac:	f08080e7          	jalr	-248(ra) # 80001bb0 <freeproc>
    release(&p->lock);
    80001cb0:	8526                	mv	a0,s1
    80001cb2:	fffff097          	auipc	ra,0xfffff
    80001cb6:	fd8080e7          	jalr	-40(ra) # 80000c8a <release>
    return 0;
    80001cba:	84ca                	mv	s1,s2
    80001cbc:	bff1                	j	80001c98 <allocproc+0x90>
    freeproc(p);
    80001cbe:	8526                	mv	a0,s1
    80001cc0:	00000097          	auipc	ra,0x0
    80001cc4:	ef0080e7          	jalr	-272(ra) # 80001bb0 <freeproc>
    release(&p->lock);
    80001cc8:	8526                	mv	a0,s1
    80001cca:	fffff097          	auipc	ra,0xfffff
    80001cce:	fc0080e7          	jalr	-64(ra) # 80000c8a <release>
    return 0;
    80001cd2:	84ca                	mv	s1,s2
    80001cd4:	b7d1                	j	80001c98 <allocproc+0x90>

0000000080001cd6 <userinit>:
{
    80001cd6:	1101                	addi	sp,sp,-32
    80001cd8:	ec06                	sd	ra,24(sp)
    80001cda:	e822                	sd	s0,16(sp)
    80001cdc:	e426                	sd	s1,8(sp)
    80001cde:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ce0:	00000097          	auipc	ra,0x0
    80001ce4:	f28080e7          	jalr	-216(ra) # 80001c08 <allocproc>
    80001ce8:	84aa                	mv	s1,a0
  initproc = p;
    80001cea:	00007797          	auipc	a5,0x7
    80001cee:	caa7b323          	sd	a0,-858(a5) # 80008990 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cf2:	03400613          	li	a2,52
    80001cf6:	00007597          	auipc	a1,0x7
    80001cfa:	bca58593          	addi	a1,a1,-1078 # 800088c0 <initcode>
    80001cfe:	6928                	ld	a0,80(a0)
    80001d00:	fffff097          	auipc	ra,0xfffff
    80001d04:	66e080e7          	jalr	1646(ra) # 8000136e <uvmfirst>
  p->sz = PGSIZE;
    80001d08:	6785                	lui	a5,0x1
    80001d0a:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001d0c:	6cb8                	ld	a4,88(s1)
    80001d0e:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001d12:	6cb8                	ld	a4,88(s1)
    80001d14:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d16:	4641                	li	a2,16
    80001d18:	00006597          	auipc	a1,0x6
    80001d1c:	4f858593          	addi	a1,a1,1272 # 80008210 <digits+0x1d0>
    80001d20:	15848513          	addi	a0,s1,344
    80001d24:	fffff097          	auipc	ra,0xfffff
    80001d28:	0f8080e7          	jalr	248(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001d2c:	00006517          	auipc	a0,0x6
    80001d30:	4f450513          	addi	a0,a0,1268 # 80008220 <digits+0x1e0>
    80001d34:	00003097          	auipc	ra,0x3
    80001d38:	804080e7          	jalr	-2044(ra) # 80004538 <namei>
    80001d3c:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d40:	478d                	li	a5,3
    80001d42:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d44:	8526                	mv	a0,s1
    80001d46:	fffff097          	auipc	ra,0xfffff
    80001d4a:	f44080e7          	jalr	-188(ra) # 80000c8a <release>
}
    80001d4e:	60e2                	ld	ra,24(sp)
    80001d50:	6442                	ld	s0,16(sp)
    80001d52:	64a2                	ld	s1,8(sp)
    80001d54:	6105                	addi	sp,sp,32
    80001d56:	8082                	ret

0000000080001d58 <growproc>:
{
    80001d58:	1101                	addi	sp,sp,-32
    80001d5a:	ec06                	sd	ra,24(sp)
    80001d5c:	e822                	sd	s0,16(sp)
    80001d5e:	e426                	sd	s1,8(sp)
    80001d60:	e04a                	sd	s2,0(sp)
    80001d62:	1000                	addi	s0,sp,32
    80001d64:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d66:	00000097          	auipc	ra,0x0
    80001d6a:	c76080e7          	jalr	-906(ra) # 800019dc <myproc>
    80001d6e:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d70:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001d72:	01204c63          	bgtz	s2,80001d8a <growproc+0x32>
  else if (n < 0)
    80001d76:	02094663          	bltz	s2,80001da2 <growproc+0x4a>
  p->sz = sz;
    80001d7a:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d7c:	4501                	li	a0,0
}
    80001d7e:	60e2                	ld	ra,24(sp)
    80001d80:	6442                	ld	s0,16(sp)
    80001d82:	64a2                	ld	s1,8(sp)
    80001d84:	6902                	ld	s2,0(sp)
    80001d86:	6105                	addi	sp,sp,32
    80001d88:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001d8a:	4691                	li	a3,4
    80001d8c:	00b90633          	add	a2,s2,a1
    80001d90:	6928                	ld	a0,80(a0)
    80001d92:	fffff097          	auipc	ra,0xfffff
    80001d96:	696080e7          	jalr	1686(ra) # 80001428 <uvmalloc>
    80001d9a:	85aa                	mv	a1,a0
    80001d9c:	fd79                	bnez	a0,80001d7a <growproc+0x22>
      return -1;
    80001d9e:	557d                	li	a0,-1
    80001da0:	bff9                	j	80001d7e <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001da2:	00b90633          	add	a2,s2,a1
    80001da6:	6928                	ld	a0,80(a0)
    80001da8:	fffff097          	auipc	ra,0xfffff
    80001dac:	638080e7          	jalr	1592(ra) # 800013e0 <uvmdealloc>
    80001db0:	85aa                	mv	a1,a0
    80001db2:	b7e1                	j	80001d7a <growproc+0x22>

0000000080001db4 <fork>:
{
    80001db4:	7139                	addi	sp,sp,-64
    80001db6:	fc06                	sd	ra,56(sp)
    80001db8:	f822                	sd	s0,48(sp)
    80001dba:	f426                	sd	s1,40(sp)
    80001dbc:	f04a                	sd	s2,32(sp)
    80001dbe:	ec4e                	sd	s3,24(sp)
    80001dc0:	e852                	sd	s4,16(sp)
    80001dc2:	e456                	sd	s5,8(sp)
    80001dc4:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001dc6:	00000097          	auipc	ra,0x0
    80001dca:	c16080e7          	jalr	-1002(ra) # 800019dc <myproc>
    80001dce:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001dd0:	00000097          	auipc	ra,0x0
    80001dd4:	e38080e7          	jalr	-456(ra) # 80001c08 <allocproc>
    80001dd8:	10050c63          	beqz	a0,80001ef0 <fork+0x13c>
    80001ddc:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001dde:	048ab603          	ld	a2,72(s5)
    80001de2:	692c                	ld	a1,80(a0)
    80001de4:	050ab503          	ld	a0,80(s5)
    80001de8:	fffff097          	auipc	ra,0xfffff
    80001dec:	794080e7          	jalr	1940(ra) # 8000157c <uvmcopy>
    80001df0:	04054863          	bltz	a0,80001e40 <fork+0x8c>
  np->sz = p->sz;
    80001df4:	048ab783          	ld	a5,72(s5)
    80001df8:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001dfc:	058ab683          	ld	a3,88(s5)
    80001e00:	87b6                	mv	a5,a3
    80001e02:	058a3703          	ld	a4,88(s4)
    80001e06:	12068693          	addi	a3,a3,288
    80001e0a:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e0e:	6788                	ld	a0,8(a5)
    80001e10:	6b8c                	ld	a1,16(a5)
    80001e12:	6f90                	ld	a2,24(a5)
    80001e14:	01073023          	sd	a6,0(a4)
    80001e18:	e708                	sd	a0,8(a4)
    80001e1a:	eb0c                	sd	a1,16(a4)
    80001e1c:	ef10                	sd	a2,24(a4)
    80001e1e:	02078793          	addi	a5,a5,32
    80001e22:	02070713          	addi	a4,a4,32
    80001e26:	fed792e3          	bne	a5,a3,80001e0a <fork+0x56>
  np->trapframe->a0 = 0;
    80001e2a:	058a3783          	ld	a5,88(s4)
    80001e2e:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001e32:	0d0a8493          	addi	s1,s5,208
    80001e36:	0d0a0913          	addi	s2,s4,208
    80001e3a:	150a8993          	addi	s3,s5,336
    80001e3e:	a00d                	j	80001e60 <fork+0xac>
    freeproc(np);
    80001e40:	8552                	mv	a0,s4
    80001e42:	00000097          	auipc	ra,0x0
    80001e46:	d6e080e7          	jalr	-658(ra) # 80001bb0 <freeproc>
    release(&np->lock);
    80001e4a:	8552                	mv	a0,s4
    80001e4c:	fffff097          	auipc	ra,0xfffff
    80001e50:	e3e080e7          	jalr	-450(ra) # 80000c8a <release>
    return -1;
    80001e54:	597d                	li	s2,-1
    80001e56:	a059                	j	80001edc <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001e58:	04a1                	addi	s1,s1,8
    80001e5a:	0921                	addi	s2,s2,8
    80001e5c:	01348b63          	beq	s1,s3,80001e72 <fork+0xbe>
    if (p->ofile[i])
    80001e60:	6088                	ld	a0,0(s1)
    80001e62:	d97d                	beqz	a0,80001e58 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e64:	00003097          	auipc	ra,0x3
    80001e68:	d6a080e7          	jalr	-662(ra) # 80004bce <filedup>
    80001e6c:	00a93023          	sd	a0,0(s2)
    80001e70:	b7e5                	j	80001e58 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e72:	150ab503          	ld	a0,336(s5)
    80001e76:	00002097          	auipc	ra,0x2
    80001e7a:	ede080e7          	jalr	-290(ra) # 80003d54 <idup>
    80001e7e:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e82:	4641                	li	a2,16
    80001e84:	158a8593          	addi	a1,s5,344
    80001e88:	158a0513          	addi	a0,s4,344
    80001e8c:	fffff097          	auipc	ra,0xfffff
    80001e90:	f90080e7          	jalr	-112(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e94:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e98:	8552                	mv	a0,s4
    80001e9a:	fffff097          	auipc	ra,0xfffff
    80001e9e:	df0080e7          	jalr	-528(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001ea2:	0000f497          	auipc	s1,0xf
    80001ea6:	d8648493          	addi	s1,s1,-634 # 80010c28 <wait_lock>
    80001eaa:	8526                	mv	a0,s1
    80001eac:	fffff097          	auipc	ra,0xfffff
    80001eb0:	d2a080e7          	jalr	-726(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001eb4:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001eb8:	8526                	mv	a0,s1
    80001eba:	fffff097          	auipc	ra,0xfffff
    80001ebe:	dd0080e7          	jalr	-560(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001ec2:	8552                	mv	a0,s4
    80001ec4:	fffff097          	auipc	ra,0xfffff
    80001ec8:	d12080e7          	jalr	-750(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001ecc:	478d                	li	a5,3
    80001ece:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001ed2:	8552                	mv	a0,s4
    80001ed4:	fffff097          	auipc	ra,0xfffff
    80001ed8:	db6080e7          	jalr	-586(ra) # 80000c8a <release>
}
    80001edc:	854a                	mv	a0,s2
    80001ede:	70e2                	ld	ra,56(sp)
    80001ee0:	7442                	ld	s0,48(sp)
    80001ee2:	74a2                	ld	s1,40(sp)
    80001ee4:	7902                	ld	s2,32(sp)
    80001ee6:	69e2                	ld	s3,24(sp)
    80001ee8:	6a42                	ld	s4,16(sp)
    80001eea:	6aa2                	ld	s5,8(sp)
    80001eec:	6121                	addi	sp,sp,64
    80001eee:	8082                	ret
    return -1;
    80001ef0:	597d                	li	s2,-1
    80001ef2:	b7ed                	j	80001edc <fork+0x128>

0000000080001ef4 <scheduler>:
{
    80001ef4:	7139                	addi	sp,sp,-64
    80001ef6:	fc06                	sd	ra,56(sp)
    80001ef8:	f822                	sd	s0,48(sp)
    80001efa:	f426                	sd	s1,40(sp)
    80001efc:	f04a                	sd	s2,32(sp)
    80001efe:	ec4e                	sd	s3,24(sp)
    80001f00:	e852                	sd	s4,16(sp)
    80001f02:	e456                	sd	s5,8(sp)
    80001f04:	e05a                	sd	s6,0(sp)
    80001f06:	0080                	addi	s0,sp,64
    80001f08:	8792                	mv	a5,tp
  int id = r_tp();
    80001f0a:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f0c:	00779a93          	slli	s5,a5,0x7
    80001f10:	0000f717          	auipc	a4,0xf
    80001f14:	d0070713          	addi	a4,a4,-768 # 80010c10 <pid_lock>
    80001f18:	9756                	add	a4,a4,s5
    80001f1a:	06073023          	sd	zero,96(a4)
        swtch(&c->context, &p->context);
    80001f1e:	0000f717          	auipc	a4,0xf
    80001f22:	d5a70713          	addi	a4,a4,-678 # 80010c78 <cpus+0x8>
    80001f26:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    80001f28:	498d                	li	s3,3
        p->state = RUNNING;
    80001f2a:	4b11                	li	s6,4
        c->proc = p;
    80001f2c:	079e                	slli	a5,a5,0x7
    80001f2e:	0000fa17          	auipc	s4,0xf
    80001f32:	ce2a0a13          	addi	s4,s4,-798 # 80010c10 <pid_lock>
    80001f36:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80001f38:	00015917          	auipc	s2,0x15
    80001f3c:	b3890913          	addi	s2,s2,-1224 # 80016a70 <shmem_queue>
  asm volatile("csrr %0, sstatus" : "=r"(x));
    80001f40:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f44:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r"(x));
    80001f48:	10079073          	csrw	sstatus,a5
    80001f4c:	0000f497          	auipc	s1,0xf
    80001f50:	12448493          	addi	s1,s1,292 # 80011070 <proc>
    80001f54:	a811                	j	80001f68 <scheduler+0x74>
      release(&p->lock);
    80001f56:	8526                	mv	a0,s1
    80001f58:	fffff097          	auipc	ra,0xfffff
    80001f5c:	d32080e7          	jalr	-718(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001f60:	16848493          	addi	s1,s1,360
    80001f64:	fd248ee3          	beq	s1,s2,80001f40 <scheduler+0x4c>
      acquire(&p->lock);
    80001f68:	8526                	mv	a0,s1
    80001f6a:	fffff097          	auipc	ra,0xfffff
    80001f6e:	c6c080e7          	jalr	-916(ra) # 80000bd6 <acquire>
      if (p->state == RUNNABLE)
    80001f72:	4c9c                	lw	a5,24(s1)
    80001f74:	ff3791e3          	bne	a5,s3,80001f56 <scheduler+0x62>
        p->state = RUNNING;
    80001f78:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f7c:	069a3023          	sd	s1,96(s4)
        swtch(&c->context, &p->context);
    80001f80:	06048593          	addi	a1,s1,96
    80001f84:	8556                	mv	a0,s5
    80001f86:	00001097          	auipc	ra,0x1
    80001f8a:	a9a080e7          	jalr	-1382(ra) # 80002a20 <swtch>
        c->proc = 0;
    80001f8e:	060a3023          	sd	zero,96(s4)
    80001f92:	b7d1                	j	80001f56 <scheduler+0x62>

0000000080001f94 <sched>:
{
    80001f94:	7179                	addi	sp,sp,-48
    80001f96:	f406                	sd	ra,40(sp)
    80001f98:	f022                	sd	s0,32(sp)
    80001f9a:	ec26                	sd	s1,24(sp)
    80001f9c:	e84a                	sd	s2,16(sp)
    80001f9e:	e44e                	sd	s3,8(sp)
    80001fa0:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fa2:	00000097          	auipc	ra,0x0
    80001fa6:	a3a080e7          	jalr	-1478(ra) # 800019dc <myproc>
    80001faa:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80001fac:	fffff097          	auipc	ra,0xfffff
    80001fb0:	bb0080e7          	jalr	-1104(ra) # 80000b5c <holding>
    80001fb4:	c93d                	beqz	a0,8000202a <sched+0x96>
  asm volatile("mv %0, tp" : "=r"(x));
    80001fb6:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80001fb8:	2781                	sext.w	a5,a5
    80001fba:	079e                	slli	a5,a5,0x7
    80001fbc:	0000f717          	auipc	a4,0xf
    80001fc0:	c5470713          	addi	a4,a4,-940 # 80010c10 <pid_lock>
    80001fc4:	97ba                	add	a5,a5,a4
    80001fc6:	0d87a703          	lw	a4,216(a5)
    80001fca:	4785                	li	a5,1
    80001fcc:	06f71763          	bne	a4,a5,8000203a <sched+0xa6>
  if (p->state == RUNNING)
    80001fd0:	4c98                	lw	a4,24(s1)
    80001fd2:	4791                	li	a5,4
    80001fd4:	06f70b63          	beq	a4,a5,8000204a <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r"(x));
    80001fd8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fdc:	8b89                	andi	a5,a5,2
  if (intr_get())
    80001fde:	efb5                	bnez	a5,8000205a <sched+0xc6>
  asm volatile("mv %0, tp" : "=r"(x));
    80001fe0:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fe2:	0000f917          	auipc	s2,0xf
    80001fe6:	c2e90913          	addi	s2,s2,-978 # 80010c10 <pid_lock>
    80001fea:	2781                	sext.w	a5,a5
    80001fec:	079e                	slli	a5,a5,0x7
    80001fee:	97ca                	add	a5,a5,s2
    80001ff0:	0dc7a983          	lw	s3,220(a5)
    80001ff4:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001ff6:	2781                	sext.w	a5,a5
    80001ff8:	079e                	slli	a5,a5,0x7
    80001ffa:	0000f597          	auipc	a1,0xf
    80001ffe:	c7e58593          	addi	a1,a1,-898 # 80010c78 <cpus+0x8>
    80002002:	95be                	add	a1,a1,a5
    80002004:	06048513          	addi	a0,s1,96
    80002008:	00001097          	auipc	ra,0x1
    8000200c:	a18080e7          	jalr	-1512(ra) # 80002a20 <swtch>
    80002010:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002012:	2781                	sext.w	a5,a5
    80002014:	079e                	slli	a5,a5,0x7
    80002016:	97ca                	add	a5,a5,s2
    80002018:	0d37ae23          	sw	s3,220(a5)
}
    8000201c:	70a2                	ld	ra,40(sp)
    8000201e:	7402                	ld	s0,32(sp)
    80002020:	64e2                	ld	s1,24(sp)
    80002022:	6942                	ld	s2,16(sp)
    80002024:	69a2                	ld	s3,8(sp)
    80002026:	6145                	addi	sp,sp,48
    80002028:	8082                	ret
    panic("sched p->lock");
    8000202a:	00006517          	auipc	a0,0x6
    8000202e:	1fe50513          	addi	a0,a0,510 # 80008228 <digits+0x1e8>
    80002032:	ffffe097          	auipc	ra,0xffffe
    80002036:	50c080e7          	jalr	1292(ra) # 8000053e <panic>
    panic("sched locks");
    8000203a:	00006517          	auipc	a0,0x6
    8000203e:	1fe50513          	addi	a0,a0,510 # 80008238 <digits+0x1f8>
    80002042:	ffffe097          	auipc	ra,0xffffe
    80002046:	4fc080e7          	jalr	1276(ra) # 8000053e <panic>
    panic("sched running");
    8000204a:	00006517          	auipc	a0,0x6
    8000204e:	1fe50513          	addi	a0,a0,510 # 80008248 <digits+0x208>
    80002052:	ffffe097          	auipc	ra,0xffffe
    80002056:	4ec080e7          	jalr	1260(ra) # 8000053e <panic>
    panic("sched interruptible");
    8000205a:	00006517          	auipc	a0,0x6
    8000205e:	1fe50513          	addi	a0,a0,510 # 80008258 <digits+0x218>
    80002062:	ffffe097          	auipc	ra,0xffffe
    80002066:	4dc080e7          	jalr	1244(ra) # 8000053e <panic>

000000008000206a <yield>:
{
    8000206a:	1101                	addi	sp,sp,-32
    8000206c:	ec06                	sd	ra,24(sp)
    8000206e:	e822                	sd	s0,16(sp)
    80002070:	e426                	sd	s1,8(sp)
    80002072:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002074:	00000097          	auipc	ra,0x0
    80002078:	968080e7          	jalr	-1688(ra) # 800019dc <myproc>
    8000207c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000207e:	fffff097          	auipc	ra,0xfffff
    80002082:	b58080e7          	jalr	-1192(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002086:	478d                	li	a5,3
    80002088:	cc9c                	sw	a5,24(s1)
  sched();
    8000208a:	00000097          	auipc	ra,0x0
    8000208e:	f0a080e7          	jalr	-246(ra) # 80001f94 <sched>
  release(&p->lock);
    80002092:	8526                	mv	a0,s1
    80002094:	fffff097          	auipc	ra,0xfffff
    80002098:	bf6080e7          	jalr	-1034(ra) # 80000c8a <release>
}
    8000209c:	60e2                	ld	ra,24(sp)
    8000209e:	6442                	ld	s0,16(sp)
    800020a0:	64a2                	ld	s1,8(sp)
    800020a2:	6105                	addi	sp,sp,32
    800020a4:	8082                	ret

00000000800020a6 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800020a6:	7179                	addi	sp,sp,-48
    800020a8:	f406                	sd	ra,40(sp)
    800020aa:	f022                	sd	s0,32(sp)
    800020ac:	ec26                	sd	s1,24(sp)
    800020ae:	e84a                	sd	s2,16(sp)
    800020b0:	e44e                	sd	s3,8(sp)
    800020b2:	1800                	addi	s0,sp,48
    800020b4:	89aa                	mv	s3,a0
    800020b6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020b8:	00000097          	auipc	ra,0x0
    800020bc:	924080e7          	jalr	-1756(ra) # 800019dc <myproc>
    800020c0:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    800020c2:	fffff097          	auipc	ra,0xfffff
    800020c6:	b14080e7          	jalr	-1260(ra) # 80000bd6 <acquire>
  release(lk);
    800020ca:	854a                	mv	a0,s2
    800020cc:	fffff097          	auipc	ra,0xfffff
    800020d0:	bbe080e7          	jalr	-1090(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    800020d4:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020d8:	4789                	li	a5,2
    800020da:	cc9c                	sw	a5,24(s1)

  sched();
    800020dc:	00000097          	auipc	ra,0x0
    800020e0:	eb8080e7          	jalr	-328(ra) # 80001f94 <sched>

  // Tidy up.
  p->chan = 0;
    800020e4:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020e8:	8526                	mv	a0,s1
    800020ea:	fffff097          	auipc	ra,0xfffff
    800020ee:	ba0080e7          	jalr	-1120(ra) # 80000c8a <release>
  acquire(lk);
    800020f2:	854a                	mv	a0,s2
    800020f4:	fffff097          	auipc	ra,0xfffff
    800020f8:	ae2080e7          	jalr	-1310(ra) # 80000bd6 <acquire>
}
    800020fc:	70a2                	ld	ra,40(sp)
    800020fe:	7402                	ld	s0,32(sp)
    80002100:	64e2                	ld	s1,24(sp)
    80002102:	6942                	ld	s2,16(sp)
    80002104:	69a2                	ld	s3,8(sp)
    80002106:	6145                	addi	sp,sp,48
    80002108:	8082                	ret

000000008000210a <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    8000210a:	7139                	addi	sp,sp,-64
    8000210c:	fc06                	sd	ra,56(sp)
    8000210e:	f822                	sd	s0,48(sp)
    80002110:	f426                	sd	s1,40(sp)
    80002112:	f04a                	sd	s2,32(sp)
    80002114:	ec4e                	sd	s3,24(sp)
    80002116:	e852                	sd	s4,16(sp)
    80002118:	e456                	sd	s5,8(sp)
    8000211a:	0080                	addi	s0,sp,64
    8000211c:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000211e:	0000f497          	auipc	s1,0xf
    80002122:	f5248493          	addi	s1,s1,-174 # 80011070 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002126:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002128:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    8000212a:	00015917          	auipc	s2,0x15
    8000212e:	94690913          	addi	s2,s2,-1722 # 80016a70 <shmem_queue>
    80002132:	a811                	j	80002146 <wakeup+0x3c>
      }
      release(&p->lock);
    80002134:	8526                	mv	a0,s1
    80002136:	fffff097          	auipc	ra,0xfffff
    8000213a:	b54080e7          	jalr	-1196(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000213e:	16848493          	addi	s1,s1,360
    80002142:	03248663          	beq	s1,s2,8000216e <wakeup+0x64>
    if (p != myproc())
    80002146:	00000097          	auipc	ra,0x0
    8000214a:	896080e7          	jalr	-1898(ra) # 800019dc <myproc>
    8000214e:	fea488e3          	beq	s1,a0,8000213e <wakeup+0x34>
      acquire(&p->lock);
    80002152:	8526                	mv	a0,s1
    80002154:	fffff097          	auipc	ra,0xfffff
    80002158:	a82080e7          	jalr	-1406(ra) # 80000bd6 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    8000215c:	4c9c                	lw	a5,24(s1)
    8000215e:	fd379be3          	bne	a5,s3,80002134 <wakeup+0x2a>
    80002162:	709c                	ld	a5,32(s1)
    80002164:	fd4798e3          	bne	a5,s4,80002134 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002168:	0154ac23          	sw	s5,24(s1)
    8000216c:	b7e1                	j	80002134 <wakeup+0x2a>
    }
  }
}
    8000216e:	70e2                	ld	ra,56(sp)
    80002170:	7442                	ld	s0,48(sp)
    80002172:	74a2                	ld	s1,40(sp)
    80002174:	7902                	ld	s2,32(sp)
    80002176:	69e2                	ld	s3,24(sp)
    80002178:	6a42                	ld	s4,16(sp)
    8000217a:	6aa2                	ld	s5,8(sp)
    8000217c:	6121                	addi	sp,sp,64
    8000217e:	8082                	ret

0000000080002180 <reparent>:
{
    80002180:	7179                	addi	sp,sp,-48
    80002182:	f406                	sd	ra,40(sp)
    80002184:	f022                	sd	s0,32(sp)
    80002186:	ec26                	sd	s1,24(sp)
    80002188:	e84a                	sd	s2,16(sp)
    8000218a:	e44e                	sd	s3,8(sp)
    8000218c:	e052                	sd	s4,0(sp)
    8000218e:	1800                	addi	s0,sp,48
    80002190:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002192:	0000f497          	auipc	s1,0xf
    80002196:	ede48493          	addi	s1,s1,-290 # 80011070 <proc>
      pp->parent = initproc;
    8000219a:	00006a17          	auipc	s4,0x6
    8000219e:	7f6a0a13          	addi	s4,s4,2038 # 80008990 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800021a2:	00015997          	auipc	s3,0x15
    800021a6:	8ce98993          	addi	s3,s3,-1842 # 80016a70 <shmem_queue>
    800021aa:	a029                	j	800021b4 <reparent+0x34>
    800021ac:	16848493          	addi	s1,s1,360
    800021b0:	01348d63          	beq	s1,s3,800021ca <reparent+0x4a>
    if (pp->parent == p)
    800021b4:	7c9c                	ld	a5,56(s1)
    800021b6:	ff279be3          	bne	a5,s2,800021ac <reparent+0x2c>
      pp->parent = initproc;
    800021ba:	000a3503          	ld	a0,0(s4)
    800021be:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800021c0:	00000097          	auipc	ra,0x0
    800021c4:	f4a080e7          	jalr	-182(ra) # 8000210a <wakeup>
    800021c8:	b7d5                	j	800021ac <reparent+0x2c>
}
    800021ca:	70a2                	ld	ra,40(sp)
    800021cc:	7402                	ld	s0,32(sp)
    800021ce:	64e2                	ld	s1,24(sp)
    800021d0:	6942                	ld	s2,16(sp)
    800021d2:	69a2                	ld	s3,8(sp)
    800021d4:	6a02                	ld	s4,0(sp)
    800021d6:	6145                	addi	sp,sp,48
    800021d8:	8082                	ret

00000000800021da <exit>:
{
    800021da:	7179                	addi	sp,sp,-48
    800021dc:	f406                	sd	ra,40(sp)
    800021de:	f022                	sd	s0,32(sp)
    800021e0:	ec26                	sd	s1,24(sp)
    800021e2:	e84a                	sd	s2,16(sp)
    800021e4:	e44e                	sd	s3,8(sp)
    800021e6:	e052                	sd	s4,0(sp)
    800021e8:	1800                	addi	s0,sp,48
    800021ea:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021ec:	fffff097          	auipc	ra,0xfffff
    800021f0:	7f0080e7          	jalr	2032(ra) # 800019dc <myproc>
    800021f4:	89aa                	mv	s3,a0
  if (p == initproc)
    800021f6:	00006797          	auipc	a5,0x6
    800021fa:	79a7b783          	ld	a5,1946(a5) # 80008990 <initproc>
    800021fe:	0d050493          	addi	s1,a0,208
    80002202:	15050913          	addi	s2,a0,336
    80002206:	02a79363          	bne	a5,a0,8000222c <exit+0x52>
    panic("init exiting");
    8000220a:	00006517          	auipc	a0,0x6
    8000220e:	06650513          	addi	a0,a0,102 # 80008270 <digits+0x230>
    80002212:	ffffe097          	auipc	ra,0xffffe
    80002216:	32c080e7          	jalr	812(ra) # 8000053e <panic>
      fileclose(f);
    8000221a:	00003097          	auipc	ra,0x3
    8000221e:	a06080e7          	jalr	-1530(ra) # 80004c20 <fileclose>
      p->ofile[fd] = 0;
    80002222:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002226:	04a1                	addi	s1,s1,8
    80002228:	01248563          	beq	s1,s2,80002232 <exit+0x58>
    if (p->ofile[fd])
    8000222c:	6088                	ld	a0,0(s1)
    8000222e:	f575                	bnez	a0,8000221a <exit+0x40>
    80002230:	bfdd                	j	80002226 <exit+0x4c>
  begin_op();
    80002232:	00002097          	auipc	ra,0x2
    80002236:	522080e7          	jalr	1314(ra) # 80004754 <begin_op>
  iput(p->cwd);
    8000223a:	1509b503          	ld	a0,336(s3)
    8000223e:	00002097          	auipc	ra,0x2
    80002242:	d0e080e7          	jalr	-754(ra) # 80003f4c <iput>
  end_op();
    80002246:	00002097          	auipc	ra,0x2
    8000224a:	58e080e7          	jalr	1422(ra) # 800047d4 <end_op>
  p->cwd = 0;
    8000224e:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002252:	0000f497          	auipc	s1,0xf
    80002256:	9d648493          	addi	s1,s1,-1578 # 80010c28 <wait_lock>
    8000225a:	8526                	mv	a0,s1
    8000225c:	fffff097          	auipc	ra,0xfffff
    80002260:	97a080e7          	jalr	-1670(ra) # 80000bd6 <acquire>
  reparent(p);
    80002264:	854e                	mv	a0,s3
    80002266:	00000097          	auipc	ra,0x0
    8000226a:	f1a080e7          	jalr	-230(ra) # 80002180 <reparent>
  wakeup(p->parent);
    8000226e:	0389b503          	ld	a0,56(s3)
    80002272:	00000097          	auipc	ra,0x0
    80002276:	e98080e7          	jalr	-360(ra) # 8000210a <wakeup>
  acquire(&p->lock);
    8000227a:	854e                	mv	a0,s3
    8000227c:	fffff097          	auipc	ra,0xfffff
    80002280:	95a080e7          	jalr	-1702(ra) # 80000bd6 <acquire>
  p->xstate = status;
    80002284:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002288:	4795                	li	a5,5
    8000228a:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000228e:	8526                	mv	a0,s1
    80002290:	fffff097          	auipc	ra,0xfffff
    80002294:	9fa080e7          	jalr	-1542(ra) # 80000c8a <release>
  sched();
    80002298:	00000097          	auipc	ra,0x0
    8000229c:	cfc080e7          	jalr	-772(ra) # 80001f94 <sched>
  panic("zombie exit");
    800022a0:	00006517          	auipc	a0,0x6
    800022a4:	fe050513          	addi	a0,a0,-32 # 80008280 <digits+0x240>
    800022a8:	ffffe097          	auipc	ra,0xffffe
    800022ac:	296080e7          	jalr	662(ra) # 8000053e <panic>

00000000800022b0 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800022b0:	7179                	addi	sp,sp,-48
    800022b2:	f406                	sd	ra,40(sp)
    800022b4:	f022                	sd	s0,32(sp)
    800022b6:	ec26                	sd	s1,24(sp)
    800022b8:	e84a                	sd	s2,16(sp)
    800022ba:	e44e                	sd	s3,8(sp)
    800022bc:	1800                	addi	s0,sp,48
    800022be:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800022c0:	0000f497          	auipc	s1,0xf
    800022c4:	db048493          	addi	s1,s1,-592 # 80011070 <proc>
    800022c8:	00014997          	auipc	s3,0x14
    800022cc:	7a898993          	addi	s3,s3,1960 # 80016a70 <shmem_queue>
  {
    acquire(&p->lock);
    800022d0:	8526                	mv	a0,s1
    800022d2:	fffff097          	auipc	ra,0xfffff
    800022d6:	904080e7          	jalr	-1788(ra) # 80000bd6 <acquire>
    if (p->pid == pid)
    800022da:	589c                	lw	a5,48(s1)
    800022dc:	01278d63          	beq	a5,s2,800022f6 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800022e0:	8526                	mv	a0,s1
    800022e2:	fffff097          	auipc	ra,0xfffff
    800022e6:	9a8080e7          	jalr	-1624(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800022ea:	16848493          	addi	s1,s1,360
    800022ee:	ff3491e3          	bne	s1,s3,800022d0 <kill+0x20>
  }
  return -1;
    800022f2:	557d                	li	a0,-1
    800022f4:	a829                	j	8000230e <kill+0x5e>
      p->killed = 1;
    800022f6:	4785                	li	a5,1
    800022f8:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800022fa:	4c98                	lw	a4,24(s1)
    800022fc:	4789                	li	a5,2
    800022fe:	00f70f63          	beq	a4,a5,8000231c <kill+0x6c>
      release(&p->lock);
    80002302:	8526                	mv	a0,s1
    80002304:	fffff097          	auipc	ra,0xfffff
    80002308:	986080e7          	jalr	-1658(ra) # 80000c8a <release>
      return 0;
    8000230c:	4501                	li	a0,0
}
    8000230e:	70a2                	ld	ra,40(sp)
    80002310:	7402                	ld	s0,32(sp)
    80002312:	64e2                	ld	s1,24(sp)
    80002314:	6942                	ld	s2,16(sp)
    80002316:	69a2                	ld	s3,8(sp)
    80002318:	6145                	addi	sp,sp,48
    8000231a:	8082                	ret
        p->state = RUNNABLE;
    8000231c:	478d                	li	a5,3
    8000231e:	cc9c                	sw	a5,24(s1)
    80002320:	b7cd                	j	80002302 <kill+0x52>

0000000080002322 <setkilled>:

void setkilled(struct proc *p)
{
    80002322:	1101                	addi	sp,sp,-32
    80002324:	ec06                	sd	ra,24(sp)
    80002326:	e822                	sd	s0,16(sp)
    80002328:	e426                	sd	s1,8(sp)
    8000232a:	1000                	addi	s0,sp,32
    8000232c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000232e:	fffff097          	auipc	ra,0xfffff
    80002332:	8a8080e7          	jalr	-1880(ra) # 80000bd6 <acquire>
  p->killed = 1;
    80002336:	4785                	li	a5,1
    80002338:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000233a:	8526                	mv	a0,s1
    8000233c:	fffff097          	auipc	ra,0xfffff
    80002340:	94e080e7          	jalr	-1714(ra) # 80000c8a <release>
}
    80002344:	60e2                	ld	ra,24(sp)
    80002346:	6442                	ld	s0,16(sp)
    80002348:	64a2                	ld	s1,8(sp)
    8000234a:	6105                	addi	sp,sp,32
    8000234c:	8082                	ret

000000008000234e <killed>:

int killed(struct proc *p)
{
    8000234e:	1101                	addi	sp,sp,-32
    80002350:	ec06                	sd	ra,24(sp)
    80002352:	e822                	sd	s0,16(sp)
    80002354:	e426                	sd	s1,8(sp)
    80002356:	e04a                	sd	s2,0(sp)
    80002358:	1000                	addi	s0,sp,32
    8000235a:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    8000235c:	fffff097          	auipc	ra,0xfffff
    80002360:	87a080e7          	jalr	-1926(ra) # 80000bd6 <acquire>
  k = p->killed;
    80002364:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002368:	8526                	mv	a0,s1
    8000236a:	fffff097          	auipc	ra,0xfffff
    8000236e:	920080e7          	jalr	-1760(ra) # 80000c8a <release>
  return k;
}
    80002372:	854a                	mv	a0,s2
    80002374:	60e2                	ld	ra,24(sp)
    80002376:	6442                	ld	s0,16(sp)
    80002378:	64a2                	ld	s1,8(sp)
    8000237a:	6902                	ld	s2,0(sp)
    8000237c:	6105                	addi	sp,sp,32
    8000237e:	8082                	ret

0000000080002380 <wait>:
{
    80002380:	715d                	addi	sp,sp,-80
    80002382:	e486                	sd	ra,72(sp)
    80002384:	e0a2                	sd	s0,64(sp)
    80002386:	fc26                	sd	s1,56(sp)
    80002388:	f84a                	sd	s2,48(sp)
    8000238a:	f44e                	sd	s3,40(sp)
    8000238c:	f052                	sd	s4,32(sp)
    8000238e:	ec56                	sd	s5,24(sp)
    80002390:	e85a                	sd	s6,16(sp)
    80002392:	e45e                	sd	s7,8(sp)
    80002394:	e062                	sd	s8,0(sp)
    80002396:	0880                	addi	s0,sp,80
    80002398:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000239a:	fffff097          	auipc	ra,0xfffff
    8000239e:	642080e7          	jalr	1602(ra) # 800019dc <myproc>
    800023a2:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800023a4:	0000f517          	auipc	a0,0xf
    800023a8:	88450513          	addi	a0,a0,-1916 # 80010c28 <wait_lock>
    800023ac:	fffff097          	auipc	ra,0xfffff
    800023b0:	82a080e7          	jalr	-2006(ra) # 80000bd6 <acquire>
    havekids = 0;
    800023b4:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    800023b6:	4a15                	li	s4,5
        havekids = 1;
    800023b8:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800023ba:	00014997          	auipc	s3,0x14
    800023be:	6b698993          	addi	s3,s3,1718 # 80016a70 <shmem_queue>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800023c2:	0000fc17          	auipc	s8,0xf
    800023c6:	866c0c13          	addi	s8,s8,-1946 # 80010c28 <wait_lock>
    havekids = 0;
    800023ca:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800023cc:	0000f497          	auipc	s1,0xf
    800023d0:	ca448493          	addi	s1,s1,-860 # 80011070 <proc>
    800023d4:	a0bd                	j	80002442 <wait+0xc2>
          pid = pp->pid;
    800023d6:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800023da:	000b0e63          	beqz	s6,800023f6 <wait+0x76>
    800023de:	4691                	li	a3,4
    800023e0:	02c48613          	addi	a2,s1,44
    800023e4:	85da                	mv	a1,s6
    800023e6:	05093503          	ld	a0,80(s2)
    800023ea:	fffff097          	auipc	ra,0xfffff
    800023ee:	296080e7          	jalr	662(ra) # 80001680 <copyout>
    800023f2:	02054563          	bltz	a0,8000241c <wait+0x9c>
          freeproc(pp);
    800023f6:	8526                	mv	a0,s1
    800023f8:	fffff097          	auipc	ra,0xfffff
    800023fc:	7b8080e7          	jalr	1976(ra) # 80001bb0 <freeproc>
          release(&pp->lock);
    80002400:	8526                	mv	a0,s1
    80002402:	fffff097          	auipc	ra,0xfffff
    80002406:	888080e7          	jalr	-1912(ra) # 80000c8a <release>
          release(&wait_lock);
    8000240a:	0000f517          	auipc	a0,0xf
    8000240e:	81e50513          	addi	a0,a0,-2018 # 80010c28 <wait_lock>
    80002412:	fffff097          	auipc	ra,0xfffff
    80002416:	878080e7          	jalr	-1928(ra) # 80000c8a <release>
          return pid;
    8000241a:	a0b5                	j	80002486 <wait+0x106>
            release(&pp->lock);
    8000241c:	8526                	mv	a0,s1
    8000241e:	fffff097          	auipc	ra,0xfffff
    80002422:	86c080e7          	jalr	-1940(ra) # 80000c8a <release>
            release(&wait_lock);
    80002426:	0000f517          	auipc	a0,0xf
    8000242a:	80250513          	addi	a0,a0,-2046 # 80010c28 <wait_lock>
    8000242e:	fffff097          	auipc	ra,0xfffff
    80002432:	85c080e7          	jalr	-1956(ra) # 80000c8a <release>
            return -1;
    80002436:	59fd                	li	s3,-1
    80002438:	a0b9                	j	80002486 <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000243a:	16848493          	addi	s1,s1,360
    8000243e:	03348463          	beq	s1,s3,80002466 <wait+0xe6>
      if (pp->parent == p)
    80002442:	7c9c                	ld	a5,56(s1)
    80002444:	ff279be3          	bne	a5,s2,8000243a <wait+0xba>
        acquire(&pp->lock);
    80002448:	8526                	mv	a0,s1
    8000244a:	ffffe097          	auipc	ra,0xffffe
    8000244e:	78c080e7          	jalr	1932(ra) # 80000bd6 <acquire>
        if (pp->state == ZOMBIE)
    80002452:	4c9c                	lw	a5,24(s1)
    80002454:	f94781e3          	beq	a5,s4,800023d6 <wait+0x56>
        release(&pp->lock);
    80002458:	8526                	mv	a0,s1
    8000245a:	fffff097          	auipc	ra,0xfffff
    8000245e:	830080e7          	jalr	-2000(ra) # 80000c8a <release>
        havekids = 1;
    80002462:	8756                	mv	a4,s5
    80002464:	bfd9                	j	8000243a <wait+0xba>
    if (!havekids || killed(p))
    80002466:	c719                	beqz	a4,80002474 <wait+0xf4>
    80002468:	854a                	mv	a0,s2
    8000246a:	00000097          	auipc	ra,0x0
    8000246e:	ee4080e7          	jalr	-284(ra) # 8000234e <killed>
    80002472:	c51d                	beqz	a0,800024a0 <wait+0x120>
      release(&wait_lock);
    80002474:	0000e517          	auipc	a0,0xe
    80002478:	7b450513          	addi	a0,a0,1972 # 80010c28 <wait_lock>
    8000247c:	fffff097          	auipc	ra,0xfffff
    80002480:	80e080e7          	jalr	-2034(ra) # 80000c8a <release>
      return -1;
    80002484:	59fd                	li	s3,-1
}
    80002486:	854e                	mv	a0,s3
    80002488:	60a6                	ld	ra,72(sp)
    8000248a:	6406                	ld	s0,64(sp)
    8000248c:	74e2                	ld	s1,56(sp)
    8000248e:	7942                	ld	s2,48(sp)
    80002490:	79a2                	ld	s3,40(sp)
    80002492:	7a02                	ld	s4,32(sp)
    80002494:	6ae2                	ld	s5,24(sp)
    80002496:	6b42                	ld	s6,16(sp)
    80002498:	6ba2                	ld	s7,8(sp)
    8000249a:	6c02                	ld	s8,0(sp)
    8000249c:	6161                	addi	sp,sp,80
    8000249e:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    800024a0:	85e2                	mv	a1,s8
    800024a2:	854a                	mv	a0,s2
    800024a4:	00000097          	auipc	ra,0x0
    800024a8:	c02080e7          	jalr	-1022(ra) # 800020a6 <sleep>
    havekids = 0;
    800024ac:	bf39                	j	800023ca <wait+0x4a>

00000000800024ae <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024ae:	7179                	addi	sp,sp,-48
    800024b0:	f406                	sd	ra,40(sp)
    800024b2:	f022                	sd	s0,32(sp)
    800024b4:	ec26                	sd	s1,24(sp)
    800024b6:	e84a                	sd	s2,16(sp)
    800024b8:	e44e                	sd	s3,8(sp)
    800024ba:	e052                	sd	s4,0(sp)
    800024bc:	1800                	addi	s0,sp,48
    800024be:	84aa                	mv	s1,a0
    800024c0:	892e                	mv	s2,a1
    800024c2:	89b2                	mv	s3,a2
    800024c4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024c6:	fffff097          	auipc	ra,0xfffff
    800024ca:	516080e7          	jalr	1302(ra) # 800019dc <myproc>
  if (user_dst)
    800024ce:	c08d                	beqz	s1,800024f0 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800024d0:	86d2                	mv	a3,s4
    800024d2:	864e                	mv	a2,s3
    800024d4:	85ca                	mv	a1,s2
    800024d6:	6928                	ld	a0,80(a0)
    800024d8:	fffff097          	auipc	ra,0xfffff
    800024dc:	1a8080e7          	jalr	424(ra) # 80001680 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024e0:	70a2                	ld	ra,40(sp)
    800024e2:	7402                	ld	s0,32(sp)
    800024e4:	64e2                	ld	s1,24(sp)
    800024e6:	6942                	ld	s2,16(sp)
    800024e8:	69a2                	ld	s3,8(sp)
    800024ea:	6a02                	ld	s4,0(sp)
    800024ec:	6145                	addi	sp,sp,48
    800024ee:	8082                	ret
    memmove((char *)dst, src, len);
    800024f0:	000a061b          	sext.w	a2,s4
    800024f4:	85ce                	mv	a1,s3
    800024f6:	854a                	mv	a0,s2
    800024f8:	fffff097          	auipc	ra,0xfffff
    800024fc:	836080e7          	jalr	-1994(ra) # 80000d2e <memmove>
    return 0;
    80002500:	8526                	mv	a0,s1
    80002502:	bff9                	j	800024e0 <either_copyout+0x32>

0000000080002504 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002504:	7179                	addi	sp,sp,-48
    80002506:	f406                	sd	ra,40(sp)
    80002508:	f022                	sd	s0,32(sp)
    8000250a:	ec26                	sd	s1,24(sp)
    8000250c:	e84a                	sd	s2,16(sp)
    8000250e:	e44e                	sd	s3,8(sp)
    80002510:	e052                	sd	s4,0(sp)
    80002512:	1800                	addi	s0,sp,48
    80002514:	892a                	mv	s2,a0
    80002516:	84ae                	mv	s1,a1
    80002518:	89b2                	mv	s3,a2
    8000251a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000251c:	fffff097          	auipc	ra,0xfffff
    80002520:	4c0080e7          	jalr	1216(ra) # 800019dc <myproc>
  if (user_src)
    80002524:	c08d                	beqz	s1,80002546 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002526:	86d2                	mv	a3,s4
    80002528:	864e                	mv	a2,s3
    8000252a:	85ca                	mv	a1,s2
    8000252c:	6928                	ld	a0,80(a0)
    8000252e:	fffff097          	auipc	ra,0xfffff
    80002532:	1de080e7          	jalr	478(ra) # 8000170c <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002536:	70a2                	ld	ra,40(sp)
    80002538:	7402                	ld	s0,32(sp)
    8000253a:	64e2                	ld	s1,24(sp)
    8000253c:	6942                	ld	s2,16(sp)
    8000253e:	69a2                	ld	s3,8(sp)
    80002540:	6a02                	ld	s4,0(sp)
    80002542:	6145                	addi	sp,sp,48
    80002544:	8082                	ret
    memmove(dst, (char *)src, len);
    80002546:	000a061b          	sext.w	a2,s4
    8000254a:	85ce                	mv	a1,s3
    8000254c:	854a                	mv	a0,s2
    8000254e:	ffffe097          	auipc	ra,0xffffe
    80002552:	7e0080e7          	jalr	2016(ra) # 80000d2e <memmove>
    return 0;
    80002556:	8526                	mv	a0,s1
    80002558:	bff9                	j	80002536 <either_copyin+0x32>

000000008000255a <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    8000255a:	715d                	addi	sp,sp,-80
    8000255c:	e486                	sd	ra,72(sp)
    8000255e:	e0a2                	sd	s0,64(sp)
    80002560:	fc26                	sd	s1,56(sp)
    80002562:	f84a                	sd	s2,48(sp)
    80002564:	f44e                	sd	s3,40(sp)
    80002566:	f052                	sd	s4,32(sp)
    80002568:	ec56                	sd	s5,24(sp)
    8000256a:	e85a                	sd	s6,16(sp)
    8000256c:	e45e                	sd	s7,8(sp)
    8000256e:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002570:	00006517          	auipc	a0,0x6
    80002574:	b5850513          	addi	a0,a0,-1192 # 800080c8 <digits+0x88>
    80002578:	ffffe097          	auipc	ra,0xffffe
    8000257c:	010080e7          	jalr	16(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002580:	0000f497          	auipc	s1,0xf
    80002584:	c4848493          	addi	s1,s1,-952 # 800111c8 <proc+0x158>
    80002588:	00014917          	auipc	s2,0x14
    8000258c:	64090913          	addi	s2,s2,1600 # 80016bc8 <shmem_queue+0x158>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002590:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002592:	00006997          	auipc	s3,0x6
    80002596:	cfe98993          	addi	s3,s3,-770 # 80008290 <digits+0x250>
    printf("%d %s %s", p->pid, state, p->name);
    8000259a:	00006a97          	auipc	s5,0x6
    8000259e:	cfea8a93          	addi	s5,s5,-770 # 80008298 <digits+0x258>
    printf("\n");
    800025a2:	00006a17          	auipc	s4,0x6
    800025a6:	b26a0a13          	addi	s4,s4,-1242 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025aa:	00006b97          	auipc	s7,0x6
    800025ae:	d2eb8b93          	addi	s7,s7,-722 # 800082d8 <states.0>
    800025b2:	a00d                	j	800025d4 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025b4:	ed86a583          	lw	a1,-296(a3)
    800025b8:	8556                	mv	a0,s5
    800025ba:	ffffe097          	auipc	ra,0xffffe
    800025be:	fce080e7          	jalr	-50(ra) # 80000588 <printf>
    printf("\n");
    800025c2:	8552                	mv	a0,s4
    800025c4:	ffffe097          	auipc	ra,0xffffe
    800025c8:	fc4080e7          	jalr	-60(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800025cc:	16848493          	addi	s1,s1,360
    800025d0:	03248163          	beq	s1,s2,800025f2 <procdump+0x98>
    if (p->state == UNUSED)
    800025d4:	86a6                	mv	a3,s1
    800025d6:	ec04a783          	lw	a5,-320(s1)
    800025da:	dbed                	beqz	a5,800025cc <procdump+0x72>
      state = "???";
    800025dc:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025de:	fcfb6be3          	bltu	s6,a5,800025b4 <procdump+0x5a>
    800025e2:	1782                	slli	a5,a5,0x20
    800025e4:	9381                	srli	a5,a5,0x20
    800025e6:	078e                	slli	a5,a5,0x3
    800025e8:	97de                	add	a5,a5,s7
    800025ea:	6390                	ld	a2,0(a5)
    800025ec:	f661                	bnez	a2,800025b4 <procdump+0x5a>
      state = "???";
    800025ee:	864e                	mv	a2,s3
    800025f0:	b7d1                	j	800025b4 <procdump+0x5a>
  }
}
    800025f2:	60a6                	ld	ra,72(sp)
    800025f4:	6406                	ld	s0,64(sp)
    800025f6:	74e2                	ld	s1,56(sp)
    800025f8:	7942                	ld	s2,48(sp)
    800025fa:	79a2                	ld	s3,40(sp)
    800025fc:	7a02                	ld	s4,32(sp)
    800025fe:	6ae2                	ld	s5,24(sp)
    80002600:	6b42                	ld	s6,16(sp)
    80002602:	6ba2                	ld	s7,8(sp)
    80002604:	6161                	addi	sp,sp,80
    80002606:	8082                	ret

0000000080002608 <map_shared_pages>:

uint64 map_shared_pages(struct proc *src_proc, struct proc *dst_proc, uint64 src_va, uint64 size)
{
    80002608:	711d                	addi	sp,sp,-96
    8000260a:	ec86                	sd	ra,88(sp)
    8000260c:	e8a2                	sd	s0,80(sp)
    8000260e:	e4a6                	sd	s1,72(sp)
    80002610:	e0ca                	sd	s2,64(sp)
    80002612:	fc4e                	sd	s3,56(sp)
    80002614:	f852                	sd	s4,48(sp)
    80002616:	f456                	sd	s5,40(sp)
    80002618:	f05a                	sd	s6,32(sp)
    8000261a:	ec5e                	sd	s7,24(sp)
    8000261c:	e862                	sd	s8,16(sp)
    8000261e:	e466                	sd	s9,8(sp)
    80002620:	e06a                	sd	s10,0(sp)
    80002622:	1080                	addi	s0,sp,96
    80002624:	8a2e                	mv	s4,a1
    80002626:	8d32                	mv	s10,a2
  uint64 src_va_page = PGROUNDDOWN(src_va);
    80002628:	77fd                	lui	a5,0xfffff
    8000262a:	00f67c33          	and	s8,a2,a5
  uint64 src_va_offset = src_va - src_va_page;
  uint64 dst_va = 0;
  pte_t *pte;
  uint64 mapped_bytes;
  for (mapped_bytes = 0; mapped_bytes < PGROUNDUP(size); mapped_bytes += PGSIZE)
    8000262e:	6b05                	lui	s6,0x1
    80002630:	1b7d                	addi	s6,s6,-1
    80002632:	9b36                	add	s6,s6,a3
    80002634:	00fb7b33          	and	s6,s6,a5
    80002638:	0a0b0063          	beqz	s6,800026d8 <map_shared_pages+0xd0>
    8000263c:	8baa                	mv	s7,a0
    8000263e:	4981                	li	s3,0
    if (pte == 0)
    {
      // maybe add unmalloc here
      return 0;
    }
    if (((*pte & PTE_V) == 0) || ((*pte & PTE_U) == 0))
    80002640:	4cc5                	li	s9,17
    {
      // maybe add unmalloc here
      return 0;
    }
    // allocate a page for dst_va
    dst_va = uvmalloc(dst_proc->pagetable, dst_proc->sz, dst_proc->sz + PGSIZE, PTE_FLAGS(*pte) | PTE_S);
    80002642:	6a85                	lui	s5,0x1
    pte = walk(src_proc->pagetable, src_va_page + mapped_bytes, 0);
    80002644:	4601                	li	a2,0
    80002646:	013c05b3          	add	a1,s8,s3
    8000264a:	050bb503          	ld	a0,80(s7)
    8000264e:	fffff097          	auipc	ra,0xfffff
    80002652:	978080e7          	jalr	-1672(ra) # 80000fc6 <walk>
    80002656:	84aa                	mv	s1,a0
    if (pte == 0)
    80002658:	c159                	beqz	a0,800026de <map_shared_pages+0xd6>
    if (((*pte & PTE_V) == 0) || ((*pte & PTE_U) == 0))
    8000265a:	6114                	ld	a3,0(a0)
    8000265c:	0116f793          	andi	a5,a3,17
    80002660:	09979163          	bne	a5,s9,800026e2 <map_shared_pages+0xda>
    dst_va = uvmalloc(dst_proc->pagetable, dst_proc->sz, dst_proc->sz + PGSIZE, PTE_FLAGS(*pte) | PTE_S);
    80002664:	048a3583          	ld	a1,72(s4)
    80002668:	2ff6f693          	andi	a3,a3,767
    8000266c:	1006e693          	ori	a3,a3,256
    80002670:	01558633          	add	a2,a1,s5
    80002674:	050a3503          	ld	a0,80(s4)
    80002678:	fffff097          	auipc	ra,0xfffff
    8000267c:	db0080e7          	jalr	-592(ra) # 80001428 <uvmalloc>
    80002680:	892a                	mv	s2,a0
    if (dst_va == 0)
    80002682:	cd05                	beqz	a0,800026ba <map_shared_pages+0xb2>
    {
      // maybe add unmalloc here
      return 0;
    }
    if (mappages(dst_proc->pagetable, dst_va, PGSIZE, PTE2PA(*pte), PTE_FLAGS(*pte) | PTE_S) != 0)
    80002684:	6094                	ld	a3,0(s1)
    80002686:	2ff6f713          	andi	a4,a3,767
    8000268a:	82a9                	srli	a3,a3,0xa
    8000268c:	10076713          	ori	a4,a4,256
    80002690:	06b2                	slli	a3,a3,0xc
    80002692:	8656                	mv	a2,s5
    80002694:	85aa                	mv	a1,a0
    80002696:	050a3503          	ld	a0,80(s4)
    8000269a:	fffff097          	auipc	ra,0xfffff
    8000269e:	a14080e7          	jalr	-1516(ra) # 800010ae <mappages>
    800026a2:	e131                	bnez	a0,800026e6 <map_shared_pages+0xde>
  for (mapped_bytes = 0; mapped_bytes < PGROUNDUP(size); mapped_bytes += PGSIZE)
    800026a4:	99d6                	add	s3,s3,s5
    800026a6:	f969efe3          	bltu	s3,s6,80002644 <map_shared_pages+0x3c>
    {
      // maybe add unmalloc here
      return 0;
    }
  }
  dst_proc->sz += mapped_bytes;
    800026aa:	048a3783          	ld	a5,72(s4)
    800026ae:	99be                	add	s3,s3,a5
    800026b0:	053a3423          	sd	s3,72(s4)
  uint64 src_va_offset = src_va - src_va_page;
    800026b4:	418d0c33          	sub	s8,s10,s8
  return dst_va + src_va_offset;
    800026b8:	9962                	add	s2,s2,s8
}
    800026ba:	854a                	mv	a0,s2
    800026bc:	60e6                	ld	ra,88(sp)
    800026be:	6446                	ld	s0,80(sp)
    800026c0:	64a6                	ld	s1,72(sp)
    800026c2:	6906                	ld	s2,64(sp)
    800026c4:	79e2                	ld	s3,56(sp)
    800026c6:	7a42                	ld	s4,48(sp)
    800026c8:	7aa2                	ld	s5,40(sp)
    800026ca:	7b02                	ld	s6,32(sp)
    800026cc:	6be2                	ld	s7,24(sp)
    800026ce:	6c42                	ld	s8,16(sp)
    800026d0:	6ca2                	ld	s9,8(sp)
    800026d2:	6d02                	ld	s10,0(sp)
    800026d4:	6125                	addi	sp,sp,96
    800026d6:	8082                	ret
  for (mapped_bytes = 0; mapped_bytes < PGROUNDUP(size); mapped_bytes += PGSIZE)
    800026d8:	89da                	mv	s3,s6
  uint64 dst_va = 0;
    800026da:	895a                	mv	s2,s6
    800026dc:	b7f9                	j	800026aa <map_shared_pages+0xa2>
      return 0;
    800026de:	4901                	li	s2,0
    800026e0:	bfe9                	j	800026ba <map_shared_pages+0xb2>
      return 0;
    800026e2:	4901                	li	s2,0
    800026e4:	bfd9                	j	800026ba <map_shared_pages+0xb2>
      return 0;
    800026e6:	4901                	li	s2,0
    800026e8:	bfc9                	j	800026ba <map_shared_pages+0xb2>

00000000800026ea <unmap_shared_pages>:
// unmap the shared memory from the destination process
// notice that the function uvmunmap is getting as an argument the number of pages to unmap, unlike mappages that gets the size of the memory to map, take that into consideration return 0 on success, -1 on failure
uint64 unmap_shared_pages(struct proc *p, uint64 addr, uint64 size)
{
    800026ea:	715d                	addi	sp,sp,-80
    800026ec:	e486                	sd	ra,72(sp)
    800026ee:	e0a2                	sd	s0,64(sp)
    800026f0:	fc26                	sd	s1,56(sp)
    800026f2:	f84a                	sd	s2,48(sp)
    800026f4:	f44e                	sd	s3,40(sp)
    800026f6:	f052                	sd	s4,32(sp)
    800026f8:	ec56                	sd	s5,24(sp)
    800026fa:	e85a                	sd	s6,16(sp)
    800026fc:	e45e                	sd	s7,8(sp)
    800026fe:	0880                	addi	s0,sp,80
    80002700:	89aa                	mv	s3,a0
  uint64 addr_page = PGROUNDDOWN(addr);
    80002702:	77fd                	lui	a5,0xfffff
    80002704:	00f5fab3          	and	s5,a1,a5
  pte_t *pte;
  int unmapped_bytes;
  for (unmapped_bytes = 0; unmapped_bytes < PGROUNDUP(size); unmapped_bytes += PGSIZE)
    80002708:	6a05                	lui	s4,0x1
    8000270a:	1a7d                	addi	s4,s4,-1
    8000270c:	9652                	add	a2,a2,s4
    8000270e:	00f67a33          	and	s4,a2,a5
    80002712:	060a0463          	beqz	s4,8000277a <unmap_shared_pages+0x90>
    80002716:	4481                	li	s1,0
    pte = walk(p->pagetable, addr_page + unmapped_bytes, 0);
    if (pte == 0)
    {
      return -1;
    }
    if (((*pte & PTE_V) == 0) || ((*pte & PTE_U) == 0) || ((*pte & PTE_S) == 0))
    80002718:	11100b13          	li	s6,273
    8000271c:	6b85                	lui	s7,0x1
    pte = walk(p->pagetable, addr_page + unmapped_bytes, 0);
    8000271e:	009a8933          	add	s2,s5,s1
    80002722:	4601                	li	a2,0
    80002724:	85ca                	mv	a1,s2
    80002726:	0509b503          	ld	a0,80(s3)
    8000272a:	fffff097          	auipc	ra,0xfffff
    8000272e:	89c080e7          	jalr	-1892(ra) # 80000fc6 <walk>
    if (pte == 0)
    80002732:	c531                	beqz	a0,8000277e <unmap_shared_pages+0x94>
    if (((*pte & PTE_V) == 0) || ((*pte & PTE_U) == 0) || ((*pte & PTE_S) == 0))
    80002734:	611c                	ld	a5,0(a0)
    80002736:	1117f793          	andi	a5,a5,273
    8000273a:	05679463          	bne	a5,s6,80002782 <unmap_shared_pages+0x98>
    {
      // error handling
      return -1;
    }
    uvmunmap(p->pagetable, addr_page + unmapped_bytes, 1, 1);
    8000273e:	4685                	li	a3,1
    80002740:	4605                	li	a2,1
    80002742:	85ca                	mv	a1,s2
    80002744:	0509b503          	ld	a0,80(s3)
    80002748:	fffff097          	auipc	ra,0xfffff
    8000274c:	b2c080e7          	jalr	-1236(ra) # 80001274 <uvmunmap>
  for (unmapped_bytes = 0; unmapped_bytes < PGROUNDUP(size); unmapped_bytes += PGSIZE)
    80002750:	94de                	add	s1,s1,s7
    80002752:	fd44e6e3          	bltu	s1,s4,8000271e <unmap_shared_pages+0x34>
  }

  p->sz -= unmapped_bytes;
    80002756:	0489b783          	ld	a5,72(s3)
    8000275a:	409784b3          	sub	s1,a5,s1
    8000275e:	0499b423          	sd	s1,72(s3)
  return 0;
    80002762:	4501                	li	a0,0
}
    80002764:	60a6                	ld	ra,72(sp)
    80002766:	6406                	ld	s0,64(sp)
    80002768:	74e2                	ld	s1,56(sp)
    8000276a:	7942                	ld	s2,48(sp)
    8000276c:	79a2                	ld	s3,40(sp)
    8000276e:	7a02                	ld	s4,32(sp)
    80002770:	6ae2                	ld	s5,24(sp)
    80002772:	6b42                	ld	s6,16(sp)
    80002774:	6ba2                	ld	s7,8(sp)
    80002776:	6161                	addi	sp,sp,80
    80002778:	8082                	ret
  for (unmapped_bytes = 0; unmapped_bytes < PGROUNDUP(size); unmapped_bytes += PGSIZE)
    8000277a:	84d2                	mv	s1,s4
    8000277c:	bfe9                	j	80002756 <unmap_shared_pages+0x6c>
      return -1;
    8000277e:	557d                	li	a0,-1
    80002780:	b7d5                	j	80002764 <unmap_shared_pages+0x7a>
      return -1;
    80002782:	557d                	li	a0,-1
    80002784:	b7c5                	j	80002764 <unmap_shared_pages+0x7a>

0000000080002786 <find_proc>:

struct proc *find_proc(uint64 pid)
{
    80002786:	7179                	addi	sp,sp,-48
    80002788:	f406                	sd	ra,40(sp)
    8000278a:	f022                	sd	s0,32(sp)
    8000278c:	ec26                	sd	s1,24(sp)
    8000278e:	e84a                	sd	s2,16(sp)
    80002790:	e44e                	sd	s3,8(sp)
    80002792:	1800                	addi	s0,sp,48
    80002794:	892a                	mv	s2,a0
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002796:	0000f497          	auipc	s1,0xf
    8000279a:	8da48493          	addi	s1,s1,-1830 # 80011070 <proc>
    8000279e:	00014997          	auipc	s3,0x14
    800027a2:	2d298993          	addi	s3,s3,722 # 80016a70 <shmem_queue>
  {
    acquire(&p->lock);
    800027a6:	8526                	mv	a0,s1
    800027a8:	ffffe097          	auipc	ra,0xffffe
    800027ac:	42e080e7          	jalr	1070(ra) # 80000bd6 <acquire>
    if (p->pid == pid)
    800027b0:	589c                	lw	a5,48(s1)
    800027b2:	01278c63          	beq	a5,s2,800027ca <find_proc+0x44>
    {
      return p;
    }
    release(&p->lock);
    800027b6:	8526                	mv	a0,s1
    800027b8:	ffffe097          	auipc	ra,0xffffe
    800027bc:	4d2080e7          	jalr	1234(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800027c0:	16848493          	addi	s1,s1,360
    800027c4:	ff3491e3          	bne	s1,s3,800027a6 <find_proc+0x20>
  }
  return 0;
    800027c8:	4481                	li	s1,0
    800027ca:	8526                	mv	a0,s1
    800027cc:	70a2                	ld	ra,40(sp)
    800027ce:	7402                	ld	s0,32(sp)
    800027d0:	64e2                	ld	s1,24(sp)
    800027d2:	6942                	ld	s2,16(sp)
    800027d4:	69a2                	ld	s3,8(sp)
    800027d6:	6145                	addi	sp,sp,48
    800027d8:	8082                	ret

00000000800027da <shmem_queue_init>:
  req->size     = 0;
}

void
shmem_queue_init(void)
{
    800027da:	1101                	addi	sp,sp,-32
    800027dc:	ec06                	sd	ra,24(sp)
    800027de:	e822                	sd	s0,16(sp)
    800027e0:	e426                	sd	s1,8(sp)
    800027e2:	1000                	addi	s0,sp,32
  initlock(&shmem_queue.lock, "shmem_queue");
    800027e4:	00014497          	auipc	s1,0x14
    800027e8:	28c48493          	addi	s1,s1,652 # 80016a70 <shmem_queue>
    800027ec:	00006597          	auipc	a1,0x6
    800027f0:	b1c58593          	addi	a1,a1,-1252 # 80008308 <states.0+0x30>
    800027f4:	8526                	mv	a0,s1
    800027f6:	ffffe097          	auipc	ra,0xffffe
    800027fa:	350080e7          	jalr	848(ra) # 80000b46 <initlock>
  
  shmem_queue.read_idx = -1;
    800027fe:	57fd                	li	a5,-1
    80002800:	18f4ac23          	sw	a5,408(s1)
  shmem_queue.write_idx = 0;
    80002804:	1804ae23          	sw	zero,412(s1)

  for (int i = 0; i < NSHMEM_REQS; i++) {
    80002808:	00014797          	auipc	a5,0x14
    8000280c:	28078793          	addi	a5,a5,640 # 80016a88 <shmem_queue+0x18>
    80002810:	00014697          	auipc	a3,0x14
    80002814:	3f868693          	addi	a3,a3,1016 # 80016c08 <shmem_queue+0x198>
  req->src_pid  = -1;
    80002818:	577d                	li	a4,-1
    8000281a:	c398                	sw	a4,0(a5)
  req->dst_pid  = -1;
    8000281c:	c3d8                	sw	a4,4(a5)
  req->src_va   = 0;
    8000281e:	0007b423          	sd	zero,8(a5)
  req->size     = 0;
    80002822:	0007b823          	sd	zero,16(a5)
  for (int i = 0; i < NSHMEM_REQS; i++) {
    80002826:	07e1                	addi	a5,a5,24
    80002828:	fed799e3          	bne	a5,a3,8000281a <shmem_queue_init+0x40>
    shmem_request_init(&shmem_queue.requests[i]);
  }
}
    8000282c:	60e2                	ld	ra,24(sp)
    8000282e:	6442                	ld	s0,16(sp)
    80002830:	64a2                	ld	s1,8(sp)
    80002832:	6105                	addi	sp,sp,32
    80002834:	8082                	ret

0000000080002836 <shmem_queue_insert>:

void
shmem_queue_insert(int src_pid, int dst_pid, uint64 src_va, uint64 size)
{
    80002836:	7139                	addi	sp,sp,-64
    80002838:	fc06                	sd	ra,56(sp)
    8000283a:	f822                	sd	s0,48(sp)
    8000283c:	f426                	sd	s1,40(sp)
    8000283e:	f04a                	sd	s2,32(sp)
    80002840:	ec4e                	sd	s3,24(sp)
    80002842:	e852                	sd	s4,16(sp)
    80002844:	e456                	sd	s5,8(sp)
    80002846:	0080                	addi	s0,sp,64
    80002848:	8aaa                	mv	s5,a0
    8000284a:	8a2e                	mv	s4,a1
    8000284c:	89b2                	mv	s3,a2
    8000284e:	8936                	mv	s2,a3
  acquire(&shmem_queue.lock);
    80002850:	00014497          	auipc	s1,0x14
    80002854:	22048493          	addi	s1,s1,544 # 80016a70 <shmem_queue>
    80002858:	8526                	mv	a0,s1
    8000285a:	ffffe097          	auipc	ra,0xffffe
    8000285e:	37c080e7          	jalr	892(ra) # 80000bd6 <acquire>

  while (shmem_queue.write_idx == shmem_queue.read_idx - 1)
    80002862:	19c4a783          	lw	a5,412(s1)
    80002866:	1984a703          	lw	a4,408(s1)
    8000286a:	fff7069b          	addiw	a3,a4,-1
    8000286e:	02f69063          	bne	a3,a5,8000288e <shmem_queue_insert+0x58>
      sleep(&shmem_queue, &shmem_queue.lock);
    80002872:	85a6                	mv	a1,s1
    80002874:	8526                	mv	a0,s1
    80002876:	00000097          	auipc	ra,0x0
    8000287a:	830080e7          	jalr	-2000(ra) # 800020a6 <sleep>
  while (shmem_queue.write_idx == shmem_queue.read_idx - 1)
    8000287e:	19c4a783          	lw	a5,412(s1)
    80002882:	1984a703          	lw	a4,408(s1)
    80002886:	fff7081b          	addiw	a6,a4,-1
    8000288a:	fef804e3          	beq	a6,a5,80002872 <shmem_queue_insert+0x3c>

  const uint idx = shmem_queue.write_idx;
  shmem_queue.requests[idx].src_pid = src_pid;
    8000288e:	00014897          	auipc	a7,0x14
    80002892:	1e288893          	addi	a7,a7,482 # 80016a70 <shmem_queue>
    80002896:	02079313          	slli	t1,a5,0x20
    8000289a:	02035313          	srli	t1,t1,0x20
    8000289e:	00131813          	slli	a6,t1,0x1
    800028a2:	006806b3          	add	a3,a6,t1
    800028a6:	068e                	slli	a3,a3,0x3
    800028a8:	96c6                	add	a3,a3,a7
    800028aa:	0156ac23          	sw	s5,24(a3)
  shmem_queue.requests[idx].dst_pid = dst_pid;
    800028ae:	006806b3          	add	a3,a6,t1
    800028b2:	068e                	slli	a3,a3,0x3
    800028b4:	96c6                	add	a3,a3,a7
    800028b6:	0146ae23          	sw	s4,28(a3)
  shmem_queue.requests[idx].src_va = src_va;
    800028ba:	006806b3          	add	a3,a6,t1
    800028be:	068e                	slli	a3,a3,0x3
    800028c0:	96c6                	add	a3,a3,a7
    800028c2:	0336b023          	sd	s3,32(a3)
  shmem_queue.requests[idx].size = size;
    800028c6:	0326b423          	sd	s2,40(a3)

  shmem_queue.write_idx = (shmem_queue.write_idx + 1) % NSHMEM_REQS;
    800028ca:	2785                	addiw	a5,a5,1
    800028cc:	41f7d69b          	sraiw	a3,a5,0x1f
    800028d0:	01c6d69b          	srliw	a3,a3,0x1c
    800028d4:	9fb5                	addw	a5,a5,a3
    800028d6:	8bbd                	andi	a5,a5,15
    800028d8:	9f95                	subw	a5,a5,a3
    800028da:	18f8ae23          	sw	a5,412(a7)

  if (shmem_queue.read_idx == -1)
    800028de:	57fd                	li	a5,-1
    800028e0:	02f70963          	beq	a4,a5,80002912 <shmem_queue_insert+0xdc>
      shmem_queue.read_idx = 0;

  wakeup(&shmem_queue);
    800028e4:	00014497          	auipc	s1,0x14
    800028e8:	18c48493          	addi	s1,s1,396 # 80016a70 <shmem_queue>
    800028ec:	8526                	mv	a0,s1
    800028ee:	00000097          	auipc	ra,0x0
    800028f2:	81c080e7          	jalr	-2020(ra) # 8000210a <wakeup>

  release(&shmem_queue.lock);
    800028f6:	8526                	mv	a0,s1
    800028f8:	ffffe097          	auipc	ra,0xffffe
    800028fc:	392080e7          	jalr	914(ra) # 80000c8a <release>
}
    80002900:	70e2                	ld	ra,56(sp)
    80002902:	7442                	ld	s0,48(sp)
    80002904:	74a2                	ld	s1,40(sp)
    80002906:	7902                	ld	s2,32(sp)
    80002908:	69e2                	ld	s3,24(sp)
    8000290a:	6a42                	ld	s4,16(sp)
    8000290c:	6aa2                	ld	s5,8(sp)
    8000290e:	6121                	addi	sp,sp,64
    80002910:	8082                	ret
      shmem_queue.read_idx = 0;
    80002912:	00014797          	auipc	a5,0x14
    80002916:	2e07ab23          	sw	zero,758(a5) # 80016c08 <shmem_queue+0x198>
    8000291a:	b7e9                	j	800028e4 <shmem_queue_insert+0xae>

000000008000291c <shmem_queue_remove>:

struct shmem_request
shmem_queue_remove(void)
{
    8000291c:	7139                	addi	sp,sp,-64
    8000291e:	fc06                	sd	ra,56(sp)
    80002920:	f822                	sd	s0,48(sp)
    80002922:	f426                	sd	s1,40(sp)
    80002924:	f04a                	sd	s2,32(sp)
    80002926:	ec4e                	sd	s3,24(sp)
    80002928:	e852                	sd	s4,16(sp)
    8000292a:	e456                	sd	s5,8(sp)
    8000292c:	e05a                	sd	s6,0(sp)
    8000292e:	0080                	addi	s0,sp,64
    80002930:	892a                	mv	s2,a0
  acquire(&shmem_queue.lock);
    80002932:	00014517          	auipc	a0,0x14
    80002936:	13e50513          	addi	a0,a0,318 # 80016a70 <shmem_queue>
    8000293a:	ffffe097          	auipc	ra,0xffffe
    8000293e:	29c080e7          	jalr	668(ra) # 80000bd6 <acquire>

  while (shmem_queue.read_idx == -1 || shmem_queue.read_idx == shmem_queue.write_idx)
    80002942:	00014497          	auipc	s1,0x14
    80002946:	12e48493          	addi	s1,s1,302 # 80016a70 <shmem_queue>
    8000294a:	59fd                	li	s3,-1
    8000294c:	a039                	j	8000295a <shmem_queue_remove+0x3e>
      sleep(&shmem_queue, &shmem_queue.lock);
    8000294e:	85a6                	mv	a1,s1
    80002950:	8526                	mv	a0,s1
    80002952:	fffff097          	auipc	ra,0xfffff
    80002956:	754080e7          	jalr	1876(ra) # 800020a6 <sleep>
  while (shmem_queue.read_idx == -1 || shmem_queue.read_idx == shmem_queue.write_idx)
    8000295a:	1984a783          	lw	a5,408(s1)
    8000295e:	ff3788e3          	beq	a5,s3,8000294e <shmem_queue_remove+0x32>
    80002962:	19c4a703          	lw	a4,412(s1)
    80002966:	fef704e3          	beq	a4,a5,8000294e <shmem_queue_remove+0x32>

  const uint idx = shmem_queue.read_idx;
  const struct shmem_request req = shmem_queue.requests[idx];
    8000296a:	00014497          	auipc	s1,0x14
    8000296e:	10648493          	addi	s1,s1,262 # 80016a70 <shmem_queue>
    80002972:	02079693          	slli	a3,a5,0x20
    80002976:	9281                	srli	a3,a3,0x20
    80002978:	00169713          	slli	a4,a3,0x1
    8000297c:	00d70633          	add	a2,a4,a3
    80002980:	060e                	slli	a2,a2,0x3
    80002982:	9626                	add	a2,a2,s1
    80002984:	01862b03          	lw	s6,24(a2) # 1018 <_entry-0x7fffefe8>
    80002988:	00d70633          	add	a2,a4,a3
    8000298c:	060e                	slli	a2,a2,0x3
    8000298e:	9626                	add	a2,a2,s1
    80002990:	01c62a83          	lw	s5,28(a2)
    80002994:	00d70633          	add	a2,a4,a3
    80002998:	060e                	slli	a2,a2,0x3
    8000299a:	9626                	add	a2,a2,s1
    8000299c:	02063a03          	ld	s4,32(a2)
    800029a0:	00d70633          	add	a2,a4,a3
    800029a4:	060e                	slli	a2,a2,0x3
    800029a6:	9626                	add	a2,a2,s1
    800029a8:	02863983          	ld	s3,40(a2)
  req->src_pid  = -1;
    800029ac:	00d70633          	add	a2,a4,a3
    800029b0:	060e                	slli	a2,a2,0x3
    800029b2:	9626                	add	a2,a2,s1
    800029b4:	55fd                	li	a1,-1
    800029b6:	ce0c                	sw	a1,24(a2)
  req->dst_pid  = -1;
    800029b8:	00d70633          	add	a2,a4,a3
    800029bc:	060e                	slli	a2,a2,0x3
    800029be:	9626                	add	a2,a2,s1
    800029c0:	ce4c                	sw	a1,28(a2)
  req->src_va   = 0;
    800029c2:	00d70633          	add	a2,a4,a3
    800029c6:	060e                	slli	a2,a2,0x3
    800029c8:	9626                	add	a2,a2,s1
    800029ca:	02063023          	sd	zero,32(a2)
  req->size     = 0;
    800029ce:	02063423          	sd	zero,40(a2)
  shmem_request_init(&shmem_queue.requests[idx]);

  shmem_queue.read_idx = (shmem_queue.read_idx + 1) % NSHMEM_REQS;
    800029d2:	2785                	addiw	a5,a5,1
    800029d4:	41f7d71b          	sraiw	a4,a5,0x1f
    800029d8:	01c7571b          	srliw	a4,a4,0x1c
    800029dc:	9fb9                	addw	a5,a5,a4
    800029de:	8bbd                	andi	a5,a5,15
    800029e0:	9f99                	subw	a5,a5,a4
    800029e2:	18f4ac23          	sw	a5,408(s1)

  wakeup(&shmem_queue);
    800029e6:	8526                	mv	a0,s1
    800029e8:	fffff097          	auipc	ra,0xfffff
    800029ec:	722080e7          	jalr	1826(ra) # 8000210a <wakeup>

  release(&shmem_queue.lock);
    800029f0:	8526                	mv	a0,s1
    800029f2:	ffffe097          	auipc	ra,0xffffe
    800029f6:	298080e7          	jalr	664(ra) # 80000c8a <release>

  return req;
    800029fa:	01692023          	sw	s6,0(s2)
    800029fe:	01592223          	sw	s5,4(s2)
    80002a02:	01493423          	sd	s4,8(s2)
    80002a06:	01393823          	sd	s3,16(s2)
    80002a0a:	854a                	mv	a0,s2
    80002a0c:	70e2                	ld	ra,56(sp)
    80002a0e:	7442                	ld	s0,48(sp)
    80002a10:	74a2                	ld	s1,40(sp)
    80002a12:	7902                	ld	s2,32(sp)
    80002a14:	69e2                	ld	s3,24(sp)
    80002a16:	6a42                	ld	s4,16(sp)
    80002a18:	6aa2                	ld	s5,8(sp)
    80002a1a:	6b02                	ld	s6,0(sp)
    80002a1c:	6121                	addi	sp,sp,64
    80002a1e:	8082                	ret

0000000080002a20 <swtch>:
    80002a20:	00153023          	sd	ra,0(a0)
    80002a24:	00253423          	sd	sp,8(a0)
    80002a28:	e900                	sd	s0,16(a0)
    80002a2a:	ed04                	sd	s1,24(a0)
    80002a2c:	03253023          	sd	s2,32(a0)
    80002a30:	03353423          	sd	s3,40(a0)
    80002a34:	03453823          	sd	s4,48(a0)
    80002a38:	03553c23          	sd	s5,56(a0)
    80002a3c:	05653023          	sd	s6,64(a0)
    80002a40:	05753423          	sd	s7,72(a0)
    80002a44:	05853823          	sd	s8,80(a0)
    80002a48:	05953c23          	sd	s9,88(a0)
    80002a4c:	07a53023          	sd	s10,96(a0)
    80002a50:	07b53423          	sd	s11,104(a0)
    80002a54:	0005b083          	ld	ra,0(a1)
    80002a58:	0085b103          	ld	sp,8(a1)
    80002a5c:	6980                	ld	s0,16(a1)
    80002a5e:	6d84                	ld	s1,24(a1)
    80002a60:	0205b903          	ld	s2,32(a1)
    80002a64:	0285b983          	ld	s3,40(a1)
    80002a68:	0305ba03          	ld	s4,48(a1)
    80002a6c:	0385ba83          	ld	s5,56(a1)
    80002a70:	0405bb03          	ld	s6,64(a1)
    80002a74:	0485bb83          	ld	s7,72(a1)
    80002a78:	0505bc03          	ld	s8,80(a1)
    80002a7c:	0585bc83          	ld	s9,88(a1)
    80002a80:	0605bd03          	ld	s10,96(a1)
    80002a84:	0685bd83          	ld	s11,104(a1)
    80002a88:	8082                	ret

0000000080002a8a <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002a8a:	1141                	addi	sp,sp,-16
    80002a8c:	e406                	sd	ra,8(sp)
    80002a8e:	e022                	sd	s0,0(sp)
    80002a90:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002a92:	00006597          	auipc	a1,0x6
    80002a96:	88658593          	addi	a1,a1,-1914 # 80008318 <states.0+0x40>
    80002a9a:	00014517          	auipc	a0,0x14
    80002a9e:	17650513          	addi	a0,a0,374 # 80016c10 <tickslock>
    80002aa2:	ffffe097          	auipc	ra,0xffffe
    80002aa6:	0a4080e7          	jalr	164(ra) # 80000b46 <initlock>
}
    80002aaa:	60a2                	ld	ra,8(sp)
    80002aac:	6402                	ld	s0,0(sp)
    80002aae:	0141                	addi	sp,sp,16
    80002ab0:	8082                	ret

0000000080002ab2 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002ab2:	1141                	addi	sp,sp,-16
    80002ab4:	e422                	sd	s0,8(sp)
    80002ab6:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r"(x));
    80002ab8:	00003797          	auipc	a5,0x3
    80002abc:	7b878793          	addi	a5,a5,1976 # 80006270 <kernelvec>
    80002ac0:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002ac4:	6422                	ld	s0,8(sp)
    80002ac6:	0141                	addi	sp,sp,16
    80002ac8:	8082                	ret

0000000080002aca <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002aca:	1141                	addi	sp,sp,-16
    80002acc:	e406                	sd	ra,8(sp)
    80002ace:	e022                	sd	s0,0(sp)
    80002ad0:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002ad2:	fffff097          	auipc	ra,0xfffff
    80002ad6:	f0a080e7          	jalr	-246(ra) # 800019dc <myproc>
  asm volatile("csrr %0, sstatus" : "=r"(x));
    80002ada:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002ade:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r"(x));
    80002ae0:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002ae4:	00004617          	auipc	a2,0x4
    80002ae8:	51c60613          	addi	a2,a2,1308 # 80007000 <_trampoline>
    80002aec:	00004697          	auipc	a3,0x4
    80002af0:	51468693          	addi	a3,a3,1300 # 80007000 <_trampoline>
    80002af4:	8e91                	sub	a3,a3,a2
    80002af6:	040007b7          	lui	a5,0x4000
    80002afa:	17fd                	addi	a5,a5,-1
    80002afc:	07b2                	slli	a5,a5,0xc
    80002afe:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r"(x));
    80002b00:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002b04:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r"(x));
    80002b06:	180026f3          	csrr	a3,satp
    80002b0a:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002b0c:	6d38                	ld	a4,88(a0)
    80002b0e:	6134                	ld	a3,64(a0)
    80002b10:	6585                	lui	a1,0x1
    80002b12:	96ae                	add	a3,a3,a1
    80002b14:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002b16:	6d38                	ld	a4,88(a0)
    80002b18:	00000697          	auipc	a3,0x0
    80002b1c:	13068693          	addi	a3,a3,304 # 80002c48 <usertrap>
    80002b20:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002b22:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r"(x));
    80002b24:	8692                	mv	a3,tp
    80002b26:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r"(x));
    80002b28:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002b2c:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002b30:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r"(x));
    80002b34:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002b38:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r"(x));
    80002b3a:	6f18                	ld	a4,24(a4)
    80002b3c:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002b40:	6928                	ld	a0,80(a0)
    80002b42:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002b44:	00004717          	auipc	a4,0x4
    80002b48:	55870713          	addi	a4,a4,1368 # 8000709c <userret>
    80002b4c:	8f11                	sub	a4,a4,a2
    80002b4e:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002b50:	577d                	li	a4,-1
    80002b52:	177e                	slli	a4,a4,0x3f
    80002b54:	8d59                	or	a0,a0,a4
    80002b56:	9782                	jalr	a5
}
    80002b58:	60a2                	ld	ra,8(sp)
    80002b5a:	6402                	ld	s0,0(sp)
    80002b5c:	0141                	addi	sp,sp,16
    80002b5e:	8082                	ret

0000000080002b60 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002b60:	1101                	addi	sp,sp,-32
    80002b62:	ec06                	sd	ra,24(sp)
    80002b64:	e822                	sd	s0,16(sp)
    80002b66:	e426                	sd	s1,8(sp)
    80002b68:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002b6a:	00014497          	auipc	s1,0x14
    80002b6e:	0a648493          	addi	s1,s1,166 # 80016c10 <tickslock>
    80002b72:	8526                	mv	a0,s1
    80002b74:	ffffe097          	auipc	ra,0xffffe
    80002b78:	062080e7          	jalr	98(ra) # 80000bd6 <acquire>
  ticks++;
    80002b7c:	00006517          	auipc	a0,0x6
    80002b80:	e1c50513          	addi	a0,a0,-484 # 80008998 <ticks>
    80002b84:	411c                	lw	a5,0(a0)
    80002b86:	2785                	addiw	a5,a5,1
    80002b88:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002b8a:	fffff097          	auipc	ra,0xfffff
    80002b8e:	580080e7          	jalr	1408(ra) # 8000210a <wakeup>
  release(&tickslock);
    80002b92:	8526                	mv	a0,s1
    80002b94:	ffffe097          	auipc	ra,0xffffe
    80002b98:	0f6080e7          	jalr	246(ra) # 80000c8a <release>
}
    80002b9c:	60e2                	ld	ra,24(sp)
    80002b9e:	6442                	ld	s0,16(sp)
    80002ba0:	64a2                	ld	s1,8(sp)
    80002ba2:	6105                	addi	sp,sp,32
    80002ba4:	8082                	ret

0000000080002ba6 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002ba6:	1101                	addi	sp,sp,-32
    80002ba8:	ec06                	sd	ra,24(sp)
    80002baa:	e822                	sd	s0,16(sp)
    80002bac:	e426                	sd	s1,8(sp)
    80002bae:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r"(x));
    80002bb0:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002bb4:	00074d63          	bltz	a4,80002bce <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002bb8:	57fd                	li	a5,-1
    80002bba:	17fe                	slli	a5,a5,0x3f
    80002bbc:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002bbe:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002bc0:	06f70363          	beq	a4,a5,80002c26 <devintr+0x80>
  }
}
    80002bc4:	60e2                	ld	ra,24(sp)
    80002bc6:	6442                	ld	s0,16(sp)
    80002bc8:	64a2                	ld	s1,8(sp)
    80002bca:	6105                	addi	sp,sp,32
    80002bcc:	8082                	ret
     (scause & 0xff) == 9){
    80002bce:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002bd2:	46a5                	li	a3,9
    80002bd4:	fed792e3          	bne	a5,a3,80002bb8 <devintr+0x12>
    int irq = plic_claim();
    80002bd8:	00003097          	auipc	ra,0x3
    80002bdc:	7a0080e7          	jalr	1952(ra) # 80006378 <plic_claim>
    80002be0:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002be2:	47a9                	li	a5,10
    80002be4:	02f50763          	beq	a0,a5,80002c12 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002be8:	4785                	li	a5,1
    80002bea:	02f50963          	beq	a0,a5,80002c1c <devintr+0x76>
    return 1;
    80002bee:	4505                	li	a0,1
    } else if(irq){
    80002bf0:	d8f1                	beqz	s1,80002bc4 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002bf2:	85a6                	mv	a1,s1
    80002bf4:	00005517          	auipc	a0,0x5
    80002bf8:	72c50513          	addi	a0,a0,1836 # 80008320 <states.0+0x48>
    80002bfc:	ffffe097          	auipc	ra,0xffffe
    80002c00:	98c080e7          	jalr	-1652(ra) # 80000588 <printf>
      plic_complete(irq);
    80002c04:	8526                	mv	a0,s1
    80002c06:	00003097          	auipc	ra,0x3
    80002c0a:	796080e7          	jalr	1942(ra) # 8000639c <plic_complete>
    return 1;
    80002c0e:	4505                	li	a0,1
    80002c10:	bf55                	j	80002bc4 <devintr+0x1e>
      uartintr();
    80002c12:	ffffe097          	auipc	ra,0xffffe
    80002c16:	d88080e7          	jalr	-632(ra) # 8000099a <uartintr>
    80002c1a:	b7ed                	j	80002c04 <devintr+0x5e>
      virtio_disk_intr();
    80002c1c:	00004097          	auipc	ra,0x4
    80002c20:	c4c080e7          	jalr	-948(ra) # 80006868 <virtio_disk_intr>
    80002c24:	b7c5                	j	80002c04 <devintr+0x5e>
    if(cpuid() == 0){
    80002c26:	fffff097          	auipc	ra,0xfffff
    80002c2a:	d8a080e7          	jalr	-630(ra) # 800019b0 <cpuid>
    80002c2e:	c901                	beqz	a0,80002c3e <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r"(x));
    80002c30:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002c34:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r"(x));
    80002c36:	14479073          	csrw	sip,a5
    return 2;
    80002c3a:	4509                	li	a0,2
    80002c3c:	b761                	j	80002bc4 <devintr+0x1e>
      clockintr();
    80002c3e:	00000097          	auipc	ra,0x0
    80002c42:	f22080e7          	jalr	-222(ra) # 80002b60 <clockintr>
    80002c46:	b7ed                	j	80002c30 <devintr+0x8a>

0000000080002c48 <usertrap>:
{
    80002c48:	1101                	addi	sp,sp,-32
    80002c4a:	ec06                	sd	ra,24(sp)
    80002c4c:	e822                	sd	s0,16(sp)
    80002c4e:	e426                	sd	s1,8(sp)
    80002c50:	e04a                	sd	s2,0(sp)
    80002c52:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r"(x));
    80002c54:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002c58:	1007f793          	andi	a5,a5,256
    80002c5c:	e3b1                	bnez	a5,80002ca0 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r"(x));
    80002c5e:	00003797          	auipc	a5,0x3
    80002c62:	61278793          	addi	a5,a5,1554 # 80006270 <kernelvec>
    80002c66:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002c6a:	fffff097          	auipc	ra,0xfffff
    80002c6e:	d72080e7          	jalr	-654(ra) # 800019dc <myproc>
    80002c72:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002c74:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r"(x));
    80002c76:	14102773          	csrr	a4,sepc
    80002c7a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r"(x));
    80002c7c:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002c80:	47a1                	li	a5,8
    80002c82:	02f70763          	beq	a4,a5,80002cb0 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002c86:	00000097          	auipc	ra,0x0
    80002c8a:	f20080e7          	jalr	-224(ra) # 80002ba6 <devintr>
    80002c8e:	892a                	mv	s2,a0
    80002c90:	c151                	beqz	a0,80002d14 <usertrap+0xcc>
  if(killed(p))
    80002c92:	8526                	mv	a0,s1
    80002c94:	fffff097          	auipc	ra,0xfffff
    80002c98:	6ba080e7          	jalr	1722(ra) # 8000234e <killed>
    80002c9c:	c929                	beqz	a0,80002cee <usertrap+0xa6>
    80002c9e:	a099                	j	80002ce4 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002ca0:	00005517          	auipc	a0,0x5
    80002ca4:	6a050513          	addi	a0,a0,1696 # 80008340 <states.0+0x68>
    80002ca8:	ffffe097          	auipc	ra,0xffffe
    80002cac:	896080e7          	jalr	-1898(ra) # 8000053e <panic>
    if(killed(p))
    80002cb0:	fffff097          	auipc	ra,0xfffff
    80002cb4:	69e080e7          	jalr	1694(ra) # 8000234e <killed>
    80002cb8:	e921                	bnez	a0,80002d08 <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002cba:	6cb8                	ld	a4,88(s1)
    80002cbc:	6f1c                	ld	a5,24(a4)
    80002cbe:	0791                	addi	a5,a5,4
    80002cc0:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r"(x));
    80002cc2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002cc6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r"(x));
    80002cca:	10079073          	csrw	sstatus,a5
    syscall();
    80002cce:	00000097          	auipc	ra,0x0
    80002cd2:	2d4080e7          	jalr	724(ra) # 80002fa2 <syscall>
  if(killed(p))
    80002cd6:	8526                	mv	a0,s1
    80002cd8:	fffff097          	auipc	ra,0xfffff
    80002cdc:	676080e7          	jalr	1654(ra) # 8000234e <killed>
    80002ce0:	c911                	beqz	a0,80002cf4 <usertrap+0xac>
    80002ce2:	4901                	li	s2,0
    exit(-1);
    80002ce4:	557d                	li	a0,-1
    80002ce6:	fffff097          	auipc	ra,0xfffff
    80002cea:	4f4080e7          	jalr	1268(ra) # 800021da <exit>
  if(which_dev == 2)
    80002cee:	4789                	li	a5,2
    80002cf0:	04f90f63          	beq	s2,a5,80002d4e <usertrap+0x106>
  usertrapret();
    80002cf4:	00000097          	auipc	ra,0x0
    80002cf8:	dd6080e7          	jalr	-554(ra) # 80002aca <usertrapret>
}
    80002cfc:	60e2                	ld	ra,24(sp)
    80002cfe:	6442                	ld	s0,16(sp)
    80002d00:	64a2                	ld	s1,8(sp)
    80002d02:	6902                	ld	s2,0(sp)
    80002d04:	6105                	addi	sp,sp,32
    80002d06:	8082                	ret
      exit(-1);
    80002d08:	557d                	li	a0,-1
    80002d0a:	fffff097          	auipc	ra,0xfffff
    80002d0e:	4d0080e7          	jalr	1232(ra) # 800021da <exit>
    80002d12:	b765                	j	80002cba <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r"(x));
    80002d14:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002d18:	5890                	lw	a2,48(s1)
    80002d1a:	00005517          	auipc	a0,0x5
    80002d1e:	64650513          	addi	a0,a0,1606 # 80008360 <states.0+0x88>
    80002d22:	ffffe097          	auipc	ra,0xffffe
    80002d26:	866080e7          	jalr	-1946(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r"(x));
    80002d2a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r"(x));
    80002d2e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d32:	00005517          	auipc	a0,0x5
    80002d36:	65e50513          	addi	a0,a0,1630 # 80008390 <states.0+0xb8>
    80002d3a:	ffffe097          	auipc	ra,0xffffe
    80002d3e:	84e080e7          	jalr	-1970(ra) # 80000588 <printf>
    setkilled(p);
    80002d42:	8526                	mv	a0,s1
    80002d44:	fffff097          	auipc	ra,0xfffff
    80002d48:	5de080e7          	jalr	1502(ra) # 80002322 <setkilled>
    80002d4c:	b769                	j	80002cd6 <usertrap+0x8e>
    yield();
    80002d4e:	fffff097          	auipc	ra,0xfffff
    80002d52:	31c080e7          	jalr	796(ra) # 8000206a <yield>
    80002d56:	bf79                	j	80002cf4 <usertrap+0xac>

0000000080002d58 <kerneltrap>:
{
    80002d58:	7179                	addi	sp,sp,-48
    80002d5a:	f406                	sd	ra,40(sp)
    80002d5c:	f022                	sd	s0,32(sp)
    80002d5e:	ec26                	sd	s1,24(sp)
    80002d60:	e84a                	sd	s2,16(sp)
    80002d62:	e44e                	sd	s3,8(sp)
    80002d64:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r"(x));
    80002d66:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r"(x));
    80002d6a:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r"(x));
    80002d6e:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002d72:	1004f793          	andi	a5,s1,256
    80002d76:	cb85                	beqz	a5,80002da6 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r"(x));
    80002d78:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002d7c:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002d7e:	ef85                	bnez	a5,80002db6 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002d80:	00000097          	auipc	ra,0x0
    80002d84:	e26080e7          	jalr	-474(ra) # 80002ba6 <devintr>
    80002d88:	cd1d                	beqz	a0,80002dc6 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d8a:	4789                	li	a5,2
    80002d8c:	06f50a63          	beq	a0,a5,80002e00 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r"(x));
    80002d90:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r"(x));
    80002d94:	10049073          	csrw	sstatus,s1
}
    80002d98:	70a2                	ld	ra,40(sp)
    80002d9a:	7402                	ld	s0,32(sp)
    80002d9c:	64e2                	ld	s1,24(sp)
    80002d9e:	6942                	ld	s2,16(sp)
    80002da0:	69a2                	ld	s3,8(sp)
    80002da2:	6145                	addi	sp,sp,48
    80002da4:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002da6:	00005517          	auipc	a0,0x5
    80002daa:	60a50513          	addi	a0,a0,1546 # 800083b0 <states.0+0xd8>
    80002dae:	ffffd097          	auipc	ra,0xffffd
    80002db2:	790080e7          	jalr	1936(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002db6:	00005517          	auipc	a0,0x5
    80002dba:	62250513          	addi	a0,a0,1570 # 800083d8 <states.0+0x100>
    80002dbe:	ffffd097          	auipc	ra,0xffffd
    80002dc2:	780080e7          	jalr	1920(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002dc6:	85ce                	mv	a1,s3
    80002dc8:	00005517          	auipc	a0,0x5
    80002dcc:	63050513          	addi	a0,a0,1584 # 800083f8 <states.0+0x120>
    80002dd0:	ffffd097          	auipc	ra,0xffffd
    80002dd4:	7b8080e7          	jalr	1976(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r"(x));
    80002dd8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r"(x));
    80002ddc:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002de0:	00005517          	auipc	a0,0x5
    80002de4:	62850513          	addi	a0,a0,1576 # 80008408 <states.0+0x130>
    80002de8:	ffffd097          	auipc	ra,0xffffd
    80002dec:	7a0080e7          	jalr	1952(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002df0:	00005517          	auipc	a0,0x5
    80002df4:	63050513          	addi	a0,a0,1584 # 80008420 <states.0+0x148>
    80002df8:	ffffd097          	auipc	ra,0xffffd
    80002dfc:	746080e7          	jalr	1862(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e00:	fffff097          	auipc	ra,0xfffff
    80002e04:	bdc080e7          	jalr	-1060(ra) # 800019dc <myproc>
    80002e08:	d541                	beqz	a0,80002d90 <kerneltrap+0x38>
    80002e0a:	fffff097          	auipc	ra,0xfffff
    80002e0e:	bd2080e7          	jalr	-1070(ra) # 800019dc <myproc>
    80002e12:	4d18                	lw	a4,24(a0)
    80002e14:	4791                	li	a5,4
    80002e16:	f6f71de3          	bne	a4,a5,80002d90 <kerneltrap+0x38>
    yield();
    80002e1a:	fffff097          	auipc	ra,0xfffff
    80002e1e:	250080e7          	jalr	592(ra) # 8000206a <yield>
    80002e22:	b7bd                	j	80002d90 <kerneltrap+0x38>

0000000080002e24 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002e24:	1101                	addi	sp,sp,-32
    80002e26:	ec06                	sd	ra,24(sp)
    80002e28:	e822                	sd	s0,16(sp)
    80002e2a:	e426                	sd	s1,8(sp)
    80002e2c:	1000                	addi	s0,sp,32
    80002e2e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002e30:	fffff097          	auipc	ra,0xfffff
    80002e34:	bac080e7          	jalr	-1108(ra) # 800019dc <myproc>
  switch (n)
    80002e38:	4795                	li	a5,5
    80002e3a:	0497e163          	bltu	a5,s1,80002e7c <argraw+0x58>
    80002e3e:	048a                	slli	s1,s1,0x2
    80002e40:	00005717          	auipc	a4,0x5
    80002e44:	61870713          	addi	a4,a4,1560 # 80008458 <states.0+0x180>
    80002e48:	94ba                	add	s1,s1,a4
    80002e4a:	409c                	lw	a5,0(s1)
    80002e4c:	97ba                	add	a5,a5,a4
    80002e4e:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80002e50:	6d3c                	ld	a5,88(a0)
    80002e52:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002e54:	60e2                	ld	ra,24(sp)
    80002e56:	6442                	ld	s0,16(sp)
    80002e58:	64a2                	ld	s1,8(sp)
    80002e5a:	6105                	addi	sp,sp,32
    80002e5c:	8082                	ret
    return p->trapframe->a1;
    80002e5e:	6d3c                	ld	a5,88(a0)
    80002e60:	7fa8                	ld	a0,120(a5)
    80002e62:	bfcd                	j	80002e54 <argraw+0x30>
    return p->trapframe->a2;
    80002e64:	6d3c                	ld	a5,88(a0)
    80002e66:	63c8                	ld	a0,128(a5)
    80002e68:	b7f5                	j	80002e54 <argraw+0x30>
    return p->trapframe->a3;
    80002e6a:	6d3c                	ld	a5,88(a0)
    80002e6c:	67c8                	ld	a0,136(a5)
    80002e6e:	b7dd                	j	80002e54 <argraw+0x30>
    return p->trapframe->a4;
    80002e70:	6d3c                	ld	a5,88(a0)
    80002e72:	6bc8                	ld	a0,144(a5)
    80002e74:	b7c5                	j	80002e54 <argraw+0x30>
    return p->trapframe->a5;
    80002e76:	6d3c                	ld	a5,88(a0)
    80002e78:	6fc8                	ld	a0,152(a5)
    80002e7a:	bfe9                	j	80002e54 <argraw+0x30>
  panic("argraw");
    80002e7c:	00005517          	auipc	a0,0x5
    80002e80:	5b450513          	addi	a0,a0,1460 # 80008430 <states.0+0x158>
    80002e84:	ffffd097          	auipc	ra,0xffffd
    80002e88:	6ba080e7          	jalr	1722(ra) # 8000053e <panic>

0000000080002e8c <fetchaddr>:
{
    80002e8c:	1101                	addi	sp,sp,-32
    80002e8e:	ec06                	sd	ra,24(sp)
    80002e90:	e822                	sd	s0,16(sp)
    80002e92:	e426                	sd	s1,8(sp)
    80002e94:	e04a                	sd	s2,0(sp)
    80002e96:	1000                	addi	s0,sp,32
    80002e98:	84aa                	mv	s1,a0
    80002e9a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002e9c:	fffff097          	auipc	ra,0xfffff
    80002ea0:	b40080e7          	jalr	-1216(ra) # 800019dc <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002ea4:	653c                	ld	a5,72(a0)
    80002ea6:	02f4f863          	bgeu	s1,a5,80002ed6 <fetchaddr+0x4a>
    80002eaa:	00848713          	addi	a4,s1,8
    80002eae:	02e7e663          	bltu	a5,a4,80002eda <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002eb2:	46a1                	li	a3,8
    80002eb4:	8626                	mv	a2,s1
    80002eb6:	85ca                	mv	a1,s2
    80002eb8:	6928                	ld	a0,80(a0)
    80002eba:	fffff097          	auipc	ra,0xfffff
    80002ebe:	852080e7          	jalr	-1966(ra) # 8000170c <copyin>
    80002ec2:	00a03533          	snez	a0,a0
    80002ec6:	40a00533          	neg	a0,a0
}
    80002eca:	60e2                	ld	ra,24(sp)
    80002ecc:	6442                	ld	s0,16(sp)
    80002ece:	64a2                	ld	s1,8(sp)
    80002ed0:	6902                	ld	s2,0(sp)
    80002ed2:	6105                	addi	sp,sp,32
    80002ed4:	8082                	ret
    return -1;
    80002ed6:	557d                	li	a0,-1
    80002ed8:	bfcd                	j	80002eca <fetchaddr+0x3e>
    80002eda:	557d                	li	a0,-1
    80002edc:	b7fd                	j	80002eca <fetchaddr+0x3e>

0000000080002ede <fetchstr>:
{
    80002ede:	7179                	addi	sp,sp,-48
    80002ee0:	f406                	sd	ra,40(sp)
    80002ee2:	f022                	sd	s0,32(sp)
    80002ee4:	ec26                	sd	s1,24(sp)
    80002ee6:	e84a                	sd	s2,16(sp)
    80002ee8:	e44e                	sd	s3,8(sp)
    80002eea:	1800                	addi	s0,sp,48
    80002eec:	892a                	mv	s2,a0
    80002eee:	84ae                	mv	s1,a1
    80002ef0:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002ef2:	fffff097          	auipc	ra,0xfffff
    80002ef6:	aea080e7          	jalr	-1302(ra) # 800019dc <myproc>
  if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80002efa:	86ce                	mv	a3,s3
    80002efc:	864a                	mv	a2,s2
    80002efe:	85a6                	mv	a1,s1
    80002f00:	6928                	ld	a0,80(a0)
    80002f02:	fffff097          	auipc	ra,0xfffff
    80002f06:	898080e7          	jalr	-1896(ra) # 8000179a <copyinstr>
    80002f0a:	00054e63          	bltz	a0,80002f26 <fetchstr+0x48>
  return strlen(buf);
    80002f0e:	8526                	mv	a0,s1
    80002f10:	ffffe097          	auipc	ra,0xffffe
    80002f14:	f3e080e7          	jalr	-194(ra) # 80000e4e <strlen>
}
    80002f18:	70a2                	ld	ra,40(sp)
    80002f1a:	7402                	ld	s0,32(sp)
    80002f1c:	64e2                	ld	s1,24(sp)
    80002f1e:	6942                	ld	s2,16(sp)
    80002f20:	69a2                	ld	s3,8(sp)
    80002f22:	6145                	addi	sp,sp,48
    80002f24:	8082                	ret
    return -1;
    80002f26:	557d                	li	a0,-1
    80002f28:	bfc5                	j	80002f18 <fetchstr+0x3a>

0000000080002f2a <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80002f2a:	1101                	addi	sp,sp,-32
    80002f2c:	ec06                	sd	ra,24(sp)
    80002f2e:	e822                	sd	s0,16(sp)
    80002f30:	e426                	sd	s1,8(sp)
    80002f32:	1000                	addi	s0,sp,32
    80002f34:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f36:	00000097          	auipc	ra,0x0
    80002f3a:	eee080e7          	jalr	-274(ra) # 80002e24 <argraw>
    80002f3e:	c088                	sw	a0,0(s1)
}
    80002f40:	60e2                	ld	ra,24(sp)
    80002f42:	6442                	ld	s0,16(sp)
    80002f44:	64a2                	ld	s1,8(sp)
    80002f46:	6105                	addi	sp,sp,32
    80002f48:	8082                	ret

0000000080002f4a <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    80002f4a:	1101                	addi	sp,sp,-32
    80002f4c:	ec06                	sd	ra,24(sp)
    80002f4e:	e822                	sd	s0,16(sp)
    80002f50:	e426                	sd	s1,8(sp)
    80002f52:	1000                	addi	s0,sp,32
    80002f54:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f56:	00000097          	auipc	ra,0x0
    80002f5a:	ece080e7          	jalr	-306(ra) # 80002e24 <argraw>
    80002f5e:	e088                	sd	a0,0(s1)
}
    80002f60:	60e2                	ld	ra,24(sp)
    80002f62:	6442                	ld	s0,16(sp)
    80002f64:	64a2                	ld	s1,8(sp)
    80002f66:	6105                	addi	sp,sp,32
    80002f68:	8082                	ret

0000000080002f6a <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002f6a:	7179                	addi	sp,sp,-48
    80002f6c:	f406                	sd	ra,40(sp)
    80002f6e:	f022                	sd	s0,32(sp)
    80002f70:	ec26                	sd	s1,24(sp)
    80002f72:	e84a                	sd	s2,16(sp)
    80002f74:	1800                	addi	s0,sp,48
    80002f76:	84ae                	mv	s1,a1
    80002f78:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002f7a:	fd840593          	addi	a1,s0,-40
    80002f7e:	00000097          	auipc	ra,0x0
    80002f82:	fcc080e7          	jalr	-52(ra) # 80002f4a <argaddr>
  return fetchstr(addr, buf, max);
    80002f86:	864a                	mv	a2,s2
    80002f88:	85a6                	mv	a1,s1
    80002f8a:	fd843503          	ld	a0,-40(s0)
    80002f8e:	00000097          	auipc	ra,0x0
    80002f92:	f50080e7          	jalr	-176(ra) # 80002ede <fetchstr>
}
    80002f96:	70a2                	ld	ra,40(sp)
    80002f98:	7402                	ld	s0,32(sp)
    80002f9a:	64e2                	ld	s1,24(sp)
    80002f9c:	6942                	ld	s2,16(sp)
    80002f9e:	6145                	addi	sp,sp,48
    80002fa0:	8082                	ret

0000000080002fa2 <syscall>:
    [SYS_map_shared_pages] sys_map_shared_pages,
    [SYS_unmap_shared_pages] sys_unmap_shared_pages,
};

void syscall(void)
{
    80002fa2:	1101                	addi	sp,sp,-32
    80002fa4:	ec06                	sd	ra,24(sp)
    80002fa6:	e822                	sd	s0,16(sp)
    80002fa8:	e426                	sd	s1,8(sp)
    80002faa:	e04a                	sd	s2,0(sp)
    80002fac:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002fae:	fffff097          	auipc	ra,0xfffff
    80002fb2:	a2e080e7          	jalr	-1490(ra) # 800019dc <myproc>
    80002fb6:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002fb8:	05853903          	ld	s2,88(a0)
    80002fbc:	0a893783          	ld	a5,168(s2)
    80002fc0:	0007869b          	sext.w	a3,a5
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002fc4:	37fd                	addiw	a5,a5,-1
    80002fc6:	476d                	li	a4,27
    80002fc8:	00f76f63          	bltu	a4,a5,80002fe6 <syscall+0x44>
    80002fcc:	00369713          	slli	a4,a3,0x3
    80002fd0:	00005797          	auipc	a5,0x5
    80002fd4:	4a078793          	addi	a5,a5,1184 # 80008470 <syscalls>
    80002fd8:	97ba                	add	a5,a5,a4
    80002fda:	639c                	ld	a5,0(a5)
    80002fdc:	c789                	beqz	a5,80002fe6 <syscall+0x44>
  {
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002fde:	9782                	jalr	a5
    80002fe0:	06a93823          	sd	a0,112(s2)
    80002fe4:	a839                	j	80003002 <syscall+0x60>
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    80002fe6:	15848613          	addi	a2,s1,344
    80002fea:	588c                	lw	a1,48(s1)
    80002fec:	00005517          	auipc	a0,0x5
    80002ff0:	44c50513          	addi	a0,a0,1100 # 80008438 <states.0+0x160>
    80002ff4:	ffffd097          	auipc	ra,0xffffd
    80002ff8:	594080e7          	jalr	1428(ra) # 80000588 <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002ffc:	6cbc                	ld	a5,88(s1)
    80002ffe:	577d                	li	a4,-1
    80003000:	fbb8                	sd	a4,112(a5)
  }
}
    80003002:	60e2                	ld	ra,24(sp)
    80003004:	6442                	ld	s0,16(sp)
    80003006:	64a2                	ld	s1,8(sp)
    80003008:	6902                	ld	s2,0(sp)
    8000300a:	6105                	addi	sp,sp,32
    8000300c:	8082                	ret

000000008000300e <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000300e:	1101                	addi	sp,sp,-32
    80003010:	ec06                	sd	ra,24(sp)
    80003012:	e822                	sd	s0,16(sp)
    80003014:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80003016:	fec40593          	addi	a1,s0,-20
    8000301a:	4501                	li	a0,0
    8000301c:	00000097          	auipc	ra,0x0
    80003020:	f0e080e7          	jalr	-242(ra) # 80002f2a <argint>
  exit(n);
    80003024:	fec42503          	lw	a0,-20(s0)
    80003028:	fffff097          	auipc	ra,0xfffff
    8000302c:	1b2080e7          	jalr	434(ra) # 800021da <exit>
  return 0; // not reached
}
    80003030:	4501                	li	a0,0
    80003032:	60e2                	ld	ra,24(sp)
    80003034:	6442                	ld	s0,16(sp)
    80003036:	6105                	addi	sp,sp,32
    80003038:	8082                	ret

000000008000303a <sys_getpid>:

uint64
sys_getpid(void)
{
    8000303a:	1141                	addi	sp,sp,-16
    8000303c:	e406                	sd	ra,8(sp)
    8000303e:	e022                	sd	s0,0(sp)
    80003040:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003042:	fffff097          	auipc	ra,0xfffff
    80003046:	99a080e7          	jalr	-1638(ra) # 800019dc <myproc>
}
    8000304a:	5908                	lw	a0,48(a0)
    8000304c:	60a2                	ld	ra,8(sp)
    8000304e:	6402                	ld	s0,0(sp)
    80003050:	0141                	addi	sp,sp,16
    80003052:	8082                	ret

0000000080003054 <sys_fork>:

uint64
sys_fork(void)
{
    80003054:	1141                	addi	sp,sp,-16
    80003056:	e406                	sd	ra,8(sp)
    80003058:	e022                	sd	s0,0(sp)
    8000305a:	0800                	addi	s0,sp,16
  return fork();
    8000305c:	fffff097          	auipc	ra,0xfffff
    80003060:	d58080e7          	jalr	-680(ra) # 80001db4 <fork>
}
    80003064:	60a2                	ld	ra,8(sp)
    80003066:	6402                	ld	s0,0(sp)
    80003068:	0141                	addi	sp,sp,16
    8000306a:	8082                	ret

000000008000306c <sys_wait>:

uint64
sys_wait(void)
{
    8000306c:	1101                	addi	sp,sp,-32
    8000306e:	ec06                	sd	ra,24(sp)
    80003070:	e822                	sd	s0,16(sp)
    80003072:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80003074:	fe840593          	addi	a1,s0,-24
    80003078:	4501                	li	a0,0
    8000307a:	00000097          	auipc	ra,0x0
    8000307e:	ed0080e7          	jalr	-304(ra) # 80002f4a <argaddr>
  return wait(p);
    80003082:	fe843503          	ld	a0,-24(s0)
    80003086:	fffff097          	auipc	ra,0xfffff
    8000308a:	2fa080e7          	jalr	762(ra) # 80002380 <wait>
}
    8000308e:	60e2                	ld	ra,24(sp)
    80003090:	6442                	ld	s0,16(sp)
    80003092:	6105                	addi	sp,sp,32
    80003094:	8082                	ret

0000000080003096 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003096:	7179                	addi	sp,sp,-48
    80003098:	f406                	sd	ra,40(sp)
    8000309a:	f022                	sd	s0,32(sp)
    8000309c:	ec26                	sd	s1,24(sp)
    8000309e:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    800030a0:	fdc40593          	addi	a1,s0,-36
    800030a4:	4501                	li	a0,0
    800030a6:	00000097          	auipc	ra,0x0
    800030aa:	e84080e7          	jalr	-380(ra) # 80002f2a <argint>
  addr = myproc()->sz;
    800030ae:	fffff097          	auipc	ra,0xfffff
    800030b2:	92e080e7          	jalr	-1746(ra) # 800019dc <myproc>
    800030b6:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    800030b8:	fdc42503          	lw	a0,-36(s0)
    800030bc:	fffff097          	auipc	ra,0xfffff
    800030c0:	c9c080e7          	jalr	-868(ra) # 80001d58 <growproc>
    800030c4:	00054863          	bltz	a0,800030d4 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    800030c8:	8526                	mv	a0,s1
    800030ca:	70a2                	ld	ra,40(sp)
    800030cc:	7402                	ld	s0,32(sp)
    800030ce:	64e2                	ld	s1,24(sp)
    800030d0:	6145                	addi	sp,sp,48
    800030d2:	8082                	ret
    return -1;
    800030d4:	54fd                	li	s1,-1
    800030d6:	bfcd                	j	800030c8 <sys_sbrk+0x32>

00000000800030d8 <sys_sleep>:

uint64
sys_sleep(void)
{
    800030d8:	7139                	addi	sp,sp,-64
    800030da:	fc06                	sd	ra,56(sp)
    800030dc:	f822                	sd	s0,48(sp)
    800030de:	f426                	sd	s1,40(sp)
    800030e0:	f04a                	sd	s2,32(sp)
    800030e2:	ec4e                	sd	s3,24(sp)
    800030e4:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800030e6:	fcc40593          	addi	a1,s0,-52
    800030ea:	4501                	li	a0,0
    800030ec:	00000097          	auipc	ra,0x0
    800030f0:	e3e080e7          	jalr	-450(ra) # 80002f2a <argint>
  acquire(&tickslock);
    800030f4:	00014517          	auipc	a0,0x14
    800030f8:	b1c50513          	addi	a0,a0,-1252 # 80016c10 <tickslock>
    800030fc:	ffffe097          	auipc	ra,0xffffe
    80003100:	ada080e7          	jalr	-1318(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80003104:	00006917          	auipc	s2,0x6
    80003108:	89492903          	lw	s2,-1900(s2) # 80008998 <ticks>
  while (ticks - ticks0 < n)
    8000310c:	fcc42783          	lw	a5,-52(s0)
    80003110:	cf9d                	beqz	a5,8000314e <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003112:	00014997          	auipc	s3,0x14
    80003116:	afe98993          	addi	s3,s3,-1282 # 80016c10 <tickslock>
    8000311a:	00006497          	auipc	s1,0x6
    8000311e:	87e48493          	addi	s1,s1,-1922 # 80008998 <ticks>
    if (killed(myproc()))
    80003122:	fffff097          	auipc	ra,0xfffff
    80003126:	8ba080e7          	jalr	-1862(ra) # 800019dc <myproc>
    8000312a:	fffff097          	auipc	ra,0xfffff
    8000312e:	224080e7          	jalr	548(ra) # 8000234e <killed>
    80003132:	ed15                	bnez	a0,8000316e <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003134:	85ce                	mv	a1,s3
    80003136:	8526                	mv	a0,s1
    80003138:	fffff097          	auipc	ra,0xfffff
    8000313c:	f6e080e7          	jalr	-146(ra) # 800020a6 <sleep>
  while (ticks - ticks0 < n)
    80003140:	409c                	lw	a5,0(s1)
    80003142:	412787bb          	subw	a5,a5,s2
    80003146:	fcc42703          	lw	a4,-52(s0)
    8000314a:	fce7ece3          	bltu	a5,a4,80003122 <sys_sleep+0x4a>
  }
  release(&tickslock);
    8000314e:	00014517          	auipc	a0,0x14
    80003152:	ac250513          	addi	a0,a0,-1342 # 80016c10 <tickslock>
    80003156:	ffffe097          	auipc	ra,0xffffe
    8000315a:	b34080e7          	jalr	-1228(ra) # 80000c8a <release>
  return 0;
    8000315e:	4501                	li	a0,0
}
    80003160:	70e2                	ld	ra,56(sp)
    80003162:	7442                	ld	s0,48(sp)
    80003164:	74a2                	ld	s1,40(sp)
    80003166:	7902                	ld	s2,32(sp)
    80003168:	69e2                	ld	s3,24(sp)
    8000316a:	6121                	addi	sp,sp,64
    8000316c:	8082                	ret
      release(&tickslock);
    8000316e:	00014517          	auipc	a0,0x14
    80003172:	aa250513          	addi	a0,a0,-1374 # 80016c10 <tickslock>
    80003176:	ffffe097          	auipc	ra,0xffffe
    8000317a:	b14080e7          	jalr	-1260(ra) # 80000c8a <release>
      return -1;
    8000317e:	557d                	li	a0,-1
    80003180:	b7c5                	j	80003160 <sys_sleep+0x88>

0000000080003182 <sys_kill>:

uint64
sys_kill(void)
{
    80003182:	1101                	addi	sp,sp,-32
    80003184:	ec06                	sd	ra,24(sp)
    80003186:	e822                	sd	s0,16(sp)
    80003188:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    8000318a:	fec40593          	addi	a1,s0,-20
    8000318e:	4501                	li	a0,0
    80003190:	00000097          	auipc	ra,0x0
    80003194:	d9a080e7          	jalr	-614(ra) # 80002f2a <argint>
  return kill(pid);
    80003198:	fec42503          	lw	a0,-20(s0)
    8000319c:	fffff097          	auipc	ra,0xfffff
    800031a0:	114080e7          	jalr	276(ra) # 800022b0 <kill>
}
    800031a4:	60e2                	ld	ra,24(sp)
    800031a6:	6442                	ld	s0,16(sp)
    800031a8:	6105                	addi	sp,sp,32
    800031aa:	8082                	ret

00000000800031ac <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800031ac:	1101                	addi	sp,sp,-32
    800031ae:	ec06                	sd	ra,24(sp)
    800031b0:	e822                	sd	s0,16(sp)
    800031b2:	e426                	sd	s1,8(sp)
    800031b4:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800031b6:	00014517          	auipc	a0,0x14
    800031ba:	a5a50513          	addi	a0,a0,-1446 # 80016c10 <tickslock>
    800031be:	ffffe097          	auipc	ra,0xffffe
    800031c2:	a18080e7          	jalr	-1512(ra) # 80000bd6 <acquire>
  xticks = ticks;
    800031c6:	00005497          	auipc	s1,0x5
    800031ca:	7d24a483          	lw	s1,2002(s1) # 80008998 <ticks>
  release(&tickslock);
    800031ce:	00014517          	auipc	a0,0x14
    800031d2:	a4250513          	addi	a0,a0,-1470 # 80016c10 <tickslock>
    800031d6:	ffffe097          	auipc	ra,0xffffe
    800031da:	ab4080e7          	jalr	-1356(ra) # 80000c8a <release>
  return xticks;
}
    800031de:	02049513          	slli	a0,s1,0x20
    800031e2:	9101                	srli	a0,a0,0x20
    800031e4:	60e2                	ld	ra,24(sp)
    800031e6:	6442                	ld	s0,16(sp)
    800031e8:	64a2                	ld	s1,8(sp)
    800031ea:	6105                	addi	sp,sp,32
    800031ec:	8082                	ret

00000000800031ee <sys_map_shared_pages>:

uint64 sys_map_shared_pages(void)
{
    800031ee:	7139                	addi	sp,sp,-64
    800031f0:	fc06                	sd	ra,56(sp)
    800031f2:	f822                	sd	s0,48(sp)
    800031f4:	f426                	sd	s1,40(sp)
    800031f6:	0080                	addi	s0,sp,64
  uint64 src_pid;
  uint64 dst_pid;
  uint64 src_va;
  uint64 size;

  argaddr(0, &src_pid);
    800031f8:	fd840593          	addi	a1,s0,-40
    800031fc:	4501                	li	a0,0
    800031fe:	00000097          	auipc	ra,0x0
    80003202:	d4c080e7          	jalr	-692(ra) # 80002f4a <argaddr>
  argaddr(1, &dst_pid);
    80003206:	fd040593          	addi	a1,s0,-48
    8000320a:	4505                	li	a0,1
    8000320c:	00000097          	auipc	ra,0x0
    80003210:	d3e080e7          	jalr	-706(ra) # 80002f4a <argaddr>
  argaddr(2, &src_va);
    80003214:	fc840593          	addi	a1,s0,-56
    80003218:	4509                	li	a0,2
    8000321a:	00000097          	auipc	ra,0x0
    8000321e:	d30080e7          	jalr	-720(ra) # 80002f4a <argaddr>
  argaddr(3, &size);
    80003222:	fc040593          	addi	a1,s0,-64
    80003226:	450d                	li	a0,3
    80003228:	00000097          	auipc	ra,0x0
    8000322c:	d22080e7          	jalr	-734(ra) # 80002f4a <argaddr>

  struct proc *src_proc = find_proc(src_pid);
    80003230:	fd843503          	ld	a0,-40(s0)
    80003234:	fffff097          	auipc	ra,0xfffff
    80003238:	552080e7          	jalr	1362(ra) # 80002786 <find_proc>
    8000323c:	84aa                	mv	s1,a0
  struct proc *dst_proc = find_proc(dst_pid);
    8000323e:	fd043503          	ld	a0,-48(s0)
    80003242:	fffff097          	auipc	ra,0xfffff
    80003246:	544080e7          	jalr	1348(ra) # 80002786 <find_proc>

  if (src_proc == 0 || dst_proc == 0)
    8000324a:	c485                	beqz	s1,80003272 <sys_map_shared_pages+0x84>
    8000324c:	85aa                	mv	a1,a0
    8000324e:	c505                	beqz	a0,80003276 <sys_map_shared_pages+0x88>
  {
    return -1;
  }

  uint64 dst_va = map_shared_pages(src_proc, dst_proc, src_va, size);
    80003250:	fc043683          	ld	a3,-64(s0)
    80003254:	fc843603          	ld	a2,-56(s0)
    80003258:	8526                	mv	a0,s1
    8000325a:	fffff097          	auipc	ra,0xfffff
    8000325e:	3ae080e7          	jalr	942(ra) # 80002608 <map_shared_pages>

  if (dst_va == 0)
    80003262:	c511                	beqz	a0,8000326e <sys_map_shared_pages+0x80>
  {
    return -1;
  }

  return dst_va;
}
    80003264:	70e2                	ld	ra,56(sp)
    80003266:	7442                	ld	s0,48(sp)
    80003268:	74a2                	ld	s1,40(sp)
    8000326a:	6121                	addi	sp,sp,64
    8000326c:	8082                	ret
    return -1;
    8000326e:	557d                	li	a0,-1
    80003270:	bfd5                	j	80003264 <sys_map_shared_pages+0x76>
    return -1;
    80003272:	557d                	li	a0,-1
    80003274:	bfc5                	j	80003264 <sys_map_shared_pages+0x76>
    80003276:	557d                	li	a0,-1
    80003278:	b7f5                	j	80003264 <sys_map_shared_pages+0x76>

000000008000327a <sys_unmap_shared_pages>:

uint64 sys_unmap_shared_pages(void)
{
    8000327a:	7179                	addi	sp,sp,-48
    8000327c:	f406                	sd	ra,40(sp)
    8000327e:	f022                	sd	s0,32(sp)
    80003280:	1800                	addi	s0,sp,48
  uint64 pid;
  uint64 addr;
  uint64 size;

  argaddr(0, &pid);
    80003282:	fe840593          	addi	a1,s0,-24
    80003286:	4501                	li	a0,0
    80003288:	00000097          	auipc	ra,0x0
    8000328c:	cc2080e7          	jalr	-830(ra) # 80002f4a <argaddr>
  argaddr(1, &addr);
    80003290:	fe040593          	addi	a1,s0,-32
    80003294:	4505                	li	a0,1
    80003296:	00000097          	auipc	ra,0x0
    8000329a:	cb4080e7          	jalr	-844(ra) # 80002f4a <argaddr>
  argaddr(2, &size);
    8000329e:	fd840593          	addi	a1,s0,-40
    800032a2:	4509                	li	a0,2
    800032a4:	00000097          	auipc	ra,0x0
    800032a8:	ca6080e7          	jalr	-858(ra) # 80002f4a <argaddr>

  struct proc *proc = find_proc(pid);
    800032ac:	fe843503          	ld	a0,-24(s0)
    800032b0:	fffff097          	auipc	ra,0xfffff
    800032b4:	4d6080e7          	jalr	1238(ra) # 80002786 <find_proc>

  if (proc == 0)
    800032b8:	cd09                	beqz	a0,800032d2 <sys_unmap_shared_pages+0x58>
  {
    return -1;
  }

  return unmap_shared_pages(proc, addr, size);
    800032ba:	fd843603          	ld	a2,-40(s0)
    800032be:	fe043583          	ld	a1,-32(s0)
    800032c2:	fffff097          	auipc	ra,0xfffff
    800032c6:	428080e7          	jalr	1064(ra) # 800026ea <unmap_shared_pages>
}
    800032ca:	70a2                	ld	ra,40(sp)
    800032cc:	7402                	ld	s0,32(sp)
    800032ce:	6145                	addi	sp,sp,48
    800032d0:	8082                	ret
    return -1;
    800032d2:	557d                	li	a0,-1
    800032d4:	bfdd                	j	800032ca <sys_unmap_shared_pages+0x50>

00000000800032d6 <sys_crypto_op>:
    0x00, 0x00, 0x00, 0x00};

uint64 sys_crypto_op(void)
{
  // Crypto server process not initialized yet
  if (crypto_srv_proc == 0)
    800032d6:	00005797          	auipc	a5,0x5
    800032da:	6ca7b783          	ld	a5,1738(a5) # 800089a0 <crypto_srv_proc>
    800032de:	cbb9                	beqz	a5,80003334 <sys_crypto_op+0x5e>
{
    800032e0:	1101                	addi	sp,sp,-32
    800032e2:	ec06                	sd	ra,24(sp)
    800032e4:	e822                	sd	s0,16(sp)
    800032e6:	1000                	addi	s0,sp,32
  }

  uint64 crypto_op;
  uint64 size;

  argaddr(0, &crypto_op);
    800032e8:	fe840593          	addi	a1,s0,-24
    800032ec:	4501                	li	a0,0
    800032ee:	00000097          	auipc	ra,0x0
    800032f2:	c5c080e7          	jalr	-932(ra) # 80002f4a <argaddr>
  argaddr(1, &size);
    800032f6:	fe040593          	addi	a1,s0,-32
    800032fa:	4505                	li	a0,1
    800032fc:	00000097          	auipc	ra,0x0
    80003300:	c4e080e7          	jalr	-946(ra) # 80002f4a <argaddr>

  const struct proc *p = myproc();
    80003304:	ffffe097          	auipc	ra,0xffffe
    80003308:	6d8080e7          	jalr	1752(ra) # 800019dc <myproc>

  // Record crypto operation request in the shmem queue
  shmem_queue_insert(p->pid, crypto_srv_proc->pid, crypto_op, size);
    8000330c:	00005797          	auipc	a5,0x5
    80003310:	6947b783          	ld	a5,1684(a5) # 800089a0 <crypto_srv_proc>
    80003314:	5b8c                	lw	a1,48(a5)
    80003316:	fe043683          	ld	a3,-32(s0)
    8000331a:	fe843603          	ld	a2,-24(s0)
    8000331e:	2581                	sext.w	a1,a1
    80003320:	5908                	lw	a0,48(a0)
    80003322:	fffff097          	auipc	ra,0xfffff
    80003326:	514080e7          	jalr	1300(ra) # 80002836 <shmem_queue_insert>

  return 0;
    8000332a:	4501                	li	a0,0
}
    8000332c:	60e2                	ld	ra,24(sp)
    8000332e:	6442                	ld	s0,16(sp)
    80003330:	6105                	addi	sp,sp,32
    80003332:	8082                	ret
    return -1;
    80003334:	557d                	li	a0,-1
}
    80003336:	8082                	ret

0000000080003338 <sys_take_shared_memory_request>:

uint64 sys_take_shared_memory_request(void)
{
    80003338:	715d                	addi	sp,sp,-80
    8000333a:	e486                	sd	ra,72(sp)
    8000333c:	e0a2                	sd	s0,64(sp)
    8000333e:	fc26                	sd	s1,56(sp)
    80003340:	f84a                	sd	s2,48(sp)
    80003342:	0880                	addi	s0,sp,80
  struct proc *p = myproc();
    80003344:	ffffe097          	auipc	ra,0xffffe
    80003348:	698080e7          	jalr	1688(ra) # 800019dc <myproc>
  if (crypto_srv_proc == 0 || p != crypto_srv_proc)
    8000334c:	00005797          	auipc	a5,0x5
    80003350:	6547b783          	ld	a5,1620(a5) # 800089a0 <crypto_srv_proc>
    80003354:	c7cd                	beqz	a5,800033fe <sys_take_shared_memory_request+0xc6>
    80003356:	84aa                	mv	s1,a0
  {
    return -1;
    80003358:	557d                	li	a0,-1
  if (crypto_srv_proc == 0 || p != crypto_srv_proc)
    8000335a:	00978863          	beq	a5,s1,8000336a <sys_take_shared_memory_request+0x32>
  copyout(p->pagetable, arg_dst_va, (char *)&dst_va, sizeof(dst_va));
  copyout(p->pagetable, arg_dst_size, (char *)&req.size, sizeof(req.size));

  release(&src_proc->lock);
  return 0;
}
    8000335e:	60a6                	ld	ra,72(sp)
    80003360:	6406                	ld	s0,64(sp)
    80003362:	74e2                	ld	s1,56(sp)
    80003364:	7942                	ld	s2,48(sp)
    80003366:	6161                	addi	sp,sp,80
    80003368:	8082                	ret
  const struct shmem_request req = shmem_queue_remove();
    8000336a:	fc840513          	addi	a0,s0,-56
    8000336e:	fffff097          	auipc	ra,0xfffff
    80003372:	5ae080e7          	jalr	1454(ra) # 8000291c <shmem_queue_remove>
  struct proc *src_proc = find_proc(req.src_pid);
    80003376:	fc842503          	lw	a0,-56(s0)
    8000337a:	fffff097          	auipc	ra,0xfffff
    8000337e:	40c080e7          	jalr	1036(ra) # 80002786 <find_proc>
    80003382:	892a                	mv	s2,a0
  if (src_proc == 0)
    80003384:	cd3d                	beqz	a0,80003402 <sys_take_shared_memory_request+0xca>
  const uint64 dst_va = map_shared_pages(src_proc, p, req.src_va, req.size);
    80003386:	fd843683          	ld	a3,-40(s0)
    8000338a:	fd043603          	ld	a2,-48(s0)
    8000338e:	85a6                	mv	a1,s1
    80003390:	fffff097          	auipc	ra,0xfffff
    80003394:	278080e7          	jalr	632(ra) # 80002608 <map_shared_pages>
    80003398:	fca43023          	sd	a0,-64(s0)
  if (dst_va == 0)
    8000339c:	c931                	beqz	a0,800033f0 <sys_take_shared_memory_request+0xb8>
  argaddr(0, &arg_dst_va);
    8000339e:	fb840593          	addi	a1,s0,-72
    800033a2:	4501                	li	a0,0
    800033a4:	00000097          	auipc	ra,0x0
    800033a8:	ba6080e7          	jalr	-1114(ra) # 80002f4a <argaddr>
  argaddr(1, &arg_dst_size);
    800033ac:	fb040593          	addi	a1,s0,-80
    800033b0:	4505                	li	a0,1
    800033b2:	00000097          	auipc	ra,0x0
    800033b6:	b98080e7          	jalr	-1128(ra) # 80002f4a <argaddr>
  copyout(p->pagetable, arg_dst_va, (char *)&dst_va, sizeof(dst_va));
    800033ba:	46a1                	li	a3,8
    800033bc:	fc040613          	addi	a2,s0,-64
    800033c0:	fb843583          	ld	a1,-72(s0)
    800033c4:	68a8                	ld	a0,80(s1)
    800033c6:	ffffe097          	auipc	ra,0xffffe
    800033ca:	2ba080e7          	jalr	698(ra) # 80001680 <copyout>
  copyout(p->pagetable, arg_dst_size, (char *)&req.size, sizeof(req.size));
    800033ce:	46a1                	li	a3,8
    800033d0:	fd840613          	addi	a2,s0,-40
    800033d4:	fb043583          	ld	a1,-80(s0)
    800033d8:	68a8                	ld	a0,80(s1)
    800033da:	ffffe097          	auipc	ra,0xffffe
    800033de:	2a6080e7          	jalr	678(ra) # 80001680 <copyout>
  release(&src_proc->lock);
    800033e2:	854a                	mv	a0,s2
    800033e4:	ffffe097          	auipc	ra,0xffffe
    800033e8:	8a6080e7          	jalr	-1882(ra) # 80000c8a <release>
  return 0;
    800033ec:	4501                	li	a0,0
    800033ee:	bf85                	j	8000335e <sys_take_shared_memory_request+0x26>
    release(&src_proc->lock);
    800033f0:	854a                	mv	a0,s2
    800033f2:	ffffe097          	auipc	ra,0xffffe
    800033f6:	898080e7          	jalr	-1896(ra) # 80000c8a <release>
    return -1;
    800033fa:	557d                	li	a0,-1
    800033fc:	b78d                	j	8000335e <sys_take_shared_memory_request+0x26>
    return -1;
    800033fe:	557d                	li	a0,-1
    80003400:	bfb9                	j	8000335e <sys_take_shared_memory_request+0x26>
    return -1;
    80003402:	557d                	li	a0,-1
    80003404:	bfa9                	j	8000335e <sys_take_shared_memory_request+0x26>

0000000080003406 <sys_remove_shared_memory_request>:

uint64 sys_remove_shared_memory_request(void)
{
    80003406:	7179                	addi	sp,sp,-48
    80003408:	f406                	sd	ra,40(sp)
    8000340a:	f022                	sd	s0,32(sp)
    8000340c:	ec26                	sd	s1,24(sp)
    8000340e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80003410:	ffffe097          	auipc	ra,0xffffe
    80003414:	5cc080e7          	jalr	1484(ra) # 800019dc <myproc>
  if (crypto_srv_proc == 0 || p != crypto_srv_proc)
    80003418:	00005797          	auipc	a5,0x5
    8000341c:	5887b783          	ld	a5,1416(a5) # 800089a0 <crypto_srv_proc>
    80003420:	c3b1                	beqz	a5,80003464 <sys_remove_shared_memory_request+0x5e>
    80003422:	84aa                	mv	s1,a0
  {
    return -1;
    80003424:	557d                	li	a0,-1
  if (crypto_srv_proc == 0 || p != crypto_srv_proc)
    80003426:	00978763          	beq	a5,s1,80003434 <sys_remove_shared_memory_request+0x2e>

  argaddr(0, &src_va);
  argaddr(1, &size);

  return unmap_shared_pages(p, src_va, size);
}
    8000342a:	70a2                	ld	ra,40(sp)
    8000342c:	7402                	ld	s0,32(sp)
    8000342e:	64e2                	ld	s1,24(sp)
    80003430:	6145                	addi	sp,sp,48
    80003432:	8082                	ret
  argaddr(0, &src_va);
    80003434:	fd840593          	addi	a1,s0,-40
    80003438:	4501                	li	a0,0
    8000343a:	00000097          	auipc	ra,0x0
    8000343e:	b10080e7          	jalr	-1264(ra) # 80002f4a <argaddr>
  argaddr(1, &size);
    80003442:	fd040593          	addi	a1,s0,-48
    80003446:	4505                	li	a0,1
    80003448:	00000097          	auipc	ra,0x0
    8000344c:	b02080e7          	jalr	-1278(ra) # 80002f4a <argaddr>
  return unmap_shared_pages(p, src_va, size);
    80003450:	fd043603          	ld	a2,-48(s0)
    80003454:	fd843583          	ld	a1,-40(s0)
    80003458:	8526                	mv	a0,s1
    8000345a:	fffff097          	auipc	ra,0xfffff
    8000345e:	290080e7          	jalr	656(ra) # 800026ea <unmap_shared_pages>
    80003462:	b7e1                	j	8000342a <sys_remove_shared_memory_request+0x24>
    return -1;
    80003464:	557d                	li	a0,-1
    80003466:	b7d1                	j	8000342a <sys_remove_shared_memory_request+0x24>

0000000080003468 <crypto_srv_init>:

// Set up crypto server process AFTER userspace has been initialized
void crypto_srv_init(void)
{
    80003468:	1101                	addi	sp,sp,-32
    8000346a:	ec06                	sd	ra,24(sp)
    8000346c:	e822                	sd	s0,16(sp)
    8000346e:	e426                	sd	s1,8(sp)
    80003470:	1000                	addi	s0,sp,32
  struct proc *p = allocproc();
    80003472:	ffffe097          	auipc	ra,0xffffe
    80003476:	796080e7          	jalr	1942(ra) # 80001c08 <allocproc>
    8000347a:	84aa                	mv	s1,a0
  crypto_srv_proc = p;
    8000347c:	00005797          	auipc	a5,0x5
    80003480:	52a7b223          	sd	a0,1316(a5) # 800089a0 <crypto_srv_proc>

  // allocate one user page and copy the crypto_srv_init_code
  uvmfirst(p->pagetable, crypto_srv_init_code, sizeof(crypto_srv_init_code));
    80003484:	03c00613          	li	a2,60
    80003488:	00005597          	auipc	a1,0x5
    8000348c:	47058593          	addi	a1,a1,1136 # 800088f8 <crypto_srv_init_code>
    80003490:	6928                	ld	a0,80(a0)
    80003492:	ffffe097          	auipc	ra,0xffffe
    80003496:	edc080e7          	jalr	-292(ra) # 8000136e <uvmfirst>
  p->sz = PGSIZE;
    8000349a:	6785                	lui	a5,0x1
    8000349c:	e4bc                	sd	a5,72(s1)

  // prepare for the very first "return" from kernel to user.
  p->trapframe->epc = 0;     // user program counter
    8000349e:	6cb8                	ld	a4,88(s1)
    800034a0:	00073c23          	sd	zero,24(a4)
  p->trapframe->sp = PGSIZE; // user stack pointer
    800034a4:	6cb8                	ld	a4,88(s1)
    800034a6:	fb1c                	sd	a5,48(a4)

  safestrcpy(p->name, "crypto_srv_init", sizeof(p->name));
    800034a8:	4641                	li	a2,16
    800034aa:	00005597          	auipc	a1,0x5
    800034ae:	0ae58593          	addi	a1,a1,174 # 80008558 <syscalls+0xe8>
    800034b2:	15848513          	addi	a0,s1,344
    800034b6:	ffffe097          	auipc	ra,0xffffe
    800034ba:	966080e7          	jalr	-1690(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    800034be:	00005517          	auipc	a0,0x5
    800034c2:	d6250513          	addi	a0,a0,-670 # 80008220 <digits+0x1e0>
    800034c6:	00001097          	auipc	ra,0x1
    800034ca:	072080e7          	jalr	114(ra) # 80004538 <namei>
    800034ce:	14a4b823          	sd	a0,336(s1)

  p->state = RUNNABLE;
    800034d2:	478d                	li	a5,3
    800034d4:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    800034d6:	8526                	mv	a0,s1
    800034d8:	ffffd097          	auipc	ra,0xffffd
    800034dc:	7b2080e7          	jalr	1970(ra) # 80000c8a <release>
    800034e0:	60e2                	ld	ra,24(sp)
    800034e2:	6442                	ld	s0,16(sp)
    800034e4:	64a2                	ld	s1,8(sp)
    800034e6:	6105                	addi	sp,sp,32
    800034e8:	8082                	ret

00000000800034ea <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800034ea:	7179                	addi	sp,sp,-48
    800034ec:	f406                	sd	ra,40(sp)
    800034ee:	f022                	sd	s0,32(sp)
    800034f0:	ec26                	sd	s1,24(sp)
    800034f2:	e84a                	sd	s2,16(sp)
    800034f4:	e44e                	sd	s3,8(sp)
    800034f6:	e052                	sd	s4,0(sp)
    800034f8:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800034fa:	00005597          	auipc	a1,0x5
    800034fe:	06e58593          	addi	a1,a1,110 # 80008568 <syscalls+0xf8>
    80003502:	00013517          	auipc	a0,0x13
    80003506:	72650513          	addi	a0,a0,1830 # 80016c28 <bcache>
    8000350a:	ffffd097          	auipc	ra,0xffffd
    8000350e:	63c080e7          	jalr	1596(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003512:	0001b797          	auipc	a5,0x1b
    80003516:	71678793          	addi	a5,a5,1814 # 8001ec28 <bcache+0x8000>
    8000351a:	0001c717          	auipc	a4,0x1c
    8000351e:	97670713          	addi	a4,a4,-1674 # 8001ee90 <bcache+0x8268>
    80003522:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003526:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000352a:	00013497          	auipc	s1,0x13
    8000352e:	71648493          	addi	s1,s1,1814 # 80016c40 <bcache+0x18>
    b->next = bcache.head.next;
    80003532:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003534:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003536:	00005a17          	auipc	s4,0x5
    8000353a:	03aa0a13          	addi	s4,s4,58 # 80008570 <syscalls+0x100>
    b->next = bcache.head.next;
    8000353e:	2b893783          	ld	a5,696(s2)
    80003542:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003544:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003548:	85d2                	mv	a1,s4
    8000354a:	01048513          	addi	a0,s1,16
    8000354e:	00001097          	auipc	ra,0x1
    80003552:	4c4080e7          	jalr	1220(ra) # 80004a12 <initsleeplock>
    bcache.head.next->prev = b;
    80003556:	2b893783          	ld	a5,696(s2)
    8000355a:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000355c:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003560:	45848493          	addi	s1,s1,1112
    80003564:	fd349de3          	bne	s1,s3,8000353e <binit+0x54>
  }
}
    80003568:	70a2                	ld	ra,40(sp)
    8000356a:	7402                	ld	s0,32(sp)
    8000356c:	64e2                	ld	s1,24(sp)
    8000356e:	6942                	ld	s2,16(sp)
    80003570:	69a2                	ld	s3,8(sp)
    80003572:	6a02                	ld	s4,0(sp)
    80003574:	6145                	addi	sp,sp,48
    80003576:	8082                	ret

0000000080003578 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003578:	7179                	addi	sp,sp,-48
    8000357a:	f406                	sd	ra,40(sp)
    8000357c:	f022                	sd	s0,32(sp)
    8000357e:	ec26                	sd	s1,24(sp)
    80003580:	e84a                	sd	s2,16(sp)
    80003582:	e44e                	sd	s3,8(sp)
    80003584:	1800                	addi	s0,sp,48
    80003586:	892a                	mv	s2,a0
    80003588:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000358a:	00013517          	auipc	a0,0x13
    8000358e:	69e50513          	addi	a0,a0,1694 # 80016c28 <bcache>
    80003592:	ffffd097          	auipc	ra,0xffffd
    80003596:	644080e7          	jalr	1604(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000359a:	0001c497          	auipc	s1,0x1c
    8000359e:	9464b483          	ld	s1,-1722(s1) # 8001eee0 <bcache+0x82b8>
    800035a2:	0001c797          	auipc	a5,0x1c
    800035a6:	8ee78793          	addi	a5,a5,-1810 # 8001ee90 <bcache+0x8268>
    800035aa:	02f48f63          	beq	s1,a5,800035e8 <bread+0x70>
    800035ae:	873e                	mv	a4,a5
    800035b0:	a021                	j	800035b8 <bread+0x40>
    800035b2:	68a4                	ld	s1,80(s1)
    800035b4:	02e48a63          	beq	s1,a4,800035e8 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800035b8:	449c                	lw	a5,8(s1)
    800035ba:	ff279ce3          	bne	a5,s2,800035b2 <bread+0x3a>
    800035be:	44dc                	lw	a5,12(s1)
    800035c0:	ff3799e3          	bne	a5,s3,800035b2 <bread+0x3a>
      b->refcnt++;
    800035c4:	40bc                	lw	a5,64(s1)
    800035c6:	2785                	addiw	a5,a5,1
    800035c8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800035ca:	00013517          	auipc	a0,0x13
    800035ce:	65e50513          	addi	a0,a0,1630 # 80016c28 <bcache>
    800035d2:	ffffd097          	auipc	ra,0xffffd
    800035d6:	6b8080e7          	jalr	1720(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800035da:	01048513          	addi	a0,s1,16
    800035de:	00001097          	auipc	ra,0x1
    800035e2:	46e080e7          	jalr	1134(ra) # 80004a4c <acquiresleep>
      return b;
    800035e6:	a8b9                	j	80003644 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800035e8:	0001c497          	auipc	s1,0x1c
    800035ec:	8f04b483          	ld	s1,-1808(s1) # 8001eed8 <bcache+0x82b0>
    800035f0:	0001c797          	auipc	a5,0x1c
    800035f4:	8a078793          	addi	a5,a5,-1888 # 8001ee90 <bcache+0x8268>
    800035f8:	00f48863          	beq	s1,a5,80003608 <bread+0x90>
    800035fc:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800035fe:	40bc                	lw	a5,64(s1)
    80003600:	cf81                	beqz	a5,80003618 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003602:	64a4                	ld	s1,72(s1)
    80003604:	fee49de3          	bne	s1,a4,800035fe <bread+0x86>
  panic("bget: no buffers");
    80003608:	00005517          	auipc	a0,0x5
    8000360c:	f7050513          	addi	a0,a0,-144 # 80008578 <syscalls+0x108>
    80003610:	ffffd097          	auipc	ra,0xffffd
    80003614:	f2e080e7          	jalr	-210(ra) # 8000053e <panic>
      b->dev = dev;
    80003618:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000361c:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003620:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003624:	4785                	li	a5,1
    80003626:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003628:	00013517          	auipc	a0,0x13
    8000362c:	60050513          	addi	a0,a0,1536 # 80016c28 <bcache>
    80003630:	ffffd097          	auipc	ra,0xffffd
    80003634:	65a080e7          	jalr	1626(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003638:	01048513          	addi	a0,s1,16
    8000363c:	00001097          	auipc	ra,0x1
    80003640:	410080e7          	jalr	1040(ra) # 80004a4c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003644:	409c                	lw	a5,0(s1)
    80003646:	cb89                	beqz	a5,80003658 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003648:	8526                	mv	a0,s1
    8000364a:	70a2                	ld	ra,40(sp)
    8000364c:	7402                	ld	s0,32(sp)
    8000364e:	64e2                	ld	s1,24(sp)
    80003650:	6942                	ld	s2,16(sp)
    80003652:	69a2                	ld	s3,8(sp)
    80003654:	6145                	addi	sp,sp,48
    80003656:	8082                	ret
    virtio_disk_rw(b, 0);
    80003658:	4581                	li	a1,0
    8000365a:	8526                	mv	a0,s1
    8000365c:	00003097          	auipc	ra,0x3
    80003660:	fd8080e7          	jalr	-40(ra) # 80006634 <virtio_disk_rw>
    b->valid = 1;
    80003664:	4785                	li	a5,1
    80003666:	c09c                	sw	a5,0(s1)
  return b;
    80003668:	b7c5                	j	80003648 <bread+0xd0>

000000008000366a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000366a:	1101                	addi	sp,sp,-32
    8000366c:	ec06                	sd	ra,24(sp)
    8000366e:	e822                	sd	s0,16(sp)
    80003670:	e426                	sd	s1,8(sp)
    80003672:	1000                	addi	s0,sp,32
    80003674:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003676:	0541                	addi	a0,a0,16
    80003678:	00001097          	auipc	ra,0x1
    8000367c:	46e080e7          	jalr	1134(ra) # 80004ae6 <holdingsleep>
    80003680:	cd01                	beqz	a0,80003698 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003682:	4585                	li	a1,1
    80003684:	8526                	mv	a0,s1
    80003686:	00003097          	auipc	ra,0x3
    8000368a:	fae080e7          	jalr	-82(ra) # 80006634 <virtio_disk_rw>
}
    8000368e:	60e2                	ld	ra,24(sp)
    80003690:	6442                	ld	s0,16(sp)
    80003692:	64a2                	ld	s1,8(sp)
    80003694:	6105                	addi	sp,sp,32
    80003696:	8082                	ret
    panic("bwrite");
    80003698:	00005517          	auipc	a0,0x5
    8000369c:	ef850513          	addi	a0,a0,-264 # 80008590 <syscalls+0x120>
    800036a0:	ffffd097          	auipc	ra,0xffffd
    800036a4:	e9e080e7          	jalr	-354(ra) # 8000053e <panic>

00000000800036a8 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800036a8:	1101                	addi	sp,sp,-32
    800036aa:	ec06                	sd	ra,24(sp)
    800036ac:	e822                	sd	s0,16(sp)
    800036ae:	e426                	sd	s1,8(sp)
    800036b0:	e04a                	sd	s2,0(sp)
    800036b2:	1000                	addi	s0,sp,32
    800036b4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800036b6:	01050913          	addi	s2,a0,16
    800036ba:	854a                	mv	a0,s2
    800036bc:	00001097          	auipc	ra,0x1
    800036c0:	42a080e7          	jalr	1066(ra) # 80004ae6 <holdingsleep>
    800036c4:	c92d                	beqz	a0,80003736 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800036c6:	854a                	mv	a0,s2
    800036c8:	00001097          	auipc	ra,0x1
    800036cc:	3da080e7          	jalr	986(ra) # 80004aa2 <releasesleep>

  acquire(&bcache.lock);
    800036d0:	00013517          	auipc	a0,0x13
    800036d4:	55850513          	addi	a0,a0,1368 # 80016c28 <bcache>
    800036d8:	ffffd097          	auipc	ra,0xffffd
    800036dc:	4fe080e7          	jalr	1278(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800036e0:	40bc                	lw	a5,64(s1)
    800036e2:	37fd                	addiw	a5,a5,-1
    800036e4:	0007871b          	sext.w	a4,a5
    800036e8:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800036ea:	eb05                	bnez	a4,8000371a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800036ec:	68bc                	ld	a5,80(s1)
    800036ee:	64b8                	ld	a4,72(s1)
    800036f0:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800036f2:	64bc                	ld	a5,72(s1)
    800036f4:	68b8                	ld	a4,80(s1)
    800036f6:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800036f8:	0001b797          	auipc	a5,0x1b
    800036fc:	53078793          	addi	a5,a5,1328 # 8001ec28 <bcache+0x8000>
    80003700:	2b87b703          	ld	a4,696(a5)
    80003704:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003706:	0001b717          	auipc	a4,0x1b
    8000370a:	78a70713          	addi	a4,a4,1930 # 8001ee90 <bcache+0x8268>
    8000370e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003710:	2b87b703          	ld	a4,696(a5)
    80003714:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003716:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000371a:	00013517          	auipc	a0,0x13
    8000371e:	50e50513          	addi	a0,a0,1294 # 80016c28 <bcache>
    80003722:	ffffd097          	auipc	ra,0xffffd
    80003726:	568080e7          	jalr	1384(ra) # 80000c8a <release>
}
    8000372a:	60e2                	ld	ra,24(sp)
    8000372c:	6442                	ld	s0,16(sp)
    8000372e:	64a2                	ld	s1,8(sp)
    80003730:	6902                	ld	s2,0(sp)
    80003732:	6105                	addi	sp,sp,32
    80003734:	8082                	ret
    panic("brelse");
    80003736:	00005517          	auipc	a0,0x5
    8000373a:	e6250513          	addi	a0,a0,-414 # 80008598 <syscalls+0x128>
    8000373e:	ffffd097          	auipc	ra,0xffffd
    80003742:	e00080e7          	jalr	-512(ra) # 8000053e <panic>

0000000080003746 <bpin>:

void
bpin(struct buf *b) {
    80003746:	1101                	addi	sp,sp,-32
    80003748:	ec06                	sd	ra,24(sp)
    8000374a:	e822                	sd	s0,16(sp)
    8000374c:	e426                	sd	s1,8(sp)
    8000374e:	1000                	addi	s0,sp,32
    80003750:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003752:	00013517          	auipc	a0,0x13
    80003756:	4d650513          	addi	a0,a0,1238 # 80016c28 <bcache>
    8000375a:	ffffd097          	auipc	ra,0xffffd
    8000375e:	47c080e7          	jalr	1148(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80003762:	40bc                	lw	a5,64(s1)
    80003764:	2785                	addiw	a5,a5,1
    80003766:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003768:	00013517          	auipc	a0,0x13
    8000376c:	4c050513          	addi	a0,a0,1216 # 80016c28 <bcache>
    80003770:	ffffd097          	auipc	ra,0xffffd
    80003774:	51a080e7          	jalr	1306(ra) # 80000c8a <release>
}
    80003778:	60e2                	ld	ra,24(sp)
    8000377a:	6442                	ld	s0,16(sp)
    8000377c:	64a2                	ld	s1,8(sp)
    8000377e:	6105                	addi	sp,sp,32
    80003780:	8082                	ret

0000000080003782 <bunpin>:

void
bunpin(struct buf *b) {
    80003782:	1101                	addi	sp,sp,-32
    80003784:	ec06                	sd	ra,24(sp)
    80003786:	e822                	sd	s0,16(sp)
    80003788:	e426                	sd	s1,8(sp)
    8000378a:	1000                	addi	s0,sp,32
    8000378c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000378e:	00013517          	auipc	a0,0x13
    80003792:	49a50513          	addi	a0,a0,1178 # 80016c28 <bcache>
    80003796:	ffffd097          	auipc	ra,0xffffd
    8000379a:	440080e7          	jalr	1088(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000379e:	40bc                	lw	a5,64(s1)
    800037a0:	37fd                	addiw	a5,a5,-1
    800037a2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800037a4:	00013517          	auipc	a0,0x13
    800037a8:	48450513          	addi	a0,a0,1156 # 80016c28 <bcache>
    800037ac:	ffffd097          	auipc	ra,0xffffd
    800037b0:	4de080e7          	jalr	1246(ra) # 80000c8a <release>
}
    800037b4:	60e2                	ld	ra,24(sp)
    800037b6:	6442                	ld	s0,16(sp)
    800037b8:	64a2                	ld	s1,8(sp)
    800037ba:	6105                	addi	sp,sp,32
    800037bc:	8082                	ret

00000000800037be <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800037be:	1101                	addi	sp,sp,-32
    800037c0:	ec06                	sd	ra,24(sp)
    800037c2:	e822                	sd	s0,16(sp)
    800037c4:	e426                	sd	s1,8(sp)
    800037c6:	e04a                	sd	s2,0(sp)
    800037c8:	1000                	addi	s0,sp,32
    800037ca:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800037cc:	00d5d59b          	srliw	a1,a1,0xd
    800037d0:	0001c797          	auipc	a5,0x1c
    800037d4:	b347a783          	lw	a5,-1228(a5) # 8001f304 <sb+0x1c>
    800037d8:	9dbd                	addw	a1,a1,a5
    800037da:	00000097          	auipc	ra,0x0
    800037de:	d9e080e7          	jalr	-610(ra) # 80003578 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800037e2:	0074f713          	andi	a4,s1,7
    800037e6:	4785                	li	a5,1
    800037e8:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800037ec:	14ce                	slli	s1,s1,0x33
    800037ee:	90d9                	srli	s1,s1,0x36
    800037f0:	00950733          	add	a4,a0,s1
    800037f4:	05874703          	lbu	a4,88(a4)
    800037f8:	00e7f6b3          	and	a3,a5,a4
    800037fc:	c69d                	beqz	a3,8000382a <bfree+0x6c>
    800037fe:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003800:	94aa                	add	s1,s1,a0
    80003802:	fff7c793          	not	a5,a5
    80003806:	8ff9                	and	a5,a5,a4
    80003808:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000380c:	00001097          	auipc	ra,0x1
    80003810:	120080e7          	jalr	288(ra) # 8000492c <log_write>
  brelse(bp);
    80003814:	854a                	mv	a0,s2
    80003816:	00000097          	auipc	ra,0x0
    8000381a:	e92080e7          	jalr	-366(ra) # 800036a8 <brelse>
}
    8000381e:	60e2                	ld	ra,24(sp)
    80003820:	6442                	ld	s0,16(sp)
    80003822:	64a2                	ld	s1,8(sp)
    80003824:	6902                	ld	s2,0(sp)
    80003826:	6105                	addi	sp,sp,32
    80003828:	8082                	ret
    panic("freeing free block");
    8000382a:	00005517          	auipc	a0,0x5
    8000382e:	d7650513          	addi	a0,a0,-650 # 800085a0 <syscalls+0x130>
    80003832:	ffffd097          	auipc	ra,0xffffd
    80003836:	d0c080e7          	jalr	-756(ra) # 8000053e <panic>

000000008000383a <balloc>:
{
    8000383a:	711d                	addi	sp,sp,-96
    8000383c:	ec86                	sd	ra,88(sp)
    8000383e:	e8a2                	sd	s0,80(sp)
    80003840:	e4a6                	sd	s1,72(sp)
    80003842:	e0ca                	sd	s2,64(sp)
    80003844:	fc4e                	sd	s3,56(sp)
    80003846:	f852                	sd	s4,48(sp)
    80003848:	f456                	sd	s5,40(sp)
    8000384a:	f05a                	sd	s6,32(sp)
    8000384c:	ec5e                	sd	s7,24(sp)
    8000384e:	e862                	sd	s8,16(sp)
    80003850:	e466                	sd	s9,8(sp)
    80003852:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003854:	0001c797          	auipc	a5,0x1c
    80003858:	a987a783          	lw	a5,-1384(a5) # 8001f2ec <sb+0x4>
    8000385c:	10078163          	beqz	a5,8000395e <balloc+0x124>
    80003860:	8baa                	mv	s7,a0
    80003862:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003864:	0001cb17          	auipc	s6,0x1c
    80003868:	a84b0b13          	addi	s6,s6,-1404 # 8001f2e8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000386c:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000386e:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003870:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003872:	6c89                	lui	s9,0x2
    80003874:	a061                	j	800038fc <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003876:	974a                	add	a4,a4,s2
    80003878:	8fd5                	or	a5,a5,a3
    8000387a:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000387e:	854a                	mv	a0,s2
    80003880:	00001097          	auipc	ra,0x1
    80003884:	0ac080e7          	jalr	172(ra) # 8000492c <log_write>
        brelse(bp);
    80003888:	854a                	mv	a0,s2
    8000388a:	00000097          	auipc	ra,0x0
    8000388e:	e1e080e7          	jalr	-482(ra) # 800036a8 <brelse>
  bp = bread(dev, bno);
    80003892:	85a6                	mv	a1,s1
    80003894:	855e                	mv	a0,s7
    80003896:	00000097          	auipc	ra,0x0
    8000389a:	ce2080e7          	jalr	-798(ra) # 80003578 <bread>
    8000389e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800038a0:	40000613          	li	a2,1024
    800038a4:	4581                	li	a1,0
    800038a6:	05850513          	addi	a0,a0,88
    800038aa:	ffffd097          	auipc	ra,0xffffd
    800038ae:	428080e7          	jalr	1064(ra) # 80000cd2 <memset>
  log_write(bp);
    800038b2:	854a                	mv	a0,s2
    800038b4:	00001097          	auipc	ra,0x1
    800038b8:	078080e7          	jalr	120(ra) # 8000492c <log_write>
  brelse(bp);
    800038bc:	854a                	mv	a0,s2
    800038be:	00000097          	auipc	ra,0x0
    800038c2:	dea080e7          	jalr	-534(ra) # 800036a8 <brelse>
}
    800038c6:	8526                	mv	a0,s1
    800038c8:	60e6                	ld	ra,88(sp)
    800038ca:	6446                	ld	s0,80(sp)
    800038cc:	64a6                	ld	s1,72(sp)
    800038ce:	6906                	ld	s2,64(sp)
    800038d0:	79e2                	ld	s3,56(sp)
    800038d2:	7a42                	ld	s4,48(sp)
    800038d4:	7aa2                	ld	s5,40(sp)
    800038d6:	7b02                	ld	s6,32(sp)
    800038d8:	6be2                	ld	s7,24(sp)
    800038da:	6c42                	ld	s8,16(sp)
    800038dc:	6ca2                	ld	s9,8(sp)
    800038de:	6125                	addi	sp,sp,96
    800038e0:	8082                	ret
    brelse(bp);
    800038e2:	854a                	mv	a0,s2
    800038e4:	00000097          	auipc	ra,0x0
    800038e8:	dc4080e7          	jalr	-572(ra) # 800036a8 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800038ec:	015c87bb          	addw	a5,s9,s5
    800038f0:	00078a9b          	sext.w	s5,a5
    800038f4:	004b2703          	lw	a4,4(s6)
    800038f8:	06eaf363          	bgeu	s5,a4,8000395e <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    800038fc:	41fad79b          	sraiw	a5,s5,0x1f
    80003900:	0137d79b          	srliw	a5,a5,0x13
    80003904:	015787bb          	addw	a5,a5,s5
    80003908:	40d7d79b          	sraiw	a5,a5,0xd
    8000390c:	01cb2583          	lw	a1,28(s6)
    80003910:	9dbd                	addw	a1,a1,a5
    80003912:	855e                	mv	a0,s7
    80003914:	00000097          	auipc	ra,0x0
    80003918:	c64080e7          	jalr	-924(ra) # 80003578 <bread>
    8000391c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000391e:	004b2503          	lw	a0,4(s6)
    80003922:	000a849b          	sext.w	s1,s5
    80003926:	8662                	mv	a2,s8
    80003928:	faa4fde3          	bgeu	s1,a0,800038e2 <balloc+0xa8>
      m = 1 << (bi % 8);
    8000392c:	41f6579b          	sraiw	a5,a2,0x1f
    80003930:	01d7d69b          	srliw	a3,a5,0x1d
    80003934:	00c6873b          	addw	a4,a3,a2
    80003938:	00777793          	andi	a5,a4,7
    8000393c:	9f95                	subw	a5,a5,a3
    8000393e:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003942:	4037571b          	sraiw	a4,a4,0x3
    80003946:	00e906b3          	add	a3,s2,a4
    8000394a:	0586c683          	lbu	a3,88(a3)
    8000394e:	00d7f5b3          	and	a1,a5,a3
    80003952:	d195                	beqz	a1,80003876 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003954:	2605                	addiw	a2,a2,1
    80003956:	2485                	addiw	s1,s1,1
    80003958:	fd4618e3          	bne	a2,s4,80003928 <balloc+0xee>
    8000395c:	b759                	j	800038e2 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    8000395e:	00005517          	auipc	a0,0x5
    80003962:	c5a50513          	addi	a0,a0,-934 # 800085b8 <syscalls+0x148>
    80003966:	ffffd097          	auipc	ra,0xffffd
    8000396a:	c22080e7          	jalr	-990(ra) # 80000588 <printf>
  return 0;
    8000396e:	4481                	li	s1,0
    80003970:	bf99                	j	800038c6 <balloc+0x8c>

0000000080003972 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003972:	7179                	addi	sp,sp,-48
    80003974:	f406                	sd	ra,40(sp)
    80003976:	f022                	sd	s0,32(sp)
    80003978:	ec26                	sd	s1,24(sp)
    8000397a:	e84a                	sd	s2,16(sp)
    8000397c:	e44e                	sd	s3,8(sp)
    8000397e:	e052                	sd	s4,0(sp)
    80003980:	1800                	addi	s0,sp,48
    80003982:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003984:	47ad                	li	a5,11
    80003986:	02b7e763          	bltu	a5,a1,800039b4 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    8000398a:	02059493          	slli	s1,a1,0x20
    8000398e:	9081                	srli	s1,s1,0x20
    80003990:	048a                	slli	s1,s1,0x2
    80003992:	94aa                	add	s1,s1,a0
    80003994:	0504a903          	lw	s2,80(s1)
    80003998:	06091e63          	bnez	s2,80003a14 <bmap+0xa2>
      addr = balloc(ip->dev);
    8000399c:	4108                	lw	a0,0(a0)
    8000399e:	00000097          	auipc	ra,0x0
    800039a2:	e9c080e7          	jalr	-356(ra) # 8000383a <balloc>
    800039a6:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800039aa:	06090563          	beqz	s2,80003a14 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    800039ae:	0524a823          	sw	s2,80(s1)
    800039b2:	a08d                	j	80003a14 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    800039b4:	ff45849b          	addiw	s1,a1,-12
    800039b8:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800039bc:	0ff00793          	li	a5,255
    800039c0:	08e7e563          	bltu	a5,a4,80003a4a <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800039c4:	08052903          	lw	s2,128(a0)
    800039c8:	00091d63          	bnez	s2,800039e2 <bmap+0x70>
      addr = balloc(ip->dev);
    800039cc:	4108                	lw	a0,0(a0)
    800039ce:	00000097          	auipc	ra,0x0
    800039d2:	e6c080e7          	jalr	-404(ra) # 8000383a <balloc>
    800039d6:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800039da:	02090d63          	beqz	s2,80003a14 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800039de:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800039e2:	85ca                	mv	a1,s2
    800039e4:	0009a503          	lw	a0,0(s3)
    800039e8:	00000097          	auipc	ra,0x0
    800039ec:	b90080e7          	jalr	-1136(ra) # 80003578 <bread>
    800039f0:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800039f2:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800039f6:	02049593          	slli	a1,s1,0x20
    800039fa:	9181                	srli	a1,a1,0x20
    800039fc:	058a                	slli	a1,a1,0x2
    800039fe:	00b784b3          	add	s1,a5,a1
    80003a02:	0004a903          	lw	s2,0(s1)
    80003a06:	02090063          	beqz	s2,80003a26 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003a0a:	8552                	mv	a0,s4
    80003a0c:	00000097          	auipc	ra,0x0
    80003a10:	c9c080e7          	jalr	-868(ra) # 800036a8 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003a14:	854a                	mv	a0,s2
    80003a16:	70a2                	ld	ra,40(sp)
    80003a18:	7402                	ld	s0,32(sp)
    80003a1a:	64e2                	ld	s1,24(sp)
    80003a1c:	6942                	ld	s2,16(sp)
    80003a1e:	69a2                	ld	s3,8(sp)
    80003a20:	6a02                	ld	s4,0(sp)
    80003a22:	6145                	addi	sp,sp,48
    80003a24:	8082                	ret
      addr = balloc(ip->dev);
    80003a26:	0009a503          	lw	a0,0(s3)
    80003a2a:	00000097          	auipc	ra,0x0
    80003a2e:	e10080e7          	jalr	-496(ra) # 8000383a <balloc>
    80003a32:	0005091b          	sext.w	s2,a0
      if(addr){
    80003a36:	fc090ae3          	beqz	s2,80003a0a <bmap+0x98>
        a[bn] = addr;
    80003a3a:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003a3e:	8552                	mv	a0,s4
    80003a40:	00001097          	auipc	ra,0x1
    80003a44:	eec080e7          	jalr	-276(ra) # 8000492c <log_write>
    80003a48:	b7c9                	j	80003a0a <bmap+0x98>
  panic("bmap: out of range");
    80003a4a:	00005517          	auipc	a0,0x5
    80003a4e:	b8650513          	addi	a0,a0,-1146 # 800085d0 <syscalls+0x160>
    80003a52:	ffffd097          	auipc	ra,0xffffd
    80003a56:	aec080e7          	jalr	-1300(ra) # 8000053e <panic>

0000000080003a5a <iget>:
{
    80003a5a:	7179                	addi	sp,sp,-48
    80003a5c:	f406                	sd	ra,40(sp)
    80003a5e:	f022                	sd	s0,32(sp)
    80003a60:	ec26                	sd	s1,24(sp)
    80003a62:	e84a                	sd	s2,16(sp)
    80003a64:	e44e                	sd	s3,8(sp)
    80003a66:	e052                	sd	s4,0(sp)
    80003a68:	1800                	addi	s0,sp,48
    80003a6a:	89aa                	mv	s3,a0
    80003a6c:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003a6e:	0001c517          	auipc	a0,0x1c
    80003a72:	89a50513          	addi	a0,a0,-1894 # 8001f308 <itable>
    80003a76:	ffffd097          	auipc	ra,0xffffd
    80003a7a:	160080e7          	jalr	352(ra) # 80000bd6 <acquire>
  empty = 0;
    80003a7e:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a80:	0001c497          	auipc	s1,0x1c
    80003a84:	8a048493          	addi	s1,s1,-1888 # 8001f320 <itable+0x18>
    80003a88:	0001d697          	auipc	a3,0x1d
    80003a8c:	32868693          	addi	a3,a3,808 # 80020db0 <log>
    80003a90:	a039                	j	80003a9e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a92:	02090b63          	beqz	s2,80003ac8 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a96:	08848493          	addi	s1,s1,136
    80003a9a:	02d48a63          	beq	s1,a3,80003ace <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003a9e:	449c                	lw	a5,8(s1)
    80003aa0:	fef059e3          	blez	a5,80003a92 <iget+0x38>
    80003aa4:	4098                	lw	a4,0(s1)
    80003aa6:	ff3716e3          	bne	a4,s3,80003a92 <iget+0x38>
    80003aaa:	40d8                	lw	a4,4(s1)
    80003aac:	ff4713e3          	bne	a4,s4,80003a92 <iget+0x38>
      ip->ref++;
    80003ab0:	2785                	addiw	a5,a5,1
    80003ab2:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003ab4:	0001c517          	auipc	a0,0x1c
    80003ab8:	85450513          	addi	a0,a0,-1964 # 8001f308 <itable>
    80003abc:	ffffd097          	auipc	ra,0xffffd
    80003ac0:	1ce080e7          	jalr	462(ra) # 80000c8a <release>
      return ip;
    80003ac4:	8926                	mv	s2,s1
    80003ac6:	a03d                	j	80003af4 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003ac8:	f7f9                	bnez	a5,80003a96 <iget+0x3c>
    80003aca:	8926                	mv	s2,s1
    80003acc:	b7e9                	j	80003a96 <iget+0x3c>
  if(empty == 0)
    80003ace:	02090c63          	beqz	s2,80003b06 <iget+0xac>
  ip->dev = dev;
    80003ad2:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003ad6:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003ada:	4785                	li	a5,1
    80003adc:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003ae0:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003ae4:	0001c517          	auipc	a0,0x1c
    80003ae8:	82450513          	addi	a0,a0,-2012 # 8001f308 <itable>
    80003aec:	ffffd097          	auipc	ra,0xffffd
    80003af0:	19e080e7          	jalr	414(ra) # 80000c8a <release>
}
    80003af4:	854a                	mv	a0,s2
    80003af6:	70a2                	ld	ra,40(sp)
    80003af8:	7402                	ld	s0,32(sp)
    80003afa:	64e2                	ld	s1,24(sp)
    80003afc:	6942                	ld	s2,16(sp)
    80003afe:	69a2                	ld	s3,8(sp)
    80003b00:	6a02                	ld	s4,0(sp)
    80003b02:	6145                	addi	sp,sp,48
    80003b04:	8082                	ret
    panic("iget: no inodes");
    80003b06:	00005517          	auipc	a0,0x5
    80003b0a:	ae250513          	addi	a0,a0,-1310 # 800085e8 <syscalls+0x178>
    80003b0e:	ffffd097          	auipc	ra,0xffffd
    80003b12:	a30080e7          	jalr	-1488(ra) # 8000053e <panic>

0000000080003b16 <fsinit>:
fsinit(int dev) {
    80003b16:	7179                	addi	sp,sp,-48
    80003b18:	f406                	sd	ra,40(sp)
    80003b1a:	f022                	sd	s0,32(sp)
    80003b1c:	ec26                	sd	s1,24(sp)
    80003b1e:	e84a                	sd	s2,16(sp)
    80003b20:	e44e                	sd	s3,8(sp)
    80003b22:	1800                	addi	s0,sp,48
    80003b24:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003b26:	4585                	li	a1,1
    80003b28:	00000097          	auipc	ra,0x0
    80003b2c:	a50080e7          	jalr	-1456(ra) # 80003578 <bread>
    80003b30:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003b32:	0001b997          	auipc	s3,0x1b
    80003b36:	7b698993          	addi	s3,s3,1974 # 8001f2e8 <sb>
    80003b3a:	02000613          	li	a2,32
    80003b3e:	05850593          	addi	a1,a0,88
    80003b42:	854e                	mv	a0,s3
    80003b44:	ffffd097          	auipc	ra,0xffffd
    80003b48:	1ea080e7          	jalr	490(ra) # 80000d2e <memmove>
  brelse(bp);
    80003b4c:	8526                	mv	a0,s1
    80003b4e:	00000097          	auipc	ra,0x0
    80003b52:	b5a080e7          	jalr	-1190(ra) # 800036a8 <brelse>
  if(sb.magic != FSMAGIC)
    80003b56:	0009a703          	lw	a4,0(s3)
    80003b5a:	102037b7          	lui	a5,0x10203
    80003b5e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003b62:	02f71263          	bne	a4,a5,80003b86 <fsinit+0x70>
  initlog(dev, &sb);
    80003b66:	0001b597          	auipc	a1,0x1b
    80003b6a:	78258593          	addi	a1,a1,1922 # 8001f2e8 <sb>
    80003b6e:	854a                	mv	a0,s2
    80003b70:	00001097          	auipc	ra,0x1
    80003b74:	b40080e7          	jalr	-1216(ra) # 800046b0 <initlog>
}
    80003b78:	70a2                	ld	ra,40(sp)
    80003b7a:	7402                	ld	s0,32(sp)
    80003b7c:	64e2                	ld	s1,24(sp)
    80003b7e:	6942                	ld	s2,16(sp)
    80003b80:	69a2                	ld	s3,8(sp)
    80003b82:	6145                	addi	sp,sp,48
    80003b84:	8082                	ret
    panic("invalid file system");
    80003b86:	00005517          	auipc	a0,0x5
    80003b8a:	a7250513          	addi	a0,a0,-1422 # 800085f8 <syscalls+0x188>
    80003b8e:	ffffd097          	auipc	ra,0xffffd
    80003b92:	9b0080e7          	jalr	-1616(ra) # 8000053e <panic>

0000000080003b96 <iinit>:
{
    80003b96:	7179                	addi	sp,sp,-48
    80003b98:	f406                	sd	ra,40(sp)
    80003b9a:	f022                	sd	s0,32(sp)
    80003b9c:	ec26                	sd	s1,24(sp)
    80003b9e:	e84a                	sd	s2,16(sp)
    80003ba0:	e44e                	sd	s3,8(sp)
    80003ba2:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003ba4:	00005597          	auipc	a1,0x5
    80003ba8:	a6c58593          	addi	a1,a1,-1428 # 80008610 <syscalls+0x1a0>
    80003bac:	0001b517          	auipc	a0,0x1b
    80003bb0:	75c50513          	addi	a0,a0,1884 # 8001f308 <itable>
    80003bb4:	ffffd097          	auipc	ra,0xffffd
    80003bb8:	f92080e7          	jalr	-110(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003bbc:	0001b497          	auipc	s1,0x1b
    80003bc0:	77448493          	addi	s1,s1,1908 # 8001f330 <itable+0x28>
    80003bc4:	0001d997          	auipc	s3,0x1d
    80003bc8:	1fc98993          	addi	s3,s3,508 # 80020dc0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003bcc:	00005917          	auipc	s2,0x5
    80003bd0:	a4c90913          	addi	s2,s2,-1460 # 80008618 <syscalls+0x1a8>
    80003bd4:	85ca                	mv	a1,s2
    80003bd6:	8526                	mv	a0,s1
    80003bd8:	00001097          	auipc	ra,0x1
    80003bdc:	e3a080e7          	jalr	-454(ra) # 80004a12 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003be0:	08848493          	addi	s1,s1,136
    80003be4:	ff3498e3          	bne	s1,s3,80003bd4 <iinit+0x3e>
}
    80003be8:	70a2                	ld	ra,40(sp)
    80003bea:	7402                	ld	s0,32(sp)
    80003bec:	64e2                	ld	s1,24(sp)
    80003bee:	6942                	ld	s2,16(sp)
    80003bf0:	69a2                	ld	s3,8(sp)
    80003bf2:	6145                	addi	sp,sp,48
    80003bf4:	8082                	ret

0000000080003bf6 <ialloc>:
{
    80003bf6:	715d                	addi	sp,sp,-80
    80003bf8:	e486                	sd	ra,72(sp)
    80003bfa:	e0a2                	sd	s0,64(sp)
    80003bfc:	fc26                	sd	s1,56(sp)
    80003bfe:	f84a                	sd	s2,48(sp)
    80003c00:	f44e                	sd	s3,40(sp)
    80003c02:	f052                	sd	s4,32(sp)
    80003c04:	ec56                	sd	s5,24(sp)
    80003c06:	e85a                	sd	s6,16(sp)
    80003c08:	e45e                	sd	s7,8(sp)
    80003c0a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c0c:	0001b717          	auipc	a4,0x1b
    80003c10:	6e872703          	lw	a4,1768(a4) # 8001f2f4 <sb+0xc>
    80003c14:	4785                	li	a5,1
    80003c16:	04e7fa63          	bgeu	a5,a4,80003c6a <ialloc+0x74>
    80003c1a:	8aaa                	mv	s5,a0
    80003c1c:	8bae                	mv	s7,a1
    80003c1e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003c20:	0001ba17          	auipc	s4,0x1b
    80003c24:	6c8a0a13          	addi	s4,s4,1736 # 8001f2e8 <sb>
    80003c28:	00048b1b          	sext.w	s6,s1
    80003c2c:	0044d793          	srli	a5,s1,0x4
    80003c30:	018a2583          	lw	a1,24(s4)
    80003c34:	9dbd                	addw	a1,a1,a5
    80003c36:	8556                	mv	a0,s5
    80003c38:	00000097          	auipc	ra,0x0
    80003c3c:	940080e7          	jalr	-1728(ra) # 80003578 <bread>
    80003c40:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003c42:	05850993          	addi	s3,a0,88
    80003c46:	00f4f793          	andi	a5,s1,15
    80003c4a:	079a                	slli	a5,a5,0x6
    80003c4c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003c4e:	00099783          	lh	a5,0(s3)
    80003c52:	c3a1                	beqz	a5,80003c92 <ialloc+0x9c>
    brelse(bp);
    80003c54:	00000097          	auipc	ra,0x0
    80003c58:	a54080e7          	jalr	-1452(ra) # 800036a8 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c5c:	0485                	addi	s1,s1,1
    80003c5e:	00ca2703          	lw	a4,12(s4)
    80003c62:	0004879b          	sext.w	a5,s1
    80003c66:	fce7e1e3          	bltu	a5,a4,80003c28 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003c6a:	00005517          	auipc	a0,0x5
    80003c6e:	9b650513          	addi	a0,a0,-1610 # 80008620 <syscalls+0x1b0>
    80003c72:	ffffd097          	auipc	ra,0xffffd
    80003c76:	916080e7          	jalr	-1770(ra) # 80000588 <printf>
  return 0;
    80003c7a:	4501                	li	a0,0
}
    80003c7c:	60a6                	ld	ra,72(sp)
    80003c7e:	6406                	ld	s0,64(sp)
    80003c80:	74e2                	ld	s1,56(sp)
    80003c82:	7942                	ld	s2,48(sp)
    80003c84:	79a2                	ld	s3,40(sp)
    80003c86:	7a02                	ld	s4,32(sp)
    80003c88:	6ae2                	ld	s5,24(sp)
    80003c8a:	6b42                	ld	s6,16(sp)
    80003c8c:	6ba2                	ld	s7,8(sp)
    80003c8e:	6161                	addi	sp,sp,80
    80003c90:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003c92:	04000613          	li	a2,64
    80003c96:	4581                	li	a1,0
    80003c98:	854e                	mv	a0,s3
    80003c9a:	ffffd097          	auipc	ra,0xffffd
    80003c9e:	038080e7          	jalr	56(ra) # 80000cd2 <memset>
      dip->type = type;
    80003ca2:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003ca6:	854a                	mv	a0,s2
    80003ca8:	00001097          	auipc	ra,0x1
    80003cac:	c84080e7          	jalr	-892(ra) # 8000492c <log_write>
      brelse(bp);
    80003cb0:	854a                	mv	a0,s2
    80003cb2:	00000097          	auipc	ra,0x0
    80003cb6:	9f6080e7          	jalr	-1546(ra) # 800036a8 <brelse>
      return iget(dev, inum);
    80003cba:	85da                	mv	a1,s6
    80003cbc:	8556                	mv	a0,s5
    80003cbe:	00000097          	auipc	ra,0x0
    80003cc2:	d9c080e7          	jalr	-612(ra) # 80003a5a <iget>
    80003cc6:	bf5d                	j	80003c7c <ialloc+0x86>

0000000080003cc8 <iupdate>:
{
    80003cc8:	1101                	addi	sp,sp,-32
    80003cca:	ec06                	sd	ra,24(sp)
    80003ccc:	e822                	sd	s0,16(sp)
    80003cce:	e426                	sd	s1,8(sp)
    80003cd0:	e04a                	sd	s2,0(sp)
    80003cd2:	1000                	addi	s0,sp,32
    80003cd4:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003cd6:	415c                	lw	a5,4(a0)
    80003cd8:	0047d79b          	srliw	a5,a5,0x4
    80003cdc:	0001b597          	auipc	a1,0x1b
    80003ce0:	6245a583          	lw	a1,1572(a1) # 8001f300 <sb+0x18>
    80003ce4:	9dbd                	addw	a1,a1,a5
    80003ce6:	4108                	lw	a0,0(a0)
    80003ce8:	00000097          	auipc	ra,0x0
    80003cec:	890080e7          	jalr	-1904(ra) # 80003578 <bread>
    80003cf0:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003cf2:	05850793          	addi	a5,a0,88
    80003cf6:	40c8                	lw	a0,4(s1)
    80003cf8:	893d                	andi	a0,a0,15
    80003cfa:	051a                	slli	a0,a0,0x6
    80003cfc:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003cfe:	04449703          	lh	a4,68(s1)
    80003d02:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003d06:	04649703          	lh	a4,70(s1)
    80003d0a:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003d0e:	04849703          	lh	a4,72(s1)
    80003d12:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003d16:	04a49703          	lh	a4,74(s1)
    80003d1a:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003d1e:	44f8                	lw	a4,76(s1)
    80003d20:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003d22:	03400613          	li	a2,52
    80003d26:	05048593          	addi	a1,s1,80
    80003d2a:	0531                	addi	a0,a0,12
    80003d2c:	ffffd097          	auipc	ra,0xffffd
    80003d30:	002080e7          	jalr	2(ra) # 80000d2e <memmove>
  log_write(bp);
    80003d34:	854a                	mv	a0,s2
    80003d36:	00001097          	auipc	ra,0x1
    80003d3a:	bf6080e7          	jalr	-1034(ra) # 8000492c <log_write>
  brelse(bp);
    80003d3e:	854a                	mv	a0,s2
    80003d40:	00000097          	auipc	ra,0x0
    80003d44:	968080e7          	jalr	-1688(ra) # 800036a8 <brelse>
}
    80003d48:	60e2                	ld	ra,24(sp)
    80003d4a:	6442                	ld	s0,16(sp)
    80003d4c:	64a2                	ld	s1,8(sp)
    80003d4e:	6902                	ld	s2,0(sp)
    80003d50:	6105                	addi	sp,sp,32
    80003d52:	8082                	ret

0000000080003d54 <idup>:
{
    80003d54:	1101                	addi	sp,sp,-32
    80003d56:	ec06                	sd	ra,24(sp)
    80003d58:	e822                	sd	s0,16(sp)
    80003d5a:	e426                	sd	s1,8(sp)
    80003d5c:	1000                	addi	s0,sp,32
    80003d5e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d60:	0001b517          	auipc	a0,0x1b
    80003d64:	5a850513          	addi	a0,a0,1448 # 8001f308 <itable>
    80003d68:	ffffd097          	auipc	ra,0xffffd
    80003d6c:	e6e080e7          	jalr	-402(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003d70:	449c                	lw	a5,8(s1)
    80003d72:	2785                	addiw	a5,a5,1
    80003d74:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d76:	0001b517          	auipc	a0,0x1b
    80003d7a:	59250513          	addi	a0,a0,1426 # 8001f308 <itable>
    80003d7e:	ffffd097          	auipc	ra,0xffffd
    80003d82:	f0c080e7          	jalr	-244(ra) # 80000c8a <release>
}
    80003d86:	8526                	mv	a0,s1
    80003d88:	60e2                	ld	ra,24(sp)
    80003d8a:	6442                	ld	s0,16(sp)
    80003d8c:	64a2                	ld	s1,8(sp)
    80003d8e:	6105                	addi	sp,sp,32
    80003d90:	8082                	ret

0000000080003d92 <ilock>:
{
    80003d92:	1101                	addi	sp,sp,-32
    80003d94:	ec06                	sd	ra,24(sp)
    80003d96:	e822                	sd	s0,16(sp)
    80003d98:	e426                	sd	s1,8(sp)
    80003d9a:	e04a                	sd	s2,0(sp)
    80003d9c:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003d9e:	c115                	beqz	a0,80003dc2 <ilock+0x30>
    80003da0:	84aa                	mv	s1,a0
    80003da2:	451c                	lw	a5,8(a0)
    80003da4:	00f05f63          	blez	a5,80003dc2 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003da8:	0541                	addi	a0,a0,16
    80003daa:	00001097          	auipc	ra,0x1
    80003dae:	ca2080e7          	jalr	-862(ra) # 80004a4c <acquiresleep>
  if(ip->valid == 0){
    80003db2:	40bc                	lw	a5,64(s1)
    80003db4:	cf99                	beqz	a5,80003dd2 <ilock+0x40>
}
    80003db6:	60e2                	ld	ra,24(sp)
    80003db8:	6442                	ld	s0,16(sp)
    80003dba:	64a2                	ld	s1,8(sp)
    80003dbc:	6902                	ld	s2,0(sp)
    80003dbe:	6105                	addi	sp,sp,32
    80003dc0:	8082                	ret
    panic("ilock");
    80003dc2:	00005517          	auipc	a0,0x5
    80003dc6:	87650513          	addi	a0,a0,-1930 # 80008638 <syscalls+0x1c8>
    80003dca:	ffffc097          	auipc	ra,0xffffc
    80003dce:	774080e7          	jalr	1908(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003dd2:	40dc                	lw	a5,4(s1)
    80003dd4:	0047d79b          	srliw	a5,a5,0x4
    80003dd8:	0001b597          	auipc	a1,0x1b
    80003ddc:	5285a583          	lw	a1,1320(a1) # 8001f300 <sb+0x18>
    80003de0:	9dbd                	addw	a1,a1,a5
    80003de2:	4088                	lw	a0,0(s1)
    80003de4:	fffff097          	auipc	ra,0xfffff
    80003de8:	794080e7          	jalr	1940(ra) # 80003578 <bread>
    80003dec:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003dee:	05850593          	addi	a1,a0,88
    80003df2:	40dc                	lw	a5,4(s1)
    80003df4:	8bbd                	andi	a5,a5,15
    80003df6:	079a                	slli	a5,a5,0x6
    80003df8:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003dfa:	00059783          	lh	a5,0(a1)
    80003dfe:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003e02:	00259783          	lh	a5,2(a1)
    80003e06:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003e0a:	00459783          	lh	a5,4(a1)
    80003e0e:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003e12:	00659783          	lh	a5,6(a1)
    80003e16:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003e1a:	459c                	lw	a5,8(a1)
    80003e1c:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003e1e:	03400613          	li	a2,52
    80003e22:	05b1                	addi	a1,a1,12
    80003e24:	05048513          	addi	a0,s1,80
    80003e28:	ffffd097          	auipc	ra,0xffffd
    80003e2c:	f06080e7          	jalr	-250(ra) # 80000d2e <memmove>
    brelse(bp);
    80003e30:	854a                	mv	a0,s2
    80003e32:	00000097          	auipc	ra,0x0
    80003e36:	876080e7          	jalr	-1930(ra) # 800036a8 <brelse>
    ip->valid = 1;
    80003e3a:	4785                	li	a5,1
    80003e3c:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003e3e:	04449783          	lh	a5,68(s1)
    80003e42:	fbb5                	bnez	a5,80003db6 <ilock+0x24>
      panic("ilock: no type");
    80003e44:	00004517          	auipc	a0,0x4
    80003e48:	7fc50513          	addi	a0,a0,2044 # 80008640 <syscalls+0x1d0>
    80003e4c:	ffffc097          	auipc	ra,0xffffc
    80003e50:	6f2080e7          	jalr	1778(ra) # 8000053e <panic>

0000000080003e54 <iunlock>:
{
    80003e54:	1101                	addi	sp,sp,-32
    80003e56:	ec06                	sd	ra,24(sp)
    80003e58:	e822                	sd	s0,16(sp)
    80003e5a:	e426                	sd	s1,8(sp)
    80003e5c:	e04a                	sd	s2,0(sp)
    80003e5e:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003e60:	c905                	beqz	a0,80003e90 <iunlock+0x3c>
    80003e62:	84aa                	mv	s1,a0
    80003e64:	01050913          	addi	s2,a0,16
    80003e68:	854a                	mv	a0,s2
    80003e6a:	00001097          	auipc	ra,0x1
    80003e6e:	c7c080e7          	jalr	-900(ra) # 80004ae6 <holdingsleep>
    80003e72:	cd19                	beqz	a0,80003e90 <iunlock+0x3c>
    80003e74:	449c                	lw	a5,8(s1)
    80003e76:	00f05d63          	blez	a5,80003e90 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003e7a:	854a                	mv	a0,s2
    80003e7c:	00001097          	auipc	ra,0x1
    80003e80:	c26080e7          	jalr	-986(ra) # 80004aa2 <releasesleep>
}
    80003e84:	60e2                	ld	ra,24(sp)
    80003e86:	6442                	ld	s0,16(sp)
    80003e88:	64a2                	ld	s1,8(sp)
    80003e8a:	6902                	ld	s2,0(sp)
    80003e8c:	6105                	addi	sp,sp,32
    80003e8e:	8082                	ret
    panic("iunlock");
    80003e90:	00004517          	auipc	a0,0x4
    80003e94:	7c050513          	addi	a0,a0,1984 # 80008650 <syscalls+0x1e0>
    80003e98:	ffffc097          	auipc	ra,0xffffc
    80003e9c:	6a6080e7          	jalr	1702(ra) # 8000053e <panic>

0000000080003ea0 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003ea0:	7179                	addi	sp,sp,-48
    80003ea2:	f406                	sd	ra,40(sp)
    80003ea4:	f022                	sd	s0,32(sp)
    80003ea6:	ec26                	sd	s1,24(sp)
    80003ea8:	e84a                	sd	s2,16(sp)
    80003eaa:	e44e                	sd	s3,8(sp)
    80003eac:	e052                	sd	s4,0(sp)
    80003eae:	1800                	addi	s0,sp,48
    80003eb0:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003eb2:	05050493          	addi	s1,a0,80
    80003eb6:	08050913          	addi	s2,a0,128
    80003eba:	a021                	j	80003ec2 <itrunc+0x22>
    80003ebc:	0491                	addi	s1,s1,4
    80003ebe:	01248d63          	beq	s1,s2,80003ed8 <itrunc+0x38>
    if(ip->addrs[i]){
    80003ec2:	408c                	lw	a1,0(s1)
    80003ec4:	dde5                	beqz	a1,80003ebc <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003ec6:	0009a503          	lw	a0,0(s3)
    80003eca:	00000097          	auipc	ra,0x0
    80003ece:	8f4080e7          	jalr	-1804(ra) # 800037be <bfree>
      ip->addrs[i] = 0;
    80003ed2:	0004a023          	sw	zero,0(s1)
    80003ed6:	b7dd                	j	80003ebc <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003ed8:	0809a583          	lw	a1,128(s3)
    80003edc:	e185                	bnez	a1,80003efc <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003ede:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003ee2:	854e                	mv	a0,s3
    80003ee4:	00000097          	auipc	ra,0x0
    80003ee8:	de4080e7          	jalr	-540(ra) # 80003cc8 <iupdate>
}
    80003eec:	70a2                	ld	ra,40(sp)
    80003eee:	7402                	ld	s0,32(sp)
    80003ef0:	64e2                	ld	s1,24(sp)
    80003ef2:	6942                	ld	s2,16(sp)
    80003ef4:	69a2                	ld	s3,8(sp)
    80003ef6:	6a02                	ld	s4,0(sp)
    80003ef8:	6145                	addi	sp,sp,48
    80003efa:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003efc:	0009a503          	lw	a0,0(s3)
    80003f00:	fffff097          	auipc	ra,0xfffff
    80003f04:	678080e7          	jalr	1656(ra) # 80003578 <bread>
    80003f08:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003f0a:	05850493          	addi	s1,a0,88
    80003f0e:	45850913          	addi	s2,a0,1112
    80003f12:	a021                	j	80003f1a <itrunc+0x7a>
    80003f14:	0491                	addi	s1,s1,4
    80003f16:	01248b63          	beq	s1,s2,80003f2c <itrunc+0x8c>
      if(a[j])
    80003f1a:	408c                	lw	a1,0(s1)
    80003f1c:	dde5                	beqz	a1,80003f14 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003f1e:	0009a503          	lw	a0,0(s3)
    80003f22:	00000097          	auipc	ra,0x0
    80003f26:	89c080e7          	jalr	-1892(ra) # 800037be <bfree>
    80003f2a:	b7ed                	j	80003f14 <itrunc+0x74>
    brelse(bp);
    80003f2c:	8552                	mv	a0,s4
    80003f2e:	fffff097          	auipc	ra,0xfffff
    80003f32:	77a080e7          	jalr	1914(ra) # 800036a8 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003f36:	0809a583          	lw	a1,128(s3)
    80003f3a:	0009a503          	lw	a0,0(s3)
    80003f3e:	00000097          	auipc	ra,0x0
    80003f42:	880080e7          	jalr	-1920(ra) # 800037be <bfree>
    ip->addrs[NDIRECT] = 0;
    80003f46:	0809a023          	sw	zero,128(s3)
    80003f4a:	bf51                	j	80003ede <itrunc+0x3e>

0000000080003f4c <iput>:
{
    80003f4c:	1101                	addi	sp,sp,-32
    80003f4e:	ec06                	sd	ra,24(sp)
    80003f50:	e822                	sd	s0,16(sp)
    80003f52:	e426                	sd	s1,8(sp)
    80003f54:	e04a                	sd	s2,0(sp)
    80003f56:	1000                	addi	s0,sp,32
    80003f58:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003f5a:	0001b517          	auipc	a0,0x1b
    80003f5e:	3ae50513          	addi	a0,a0,942 # 8001f308 <itable>
    80003f62:	ffffd097          	auipc	ra,0xffffd
    80003f66:	c74080e7          	jalr	-908(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f6a:	4498                	lw	a4,8(s1)
    80003f6c:	4785                	li	a5,1
    80003f6e:	02f70363          	beq	a4,a5,80003f94 <iput+0x48>
  ip->ref--;
    80003f72:	449c                	lw	a5,8(s1)
    80003f74:	37fd                	addiw	a5,a5,-1
    80003f76:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003f78:	0001b517          	auipc	a0,0x1b
    80003f7c:	39050513          	addi	a0,a0,912 # 8001f308 <itable>
    80003f80:	ffffd097          	auipc	ra,0xffffd
    80003f84:	d0a080e7          	jalr	-758(ra) # 80000c8a <release>
}
    80003f88:	60e2                	ld	ra,24(sp)
    80003f8a:	6442                	ld	s0,16(sp)
    80003f8c:	64a2                	ld	s1,8(sp)
    80003f8e:	6902                	ld	s2,0(sp)
    80003f90:	6105                	addi	sp,sp,32
    80003f92:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f94:	40bc                	lw	a5,64(s1)
    80003f96:	dff1                	beqz	a5,80003f72 <iput+0x26>
    80003f98:	04a49783          	lh	a5,74(s1)
    80003f9c:	fbf9                	bnez	a5,80003f72 <iput+0x26>
    acquiresleep(&ip->lock);
    80003f9e:	01048913          	addi	s2,s1,16
    80003fa2:	854a                	mv	a0,s2
    80003fa4:	00001097          	auipc	ra,0x1
    80003fa8:	aa8080e7          	jalr	-1368(ra) # 80004a4c <acquiresleep>
    release(&itable.lock);
    80003fac:	0001b517          	auipc	a0,0x1b
    80003fb0:	35c50513          	addi	a0,a0,860 # 8001f308 <itable>
    80003fb4:	ffffd097          	auipc	ra,0xffffd
    80003fb8:	cd6080e7          	jalr	-810(ra) # 80000c8a <release>
    itrunc(ip);
    80003fbc:	8526                	mv	a0,s1
    80003fbe:	00000097          	auipc	ra,0x0
    80003fc2:	ee2080e7          	jalr	-286(ra) # 80003ea0 <itrunc>
    ip->type = 0;
    80003fc6:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003fca:	8526                	mv	a0,s1
    80003fcc:	00000097          	auipc	ra,0x0
    80003fd0:	cfc080e7          	jalr	-772(ra) # 80003cc8 <iupdate>
    ip->valid = 0;
    80003fd4:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003fd8:	854a                	mv	a0,s2
    80003fda:	00001097          	auipc	ra,0x1
    80003fde:	ac8080e7          	jalr	-1336(ra) # 80004aa2 <releasesleep>
    acquire(&itable.lock);
    80003fe2:	0001b517          	auipc	a0,0x1b
    80003fe6:	32650513          	addi	a0,a0,806 # 8001f308 <itable>
    80003fea:	ffffd097          	auipc	ra,0xffffd
    80003fee:	bec080e7          	jalr	-1044(ra) # 80000bd6 <acquire>
    80003ff2:	b741                	j	80003f72 <iput+0x26>

0000000080003ff4 <iunlockput>:
{
    80003ff4:	1101                	addi	sp,sp,-32
    80003ff6:	ec06                	sd	ra,24(sp)
    80003ff8:	e822                	sd	s0,16(sp)
    80003ffa:	e426                	sd	s1,8(sp)
    80003ffc:	1000                	addi	s0,sp,32
    80003ffe:	84aa                	mv	s1,a0
  iunlock(ip);
    80004000:	00000097          	auipc	ra,0x0
    80004004:	e54080e7          	jalr	-428(ra) # 80003e54 <iunlock>
  iput(ip);
    80004008:	8526                	mv	a0,s1
    8000400a:	00000097          	auipc	ra,0x0
    8000400e:	f42080e7          	jalr	-190(ra) # 80003f4c <iput>
}
    80004012:	60e2                	ld	ra,24(sp)
    80004014:	6442                	ld	s0,16(sp)
    80004016:	64a2                	ld	s1,8(sp)
    80004018:	6105                	addi	sp,sp,32
    8000401a:	8082                	ret

000000008000401c <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000401c:	1141                	addi	sp,sp,-16
    8000401e:	e422                	sd	s0,8(sp)
    80004020:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004022:	411c                	lw	a5,0(a0)
    80004024:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004026:	415c                	lw	a5,4(a0)
    80004028:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000402a:	04451783          	lh	a5,68(a0)
    8000402e:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004032:	04a51783          	lh	a5,74(a0)
    80004036:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000403a:	04c56783          	lwu	a5,76(a0)
    8000403e:	e99c                	sd	a5,16(a1)
}
    80004040:	6422                	ld	s0,8(sp)
    80004042:	0141                	addi	sp,sp,16
    80004044:	8082                	ret

0000000080004046 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004046:	457c                	lw	a5,76(a0)
    80004048:	0ed7e963          	bltu	a5,a3,8000413a <readi+0xf4>
{
    8000404c:	7159                	addi	sp,sp,-112
    8000404e:	f486                	sd	ra,104(sp)
    80004050:	f0a2                	sd	s0,96(sp)
    80004052:	eca6                	sd	s1,88(sp)
    80004054:	e8ca                	sd	s2,80(sp)
    80004056:	e4ce                	sd	s3,72(sp)
    80004058:	e0d2                	sd	s4,64(sp)
    8000405a:	fc56                	sd	s5,56(sp)
    8000405c:	f85a                	sd	s6,48(sp)
    8000405e:	f45e                	sd	s7,40(sp)
    80004060:	f062                	sd	s8,32(sp)
    80004062:	ec66                	sd	s9,24(sp)
    80004064:	e86a                	sd	s10,16(sp)
    80004066:	e46e                	sd	s11,8(sp)
    80004068:	1880                	addi	s0,sp,112
    8000406a:	8b2a                	mv	s6,a0
    8000406c:	8bae                	mv	s7,a1
    8000406e:	8a32                	mv	s4,a2
    80004070:	84b6                	mv	s1,a3
    80004072:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80004074:	9f35                	addw	a4,a4,a3
    return 0;
    80004076:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004078:	0ad76063          	bltu	a4,a3,80004118 <readi+0xd2>
  if(off + n > ip->size)
    8000407c:	00e7f463          	bgeu	a5,a4,80004084 <readi+0x3e>
    n = ip->size - off;
    80004080:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004084:	0a0a8963          	beqz	s5,80004136 <readi+0xf0>
    80004088:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000408a:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000408e:	5c7d                	li	s8,-1
    80004090:	a82d                	j	800040ca <readi+0x84>
    80004092:	020d1d93          	slli	s11,s10,0x20
    80004096:	020ddd93          	srli	s11,s11,0x20
    8000409a:	05890793          	addi	a5,s2,88
    8000409e:	86ee                	mv	a3,s11
    800040a0:	963e                	add	a2,a2,a5
    800040a2:	85d2                	mv	a1,s4
    800040a4:	855e                	mv	a0,s7
    800040a6:	ffffe097          	auipc	ra,0xffffe
    800040aa:	408080e7          	jalr	1032(ra) # 800024ae <either_copyout>
    800040ae:	05850d63          	beq	a0,s8,80004108 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800040b2:	854a                	mv	a0,s2
    800040b4:	fffff097          	auipc	ra,0xfffff
    800040b8:	5f4080e7          	jalr	1524(ra) # 800036a8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040bc:	013d09bb          	addw	s3,s10,s3
    800040c0:	009d04bb          	addw	s1,s10,s1
    800040c4:	9a6e                	add	s4,s4,s11
    800040c6:	0559f763          	bgeu	s3,s5,80004114 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    800040ca:	00a4d59b          	srliw	a1,s1,0xa
    800040ce:	855a                	mv	a0,s6
    800040d0:	00000097          	auipc	ra,0x0
    800040d4:	8a2080e7          	jalr	-1886(ra) # 80003972 <bmap>
    800040d8:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800040dc:	cd85                	beqz	a1,80004114 <readi+0xce>
    bp = bread(ip->dev, addr);
    800040de:	000b2503          	lw	a0,0(s6)
    800040e2:	fffff097          	auipc	ra,0xfffff
    800040e6:	496080e7          	jalr	1174(ra) # 80003578 <bread>
    800040ea:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800040ec:	3ff4f613          	andi	a2,s1,1023
    800040f0:	40cc87bb          	subw	a5,s9,a2
    800040f4:	413a873b          	subw	a4,s5,s3
    800040f8:	8d3e                	mv	s10,a5
    800040fa:	2781                	sext.w	a5,a5
    800040fc:	0007069b          	sext.w	a3,a4
    80004100:	f8f6f9e3          	bgeu	a3,a5,80004092 <readi+0x4c>
    80004104:	8d3a                	mv	s10,a4
    80004106:	b771                	j	80004092 <readi+0x4c>
      brelse(bp);
    80004108:	854a                	mv	a0,s2
    8000410a:	fffff097          	auipc	ra,0xfffff
    8000410e:	59e080e7          	jalr	1438(ra) # 800036a8 <brelse>
      tot = -1;
    80004112:	59fd                	li	s3,-1
  }
  return tot;
    80004114:	0009851b          	sext.w	a0,s3
}
    80004118:	70a6                	ld	ra,104(sp)
    8000411a:	7406                	ld	s0,96(sp)
    8000411c:	64e6                	ld	s1,88(sp)
    8000411e:	6946                	ld	s2,80(sp)
    80004120:	69a6                	ld	s3,72(sp)
    80004122:	6a06                	ld	s4,64(sp)
    80004124:	7ae2                	ld	s5,56(sp)
    80004126:	7b42                	ld	s6,48(sp)
    80004128:	7ba2                	ld	s7,40(sp)
    8000412a:	7c02                	ld	s8,32(sp)
    8000412c:	6ce2                	ld	s9,24(sp)
    8000412e:	6d42                	ld	s10,16(sp)
    80004130:	6da2                	ld	s11,8(sp)
    80004132:	6165                	addi	sp,sp,112
    80004134:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004136:	89d6                	mv	s3,s5
    80004138:	bff1                	j	80004114 <readi+0xce>
    return 0;
    8000413a:	4501                	li	a0,0
}
    8000413c:	8082                	ret

000000008000413e <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000413e:	457c                	lw	a5,76(a0)
    80004140:	10d7e863          	bltu	a5,a3,80004250 <writei+0x112>
{
    80004144:	7159                	addi	sp,sp,-112
    80004146:	f486                	sd	ra,104(sp)
    80004148:	f0a2                	sd	s0,96(sp)
    8000414a:	eca6                	sd	s1,88(sp)
    8000414c:	e8ca                	sd	s2,80(sp)
    8000414e:	e4ce                	sd	s3,72(sp)
    80004150:	e0d2                	sd	s4,64(sp)
    80004152:	fc56                	sd	s5,56(sp)
    80004154:	f85a                	sd	s6,48(sp)
    80004156:	f45e                	sd	s7,40(sp)
    80004158:	f062                	sd	s8,32(sp)
    8000415a:	ec66                	sd	s9,24(sp)
    8000415c:	e86a                	sd	s10,16(sp)
    8000415e:	e46e                	sd	s11,8(sp)
    80004160:	1880                	addi	s0,sp,112
    80004162:	8aaa                	mv	s5,a0
    80004164:	8bae                	mv	s7,a1
    80004166:	8a32                	mv	s4,a2
    80004168:	8936                	mv	s2,a3
    8000416a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    8000416c:	00e687bb          	addw	a5,a3,a4
    80004170:	0ed7e263          	bltu	a5,a3,80004254 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004174:	00043737          	lui	a4,0x43
    80004178:	0ef76063          	bltu	a4,a5,80004258 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000417c:	0c0b0863          	beqz	s6,8000424c <writei+0x10e>
    80004180:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004182:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004186:	5c7d                	li	s8,-1
    80004188:	a091                	j	800041cc <writei+0x8e>
    8000418a:	020d1d93          	slli	s11,s10,0x20
    8000418e:	020ddd93          	srli	s11,s11,0x20
    80004192:	05848793          	addi	a5,s1,88
    80004196:	86ee                	mv	a3,s11
    80004198:	8652                	mv	a2,s4
    8000419a:	85de                	mv	a1,s7
    8000419c:	953e                	add	a0,a0,a5
    8000419e:	ffffe097          	auipc	ra,0xffffe
    800041a2:	366080e7          	jalr	870(ra) # 80002504 <either_copyin>
    800041a6:	07850263          	beq	a0,s8,8000420a <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800041aa:	8526                	mv	a0,s1
    800041ac:	00000097          	auipc	ra,0x0
    800041b0:	780080e7          	jalr	1920(ra) # 8000492c <log_write>
    brelse(bp);
    800041b4:	8526                	mv	a0,s1
    800041b6:	fffff097          	auipc	ra,0xfffff
    800041ba:	4f2080e7          	jalr	1266(ra) # 800036a8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041be:	013d09bb          	addw	s3,s10,s3
    800041c2:	012d093b          	addw	s2,s10,s2
    800041c6:	9a6e                	add	s4,s4,s11
    800041c8:	0569f663          	bgeu	s3,s6,80004214 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    800041cc:	00a9559b          	srliw	a1,s2,0xa
    800041d0:	8556                	mv	a0,s5
    800041d2:	fffff097          	auipc	ra,0xfffff
    800041d6:	7a0080e7          	jalr	1952(ra) # 80003972 <bmap>
    800041da:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800041de:	c99d                	beqz	a1,80004214 <writei+0xd6>
    bp = bread(ip->dev, addr);
    800041e0:	000aa503          	lw	a0,0(s5) # 1000 <_entry-0x7ffff000>
    800041e4:	fffff097          	auipc	ra,0xfffff
    800041e8:	394080e7          	jalr	916(ra) # 80003578 <bread>
    800041ec:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800041ee:	3ff97513          	andi	a0,s2,1023
    800041f2:	40ac87bb          	subw	a5,s9,a0
    800041f6:	413b073b          	subw	a4,s6,s3
    800041fa:	8d3e                	mv	s10,a5
    800041fc:	2781                	sext.w	a5,a5
    800041fe:	0007069b          	sext.w	a3,a4
    80004202:	f8f6f4e3          	bgeu	a3,a5,8000418a <writei+0x4c>
    80004206:	8d3a                	mv	s10,a4
    80004208:	b749                	j	8000418a <writei+0x4c>
      brelse(bp);
    8000420a:	8526                	mv	a0,s1
    8000420c:	fffff097          	auipc	ra,0xfffff
    80004210:	49c080e7          	jalr	1180(ra) # 800036a8 <brelse>
  }

  if(off > ip->size)
    80004214:	04caa783          	lw	a5,76(s5)
    80004218:	0127f463          	bgeu	a5,s2,80004220 <writei+0xe2>
    ip->size = off;
    8000421c:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004220:	8556                	mv	a0,s5
    80004222:	00000097          	auipc	ra,0x0
    80004226:	aa6080e7          	jalr	-1370(ra) # 80003cc8 <iupdate>

  return tot;
    8000422a:	0009851b          	sext.w	a0,s3
}
    8000422e:	70a6                	ld	ra,104(sp)
    80004230:	7406                	ld	s0,96(sp)
    80004232:	64e6                	ld	s1,88(sp)
    80004234:	6946                	ld	s2,80(sp)
    80004236:	69a6                	ld	s3,72(sp)
    80004238:	6a06                	ld	s4,64(sp)
    8000423a:	7ae2                	ld	s5,56(sp)
    8000423c:	7b42                	ld	s6,48(sp)
    8000423e:	7ba2                	ld	s7,40(sp)
    80004240:	7c02                	ld	s8,32(sp)
    80004242:	6ce2                	ld	s9,24(sp)
    80004244:	6d42                	ld	s10,16(sp)
    80004246:	6da2                	ld	s11,8(sp)
    80004248:	6165                	addi	sp,sp,112
    8000424a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000424c:	89da                	mv	s3,s6
    8000424e:	bfc9                	j	80004220 <writei+0xe2>
    return -1;
    80004250:	557d                	li	a0,-1
}
    80004252:	8082                	ret
    return -1;
    80004254:	557d                	li	a0,-1
    80004256:	bfe1                	j	8000422e <writei+0xf0>
    return -1;
    80004258:	557d                	li	a0,-1
    8000425a:	bfd1                	j	8000422e <writei+0xf0>

000000008000425c <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000425c:	1141                	addi	sp,sp,-16
    8000425e:	e406                	sd	ra,8(sp)
    80004260:	e022                	sd	s0,0(sp)
    80004262:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004264:	4639                	li	a2,14
    80004266:	ffffd097          	auipc	ra,0xffffd
    8000426a:	b3c080e7          	jalr	-1220(ra) # 80000da2 <strncmp>
}
    8000426e:	60a2                	ld	ra,8(sp)
    80004270:	6402                	ld	s0,0(sp)
    80004272:	0141                	addi	sp,sp,16
    80004274:	8082                	ret

0000000080004276 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004276:	7139                	addi	sp,sp,-64
    80004278:	fc06                	sd	ra,56(sp)
    8000427a:	f822                	sd	s0,48(sp)
    8000427c:	f426                	sd	s1,40(sp)
    8000427e:	f04a                	sd	s2,32(sp)
    80004280:	ec4e                	sd	s3,24(sp)
    80004282:	e852                	sd	s4,16(sp)
    80004284:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004286:	04451703          	lh	a4,68(a0)
    8000428a:	4785                	li	a5,1
    8000428c:	00f71a63          	bne	a4,a5,800042a0 <dirlookup+0x2a>
    80004290:	892a                	mv	s2,a0
    80004292:	89ae                	mv	s3,a1
    80004294:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004296:	457c                	lw	a5,76(a0)
    80004298:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000429a:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000429c:	e79d                	bnez	a5,800042ca <dirlookup+0x54>
    8000429e:	a8a5                	j	80004316 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800042a0:	00004517          	auipc	a0,0x4
    800042a4:	3b850513          	addi	a0,a0,952 # 80008658 <syscalls+0x1e8>
    800042a8:	ffffc097          	auipc	ra,0xffffc
    800042ac:	296080e7          	jalr	662(ra) # 8000053e <panic>
      panic("dirlookup read");
    800042b0:	00004517          	auipc	a0,0x4
    800042b4:	3c050513          	addi	a0,a0,960 # 80008670 <syscalls+0x200>
    800042b8:	ffffc097          	auipc	ra,0xffffc
    800042bc:	286080e7          	jalr	646(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042c0:	24c1                	addiw	s1,s1,16
    800042c2:	04c92783          	lw	a5,76(s2)
    800042c6:	04f4f763          	bgeu	s1,a5,80004314 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042ca:	4741                	li	a4,16
    800042cc:	86a6                	mv	a3,s1
    800042ce:	fc040613          	addi	a2,s0,-64
    800042d2:	4581                	li	a1,0
    800042d4:	854a                	mv	a0,s2
    800042d6:	00000097          	auipc	ra,0x0
    800042da:	d70080e7          	jalr	-656(ra) # 80004046 <readi>
    800042de:	47c1                	li	a5,16
    800042e0:	fcf518e3          	bne	a0,a5,800042b0 <dirlookup+0x3a>
    if(de.inum == 0)
    800042e4:	fc045783          	lhu	a5,-64(s0)
    800042e8:	dfe1                	beqz	a5,800042c0 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800042ea:	fc240593          	addi	a1,s0,-62
    800042ee:	854e                	mv	a0,s3
    800042f0:	00000097          	auipc	ra,0x0
    800042f4:	f6c080e7          	jalr	-148(ra) # 8000425c <namecmp>
    800042f8:	f561                	bnez	a0,800042c0 <dirlookup+0x4a>
      if(poff)
    800042fa:	000a0463          	beqz	s4,80004302 <dirlookup+0x8c>
        *poff = off;
    800042fe:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004302:	fc045583          	lhu	a1,-64(s0)
    80004306:	00092503          	lw	a0,0(s2)
    8000430a:	fffff097          	auipc	ra,0xfffff
    8000430e:	750080e7          	jalr	1872(ra) # 80003a5a <iget>
    80004312:	a011                	j	80004316 <dirlookup+0xa0>
  return 0;
    80004314:	4501                	li	a0,0
}
    80004316:	70e2                	ld	ra,56(sp)
    80004318:	7442                	ld	s0,48(sp)
    8000431a:	74a2                	ld	s1,40(sp)
    8000431c:	7902                	ld	s2,32(sp)
    8000431e:	69e2                	ld	s3,24(sp)
    80004320:	6a42                	ld	s4,16(sp)
    80004322:	6121                	addi	sp,sp,64
    80004324:	8082                	ret

0000000080004326 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004326:	711d                	addi	sp,sp,-96
    80004328:	ec86                	sd	ra,88(sp)
    8000432a:	e8a2                	sd	s0,80(sp)
    8000432c:	e4a6                	sd	s1,72(sp)
    8000432e:	e0ca                	sd	s2,64(sp)
    80004330:	fc4e                	sd	s3,56(sp)
    80004332:	f852                	sd	s4,48(sp)
    80004334:	f456                	sd	s5,40(sp)
    80004336:	f05a                	sd	s6,32(sp)
    80004338:	ec5e                	sd	s7,24(sp)
    8000433a:	e862                	sd	s8,16(sp)
    8000433c:	e466                	sd	s9,8(sp)
    8000433e:	1080                	addi	s0,sp,96
    80004340:	84aa                	mv	s1,a0
    80004342:	8aae                	mv	s5,a1
    80004344:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004346:	00054703          	lbu	a4,0(a0)
    8000434a:	02f00793          	li	a5,47
    8000434e:	02f70363          	beq	a4,a5,80004374 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004352:	ffffd097          	auipc	ra,0xffffd
    80004356:	68a080e7          	jalr	1674(ra) # 800019dc <myproc>
    8000435a:	15053503          	ld	a0,336(a0)
    8000435e:	00000097          	auipc	ra,0x0
    80004362:	9f6080e7          	jalr	-1546(ra) # 80003d54 <idup>
    80004366:	89aa                	mv	s3,a0
  while(*path == '/')
    80004368:	02f00913          	li	s2,47
  len = path - s;
    8000436c:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    8000436e:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004370:	4b85                	li	s7,1
    80004372:	a865                	j	8000442a <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004374:	4585                	li	a1,1
    80004376:	4505                	li	a0,1
    80004378:	fffff097          	auipc	ra,0xfffff
    8000437c:	6e2080e7          	jalr	1762(ra) # 80003a5a <iget>
    80004380:	89aa                	mv	s3,a0
    80004382:	b7dd                	j	80004368 <namex+0x42>
      iunlockput(ip);
    80004384:	854e                	mv	a0,s3
    80004386:	00000097          	auipc	ra,0x0
    8000438a:	c6e080e7          	jalr	-914(ra) # 80003ff4 <iunlockput>
      return 0;
    8000438e:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004390:	854e                	mv	a0,s3
    80004392:	60e6                	ld	ra,88(sp)
    80004394:	6446                	ld	s0,80(sp)
    80004396:	64a6                	ld	s1,72(sp)
    80004398:	6906                	ld	s2,64(sp)
    8000439a:	79e2                	ld	s3,56(sp)
    8000439c:	7a42                	ld	s4,48(sp)
    8000439e:	7aa2                	ld	s5,40(sp)
    800043a0:	7b02                	ld	s6,32(sp)
    800043a2:	6be2                	ld	s7,24(sp)
    800043a4:	6c42                	ld	s8,16(sp)
    800043a6:	6ca2                	ld	s9,8(sp)
    800043a8:	6125                	addi	sp,sp,96
    800043aa:	8082                	ret
      iunlock(ip);
    800043ac:	854e                	mv	a0,s3
    800043ae:	00000097          	auipc	ra,0x0
    800043b2:	aa6080e7          	jalr	-1370(ra) # 80003e54 <iunlock>
      return ip;
    800043b6:	bfe9                	j	80004390 <namex+0x6a>
      iunlockput(ip);
    800043b8:	854e                	mv	a0,s3
    800043ba:	00000097          	auipc	ra,0x0
    800043be:	c3a080e7          	jalr	-966(ra) # 80003ff4 <iunlockput>
      return 0;
    800043c2:	89e6                	mv	s3,s9
    800043c4:	b7f1                	j	80004390 <namex+0x6a>
  len = path - s;
    800043c6:	40b48633          	sub	a2,s1,a1
    800043ca:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800043ce:	099c5463          	bge	s8,s9,80004456 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800043d2:	4639                	li	a2,14
    800043d4:	8552                	mv	a0,s4
    800043d6:	ffffd097          	auipc	ra,0xffffd
    800043da:	958080e7          	jalr	-1704(ra) # 80000d2e <memmove>
  while(*path == '/')
    800043de:	0004c783          	lbu	a5,0(s1)
    800043e2:	01279763          	bne	a5,s2,800043f0 <namex+0xca>
    path++;
    800043e6:	0485                	addi	s1,s1,1
  while(*path == '/')
    800043e8:	0004c783          	lbu	a5,0(s1)
    800043ec:	ff278de3          	beq	a5,s2,800043e6 <namex+0xc0>
    ilock(ip);
    800043f0:	854e                	mv	a0,s3
    800043f2:	00000097          	auipc	ra,0x0
    800043f6:	9a0080e7          	jalr	-1632(ra) # 80003d92 <ilock>
    if(ip->type != T_DIR){
    800043fa:	04499783          	lh	a5,68(s3)
    800043fe:	f97793e3          	bne	a5,s7,80004384 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004402:	000a8563          	beqz	s5,8000440c <namex+0xe6>
    80004406:	0004c783          	lbu	a5,0(s1)
    8000440a:	d3cd                	beqz	a5,800043ac <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000440c:	865a                	mv	a2,s6
    8000440e:	85d2                	mv	a1,s4
    80004410:	854e                	mv	a0,s3
    80004412:	00000097          	auipc	ra,0x0
    80004416:	e64080e7          	jalr	-412(ra) # 80004276 <dirlookup>
    8000441a:	8caa                	mv	s9,a0
    8000441c:	dd51                	beqz	a0,800043b8 <namex+0x92>
    iunlockput(ip);
    8000441e:	854e                	mv	a0,s3
    80004420:	00000097          	auipc	ra,0x0
    80004424:	bd4080e7          	jalr	-1068(ra) # 80003ff4 <iunlockput>
    ip = next;
    80004428:	89e6                	mv	s3,s9
  while(*path == '/')
    8000442a:	0004c783          	lbu	a5,0(s1)
    8000442e:	05279763          	bne	a5,s2,8000447c <namex+0x156>
    path++;
    80004432:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004434:	0004c783          	lbu	a5,0(s1)
    80004438:	ff278de3          	beq	a5,s2,80004432 <namex+0x10c>
  if(*path == 0)
    8000443c:	c79d                	beqz	a5,8000446a <namex+0x144>
    path++;
    8000443e:	85a6                	mv	a1,s1
  len = path - s;
    80004440:	8cda                	mv	s9,s6
    80004442:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80004444:	01278963          	beq	a5,s2,80004456 <namex+0x130>
    80004448:	dfbd                	beqz	a5,800043c6 <namex+0xa0>
    path++;
    8000444a:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000444c:	0004c783          	lbu	a5,0(s1)
    80004450:	ff279ce3          	bne	a5,s2,80004448 <namex+0x122>
    80004454:	bf8d                	j	800043c6 <namex+0xa0>
    memmove(name, s, len);
    80004456:	2601                	sext.w	a2,a2
    80004458:	8552                	mv	a0,s4
    8000445a:	ffffd097          	auipc	ra,0xffffd
    8000445e:	8d4080e7          	jalr	-1836(ra) # 80000d2e <memmove>
    name[len] = 0;
    80004462:	9cd2                	add	s9,s9,s4
    80004464:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004468:	bf9d                	j	800043de <namex+0xb8>
  if(nameiparent){
    8000446a:	f20a83e3          	beqz	s5,80004390 <namex+0x6a>
    iput(ip);
    8000446e:	854e                	mv	a0,s3
    80004470:	00000097          	auipc	ra,0x0
    80004474:	adc080e7          	jalr	-1316(ra) # 80003f4c <iput>
    return 0;
    80004478:	4981                	li	s3,0
    8000447a:	bf19                	j	80004390 <namex+0x6a>
  if(*path == 0)
    8000447c:	d7fd                	beqz	a5,8000446a <namex+0x144>
  while(*path != '/' && *path != 0)
    8000447e:	0004c783          	lbu	a5,0(s1)
    80004482:	85a6                	mv	a1,s1
    80004484:	b7d1                	j	80004448 <namex+0x122>

0000000080004486 <dirlink>:
{
    80004486:	7139                	addi	sp,sp,-64
    80004488:	fc06                	sd	ra,56(sp)
    8000448a:	f822                	sd	s0,48(sp)
    8000448c:	f426                	sd	s1,40(sp)
    8000448e:	f04a                	sd	s2,32(sp)
    80004490:	ec4e                	sd	s3,24(sp)
    80004492:	e852                	sd	s4,16(sp)
    80004494:	0080                	addi	s0,sp,64
    80004496:	892a                	mv	s2,a0
    80004498:	8a2e                	mv	s4,a1
    8000449a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000449c:	4601                	li	a2,0
    8000449e:	00000097          	auipc	ra,0x0
    800044a2:	dd8080e7          	jalr	-552(ra) # 80004276 <dirlookup>
    800044a6:	e93d                	bnez	a0,8000451c <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044a8:	04c92483          	lw	s1,76(s2)
    800044ac:	c49d                	beqz	s1,800044da <dirlink+0x54>
    800044ae:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800044b0:	4741                	li	a4,16
    800044b2:	86a6                	mv	a3,s1
    800044b4:	fc040613          	addi	a2,s0,-64
    800044b8:	4581                	li	a1,0
    800044ba:	854a                	mv	a0,s2
    800044bc:	00000097          	auipc	ra,0x0
    800044c0:	b8a080e7          	jalr	-1142(ra) # 80004046 <readi>
    800044c4:	47c1                	li	a5,16
    800044c6:	06f51163          	bne	a0,a5,80004528 <dirlink+0xa2>
    if(de.inum == 0)
    800044ca:	fc045783          	lhu	a5,-64(s0)
    800044ce:	c791                	beqz	a5,800044da <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044d0:	24c1                	addiw	s1,s1,16
    800044d2:	04c92783          	lw	a5,76(s2)
    800044d6:	fcf4ede3          	bltu	s1,a5,800044b0 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800044da:	4639                	li	a2,14
    800044dc:	85d2                	mv	a1,s4
    800044de:	fc240513          	addi	a0,s0,-62
    800044e2:	ffffd097          	auipc	ra,0xffffd
    800044e6:	8fc080e7          	jalr	-1796(ra) # 80000dde <strncpy>
  de.inum = inum;
    800044ea:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800044ee:	4741                	li	a4,16
    800044f0:	86a6                	mv	a3,s1
    800044f2:	fc040613          	addi	a2,s0,-64
    800044f6:	4581                	li	a1,0
    800044f8:	854a                	mv	a0,s2
    800044fa:	00000097          	auipc	ra,0x0
    800044fe:	c44080e7          	jalr	-956(ra) # 8000413e <writei>
    80004502:	1541                	addi	a0,a0,-16
    80004504:	00a03533          	snez	a0,a0
    80004508:	40a00533          	neg	a0,a0
}
    8000450c:	70e2                	ld	ra,56(sp)
    8000450e:	7442                	ld	s0,48(sp)
    80004510:	74a2                	ld	s1,40(sp)
    80004512:	7902                	ld	s2,32(sp)
    80004514:	69e2                	ld	s3,24(sp)
    80004516:	6a42                	ld	s4,16(sp)
    80004518:	6121                	addi	sp,sp,64
    8000451a:	8082                	ret
    iput(ip);
    8000451c:	00000097          	auipc	ra,0x0
    80004520:	a30080e7          	jalr	-1488(ra) # 80003f4c <iput>
    return -1;
    80004524:	557d                	li	a0,-1
    80004526:	b7dd                	j	8000450c <dirlink+0x86>
      panic("dirlink read");
    80004528:	00004517          	auipc	a0,0x4
    8000452c:	15850513          	addi	a0,a0,344 # 80008680 <syscalls+0x210>
    80004530:	ffffc097          	auipc	ra,0xffffc
    80004534:	00e080e7          	jalr	14(ra) # 8000053e <panic>

0000000080004538 <namei>:

struct inode*
namei(char *path)
{
    80004538:	1101                	addi	sp,sp,-32
    8000453a:	ec06                	sd	ra,24(sp)
    8000453c:	e822                	sd	s0,16(sp)
    8000453e:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004540:	fe040613          	addi	a2,s0,-32
    80004544:	4581                	li	a1,0
    80004546:	00000097          	auipc	ra,0x0
    8000454a:	de0080e7          	jalr	-544(ra) # 80004326 <namex>
}
    8000454e:	60e2                	ld	ra,24(sp)
    80004550:	6442                	ld	s0,16(sp)
    80004552:	6105                	addi	sp,sp,32
    80004554:	8082                	ret

0000000080004556 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004556:	1141                	addi	sp,sp,-16
    80004558:	e406                	sd	ra,8(sp)
    8000455a:	e022                	sd	s0,0(sp)
    8000455c:	0800                	addi	s0,sp,16
    8000455e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004560:	4585                	li	a1,1
    80004562:	00000097          	auipc	ra,0x0
    80004566:	dc4080e7          	jalr	-572(ra) # 80004326 <namex>
}
    8000456a:	60a2                	ld	ra,8(sp)
    8000456c:	6402                	ld	s0,0(sp)
    8000456e:	0141                	addi	sp,sp,16
    80004570:	8082                	ret

0000000080004572 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004572:	1101                	addi	sp,sp,-32
    80004574:	ec06                	sd	ra,24(sp)
    80004576:	e822                	sd	s0,16(sp)
    80004578:	e426                	sd	s1,8(sp)
    8000457a:	e04a                	sd	s2,0(sp)
    8000457c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000457e:	0001d917          	auipc	s2,0x1d
    80004582:	83290913          	addi	s2,s2,-1998 # 80020db0 <log>
    80004586:	01892583          	lw	a1,24(s2)
    8000458a:	02892503          	lw	a0,40(s2)
    8000458e:	fffff097          	auipc	ra,0xfffff
    80004592:	fea080e7          	jalr	-22(ra) # 80003578 <bread>
    80004596:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004598:	02c92683          	lw	a3,44(s2)
    8000459c:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000459e:	02d05763          	blez	a3,800045cc <write_head+0x5a>
    800045a2:	0001d797          	auipc	a5,0x1d
    800045a6:	83e78793          	addi	a5,a5,-1986 # 80020de0 <log+0x30>
    800045aa:	05c50713          	addi	a4,a0,92
    800045ae:	36fd                	addiw	a3,a3,-1
    800045b0:	1682                	slli	a3,a3,0x20
    800045b2:	9281                	srli	a3,a3,0x20
    800045b4:	068a                	slli	a3,a3,0x2
    800045b6:	0001d617          	auipc	a2,0x1d
    800045ba:	82e60613          	addi	a2,a2,-2002 # 80020de4 <log+0x34>
    800045be:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800045c0:	4390                	lw	a2,0(a5)
    800045c2:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800045c4:	0791                	addi	a5,a5,4
    800045c6:	0711                	addi	a4,a4,4
    800045c8:	fed79ce3          	bne	a5,a3,800045c0 <write_head+0x4e>
  }
  bwrite(buf);
    800045cc:	8526                	mv	a0,s1
    800045ce:	fffff097          	auipc	ra,0xfffff
    800045d2:	09c080e7          	jalr	156(ra) # 8000366a <bwrite>
  brelse(buf);
    800045d6:	8526                	mv	a0,s1
    800045d8:	fffff097          	auipc	ra,0xfffff
    800045dc:	0d0080e7          	jalr	208(ra) # 800036a8 <brelse>
}
    800045e0:	60e2                	ld	ra,24(sp)
    800045e2:	6442                	ld	s0,16(sp)
    800045e4:	64a2                	ld	s1,8(sp)
    800045e6:	6902                	ld	s2,0(sp)
    800045e8:	6105                	addi	sp,sp,32
    800045ea:	8082                	ret

00000000800045ec <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800045ec:	0001c797          	auipc	a5,0x1c
    800045f0:	7f07a783          	lw	a5,2032(a5) # 80020ddc <log+0x2c>
    800045f4:	0af05d63          	blez	a5,800046ae <install_trans+0xc2>
{
    800045f8:	7139                	addi	sp,sp,-64
    800045fa:	fc06                	sd	ra,56(sp)
    800045fc:	f822                	sd	s0,48(sp)
    800045fe:	f426                	sd	s1,40(sp)
    80004600:	f04a                	sd	s2,32(sp)
    80004602:	ec4e                	sd	s3,24(sp)
    80004604:	e852                	sd	s4,16(sp)
    80004606:	e456                	sd	s5,8(sp)
    80004608:	e05a                	sd	s6,0(sp)
    8000460a:	0080                	addi	s0,sp,64
    8000460c:	8b2a                	mv	s6,a0
    8000460e:	0001ca97          	auipc	s5,0x1c
    80004612:	7d2a8a93          	addi	s5,s5,2002 # 80020de0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004616:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004618:	0001c997          	auipc	s3,0x1c
    8000461c:	79898993          	addi	s3,s3,1944 # 80020db0 <log>
    80004620:	a00d                	j	80004642 <install_trans+0x56>
    brelse(lbuf);
    80004622:	854a                	mv	a0,s2
    80004624:	fffff097          	auipc	ra,0xfffff
    80004628:	084080e7          	jalr	132(ra) # 800036a8 <brelse>
    brelse(dbuf);
    8000462c:	8526                	mv	a0,s1
    8000462e:	fffff097          	auipc	ra,0xfffff
    80004632:	07a080e7          	jalr	122(ra) # 800036a8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004636:	2a05                	addiw	s4,s4,1
    80004638:	0a91                	addi	s5,s5,4
    8000463a:	02c9a783          	lw	a5,44(s3)
    8000463e:	04fa5e63          	bge	s4,a5,8000469a <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004642:	0189a583          	lw	a1,24(s3)
    80004646:	014585bb          	addw	a1,a1,s4
    8000464a:	2585                	addiw	a1,a1,1
    8000464c:	0289a503          	lw	a0,40(s3)
    80004650:	fffff097          	auipc	ra,0xfffff
    80004654:	f28080e7          	jalr	-216(ra) # 80003578 <bread>
    80004658:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000465a:	000aa583          	lw	a1,0(s5)
    8000465e:	0289a503          	lw	a0,40(s3)
    80004662:	fffff097          	auipc	ra,0xfffff
    80004666:	f16080e7          	jalr	-234(ra) # 80003578 <bread>
    8000466a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000466c:	40000613          	li	a2,1024
    80004670:	05890593          	addi	a1,s2,88
    80004674:	05850513          	addi	a0,a0,88
    80004678:	ffffc097          	auipc	ra,0xffffc
    8000467c:	6b6080e7          	jalr	1718(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    80004680:	8526                	mv	a0,s1
    80004682:	fffff097          	auipc	ra,0xfffff
    80004686:	fe8080e7          	jalr	-24(ra) # 8000366a <bwrite>
    if(recovering == 0)
    8000468a:	f80b1ce3          	bnez	s6,80004622 <install_trans+0x36>
      bunpin(dbuf);
    8000468e:	8526                	mv	a0,s1
    80004690:	fffff097          	auipc	ra,0xfffff
    80004694:	0f2080e7          	jalr	242(ra) # 80003782 <bunpin>
    80004698:	b769                	j	80004622 <install_trans+0x36>
}
    8000469a:	70e2                	ld	ra,56(sp)
    8000469c:	7442                	ld	s0,48(sp)
    8000469e:	74a2                	ld	s1,40(sp)
    800046a0:	7902                	ld	s2,32(sp)
    800046a2:	69e2                	ld	s3,24(sp)
    800046a4:	6a42                	ld	s4,16(sp)
    800046a6:	6aa2                	ld	s5,8(sp)
    800046a8:	6b02                	ld	s6,0(sp)
    800046aa:	6121                	addi	sp,sp,64
    800046ac:	8082                	ret
    800046ae:	8082                	ret

00000000800046b0 <initlog>:
{
    800046b0:	7179                	addi	sp,sp,-48
    800046b2:	f406                	sd	ra,40(sp)
    800046b4:	f022                	sd	s0,32(sp)
    800046b6:	ec26                	sd	s1,24(sp)
    800046b8:	e84a                	sd	s2,16(sp)
    800046ba:	e44e                	sd	s3,8(sp)
    800046bc:	1800                	addi	s0,sp,48
    800046be:	892a                	mv	s2,a0
    800046c0:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800046c2:	0001c497          	auipc	s1,0x1c
    800046c6:	6ee48493          	addi	s1,s1,1774 # 80020db0 <log>
    800046ca:	00004597          	auipc	a1,0x4
    800046ce:	fc658593          	addi	a1,a1,-58 # 80008690 <syscalls+0x220>
    800046d2:	8526                	mv	a0,s1
    800046d4:	ffffc097          	auipc	ra,0xffffc
    800046d8:	472080e7          	jalr	1138(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    800046dc:	0149a583          	lw	a1,20(s3)
    800046e0:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800046e2:	0109a783          	lw	a5,16(s3)
    800046e6:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800046e8:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800046ec:	854a                	mv	a0,s2
    800046ee:	fffff097          	auipc	ra,0xfffff
    800046f2:	e8a080e7          	jalr	-374(ra) # 80003578 <bread>
  log.lh.n = lh->n;
    800046f6:	4d34                	lw	a3,88(a0)
    800046f8:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800046fa:	02d05563          	blez	a3,80004724 <initlog+0x74>
    800046fe:	05c50793          	addi	a5,a0,92
    80004702:	0001c717          	auipc	a4,0x1c
    80004706:	6de70713          	addi	a4,a4,1758 # 80020de0 <log+0x30>
    8000470a:	36fd                	addiw	a3,a3,-1
    8000470c:	1682                	slli	a3,a3,0x20
    8000470e:	9281                	srli	a3,a3,0x20
    80004710:	068a                	slli	a3,a3,0x2
    80004712:	06050613          	addi	a2,a0,96
    80004716:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004718:	4390                	lw	a2,0(a5)
    8000471a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000471c:	0791                	addi	a5,a5,4
    8000471e:	0711                	addi	a4,a4,4
    80004720:	fed79ce3          	bne	a5,a3,80004718 <initlog+0x68>
  brelse(buf);
    80004724:	fffff097          	auipc	ra,0xfffff
    80004728:	f84080e7          	jalr	-124(ra) # 800036a8 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000472c:	4505                	li	a0,1
    8000472e:	00000097          	auipc	ra,0x0
    80004732:	ebe080e7          	jalr	-322(ra) # 800045ec <install_trans>
  log.lh.n = 0;
    80004736:	0001c797          	auipc	a5,0x1c
    8000473a:	6a07a323          	sw	zero,1702(a5) # 80020ddc <log+0x2c>
  write_head(); // clear the log
    8000473e:	00000097          	auipc	ra,0x0
    80004742:	e34080e7          	jalr	-460(ra) # 80004572 <write_head>
}
    80004746:	70a2                	ld	ra,40(sp)
    80004748:	7402                	ld	s0,32(sp)
    8000474a:	64e2                	ld	s1,24(sp)
    8000474c:	6942                	ld	s2,16(sp)
    8000474e:	69a2                	ld	s3,8(sp)
    80004750:	6145                	addi	sp,sp,48
    80004752:	8082                	ret

0000000080004754 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004754:	1101                	addi	sp,sp,-32
    80004756:	ec06                	sd	ra,24(sp)
    80004758:	e822                	sd	s0,16(sp)
    8000475a:	e426                	sd	s1,8(sp)
    8000475c:	e04a                	sd	s2,0(sp)
    8000475e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004760:	0001c517          	auipc	a0,0x1c
    80004764:	65050513          	addi	a0,a0,1616 # 80020db0 <log>
    80004768:	ffffc097          	auipc	ra,0xffffc
    8000476c:	46e080e7          	jalr	1134(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    80004770:	0001c497          	auipc	s1,0x1c
    80004774:	64048493          	addi	s1,s1,1600 # 80020db0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004778:	4979                	li	s2,30
    8000477a:	a039                	j	80004788 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000477c:	85a6                	mv	a1,s1
    8000477e:	8526                	mv	a0,s1
    80004780:	ffffe097          	auipc	ra,0xffffe
    80004784:	926080e7          	jalr	-1754(ra) # 800020a6 <sleep>
    if(log.committing){
    80004788:	50dc                	lw	a5,36(s1)
    8000478a:	fbed                	bnez	a5,8000477c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000478c:	509c                	lw	a5,32(s1)
    8000478e:	0017871b          	addiw	a4,a5,1
    80004792:	0007069b          	sext.w	a3,a4
    80004796:	0027179b          	slliw	a5,a4,0x2
    8000479a:	9fb9                	addw	a5,a5,a4
    8000479c:	0017979b          	slliw	a5,a5,0x1
    800047a0:	54d8                	lw	a4,44(s1)
    800047a2:	9fb9                	addw	a5,a5,a4
    800047a4:	00f95963          	bge	s2,a5,800047b6 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800047a8:	85a6                	mv	a1,s1
    800047aa:	8526                	mv	a0,s1
    800047ac:	ffffe097          	auipc	ra,0xffffe
    800047b0:	8fa080e7          	jalr	-1798(ra) # 800020a6 <sleep>
    800047b4:	bfd1                	j	80004788 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800047b6:	0001c517          	auipc	a0,0x1c
    800047ba:	5fa50513          	addi	a0,a0,1530 # 80020db0 <log>
    800047be:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800047c0:	ffffc097          	auipc	ra,0xffffc
    800047c4:	4ca080e7          	jalr	1226(ra) # 80000c8a <release>
      break;
    }
  }
}
    800047c8:	60e2                	ld	ra,24(sp)
    800047ca:	6442                	ld	s0,16(sp)
    800047cc:	64a2                	ld	s1,8(sp)
    800047ce:	6902                	ld	s2,0(sp)
    800047d0:	6105                	addi	sp,sp,32
    800047d2:	8082                	ret

00000000800047d4 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800047d4:	7139                	addi	sp,sp,-64
    800047d6:	fc06                	sd	ra,56(sp)
    800047d8:	f822                	sd	s0,48(sp)
    800047da:	f426                	sd	s1,40(sp)
    800047dc:	f04a                	sd	s2,32(sp)
    800047de:	ec4e                	sd	s3,24(sp)
    800047e0:	e852                	sd	s4,16(sp)
    800047e2:	e456                	sd	s5,8(sp)
    800047e4:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800047e6:	0001c497          	auipc	s1,0x1c
    800047ea:	5ca48493          	addi	s1,s1,1482 # 80020db0 <log>
    800047ee:	8526                	mv	a0,s1
    800047f0:	ffffc097          	auipc	ra,0xffffc
    800047f4:	3e6080e7          	jalr	998(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    800047f8:	509c                	lw	a5,32(s1)
    800047fa:	37fd                	addiw	a5,a5,-1
    800047fc:	0007891b          	sext.w	s2,a5
    80004800:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004802:	50dc                	lw	a5,36(s1)
    80004804:	e7b9                	bnez	a5,80004852 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004806:	04091e63          	bnez	s2,80004862 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000480a:	0001c497          	auipc	s1,0x1c
    8000480e:	5a648493          	addi	s1,s1,1446 # 80020db0 <log>
    80004812:	4785                	li	a5,1
    80004814:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004816:	8526                	mv	a0,s1
    80004818:	ffffc097          	auipc	ra,0xffffc
    8000481c:	472080e7          	jalr	1138(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004820:	54dc                	lw	a5,44(s1)
    80004822:	06f04763          	bgtz	a5,80004890 <end_op+0xbc>
    acquire(&log.lock);
    80004826:	0001c497          	auipc	s1,0x1c
    8000482a:	58a48493          	addi	s1,s1,1418 # 80020db0 <log>
    8000482e:	8526                	mv	a0,s1
    80004830:	ffffc097          	auipc	ra,0xffffc
    80004834:	3a6080e7          	jalr	934(ra) # 80000bd6 <acquire>
    log.committing = 0;
    80004838:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000483c:	8526                	mv	a0,s1
    8000483e:	ffffe097          	auipc	ra,0xffffe
    80004842:	8cc080e7          	jalr	-1844(ra) # 8000210a <wakeup>
    release(&log.lock);
    80004846:	8526                	mv	a0,s1
    80004848:	ffffc097          	auipc	ra,0xffffc
    8000484c:	442080e7          	jalr	1090(ra) # 80000c8a <release>
}
    80004850:	a03d                	j	8000487e <end_op+0xaa>
    panic("log.committing");
    80004852:	00004517          	auipc	a0,0x4
    80004856:	e4650513          	addi	a0,a0,-442 # 80008698 <syscalls+0x228>
    8000485a:	ffffc097          	auipc	ra,0xffffc
    8000485e:	ce4080e7          	jalr	-796(ra) # 8000053e <panic>
    wakeup(&log);
    80004862:	0001c497          	auipc	s1,0x1c
    80004866:	54e48493          	addi	s1,s1,1358 # 80020db0 <log>
    8000486a:	8526                	mv	a0,s1
    8000486c:	ffffe097          	auipc	ra,0xffffe
    80004870:	89e080e7          	jalr	-1890(ra) # 8000210a <wakeup>
  release(&log.lock);
    80004874:	8526                	mv	a0,s1
    80004876:	ffffc097          	auipc	ra,0xffffc
    8000487a:	414080e7          	jalr	1044(ra) # 80000c8a <release>
}
    8000487e:	70e2                	ld	ra,56(sp)
    80004880:	7442                	ld	s0,48(sp)
    80004882:	74a2                	ld	s1,40(sp)
    80004884:	7902                	ld	s2,32(sp)
    80004886:	69e2                	ld	s3,24(sp)
    80004888:	6a42                	ld	s4,16(sp)
    8000488a:	6aa2                	ld	s5,8(sp)
    8000488c:	6121                	addi	sp,sp,64
    8000488e:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004890:	0001ca97          	auipc	s5,0x1c
    80004894:	550a8a93          	addi	s5,s5,1360 # 80020de0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004898:	0001ca17          	auipc	s4,0x1c
    8000489c:	518a0a13          	addi	s4,s4,1304 # 80020db0 <log>
    800048a0:	018a2583          	lw	a1,24(s4)
    800048a4:	012585bb          	addw	a1,a1,s2
    800048a8:	2585                	addiw	a1,a1,1
    800048aa:	028a2503          	lw	a0,40(s4)
    800048ae:	fffff097          	auipc	ra,0xfffff
    800048b2:	cca080e7          	jalr	-822(ra) # 80003578 <bread>
    800048b6:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800048b8:	000aa583          	lw	a1,0(s5)
    800048bc:	028a2503          	lw	a0,40(s4)
    800048c0:	fffff097          	auipc	ra,0xfffff
    800048c4:	cb8080e7          	jalr	-840(ra) # 80003578 <bread>
    800048c8:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800048ca:	40000613          	li	a2,1024
    800048ce:	05850593          	addi	a1,a0,88
    800048d2:	05848513          	addi	a0,s1,88
    800048d6:	ffffc097          	auipc	ra,0xffffc
    800048da:	458080e7          	jalr	1112(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    800048de:	8526                	mv	a0,s1
    800048e0:	fffff097          	auipc	ra,0xfffff
    800048e4:	d8a080e7          	jalr	-630(ra) # 8000366a <bwrite>
    brelse(from);
    800048e8:	854e                	mv	a0,s3
    800048ea:	fffff097          	auipc	ra,0xfffff
    800048ee:	dbe080e7          	jalr	-578(ra) # 800036a8 <brelse>
    brelse(to);
    800048f2:	8526                	mv	a0,s1
    800048f4:	fffff097          	auipc	ra,0xfffff
    800048f8:	db4080e7          	jalr	-588(ra) # 800036a8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800048fc:	2905                	addiw	s2,s2,1
    800048fe:	0a91                	addi	s5,s5,4
    80004900:	02ca2783          	lw	a5,44(s4)
    80004904:	f8f94ee3          	blt	s2,a5,800048a0 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004908:	00000097          	auipc	ra,0x0
    8000490c:	c6a080e7          	jalr	-918(ra) # 80004572 <write_head>
    install_trans(0); // Now install writes to home locations
    80004910:	4501                	li	a0,0
    80004912:	00000097          	auipc	ra,0x0
    80004916:	cda080e7          	jalr	-806(ra) # 800045ec <install_trans>
    log.lh.n = 0;
    8000491a:	0001c797          	auipc	a5,0x1c
    8000491e:	4c07a123          	sw	zero,1218(a5) # 80020ddc <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004922:	00000097          	auipc	ra,0x0
    80004926:	c50080e7          	jalr	-944(ra) # 80004572 <write_head>
    8000492a:	bdf5                	j	80004826 <end_op+0x52>

000000008000492c <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000492c:	1101                	addi	sp,sp,-32
    8000492e:	ec06                	sd	ra,24(sp)
    80004930:	e822                	sd	s0,16(sp)
    80004932:	e426                	sd	s1,8(sp)
    80004934:	e04a                	sd	s2,0(sp)
    80004936:	1000                	addi	s0,sp,32
    80004938:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000493a:	0001c917          	auipc	s2,0x1c
    8000493e:	47690913          	addi	s2,s2,1142 # 80020db0 <log>
    80004942:	854a                	mv	a0,s2
    80004944:	ffffc097          	auipc	ra,0xffffc
    80004948:	292080e7          	jalr	658(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000494c:	02c92603          	lw	a2,44(s2)
    80004950:	47f5                	li	a5,29
    80004952:	06c7c563          	blt	a5,a2,800049bc <log_write+0x90>
    80004956:	0001c797          	auipc	a5,0x1c
    8000495a:	4767a783          	lw	a5,1142(a5) # 80020dcc <log+0x1c>
    8000495e:	37fd                	addiw	a5,a5,-1
    80004960:	04f65e63          	bge	a2,a5,800049bc <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004964:	0001c797          	auipc	a5,0x1c
    80004968:	46c7a783          	lw	a5,1132(a5) # 80020dd0 <log+0x20>
    8000496c:	06f05063          	blez	a5,800049cc <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004970:	4781                	li	a5,0
    80004972:	06c05563          	blez	a2,800049dc <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004976:	44cc                	lw	a1,12(s1)
    80004978:	0001c717          	auipc	a4,0x1c
    8000497c:	46870713          	addi	a4,a4,1128 # 80020de0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004980:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004982:	4314                	lw	a3,0(a4)
    80004984:	04b68c63          	beq	a3,a1,800049dc <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004988:	2785                	addiw	a5,a5,1
    8000498a:	0711                	addi	a4,a4,4
    8000498c:	fef61be3          	bne	a2,a5,80004982 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004990:	0621                	addi	a2,a2,8
    80004992:	060a                	slli	a2,a2,0x2
    80004994:	0001c797          	auipc	a5,0x1c
    80004998:	41c78793          	addi	a5,a5,1052 # 80020db0 <log>
    8000499c:	963e                	add	a2,a2,a5
    8000499e:	44dc                	lw	a5,12(s1)
    800049a0:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800049a2:	8526                	mv	a0,s1
    800049a4:	fffff097          	auipc	ra,0xfffff
    800049a8:	da2080e7          	jalr	-606(ra) # 80003746 <bpin>
    log.lh.n++;
    800049ac:	0001c717          	auipc	a4,0x1c
    800049b0:	40470713          	addi	a4,a4,1028 # 80020db0 <log>
    800049b4:	575c                	lw	a5,44(a4)
    800049b6:	2785                	addiw	a5,a5,1
    800049b8:	d75c                	sw	a5,44(a4)
    800049ba:	a835                	j	800049f6 <log_write+0xca>
    panic("too big a transaction");
    800049bc:	00004517          	auipc	a0,0x4
    800049c0:	cec50513          	addi	a0,a0,-788 # 800086a8 <syscalls+0x238>
    800049c4:	ffffc097          	auipc	ra,0xffffc
    800049c8:	b7a080e7          	jalr	-1158(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800049cc:	00004517          	auipc	a0,0x4
    800049d0:	cf450513          	addi	a0,a0,-780 # 800086c0 <syscalls+0x250>
    800049d4:	ffffc097          	auipc	ra,0xffffc
    800049d8:	b6a080e7          	jalr	-1174(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800049dc:	00878713          	addi	a4,a5,8
    800049e0:	00271693          	slli	a3,a4,0x2
    800049e4:	0001c717          	auipc	a4,0x1c
    800049e8:	3cc70713          	addi	a4,a4,972 # 80020db0 <log>
    800049ec:	9736                	add	a4,a4,a3
    800049ee:	44d4                	lw	a3,12(s1)
    800049f0:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800049f2:	faf608e3          	beq	a2,a5,800049a2 <log_write+0x76>
  }
  release(&log.lock);
    800049f6:	0001c517          	auipc	a0,0x1c
    800049fa:	3ba50513          	addi	a0,a0,954 # 80020db0 <log>
    800049fe:	ffffc097          	auipc	ra,0xffffc
    80004a02:	28c080e7          	jalr	652(ra) # 80000c8a <release>
}
    80004a06:	60e2                	ld	ra,24(sp)
    80004a08:	6442                	ld	s0,16(sp)
    80004a0a:	64a2                	ld	s1,8(sp)
    80004a0c:	6902                	ld	s2,0(sp)
    80004a0e:	6105                	addi	sp,sp,32
    80004a10:	8082                	ret

0000000080004a12 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004a12:	1101                	addi	sp,sp,-32
    80004a14:	ec06                	sd	ra,24(sp)
    80004a16:	e822                	sd	s0,16(sp)
    80004a18:	e426                	sd	s1,8(sp)
    80004a1a:	e04a                	sd	s2,0(sp)
    80004a1c:	1000                	addi	s0,sp,32
    80004a1e:	84aa                	mv	s1,a0
    80004a20:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004a22:	00004597          	auipc	a1,0x4
    80004a26:	cbe58593          	addi	a1,a1,-834 # 800086e0 <syscalls+0x270>
    80004a2a:	0521                	addi	a0,a0,8
    80004a2c:	ffffc097          	auipc	ra,0xffffc
    80004a30:	11a080e7          	jalr	282(ra) # 80000b46 <initlock>
  lk->name = name;
    80004a34:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004a38:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a3c:	0204a423          	sw	zero,40(s1)
}
    80004a40:	60e2                	ld	ra,24(sp)
    80004a42:	6442                	ld	s0,16(sp)
    80004a44:	64a2                	ld	s1,8(sp)
    80004a46:	6902                	ld	s2,0(sp)
    80004a48:	6105                	addi	sp,sp,32
    80004a4a:	8082                	ret

0000000080004a4c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004a4c:	1101                	addi	sp,sp,-32
    80004a4e:	ec06                	sd	ra,24(sp)
    80004a50:	e822                	sd	s0,16(sp)
    80004a52:	e426                	sd	s1,8(sp)
    80004a54:	e04a                	sd	s2,0(sp)
    80004a56:	1000                	addi	s0,sp,32
    80004a58:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a5a:	00850913          	addi	s2,a0,8
    80004a5e:	854a                	mv	a0,s2
    80004a60:	ffffc097          	auipc	ra,0xffffc
    80004a64:	176080e7          	jalr	374(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004a68:	409c                	lw	a5,0(s1)
    80004a6a:	cb89                	beqz	a5,80004a7c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004a6c:	85ca                	mv	a1,s2
    80004a6e:	8526                	mv	a0,s1
    80004a70:	ffffd097          	auipc	ra,0xffffd
    80004a74:	636080e7          	jalr	1590(ra) # 800020a6 <sleep>
  while (lk->locked) {
    80004a78:	409c                	lw	a5,0(s1)
    80004a7a:	fbed                	bnez	a5,80004a6c <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004a7c:	4785                	li	a5,1
    80004a7e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004a80:	ffffd097          	auipc	ra,0xffffd
    80004a84:	f5c080e7          	jalr	-164(ra) # 800019dc <myproc>
    80004a88:	591c                	lw	a5,48(a0)
    80004a8a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004a8c:	854a                	mv	a0,s2
    80004a8e:	ffffc097          	auipc	ra,0xffffc
    80004a92:	1fc080e7          	jalr	508(ra) # 80000c8a <release>
}
    80004a96:	60e2                	ld	ra,24(sp)
    80004a98:	6442                	ld	s0,16(sp)
    80004a9a:	64a2                	ld	s1,8(sp)
    80004a9c:	6902                	ld	s2,0(sp)
    80004a9e:	6105                	addi	sp,sp,32
    80004aa0:	8082                	ret

0000000080004aa2 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004aa2:	1101                	addi	sp,sp,-32
    80004aa4:	ec06                	sd	ra,24(sp)
    80004aa6:	e822                	sd	s0,16(sp)
    80004aa8:	e426                	sd	s1,8(sp)
    80004aaa:	e04a                	sd	s2,0(sp)
    80004aac:	1000                	addi	s0,sp,32
    80004aae:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004ab0:	00850913          	addi	s2,a0,8
    80004ab4:	854a                	mv	a0,s2
    80004ab6:	ffffc097          	auipc	ra,0xffffc
    80004aba:	120080e7          	jalr	288(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004abe:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004ac2:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004ac6:	8526                	mv	a0,s1
    80004ac8:	ffffd097          	auipc	ra,0xffffd
    80004acc:	642080e7          	jalr	1602(ra) # 8000210a <wakeup>
  release(&lk->lk);
    80004ad0:	854a                	mv	a0,s2
    80004ad2:	ffffc097          	auipc	ra,0xffffc
    80004ad6:	1b8080e7          	jalr	440(ra) # 80000c8a <release>
}
    80004ada:	60e2                	ld	ra,24(sp)
    80004adc:	6442                	ld	s0,16(sp)
    80004ade:	64a2                	ld	s1,8(sp)
    80004ae0:	6902                	ld	s2,0(sp)
    80004ae2:	6105                	addi	sp,sp,32
    80004ae4:	8082                	ret

0000000080004ae6 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004ae6:	7179                	addi	sp,sp,-48
    80004ae8:	f406                	sd	ra,40(sp)
    80004aea:	f022                	sd	s0,32(sp)
    80004aec:	ec26                	sd	s1,24(sp)
    80004aee:	e84a                	sd	s2,16(sp)
    80004af0:	e44e                	sd	s3,8(sp)
    80004af2:	1800                	addi	s0,sp,48
    80004af4:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004af6:	00850913          	addi	s2,a0,8
    80004afa:	854a                	mv	a0,s2
    80004afc:	ffffc097          	auipc	ra,0xffffc
    80004b00:	0da080e7          	jalr	218(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b04:	409c                	lw	a5,0(s1)
    80004b06:	ef99                	bnez	a5,80004b24 <holdingsleep+0x3e>
    80004b08:	4481                	li	s1,0
  release(&lk->lk);
    80004b0a:	854a                	mv	a0,s2
    80004b0c:	ffffc097          	auipc	ra,0xffffc
    80004b10:	17e080e7          	jalr	382(ra) # 80000c8a <release>
  return r;
}
    80004b14:	8526                	mv	a0,s1
    80004b16:	70a2                	ld	ra,40(sp)
    80004b18:	7402                	ld	s0,32(sp)
    80004b1a:	64e2                	ld	s1,24(sp)
    80004b1c:	6942                	ld	s2,16(sp)
    80004b1e:	69a2                	ld	s3,8(sp)
    80004b20:	6145                	addi	sp,sp,48
    80004b22:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b24:	0284a983          	lw	s3,40(s1)
    80004b28:	ffffd097          	auipc	ra,0xffffd
    80004b2c:	eb4080e7          	jalr	-332(ra) # 800019dc <myproc>
    80004b30:	5904                	lw	s1,48(a0)
    80004b32:	413484b3          	sub	s1,s1,s3
    80004b36:	0014b493          	seqz	s1,s1
    80004b3a:	bfc1                	j	80004b0a <holdingsleep+0x24>

0000000080004b3c <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004b3c:	1141                	addi	sp,sp,-16
    80004b3e:	e406                	sd	ra,8(sp)
    80004b40:	e022                	sd	s0,0(sp)
    80004b42:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004b44:	00004597          	auipc	a1,0x4
    80004b48:	bac58593          	addi	a1,a1,-1108 # 800086f0 <syscalls+0x280>
    80004b4c:	0001c517          	auipc	a0,0x1c
    80004b50:	3ac50513          	addi	a0,a0,940 # 80020ef8 <ftable>
    80004b54:	ffffc097          	auipc	ra,0xffffc
    80004b58:	ff2080e7          	jalr	-14(ra) # 80000b46 <initlock>
}
    80004b5c:	60a2                	ld	ra,8(sp)
    80004b5e:	6402                	ld	s0,0(sp)
    80004b60:	0141                	addi	sp,sp,16
    80004b62:	8082                	ret

0000000080004b64 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004b64:	1101                	addi	sp,sp,-32
    80004b66:	ec06                	sd	ra,24(sp)
    80004b68:	e822                	sd	s0,16(sp)
    80004b6a:	e426                	sd	s1,8(sp)
    80004b6c:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004b6e:	0001c517          	auipc	a0,0x1c
    80004b72:	38a50513          	addi	a0,a0,906 # 80020ef8 <ftable>
    80004b76:	ffffc097          	auipc	ra,0xffffc
    80004b7a:	060080e7          	jalr	96(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b7e:	0001c497          	auipc	s1,0x1c
    80004b82:	39248493          	addi	s1,s1,914 # 80020f10 <ftable+0x18>
    80004b86:	0001d717          	auipc	a4,0x1d
    80004b8a:	32a70713          	addi	a4,a4,810 # 80021eb0 <disk>
    if(f->ref == 0){
    80004b8e:	40dc                	lw	a5,4(s1)
    80004b90:	cf99                	beqz	a5,80004bae <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b92:	02848493          	addi	s1,s1,40
    80004b96:	fee49ce3          	bne	s1,a4,80004b8e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004b9a:	0001c517          	auipc	a0,0x1c
    80004b9e:	35e50513          	addi	a0,a0,862 # 80020ef8 <ftable>
    80004ba2:	ffffc097          	auipc	ra,0xffffc
    80004ba6:	0e8080e7          	jalr	232(ra) # 80000c8a <release>
  return 0;
    80004baa:	4481                	li	s1,0
    80004bac:	a819                	j	80004bc2 <filealloc+0x5e>
      f->ref = 1;
    80004bae:	4785                	li	a5,1
    80004bb0:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004bb2:	0001c517          	auipc	a0,0x1c
    80004bb6:	34650513          	addi	a0,a0,838 # 80020ef8 <ftable>
    80004bba:	ffffc097          	auipc	ra,0xffffc
    80004bbe:	0d0080e7          	jalr	208(ra) # 80000c8a <release>
}
    80004bc2:	8526                	mv	a0,s1
    80004bc4:	60e2                	ld	ra,24(sp)
    80004bc6:	6442                	ld	s0,16(sp)
    80004bc8:	64a2                	ld	s1,8(sp)
    80004bca:	6105                	addi	sp,sp,32
    80004bcc:	8082                	ret

0000000080004bce <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004bce:	1101                	addi	sp,sp,-32
    80004bd0:	ec06                	sd	ra,24(sp)
    80004bd2:	e822                	sd	s0,16(sp)
    80004bd4:	e426                	sd	s1,8(sp)
    80004bd6:	1000                	addi	s0,sp,32
    80004bd8:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004bda:	0001c517          	auipc	a0,0x1c
    80004bde:	31e50513          	addi	a0,a0,798 # 80020ef8 <ftable>
    80004be2:	ffffc097          	auipc	ra,0xffffc
    80004be6:	ff4080e7          	jalr	-12(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004bea:	40dc                	lw	a5,4(s1)
    80004bec:	02f05263          	blez	a5,80004c10 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004bf0:	2785                	addiw	a5,a5,1
    80004bf2:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004bf4:	0001c517          	auipc	a0,0x1c
    80004bf8:	30450513          	addi	a0,a0,772 # 80020ef8 <ftable>
    80004bfc:	ffffc097          	auipc	ra,0xffffc
    80004c00:	08e080e7          	jalr	142(ra) # 80000c8a <release>
  return f;
}
    80004c04:	8526                	mv	a0,s1
    80004c06:	60e2                	ld	ra,24(sp)
    80004c08:	6442                	ld	s0,16(sp)
    80004c0a:	64a2                	ld	s1,8(sp)
    80004c0c:	6105                	addi	sp,sp,32
    80004c0e:	8082                	ret
    panic("filedup");
    80004c10:	00004517          	auipc	a0,0x4
    80004c14:	ae850513          	addi	a0,a0,-1304 # 800086f8 <syscalls+0x288>
    80004c18:	ffffc097          	auipc	ra,0xffffc
    80004c1c:	926080e7          	jalr	-1754(ra) # 8000053e <panic>

0000000080004c20 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004c20:	7139                	addi	sp,sp,-64
    80004c22:	fc06                	sd	ra,56(sp)
    80004c24:	f822                	sd	s0,48(sp)
    80004c26:	f426                	sd	s1,40(sp)
    80004c28:	f04a                	sd	s2,32(sp)
    80004c2a:	ec4e                	sd	s3,24(sp)
    80004c2c:	e852                	sd	s4,16(sp)
    80004c2e:	e456                	sd	s5,8(sp)
    80004c30:	0080                	addi	s0,sp,64
    80004c32:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004c34:	0001c517          	auipc	a0,0x1c
    80004c38:	2c450513          	addi	a0,a0,708 # 80020ef8 <ftable>
    80004c3c:	ffffc097          	auipc	ra,0xffffc
    80004c40:	f9a080e7          	jalr	-102(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004c44:	40dc                	lw	a5,4(s1)
    80004c46:	06f05163          	blez	a5,80004ca8 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004c4a:	37fd                	addiw	a5,a5,-1
    80004c4c:	0007871b          	sext.w	a4,a5
    80004c50:	c0dc                	sw	a5,4(s1)
    80004c52:	06e04363          	bgtz	a4,80004cb8 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004c56:	0004a903          	lw	s2,0(s1)
    80004c5a:	0094ca83          	lbu	s5,9(s1)
    80004c5e:	0104ba03          	ld	s4,16(s1)
    80004c62:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004c66:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004c6a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004c6e:	0001c517          	auipc	a0,0x1c
    80004c72:	28a50513          	addi	a0,a0,650 # 80020ef8 <ftable>
    80004c76:	ffffc097          	auipc	ra,0xffffc
    80004c7a:	014080e7          	jalr	20(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004c7e:	4785                	li	a5,1
    80004c80:	04f90d63          	beq	s2,a5,80004cda <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004c84:	3979                	addiw	s2,s2,-2
    80004c86:	4785                	li	a5,1
    80004c88:	0527e063          	bltu	a5,s2,80004cc8 <fileclose+0xa8>
    begin_op();
    80004c8c:	00000097          	auipc	ra,0x0
    80004c90:	ac8080e7          	jalr	-1336(ra) # 80004754 <begin_op>
    iput(ff.ip);
    80004c94:	854e                	mv	a0,s3
    80004c96:	fffff097          	auipc	ra,0xfffff
    80004c9a:	2b6080e7          	jalr	694(ra) # 80003f4c <iput>
    end_op();
    80004c9e:	00000097          	auipc	ra,0x0
    80004ca2:	b36080e7          	jalr	-1226(ra) # 800047d4 <end_op>
    80004ca6:	a00d                	j	80004cc8 <fileclose+0xa8>
    panic("fileclose");
    80004ca8:	00004517          	auipc	a0,0x4
    80004cac:	a5850513          	addi	a0,a0,-1448 # 80008700 <syscalls+0x290>
    80004cb0:	ffffc097          	auipc	ra,0xffffc
    80004cb4:	88e080e7          	jalr	-1906(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004cb8:	0001c517          	auipc	a0,0x1c
    80004cbc:	24050513          	addi	a0,a0,576 # 80020ef8 <ftable>
    80004cc0:	ffffc097          	auipc	ra,0xffffc
    80004cc4:	fca080e7          	jalr	-54(ra) # 80000c8a <release>
  }
}
    80004cc8:	70e2                	ld	ra,56(sp)
    80004cca:	7442                	ld	s0,48(sp)
    80004ccc:	74a2                	ld	s1,40(sp)
    80004cce:	7902                	ld	s2,32(sp)
    80004cd0:	69e2                	ld	s3,24(sp)
    80004cd2:	6a42                	ld	s4,16(sp)
    80004cd4:	6aa2                	ld	s5,8(sp)
    80004cd6:	6121                	addi	sp,sp,64
    80004cd8:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004cda:	85d6                	mv	a1,s5
    80004cdc:	8552                	mv	a0,s4
    80004cde:	00000097          	auipc	ra,0x0
    80004ce2:	34c080e7          	jalr	844(ra) # 8000502a <pipeclose>
    80004ce6:	b7cd                	j	80004cc8 <fileclose+0xa8>

0000000080004ce8 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004ce8:	715d                	addi	sp,sp,-80
    80004cea:	e486                	sd	ra,72(sp)
    80004cec:	e0a2                	sd	s0,64(sp)
    80004cee:	fc26                	sd	s1,56(sp)
    80004cf0:	f84a                	sd	s2,48(sp)
    80004cf2:	f44e                	sd	s3,40(sp)
    80004cf4:	0880                	addi	s0,sp,80
    80004cf6:	84aa                	mv	s1,a0
    80004cf8:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004cfa:	ffffd097          	auipc	ra,0xffffd
    80004cfe:	ce2080e7          	jalr	-798(ra) # 800019dc <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004d02:	409c                	lw	a5,0(s1)
    80004d04:	37f9                	addiw	a5,a5,-2
    80004d06:	4705                	li	a4,1
    80004d08:	04f76763          	bltu	a4,a5,80004d56 <filestat+0x6e>
    80004d0c:	892a                	mv	s2,a0
    ilock(f->ip);
    80004d0e:	6c88                	ld	a0,24(s1)
    80004d10:	fffff097          	auipc	ra,0xfffff
    80004d14:	082080e7          	jalr	130(ra) # 80003d92 <ilock>
    stati(f->ip, &st);
    80004d18:	fb840593          	addi	a1,s0,-72
    80004d1c:	6c88                	ld	a0,24(s1)
    80004d1e:	fffff097          	auipc	ra,0xfffff
    80004d22:	2fe080e7          	jalr	766(ra) # 8000401c <stati>
    iunlock(f->ip);
    80004d26:	6c88                	ld	a0,24(s1)
    80004d28:	fffff097          	auipc	ra,0xfffff
    80004d2c:	12c080e7          	jalr	300(ra) # 80003e54 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004d30:	46e1                	li	a3,24
    80004d32:	fb840613          	addi	a2,s0,-72
    80004d36:	85ce                	mv	a1,s3
    80004d38:	05093503          	ld	a0,80(s2)
    80004d3c:	ffffd097          	auipc	ra,0xffffd
    80004d40:	944080e7          	jalr	-1724(ra) # 80001680 <copyout>
    80004d44:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004d48:	60a6                	ld	ra,72(sp)
    80004d4a:	6406                	ld	s0,64(sp)
    80004d4c:	74e2                	ld	s1,56(sp)
    80004d4e:	7942                	ld	s2,48(sp)
    80004d50:	79a2                	ld	s3,40(sp)
    80004d52:	6161                	addi	sp,sp,80
    80004d54:	8082                	ret
  return -1;
    80004d56:	557d                	li	a0,-1
    80004d58:	bfc5                	j	80004d48 <filestat+0x60>

0000000080004d5a <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004d5a:	7179                	addi	sp,sp,-48
    80004d5c:	f406                	sd	ra,40(sp)
    80004d5e:	f022                	sd	s0,32(sp)
    80004d60:	ec26                	sd	s1,24(sp)
    80004d62:	e84a                	sd	s2,16(sp)
    80004d64:	e44e                	sd	s3,8(sp)
    80004d66:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004d68:	00854783          	lbu	a5,8(a0)
    80004d6c:	c3d5                	beqz	a5,80004e10 <fileread+0xb6>
    80004d6e:	84aa                	mv	s1,a0
    80004d70:	89ae                	mv	s3,a1
    80004d72:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d74:	411c                	lw	a5,0(a0)
    80004d76:	4705                	li	a4,1
    80004d78:	04e78963          	beq	a5,a4,80004dca <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d7c:	470d                	li	a4,3
    80004d7e:	04e78d63          	beq	a5,a4,80004dd8 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d82:	4709                	li	a4,2
    80004d84:	06e79e63          	bne	a5,a4,80004e00 <fileread+0xa6>
    ilock(f->ip);
    80004d88:	6d08                	ld	a0,24(a0)
    80004d8a:	fffff097          	auipc	ra,0xfffff
    80004d8e:	008080e7          	jalr	8(ra) # 80003d92 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004d92:	874a                	mv	a4,s2
    80004d94:	5094                	lw	a3,32(s1)
    80004d96:	864e                	mv	a2,s3
    80004d98:	4585                	li	a1,1
    80004d9a:	6c88                	ld	a0,24(s1)
    80004d9c:	fffff097          	auipc	ra,0xfffff
    80004da0:	2aa080e7          	jalr	682(ra) # 80004046 <readi>
    80004da4:	892a                	mv	s2,a0
    80004da6:	00a05563          	blez	a0,80004db0 <fileread+0x56>
      f->off += r;
    80004daa:	509c                	lw	a5,32(s1)
    80004dac:	9fa9                	addw	a5,a5,a0
    80004dae:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004db0:	6c88                	ld	a0,24(s1)
    80004db2:	fffff097          	auipc	ra,0xfffff
    80004db6:	0a2080e7          	jalr	162(ra) # 80003e54 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004dba:	854a                	mv	a0,s2
    80004dbc:	70a2                	ld	ra,40(sp)
    80004dbe:	7402                	ld	s0,32(sp)
    80004dc0:	64e2                	ld	s1,24(sp)
    80004dc2:	6942                	ld	s2,16(sp)
    80004dc4:	69a2                	ld	s3,8(sp)
    80004dc6:	6145                	addi	sp,sp,48
    80004dc8:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004dca:	6908                	ld	a0,16(a0)
    80004dcc:	00000097          	auipc	ra,0x0
    80004dd0:	3c6080e7          	jalr	966(ra) # 80005192 <piperead>
    80004dd4:	892a                	mv	s2,a0
    80004dd6:	b7d5                	j	80004dba <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004dd8:	02451783          	lh	a5,36(a0)
    80004ddc:	03079693          	slli	a3,a5,0x30
    80004de0:	92c1                	srli	a3,a3,0x30
    80004de2:	4725                	li	a4,9
    80004de4:	02d76863          	bltu	a4,a3,80004e14 <fileread+0xba>
    80004de8:	0792                	slli	a5,a5,0x4
    80004dea:	0001c717          	auipc	a4,0x1c
    80004dee:	06e70713          	addi	a4,a4,110 # 80020e58 <devsw>
    80004df2:	97ba                	add	a5,a5,a4
    80004df4:	639c                	ld	a5,0(a5)
    80004df6:	c38d                	beqz	a5,80004e18 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004df8:	4505                	li	a0,1
    80004dfa:	9782                	jalr	a5
    80004dfc:	892a                	mv	s2,a0
    80004dfe:	bf75                	j	80004dba <fileread+0x60>
    panic("fileread");
    80004e00:	00004517          	auipc	a0,0x4
    80004e04:	91050513          	addi	a0,a0,-1776 # 80008710 <syscalls+0x2a0>
    80004e08:	ffffb097          	auipc	ra,0xffffb
    80004e0c:	736080e7          	jalr	1846(ra) # 8000053e <panic>
    return -1;
    80004e10:	597d                	li	s2,-1
    80004e12:	b765                	j	80004dba <fileread+0x60>
      return -1;
    80004e14:	597d                	li	s2,-1
    80004e16:	b755                	j	80004dba <fileread+0x60>
    80004e18:	597d                	li	s2,-1
    80004e1a:	b745                	j	80004dba <fileread+0x60>

0000000080004e1c <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004e1c:	715d                	addi	sp,sp,-80
    80004e1e:	e486                	sd	ra,72(sp)
    80004e20:	e0a2                	sd	s0,64(sp)
    80004e22:	fc26                	sd	s1,56(sp)
    80004e24:	f84a                	sd	s2,48(sp)
    80004e26:	f44e                	sd	s3,40(sp)
    80004e28:	f052                	sd	s4,32(sp)
    80004e2a:	ec56                	sd	s5,24(sp)
    80004e2c:	e85a                	sd	s6,16(sp)
    80004e2e:	e45e                	sd	s7,8(sp)
    80004e30:	e062                	sd	s8,0(sp)
    80004e32:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004e34:	00954783          	lbu	a5,9(a0)
    80004e38:	10078663          	beqz	a5,80004f44 <filewrite+0x128>
    80004e3c:	892a                	mv	s2,a0
    80004e3e:	8aae                	mv	s5,a1
    80004e40:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004e42:	411c                	lw	a5,0(a0)
    80004e44:	4705                	li	a4,1
    80004e46:	02e78263          	beq	a5,a4,80004e6a <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004e4a:	470d                	li	a4,3
    80004e4c:	02e78663          	beq	a5,a4,80004e78 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004e50:	4709                	li	a4,2
    80004e52:	0ee79163          	bne	a5,a4,80004f34 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004e56:	0ac05d63          	blez	a2,80004f10 <filewrite+0xf4>
    int i = 0;
    80004e5a:	4981                	li	s3,0
    80004e5c:	6b05                	lui	s6,0x1
    80004e5e:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004e62:	6b85                	lui	s7,0x1
    80004e64:	c00b8b9b          	addiw	s7,s7,-1024
    80004e68:	a861                	j	80004f00 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004e6a:	6908                	ld	a0,16(a0)
    80004e6c:	00000097          	auipc	ra,0x0
    80004e70:	22e080e7          	jalr	558(ra) # 8000509a <pipewrite>
    80004e74:	8a2a                	mv	s4,a0
    80004e76:	a045                	j	80004f16 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004e78:	02451783          	lh	a5,36(a0)
    80004e7c:	03079693          	slli	a3,a5,0x30
    80004e80:	92c1                	srli	a3,a3,0x30
    80004e82:	4725                	li	a4,9
    80004e84:	0cd76263          	bltu	a4,a3,80004f48 <filewrite+0x12c>
    80004e88:	0792                	slli	a5,a5,0x4
    80004e8a:	0001c717          	auipc	a4,0x1c
    80004e8e:	fce70713          	addi	a4,a4,-50 # 80020e58 <devsw>
    80004e92:	97ba                	add	a5,a5,a4
    80004e94:	679c                	ld	a5,8(a5)
    80004e96:	cbdd                	beqz	a5,80004f4c <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004e98:	4505                	li	a0,1
    80004e9a:	9782                	jalr	a5
    80004e9c:	8a2a                	mv	s4,a0
    80004e9e:	a8a5                	j	80004f16 <filewrite+0xfa>
    80004ea0:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004ea4:	00000097          	auipc	ra,0x0
    80004ea8:	8b0080e7          	jalr	-1872(ra) # 80004754 <begin_op>
      ilock(f->ip);
    80004eac:	01893503          	ld	a0,24(s2)
    80004eb0:	fffff097          	auipc	ra,0xfffff
    80004eb4:	ee2080e7          	jalr	-286(ra) # 80003d92 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004eb8:	8762                	mv	a4,s8
    80004eba:	02092683          	lw	a3,32(s2)
    80004ebe:	01598633          	add	a2,s3,s5
    80004ec2:	4585                	li	a1,1
    80004ec4:	01893503          	ld	a0,24(s2)
    80004ec8:	fffff097          	auipc	ra,0xfffff
    80004ecc:	276080e7          	jalr	630(ra) # 8000413e <writei>
    80004ed0:	84aa                	mv	s1,a0
    80004ed2:	00a05763          	blez	a0,80004ee0 <filewrite+0xc4>
        f->off += r;
    80004ed6:	02092783          	lw	a5,32(s2)
    80004eda:	9fa9                	addw	a5,a5,a0
    80004edc:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004ee0:	01893503          	ld	a0,24(s2)
    80004ee4:	fffff097          	auipc	ra,0xfffff
    80004ee8:	f70080e7          	jalr	-144(ra) # 80003e54 <iunlock>
      end_op();
    80004eec:	00000097          	auipc	ra,0x0
    80004ef0:	8e8080e7          	jalr	-1816(ra) # 800047d4 <end_op>

      if(r != n1){
    80004ef4:	009c1f63          	bne	s8,s1,80004f12 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004ef8:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004efc:	0149db63          	bge	s3,s4,80004f12 <filewrite+0xf6>
      int n1 = n - i;
    80004f00:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004f04:	84be                	mv	s1,a5
    80004f06:	2781                	sext.w	a5,a5
    80004f08:	f8fb5ce3          	bge	s6,a5,80004ea0 <filewrite+0x84>
    80004f0c:	84de                	mv	s1,s7
    80004f0e:	bf49                	j	80004ea0 <filewrite+0x84>
    int i = 0;
    80004f10:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004f12:	013a1f63          	bne	s4,s3,80004f30 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004f16:	8552                	mv	a0,s4
    80004f18:	60a6                	ld	ra,72(sp)
    80004f1a:	6406                	ld	s0,64(sp)
    80004f1c:	74e2                	ld	s1,56(sp)
    80004f1e:	7942                	ld	s2,48(sp)
    80004f20:	79a2                	ld	s3,40(sp)
    80004f22:	7a02                	ld	s4,32(sp)
    80004f24:	6ae2                	ld	s5,24(sp)
    80004f26:	6b42                	ld	s6,16(sp)
    80004f28:	6ba2                	ld	s7,8(sp)
    80004f2a:	6c02                	ld	s8,0(sp)
    80004f2c:	6161                	addi	sp,sp,80
    80004f2e:	8082                	ret
    ret = (i == n ? n : -1);
    80004f30:	5a7d                	li	s4,-1
    80004f32:	b7d5                	j	80004f16 <filewrite+0xfa>
    panic("filewrite");
    80004f34:	00003517          	auipc	a0,0x3
    80004f38:	7ec50513          	addi	a0,a0,2028 # 80008720 <syscalls+0x2b0>
    80004f3c:	ffffb097          	auipc	ra,0xffffb
    80004f40:	602080e7          	jalr	1538(ra) # 8000053e <panic>
    return -1;
    80004f44:	5a7d                	li	s4,-1
    80004f46:	bfc1                	j	80004f16 <filewrite+0xfa>
      return -1;
    80004f48:	5a7d                	li	s4,-1
    80004f4a:	b7f1                	j	80004f16 <filewrite+0xfa>
    80004f4c:	5a7d                	li	s4,-1
    80004f4e:	b7e1                	j	80004f16 <filewrite+0xfa>

0000000080004f50 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004f50:	7179                	addi	sp,sp,-48
    80004f52:	f406                	sd	ra,40(sp)
    80004f54:	f022                	sd	s0,32(sp)
    80004f56:	ec26                	sd	s1,24(sp)
    80004f58:	e84a                	sd	s2,16(sp)
    80004f5a:	e44e                	sd	s3,8(sp)
    80004f5c:	e052                	sd	s4,0(sp)
    80004f5e:	1800                	addi	s0,sp,48
    80004f60:	84aa                	mv	s1,a0
    80004f62:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004f64:	0005b023          	sd	zero,0(a1)
    80004f68:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004f6c:	00000097          	auipc	ra,0x0
    80004f70:	bf8080e7          	jalr	-1032(ra) # 80004b64 <filealloc>
    80004f74:	e088                	sd	a0,0(s1)
    80004f76:	c551                	beqz	a0,80005002 <pipealloc+0xb2>
    80004f78:	00000097          	auipc	ra,0x0
    80004f7c:	bec080e7          	jalr	-1044(ra) # 80004b64 <filealloc>
    80004f80:	00aa3023          	sd	a0,0(s4)
    80004f84:	c92d                	beqz	a0,80004ff6 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004f86:	ffffc097          	auipc	ra,0xffffc
    80004f8a:	b60080e7          	jalr	-1184(ra) # 80000ae6 <kalloc>
    80004f8e:	892a                	mv	s2,a0
    80004f90:	c125                	beqz	a0,80004ff0 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004f92:	4985                	li	s3,1
    80004f94:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004f98:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004f9c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004fa0:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004fa4:	00003597          	auipc	a1,0x3
    80004fa8:	78c58593          	addi	a1,a1,1932 # 80008730 <syscalls+0x2c0>
    80004fac:	ffffc097          	auipc	ra,0xffffc
    80004fb0:	b9a080e7          	jalr	-1126(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004fb4:	609c                	ld	a5,0(s1)
    80004fb6:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004fba:	609c                	ld	a5,0(s1)
    80004fbc:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004fc0:	609c                	ld	a5,0(s1)
    80004fc2:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004fc6:	609c                	ld	a5,0(s1)
    80004fc8:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004fcc:	000a3783          	ld	a5,0(s4)
    80004fd0:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004fd4:	000a3783          	ld	a5,0(s4)
    80004fd8:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004fdc:	000a3783          	ld	a5,0(s4)
    80004fe0:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004fe4:	000a3783          	ld	a5,0(s4)
    80004fe8:	0127b823          	sd	s2,16(a5)
  return 0;
    80004fec:	4501                	li	a0,0
    80004fee:	a025                	j	80005016 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004ff0:	6088                	ld	a0,0(s1)
    80004ff2:	e501                	bnez	a0,80004ffa <pipealloc+0xaa>
    80004ff4:	a039                	j	80005002 <pipealloc+0xb2>
    80004ff6:	6088                	ld	a0,0(s1)
    80004ff8:	c51d                	beqz	a0,80005026 <pipealloc+0xd6>
    fileclose(*f0);
    80004ffa:	00000097          	auipc	ra,0x0
    80004ffe:	c26080e7          	jalr	-986(ra) # 80004c20 <fileclose>
  if(*f1)
    80005002:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005006:	557d                	li	a0,-1
  if(*f1)
    80005008:	c799                	beqz	a5,80005016 <pipealloc+0xc6>
    fileclose(*f1);
    8000500a:	853e                	mv	a0,a5
    8000500c:	00000097          	auipc	ra,0x0
    80005010:	c14080e7          	jalr	-1004(ra) # 80004c20 <fileclose>
  return -1;
    80005014:	557d                	li	a0,-1
}
    80005016:	70a2                	ld	ra,40(sp)
    80005018:	7402                	ld	s0,32(sp)
    8000501a:	64e2                	ld	s1,24(sp)
    8000501c:	6942                	ld	s2,16(sp)
    8000501e:	69a2                	ld	s3,8(sp)
    80005020:	6a02                	ld	s4,0(sp)
    80005022:	6145                	addi	sp,sp,48
    80005024:	8082                	ret
  return -1;
    80005026:	557d                	li	a0,-1
    80005028:	b7fd                	j	80005016 <pipealloc+0xc6>

000000008000502a <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000502a:	1101                	addi	sp,sp,-32
    8000502c:	ec06                	sd	ra,24(sp)
    8000502e:	e822                	sd	s0,16(sp)
    80005030:	e426                	sd	s1,8(sp)
    80005032:	e04a                	sd	s2,0(sp)
    80005034:	1000                	addi	s0,sp,32
    80005036:	84aa                	mv	s1,a0
    80005038:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000503a:	ffffc097          	auipc	ra,0xffffc
    8000503e:	b9c080e7          	jalr	-1124(ra) # 80000bd6 <acquire>
  if(writable){
    80005042:	02090d63          	beqz	s2,8000507c <pipeclose+0x52>
    pi->writeopen = 0;
    80005046:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000504a:	21848513          	addi	a0,s1,536
    8000504e:	ffffd097          	auipc	ra,0xffffd
    80005052:	0bc080e7          	jalr	188(ra) # 8000210a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005056:	2204b783          	ld	a5,544(s1)
    8000505a:	eb95                	bnez	a5,8000508e <pipeclose+0x64>
    release(&pi->lock);
    8000505c:	8526                	mv	a0,s1
    8000505e:	ffffc097          	auipc	ra,0xffffc
    80005062:	c2c080e7          	jalr	-980(ra) # 80000c8a <release>
    kfree((char*)pi);
    80005066:	8526                	mv	a0,s1
    80005068:	ffffc097          	auipc	ra,0xffffc
    8000506c:	982080e7          	jalr	-1662(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80005070:	60e2                	ld	ra,24(sp)
    80005072:	6442                	ld	s0,16(sp)
    80005074:	64a2                	ld	s1,8(sp)
    80005076:	6902                	ld	s2,0(sp)
    80005078:	6105                	addi	sp,sp,32
    8000507a:	8082                	ret
    pi->readopen = 0;
    8000507c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005080:	21c48513          	addi	a0,s1,540
    80005084:	ffffd097          	auipc	ra,0xffffd
    80005088:	086080e7          	jalr	134(ra) # 8000210a <wakeup>
    8000508c:	b7e9                	j	80005056 <pipeclose+0x2c>
    release(&pi->lock);
    8000508e:	8526                	mv	a0,s1
    80005090:	ffffc097          	auipc	ra,0xffffc
    80005094:	bfa080e7          	jalr	-1030(ra) # 80000c8a <release>
}
    80005098:	bfe1                	j	80005070 <pipeclose+0x46>

000000008000509a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000509a:	711d                	addi	sp,sp,-96
    8000509c:	ec86                	sd	ra,88(sp)
    8000509e:	e8a2                	sd	s0,80(sp)
    800050a0:	e4a6                	sd	s1,72(sp)
    800050a2:	e0ca                	sd	s2,64(sp)
    800050a4:	fc4e                	sd	s3,56(sp)
    800050a6:	f852                	sd	s4,48(sp)
    800050a8:	f456                	sd	s5,40(sp)
    800050aa:	f05a                	sd	s6,32(sp)
    800050ac:	ec5e                	sd	s7,24(sp)
    800050ae:	e862                	sd	s8,16(sp)
    800050b0:	1080                	addi	s0,sp,96
    800050b2:	84aa                	mv	s1,a0
    800050b4:	8aae                	mv	s5,a1
    800050b6:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800050b8:	ffffd097          	auipc	ra,0xffffd
    800050bc:	924080e7          	jalr	-1756(ra) # 800019dc <myproc>
    800050c0:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800050c2:	8526                	mv	a0,s1
    800050c4:	ffffc097          	auipc	ra,0xffffc
    800050c8:	b12080e7          	jalr	-1262(ra) # 80000bd6 <acquire>
  while(i < n){
    800050cc:	0b405663          	blez	s4,80005178 <pipewrite+0xde>
  int i = 0;
    800050d0:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800050d2:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800050d4:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800050d8:	21c48b93          	addi	s7,s1,540
    800050dc:	a089                	j	8000511e <pipewrite+0x84>
      release(&pi->lock);
    800050de:	8526                	mv	a0,s1
    800050e0:	ffffc097          	auipc	ra,0xffffc
    800050e4:	baa080e7          	jalr	-1110(ra) # 80000c8a <release>
      return -1;
    800050e8:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800050ea:	854a                	mv	a0,s2
    800050ec:	60e6                	ld	ra,88(sp)
    800050ee:	6446                	ld	s0,80(sp)
    800050f0:	64a6                	ld	s1,72(sp)
    800050f2:	6906                	ld	s2,64(sp)
    800050f4:	79e2                	ld	s3,56(sp)
    800050f6:	7a42                	ld	s4,48(sp)
    800050f8:	7aa2                	ld	s5,40(sp)
    800050fa:	7b02                	ld	s6,32(sp)
    800050fc:	6be2                	ld	s7,24(sp)
    800050fe:	6c42                	ld	s8,16(sp)
    80005100:	6125                	addi	sp,sp,96
    80005102:	8082                	ret
      wakeup(&pi->nread);
    80005104:	8562                	mv	a0,s8
    80005106:	ffffd097          	auipc	ra,0xffffd
    8000510a:	004080e7          	jalr	4(ra) # 8000210a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000510e:	85a6                	mv	a1,s1
    80005110:	855e                	mv	a0,s7
    80005112:	ffffd097          	auipc	ra,0xffffd
    80005116:	f94080e7          	jalr	-108(ra) # 800020a6 <sleep>
  while(i < n){
    8000511a:	07495063          	bge	s2,s4,8000517a <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    8000511e:	2204a783          	lw	a5,544(s1)
    80005122:	dfd5                	beqz	a5,800050de <pipewrite+0x44>
    80005124:	854e                	mv	a0,s3
    80005126:	ffffd097          	auipc	ra,0xffffd
    8000512a:	228080e7          	jalr	552(ra) # 8000234e <killed>
    8000512e:	f945                	bnez	a0,800050de <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005130:	2184a783          	lw	a5,536(s1)
    80005134:	21c4a703          	lw	a4,540(s1)
    80005138:	2007879b          	addiw	a5,a5,512
    8000513c:	fcf704e3          	beq	a4,a5,80005104 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005140:	4685                	li	a3,1
    80005142:	01590633          	add	a2,s2,s5
    80005146:	faf40593          	addi	a1,s0,-81
    8000514a:	0509b503          	ld	a0,80(s3)
    8000514e:	ffffc097          	auipc	ra,0xffffc
    80005152:	5be080e7          	jalr	1470(ra) # 8000170c <copyin>
    80005156:	03650263          	beq	a0,s6,8000517a <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000515a:	21c4a783          	lw	a5,540(s1)
    8000515e:	0017871b          	addiw	a4,a5,1
    80005162:	20e4ae23          	sw	a4,540(s1)
    80005166:	1ff7f793          	andi	a5,a5,511
    8000516a:	97a6                	add	a5,a5,s1
    8000516c:	faf44703          	lbu	a4,-81(s0)
    80005170:	00e78c23          	sb	a4,24(a5)
      i++;
    80005174:	2905                	addiw	s2,s2,1
    80005176:	b755                	j	8000511a <pipewrite+0x80>
  int i = 0;
    80005178:	4901                	li	s2,0
  wakeup(&pi->nread);
    8000517a:	21848513          	addi	a0,s1,536
    8000517e:	ffffd097          	auipc	ra,0xffffd
    80005182:	f8c080e7          	jalr	-116(ra) # 8000210a <wakeup>
  release(&pi->lock);
    80005186:	8526                	mv	a0,s1
    80005188:	ffffc097          	auipc	ra,0xffffc
    8000518c:	b02080e7          	jalr	-1278(ra) # 80000c8a <release>
  return i;
    80005190:	bfa9                	j	800050ea <pipewrite+0x50>

0000000080005192 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005192:	715d                	addi	sp,sp,-80
    80005194:	e486                	sd	ra,72(sp)
    80005196:	e0a2                	sd	s0,64(sp)
    80005198:	fc26                	sd	s1,56(sp)
    8000519a:	f84a                	sd	s2,48(sp)
    8000519c:	f44e                	sd	s3,40(sp)
    8000519e:	f052                	sd	s4,32(sp)
    800051a0:	ec56                	sd	s5,24(sp)
    800051a2:	e85a                	sd	s6,16(sp)
    800051a4:	0880                	addi	s0,sp,80
    800051a6:	84aa                	mv	s1,a0
    800051a8:	892e                	mv	s2,a1
    800051aa:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800051ac:	ffffd097          	auipc	ra,0xffffd
    800051b0:	830080e7          	jalr	-2000(ra) # 800019dc <myproc>
    800051b4:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800051b6:	8526                	mv	a0,s1
    800051b8:	ffffc097          	auipc	ra,0xffffc
    800051bc:	a1e080e7          	jalr	-1506(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800051c0:	2184a703          	lw	a4,536(s1)
    800051c4:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800051c8:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800051cc:	02f71763          	bne	a4,a5,800051fa <piperead+0x68>
    800051d0:	2244a783          	lw	a5,548(s1)
    800051d4:	c39d                	beqz	a5,800051fa <piperead+0x68>
    if(killed(pr)){
    800051d6:	8552                	mv	a0,s4
    800051d8:	ffffd097          	auipc	ra,0xffffd
    800051dc:	176080e7          	jalr	374(ra) # 8000234e <killed>
    800051e0:	e941                	bnez	a0,80005270 <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800051e2:	85a6                	mv	a1,s1
    800051e4:	854e                	mv	a0,s3
    800051e6:	ffffd097          	auipc	ra,0xffffd
    800051ea:	ec0080e7          	jalr	-320(ra) # 800020a6 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800051ee:	2184a703          	lw	a4,536(s1)
    800051f2:	21c4a783          	lw	a5,540(s1)
    800051f6:	fcf70de3          	beq	a4,a5,800051d0 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051fa:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800051fc:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051fe:	05505363          	blez	s5,80005244 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80005202:	2184a783          	lw	a5,536(s1)
    80005206:	21c4a703          	lw	a4,540(s1)
    8000520a:	02f70d63          	beq	a4,a5,80005244 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000520e:	0017871b          	addiw	a4,a5,1
    80005212:	20e4ac23          	sw	a4,536(s1)
    80005216:	1ff7f793          	andi	a5,a5,511
    8000521a:	97a6                	add	a5,a5,s1
    8000521c:	0187c783          	lbu	a5,24(a5)
    80005220:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005224:	4685                	li	a3,1
    80005226:	fbf40613          	addi	a2,s0,-65
    8000522a:	85ca                	mv	a1,s2
    8000522c:	050a3503          	ld	a0,80(s4)
    80005230:	ffffc097          	auipc	ra,0xffffc
    80005234:	450080e7          	jalr	1104(ra) # 80001680 <copyout>
    80005238:	01650663          	beq	a0,s6,80005244 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000523c:	2985                	addiw	s3,s3,1
    8000523e:	0905                	addi	s2,s2,1
    80005240:	fd3a91e3          	bne	s5,s3,80005202 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005244:	21c48513          	addi	a0,s1,540
    80005248:	ffffd097          	auipc	ra,0xffffd
    8000524c:	ec2080e7          	jalr	-318(ra) # 8000210a <wakeup>
  release(&pi->lock);
    80005250:	8526                	mv	a0,s1
    80005252:	ffffc097          	auipc	ra,0xffffc
    80005256:	a38080e7          	jalr	-1480(ra) # 80000c8a <release>
  return i;
}
    8000525a:	854e                	mv	a0,s3
    8000525c:	60a6                	ld	ra,72(sp)
    8000525e:	6406                	ld	s0,64(sp)
    80005260:	74e2                	ld	s1,56(sp)
    80005262:	7942                	ld	s2,48(sp)
    80005264:	79a2                	ld	s3,40(sp)
    80005266:	7a02                	ld	s4,32(sp)
    80005268:	6ae2                	ld	s5,24(sp)
    8000526a:	6b42                	ld	s6,16(sp)
    8000526c:	6161                	addi	sp,sp,80
    8000526e:	8082                	ret
      release(&pi->lock);
    80005270:	8526                	mv	a0,s1
    80005272:	ffffc097          	auipc	ra,0xffffc
    80005276:	a18080e7          	jalr	-1512(ra) # 80000c8a <release>
      return -1;
    8000527a:	59fd                	li	s3,-1
    8000527c:	bff9                	j	8000525a <piperead+0xc8>

000000008000527e <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    8000527e:	1141                	addi	sp,sp,-16
    80005280:	e422                	sd	s0,8(sp)
    80005282:	0800                	addi	s0,sp,16
    80005284:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005286:	8905                	andi	a0,a0,1
    80005288:	c111                	beqz	a0,8000528c <flags2perm+0xe>
      perm = PTE_X;
    8000528a:	4521                	li	a0,8
    if(flags & 0x2)
    8000528c:	8b89                	andi	a5,a5,2
    8000528e:	c399                	beqz	a5,80005294 <flags2perm+0x16>
      perm |= PTE_W;
    80005290:	00456513          	ori	a0,a0,4
    return perm;
}
    80005294:	6422                	ld	s0,8(sp)
    80005296:	0141                	addi	sp,sp,16
    80005298:	8082                	ret

000000008000529a <exec>:

int
exec(char *path, char **argv)
{
    8000529a:	de010113          	addi	sp,sp,-544
    8000529e:	20113c23          	sd	ra,536(sp)
    800052a2:	20813823          	sd	s0,528(sp)
    800052a6:	20913423          	sd	s1,520(sp)
    800052aa:	21213023          	sd	s2,512(sp)
    800052ae:	ffce                	sd	s3,504(sp)
    800052b0:	fbd2                	sd	s4,496(sp)
    800052b2:	f7d6                	sd	s5,488(sp)
    800052b4:	f3da                	sd	s6,480(sp)
    800052b6:	efde                	sd	s7,472(sp)
    800052b8:	ebe2                	sd	s8,464(sp)
    800052ba:	e7e6                	sd	s9,456(sp)
    800052bc:	e3ea                	sd	s10,448(sp)
    800052be:	ff6e                	sd	s11,440(sp)
    800052c0:	1400                	addi	s0,sp,544
    800052c2:	892a                	mv	s2,a0
    800052c4:	dea43423          	sd	a0,-536(s0)
    800052c8:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800052cc:	ffffc097          	auipc	ra,0xffffc
    800052d0:	710080e7          	jalr	1808(ra) # 800019dc <myproc>
    800052d4:	84aa                	mv	s1,a0

  begin_op();
    800052d6:	fffff097          	auipc	ra,0xfffff
    800052da:	47e080e7          	jalr	1150(ra) # 80004754 <begin_op>

  if((ip = namei(path)) == 0){
    800052de:	854a                	mv	a0,s2
    800052e0:	fffff097          	auipc	ra,0xfffff
    800052e4:	258080e7          	jalr	600(ra) # 80004538 <namei>
    800052e8:	c93d                	beqz	a0,8000535e <exec+0xc4>
    800052ea:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800052ec:	fffff097          	auipc	ra,0xfffff
    800052f0:	aa6080e7          	jalr	-1370(ra) # 80003d92 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800052f4:	04000713          	li	a4,64
    800052f8:	4681                	li	a3,0
    800052fa:	e5040613          	addi	a2,s0,-432
    800052fe:	4581                	li	a1,0
    80005300:	8556                	mv	a0,s5
    80005302:	fffff097          	auipc	ra,0xfffff
    80005306:	d44080e7          	jalr	-700(ra) # 80004046 <readi>
    8000530a:	04000793          	li	a5,64
    8000530e:	00f51a63          	bne	a0,a5,80005322 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005312:	e5042703          	lw	a4,-432(s0)
    80005316:	464c47b7          	lui	a5,0x464c4
    8000531a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000531e:	04f70663          	beq	a4,a5,8000536a <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005322:	8556                	mv	a0,s5
    80005324:	fffff097          	auipc	ra,0xfffff
    80005328:	cd0080e7          	jalr	-816(ra) # 80003ff4 <iunlockput>
    end_op();
    8000532c:	fffff097          	auipc	ra,0xfffff
    80005330:	4a8080e7          	jalr	1192(ra) # 800047d4 <end_op>
  }
  return -1;
    80005334:	557d                	li	a0,-1
}
    80005336:	21813083          	ld	ra,536(sp)
    8000533a:	21013403          	ld	s0,528(sp)
    8000533e:	20813483          	ld	s1,520(sp)
    80005342:	20013903          	ld	s2,512(sp)
    80005346:	79fe                	ld	s3,504(sp)
    80005348:	7a5e                	ld	s4,496(sp)
    8000534a:	7abe                	ld	s5,488(sp)
    8000534c:	7b1e                	ld	s6,480(sp)
    8000534e:	6bfe                	ld	s7,472(sp)
    80005350:	6c5e                	ld	s8,464(sp)
    80005352:	6cbe                	ld	s9,456(sp)
    80005354:	6d1e                	ld	s10,448(sp)
    80005356:	7dfa                	ld	s11,440(sp)
    80005358:	22010113          	addi	sp,sp,544
    8000535c:	8082                	ret
    end_op();
    8000535e:	fffff097          	auipc	ra,0xfffff
    80005362:	476080e7          	jalr	1142(ra) # 800047d4 <end_op>
    return -1;
    80005366:	557d                	li	a0,-1
    80005368:	b7f9                	j	80005336 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    8000536a:	8526                	mv	a0,s1
    8000536c:	ffffc097          	auipc	ra,0xffffc
    80005370:	756080e7          	jalr	1878(ra) # 80001ac2 <proc_pagetable>
    80005374:	8b2a                	mv	s6,a0
    80005376:	d555                	beqz	a0,80005322 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005378:	e7042783          	lw	a5,-400(s0)
    8000537c:	e8845703          	lhu	a4,-376(s0)
    80005380:	c735                	beqz	a4,800053ec <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005382:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005384:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005388:	6a05                	lui	s4,0x1
    8000538a:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    8000538e:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80005392:	6d85                	lui	s11,0x1
    80005394:	7d7d                	lui	s10,0xfffff
    80005396:	a481                	j	800055d6 <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005398:	00003517          	auipc	a0,0x3
    8000539c:	3a050513          	addi	a0,a0,928 # 80008738 <syscalls+0x2c8>
    800053a0:	ffffb097          	auipc	ra,0xffffb
    800053a4:	19e080e7          	jalr	414(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800053a8:	874a                	mv	a4,s2
    800053aa:	009c86bb          	addw	a3,s9,s1
    800053ae:	4581                	li	a1,0
    800053b0:	8556                	mv	a0,s5
    800053b2:	fffff097          	auipc	ra,0xfffff
    800053b6:	c94080e7          	jalr	-876(ra) # 80004046 <readi>
    800053ba:	2501                	sext.w	a0,a0
    800053bc:	1aa91a63          	bne	s2,a0,80005570 <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    800053c0:	009d84bb          	addw	s1,s11,s1
    800053c4:	013d09bb          	addw	s3,s10,s3
    800053c8:	1f74f763          	bgeu	s1,s7,800055b6 <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    800053cc:	02049593          	slli	a1,s1,0x20
    800053d0:	9181                	srli	a1,a1,0x20
    800053d2:	95e2                	add	a1,a1,s8
    800053d4:	855a                	mv	a0,s6
    800053d6:	ffffc097          	auipc	ra,0xffffc
    800053da:	c96080e7          	jalr	-874(ra) # 8000106c <walkaddr>
    800053de:	862a                	mv	a2,a0
    if(pa == 0)
    800053e0:	dd45                	beqz	a0,80005398 <exec+0xfe>
      n = PGSIZE;
    800053e2:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    800053e4:	fd49f2e3          	bgeu	s3,s4,800053a8 <exec+0x10e>
      n = sz - i;
    800053e8:	894e                	mv	s2,s3
    800053ea:	bf7d                	j	800053a8 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800053ec:	4901                	li	s2,0
  iunlockput(ip);
    800053ee:	8556                	mv	a0,s5
    800053f0:	fffff097          	auipc	ra,0xfffff
    800053f4:	c04080e7          	jalr	-1020(ra) # 80003ff4 <iunlockput>
  end_op();
    800053f8:	fffff097          	auipc	ra,0xfffff
    800053fc:	3dc080e7          	jalr	988(ra) # 800047d4 <end_op>
  p = myproc();
    80005400:	ffffc097          	auipc	ra,0xffffc
    80005404:	5dc080e7          	jalr	1500(ra) # 800019dc <myproc>
    80005408:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    8000540a:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    8000540e:	6785                	lui	a5,0x1
    80005410:	17fd                	addi	a5,a5,-1
    80005412:	993e                	add	s2,s2,a5
    80005414:	77fd                	lui	a5,0xfffff
    80005416:	00f977b3          	and	a5,s2,a5
    8000541a:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000541e:	4691                	li	a3,4
    80005420:	6609                	lui	a2,0x2
    80005422:	963e                	add	a2,a2,a5
    80005424:	85be                	mv	a1,a5
    80005426:	855a                	mv	a0,s6
    80005428:	ffffc097          	auipc	ra,0xffffc
    8000542c:	000080e7          	jalr	ra # 80001428 <uvmalloc>
    80005430:	8c2a                	mv	s8,a0
  ip = 0;
    80005432:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005434:	12050e63          	beqz	a0,80005570 <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005438:	75f9                	lui	a1,0xffffe
    8000543a:	95aa                	add	a1,a1,a0
    8000543c:	855a                	mv	a0,s6
    8000543e:	ffffc097          	auipc	ra,0xffffc
    80005442:	210080e7          	jalr	528(ra) # 8000164e <uvmclear>
  stackbase = sp - PGSIZE;
    80005446:	7afd                	lui	s5,0xfffff
    80005448:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    8000544a:	df043783          	ld	a5,-528(s0)
    8000544e:	6388                	ld	a0,0(a5)
    80005450:	c925                	beqz	a0,800054c0 <exec+0x226>
    80005452:	e9040993          	addi	s3,s0,-368
    80005456:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000545a:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000545c:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000545e:	ffffc097          	auipc	ra,0xffffc
    80005462:	9f0080e7          	jalr	-1552(ra) # 80000e4e <strlen>
    80005466:	0015079b          	addiw	a5,a0,1
    8000546a:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000546e:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005472:	13596663          	bltu	s2,s5,8000559e <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005476:	df043d83          	ld	s11,-528(s0)
    8000547a:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    8000547e:	8552                	mv	a0,s4
    80005480:	ffffc097          	auipc	ra,0xffffc
    80005484:	9ce080e7          	jalr	-1586(ra) # 80000e4e <strlen>
    80005488:	0015069b          	addiw	a3,a0,1
    8000548c:	8652                	mv	a2,s4
    8000548e:	85ca                	mv	a1,s2
    80005490:	855a                	mv	a0,s6
    80005492:	ffffc097          	auipc	ra,0xffffc
    80005496:	1ee080e7          	jalr	494(ra) # 80001680 <copyout>
    8000549a:	10054663          	bltz	a0,800055a6 <exec+0x30c>
    ustack[argc] = sp;
    8000549e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800054a2:	0485                	addi	s1,s1,1
    800054a4:	008d8793          	addi	a5,s11,8
    800054a8:	def43823          	sd	a5,-528(s0)
    800054ac:	008db503          	ld	a0,8(s11)
    800054b0:	c911                	beqz	a0,800054c4 <exec+0x22a>
    if(argc >= MAXARG)
    800054b2:	09a1                	addi	s3,s3,8
    800054b4:	fb3c95e3          	bne	s9,s3,8000545e <exec+0x1c4>
  sz = sz1;
    800054b8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800054bc:	4a81                	li	s5,0
    800054be:	a84d                	j	80005570 <exec+0x2d6>
  sp = sz;
    800054c0:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800054c2:	4481                	li	s1,0
  ustack[argc] = 0;
    800054c4:	00349793          	slli	a5,s1,0x3
    800054c8:	f9040713          	addi	a4,s0,-112
    800054cc:	97ba                	add	a5,a5,a4
    800054ce:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffdcf10>
  sp -= (argc+1) * sizeof(uint64);
    800054d2:	00148693          	addi	a3,s1,1
    800054d6:	068e                	slli	a3,a3,0x3
    800054d8:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800054dc:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800054e0:	01597663          	bgeu	s2,s5,800054ec <exec+0x252>
  sz = sz1;
    800054e4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800054e8:	4a81                	li	s5,0
    800054ea:	a059                	j	80005570 <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800054ec:	e9040613          	addi	a2,s0,-368
    800054f0:	85ca                	mv	a1,s2
    800054f2:	855a                	mv	a0,s6
    800054f4:	ffffc097          	auipc	ra,0xffffc
    800054f8:	18c080e7          	jalr	396(ra) # 80001680 <copyout>
    800054fc:	0a054963          	bltz	a0,800055ae <exec+0x314>
  p->trapframe->a1 = sp;
    80005500:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80005504:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005508:	de843783          	ld	a5,-536(s0)
    8000550c:	0007c703          	lbu	a4,0(a5)
    80005510:	cf11                	beqz	a4,8000552c <exec+0x292>
    80005512:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005514:	02f00693          	li	a3,47
    80005518:	a039                	j	80005526 <exec+0x28c>
      last = s+1;
    8000551a:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    8000551e:	0785                	addi	a5,a5,1
    80005520:	fff7c703          	lbu	a4,-1(a5)
    80005524:	c701                	beqz	a4,8000552c <exec+0x292>
    if(*s == '/')
    80005526:	fed71ce3          	bne	a4,a3,8000551e <exec+0x284>
    8000552a:	bfc5                	j	8000551a <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    8000552c:	4641                	li	a2,16
    8000552e:	de843583          	ld	a1,-536(s0)
    80005532:	158b8513          	addi	a0,s7,344
    80005536:	ffffc097          	auipc	ra,0xffffc
    8000553a:	8e6080e7          	jalr	-1818(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    8000553e:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005542:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005546:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000554a:	058bb783          	ld	a5,88(s7)
    8000554e:	e6843703          	ld	a4,-408(s0)
    80005552:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005554:	058bb783          	ld	a5,88(s7)
    80005558:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000555c:	85ea                	mv	a1,s10
    8000555e:	ffffc097          	auipc	ra,0xffffc
    80005562:	600080e7          	jalr	1536(ra) # 80001b5e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005566:	0004851b          	sext.w	a0,s1
    8000556a:	b3f1                	j	80005336 <exec+0x9c>
    8000556c:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005570:	df843583          	ld	a1,-520(s0)
    80005574:	855a                	mv	a0,s6
    80005576:	ffffc097          	auipc	ra,0xffffc
    8000557a:	5e8080e7          	jalr	1512(ra) # 80001b5e <proc_freepagetable>
  if(ip){
    8000557e:	da0a92e3          	bnez	s5,80005322 <exec+0x88>
  return -1;
    80005582:	557d                	li	a0,-1
    80005584:	bb4d                	j	80005336 <exec+0x9c>
    80005586:	df243c23          	sd	s2,-520(s0)
    8000558a:	b7dd                	j	80005570 <exec+0x2d6>
    8000558c:	df243c23          	sd	s2,-520(s0)
    80005590:	b7c5                	j	80005570 <exec+0x2d6>
    80005592:	df243c23          	sd	s2,-520(s0)
    80005596:	bfe9                	j	80005570 <exec+0x2d6>
    80005598:	df243c23          	sd	s2,-520(s0)
    8000559c:	bfd1                	j	80005570 <exec+0x2d6>
  sz = sz1;
    8000559e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800055a2:	4a81                	li	s5,0
    800055a4:	b7f1                	j	80005570 <exec+0x2d6>
  sz = sz1;
    800055a6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800055aa:	4a81                	li	s5,0
    800055ac:	b7d1                	j	80005570 <exec+0x2d6>
  sz = sz1;
    800055ae:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800055b2:	4a81                	li	s5,0
    800055b4:	bf75                	j	80005570 <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800055b6:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800055ba:	e0843783          	ld	a5,-504(s0)
    800055be:	0017869b          	addiw	a3,a5,1
    800055c2:	e0d43423          	sd	a3,-504(s0)
    800055c6:	e0043783          	ld	a5,-512(s0)
    800055ca:	0387879b          	addiw	a5,a5,56
    800055ce:	e8845703          	lhu	a4,-376(s0)
    800055d2:	e0e6dee3          	bge	a3,a4,800053ee <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800055d6:	2781                	sext.w	a5,a5
    800055d8:	e0f43023          	sd	a5,-512(s0)
    800055dc:	03800713          	li	a4,56
    800055e0:	86be                	mv	a3,a5
    800055e2:	e1840613          	addi	a2,s0,-488
    800055e6:	4581                	li	a1,0
    800055e8:	8556                	mv	a0,s5
    800055ea:	fffff097          	auipc	ra,0xfffff
    800055ee:	a5c080e7          	jalr	-1444(ra) # 80004046 <readi>
    800055f2:	03800793          	li	a5,56
    800055f6:	f6f51be3          	bne	a0,a5,8000556c <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    800055fa:	e1842783          	lw	a5,-488(s0)
    800055fe:	4705                	li	a4,1
    80005600:	fae79de3          	bne	a5,a4,800055ba <exec+0x320>
    if(ph.memsz < ph.filesz)
    80005604:	e4043483          	ld	s1,-448(s0)
    80005608:	e3843783          	ld	a5,-456(s0)
    8000560c:	f6f4ede3          	bltu	s1,a5,80005586 <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005610:	e2843783          	ld	a5,-472(s0)
    80005614:	94be                	add	s1,s1,a5
    80005616:	f6f4ebe3          	bltu	s1,a5,8000558c <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    8000561a:	de043703          	ld	a4,-544(s0)
    8000561e:	8ff9                	and	a5,a5,a4
    80005620:	fbad                	bnez	a5,80005592 <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005622:	e1c42503          	lw	a0,-484(s0)
    80005626:	00000097          	auipc	ra,0x0
    8000562a:	c58080e7          	jalr	-936(ra) # 8000527e <flags2perm>
    8000562e:	86aa                	mv	a3,a0
    80005630:	8626                	mv	a2,s1
    80005632:	85ca                	mv	a1,s2
    80005634:	855a                	mv	a0,s6
    80005636:	ffffc097          	auipc	ra,0xffffc
    8000563a:	df2080e7          	jalr	-526(ra) # 80001428 <uvmalloc>
    8000563e:	dea43c23          	sd	a0,-520(s0)
    80005642:	d939                	beqz	a0,80005598 <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005644:	e2843c03          	ld	s8,-472(s0)
    80005648:	e2042c83          	lw	s9,-480(s0)
    8000564c:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005650:	f60b83e3          	beqz	s7,800055b6 <exec+0x31c>
    80005654:	89de                	mv	s3,s7
    80005656:	4481                	li	s1,0
    80005658:	bb95                	j	800053cc <exec+0x132>

000000008000565a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000565a:	7179                	addi	sp,sp,-48
    8000565c:	f406                	sd	ra,40(sp)
    8000565e:	f022                	sd	s0,32(sp)
    80005660:	ec26                	sd	s1,24(sp)
    80005662:	e84a                	sd	s2,16(sp)
    80005664:	1800                	addi	s0,sp,48
    80005666:	892e                	mv	s2,a1
    80005668:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000566a:	fdc40593          	addi	a1,s0,-36
    8000566e:	ffffe097          	auipc	ra,0xffffe
    80005672:	8bc080e7          	jalr	-1860(ra) # 80002f2a <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005676:	fdc42703          	lw	a4,-36(s0)
    8000567a:	47bd                	li	a5,15
    8000567c:	02e7eb63          	bltu	a5,a4,800056b2 <argfd+0x58>
    80005680:	ffffc097          	auipc	ra,0xffffc
    80005684:	35c080e7          	jalr	860(ra) # 800019dc <myproc>
    80005688:	fdc42703          	lw	a4,-36(s0)
    8000568c:	01a70793          	addi	a5,a4,26
    80005690:	078e                	slli	a5,a5,0x3
    80005692:	953e                	add	a0,a0,a5
    80005694:	611c                	ld	a5,0(a0)
    80005696:	c385                	beqz	a5,800056b6 <argfd+0x5c>
    return -1;
  if(pfd)
    80005698:	00090463          	beqz	s2,800056a0 <argfd+0x46>
    *pfd = fd;
    8000569c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800056a0:	4501                	li	a0,0
  if(pf)
    800056a2:	c091                	beqz	s1,800056a6 <argfd+0x4c>
    *pf = f;
    800056a4:	e09c                	sd	a5,0(s1)
}
    800056a6:	70a2                	ld	ra,40(sp)
    800056a8:	7402                	ld	s0,32(sp)
    800056aa:	64e2                	ld	s1,24(sp)
    800056ac:	6942                	ld	s2,16(sp)
    800056ae:	6145                	addi	sp,sp,48
    800056b0:	8082                	ret
    return -1;
    800056b2:	557d                	li	a0,-1
    800056b4:	bfcd                	j	800056a6 <argfd+0x4c>
    800056b6:	557d                	li	a0,-1
    800056b8:	b7fd                	j	800056a6 <argfd+0x4c>

00000000800056ba <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800056ba:	1101                	addi	sp,sp,-32
    800056bc:	ec06                	sd	ra,24(sp)
    800056be:	e822                	sd	s0,16(sp)
    800056c0:	e426                	sd	s1,8(sp)
    800056c2:	1000                	addi	s0,sp,32
    800056c4:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800056c6:	ffffc097          	auipc	ra,0xffffc
    800056ca:	316080e7          	jalr	790(ra) # 800019dc <myproc>
    800056ce:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800056d0:	0d050793          	addi	a5,a0,208
    800056d4:	4501                	li	a0,0
    800056d6:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800056d8:	6398                	ld	a4,0(a5)
    800056da:	cb19                	beqz	a4,800056f0 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800056dc:	2505                	addiw	a0,a0,1
    800056de:	07a1                	addi	a5,a5,8
    800056e0:	fed51ce3          	bne	a0,a3,800056d8 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800056e4:	557d                	li	a0,-1
}
    800056e6:	60e2                	ld	ra,24(sp)
    800056e8:	6442                	ld	s0,16(sp)
    800056ea:	64a2                	ld	s1,8(sp)
    800056ec:	6105                	addi	sp,sp,32
    800056ee:	8082                	ret
      p->ofile[fd] = f;
    800056f0:	01a50793          	addi	a5,a0,26
    800056f4:	078e                	slli	a5,a5,0x3
    800056f6:	963e                	add	a2,a2,a5
    800056f8:	e204                	sd	s1,0(a2)
      return fd;
    800056fa:	b7f5                	j	800056e6 <fdalloc+0x2c>

00000000800056fc <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800056fc:	715d                	addi	sp,sp,-80
    800056fe:	e486                	sd	ra,72(sp)
    80005700:	e0a2                	sd	s0,64(sp)
    80005702:	fc26                	sd	s1,56(sp)
    80005704:	f84a                	sd	s2,48(sp)
    80005706:	f44e                	sd	s3,40(sp)
    80005708:	f052                	sd	s4,32(sp)
    8000570a:	ec56                	sd	s5,24(sp)
    8000570c:	e85a                	sd	s6,16(sp)
    8000570e:	0880                	addi	s0,sp,80
    80005710:	8b2e                	mv	s6,a1
    80005712:	89b2                	mv	s3,a2
    80005714:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005716:	fb040593          	addi	a1,s0,-80
    8000571a:	fffff097          	auipc	ra,0xfffff
    8000571e:	e3c080e7          	jalr	-452(ra) # 80004556 <nameiparent>
    80005722:	84aa                	mv	s1,a0
    80005724:	14050f63          	beqz	a0,80005882 <create+0x186>
    return 0;

  ilock(dp);
    80005728:	ffffe097          	auipc	ra,0xffffe
    8000572c:	66a080e7          	jalr	1642(ra) # 80003d92 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005730:	4601                	li	a2,0
    80005732:	fb040593          	addi	a1,s0,-80
    80005736:	8526                	mv	a0,s1
    80005738:	fffff097          	auipc	ra,0xfffff
    8000573c:	b3e080e7          	jalr	-1218(ra) # 80004276 <dirlookup>
    80005740:	8aaa                	mv	s5,a0
    80005742:	c931                	beqz	a0,80005796 <create+0x9a>
    iunlockput(dp);
    80005744:	8526                	mv	a0,s1
    80005746:	fffff097          	auipc	ra,0xfffff
    8000574a:	8ae080e7          	jalr	-1874(ra) # 80003ff4 <iunlockput>
    ilock(ip);
    8000574e:	8556                	mv	a0,s5
    80005750:	ffffe097          	auipc	ra,0xffffe
    80005754:	642080e7          	jalr	1602(ra) # 80003d92 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005758:	000b059b          	sext.w	a1,s6
    8000575c:	4789                	li	a5,2
    8000575e:	02f59563          	bne	a1,a5,80005788 <create+0x8c>
    80005762:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdd054>
    80005766:	37f9                	addiw	a5,a5,-2
    80005768:	17c2                	slli	a5,a5,0x30
    8000576a:	93c1                	srli	a5,a5,0x30
    8000576c:	4705                	li	a4,1
    8000576e:	00f76d63          	bltu	a4,a5,80005788 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005772:	8556                	mv	a0,s5
    80005774:	60a6                	ld	ra,72(sp)
    80005776:	6406                	ld	s0,64(sp)
    80005778:	74e2                	ld	s1,56(sp)
    8000577a:	7942                	ld	s2,48(sp)
    8000577c:	79a2                	ld	s3,40(sp)
    8000577e:	7a02                	ld	s4,32(sp)
    80005780:	6ae2                	ld	s5,24(sp)
    80005782:	6b42                	ld	s6,16(sp)
    80005784:	6161                	addi	sp,sp,80
    80005786:	8082                	ret
    iunlockput(ip);
    80005788:	8556                	mv	a0,s5
    8000578a:	fffff097          	auipc	ra,0xfffff
    8000578e:	86a080e7          	jalr	-1942(ra) # 80003ff4 <iunlockput>
    return 0;
    80005792:	4a81                	li	s5,0
    80005794:	bff9                	j	80005772 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005796:	85da                	mv	a1,s6
    80005798:	4088                	lw	a0,0(s1)
    8000579a:	ffffe097          	auipc	ra,0xffffe
    8000579e:	45c080e7          	jalr	1116(ra) # 80003bf6 <ialloc>
    800057a2:	8a2a                	mv	s4,a0
    800057a4:	c539                	beqz	a0,800057f2 <create+0xf6>
  ilock(ip);
    800057a6:	ffffe097          	auipc	ra,0xffffe
    800057aa:	5ec080e7          	jalr	1516(ra) # 80003d92 <ilock>
  ip->major = major;
    800057ae:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800057b2:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800057b6:	4905                	li	s2,1
    800057b8:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800057bc:	8552                	mv	a0,s4
    800057be:	ffffe097          	auipc	ra,0xffffe
    800057c2:	50a080e7          	jalr	1290(ra) # 80003cc8 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800057c6:	000b059b          	sext.w	a1,s6
    800057ca:	03258b63          	beq	a1,s2,80005800 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    800057ce:	004a2603          	lw	a2,4(s4)
    800057d2:	fb040593          	addi	a1,s0,-80
    800057d6:	8526                	mv	a0,s1
    800057d8:	fffff097          	auipc	ra,0xfffff
    800057dc:	cae080e7          	jalr	-850(ra) # 80004486 <dirlink>
    800057e0:	06054f63          	bltz	a0,8000585e <create+0x162>
  iunlockput(dp);
    800057e4:	8526                	mv	a0,s1
    800057e6:	fffff097          	auipc	ra,0xfffff
    800057ea:	80e080e7          	jalr	-2034(ra) # 80003ff4 <iunlockput>
  return ip;
    800057ee:	8ad2                	mv	s5,s4
    800057f0:	b749                	j	80005772 <create+0x76>
    iunlockput(dp);
    800057f2:	8526                	mv	a0,s1
    800057f4:	fffff097          	auipc	ra,0xfffff
    800057f8:	800080e7          	jalr	-2048(ra) # 80003ff4 <iunlockput>
    return 0;
    800057fc:	8ad2                	mv	s5,s4
    800057fe:	bf95                	j	80005772 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005800:	004a2603          	lw	a2,4(s4)
    80005804:	00003597          	auipc	a1,0x3
    80005808:	f5458593          	addi	a1,a1,-172 # 80008758 <syscalls+0x2e8>
    8000580c:	8552                	mv	a0,s4
    8000580e:	fffff097          	auipc	ra,0xfffff
    80005812:	c78080e7          	jalr	-904(ra) # 80004486 <dirlink>
    80005816:	04054463          	bltz	a0,8000585e <create+0x162>
    8000581a:	40d0                	lw	a2,4(s1)
    8000581c:	00003597          	auipc	a1,0x3
    80005820:	f4458593          	addi	a1,a1,-188 # 80008760 <syscalls+0x2f0>
    80005824:	8552                	mv	a0,s4
    80005826:	fffff097          	auipc	ra,0xfffff
    8000582a:	c60080e7          	jalr	-928(ra) # 80004486 <dirlink>
    8000582e:	02054863          	bltz	a0,8000585e <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005832:	004a2603          	lw	a2,4(s4)
    80005836:	fb040593          	addi	a1,s0,-80
    8000583a:	8526                	mv	a0,s1
    8000583c:	fffff097          	auipc	ra,0xfffff
    80005840:	c4a080e7          	jalr	-950(ra) # 80004486 <dirlink>
    80005844:	00054d63          	bltz	a0,8000585e <create+0x162>
    dp->nlink++;  // for ".."
    80005848:	04a4d783          	lhu	a5,74(s1)
    8000584c:	2785                	addiw	a5,a5,1
    8000584e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005852:	8526                	mv	a0,s1
    80005854:	ffffe097          	auipc	ra,0xffffe
    80005858:	474080e7          	jalr	1140(ra) # 80003cc8 <iupdate>
    8000585c:	b761                	j	800057e4 <create+0xe8>
  ip->nlink = 0;
    8000585e:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005862:	8552                	mv	a0,s4
    80005864:	ffffe097          	auipc	ra,0xffffe
    80005868:	464080e7          	jalr	1124(ra) # 80003cc8 <iupdate>
  iunlockput(ip);
    8000586c:	8552                	mv	a0,s4
    8000586e:	ffffe097          	auipc	ra,0xffffe
    80005872:	786080e7          	jalr	1926(ra) # 80003ff4 <iunlockput>
  iunlockput(dp);
    80005876:	8526                	mv	a0,s1
    80005878:	ffffe097          	auipc	ra,0xffffe
    8000587c:	77c080e7          	jalr	1916(ra) # 80003ff4 <iunlockput>
  return 0;
    80005880:	bdcd                	j	80005772 <create+0x76>
    return 0;
    80005882:	8aaa                	mv	s5,a0
    80005884:	b5fd                	j	80005772 <create+0x76>

0000000080005886 <sys_dup>:
{
    80005886:	7179                	addi	sp,sp,-48
    80005888:	f406                	sd	ra,40(sp)
    8000588a:	f022                	sd	s0,32(sp)
    8000588c:	ec26                	sd	s1,24(sp)
    8000588e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005890:	fd840613          	addi	a2,s0,-40
    80005894:	4581                	li	a1,0
    80005896:	4501                	li	a0,0
    80005898:	00000097          	auipc	ra,0x0
    8000589c:	dc2080e7          	jalr	-574(ra) # 8000565a <argfd>
    return -1;
    800058a0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800058a2:	02054363          	bltz	a0,800058c8 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800058a6:	fd843503          	ld	a0,-40(s0)
    800058aa:	00000097          	auipc	ra,0x0
    800058ae:	e10080e7          	jalr	-496(ra) # 800056ba <fdalloc>
    800058b2:	84aa                	mv	s1,a0
    return -1;
    800058b4:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800058b6:	00054963          	bltz	a0,800058c8 <sys_dup+0x42>
  filedup(f);
    800058ba:	fd843503          	ld	a0,-40(s0)
    800058be:	fffff097          	auipc	ra,0xfffff
    800058c2:	310080e7          	jalr	784(ra) # 80004bce <filedup>
  return fd;
    800058c6:	87a6                	mv	a5,s1
}
    800058c8:	853e                	mv	a0,a5
    800058ca:	70a2                	ld	ra,40(sp)
    800058cc:	7402                	ld	s0,32(sp)
    800058ce:	64e2                	ld	s1,24(sp)
    800058d0:	6145                	addi	sp,sp,48
    800058d2:	8082                	ret

00000000800058d4 <sys_read>:
{
    800058d4:	7179                	addi	sp,sp,-48
    800058d6:	f406                	sd	ra,40(sp)
    800058d8:	f022                	sd	s0,32(sp)
    800058da:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800058dc:	fd840593          	addi	a1,s0,-40
    800058e0:	4505                	li	a0,1
    800058e2:	ffffd097          	auipc	ra,0xffffd
    800058e6:	668080e7          	jalr	1640(ra) # 80002f4a <argaddr>
  argint(2, &n);
    800058ea:	fe440593          	addi	a1,s0,-28
    800058ee:	4509                	li	a0,2
    800058f0:	ffffd097          	auipc	ra,0xffffd
    800058f4:	63a080e7          	jalr	1594(ra) # 80002f2a <argint>
  if(argfd(0, 0, &f) < 0)
    800058f8:	fe840613          	addi	a2,s0,-24
    800058fc:	4581                	li	a1,0
    800058fe:	4501                	li	a0,0
    80005900:	00000097          	auipc	ra,0x0
    80005904:	d5a080e7          	jalr	-678(ra) # 8000565a <argfd>
    80005908:	87aa                	mv	a5,a0
    return -1;
    8000590a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000590c:	0007cc63          	bltz	a5,80005924 <sys_read+0x50>
  return fileread(f, p, n);
    80005910:	fe442603          	lw	a2,-28(s0)
    80005914:	fd843583          	ld	a1,-40(s0)
    80005918:	fe843503          	ld	a0,-24(s0)
    8000591c:	fffff097          	auipc	ra,0xfffff
    80005920:	43e080e7          	jalr	1086(ra) # 80004d5a <fileread>
}
    80005924:	70a2                	ld	ra,40(sp)
    80005926:	7402                	ld	s0,32(sp)
    80005928:	6145                	addi	sp,sp,48
    8000592a:	8082                	ret

000000008000592c <sys_write>:
{
    8000592c:	7179                	addi	sp,sp,-48
    8000592e:	f406                	sd	ra,40(sp)
    80005930:	f022                	sd	s0,32(sp)
    80005932:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005934:	fd840593          	addi	a1,s0,-40
    80005938:	4505                	li	a0,1
    8000593a:	ffffd097          	auipc	ra,0xffffd
    8000593e:	610080e7          	jalr	1552(ra) # 80002f4a <argaddr>
  argint(2, &n);
    80005942:	fe440593          	addi	a1,s0,-28
    80005946:	4509                	li	a0,2
    80005948:	ffffd097          	auipc	ra,0xffffd
    8000594c:	5e2080e7          	jalr	1506(ra) # 80002f2a <argint>
  if(argfd(0, 0, &f) < 0)
    80005950:	fe840613          	addi	a2,s0,-24
    80005954:	4581                	li	a1,0
    80005956:	4501                	li	a0,0
    80005958:	00000097          	auipc	ra,0x0
    8000595c:	d02080e7          	jalr	-766(ra) # 8000565a <argfd>
    80005960:	87aa                	mv	a5,a0
    return -1;
    80005962:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005964:	0007cc63          	bltz	a5,8000597c <sys_write+0x50>
  return filewrite(f, p, n);
    80005968:	fe442603          	lw	a2,-28(s0)
    8000596c:	fd843583          	ld	a1,-40(s0)
    80005970:	fe843503          	ld	a0,-24(s0)
    80005974:	fffff097          	auipc	ra,0xfffff
    80005978:	4a8080e7          	jalr	1192(ra) # 80004e1c <filewrite>
}
    8000597c:	70a2                	ld	ra,40(sp)
    8000597e:	7402                	ld	s0,32(sp)
    80005980:	6145                	addi	sp,sp,48
    80005982:	8082                	ret

0000000080005984 <sys_close>:
{
    80005984:	1101                	addi	sp,sp,-32
    80005986:	ec06                	sd	ra,24(sp)
    80005988:	e822                	sd	s0,16(sp)
    8000598a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000598c:	fe040613          	addi	a2,s0,-32
    80005990:	fec40593          	addi	a1,s0,-20
    80005994:	4501                	li	a0,0
    80005996:	00000097          	auipc	ra,0x0
    8000599a:	cc4080e7          	jalr	-828(ra) # 8000565a <argfd>
    return -1;
    8000599e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800059a0:	02054463          	bltz	a0,800059c8 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800059a4:	ffffc097          	auipc	ra,0xffffc
    800059a8:	038080e7          	jalr	56(ra) # 800019dc <myproc>
    800059ac:	fec42783          	lw	a5,-20(s0)
    800059b0:	07e9                	addi	a5,a5,26
    800059b2:	078e                	slli	a5,a5,0x3
    800059b4:	97aa                	add	a5,a5,a0
    800059b6:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800059ba:	fe043503          	ld	a0,-32(s0)
    800059be:	fffff097          	auipc	ra,0xfffff
    800059c2:	262080e7          	jalr	610(ra) # 80004c20 <fileclose>
  return 0;
    800059c6:	4781                	li	a5,0
}
    800059c8:	853e                	mv	a0,a5
    800059ca:	60e2                	ld	ra,24(sp)
    800059cc:	6442                	ld	s0,16(sp)
    800059ce:	6105                	addi	sp,sp,32
    800059d0:	8082                	ret

00000000800059d2 <sys_fstat>:
{
    800059d2:	1101                	addi	sp,sp,-32
    800059d4:	ec06                	sd	ra,24(sp)
    800059d6:	e822                	sd	s0,16(sp)
    800059d8:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800059da:	fe040593          	addi	a1,s0,-32
    800059de:	4505                	li	a0,1
    800059e0:	ffffd097          	auipc	ra,0xffffd
    800059e4:	56a080e7          	jalr	1386(ra) # 80002f4a <argaddr>
  if(argfd(0, 0, &f) < 0)
    800059e8:	fe840613          	addi	a2,s0,-24
    800059ec:	4581                	li	a1,0
    800059ee:	4501                	li	a0,0
    800059f0:	00000097          	auipc	ra,0x0
    800059f4:	c6a080e7          	jalr	-918(ra) # 8000565a <argfd>
    800059f8:	87aa                	mv	a5,a0
    return -1;
    800059fa:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800059fc:	0007ca63          	bltz	a5,80005a10 <sys_fstat+0x3e>
  return filestat(f, st);
    80005a00:	fe043583          	ld	a1,-32(s0)
    80005a04:	fe843503          	ld	a0,-24(s0)
    80005a08:	fffff097          	auipc	ra,0xfffff
    80005a0c:	2e0080e7          	jalr	736(ra) # 80004ce8 <filestat>
}
    80005a10:	60e2                	ld	ra,24(sp)
    80005a12:	6442                	ld	s0,16(sp)
    80005a14:	6105                	addi	sp,sp,32
    80005a16:	8082                	ret

0000000080005a18 <sys_link>:
{
    80005a18:	7169                	addi	sp,sp,-304
    80005a1a:	f606                	sd	ra,296(sp)
    80005a1c:	f222                	sd	s0,288(sp)
    80005a1e:	ee26                	sd	s1,280(sp)
    80005a20:	ea4a                	sd	s2,272(sp)
    80005a22:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a24:	08000613          	li	a2,128
    80005a28:	ed040593          	addi	a1,s0,-304
    80005a2c:	4501                	li	a0,0
    80005a2e:	ffffd097          	auipc	ra,0xffffd
    80005a32:	53c080e7          	jalr	1340(ra) # 80002f6a <argstr>
    return -1;
    80005a36:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a38:	10054e63          	bltz	a0,80005b54 <sys_link+0x13c>
    80005a3c:	08000613          	li	a2,128
    80005a40:	f5040593          	addi	a1,s0,-176
    80005a44:	4505                	li	a0,1
    80005a46:	ffffd097          	auipc	ra,0xffffd
    80005a4a:	524080e7          	jalr	1316(ra) # 80002f6a <argstr>
    return -1;
    80005a4e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a50:	10054263          	bltz	a0,80005b54 <sys_link+0x13c>
  begin_op();
    80005a54:	fffff097          	auipc	ra,0xfffff
    80005a58:	d00080e7          	jalr	-768(ra) # 80004754 <begin_op>
  if((ip = namei(old)) == 0){
    80005a5c:	ed040513          	addi	a0,s0,-304
    80005a60:	fffff097          	auipc	ra,0xfffff
    80005a64:	ad8080e7          	jalr	-1320(ra) # 80004538 <namei>
    80005a68:	84aa                	mv	s1,a0
    80005a6a:	c551                	beqz	a0,80005af6 <sys_link+0xde>
  ilock(ip);
    80005a6c:	ffffe097          	auipc	ra,0xffffe
    80005a70:	326080e7          	jalr	806(ra) # 80003d92 <ilock>
  if(ip->type == T_DIR){
    80005a74:	04449703          	lh	a4,68(s1)
    80005a78:	4785                	li	a5,1
    80005a7a:	08f70463          	beq	a4,a5,80005b02 <sys_link+0xea>
  ip->nlink++;
    80005a7e:	04a4d783          	lhu	a5,74(s1)
    80005a82:	2785                	addiw	a5,a5,1
    80005a84:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a88:	8526                	mv	a0,s1
    80005a8a:	ffffe097          	auipc	ra,0xffffe
    80005a8e:	23e080e7          	jalr	574(ra) # 80003cc8 <iupdate>
  iunlock(ip);
    80005a92:	8526                	mv	a0,s1
    80005a94:	ffffe097          	auipc	ra,0xffffe
    80005a98:	3c0080e7          	jalr	960(ra) # 80003e54 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005a9c:	fd040593          	addi	a1,s0,-48
    80005aa0:	f5040513          	addi	a0,s0,-176
    80005aa4:	fffff097          	auipc	ra,0xfffff
    80005aa8:	ab2080e7          	jalr	-1358(ra) # 80004556 <nameiparent>
    80005aac:	892a                	mv	s2,a0
    80005aae:	c935                	beqz	a0,80005b22 <sys_link+0x10a>
  ilock(dp);
    80005ab0:	ffffe097          	auipc	ra,0xffffe
    80005ab4:	2e2080e7          	jalr	738(ra) # 80003d92 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005ab8:	00092703          	lw	a4,0(s2)
    80005abc:	409c                	lw	a5,0(s1)
    80005abe:	04f71d63          	bne	a4,a5,80005b18 <sys_link+0x100>
    80005ac2:	40d0                	lw	a2,4(s1)
    80005ac4:	fd040593          	addi	a1,s0,-48
    80005ac8:	854a                	mv	a0,s2
    80005aca:	fffff097          	auipc	ra,0xfffff
    80005ace:	9bc080e7          	jalr	-1604(ra) # 80004486 <dirlink>
    80005ad2:	04054363          	bltz	a0,80005b18 <sys_link+0x100>
  iunlockput(dp);
    80005ad6:	854a                	mv	a0,s2
    80005ad8:	ffffe097          	auipc	ra,0xffffe
    80005adc:	51c080e7          	jalr	1308(ra) # 80003ff4 <iunlockput>
  iput(ip);
    80005ae0:	8526                	mv	a0,s1
    80005ae2:	ffffe097          	auipc	ra,0xffffe
    80005ae6:	46a080e7          	jalr	1130(ra) # 80003f4c <iput>
  end_op();
    80005aea:	fffff097          	auipc	ra,0xfffff
    80005aee:	cea080e7          	jalr	-790(ra) # 800047d4 <end_op>
  return 0;
    80005af2:	4781                	li	a5,0
    80005af4:	a085                	j	80005b54 <sys_link+0x13c>
    end_op();
    80005af6:	fffff097          	auipc	ra,0xfffff
    80005afa:	cde080e7          	jalr	-802(ra) # 800047d4 <end_op>
    return -1;
    80005afe:	57fd                	li	a5,-1
    80005b00:	a891                	j	80005b54 <sys_link+0x13c>
    iunlockput(ip);
    80005b02:	8526                	mv	a0,s1
    80005b04:	ffffe097          	auipc	ra,0xffffe
    80005b08:	4f0080e7          	jalr	1264(ra) # 80003ff4 <iunlockput>
    end_op();
    80005b0c:	fffff097          	auipc	ra,0xfffff
    80005b10:	cc8080e7          	jalr	-824(ra) # 800047d4 <end_op>
    return -1;
    80005b14:	57fd                	li	a5,-1
    80005b16:	a83d                	j	80005b54 <sys_link+0x13c>
    iunlockput(dp);
    80005b18:	854a                	mv	a0,s2
    80005b1a:	ffffe097          	auipc	ra,0xffffe
    80005b1e:	4da080e7          	jalr	1242(ra) # 80003ff4 <iunlockput>
  ilock(ip);
    80005b22:	8526                	mv	a0,s1
    80005b24:	ffffe097          	auipc	ra,0xffffe
    80005b28:	26e080e7          	jalr	622(ra) # 80003d92 <ilock>
  ip->nlink--;
    80005b2c:	04a4d783          	lhu	a5,74(s1)
    80005b30:	37fd                	addiw	a5,a5,-1
    80005b32:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005b36:	8526                	mv	a0,s1
    80005b38:	ffffe097          	auipc	ra,0xffffe
    80005b3c:	190080e7          	jalr	400(ra) # 80003cc8 <iupdate>
  iunlockput(ip);
    80005b40:	8526                	mv	a0,s1
    80005b42:	ffffe097          	auipc	ra,0xffffe
    80005b46:	4b2080e7          	jalr	1202(ra) # 80003ff4 <iunlockput>
  end_op();
    80005b4a:	fffff097          	auipc	ra,0xfffff
    80005b4e:	c8a080e7          	jalr	-886(ra) # 800047d4 <end_op>
  return -1;
    80005b52:	57fd                	li	a5,-1
}
    80005b54:	853e                	mv	a0,a5
    80005b56:	70b2                	ld	ra,296(sp)
    80005b58:	7412                	ld	s0,288(sp)
    80005b5a:	64f2                	ld	s1,280(sp)
    80005b5c:	6952                	ld	s2,272(sp)
    80005b5e:	6155                	addi	sp,sp,304
    80005b60:	8082                	ret

0000000080005b62 <sys_unlink>:
{
    80005b62:	7151                	addi	sp,sp,-240
    80005b64:	f586                	sd	ra,232(sp)
    80005b66:	f1a2                	sd	s0,224(sp)
    80005b68:	eda6                	sd	s1,216(sp)
    80005b6a:	e9ca                	sd	s2,208(sp)
    80005b6c:	e5ce                	sd	s3,200(sp)
    80005b6e:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005b70:	08000613          	li	a2,128
    80005b74:	f3040593          	addi	a1,s0,-208
    80005b78:	4501                	li	a0,0
    80005b7a:	ffffd097          	auipc	ra,0xffffd
    80005b7e:	3f0080e7          	jalr	1008(ra) # 80002f6a <argstr>
    80005b82:	18054163          	bltz	a0,80005d04 <sys_unlink+0x1a2>
  begin_op();
    80005b86:	fffff097          	auipc	ra,0xfffff
    80005b8a:	bce080e7          	jalr	-1074(ra) # 80004754 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005b8e:	fb040593          	addi	a1,s0,-80
    80005b92:	f3040513          	addi	a0,s0,-208
    80005b96:	fffff097          	auipc	ra,0xfffff
    80005b9a:	9c0080e7          	jalr	-1600(ra) # 80004556 <nameiparent>
    80005b9e:	84aa                	mv	s1,a0
    80005ba0:	c979                	beqz	a0,80005c76 <sys_unlink+0x114>
  ilock(dp);
    80005ba2:	ffffe097          	auipc	ra,0xffffe
    80005ba6:	1f0080e7          	jalr	496(ra) # 80003d92 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005baa:	00003597          	auipc	a1,0x3
    80005bae:	bae58593          	addi	a1,a1,-1106 # 80008758 <syscalls+0x2e8>
    80005bb2:	fb040513          	addi	a0,s0,-80
    80005bb6:	ffffe097          	auipc	ra,0xffffe
    80005bba:	6a6080e7          	jalr	1702(ra) # 8000425c <namecmp>
    80005bbe:	14050a63          	beqz	a0,80005d12 <sys_unlink+0x1b0>
    80005bc2:	00003597          	auipc	a1,0x3
    80005bc6:	b9e58593          	addi	a1,a1,-1122 # 80008760 <syscalls+0x2f0>
    80005bca:	fb040513          	addi	a0,s0,-80
    80005bce:	ffffe097          	auipc	ra,0xffffe
    80005bd2:	68e080e7          	jalr	1678(ra) # 8000425c <namecmp>
    80005bd6:	12050e63          	beqz	a0,80005d12 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005bda:	f2c40613          	addi	a2,s0,-212
    80005bde:	fb040593          	addi	a1,s0,-80
    80005be2:	8526                	mv	a0,s1
    80005be4:	ffffe097          	auipc	ra,0xffffe
    80005be8:	692080e7          	jalr	1682(ra) # 80004276 <dirlookup>
    80005bec:	892a                	mv	s2,a0
    80005bee:	12050263          	beqz	a0,80005d12 <sys_unlink+0x1b0>
  ilock(ip);
    80005bf2:	ffffe097          	auipc	ra,0xffffe
    80005bf6:	1a0080e7          	jalr	416(ra) # 80003d92 <ilock>
  if(ip->nlink < 1)
    80005bfa:	04a91783          	lh	a5,74(s2)
    80005bfe:	08f05263          	blez	a5,80005c82 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005c02:	04491703          	lh	a4,68(s2)
    80005c06:	4785                	li	a5,1
    80005c08:	08f70563          	beq	a4,a5,80005c92 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005c0c:	4641                	li	a2,16
    80005c0e:	4581                	li	a1,0
    80005c10:	fc040513          	addi	a0,s0,-64
    80005c14:	ffffb097          	auipc	ra,0xffffb
    80005c18:	0be080e7          	jalr	190(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c1c:	4741                	li	a4,16
    80005c1e:	f2c42683          	lw	a3,-212(s0)
    80005c22:	fc040613          	addi	a2,s0,-64
    80005c26:	4581                	li	a1,0
    80005c28:	8526                	mv	a0,s1
    80005c2a:	ffffe097          	auipc	ra,0xffffe
    80005c2e:	514080e7          	jalr	1300(ra) # 8000413e <writei>
    80005c32:	47c1                	li	a5,16
    80005c34:	0af51563          	bne	a0,a5,80005cde <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005c38:	04491703          	lh	a4,68(s2)
    80005c3c:	4785                	li	a5,1
    80005c3e:	0af70863          	beq	a4,a5,80005cee <sys_unlink+0x18c>
  iunlockput(dp);
    80005c42:	8526                	mv	a0,s1
    80005c44:	ffffe097          	auipc	ra,0xffffe
    80005c48:	3b0080e7          	jalr	944(ra) # 80003ff4 <iunlockput>
  ip->nlink--;
    80005c4c:	04a95783          	lhu	a5,74(s2)
    80005c50:	37fd                	addiw	a5,a5,-1
    80005c52:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005c56:	854a                	mv	a0,s2
    80005c58:	ffffe097          	auipc	ra,0xffffe
    80005c5c:	070080e7          	jalr	112(ra) # 80003cc8 <iupdate>
  iunlockput(ip);
    80005c60:	854a                	mv	a0,s2
    80005c62:	ffffe097          	auipc	ra,0xffffe
    80005c66:	392080e7          	jalr	914(ra) # 80003ff4 <iunlockput>
  end_op();
    80005c6a:	fffff097          	auipc	ra,0xfffff
    80005c6e:	b6a080e7          	jalr	-1174(ra) # 800047d4 <end_op>
  return 0;
    80005c72:	4501                	li	a0,0
    80005c74:	a84d                	j	80005d26 <sys_unlink+0x1c4>
    end_op();
    80005c76:	fffff097          	auipc	ra,0xfffff
    80005c7a:	b5e080e7          	jalr	-1186(ra) # 800047d4 <end_op>
    return -1;
    80005c7e:	557d                	li	a0,-1
    80005c80:	a05d                	j	80005d26 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005c82:	00003517          	auipc	a0,0x3
    80005c86:	ae650513          	addi	a0,a0,-1306 # 80008768 <syscalls+0x2f8>
    80005c8a:	ffffb097          	auipc	ra,0xffffb
    80005c8e:	8b4080e7          	jalr	-1868(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c92:	04c92703          	lw	a4,76(s2)
    80005c96:	02000793          	li	a5,32
    80005c9a:	f6e7f9e3          	bgeu	a5,a4,80005c0c <sys_unlink+0xaa>
    80005c9e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005ca2:	4741                	li	a4,16
    80005ca4:	86ce                	mv	a3,s3
    80005ca6:	f1840613          	addi	a2,s0,-232
    80005caa:	4581                	li	a1,0
    80005cac:	854a                	mv	a0,s2
    80005cae:	ffffe097          	auipc	ra,0xffffe
    80005cb2:	398080e7          	jalr	920(ra) # 80004046 <readi>
    80005cb6:	47c1                	li	a5,16
    80005cb8:	00f51b63          	bne	a0,a5,80005cce <sys_unlink+0x16c>
    if(de.inum != 0)
    80005cbc:	f1845783          	lhu	a5,-232(s0)
    80005cc0:	e7a1                	bnez	a5,80005d08 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005cc2:	29c1                	addiw	s3,s3,16
    80005cc4:	04c92783          	lw	a5,76(s2)
    80005cc8:	fcf9ede3          	bltu	s3,a5,80005ca2 <sys_unlink+0x140>
    80005ccc:	b781                	j	80005c0c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005cce:	00003517          	auipc	a0,0x3
    80005cd2:	ab250513          	addi	a0,a0,-1358 # 80008780 <syscalls+0x310>
    80005cd6:	ffffb097          	auipc	ra,0xffffb
    80005cda:	868080e7          	jalr	-1944(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005cde:	00003517          	auipc	a0,0x3
    80005ce2:	aba50513          	addi	a0,a0,-1350 # 80008798 <syscalls+0x328>
    80005ce6:	ffffb097          	auipc	ra,0xffffb
    80005cea:	858080e7          	jalr	-1960(ra) # 8000053e <panic>
    dp->nlink--;
    80005cee:	04a4d783          	lhu	a5,74(s1)
    80005cf2:	37fd                	addiw	a5,a5,-1
    80005cf4:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005cf8:	8526                	mv	a0,s1
    80005cfa:	ffffe097          	auipc	ra,0xffffe
    80005cfe:	fce080e7          	jalr	-50(ra) # 80003cc8 <iupdate>
    80005d02:	b781                	j	80005c42 <sys_unlink+0xe0>
    return -1;
    80005d04:	557d                	li	a0,-1
    80005d06:	a005                	j	80005d26 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005d08:	854a                	mv	a0,s2
    80005d0a:	ffffe097          	auipc	ra,0xffffe
    80005d0e:	2ea080e7          	jalr	746(ra) # 80003ff4 <iunlockput>
  iunlockput(dp);
    80005d12:	8526                	mv	a0,s1
    80005d14:	ffffe097          	auipc	ra,0xffffe
    80005d18:	2e0080e7          	jalr	736(ra) # 80003ff4 <iunlockput>
  end_op();
    80005d1c:	fffff097          	auipc	ra,0xfffff
    80005d20:	ab8080e7          	jalr	-1352(ra) # 800047d4 <end_op>
  return -1;
    80005d24:	557d                	li	a0,-1
}
    80005d26:	70ae                	ld	ra,232(sp)
    80005d28:	740e                	ld	s0,224(sp)
    80005d2a:	64ee                	ld	s1,216(sp)
    80005d2c:	694e                	ld	s2,208(sp)
    80005d2e:	69ae                	ld	s3,200(sp)
    80005d30:	616d                	addi	sp,sp,240
    80005d32:	8082                	ret

0000000080005d34 <sys_open>:

uint64
sys_open(void)
{
    80005d34:	7131                	addi	sp,sp,-192
    80005d36:	fd06                	sd	ra,184(sp)
    80005d38:	f922                	sd	s0,176(sp)
    80005d3a:	f526                	sd	s1,168(sp)
    80005d3c:	f14a                	sd	s2,160(sp)
    80005d3e:	ed4e                	sd	s3,152(sp)
    80005d40:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005d42:	f4c40593          	addi	a1,s0,-180
    80005d46:	4505                	li	a0,1
    80005d48:	ffffd097          	auipc	ra,0xffffd
    80005d4c:	1e2080e7          	jalr	482(ra) # 80002f2a <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005d50:	08000613          	li	a2,128
    80005d54:	f5040593          	addi	a1,s0,-176
    80005d58:	4501                	li	a0,0
    80005d5a:	ffffd097          	auipc	ra,0xffffd
    80005d5e:	210080e7          	jalr	528(ra) # 80002f6a <argstr>
    80005d62:	87aa                	mv	a5,a0
    return -1;
    80005d64:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005d66:	0a07c963          	bltz	a5,80005e18 <sys_open+0xe4>

  begin_op();
    80005d6a:	fffff097          	auipc	ra,0xfffff
    80005d6e:	9ea080e7          	jalr	-1558(ra) # 80004754 <begin_op>

  if(omode & O_CREATE){
    80005d72:	f4c42783          	lw	a5,-180(s0)
    80005d76:	2007f793          	andi	a5,a5,512
    80005d7a:	cfc5                	beqz	a5,80005e32 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005d7c:	4681                	li	a3,0
    80005d7e:	4601                	li	a2,0
    80005d80:	4589                	li	a1,2
    80005d82:	f5040513          	addi	a0,s0,-176
    80005d86:	00000097          	auipc	ra,0x0
    80005d8a:	976080e7          	jalr	-1674(ra) # 800056fc <create>
    80005d8e:	84aa                	mv	s1,a0
    if(ip == 0){
    80005d90:	c959                	beqz	a0,80005e26 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005d92:	04449703          	lh	a4,68(s1)
    80005d96:	478d                	li	a5,3
    80005d98:	00f71763          	bne	a4,a5,80005da6 <sys_open+0x72>
    80005d9c:	0464d703          	lhu	a4,70(s1)
    80005da0:	47a5                	li	a5,9
    80005da2:	0ce7ed63          	bltu	a5,a4,80005e7c <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005da6:	fffff097          	auipc	ra,0xfffff
    80005daa:	dbe080e7          	jalr	-578(ra) # 80004b64 <filealloc>
    80005dae:	89aa                	mv	s3,a0
    80005db0:	10050363          	beqz	a0,80005eb6 <sys_open+0x182>
    80005db4:	00000097          	auipc	ra,0x0
    80005db8:	906080e7          	jalr	-1786(ra) # 800056ba <fdalloc>
    80005dbc:	892a                	mv	s2,a0
    80005dbe:	0e054763          	bltz	a0,80005eac <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005dc2:	04449703          	lh	a4,68(s1)
    80005dc6:	478d                	li	a5,3
    80005dc8:	0cf70563          	beq	a4,a5,80005e92 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005dcc:	4789                	li	a5,2
    80005dce:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005dd2:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005dd6:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005dda:	f4c42783          	lw	a5,-180(s0)
    80005dde:	0017c713          	xori	a4,a5,1
    80005de2:	8b05                	andi	a4,a4,1
    80005de4:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005de8:	0037f713          	andi	a4,a5,3
    80005dec:	00e03733          	snez	a4,a4
    80005df0:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005df4:	4007f793          	andi	a5,a5,1024
    80005df8:	c791                	beqz	a5,80005e04 <sys_open+0xd0>
    80005dfa:	04449703          	lh	a4,68(s1)
    80005dfe:	4789                	li	a5,2
    80005e00:	0af70063          	beq	a4,a5,80005ea0 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005e04:	8526                	mv	a0,s1
    80005e06:	ffffe097          	auipc	ra,0xffffe
    80005e0a:	04e080e7          	jalr	78(ra) # 80003e54 <iunlock>
  end_op();
    80005e0e:	fffff097          	auipc	ra,0xfffff
    80005e12:	9c6080e7          	jalr	-1594(ra) # 800047d4 <end_op>

  return fd;
    80005e16:	854a                	mv	a0,s2
}
    80005e18:	70ea                	ld	ra,184(sp)
    80005e1a:	744a                	ld	s0,176(sp)
    80005e1c:	74aa                	ld	s1,168(sp)
    80005e1e:	790a                	ld	s2,160(sp)
    80005e20:	69ea                	ld	s3,152(sp)
    80005e22:	6129                	addi	sp,sp,192
    80005e24:	8082                	ret
      end_op();
    80005e26:	fffff097          	auipc	ra,0xfffff
    80005e2a:	9ae080e7          	jalr	-1618(ra) # 800047d4 <end_op>
      return -1;
    80005e2e:	557d                	li	a0,-1
    80005e30:	b7e5                	j	80005e18 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005e32:	f5040513          	addi	a0,s0,-176
    80005e36:	ffffe097          	auipc	ra,0xffffe
    80005e3a:	702080e7          	jalr	1794(ra) # 80004538 <namei>
    80005e3e:	84aa                	mv	s1,a0
    80005e40:	c905                	beqz	a0,80005e70 <sys_open+0x13c>
    ilock(ip);
    80005e42:	ffffe097          	auipc	ra,0xffffe
    80005e46:	f50080e7          	jalr	-176(ra) # 80003d92 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005e4a:	04449703          	lh	a4,68(s1)
    80005e4e:	4785                	li	a5,1
    80005e50:	f4f711e3          	bne	a4,a5,80005d92 <sys_open+0x5e>
    80005e54:	f4c42783          	lw	a5,-180(s0)
    80005e58:	d7b9                	beqz	a5,80005da6 <sys_open+0x72>
      iunlockput(ip);
    80005e5a:	8526                	mv	a0,s1
    80005e5c:	ffffe097          	auipc	ra,0xffffe
    80005e60:	198080e7          	jalr	408(ra) # 80003ff4 <iunlockput>
      end_op();
    80005e64:	fffff097          	auipc	ra,0xfffff
    80005e68:	970080e7          	jalr	-1680(ra) # 800047d4 <end_op>
      return -1;
    80005e6c:	557d                	li	a0,-1
    80005e6e:	b76d                	j	80005e18 <sys_open+0xe4>
      end_op();
    80005e70:	fffff097          	auipc	ra,0xfffff
    80005e74:	964080e7          	jalr	-1692(ra) # 800047d4 <end_op>
      return -1;
    80005e78:	557d                	li	a0,-1
    80005e7a:	bf79                	j	80005e18 <sys_open+0xe4>
    iunlockput(ip);
    80005e7c:	8526                	mv	a0,s1
    80005e7e:	ffffe097          	auipc	ra,0xffffe
    80005e82:	176080e7          	jalr	374(ra) # 80003ff4 <iunlockput>
    end_op();
    80005e86:	fffff097          	auipc	ra,0xfffff
    80005e8a:	94e080e7          	jalr	-1714(ra) # 800047d4 <end_op>
    return -1;
    80005e8e:	557d                	li	a0,-1
    80005e90:	b761                	j	80005e18 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005e92:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005e96:	04649783          	lh	a5,70(s1)
    80005e9a:	02f99223          	sh	a5,36(s3)
    80005e9e:	bf25                	j	80005dd6 <sys_open+0xa2>
    itrunc(ip);
    80005ea0:	8526                	mv	a0,s1
    80005ea2:	ffffe097          	auipc	ra,0xffffe
    80005ea6:	ffe080e7          	jalr	-2(ra) # 80003ea0 <itrunc>
    80005eaa:	bfa9                	j	80005e04 <sys_open+0xd0>
      fileclose(f);
    80005eac:	854e                	mv	a0,s3
    80005eae:	fffff097          	auipc	ra,0xfffff
    80005eb2:	d72080e7          	jalr	-654(ra) # 80004c20 <fileclose>
    iunlockput(ip);
    80005eb6:	8526                	mv	a0,s1
    80005eb8:	ffffe097          	auipc	ra,0xffffe
    80005ebc:	13c080e7          	jalr	316(ra) # 80003ff4 <iunlockput>
    end_op();
    80005ec0:	fffff097          	auipc	ra,0xfffff
    80005ec4:	914080e7          	jalr	-1772(ra) # 800047d4 <end_op>
    return -1;
    80005ec8:	557d                	li	a0,-1
    80005eca:	b7b9                	j	80005e18 <sys_open+0xe4>

0000000080005ecc <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005ecc:	7175                	addi	sp,sp,-144
    80005ece:	e506                	sd	ra,136(sp)
    80005ed0:	e122                	sd	s0,128(sp)
    80005ed2:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005ed4:	fffff097          	auipc	ra,0xfffff
    80005ed8:	880080e7          	jalr	-1920(ra) # 80004754 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005edc:	08000613          	li	a2,128
    80005ee0:	f7040593          	addi	a1,s0,-144
    80005ee4:	4501                	li	a0,0
    80005ee6:	ffffd097          	auipc	ra,0xffffd
    80005eea:	084080e7          	jalr	132(ra) # 80002f6a <argstr>
    80005eee:	02054963          	bltz	a0,80005f20 <sys_mkdir+0x54>
    80005ef2:	4681                	li	a3,0
    80005ef4:	4601                	li	a2,0
    80005ef6:	4585                	li	a1,1
    80005ef8:	f7040513          	addi	a0,s0,-144
    80005efc:	00000097          	auipc	ra,0x0
    80005f00:	800080e7          	jalr	-2048(ra) # 800056fc <create>
    80005f04:	cd11                	beqz	a0,80005f20 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f06:	ffffe097          	auipc	ra,0xffffe
    80005f0a:	0ee080e7          	jalr	238(ra) # 80003ff4 <iunlockput>
  end_op();
    80005f0e:	fffff097          	auipc	ra,0xfffff
    80005f12:	8c6080e7          	jalr	-1850(ra) # 800047d4 <end_op>
  return 0;
    80005f16:	4501                	li	a0,0
}
    80005f18:	60aa                	ld	ra,136(sp)
    80005f1a:	640a                	ld	s0,128(sp)
    80005f1c:	6149                	addi	sp,sp,144
    80005f1e:	8082                	ret
    end_op();
    80005f20:	fffff097          	auipc	ra,0xfffff
    80005f24:	8b4080e7          	jalr	-1868(ra) # 800047d4 <end_op>
    return -1;
    80005f28:	557d                	li	a0,-1
    80005f2a:	b7fd                	j	80005f18 <sys_mkdir+0x4c>

0000000080005f2c <sys_mknod>:

uint64
sys_mknod(void)
{
    80005f2c:	7135                	addi	sp,sp,-160
    80005f2e:	ed06                	sd	ra,152(sp)
    80005f30:	e922                	sd	s0,144(sp)
    80005f32:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005f34:	fffff097          	auipc	ra,0xfffff
    80005f38:	820080e7          	jalr	-2016(ra) # 80004754 <begin_op>
  argint(1, &major);
    80005f3c:	f6c40593          	addi	a1,s0,-148
    80005f40:	4505                	li	a0,1
    80005f42:	ffffd097          	auipc	ra,0xffffd
    80005f46:	fe8080e7          	jalr	-24(ra) # 80002f2a <argint>
  argint(2, &minor);
    80005f4a:	f6840593          	addi	a1,s0,-152
    80005f4e:	4509                	li	a0,2
    80005f50:	ffffd097          	auipc	ra,0xffffd
    80005f54:	fda080e7          	jalr	-38(ra) # 80002f2a <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f58:	08000613          	li	a2,128
    80005f5c:	f7040593          	addi	a1,s0,-144
    80005f60:	4501                	li	a0,0
    80005f62:	ffffd097          	auipc	ra,0xffffd
    80005f66:	008080e7          	jalr	8(ra) # 80002f6a <argstr>
    80005f6a:	02054b63          	bltz	a0,80005fa0 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005f6e:	f6841683          	lh	a3,-152(s0)
    80005f72:	f6c41603          	lh	a2,-148(s0)
    80005f76:	458d                	li	a1,3
    80005f78:	f7040513          	addi	a0,s0,-144
    80005f7c:	fffff097          	auipc	ra,0xfffff
    80005f80:	780080e7          	jalr	1920(ra) # 800056fc <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f84:	cd11                	beqz	a0,80005fa0 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f86:	ffffe097          	auipc	ra,0xffffe
    80005f8a:	06e080e7          	jalr	110(ra) # 80003ff4 <iunlockput>
  end_op();
    80005f8e:	fffff097          	auipc	ra,0xfffff
    80005f92:	846080e7          	jalr	-1978(ra) # 800047d4 <end_op>
  return 0;
    80005f96:	4501                	li	a0,0
}
    80005f98:	60ea                	ld	ra,152(sp)
    80005f9a:	644a                	ld	s0,144(sp)
    80005f9c:	610d                	addi	sp,sp,160
    80005f9e:	8082                	ret
    end_op();
    80005fa0:	fffff097          	auipc	ra,0xfffff
    80005fa4:	834080e7          	jalr	-1996(ra) # 800047d4 <end_op>
    return -1;
    80005fa8:	557d                	li	a0,-1
    80005faa:	b7fd                	j	80005f98 <sys_mknod+0x6c>

0000000080005fac <sys_chdir>:

uint64
sys_chdir(void)
{
    80005fac:	7135                	addi	sp,sp,-160
    80005fae:	ed06                	sd	ra,152(sp)
    80005fb0:	e922                	sd	s0,144(sp)
    80005fb2:	e526                	sd	s1,136(sp)
    80005fb4:	e14a                	sd	s2,128(sp)
    80005fb6:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005fb8:	ffffc097          	auipc	ra,0xffffc
    80005fbc:	a24080e7          	jalr	-1500(ra) # 800019dc <myproc>
    80005fc0:	892a                	mv	s2,a0
  
  begin_op();
    80005fc2:	ffffe097          	auipc	ra,0xffffe
    80005fc6:	792080e7          	jalr	1938(ra) # 80004754 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005fca:	08000613          	li	a2,128
    80005fce:	f6040593          	addi	a1,s0,-160
    80005fd2:	4501                	li	a0,0
    80005fd4:	ffffd097          	auipc	ra,0xffffd
    80005fd8:	f96080e7          	jalr	-106(ra) # 80002f6a <argstr>
    80005fdc:	04054b63          	bltz	a0,80006032 <sys_chdir+0x86>
    80005fe0:	f6040513          	addi	a0,s0,-160
    80005fe4:	ffffe097          	auipc	ra,0xffffe
    80005fe8:	554080e7          	jalr	1364(ra) # 80004538 <namei>
    80005fec:	84aa                	mv	s1,a0
    80005fee:	c131                	beqz	a0,80006032 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005ff0:	ffffe097          	auipc	ra,0xffffe
    80005ff4:	da2080e7          	jalr	-606(ra) # 80003d92 <ilock>
  if(ip->type != T_DIR){
    80005ff8:	04449703          	lh	a4,68(s1)
    80005ffc:	4785                	li	a5,1
    80005ffe:	04f71063          	bne	a4,a5,8000603e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006002:	8526                	mv	a0,s1
    80006004:	ffffe097          	auipc	ra,0xffffe
    80006008:	e50080e7          	jalr	-432(ra) # 80003e54 <iunlock>
  iput(p->cwd);
    8000600c:	15093503          	ld	a0,336(s2)
    80006010:	ffffe097          	auipc	ra,0xffffe
    80006014:	f3c080e7          	jalr	-196(ra) # 80003f4c <iput>
  end_op();
    80006018:	ffffe097          	auipc	ra,0xffffe
    8000601c:	7bc080e7          	jalr	1980(ra) # 800047d4 <end_op>
  p->cwd = ip;
    80006020:	14993823          	sd	s1,336(s2)
  return 0;
    80006024:	4501                	li	a0,0
}
    80006026:	60ea                	ld	ra,152(sp)
    80006028:	644a                	ld	s0,144(sp)
    8000602a:	64aa                	ld	s1,136(sp)
    8000602c:	690a                	ld	s2,128(sp)
    8000602e:	610d                	addi	sp,sp,160
    80006030:	8082                	ret
    end_op();
    80006032:	ffffe097          	auipc	ra,0xffffe
    80006036:	7a2080e7          	jalr	1954(ra) # 800047d4 <end_op>
    return -1;
    8000603a:	557d                	li	a0,-1
    8000603c:	b7ed                	j	80006026 <sys_chdir+0x7a>
    iunlockput(ip);
    8000603e:	8526                	mv	a0,s1
    80006040:	ffffe097          	auipc	ra,0xffffe
    80006044:	fb4080e7          	jalr	-76(ra) # 80003ff4 <iunlockput>
    end_op();
    80006048:	ffffe097          	auipc	ra,0xffffe
    8000604c:	78c080e7          	jalr	1932(ra) # 800047d4 <end_op>
    return -1;
    80006050:	557d                	li	a0,-1
    80006052:	bfd1                	j	80006026 <sys_chdir+0x7a>

0000000080006054 <sys_exec>:

uint64
sys_exec(void)
{
    80006054:	7145                	addi	sp,sp,-464
    80006056:	e786                	sd	ra,456(sp)
    80006058:	e3a2                	sd	s0,448(sp)
    8000605a:	ff26                	sd	s1,440(sp)
    8000605c:	fb4a                	sd	s2,432(sp)
    8000605e:	f74e                	sd	s3,424(sp)
    80006060:	f352                	sd	s4,416(sp)
    80006062:	ef56                	sd	s5,408(sp)
    80006064:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80006066:	e3840593          	addi	a1,s0,-456
    8000606a:	4505                	li	a0,1
    8000606c:	ffffd097          	auipc	ra,0xffffd
    80006070:	ede080e7          	jalr	-290(ra) # 80002f4a <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80006074:	08000613          	li	a2,128
    80006078:	f4040593          	addi	a1,s0,-192
    8000607c:	4501                	li	a0,0
    8000607e:	ffffd097          	auipc	ra,0xffffd
    80006082:	eec080e7          	jalr	-276(ra) # 80002f6a <argstr>
    80006086:	87aa                	mv	a5,a0
    return -1;
    80006088:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    8000608a:	0c07c263          	bltz	a5,8000614e <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    8000608e:	10000613          	li	a2,256
    80006092:	4581                	li	a1,0
    80006094:	e4040513          	addi	a0,s0,-448
    80006098:	ffffb097          	auipc	ra,0xffffb
    8000609c:	c3a080e7          	jalr	-966(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800060a0:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800060a4:	89a6                	mv	s3,s1
    800060a6:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800060a8:	02000a13          	li	s4,32
    800060ac:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800060b0:	00391793          	slli	a5,s2,0x3
    800060b4:	e3040593          	addi	a1,s0,-464
    800060b8:	e3843503          	ld	a0,-456(s0)
    800060bc:	953e                	add	a0,a0,a5
    800060be:	ffffd097          	auipc	ra,0xffffd
    800060c2:	dce080e7          	jalr	-562(ra) # 80002e8c <fetchaddr>
    800060c6:	02054a63          	bltz	a0,800060fa <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    800060ca:	e3043783          	ld	a5,-464(s0)
    800060ce:	c3b9                	beqz	a5,80006114 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800060d0:	ffffb097          	auipc	ra,0xffffb
    800060d4:	a16080e7          	jalr	-1514(ra) # 80000ae6 <kalloc>
    800060d8:	85aa                	mv	a1,a0
    800060da:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800060de:	cd11                	beqz	a0,800060fa <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800060e0:	6605                	lui	a2,0x1
    800060e2:	e3043503          	ld	a0,-464(s0)
    800060e6:	ffffd097          	auipc	ra,0xffffd
    800060ea:	df8080e7          	jalr	-520(ra) # 80002ede <fetchstr>
    800060ee:	00054663          	bltz	a0,800060fa <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    800060f2:	0905                	addi	s2,s2,1
    800060f4:	09a1                	addi	s3,s3,8
    800060f6:	fb491be3          	bne	s2,s4,800060ac <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060fa:	10048913          	addi	s2,s1,256
    800060fe:	6088                	ld	a0,0(s1)
    80006100:	c531                	beqz	a0,8000614c <sys_exec+0xf8>
    kfree(argv[i]);
    80006102:	ffffb097          	auipc	ra,0xffffb
    80006106:	8e8080e7          	jalr	-1816(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000610a:	04a1                	addi	s1,s1,8
    8000610c:	ff2499e3          	bne	s1,s2,800060fe <sys_exec+0xaa>
  return -1;
    80006110:	557d                	li	a0,-1
    80006112:	a835                	j	8000614e <sys_exec+0xfa>
      argv[i] = 0;
    80006114:	0a8e                	slli	s5,s5,0x3
    80006116:	fc040793          	addi	a5,s0,-64
    8000611a:	9abe                	add	s5,s5,a5
    8000611c:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006120:	e4040593          	addi	a1,s0,-448
    80006124:	f4040513          	addi	a0,s0,-192
    80006128:	fffff097          	auipc	ra,0xfffff
    8000612c:	172080e7          	jalr	370(ra) # 8000529a <exec>
    80006130:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006132:	10048993          	addi	s3,s1,256
    80006136:	6088                	ld	a0,0(s1)
    80006138:	c901                	beqz	a0,80006148 <sys_exec+0xf4>
    kfree(argv[i]);
    8000613a:	ffffb097          	auipc	ra,0xffffb
    8000613e:	8b0080e7          	jalr	-1872(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006142:	04a1                	addi	s1,s1,8
    80006144:	ff3499e3          	bne	s1,s3,80006136 <sys_exec+0xe2>
  return ret;
    80006148:	854a                	mv	a0,s2
    8000614a:	a011                	j	8000614e <sys_exec+0xfa>
  return -1;
    8000614c:	557d                	li	a0,-1
}
    8000614e:	60be                	ld	ra,456(sp)
    80006150:	641e                	ld	s0,448(sp)
    80006152:	74fa                	ld	s1,440(sp)
    80006154:	795a                	ld	s2,432(sp)
    80006156:	79ba                	ld	s3,424(sp)
    80006158:	7a1a                	ld	s4,416(sp)
    8000615a:	6afa                	ld	s5,408(sp)
    8000615c:	6179                	addi	sp,sp,464
    8000615e:	8082                	ret

0000000080006160 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006160:	7139                	addi	sp,sp,-64
    80006162:	fc06                	sd	ra,56(sp)
    80006164:	f822                	sd	s0,48(sp)
    80006166:	f426                	sd	s1,40(sp)
    80006168:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000616a:	ffffc097          	auipc	ra,0xffffc
    8000616e:	872080e7          	jalr	-1934(ra) # 800019dc <myproc>
    80006172:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80006174:	fd840593          	addi	a1,s0,-40
    80006178:	4501                	li	a0,0
    8000617a:	ffffd097          	auipc	ra,0xffffd
    8000617e:	dd0080e7          	jalr	-560(ra) # 80002f4a <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80006182:	fc840593          	addi	a1,s0,-56
    80006186:	fd040513          	addi	a0,s0,-48
    8000618a:	fffff097          	auipc	ra,0xfffff
    8000618e:	dc6080e7          	jalr	-570(ra) # 80004f50 <pipealloc>
    return -1;
    80006192:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006194:	0c054463          	bltz	a0,8000625c <sys_pipe+0xfc>
  fd0 = -1;
    80006198:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000619c:	fd043503          	ld	a0,-48(s0)
    800061a0:	fffff097          	auipc	ra,0xfffff
    800061a4:	51a080e7          	jalr	1306(ra) # 800056ba <fdalloc>
    800061a8:	fca42223          	sw	a0,-60(s0)
    800061ac:	08054b63          	bltz	a0,80006242 <sys_pipe+0xe2>
    800061b0:	fc843503          	ld	a0,-56(s0)
    800061b4:	fffff097          	auipc	ra,0xfffff
    800061b8:	506080e7          	jalr	1286(ra) # 800056ba <fdalloc>
    800061bc:	fca42023          	sw	a0,-64(s0)
    800061c0:	06054863          	bltz	a0,80006230 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800061c4:	4691                	li	a3,4
    800061c6:	fc440613          	addi	a2,s0,-60
    800061ca:	fd843583          	ld	a1,-40(s0)
    800061ce:	68a8                	ld	a0,80(s1)
    800061d0:	ffffb097          	auipc	ra,0xffffb
    800061d4:	4b0080e7          	jalr	1200(ra) # 80001680 <copyout>
    800061d8:	02054063          	bltz	a0,800061f8 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800061dc:	4691                	li	a3,4
    800061de:	fc040613          	addi	a2,s0,-64
    800061e2:	fd843583          	ld	a1,-40(s0)
    800061e6:	0591                	addi	a1,a1,4
    800061e8:	68a8                	ld	a0,80(s1)
    800061ea:	ffffb097          	auipc	ra,0xffffb
    800061ee:	496080e7          	jalr	1174(ra) # 80001680 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800061f2:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800061f4:	06055463          	bgez	a0,8000625c <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    800061f8:	fc442783          	lw	a5,-60(s0)
    800061fc:	07e9                	addi	a5,a5,26
    800061fe:	078e                	slli	a5,a5,0x3
    80006200:	97a6                	add	a5,a5,s1
    80006202:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006206:	fc042503          	lw	a0,-64(s0)
    8000620a:	0569                	addi	a0,a0,26
    8000620c:	050e                	slli	a0,a0,0x3
    8000620e:	94aa                	add	s1,s1,a0
    80006210:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006214:	fd043503          	ld	a0,-48(s0)
    80006218:	fffff097          	auipc	ra,0xfffff
    8000621c:	a08080e7          	jalr	-1528(ra) # 80004c20 <fileclose>
    fileclose(wf);
    80006220:	fc843503          	ld	a0,-56(s0)
    80006224:	fffff097          	auipc	ra,0xfffff
    80006228:	9fc080e7          	jalr	-1540(ra) # 80004c20 <fileclose>
    return -1;
    8000622c:	57fd                	li	a5,-1
    8000622e:	a03d                	j	8000625c <sys_pipe+0xfc>
    if(fd0 >= 0)
    80006230:	fc442783          	lw	a5,-60(s0)
    80006234:	0007c763          	bltz	a5,80006242 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80006238:	07e9                	addi	a5,a5,26
    8000623a:	078e                	slli	a5,a5,0x3
    8000623c:	94be                	add	s1,s1,a5
    8000623e:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006242:	fd043503          	ld	a0,-48(s0)
    80006246:	fffff097          	auipc	ra,0xfffff
    8000624a:	9da080e7          	jalr	-1574(ra) # 80004c20 <fileclose>
    fileclose(wf);
    8000624e:	fc843503          	ld	a0,-56(s0)
    80006252:	fffff097          	auipc	ra,0xfffff
    80006256:	9ce080e7          	jalr	-1586(ra) # 80004c20 <fileclose>
    return -1;
    8000625a:	57fd                	li	a5,-1
}
    8000625c:	853e                	mv	a0,a5
    8000625e:	70e2                	ld	ra,56(sp)
    80006260:	7442                	ld	s0,48(sp)
    80006262:	74a2                	ld	s1,40(sp)
    80006264:	6121                	addi	sp,sp,64
    80006266:	8082                	ret
	...

0000000080006270 <kernelvec>:
    80006270:	7111                	addi	sp,sp,-256
    80006272:	e006                	sd	ra,0(sp)
    80006274:	e40a                	sd	sp,8(sp)
    80006276:	e80e                	sd	gp,16(sp)
    80006278:	ec12                	sd	tp,24(sp)
    8000627a:	f016                	sd	t0,32(sp)
    8000627c:	f41a                	sd	t1,40(sp)
    8000627e:	f81e                	sd	t2,48(sp)
    80006280:	fc22                	sd	s0,56(sp)
    80006282:	e0a6                	sd	s1,64(sp)
    80006284:	e4aa                	sd	a0,72(sp)
    80006286:	e8ae                	sd	a1,80(sp)
    80006288:	ecb2                	sd	a2,88(sp)
    8000628a:	f0b6                	sd	a3,96(sp)
    8000628c:	f4ba                	sd	a4,104(sp)
    8000628e:	f8be                	sd	a5,112(sp)
    80006290:	fcc2                	sd	a6,120(sp)
    80006292:	e146                	sd	a7,128(sp)
    80006294:	e54a                	sd	s2,136(sp)
    80006296:	e94e                	sd	s3,144(sp)
    80006298:	ed52                	sd	s4,152(sp)
    8000629a:	f156                	sd	s5,160(sp)
    8000629c:	f55a                	sd	s6,168(sp)
    8000629e:	f95e                	sd	s7,176(sp)
    800062a0:	fd62                	sd	s8,184(sp)
    800062a2:	e1e6                	sd	s9,192(sp)
    800062a4:	e5ea                	sd	s10,200(sp)
    800062a6:	e9ee                	sd	s11,208(sp)
    800062a8:	edf2                	sd	t3,216(sp)
    800062aa:	f1f6                	sd	t4,224(sp)
    800062ac:	f5fa                	sd	t5,232(sp)
    800062ae:	f9fe                	sd	t6,240(sp)
    800062b0:	aa9fc0ef          	jal	ra,80002d58 <kerneltrap>
    800062b4:	6082                	ld	ra,0(sp)
    800062b6:	6122                	ld	sp,8(sp)
    800062b8:	61c2                	ld	gp,16(sp)
    800062ba:	7282                	ld	t0,32(sp)
    800062bc:	7322                	ld	t1,40(sp)
    800062be:	73c2                	ld	t2,48(sp)
    800062c0:	7462                	ld	s0,56(sp)
    800062c2:	6486                	ld	s1,64(sp)
    800062c4:	6526                	ld	a0,72(sp)
    800062c6:	65c6                	ld	a1,80(sp)
    800062c8:	6666                	ld	a2,88(sp)
    800062ca:	7686                	ld	a3,96(sp)
    800062cc:	7726                	ld	a4,104(sp)
    800062ce:	77c6                	ld	a5,112(sp)
    800062d0:	7866                	ld	a6,120(sp)
    800062d2:	688a                	ld	a7,128(sp)
    800062d4:	692a                	ld	s2,136(sp)
    800062d6:	69ca                	ld	s3,144(sp)
    800062d8:	6a6a                	ld	s4,152(sp)
    800062da:	7a8a                	ld	s5,160(sp)
    800062dc:	7b2a                	ld	s6,168(sp)
    800062de:	7bca                	ld	s7,176(sp)
    800062e0:	7c6a                	ld	s8,184(sp)
    800062e2:	6c8e                	ld	s9,192(sp)
    800062e4:	6d2e                	ld	s10,200(sp)
    800062e6:	6dce                	ld	s11,208(sp)
    800062e8:	6e6e                	ld	t3,216(sp)
    800062ea:	7e8e                	ld	t4,224(sp)
    800062ec:	7f2e                	ld	t5,232(sp)
    800062ee:	7fce                	ld	t6,240(sp)
    800062f0:	6111                	addi	sp,sp,256
    800062f2:	10200073          	sret
    800062f6:	00000013          	nop
    800062fa:	00000013          	nop
    800062fe:	0001                	nop

0000000080006300 <timervec>:
    80006300:	34051573          	csrrw	a0,mscratch,a0
    80006304:	e10c                	sd	a1,0(a0)
    80006306:	e510                	sd	a2,8(a0)
    80006308:	e914                	sd	a3,16(a0)
    8000630a:	6d0c                	ld	a1,24(a0)
    8000630c:	7110                	ld	a2,32(a0)
    8000630e:	6194                	ld	a3,0(a1)
    80006310:	96b2                	add	a3,a3,a2
    80006312:	e194                	sd	a3,0(a1)
    80006314:	4589                	li	a1,2
    80006316:	14459073          	csrw	sip,a1
    8000631a:	6914                	ld	a3,16(a0)
    8000631c:	6510                	ld	a2,8(a0)
    8000631e:	610c                	ld	a1,0(a0)
    80006320:	34051573          	csrrw	a0,mscratch,a0
    80006324:	30200073          	mret
	...

000000008000632a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000632a:	1141                	addi	sp,sp,-16
    8000632c:	e422                	sd	s0,8(sp)
    8000632e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006330:	0c0007b7          	lui	a5,0xc000
    80006334:	4705                	li	a4,1
    80006336:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006338:	c3d8                	sw	a4,4(a5)
}
    8000633a:	6422                	ld	s0,8(sp)
    8000633c:	0141                	addi	sp,sp,16
    8000633e:	8082                	ret

0000000080006340 <plicinithart>:

void
plicinithart(void)
{
    80006340:	1141                	addi	sp,sp,-16
    80006342:	e406                	sd	ra,8(sp)
    80006344:	e022                	sd	s0,0(sp)
    80006346:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006348:	ffffb097          	auipc	ra,0xffffb
    8000634c:	668080e7          	jalr	1640(ra) # 800019b0 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006350:	0085171b          	slliw	a4,a0,0x8
    80006354:	0c0027b7          	lui	a5,0xc002
    80006358:	97ba                	add	a5,a5,a4
    8000635a:	40200713          	li	a4,1026
    8000635e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006362:	00d5151b          	slliw	a0,a0,0xd
    80006366:	0c2017b7          	lui	a5,0xc201
    8000636a:	953e                	add	a0,a0,a5
    8000636c:	00052023          	sw	zero,0(a0)
}
    80006370:	60a2                	ld	ra,8(sp)
    80006372:	6402                	ld	s0,0(sp)
    80006374:	0141                	addi	sp,sp,16
    80006376:	8082                	ret

0000000080006378 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006378:	1141                	addi	sp,sp,-16
    8000637a:	e406                	sd	ra,8(sp)
    8000637c:	e022                	sd	s0,0(sp)
    8000637e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006380:	ffffb097          	auipc	ra,0xffffb
    80006384:	630080e7          	jalr	1584(ra) # 800019b0 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006388:	00d5179b          	slliw	a5,a0,0xd
    8000638c:	0c201537          	lui	a0,0xc201
    80006390:	953e                	add	a0,a0,a5
  return irq;
}
    80006392:	4148                	lw	a0,4(a0)
    80006394:	60a2                	ld	ra,8(sp)
    80006396:	6402                	ld	s0,0(sp)
    80006398:	0141                	addi	sp,sp,16
    8000639a:	8082                	ret

000000008000639c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000639c:	1101                	addi	sp,sp,-32
    8000639e:	ec06                	sd	ra,24(sp)
    800063a0:	e822                	sd	s0,16(sp)
    800063a2:	e426                	sd	s1,8(sp)
    800063a4:	1000                	addi	s0,sp,32
    800063a6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800063a8:	ffffb097          	auipc	ra,0xffffb
    800063ac:	608080e7          	jalr	1544(ra) # 800019b0 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800063b0:	00d5151b          	slliw	a0,a0,0xd
    800063b4:	0c2017b7          	lui	a5,0xc201
    800063b8:	97aa                	add	a5,a5,a0
    800063ba:	c3c4                	sw	s1,4(a5)
}
    800063bc:	60e2                	ld	ra,24(sp)
    800063be:	6442                	ld	s0,16(sp)
    800063c0:	64a2                	ld	s1,8(sp)
    800063c2:	6105                	addi	sp,sp,32
    800063c4:	8082                	ret

00000000800063c6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800063c6:	1141                	addi	sp,sp,-16
    800063c8:	e406                	sd	ra,8(sp)
    800063ca:	e022                	sd	s0,0(sp)
    800063cc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800063ce:	479d                	li	a5,7
    800063d0:	04a7cc63          	blt	a5,a0,80006428 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    800063d4:	0001c797          	auipc	a5,0x1c
    800063d8:	adc78793          	addi	a5,a5,-1316 # 80021eb0 <disk>
    800063dc:	97aa                	add	a5,a5,a0
    800063de:	0187c783          	lbu	a5,24(a5)
    800063e2:	ebb9                	bnez	a5,80006438 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800063e4:	00451613          	slli	a2,a0,0x4
    800063e8:	0001c797          	auipc	a5,0x1c
    800063ec:	ac878793          	addi	a5,a5,-1336 # 80021eb0 <disk>
    800063f0:	6394                	ld	a3,0(a5)
    800063f2:	96b2                	add	a3,a3,a2
    800063f4:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800063f8:	6398                	ld	a4,0(a5)
    800063fa:	9732                	add	a4,a4,a2
    800063fc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006400:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006404:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006408:	953e                	add	a0,a0,a5
    8000640a:	4785                	li	a5,1
    8000640c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80006410:	0001c517          	auipc	a0,0x1c
    80006414:	ab850513          	addi	a0,a0,-1352 # 80021ec8 <disk+0x18>
    80006418:	ffffc097          	auipc	ra,0xffffc
    8000641c:	cf2080e7          	jalr	-782(ra) # 8000210a <wakeup>
}
    80006420:	60a2                	ld	ra,8(sp)
    80006422:	6402                	ld	s0,0(sp)
    80006424:	0141                	addi	sp,sp,16
    80006426:	8082                	ret
    panic("free_desc 1");
    80006428:	00002517          	auipc	a0,0x2
    8000642c:	38050513          	addi	a0,a0,896 # 800087a8 <syscalls+0x338>
    80006430:	ffffa097          	auipc	ra,0xffffa
    80006434:	10e080e7          	jalr	270(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006438:	00002517          	auipc	a0,0x2
    8000643c:	38050513          	addi	a0,a0,896 # 800087b8 <syscalls+0x348>
    80006440:	ffffa097          	auipc	ra,0xffffa
    80006444:	0fe080e7          	jalr	254(ra) # 8000053e <panic>

0000000080006448 <virtio_disk_init>:
{
    80006448:	1101                	addi	sp,sp,-32
    8000644a:	ec06                	sd	ra,24(sp)
    8000644c:	e822                	sd	s0,16(sp)
    8000644e:	e426                	sd	s1,8(sp)
    80006450:	e04a                	sd	s2,0(sp)
    80006452:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006454:	00002597          	auipc	a1,0x2
    80006458:	37458593          	addi	a1,a1,884 # 800087c8 <syscalls+0x358>
    8000645c:	0001c517          	auipc	a0,0x1c
    80006460:	b7c50513          	addi	a0,a0,-1156 # 80021fd8 <disk+0x128>
    80006464:	ffffa097          	auipc	ra,0xffffa
    80006468:	6e2080e7          	jalr	1762(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000646c:	100017b7          	lui	a5,0x10001
    80006470:	4398                	lw	a4,0(a5)
    80006472:	2701                	sext.w	a4,a4
    80006474:	747277b7          	lui	a5,0x74727
    80006478:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000647c:	14f71c63          	bne	a4,a5,800065d4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006480:	100017b7          	lui	a5,0x10001
    80006484:	43dc                	lw	a5,4(a5)
    80006486:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006488:	4709                	li	a4,2
    8000648a:	14e79563          	bne	a5,a4,800065d4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000648e:	100017b7          	lui	a5,0x10001
    80006492:	479c                	lw	a5,8(a5)
    80006494:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006496:	12e79f63          	bne	a5,a4,800065d4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000649a:	100017b7          	lui	a5,0x10001
    8000649e:	47d8                	lw	a4,12(a5)
    800064a0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064a2:	554d47b7          	lui	a5,0x554d4
    800064a6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800064aa:	12f71563          	bne	a4,a5,800065d4 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    800064ae:	100017b7          	lui	a5,0x10001
    800064b2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    800064b6:	4705                	li	a4,1
    800064b8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800064ba:	470d                	li	a4,3
    800064bc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800064be:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800064c0:	c7ffe737          	lui	a4,0xc7ffe
    800064c4:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc76f>
    800064c8:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800064ca:	2701                	sext.w	a4,a4
    800064cc:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800064ce:	472d                	li	a4,11
    800064d0:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800064d2:	5bbc                	lw	a5,112(a5)
    800064d4:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800064d8:	8ba1                	andi	a5,a5,8
    800064da:	10078563          	beqz	a5,800065e4 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800064de:	100017b7          	lui	a5,0x10001
    800064e2:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800064e6:	43fc                	lw	a5,68(a5)
    800064e8:	2781                	sext.w	a5,a5
    800064ea:	10079563          	bnez	a5,800065f4 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800064ee:	100017b7          	lui	a5,0x10001
    800064f2:	5bdc                	lw	a5,52(a5)
    800064f4:	2781                	sext.w	a5,a5
  if(max == 0)
    800064f6:	10078763          	beqz	a5,80006604 <virtio_disk_init+0x1bc>
  if(max < NUM)
    800064fa:	471d                	li	a4,7
    800064fc:	10f77c63          	bgeu	a4,a5,80006614 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    80006500:	ffffa097          	auipc	ra,0xffffa
    80006504:	5e6080e7          	jalr	1510(ra) # 80000ae6 <kalloc>
    80006508:	0001c497          	auipc	s1,0x1c
    8000650c:	9a848493          	addi	s1,s1,-1624 # 80021eb0 <disk>
    80006510:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006512:	ffffa097          	auipc	ra,0xffffa
    80006516:	5d4080e7          	jalr	1492(ra) # 80000ae6 <kalloc>
    8000651a:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000651c:	ffffa097          	auipc	ra,0xffffa
    80006520:	5ca080e7          	jalr	1482(ra) # 80000ae6 <kalloc>
    80006524:	87aa                	mv	a5,a0
    80006526:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006528:	6088                	ld	a0,0(s1)
    8000652a:	cd6d                	beqz	a0,80006624 <virtio_disk_init+0x1dc>
    8000652c:	0001c717          	auipc	a4,0x1c
    80006530:	98c73703          	ld	a4,-1652(a4) # 80021eb8 <disk+0x8>
    80006534:	cb65                	beqz	a4,80006624 <virtio_disk_init+0x1dc>
    80006536:	c7fd                	beqz	a5,80006624 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    80006538:	6605                	lui	a2,0x1
    8000653a:	4581                	li	a1,0
    8000653c:	ffffa097          	auipc	ra,0xffffa
    80006540:	796080e7          	jalr	1942(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006544:	0001c497          	auipc	s1,0x1c
    80006548:	96c48493          	addi	s1,s1,-1684 # 80021eb0 <disk>
    8000654c:	6605                	lui	a2,0x1
    8000654e:	4581                	li	a1,0
    80006550:	6488                	ld	a0,8(s1)
    80006552:	ffffa097          	auipc	ra,0xffffa
    80006556:	780080e7          	jalr	1920(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    8000655a:	6605                	lui	a2,0x1
    8000655c:	4581                	li	a1,0
    8000655e:	6888                	ld	a0,16(s1)
    80006560:	ffffa097          	auipc	ra,0xffffa
    80006564:	772080e7          	jalr	1906(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006568:	100017b7          	lui	a5,0x10001
    8000656c:	4721                	li	a4,8
    8000656e:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006570:	4098                	lw	a4,0(s1)
    80006572:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006576:	40d8                	lw	a4,4(s1)
    80006578:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000657c:	6498                	ld	a4,8(s1)
    8000657e:	0007069b          	sext.w	a3,a4
    80006582:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006586:	9701                	srai	a4,a4,0x20
    80006588:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000658c:	6898                	ld	a4,16(s1)
    8000658e:	0007069b          	sext.w	a3,a4
    80006592:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006596:	9701                	srai	a4,a4,0x20
    80006598:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000659c:	4705                	li	a4,1
    8000659e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800065a0:	00e48c23          	sb	a4,24(s1)
    800065a4:	00e48ca3          	sb	a4,25(s1)
    800065a8:	00e48d23          	sb	a4,26(s1)
    800065ac:	00e48da3          	sb	a4,27(s1)
    800065b0:	00e48e23          	sb	a4,28(s1)
    800065b4:	00e48ea3          	sb	a4,29(s1)
    800065b8:	00e48f23          	sb	a4,30(s1)
    800065bc:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800065c0:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800065c4:	0727a823          	sw	s2,112(a5)
}
    800065c8:	60e2                	ld	ra,24(sp)
    800065ca:	6442                	ld	s0,16(sp)
    800065cc:	64a2                	ld	s1,8(sp)
    800065ce:	6902                	ld	s2,0(sp)
    800065d0:	6105                	addi	sp,sp,32
    800065d2:	8082                	ret
    panic("could not find virtio disk");
    800065d4:	00002517          	auipc	a0,0x2
    800065d8:	20450513          	addi	a0,a0,516 # 800087d8 <syscalls+0x368>
    800065dc:	ffffa097          	auipc	ra,0xffffa
    800065e0:	f62080e7          	jalr	-158(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    800065e4:	00002517          	auipc	a0,0x2
    800065e8:	21450513          	addi	a0,a0,532 # 800087f8 <syscalls+0x388>
    800065ec:	ffffa097          	auipc	ra,0xffffa
    800065f0:	f52080e7          	jalr	-174(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    800065f4:	00002517          	auipc	a0,0x2
    800065f8:	22450513          	addi	a0,a0,548 # 80008818 <syscalls+0x3a8>
    800065fc:	ffffa097          	auipc	ra,0xffffa
    80006600:	f42080e7          	jalr	-190(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006604:	00002517          	auipc	a0,0x2
    80006608:	23450513          	addi	a0,a0,564 # 80008838 <syscalls+0x3c8>
    8000660c:	ffffa097          	auipc	ra,0xffffa
    80006610:	f32080e7          	jalr	-206(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006614:	00002517          	auipc	a0,0x2
    80006618:	24450513          	addi	a0,a0,580 # 80008858 <syscalls+0x3e8>
    8000661c:	ffffa097          	auipc	ra,0xffffa
    80006620:	f22080e7          	jalr	-222(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    80006624:	00002517          	auipc	a0,0x2
    80006628:	25450513          	addi	a0,a0,596 # 80008878 <syscalls+0x408>
    8000662c:	ffffa097          	auipc	ra,0xffffa
    80006630:	f12080e7          	jalr	-238(ra) # 8000053e <panic>

0000000080006634 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006634:	7119                	addi	sp,sp,-128
    80006636:	fc86                	sd	ra,120(sp)
    80006638:	f8a2                	sd	s0,112(sp)
    8000663a:	f4a6                	sd	s1,104(sp)
    8000663c:	f0ca                	sd	s2,96(sp)
    8000663e:	ecce                	sd	s3,88(sp)
    80006640:	e8d2                	sd	s4,80(sp)
    80006642:	e4d6                	sd	s5,72(sp)
    80006644:	e0da                	sd	s6,64(sp)
    80006646:	fc5e                	sd	s7,56(sp)
    80006648:	f862                	sd	s8,48(sp)
    8000664a:	f466                	sd	s9,40(sp)
    8000664c:	f06a                	sd	s10,32(sp)
    8000664e:	ec6e                	sd	s11,24(sp)
    80006650:	0100                	addi	s0,sp,128
    80006652:	8aaa                	mv	s5,a0
    80006654:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006656:	00c52d03          	lw	s10,12(a0)
    8000665a:	001d1d1b          	slliw	s10,s10,0x1
    8000665e:	1d02                	slli	s10,s10,0x20
    80006660:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006664:	0001c517          	auipc	a0,0x1c
    80006668:	97450513          	addi	a0,a0,-1676 # 80021fd8 <disk+0x128>
    8000666c:	ffffa097          	auipc	ra,0xffffa
    80006670:	56a080e7          	jalr	1386(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006674:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006676:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006678:	0001cb97          	auipc	s7,0x1c
    8000667c:	838b8b93          	addi	s7,s7,-1992 # 80021eb0 <disk>
  for(int i = 0; i < 3; i++){
    80006680:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006682:	0001cc97          	auipc	s9,0x1c
    80006686:	956c8c93          	addi	s9,s9,-1706 # 80021fd8 <disk+0x128>
    8000668a:	a08d                	j	800066ec <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000668c:	00fb8733          	add	a4,s7,a5
    80006690:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006694:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006696:	0207c563          	bltz	a5,800066c0 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000669a:	2905                	addiw	s2,s2,1
    8000669c:	0611                	addi	a2,a2,4
    8000669e:	05690c63          	beq	s2,s6,800066f6 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800066a2:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800066a4:	0001c717          	auipc	a4,0x1c
    800066a8:	80c70713          	addi	a4,a4,-2036 # 80021eb0 <disk>
    800066ac:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800066ae:	01874683          	lbu	a3,24(a4)
    800066b2:	fee9                	bnez	a3,8000668c <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800066b4:	2785                	addiw	a5,a5,1
    800066b6:	0705                	addi	a4,a4,1
    800066b8:	fe979be3          	bne	a5,s1,800066ae <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800066bc:	57fd                	li	a5,-1
    800066be:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800066c0:	01205d63          	blez	s2,800066da <virtio_disk_rw+0xa6>
    800066c4:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800066c6:	000a2503          	lw	a0,0(s4)
    800066ca:	00000097          	auipc	ra,0x0
    800066ce:	cfc080e7          	jalr	-772(ra) # 800063c6 <free_desc>
      for(int j = 0; j < i; j++)
    800066d2:	2d85                	addiw	s11,s11,1
    800066d4:	0a11                	addi	s4,s4,4
    800066d6:	ffb918e3          	bne	s2,s11,800066c6 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800066da:	85e6                	mv	a1,s9
    800066dc:	0001b517          	auipc	a0,0x1b
    800066e0:	7ec50513          	addi	a0,a0,2028 # 80021ec8 <disk+0x18>
    800066e4:	ffffc097          	auipc	ra,0xffffc
    800066e8:	9c2080e7          	jalr	-1598(ra) # 800020a6 <sleep>
  for(int i = 0; i < 3; i++){
    800066ec:	f8040a13          	addi	s4,s0,-128
{
    800066f0:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800066f2:	894e                	mv	s2,s3
    800066f4:	b77d                	j	800066a2 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800066f6:	f8042583          	lw	a1,-128(s0)
    800066fa:	00a58793          	addi	a5,a1,10
    800066fe:	0792                	slli	a5,a5,0x4

  if(write)
    80006700:	0001b617          	auipc	a2,0x1b
    80006704:	7b060613          	addi	a2,a2,1968 # 80021eb0 <disk>
    80006708:	00f60733          	add	a4,a2,a5
    8000670c:	018036b3          	snez	a3,s8
    80006710:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006712:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80006716:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    8000671a:	f6078693          	addi	a3,a5,-160
    8000671e:	6218                	ld	a4,0(a2)
    80006720:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006722:	00878513          	addi	a0,a5,8
    80006726:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006728:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000672a:	6208                	ld	a0,0(a2)
    8000672c:	96aa                	add	a3,a3,a0
    8000672e:	4741                	li	a4,16
    80006730:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006732:	4705                	li	a4,1
    80006734:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006738:	f8442703          	lw	a4,-124(s0)
    8000673c:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006740:	0712                	slli	a4,a4,0x4
    80006742:	953a                	add	a0,a0,a4
    80006744:	058a8693          	addi	a3,s5,88
    80006748:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000674a:	6208                	ld	a0,0(a2)
    8000674c:	972a                	add	a4,a4,a0
    8000674e:	40000693          	li	a3,1024
    80006752:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006754:	001c3c13          	seqz	s8,s8
    80006758:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000675a:	001c6c13          	ori	s8,s8,1
    8000675e:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006762:	f8842603          	lw	a2,-120(s0)
    80006766:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    8000676a:	0001b697          	auipc	a3,0x1b
    8000676e:	74668693          	addi	a3,a3,1862 # 80021eb0 <disk>
    80006772:	00258713          	addi	a4,a1,2
    80006776:	0712                	slli	a4,a4,0x4
    80006778:	9736                	add	a4,a4,a3
    8000677a:	587d                	li	a6,-1
    8000677c:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006780:	0612                	slli	a2,a2,0x4
    80006782:	9532                	add	a0,a0,a2
    80006784:	f9078793          	addi	a5,a5,-112
    80006788:	97b6                	add	a5,a5,a3
    8000678a:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    8000678c:	629c                	ld	a5,0(a3)
    8000678e:	97b2                	add	a5,a5,a2
    80006790:	4605                	li	a2,1
    80006792:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006794:	4509                	li	a0,2
    80006796:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    8000679a:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000679e:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800067a2:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800067a6:	6698                	ld	a4,8(a3)
    800067a8:	00275783          	lhu	a5,2(a4)
    800067ac:	8b9d                	andi	a5,a5,7
    800067ae:	0786                	slli	a5,a5,0x1
    800067b0:	97ba                	add	a5,a5,a4
    800067b2:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800067b6:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800067ba:	6698                	ld	a4,8(a3)
    800067bc:	00275783          	lhu	a5,2(a4)
    800067c0:	2785                	addiw	a5,a5,1
    800067c2:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800067c6:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800067ca:	100017b7          	lui	a5,0x10001
    800067ce:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800067d2:	004aa783          	lw	a5,4(s5)
    800067d6:	02c79163          	bne	a5,a2,800067f8 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800067da:	0001b917          	auipc	s2,0x1b
    800067de:	7fe90913          	addi	s2,s2,2046 # 80021fd8 <disk+0x128>
  while(b->disk == 1) {
    800067e2:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800067e4:	85ca                	mv	a1,s2
    800067e6:	8556                	mv	a0,s5
    800067e8:	ffffc097          	auipc	ra,0xffffc
    800067ec:	8be080e7          	jalr	-1858(ra) # 800020a6 <sleep>
  while(b->disk == 1) {
    800067f0:	004aa783          	lw	a5,4(s5)
    800067f4:	fe9788e3          	beq	a5,s1,800067e4 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800067f8:	f8042903          	lw	s2,-128(s0)
    800067fc:	00290793          	addi	a5,s2,2
    80006800:	00479713          	slli	a4,a5,0x4
    80006804:	0001b797          	auipc	a5,0x1b
    80006808:	6ac78793          	addi	a5,a5,1708 # 80021eb0 <disk>
    8000680c:	97ba                	add	a5,a5,a4
    8000680e:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006812:	0001b997          	auipc	s3,0x1b
    80006816:	69e98993          	addi	s3,s3,1694 # 80021eb0 <disk>
    8000681a:	00491713          	slli	a4,s2,0x4
    8000681e:	0009b783          	ld	a5,0(s3)
    80006822:	97ba                	add	a5,a5,a4
    80006824:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006828:	854a                	mv	a0,s2
    8000682a:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000682e:	00000097          	auipc	ra,0x0
    80006832:	b98080e7          	jalr	-1128(ra) # 800063c6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006836:	8885                	andi	s1,s1,1
    80006838:	f0ed                	bnez	s1,8000681a <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000683a:	0001b517          	auipc	a0,0x1b
    8000683e:	79e50513          	addi	a0,a0,1950 # 80021fd8 <disk+0x128>
    80006842:	ffffa097          	auipc	ra,0xffffa
    80006846:	448080e7          	jalr	1096(ra) # 80000c8a <release>
}
    8000684a:	70e6                	ld	ra,120(sp)
    8000684c:	7446                	ld	s0,112(sp)
    8000684e:	74a6                	ld	s1,104(sp)
    80006850:	7906                	ld	s2,96(sp)
    80006852:	69e6                	ld	s3,88(sp)
    80006854:	6a46                	ld	s4,80(sp)
    80006856:	6aa6                	ld	s5,72(sp)
    80006858:	6b06                	ld	s6,64(sp)
    8000685a:	7be2                	ld	s7,56(sp)
    8000685c:	7c42                	ld	s8,48(sp)
    8000685e:	7ca2                	ld	s9,40(sp)
    80006860:	7d02                	ld	s10,32(sp)
    80006862:	6de2                	ld	s11,24(sp)
    80006864:	6109                	addi	sp,sp,128
    80006866:	8082                	ret

0000000080006868 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006868:	1101                	addi	sp,sp,-32
    8000686a:	ec06                	sd	ra,24(sp)
    8000686c:	e822                	sd	s0,16(sp)
    8000686e:	e426                	sd	s1,8(sp)
    80006870:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006872:	0001b497          	auipc	s1,0x1b
    80006876:	63e48493          	addi	s1,s1,1598 # 80021eb0 <disk>
    8000687a:	0001b517          	auipc	a0,0x1b
    8000687e:	75e50513          	addi	a0,a0,1886 # 80021fd8 <disk+0x128>
    80006882:	ffffa097          	auipc	ra,0xffffa
    80006886:	354080e7          	jalr	852(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000688a:	10001737          	lui	a4,0x10001
    8000688e:	533c                	lw	a5,96(a4)
    80006890:	8b8d                	andi	a5,a5,3
    80006892:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006894:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006898:	689c                	ld	a5,16(s1)
    8000689a:	0204d703          	lhu	a4,32(s1)
    8000689e:	0027d783          	lhu	a5,2(a5)
    800068a2:	04f70863          	beq	a4,a5,800068f2 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800068a6:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800068aa:	6898                	ld	a4,16(s1)
    800068ac:	0204d783          	lhu	a5,32(s1)
    800068b0:	8b9d                	andi	a5,a5,7
    800068b2:	078e                	slli	a5,a5,0x3
    800068b4:	97ba                	add	a5,a5,a4
    800068b6:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800068b8:	00278713          	addi	a4,a5,2
    800068bc:	0712                	slli	a4,a4,0x4
    800068be:	9726                	add	a4,a4,s1
    800068c0:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800068c4:	e721                	bnez	a4,8000690c <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800068c6:	0789                	addi	a5,a5,2
    800068c8:	0792                	slli	a5,a5,0x4
    800068ca:	97a6                	add	a5,a5,s1
    800068cc:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800068ce:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800068d2:	ffffc097          	auipc	ra,0xffffc
    800068d6:	838080e7          	jalr	-1992(ra) # 8000210a <wakeup>

    disk.used_idx += 1;
    800068da:	0204d783          	lhu	a5,32(s1)
    800068de:	2785                	addiw	a5,a5,1
    800068e0:	17c2                	slli	a5,a5,0x30
    800068e2:	93c1                	srli	a5,a5,0x30
    800068e4:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800068e8:	6898                	ld	a4,16(s1)
    800068ea:	00275703          	lhu	a4,2(a4)
    800068ee:	faf71ce3          	bne	a4,a5,800068a6 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800068f2:	0001b517          	auipc	a0,0x1b
    800068f6:	6e650513          	addi	a0,a0,1766 # 80021fd8 <disk+0x128>
    800068fa:	ffffa097          	auipc	ra,0xffffa
    800068fe:	390080e7          	jalr	912(ra) # 80000c8a <release>
}
    80006902:	60e2                	ld	ra,24(sp)
    80006904:	6442                	ld	s0,16(sp)
    80006906:	64a2                	ld	s1,8(sp)
    80006908:	6105                	addi	sp,sp,32
    8000690a:	8082                	ret
      panic("virtio_disk_intr status");
    8000690c:	00002517          	auipc	a0,0x2
    80006910:	f8450513          	addi	a0,a0,-124 # 80008890 <syscalls+0x420>
    80006914:	ffffa097          	auipc	ra,0xffffa
    80006918:	c2a080e7          	jalr	-982(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
