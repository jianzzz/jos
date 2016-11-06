
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# 把[0,4MB)物理地址同时映射到线性地址[0, 4MB)和[KERNBASE, KERNBASE+4MB)中
	
	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	# 此时还没开启分页，需要RELOC将线性地址转化为物理地址
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 70 11 00       	mov    $0x117000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0
	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	# 线性地址[0, 4MB)和[KERNBASE, KERNBASE+4MB)同时映射到[0,4MB)物理地址
	# 如果不映射线性地址[0, 4MB)，则low eip的线性地址不在可访问线性地址范围内，将出现非法访问
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax # jmp 之后eip将会加上KERNBASE !!!
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp
	# (KSTKSIZE 在 inc/memlayout.h 中定义为 32k)，而 bootstacktop 则指向的是这段区域后的第
	# 一个字节，由于刚开始的时候堆栈是空的，所以栈顶便是 bootstacktop 所指向的位置，于是
	# 程序便将 bootstacktop 的值赋给了 esp 寄存器。

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 70 11 f0       	mov    $0xf0117000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 18             	sub    $0x18,%esp
	分便是 bss 节的部分，我们又知道 bss 节的内容是未初始化的变量，而这些变量是默认为零
	的，所以在一开始的时候程序要用 memset(edata, 0, end - edata)这句代码将这些变量都置为
	零。
	*/

	memset(edata, 0, end - edata);
f0100046:	b8 70 99 11 f0       	mov    $0xf0119970,%eax
f010004b:	2d 00 93 11 f0       	sub    $0xf0119300,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 00 93 11 f0 	movl   $0xf0119300,(%esp)
f0100063:	e8 9f 3f 00 00       	call   f0104007 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 c8 05 00 00       	call   f0100635 <cons_init>
 
	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 a0 44 10 f0 	movl   $0xf01044a0,(%esp)
f010007c:	e8 12 34 00 00       	call   f0103493 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 0b 18 00 00       	call   f0101891 <mem_init>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100086:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010008d:	e8 d2 0d 00 00       	call   f0100e64 <monitor>
f0100092:	eb f2                	jmp    f0100086 <i386_init+0x46>

f0100094 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	56                   	push   %esi
f0100098:	53                   	push   %ebx
f0100099:	83 ec 10             	sub    $0x10,%esp
f010009c:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f010009f:	83 3d 60 99 11 f0 00 	cmpl   $0x0,0xf0119960
f01000a6:	75 3d                	jne    f01000e5 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000a8:	89 35 60 99 11 f0    	mov    %esi,0xf0119960

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000ae:	fa                   	cli    
f01000af:	fc                   	cld    

	va_start(ap, fmt);
f01000b0:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000b3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000b6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01000bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000c1:	c7 04 24 bb 44 10 f0 	movl   $0xf01044bb,(%esp)
f01000c8:	e8 c6 33 00 00       	call   f0103493 <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 87 33 00 00       	call   f0103460 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 6c 47 10 f0 	movl   $0xf010476c,(%esp)
f01000e0:	e8 ae 33 00 00       	call   f0103493 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ec:	e8 73 0d 00 00       	call   f0100e64 <monitor>
f01000f1:	eb f2                	jmp    f01000e5 <_panic+0x51>

f01000f3 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f3:	55                   	push   %ebp
f01000f4:	89 e5                	mov    %esp,%ebp
f01000f6:	53                   	push   %ebx
f01000f7:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fa:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000fd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100100:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100104:	8b 45 08             	mov    0x8(%ebp),%eax
f0100107:	89 44 24 04          	mov    %eax,0x4(%esp)
f010010b:	c7 04 24 d3 44 10 f0 	movl   $0xf01044d3,(%esp)
f0100112:	e8 7c 33 00 00       	call   f0103493 <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 3a 33 00 00       	call   f0103460 <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 6c 47 10 f0 	movl   $0xf010476c,(%esp)
f010012d:	e8 61 33 00 00       	call   f0103493 <cprintf>
	va_end(ap);
}
f0100132:	83 c4 14             	add    $0x14,%esp
f0100135:	5b                   	pop    %ebx
f0100136:	5d                   	pop    %ebp
f0100137:	c3                   	ret    
f0100138:	66 90                	xchg   %ax,%ax
f010013a:	66 90                	xchg   %ax,%ax
f010013c:	66 90                	xchg   %ax,%ax
f010013e:	66 90                	xchg   %ax,%ax

f0100140 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100140:	55                   	push   %ebp
f0100141:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100143:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100148:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100149:	a8 01                	test   $0x1,%al
f010014b:	74 08                	je     f0100155 <serial_proc_data+0x15>
f010014d:	b2 f8                	mov    $0xf8,%dl
f010014f:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100150:	0f b6 c0             	movzbl %al,%eax
f0100153:	eb 05                	jmp    f010015a <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100155:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010015a:	5d                   	pop    %ebp
f010015b:	c3                   	ret    

f010015c <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010015c:	55                   	push   %ebp
f010015d:	89 e5                	mov    %esp,%ebp
f010015f:	53                   	push   %ebx
f0100160:	83 ec 04             	sub    $0x4,%esp
f0100163:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100165:	eb 2a                	jmp    f0100191 <cons_intr+0x35>
		if (c == 0)
f0100167:	85 d2                	test   %edx,%edx
f0100169:	74 26                	je     f0100191 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f010016b:	a1 24 95 11 f0       	mov    0xf0119524,%eax
f0100170:	8d 48 01             	lea    0x1(%eax),%ecx
f0100173:	89 0d 24 95 11 f0    	mov    %ecx,0xf0119524
f0100179:	88 90 20 93 11 f0    	mov    %dl,-0xfee6ce0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f010017f:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100185:	75 0a                	jne    f0100191 <cons_intr+0x35>
			cons.wpos = 0;
f0100187:	c7 05 24 95 11 f0 00 	movl   $0x0,0xf0119524
f010018e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100191:	ff d3                	call   *%ebx
f0100193:	89 c2                	mov    %eax,%edx
f0100195:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100198:	75 cd                	jne    f0100167 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010019a:	83 c4 04             	add    $0x4,%esp
f010019d:	5b                   	pop    %ebx
f010019e:	5d                   	pop    %ebp
f010019f:	c3                   	ret    

f01001a0 <kbd_proc_data>:
f01001a0:	ba 64 00 00 00       	mov    $0x64,%edx
f01001a5:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01001a6:	a8 01                	test   $0x1,%al
f01001a8:	0f 84 ef 00 00 00    	je     f010029d <kbd_proc_data+0xfd>
f01001ae:	b2 60                	mov    $0x60,%dl
f01001b0:	ec                   	in     (%dx),%al
f01001b1:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001b3:	3c e0                	cmp    $0xe0,%al
f01001b5:	75 0d                	jne    f01001c4 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f01001b7:	83 0d 00 93 11 f0 40 	orl    $0x40,0xf0119300
		return 0;
f01001be:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001c3:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001c4:	55                   	push   %ebp
f01001c5:	89 e5                	mov    %esp,%ebp
f01001c7:	53                   	push   %ebx
f01001c8:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001cb:	84 c0                	test   %al,%al
f01001cd:	79 37                	jns    f0100206 <kbd_proc_data+0x66>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001cf:	8b 0d 00 93 11 f0    	mov    0xf0119300,%ecx
f01001d5:	89 cb                	mov    %ecx,%ebx
f01001d7:	83 e3 40             	and    $0x40,%ebx
f01001da:	83 e0 7f             	and    $0x7f,%eax
f01001dd:	85 db                	test   %ebx,%ebx
f01001df:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001e2:	0f b6 d2             	movzbl %dl,%edx
f01001e5:	0f b6 82 60 46 10 f0 	movzbl -0xfefb9a0(%edx),%eax
f01001ec:	83 c8 40             	or     $0x40,%eax
f01001ef:	0f b6 c0             	movzbl %al,%eax
f01001f2:	f7 d0                	not    %eax
f01001f4:	21 c1                	and    %eax,%ecx
f01001f6:	89 0d 00 93 11 f0    	mov    %ecx,0xf0119300
		return 0;
f01001fc:	b8 00 00 00 00       	mov    $0x0,%eax
f0100201:	e9 9d 00 00 00       	jmp    f01002a3 <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100206:	8b 0d 00 93 11 f0    	mov    0xf0119300,%ecx
f010020c:	f6 c1 40             	test   $0x40,%cl
f010020f:	74 0e                	je     f010021f <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100211:	83 c8 80             	or     $0xffffff80,%eax
f0100214:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100216:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100219:	89 0d 00 93 11 f0    	mov    %ecx,0xf0119300
	}

	shift |= shiftcode[data];
f010021f:	0f b6 d2             	movzbl %dl,%edx
f0100222:	0f b6 82 60 46 10 f0 	movzbl -0xfefb9a0(%edx),%eax
f0100229:	0b 05 00 93 11 f0    	or     0xf0119300,%eax
	shift ^= togglecode[data];
f010022f:	0f b6 8a 60 45 10 f0 	movzbl -0xfefbaa0(%edx),%ecx
f0100236:	31 c8                	xor    %ecx,%eax
f0100238:	a3 00 93 11 f0       	mov    %eax,0xf0119300

	c = charcode[shift & (CTL | SHIFT)][data];
f010023d:	89 c1                	mov    %eax,%ecx
f010023f:	83 e1 03             	and    $0x3,%ecx
f0100242:	8b 0c 8d 40 45 10 f0 	mov    -0xfefbac0(,%ecx,4),%ecx
f0100249:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010024d:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100250:	a8 08                	test   $0x8,%al
f0100252:	74 1b                	je     f010026f <kbd_proc_data+0xcf>
		if ('a' <= c && c <= 'z')
f0100254:	89 da                	mov    %ebx,%edx
f0100256:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100259:	83 f9 19             	cmp    $0x19,%ecx
f010025c:	77 05                	ja     f0100263 <kbd_proc_data+0xc3>
			c += 'A' - 'a';
f010025e:	83 eb 20             	sub    $0x20,%ebx
f0100261:	eb 0c                	jmp    f010026f <kbd_proc_data+0xcf>
		else if ('A' <= c && c <= 'Z')
f0100263:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100266:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100269:	83 fa 19             	cmp    $0x19,%edx
f010026c:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010026f:	f7 d0                	not    %eax
f0100271:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100273:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100275:	f6 c2 06             	test   $0x6,%dl
f0100278:	75 29                	jne    f01002a3 <kbd_proc_data+0x103>
f010027a:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100280:	75 21                	jne    f01002a3 <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f0100282:	c7 04 24 ed 44 10 f0 	movl   $0xf01044ed,(%esp)
f0100289:	e8 05 32 00 00       	call   f0103493 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010028e:	ba 92 00 00 00       	mov    $0x92,%edx
f0100293:	b8 03 00 00 00       	mov    $0x3,%eax
f0100298:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100299:	89 d8                	mov    %ebx,%eax
f010029b:	eb 06                	jmp    f01002a3 <kbd_proc_data+0x103>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f010029d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002a2:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01002a3:	83 c4 14             	add    $0x14,%esp
f01002a6:	5b                   	pop    %ebx
f01002a7:	5d                   	pop    %ebp
f01002a8:	c3                   	ret    

f01002a9 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01002a9:	80 3d 38 95 11 f0 00 	cmpb   $0x0,0xf0119538
f01002b0:	74 11                	je     f01002c3 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01002b2:	55                   	push   %ebp
f01002b3:	89 e5                	mov    %esp,%ebp
f01002b5:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01002b8:	b8 40 01 10 f0       	mov    $0xf0100140,%eax
f01002bd:	e8 9a fe ff ff       	call   f010015c <cons_intr>
}
f01002c2:	c9                   	leave  
f01002c3:	f3 c3                	repz ret 

f01002c5 <get_color>:

/***** 
	setcolor function add by zhuangjian, 2016/07/17 
*****/
int 
get_color(const char *color){  
f01002c5:	55                   	push   %ebp
f01002c6:	89 e5                	mov    %esp,%ebp
f01002c8:	53                   	push   %ebx
f01002c9:	83 ec 14             	sub    $0x14,%esp
f01002cc:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if(strcmp(color,"black") == 0) return BLACK;
f01002cf:	c7 44 24 04 f9 44 10 	movl   $0xf01044f9,0x4(%esp)
f01002d6:	f0 
f01002d7:	89 1c 24             	mov    %ebx,(%esp)
f01002da:	e8 8d 3c 00 00       	call   f0103f6c <strcmp>
f01002df:	85 c0                	test   %eax,%eax
f01002e1:	74 6c                	je     f010034f <get_color+0x8a>
	if(strcmp(color,"white") == 0) return WHITE;
f01002e3:	c7 44 24 04 ff 44 10 	movl   $0xf01044ff,0x4(%esp)
f01002ea:	f0 
f01002eb:	89 1c 24             	mov    %ebx,(%esp)
f01002ee:	e8 79 3c 00 00       	call   f0103f6c <strcmp>
f01002f3:	89 c2                	mov    %eax,%edx
f01002f5:	b8 07 00 00 00       	mov    $0x7,%eax
f01002fa:	85 d2                	test   %edx,%edx
f01002fc:	74 51                	je     f010034f <get_color+0x8a>
	if(strcmp(color,"red") == 0)   return RED;
f01002fe:	c7 44 24 04 05 45 10 	movl   $0xf0104505,0x4(%esp)
f0100305:	f0 
f0100306:	89 1c 24             	mov    %ebx,(%esp)
f0100309:	e8 5e 3c 00 00       	call   f0103f6c <strcmp>
f010030e:	89 c2                	mov    %eax,%edx
f0100310:	b8 04 00 00 00       	mov    $0x4,%eax
f0100315:	85 d2                	test   %edx,%edx
f0100317:	74 36                	je     f010034f <get_color+0x8a>
	if(strcmp(color,"green") == 0) return GREEN;
f0100319:	c7 44 24 04 09 45 10 	movl   $0xf0104509,0x4(%esp)
f0100320:	f0 
f0100321:	89 1c 24             	mov    %ebx,(%esp)
f0100324:	e8 43 3c 00 00       	call   f0103f6c <strcmp>
f0100329:	89 c2                	mov    %eax,%edx
f010032b:	b8 02 00 00 00       	mov    $0x2,%eax
f0100330:	85 d2                	test   %edx,%edx
f0100332:	74 1b                	je     f010034f <get_color+0x8a>
	if(strcmp(color,"blue") == 0)  return BLUE;
f0100334:	c7 44 24 04 0f 45 10 	movl   $0xf010450f,0x4(%esp)
f010033b:	f0 
f010033c:	89 1c 24             	mov    %ebx,(%esp)
f010033f:	e8 28 3c 00 00       	call   f0103f6c <strcmp>
f0100344:	83 f8 01             	cmp    $0x1,%eax
f0100347:	19 c0                	sbb    %eax,%eax
f0100349:	83 e0 02             	and    $0x2,%eax
f010034c:	83 e8 01             	sub    $0x1,%eax
	return -1;
}
f010034f:	83 c4 14             	add    $0x14,%esp
f0100352:	5b                   	pop    %ebx
f0100353:	5d                   	pop    %ebp
f0100354:	c3                   	ret    

f0100355 <get_bg_ch_color>:

int 
get_bg_ch_color(const char *bg, const char *ch){
f0100355:	55                   	push   %ebp
f0100356:	89 e5                	mov    %esp,%ebp
f0100358:	53                   	push   %ebx
f0100359:	83 ec 14             	sub    $0x14,%esp
	int b = get_color(bg);
f010035c:	8b 45 08             	mov    0x8(%ebp),%eax
f010035f:	89 04 24             	mov    %eax,(%esp)
f0100362:	e8 5e ff ff ff       	call   f01002c5 <get_color>
f0100367:	89 c3                	mov    %eax,%ebx
	int c = get_color(ch);  
f0100369:	8b 45 0c             	mov    0xc(%ebp),%eax
f010036c:	89 04 24             	mov    %eax,(%esp)
f010036f:	e8 51 ff ff ff       	call   f01002c5 <get_color>
f0100374:	89 c2                	mov    %eax,%edx
	if(b == -1 && c == -1) return 0x7000;
f0100376:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100379:	75 0a                	jne    f0100385 <get_bg_ch_color+0x30>
f010037b:	b8 00 70 00 00       	mov    $0x7000,%eax
f0100380:	83 fb ff             	cmp    $0xffffffff,%ebx
f0100383:	74 0f                	je     f0100394 <get_bg_ch_color+0x3f>
	return ((b << 12) | (c << 8)) & 0xff00; 
f0100385:	89 d0                	mov    %edx,%eax
f0100387:	c1 e0 08             	shl    $0x8,%eax
f010038a:	c1 e3 0c             	shl    $0xc,%ebx
f010038d:	09 d8                	or     %ebx,%eax
f010038f:	25 00 ff 00 00       	and    $0xff00,%eax
}
f0100394:	83 c4 14             	add    $0x14,%esp
f0100397:	5b                   	pop    %ebx
f0100398:	5d                   	pop    %ebp
f0100399:	c3                   	ret    

f010039a <setcolor>:

static int bg_ch_color;
void
setcolor(const char *bg, const char *ch){
f010039a:	55                   	push   %ebp
f010039b:	89 e5                	mov    %esp,%ebp
f010039d:	53                   	push   %ebx
f010039e:	83 ec 14             	sub    $0x14,%esp
	bg_ch_color = get_bg_ch_color(bg,ch);	
f01003a1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01003a4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01003a8:	8b 45 08             	mov    0x8(%ebp),%eax
f01003ab:	89 04 24             	mov    %eax,(%esp)
f01003ae:	e8 a2 ff ff ff       	call   f0100355 <get_bg_ch_color>
f01003b3:	a3 28 95 11 f0       	mov    %eax,0xf0119528
	int i;	 
	for(i=0;i<CRT_SIZE;i++){
		crt_buf[i] = (crt_buf[i] & 0xff) | bg_ch_color;
f01003b8:	8b 0d 30 95 11 f0    	mov    0xf0119530,%ecx
static int bg_ch_color;
void
setcolor(const char *bg, const char *ch){
	bg_ch_color = get_bg_ch_color(bg,ch);	
	int i;	 
	for(i=0;i<CRT_SIZE;i++){
f01003be:	ba 00 00 00 00       	mov    $0x0,%edx
		crt_buf[i] = (crt_buf[i] & 0xff) | bg_ch_color;
f01003c3:	0f b6 1c 51          	movzbl (%ecx,%edx,2),%ebx
f01003c7:	09 c3                	or     %eax,%ebx
f01003c9:	66 89 1c 51          	mov    %bx,(%ecx,%edx,2)
static int bg_ch_color;
void
setcolor(const char *bg, const char *ch){
	bg_ch_color = get_bg_ch_color(bg,ch);	
	int i;	 
	for(i=0;i<CRT_SIZE;i++){
f01003cd:	83 c2 01             	add    $0x1,%edx
f01003d0:	81 fa d0 07 00 00    	cmp    $0x7d0,%edx
f01003d6:	75 eb                	jne    f01003c3 <setcolor+0x29>
		crt_buf[i] = (crt_buf[i] & 0xff) | bg_ch_color;
	}	
}
f01003d8:	83 c4 14             	add    $0x14,%esp
f01003db:	5b                   	pop    %ebx
f01003dc:	5d                   	pop    %ebp
f01003dd:	c3                   	ret    

f01003de <get_default_color>:

int 
get_default_color(){	
f01003de:	55                   	push   %ebp
f01003df:	89 e5                	mov    %esp,%ebp
	if(bg_ch_color == 0) return 0x0700;
f01003e1:	a1 28 95 11 f0       	mov    0xf0119528,%eax
f01003e6:	85 c0                	test   %eax,%eax
f01003e8:	ba 00 07 00 00       	mov    $0x700,%edx
f01003ed:	0f 44 c2             	cmove  %edx,%eax
	return bg_ch_color;
}
f01003f0:	5d                   	pop    %ebp
f01003f1:	c3                   	ret    

f01003f2 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01003f2:	55                   	push   %ebp
f01003f3:	89 e5                	mov    %esp,%ebp
f01003f5:	57                   	push   %edi
f01003f6:	56                   	push   %esi
f01003f7:	53                   	push   %ebx
f01003f8:	83 ec 1c             	sub    $0x1c,%esp
f01003fb:	89 c6                	mov    %eax,%esi
f01003fd:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100402:	bf fd 03 00 00       	mov    $0x3fd,%edi
f0100407:	b9 84 00 00 00       	mov    $0x84,%ecx
f010040c:	eb 06                	jmp    f0100414 <cons_putc+0x22>
f010040e:	89 ca                	mov    %ecx,%edx
f0100410:	ec                   	in     (%dx),%al
f0100411:	ec                   	in     (%dx),%al
f0100412:	ec                   	in     (%dx),%al
f0100413:	ec                   	in     (%dx),%al
f0100414:	89 fa                	mov    %edi,%edx
f0100416:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f0100417:	a8 20                	test   $0x20,%al
f0100419:	75 05                	jne    f0100420 <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010041b:	83 eb 01             	sub    $0x1,%ebx
f010041e:	75 ee                	jne    f010040e <cons_putc+0x1c>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f0100420:	89 f0                	mov    %esi,%eax
f0100422:	0f b6 c0             	movzbl %al,%eax
f0100425:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100428:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010042d:	ee                   	out    %al,(%dx)
f010042e:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100433:	bf 79 03 00 00       	mov    $0x379,%edi
f0100438:	b9 84 00 00 00       	mov    $0x84,%ecx
f010043d:	eb 06                	jmp    f0100445 <cons_putc+0x53>
f010043f:	89 ca                	mov    %ecx,%edx
f0100441:	ec                   	in     (%dx),%al
f0100442:	ec                   	in     (%dx),%al
f0100443:	ec                   	in     (%dx),%al
f0100444:	ec                   	in     (%dx),%al
f0100445:	89 fa                	mov    %edi,%edx
f0100447:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100448:	84 c0                	test   %al,%al
f010044a:	78 05                	js     f0100451 <cons_putc+0x5f>
f010044c:	83 eb 01             	sub    $0x1,%ebx
f010044f:	75 ee                	jne    f010043f <cons_putc+0x4d>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100451:	ba 78 03 00 00       	mov    $0x378,%edx
f0100456:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f010045a:	ee                   	out    %al,(%dx)
f010045b:	b2 7a                	mov    $0x7a,%dl
f010045d:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100462:	ee                   	out    %al,(%dx)
f0100463:	b8 08 00 00 00       	mov    $0x8,%eax
f0100468:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100469:	f7 c6 00 ff ff ff    	test   $0xffffff00,%esi
f010046f:	75 07                	jne    f0100478 <cons_putc+0x86>
		//c |= 0x0700;
		c |= get_default_color();
f0100471:	e8 68 ff ff ff       	call   f01003de <get_default_color>
f0100476:	09 c6                	or     %eax,%esi

	switch (c & 0xff) {
f0100478:	89 f0                	mov    %esi,%eax
f010047a:	0f b6 c0             	movzbl %al,%eax
f010047d:	83 f8 09             	cmp    $0x9,%eax
f0100480:	74 7b                	je     f01004fd <cons_putc+0x10b>
f0100482:	83 f8 09             	cmp    $0x9,%eax
f0100485:	7f 0e                	jg     f0100495 <cons_putc+0xa3>
f0100487:	83 f8 08             	cmp    $0x8,%eax
f010048a:	74 1b                	je     f01004a7 <cons_putc+0xb5>
f010048c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100490:	e9 9c 00 00 00       	jmp    f0100531 <cons_putc+0x13f>
f0100495:	83 f8 0a             	cmp    $0xa,%eax
f0100498:	74 3d                	je     f01004d7 <cons_putc+0xe5>
f010049a:	83 f8 0d             	cmp    $0xd,%eax
f010049d:	8d 76 00             	lea    0x0(%esi),%esi
f01004a0:	74 3d                	je     f01004df <cons_putc+0xed>
f01004a2:	e9 8a 00 00 00       	jmp    f0100531 <cons_putc+0x13f>
	case '\b':
		if (crt_pos > 0) {
f01004a7:	0f b7 05 2c 95 11 f0 	movzwl 0xf011952c,%eax
f01004ae:	66 85 c0             	test   %ax,%ax
f01004b1:	0f 84 ec 00 00 00    	je     f01005a3 <cons_putc+0x1b1>
			crt_pos--;
f01004b7:	83 e8 01             	sub    $0x1,%eax
f01004ba:	66 a3 2c 95 11 f0    	mov    %ax,0xf011952c
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004c0:	0f b7 c0             	movzwl %ax,%eax
f01004c3:	66 81 e6 00 ff       	and    $0xff00,%si
f01004c8:	83 ce 20             	or     $0x20,%esi
f01004cb:	8b 15 30 95 11 f0    	mov    0xf0119530,%edx
f01004d1:	66 89 34 42          	mov    %si,(%edx,%eax,2)
f01004d5:	eb 78                	jmp    f010054f <cons_putc+0x15d>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01004d7:	66 83 05 2c 95 11 f0 	addw   $0x50,0xf011952c
f01004de:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01004df:	0f b7 05 2c 95 11 f0 	movzwl 0xf011952c,%eax
f01004e6:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01004ec:	c1 e8 16             	shr    $0x16,%eax
f01004ef:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01004f2:	c1 e0 04             	shl    $0x4,%eax
f01004f5:	66 a3 2c 95 11 f0    	mov    %ax,0xf011952c
f01004fb:	eb 52                	jmp    f010054f <cons_putc+0x15d>
		break;
	case '\t':
		cons_putc(' ');
f01004fd:	b8 20 00 00 00       	mov    $0x20,%eax
f0100502:	e8 eb fe ff ff       	call   f01003f2 <cons_putc>
		cons_putc(' ');
f0100507:	b8 20 00 00 00       	mov    $0x20,%eax
f010050c:	e8 e1 fe ff ff       	call   f01003f2 <cons_putc>
		cons_putc(' ');
f0100511:	b8 20 00 00 00       	mov    $0x20,%eax
f0100516:	e8 d7 fe ff ff       	call   f01003f2 <cons_putc>
		cons_putc(' ');
f010051b:	b8 20 00 00 00       	mov    $0x20,%eax
f0100520:	e8 cd fe ff ff       	call   f01003f2 <cons_putc>
		cons_putc(' ');
f0100525:	b8 20 00 00 00       	mov    $0x20,%eax
f010052a:	e8 c3 fe ff ff       	call   f01003f2 <cons_putc>
f010052f:	eb 1e                	jmp    f010054f <cons_putc+0x15d>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100531:	0f b7 05 2c 95 11 f0 	movzwl 0xf011952c,%eax
f0100538:	8d 50 01             	lea    0x1(%eax),%edx
f010053b:	66 89 15 2c 95 11 f0 	mov    %dx,0xf011952c
f0100542:	0f b7 c0             	movzwl %ax,%eax
f0100545:	8b 15 30 95 11 f0    	mov    0xf0119530,%edx
f010054b:	66 89 34 42          	mov    %si,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f010054f:	66 81 3d 2c 95 11 f0 	cmpw   $0x7cf,0xf011952c
f0100556:	cf 07 
f0100558:	76 49                	jbe    f01005a3 <cons_putc+0x1b1>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010055a:	a1 30 95 11 f0       	mov    0xf0119530,%eax
f010055f:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100566:	00 
f0100567:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010056d:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100571:	89 04 24             	mov    %eax,(%esp)
f0100574:	e8 db 3a 00 00       	call   f0104054 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			//crt_buf[i] = 0x0700 | ' ';
			crt_buf[i] = get_default_color() | ' ';
f0100579:	8b 35 30 95 11 f0    	mov    0xf0119530,%esi
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010057f:	bb 80 07 00 00       	mov    $0x780,%ebx
			//crt_buf[i] = 0x0700 | ' ';
			crt_buf[i] = get_default_color() | ' ';
f0100584:	e8 55 fe ff ff       	call   f01003de <get_default_color>
f0100589:	83 c8 20             	or     $0x20,%eax
f010058c:	66 89 04 5e          	mov    %ax,(%esi,%ebx,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100590:	83 c3 01             	add    $0x1,%ebx
f0100593:	81 fb d0 07 00 00    	cmp    $0x7d0,%ebx
f0100599:	75 e9                	jne    f0100584 <cons_putc+0x192>
			//crt_buf[i] = 0x0700 | ' ';
			crt_buf[i] = get_default_color() | ' ';
		crt_pos -= CRT_COLS;
f010059b:	66 83 2d 2c 95 11 f0 	subw   $0x50,0xf011952c
f01005a2:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01005a3:	8b 0d 34 95 11 f0    	mov    0xf0119534,%ecx
f01005a9:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005ae:	89 ca                	mov    %ecx,%edx
f01005b0:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01005b1:	0f b7 1d 2c 95 11 f0 	movzwl 0xf011952c,%ebx
f01005b8:	8d 71 01             	lea    0x1(%ecx),%esi
f01005bb:	89 d8                	mov    %ebx,%eax
f01005bd:	66 c1 e8 08          	shr    $0x8,%ax
f01005c1:	89 f2                	mov    %esi,%edx
f01005c3:	ee                   	out    %al,(%dx)
f01005c4:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005c9:	89 ca                	mov    %ecx,%edx
f01005cb:	ee                   	out    %al,(%dx)
f01005cc:	89 d8                	mov    %ebx,%eax
f01005ce:	89 f2                	mov    %esi,%edx
f01005d0:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01005d1:	83 c4 1c             	add    $0x1c,%esp
f01005d4:	5b                   	pop    %ebx
f01005d5:	5e                   	pop    %esi
f01005d6:	5f                   	pop    %edi
f01005d7:	5d                   	pop    %ebp
f01005d8:	c3                   	ret    

f01005d9 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01005d9:	55                   	push   %ebp
f01005da:	89 e5                	mov    %esp,%ebp
f01005dc:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01005df:	b8 a0 01 10 f0       	mov    $0xf01001a0,%eax
f01005e4:	e8 73 fb ff ff       	call   f010015c <cons_intr>
}
f01005e9:	c9                   	leave  
f01005ea:	c3                   	ret    

f01005eb <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01005eb:	55                   	push   %ebp
f01005ec:	89 e5                	mov    %esp,%ebp
f01005ee:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01005f1:	e8 b3 fc ff ff       	call   f01002a9 <serial_intr>
	kbd_intr();
f01005f6:	e8 de ff ff ff       	call   f01005d9 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01005fb:	a1 20 95 11 f0       	mov    0xf0119520,%eax
f0100600:	3b 05 24 95 11 f0    	cmp    0xf0119524,%eax
f0100606:	74 26                	je     f010062e <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100608:	8d 50 01             	lea    0x1(%eax),%edx
f010060b:	89 15 20 95 11 f0    	mov    %edx,0xf0119520
f0100611:	0f b6 88 20 93 11 f0 	movzbl -0xfee6ce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100618:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f010061a:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100620:	75 11                	jne    f0100633 <cons_getc+0x48>
			cons.rpos = 0;
f0100622:	c7 05 20 95 11 f0 00 	movl   $0x0,0xf0119520
f0100629:	00 00 00 
f010062c:	eb 05                	jmp    f0100633 <cons_getc+0x48>
		return c;
	}
	return 0;
f010062e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100633:	c9                   	leave  
f0100634:	c3                   	ret    

f0100635 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100635:	55                   	push   %ebp
f0100636:	89 e5                	mov    %esp,%ebp
f0100638:	57                   	push   %edi
f0100639:	56                   	push   %esi
f010063a:	53                   	push   %ebx
f010063b:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f010063e:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100645:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010064c:	5a a5 
	if (*cp != 0xA55A) {
f010064e:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100655:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100659:	74 11                	je     f010066c <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010065b:	c7 05 34 95 11 f0 b4 	movl   $0x3b4,0xf0119534
f0100662:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100665:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f010066a:	eb 16                	jmp    f0100682 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010066c:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100673:	c7 05 34 95 11 f0 d4 	movl   $0x3d4,0xf0119534
f010067a:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010067d:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100682:	8b 0d 34 95 11 f0    	mov    0xf0119534,%ecx
f0100688:	b8 0e 00 00 00       	mov    $0xe,%eax
f010068d:	89 ca                	mov    %ecx,%edx
f010068f:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100690:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100693:	89 da                	mov    %ebx,%edx
f0100695:	ec                   	in     (%dx),%al
f0100696:	0f b6 f0             	movzbl %al,%esi
f0100699:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010069c:	b8 0f 00 00 00       	mov    $0xf,%eax
f01006a1:	89 ca                	mov    %ecx,%edx
f01006a3:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006a4:	89 da                	mov    %ebx,%edx
f01006a6:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01006a7:	89 3d 30 95 11 f0    	mov    %edi,0xf0119530

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01006ad:	0f b6 d8             	movzbl %al,%ebx
f01006b0:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01006b2:	66 89 35 2c 95 11 f0 	mov    %si,0xf011952c
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006b9:	be fa 03 00 00       	mov    $0x3fa,%esi
f01006be:	b8 00 00 00 00       	mov    $0x0,%eax
f01006c3:	89 f2                	mov    %esi,%edx
f01006c5:	ee                   	out    %al,(%dx)
f01006c6:	b2 fb                	mov    $0xfb,%dl
f01006c8:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01006cd:	ee                   	out    %al,(%dx)
f01006ce:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01006d3:	b8 0c 00 00 00       	mov    $0xc,%eax
f01006d8:	89 da                	mov    %ebx,%edx
f01006da:	ee                   	out    %al,(%dx)
f01006db:	b2 f9                	mov    $0xf9,%dl
f01006dd:	b8 00 00 00 00       	mov    $0x0,%eax
f01006e2:	ee                   	out    %al,(%dx)
f01006e3:	b2 fb                	mov    $0xfb,%dl
f01006e5:	b8 03 00 00 00       	mov    $0x3,%eax
f01006ea:	ee                   	out    %al,(%dx)
f01006eb:	b2 fc                	mov    $0xfc,%dl
f01006ed:	b8 00 00 00 00       	mov    $0x0,%eax
f01006f2:	ee                   	out    %al,(%dx)
f01006f3:	b2 f9                	mov    $0xf9,%dl
f01006f5:	b8 01 00 00 00       	mov    $0x1,%eax
f01006fa:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006fb:	b2 fd                	mov    $0xfd,%dl
f01006fd:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01006fe:	3c ff                	cmp    $0xff,%al
f0100700:	0f 95 c1             	setne  %cl
f0100703:	88 0d 38 95 11 f0    	mov    %cl,0xf0119538
f0100709:	89 f2                	mov    %esi,%edx
f010070b:	ec                   	in     (%dx),%al
f010070c:	89 da                	mov    %ebx,%edx
f010070e:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010070f:	84 c9                	test   %cl,%cl
f0100711:	75 0c                	jne    f010071f <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f0100713:	c7 04 24 14 45 10 f0 	movl   $0xf0104514,(%esp)
f010071a:	e8 74 2d 00 00       	call   f0103493 <cprintf>
}
f010071f:	83 c4 1c             	add    $0x1c,%esp
f0100722:	5b                   	pop    %ebx
f0100723:	5e                   	pop    %esi
f0100724:	5f                   	pop    %edi
f0100725:	5d                   	pop    %ebp
f0100726:	c3                   	ret    

f0100727 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100727:	55                   	push   %ebp
f0100728:	89 e5                	mov    %esp,%ebp
f010072a:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010072d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100730:	e8 bd fc ff ff       	call   f01003f2 <cons_putc>
}
f0100735:	c9                   	leave  
f0100736:	c3                   	ret    

f0100737 <getchar>:

int
getchar(void)
{
f0100737:	55                   	push   %ebp
f0100738:	89 e5                	mov    %esp,%ebp
f010073a:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010073d:	e8 a9 fe ff ff       	call   f01005eb <cons_getc>
f0100742:	85 c0                	test   %eax,%eax
f0100744:	74 f7                	je     f010073d <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100746:	c9                   	leave  
f0100747:	c3                   	ret    

f0100748 <iscons>:

int
iscons(int fdnum)
{
f0100748:	55                   	push   %ebp
f0100749:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010074b:	b8 01 00 00 00       	mov    $0x1,%eax
f0100750:	5d                   	pop    %ebp
f0100751:	c3                   	ret    
f0100752:	66 90                	xchg   %ax,%ax
f0100754:	66 90                	xchg   %ax,%ax
f0100756:	66 90                	xchg   %ax,%ax
f0100758:	66 90                	xchg   %ax,%ax
f010075a:	66 90                	xchg   %ax,%ax
f010075c:	66 90                	xchg   %ax,%ax
f010075e:	66 90                	xchg   %ax,%ax

f0100760 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100760:	55                   	push   %ebp
f0100761:	89 e5                	mov    %esp,%ebp
f0100763:	56                   	push   %esi
f0100764:	53                   	push   %ebx
f0100765:	83 ec 10             	sub    $0x10,%esp
f0100768:	be a4 4e 10 f0       	mov    $0xf0104ea4,%esi
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f010076d:	bb 00 00 00 00       	mov    $0x0,%ebx
		cprintf("%d: %s - %s\n\n",i+1, commands[i].name, commands[i].desc);
f0100772:	83 c3 01             	add    $0x1,%ebx
f0100775:	8b 06                	mov    (%esi),%eax
f0100777:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010077b:	8b 46 fc             	mov    -0x4(%esi),%eax
f010077e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100782:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100786:	c7 04 24 60 47 10 f0 	movl   $0xf0104760,(%esp)
f010078d:	e8 01 2d 00 00       	call   f0103493 <cprintf>
f0100792:	83 c6 0c             	add    $0xc,%esi
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f0100795:	83 fb 07             	cmp    $0x7,%ebx
f0100798:	75 d8                	jne    f0100772 <mon_help+0x12>
		cprintf("%d: %s - %s\n\n",i+1, commands[i].name, commands[i].desc);
	return 0;
}
f010079a:	b8 00 00 00 00       	mov    $0x0,%eax
f010079f:	83 c4 10             	add    $0x10,%esp
f01007a2:	5b                   	pop    %ebx
f01007a3:	5e                   	pop    %esi
f01007a4:	5d                   	pop    %ebp
f01007a5:	c3                   	ret    

f01007a6 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01007a6:	55                   	push   %ebp
f01007a7:	89 e5                	mov    %esp,%ebp
f01007a9:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01007ac:	c7 04 24 6e 47 10 f0 	movl   $0xf010476e,(%esp)
f01007b3:	e8 db 2c 00 00       	call   f0103493 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007b8:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01007bf:	00 
f01007c0:	c7 04 24 e0 48 10 f0 	movl   $0xf01048e0,(%esp)
f01007c7:	e8 c7 2c 00 00       	call   f0103493 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007cc:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01007d3:	00 
f01007d4:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01007db:	f0 
f01007dc:	c7 04 24 08 49 10 f0 	movl   $0xf0104908,(%esp)
f01007e3:	e8 ab 2c 00 00       	call   f0103493 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007e8:	c7 44 24 08 97 44 10 	movl   $0x104497,0x8(%esp)
f01007ef:	00 
f01007f0:	c7 44 24 04 97 44 10 	movl   $0xf0104497,0x4(%esp)
f01007f7:	f0 
f01007f8:	c7 04 24 2c 49 10 f0 	movl   $0xf010492c,(%esp)
f01007ff:	e8 8f 2c 00 00       	call   f0103493 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100804:	c7 44 24 08 00 93 11 	movl   $0x119300,0x8(%esp)
f010080b:	00 
f010080c:	c7 44 24 04 00 93 11 	movl   $0xf0119300,0x4(%esp)
f0100813:	f0 
f0100814:	c7 04 24 50 49 10 f0 	movl   $0xf0104950,(%esp)
f010081b:	e8 73 2c 00 00       	call   f0103493 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100820:	c7 44 24 08 70 99 11 	movl   $0x119970,0x8(%esp)
f0100827:	00 
f0100828:	c7 44 24 04 70 99 11 	movl   $0xf0119970,0x4(%esp)
f010082f:	f0 
f0100830:	c7 04 24 74 49 10 f0 	movl   $0xf0104974,(%esp)
f0100837:	e8 57 2c 00 00       	call   f0103493 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010083c:	b8 6f 9d 11 f0       	mov    $0xf0119d6f,%eax
f0100841:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100846:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010084b:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100851:	85 c0                	test   %eax,%eax
f0100853:	0f 48 c2             	cmovs  %edx,%eax
f0100856:	c1 f8 0a             	sar    $0xa,%eax
f0100859:	89 44 24 04          	mov    %eax,0x4(%esp)
f010085d:	c7 04 24 98 49 10 f0 	movl   $0xf0104998,(%esp)
f0100864:	e8 2a 2c 00 00       	call   f0103493 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100869:	b8 00 00 00 00       	mov    $0x0,%eax
f010086e:	c9                   	leave  
f010086f:	c3                   	ret    

f0100870 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{ 
f0100870:	55                   	push   %ebp
f0100871:	89 e5                	mov    %esp,%ebp
f0100873:	57                   	push   %edi
f0100874:	56                   	push   %esi
f0100875:	53                   	push   %ebx
f0100876:	83 ec 5c             	sub    $0x5c,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100879:	89 e8                	mov    %ebp,%eax
	// Your code here.
	uint32_t *ebp, eip;
	uint32_t arg0, arg1, arg2, arg3, arg4;
	ebp = (uint32_t*)read_ebp();
f010087b:	89 c3                	mov    %eax,%ebx
	eip = ebp[1];
f010087d:	8b 70 04             	mov    0x4(%eax),%esi
	arg0 = ebp[2];
f0100880:	8b 50 08             	mov    0x8(%eax),%edx
f0100883:	89 55 c4             	mov    %edx,-0x3c(%ebp)
	arg1 = ebp[3];
f0100886:	8b 48 0c             	mov    0xc(%eax),%ecx
f0100889:	89 4d c0             	mov    %ecx,-0x40(%ebp)
	arg2 = ebp[4];
f010088c:	8b 50 10             	mov    0x10(%eax),%edx
f010088f:	89 55 bc             	mov    %edx,-0x44(%ebp)
	arg3 = ebp[5];
f0100892:	8b 78 14             	mov    0x14(%eax),%edi
f0100895:	89 7d b8             	mov    %edi,-0x48(%ebp)
	arg4 = ebp[6]; 
f0100898:	8b 78 18             	mov    0x18(%eax),%edi
	cprintf("Stack backtrace:\n");
f010089b:	c7 04 24 87 47 10 f0 	movl   $0xf0104787,(%esp)
f01008a2:	e8 ec 2b 00 00       	call   f0103493 <cprintf>
f01008a7:	8b 45 c0             	mov    -0x40(%ebp),%eax
f01008aa:	8b 55 bc             	mov    -0x44(%ebp),%edx
f01008ad:	8b 4d b8             	mov    -0x48(%ebp),%ecx
	当发现 ebp 的值为 0 时便停止循环。
	因为最外层的程序是 kern/entry.S 中的入口程序，记得在之前我们看到过入口程序中有一句
	代码是“ movl $0x0,%ebp”，也就是说在入口程序调用 i386_init 函数之前便把 ebp 的值置
	为 0，也就是说入口程序的 ebp 实际上为 0
	*/
	while(ebp != 0){
f01008b0:	e9 90 00 00 00       	jmp    f0100945 <mon_backtrace+0xd5>
		cprintf("ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n",
f01008b5:	89 7c 24 1c          	mov    %edi,0x1c(%esp)
f01008b9:	89 4c 24 18          	mov    %ecx,0x18(%esp)
f01008bd:	89 54 24 14          	mov    %edx,0x14(%esp)
f01008c1:	89 44 24 10          	mov    %eax,0x10(%esp)
f01008c5:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f01008c8:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01008cc:	89 74 24 08          	mov    %esi,0x8(%esp)
f01008d0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01008d4:	c7 04 24 c4 49 10 f0 	movl   $0xf01049c4,(%esp)
f01008db:	e8 b3 2b 00 00       	call   f0103493 <cprintf>
			ebp,eip,arg0,arg1,arg2,arg3,arg4);
		struct Eipdebuginfo info;

		if(debuginfo_eip(eip, &info) == 0){
f01008e0:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01008e3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008e7:	89 34 24             	mov    %esi,(%esp)
f01008ea:	e8 9b 2c 00 00       	call   f010358a <debuginfo_eip>
f01008ef:	85 c0                	test   %eax,%eax
f01008f1:	75 3b                	jne    f010092e <mon_backtrace+0xbe>
			//file name : line
	    	cprintf("\t%s:%d: ", info.eip_file, info.eip_line);
f01008f3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01008f6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01008fa:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01008fd:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100901:	c7 04 24 99 47 10 f0 	movl   $0xf0104799,(%esp)
f0100908:	e8 86 2b 00 00       	call   f0103493 <cprintf>
	    	//function name + the offset of the eip from the first instruction of the function
	    	//注意：printf("%.*s", length, string)打印string的至多length个字符
	      	cprintf("%.*s+%d\n", info.eip_fn_namelen, info.eip_fn_name, eip - info.eip_fn_addr);
f010090d:	2b 75 e0             	sub    -0x20(%ebp),%esi
f0100910:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100914:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100917:	89 44 24 08          	mov    %eax,0x8(%esp)
f010091b:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010091e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100922:	c7 04 24 a2 47 10 f0 	movl   $0xf01047a2,(%esp)
f0100929:	e8 65 2b 00 00       	call   f0103493 <cprintf>
	    } 

		ebp = (uint32_t*)ebp[0];
f010092e:	8b 1b                	mov    (%ebx),%ebx
		eip = ebp[1];
f0100930:	8b 73 04             	mov    0x4(%ebx),%esi
		arg0 = ebp[2];
f0100933:	8b 43 08             	mov    0x8(%ebx),%eax
f0100936:	89 45 c4             	mov    %eax,-0x3c(%ebp)
		arg1 = ebp[3];
f0100939:	8b 43 0c             	mov    0xc(%ebx),%eax
		arg2 = ebp[4];
f010093c:	8b 53 10             	mov    0x10(%ebx),%edx
		arg3 = ebp[5];
f010093f:	8b 4b 14             	mov    0x14(%ebx),%ecx
		arg4 = ebp[6]; 
f0100942:	8b 7b 18             	mov    0x18(%ebx),%edi
	当发现 ebp 的值为 0 时便停止循环。
	因为最外层的程序是 kern/entry.S 中的入口程序，记得在之前我们看到过入口程序中有一句
	代码是“ movl $0x0,%ebp”，也就是说在入口程序调用 i386_init 函数之前便把 ebp 的值置
	为 0，也就是说入口程序的 ebp 实际上为 0
	*/
	while(ebp != 0){
f0100945:	85 db                	test   %ebx,%ebx
f0100947:	0f 85 68 ff ff ff    	jne    f01008b5 <mon_backtrace+0x45>
		arg2 = ebp[4];
		arg3 = ebp[5];
		arg4 = ebp[6]; 
	} 
	return 0;
}
f010094d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100952:	83 c4 5c             	add    $0x5c,%esp
f0100955:	5b                   	pop    %ebx
f0100956:	5e                   	pop    %esi
f0100957:	5f                   	pop    %edi
f0100958:	5d                   	pop    %ebp
f0100959:	c3                   	ret    

f010095a <jz_atoi>:


/***** 
	setcolor command add by zhuangjian, 2016/07/17 
*****/
int jz_atoi(char* pstr) {
f010095a:	55                   	push   %ebp
f010095b:	89 e5                	mov    %esp,%ebp
f010095d:	56                   	push   %esi
f010095e:	53                   	push   %ebx
f010095f:	8b 55 08             	mov    0x8(%ebp),%edx
    int intVal = 0;              // 返回值
    int sign = 1;                // 符号, 正数为 1, 负数为 -1
    if(pstr == 0) return 0;      // 判断指针是否为空 pstr == NULL
f0100962:	85 d2                	test   %edx,%edx
f0100964:	75 05                	jne    f010096b <jz_atoi+0x11>
f0100966:	eb 4a                	jmp    f01009b2 <jz_atoi+0x58>
    while(' '== *pstr) pstr++;   // 跳过前面的空格字符 ' ' 的 ascii 值 0x20
f0100968:	83 c2 01             	add    $0x1,%edx
f010096b:	0f b6 0a             	movzbl (%edx),%ecx
f010096e:	80 f9 20             	cmp    $0x20,%cl
f0100971:	74 f5                	je     f0100968 <jz_atoi+0xe>
f0100973:	89 d0                	mov    %edx,%eax
    if('-'==*pstr) sign = -1;    // 判断正负号
f0100975:	80 f9 2d             	cmp    $0x2d,%cl
f0100978:	74 0c                	je     f0100986 <jz_atoi+0x2c>
/***** 
	setcolor command add by zhuangjian, 2016/07/17 
*****/
int jz_atoi(char* pstr) {
    int intVal = 0;              // 返回值
    int sign = 1;                // 符号, 正数为 1, 负数为 -1
f010097a:	be 01 00 00 00       	mov    $0x1,%esi
    if(pstr == 0) return 0;      // 判断指针是否为空 pstr == NULL
    while(' '== *pstr) pstr++;   // 跳过前面的空格字符 ' ' 的 ascii 值 0x20
    if('-'==*pstr) sign = -1;    // 判断正负号
    if('-'==*pstr || '+'==*pstr) pstr++;// 如果是符号, 指针后移
f010097f:	80 f9 2b             	cmp    $0x2b,%cl
f0100982:	75 0a                	jne    f010098e <jz_atoi+0x34>
f0100984:	eb 05                	jmp    f010098b <jz_atoi+0x31>
int jz_atoi(char* pstr) {
    int intVal = 0;              // 返回值
    int sign = 1;                // 符号, 正数为 1, 负数为 -1
    if(pstr == 0) return 0;      // 判断指针是否为空 pstr == NULL
    while(' '== *pstr) pstr++;   // 跳过前面的空格字符 ' ' 的 ascii 值 0x20
    if('-'==*pstr) sign = -1;    // 判断正负号
f0100986:	be ff ff ff ff       	mov    $0xffffffff,%esi
    if('-'==*pstr || '+'==*pstr) pstr++;// 如果是符号, 指针后移
f010098b:	8d 50 01             	lea    0x1(%eax),%edx
/***** 
	setcolor command add by zhuangjian, 2016/07/17 
*****/
int jz_atoi(char* pstr) {
    int intVal = 0;              // 返回值
    int sign = 1;                // 符号, 正数为 1, 负数为 -1
f010098e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100993:	eb 0d                	jmp    f01009a2 <jz_atoi+0x48>
    while(*pstr >= '0' && *pstr <= '9') {// 逐字符转换成整数
        // 转换说明
        // ascii 的 '0' = 0x30 转换为int以后 - 0x30即为整型的0
        // ascii 的 '1' = 0x31 转换为int以后 - 0x30即为整型的1
        // ...
        intVal = intVal * 10 + (((int)*pstr)-0x30);// 十进制即每位乘10, 结果累加保存
f0100995:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100998:	0f be c9             	movsbl %cl,%ecx
f010099b:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
        pstr++;// 指针后移
f010099f:	83 c2 01             	add    $0x1,%edx
    int sign = 1;                // 符号, 正数为 1, 负数为 -1
    if(pstr == 0) return 0;      // 判断指针是否为空 pstr == NULL
    while(' '== *pstr) pstr++;   // 跳过前面的空格字符 ' ' 的 ascii 值 0x20
    if('-'==*pstr) sign = -1;    // 判断正负号
    if('-'==*pstr || '+'==*pstr) pstr++;// 如果是符号, 指针后移
    while(*pstr >= '0' && *pstr <= '9') {// 逐字符转换成整数
f01009a2:	0f b6 0a             	movzbl (%edx),%ecx
f01009a5:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f01009a8:	80 fb 09             	cmp    $0x9,%bl
f01009ab:	76 e8                	jbe    f0100995 <jz_atoi+0x3b>
        // ascii 的 '1' = 0x31 转换为int以后 - 0x30即为整型的1
        // ...
        intVal = intVal * 10 + (((int)*pstr)-0x30);// 十进制即每位乘10, 结果累加保存
        pstr++;// 指针后移
    }
    return intVal * sign;// 返回结果,int32 范围是: 2147483647 ~ -2147483648, 此处会进行溢出运算
f01009ad:	0f af c6             	imul   %esi,%eax
f01009b0:	eb 05                	jmp    f01009b7 <jz_atoi+0x5d>
	setcolor command add by zhuangjian, 2016/07/17 
*****/
int jz_atoi(char* pstr) {
    int intVal = 0;              // 返回值
    int sign = 1;                // 符号, 正数为 1, 负数为 -1
    if(pstr == 0) return 0;      // 判断指针是否为空 pstr == NULL
f01009b2:	b8 00 00 00 00       	mov    $0x0,%eax
        intVal = intVal * 10 + (((int)*pstr)-0x30);// 十进制即每位乘10, 结果累加保存
        pstr++;// 指针后移
    }
    return intVal * sign;// 返回结果,int32 范围是: 2147483647 ~ -2147483648, 此处会进行溢出运算
     
}
f01009b7:	5b                   	pop    %ebx
f01009b8:	5e                   	pop    %esi
f01009b9:	5d                   	pop    %ebp
f01009ba:	c3                   	ret    

f01009bb <jz_xtoi>:

uint32_t jz_xtoi(char* pstr){
f01009bb:	55                   	push   %ebp
f01009bc:	89 e5                	mov    %esp,%ebp
f01009be:	53                   	push   %ebx
	uint32_t res = 0;
	pstr += 2;//0x...
f01009bf:	8b 45 08             	mov    0x8(%ebp),%eax
f01009c2:	8d 50 02             	lea    0x2(%eax),%edx
    return intVal * sign;// 返回结果,int32 范围是: 2147483647 ~ -2147483648, 此处会进行溢出运算
     
}

uint32_t jz_xtoi(char* pstr){
	uint32_t res = 0;
f01009c5:	b8 00 00 00 00       	mov    $0x0,%eax
	pstr += 2;//0x...
	while(*pstr){
f01009ca:	eb 29                	jmp    f01009f5 <jz_xtoi+0x3a>
		if(*pstr >= 'a' && *pstr <= 'z') *pstr = *pstr - 'a' + 10 + '0';
f01009cc:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f01009cf:	80 fb 19             	cmp    $0x19,%bl
f01009d2:	77 07                	ja     f01009db <jz_xtoi+0x20>
f01009d4:	83 e9 27             	sub    $0x27,%ecx
f01009d7:	88 0a                	mov    %cl,(%edx)
f01009d9:	eb 0d                	jmp    f01009e8 <jz_xtoi+0x2d>
		else if(*pstr >= 'A' && *pstr <= 'Z') *pstr = *pstr - 'A' + 10 + '0';
f01009db:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f01009de:	80 fb 19             	cmp    $0x19,%bl
f01009e1:	77 05                	ja     f01009e8 <jz_xtoi+0x2d>
f01009e3:	83 e9 07             	sub    $0x7,%ecx
f01009e6:	88 0a                	mov    %cl,(%edx)
		res = res*16 + *pstr - '0';
f01009e8:	c1 e0 04             	shl    $0x4,%eax
f01009eb:	0f be 0a             	movsbl (%edx),%ecx
f01009ee:	8d 44 08 d0          	lea    -0x30(%eax,%ecx,1),%eax
		++pstr;
f01009f2:	83 c2 01             	add    $0x1,%edx
}

uint32_t jz_xtoi(char* pstr){
	uint32_t res = 0;
	pstr += 2;//0x...
	while(*pstr){
f01009f5:	0f b6 0a             	movzbl (%edx),%ecx
f01009f8:	84 c9                	test   %cl,%cl
f01009fa:	75 d0                	jne    f01009cc <jz_xtoi+0x11>
		else if(*pstr >= 'A' && *pstr <= 'Z') *pstr = *pstr - 'A' + 10 + '0';
		res = res*16 + *pstr - '0';
		++pstr;
	}
	return res;
}
f01009fc:	5b                   	pop    %ebx
f01009fd:	5d                   	pop    %ebp
f01009fe:	c3                   	ret    

f01009ff <mon_showmappings>:
	return 0;
}

int
mon_showmappings(int argc, char **argv, struct Trapframe *tf)
{ 
f01009ff:	55                   	push   %ebp
f0100a00:	89 e5                	mov    %esp,%ebp
f0100a02:	57                   	push   %edi
f0100a03:	56                   	push   %esi
f0100a04:	53                   	push   %ebx
f0100a05:	83 ec 2c             	sub    $0x2c,%esp
f0100a08:	8b 75 0c             	mov    0xc(%ebp),%esi
	if(argc != 3) {
f0100a0b:	83 7d 08 03          	cmpl   $0x3,0x8(%ebp)
f0100a0f:	74 11                	je     f0100a22 <mon_showmappings+0x23>
   	  	cprintf("Make sure the correct style: showmappings 0xbegin_addr 0xend_addr\n");
f0100a11:	c7 04 24 f8 49 10 f0 	movl   $0xf01049f8,(%esp)
f0100a18:	e8 76 2a 00 00       	call   f0103493 <cprintf>
		return 0;
f0100a1d:	e9 4e 01 00 00       	jmp    f0100b70 <mon_showmappings+0x171>
	}	 
	//将地址字符串转换int，然后判断低12位是不是0
	uint32_t begin = jz_xtoi(argv[1]), end = jz_xtoi(argv[2]);
f0100a22:	8b 46 04             	mov    0x4(%esi),%eax
f0100a25:	89 04 24             	mov    %eax,(%esp)
f0100a28:	e8 8e ff ff ff       	call   f01009bb <jz_xtoi>
f0100a2d:	89 c3                	mov    %eax,%ebx
f0100a2f:	8b 46 08             	mov    0x8(%esi),%eax
f0100a32:	89 04 24             	mov    %eax,(%esp)
f0100a35:	e8 81 ff ff ff       	call   f01009bb <jz_xtoi>
f0100a3a:	89 c6                	mov    %eax,%esi
f0100a3c:	09 d8                	or     %ebx,%eax
	if((begin & 0xfff) != 0 || (end & 0xfff) != 0 ){
f0100a3e:	a9 ff 0f 00 00       	test   $0xfff,%eax
f0100a43:	74 11                	je     f0100a56 <mon_showmappings+0x57>
		cprintf("Make sure the addr's low 12 bits is zero\n");
f0100a45:	c7 04 24 3c 4a 10 f0 	movl   $0xf0104a3c,(%esp)
f0100a4c:	e8 42 2a 00 00       	call   f0103493 <cprintf>
		return 0;
f0100a51:	e9 1a 01 00 00       	jmp    f0100b70 <mon_showmappings+0x171>
	}
	cprintf("Attention! You may test addr above UPAGES(0xef000000)\n");
f0100a56:	c7 04 24 68 4a 10 f0 	movl   $0xf0104a68,(%esp)
f0100a5d:	e8 31 2a 00 00       	call   f0103493 <cprintf>
	cprintf("begin:%p, end:%p\n",begin,end);
f0100a62:	89 74 24 08          	mov    %esi,0x8(%esp)
f0100a66:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100a6a:	c7 04 24 ab 47 10 f0 	movl   $0xf01047ab,(%esp)
f0100a71:	e8 1d 2a 00 00       	call   f0103493 <cprintf>

static __inline uint32_t
rcr3(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr3,%0" : "=r" (val));
f0100a76:	0f 20 df             	mov    %cr3,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a79:	89 f8                	mov    %edi,%eax
f0100a7b:	c1 e8 0c             	shr    $0xc,%eax
f0100a7e:	3b 05 64 99 11 f0    	cmp    0xf0119964,%eax
f0100a84:	72 20                	jb     f0100aa6 <mon_showmappings+0xa7>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a86:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0100a8a:	c7 44 24 08 a0 4a 10 	movl   $0xf0104aa0,0x8(%esp)
f0100a91:	f0 
f0100a92:	c7 44 24 04 bf 00 00 	movl   $0xbf,0x4(%esp)
f0100a99:	00 
f0100a9a:	c7 04 24 bd 47 10 f0 	movl   $0xf01047bd,(%esp)
f0100aa1:	e8 ee f5 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100aa6:	81 ef 00 00 00 10    	sub    $0x10000000,%edi
	pde_t *kpgdir = KADDR(rcr3()), *pde; 
	pte_t *pte, *p;
	uint32_t va;
	for (va = begin; va <= end; va += PGSIZE) 
f0100aac:	e9 b7 00 00 00       	jmp    f0100b68 <mon_showmappings+0x169>
	{ 
		//or you can use pgdir_walk
		pde = &kpgdir[PDX(va)];
f0100ab1:	89 d8                	mov    %ebx,%eax
f0100ab3:	c1 e8 16             	shr    $0x16,%eax
		if (*pde & PTE_P){ 
f0100ab6:	8b 04 87             	mov    (%edi,%eax,4),%eax
f0100ab9:	a8 01                	test   $0x1,%al
f0100abb:	0f 84 91 00 00 00    	je     f0100b52 <mon_showmappings+0x153>
			pte = (pte_t*) KADDR(PTE_ADDR(*pde)); 
f0100ac1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ac6:	89 c2                	mov    %eax,%edx
f0100ac8:	c1 ea 0c             	shr    $0xc,%edx
f0100acb:	3b 15 64 99 11 f0    	cmp    0xf0119964,%edx
f0100ad1:	72 20                	jb     f0100af3 <mon_showmappings+0xf4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ad3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ad7:	c7 44 24 08 a0 4a 10 	movl   $0xf0104aa0,0x8(%esp)
f0100ade:	f0 
f0100adf:	c7 44 24 04 c7 00 00 	movl   $0xc7,0x4(%esp)
f0100ae6:	00 
f0100ae7:	c7 04 24 bd 47 10 f0 	movl   $0xf01047bd,(%esp)
f0100aee:	e8 a1 f5 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100af3:	8d 90 00 00 00 f0    	lea    -0x10000000(%eax),%edx
			if (*pte & PTE_P){ 
f0100af9:	f6 80 00 00 00 f0 01 	testb  $0x1,-0x10000000(%eax)
f0100b00:	74 3e                	je     f0100b40 <mon_showmappings+0x141>
				p = &pte[PTX(va)];
f0100b02:	89 d8                	mov    %ebx,%eax
f0100b04:	c1 e8 0c             	shr    $0xc,%eax
f0100b07:	25 ff 03 00 00       	and    $0x3ff,%eax
				cprintf("va: %p, pa: %p, PTE_P: %x, PTE_W: %x, PTE_U: %x\n", 
					va, *p, *p&PTE_P, *p&PTE_W, *p&PTE_U);			
f0100b0c:	8b 04 82             	mov    (%edx,%eax,4),%eax
		pde = &kpgdir[PDX(va)];
		if (*pde & PTE_P){ 
			pte = (pte_t*) KADDR(PTE_ADDR(*pde)); 
			if (*pte & PTE_P){ 
				p = &pte[PTX(va)];
				cprintf("va: %p, pa: %p, PTE_P: %x, PTE_W: %x, PTE_U: %x\n", 
f0100b0f:	89 c2                	mov    %eax,%edx
f0100b11:	83 e2 04             	and    $0x4,%edx
f0100b14:	89 54 24 14          	mov    %edx,0x14(%esp)
f0100b18:	89 c2                	mov    %eax,%edx
f0100b1a:	83 e2 02             	and    $0x2,%edx
f0100b1d:	89 54 24 10          	mov    %edx,0x10(%esp)
f0100b21:	89 c2                	mov    %eax,%edx
f0100b23:	83 e2 01             	and    $0x1,%edx
f0100b26:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100b2a:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100b2e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100b32:	c7 04 24 c4 4a 10 f0 	movl   $0xf0104ac4,(%esp)
f0100b39:	e8 55 29 00 00       	call   f0103493 <cprintf>
f0100b3e:	eb 22                	jmp    f0100b62 <mon_showmappings+0x163>
					va, *p, *p&PTE_P, *p&PTE_W, *p&PTE_U);			
			} else {
				cprintf("page mapping not exist: %x\n", va);
f0100b40:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100b44:	c7 04 24 cc 47 10 f0 	movl   $0xf01047cc,(%esp)
f0100b4b:	e8 43 29 00 00       	call   f0103493 <cprintf>
f0100b50:	eb 10                	jmp    f0100b62 <mon_showmappings+0x163>
			}
		} else {
			cprintf("page mapping not exist: %x\n", va);
f0100b52:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100b56:	c7 04 24 cc 47 10 f0 	movl   $0xf01047cc,(%esp)
f0100b5d:	e8 31 29 00 00       	call   f0103493 <cprintf>
	cprintf("Attention! You may test addr above UPAGES(0xef000000)\n");
	cprintf("begin:%p, end:%p\n",begin,end);
	pde_t *kpgdir = KADDR(rcr3()), *pde; 
	pte_t *pte, *p;
	uint32_t va;
	for (va = begin; va <= end; va += PGSIZE) 
f0100b62:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100b68:	39 f3                	cmp    %esi,%ebx
f0100b6a:	0f 86 41 ff ff ff    	jbe    f0100ab1 <mon_showmappings+0xb2>
		} else {
			cprintf("page mapping not exist: %x\n", va);
		}
	}
	return 0;
}
f0100b70:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b75:	83 c4 2c             	add    $0x2c,%esp
f0100b78:	5b                   	pop    %ebx
f0100b79:	5e                   	pop    %esi
f0100b7a:	5f                   	pop    %edi
f0100b7b:	5d                   	pop    %ebp
f0100b7c:	c3                   	ret    

f0100b7d <mon_setpermissions>:

int 
mon_setpermissions(int argc, char **argv, struct Trapframe *tf)
{ 
f0100b7d:	55                   	push   %ebp
f0100b7e:	89 e5                	mov    %esp,%ebp
f0100b80:	56                   	push   %esi
f0100b81:	53                   	push   %ebx
f0100b82:	83 ec 20             	sub    $0x20,%esp
	if(argc != 4) {
f0100b85:	83 7d 08 04          	cmpl   $0x4,0x8(%ebp)
f0100b89:	74 11                	je     f0100b9c <mon_setpermissions+0x1f>
   	  	cprintf("Make sure the correct style: setpermissions 0xaddr [0|1 :clear or set] [P|W|U]\n");
f0100b8b:	c7 04 24 f8 4a 10 f0 	movl   $0xf0104af8,(%esp)
f0100b92:	e8 fc 28 00 00       	call   f0103493 <cprintf>
		return 0;
f0100b97:	e9 4b 01 00 00       	jmp    f0100ce7 <mon_setpermissions+0x16a>
	}	 
	//将地址字符串转换int，然后判断低12位是不是0
	uint32_t va = jz_xtoi(argv[1]);
f0100b9c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100b9f:	8b 40 04             	mov    0x4(%eax),%eax
f0100ba2:	89 04 24             	mov    %eax,(%esp)
f0100ba5:	e8 11 fe ff ff       	call   f01009bb <jz_xtoi>
f0100baa:	89 c3                	mov    %eax,%ebx
	if((va & 0xfff) != 0 ){
f0100bac:	a9 ff 0f 00 00       	test   $0xfff,%eax
f0100bb1:	74 11                	je     f0100bc4 <mon_setpermissions+0x47>
		cprintf("Make sure the addr's low 12 bits is zero\n");
f0100bb3:	c7 04 24 3c 4a 10 f0 	movl   $0xf0104a3c,(%esp)
f0100bba:	e8 d4 28 00 00       	call   f0103493 <cprintf>
		return 0;
f0100bbf:	e9 23 01 00 00       	jmp    f0100ce7 <mon_setpermissions+0x16a>
f0100bc4:	0f 20 d8             	mov    %cr3,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100bc7:	89 c2                	mov    %eax,%edx
f0100bc9:	c1 ea 0c             	shr    $0xc,%edx
f0100bcc:	3b 15 64 99 11 f0    	cmp    0xf0119964,%edx
f0100bd2:	72 20                	jb     f0100bf4 <mon_setpermissions+0x77>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100bd4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100bd8:	c7 44 24 08 a0 4a 10 	movl   $0xf0104aa0,0x8(%esp)
f0100bdf:	f0 
f0100be0:	c7 44 24 04 e4 00 00 	movl   $0xe4,0x4(%esp)
f0100be7:	00 
f0100be8:	c7 04 24 bd 47 10 f0 	movl   $0xf01047bd,(%esp)
f0100bef:	e8 a0 f4 ff ff       	call   f0100094 <_panic>
	}

	pte_t *pte = pgdir_walk((pde_t *)KADDR(rcr3()),(void *)va,false);
f0100bf4:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100bfb:	00 
f0100bfc:	89 5c 24 04          	mov    %ebx,0x4(%esp)
	return (void *)(pa + KERNBASE);
f0100c00:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c05:	89 04 24             	mov    %eax,(%esp)
f0100c08:	e8 e9 09 00 00       	call   f01015f6 <pgdir_walk>
f0100c0d:	89 c6                	mov    %eax,%esi
	if (pte && (*pte & PTE_P)){  
f0100c0f:	85 c0                	test   %eax,%eax
f0100c11:	0f 84 c0 00 00 00    	je     f0100cd7 <mon_setpermissions+0x15a>
f0100c17:	f6 00 01             	testb  $0x1,(%eax)
f0100c1a:	0f 84 b7 00 00 00    	je     f0100cd7 <mon_setpermissions+0x15a>
		cprintf("before setpermissions %p\n",va);
f0100c20:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100c24:	c7 04 24 e8 47 10 f0 	movl   $0xf01047e8,(%esp)
f0100c2b:	e8 63 28 00 00       	call   f0103493 <cprintf>
		cprintf("va: %p, pa: %p, PTE_P: %x, PTE_W: %x, PTE_U: %x\n", 
			va, *pte, *pte&PTE_P, *pte&PTE_W, *pte&PTE_U);			
f0100c30:	8b 06                	mov    (%esi),%eax
	}

	pte_t *pte = pgdir_walk((pde_t *)KADDR(rcr3()),(void *)va,false);
	if (pte && (*pte & PTE_P)){  
		cprintf("before setpermissions %p\n",va);
		cprintf("va: %p, pa: %p, PTE_P: %x, PTE_W: %x, PTE_U: %x\n", 
f0100c32:	89 c2                	mov    %eax,%edx
f0100c34:	83 e2 04             	and    $0x4,%edx
f0100c37:	89 54 24 14          	mov    %edx,0x14(%esp)
f0100c3b:	89 c2                	mov    %eax,%edx
f0100c3d:	83 e2 02             	and    $0x2,%edx
f0100c40:	89 54 24 10          	mov    %edx,0x10(%esp)
f0100c44:	89 c2                	mov    %eax,%edx
f0100c46:	83 e2 01             	and    $0x1,%edx
f0100c49:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100c4d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100c51:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100c55:	c7 04 24 c4 4a 10 f0 	movl   $0xf0104ac4,(%esp)
f0100c5c:	e8 32 28 00 00       	call   f0103493 <cprintf>
			va, *pte, *pte&PTE_P, *pte&PTE_W, *pte&PTE_U);			
		uint32_t perm = 0;
	    if (argv[3][0] == 'P') perm = PTE_P;
f0100c61:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100c64:	8b 40 0c             	mov    0xc(%eax),%eax
f0100c67:	0f b6 00             	movzbl (%eax),%eax
	    if (argv[3][0] == 'W') perm = PTE_W;
f0100c6a:	ba 02 00 00 00       	mov    $0x2,%edx
f0100c6f:	3c 57                	cmp    $0x57,%al
f0100c71:	74 0e                	je     f0100c81 <mon_setpermissions+0x104>
	    if (argv[3][0] == 'U') perm = PTE_U;
f0100c73:	b2 04                	mov    $0x4,%dl
f0100c75:	3c 55                	cmp    $0x55,%al
f0100c77:	74 08                	je     f0100c81 <mon_setpermissions+0x104>
	if (pte && (*pte & PTE_P)){  
		cprintf("before setpermissions %p\n",va);
		cprintf("va: %p, pa: %p, PTE_P: %x, PTE_W: %x, PTE_U: %x\n", 
			va, *pte, *pte&PTE_P, *pte&PTE_W, *pte&PTE_U);			
		uint32_t perm = 0;
	    if (argv[3][0] == 'P') perm = PTE_P;
f0100c79:	3c 50                	cmp    $0x50,%al
f0100c7b:	0f 94 c2             	sete   %dl
f0100c7e:	0f b6 d2             	movzbl %dl,%edx
	    if (argv[3][0] == 'W') perm = PTE_W;
	    if (argv[3][0] == 'U') perm = PTE_U;
	    if (argv[2][0] == '0')  //clear
f0100c81:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100c84:	8b 40 08             	mov    0x8(%eax),%eax
f0100c87:	80 38 30             	cmpb   $0x30,(%eax)
f0100c8a:	75 06                	jne    f0100c92 <mon_setpermissions+0x115>
	        *pte = *pte & ~perm;
f0100c8c:	f7 d2                	not    %edx
f0100c8e:	21 16                	and    %edx,(%esi)
f0100c90:	eb 02                	jmp    f0100c94 <mon_setpermissions+0x117>
	    else    //set
	        *pte = *pte | perm;
f0100c92:	09 16                	or     %edx,(%esi)
	    cprintf("after setpermissions %p\n",va);
f0100c94:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100c98:	c7 04 24 02 48 10 f0 	movl   $0xf0104802,(%esp)
f0100c9f:	e8 ef 27 00 00       	call   f0103493 <cprintf>
		cprintf("va: %p, pa: %p, PTE_P: %x, PTE_W: %x, PTE_U: %x\n", 
			va, *pte, *pte&PTE_P, *pte&PTE_W, *pte&PTE_U);		
f0100ca4:	8b 06                	mov    (%esi),%eax
	    if (argv[2][0] == '0')  //clear
	        *pte = *pte & ~perm;
	    else    //set
	        *pte = *pte | perm;
	    cprintf("after setpermissions %p\n",va);
		cprintf("va: %p, pa: %p, PTE_P: %x, PTE_W: %x, PTE_U: %x\n", 
f0100ca6:	89 c2                	mov    %eax,%edx
f0100ca8:	83 e2 04             	and    $0x4,%edx
f0100cab:	89 54 24 14          	mov    %edx,0x14(%esp)
f0100caf:	89 c2                	mov    %eax,%edx
f0100cb1:	83 e2 02             	and    $0x2,%edx
f0100cb4:	89 54 24 10          	mov    %edx,0x10(%esp)
f0100cb8:	89 c2                	mov    %eax,%edx
f0100cba:	83 e2 01             	and    $0x1,%edx
f0100cbd:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100cc1:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100cc5:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100cc9:	c7 04 24 c4 4a 10 f0 	movl   $0xf0104ac4,(%esp)
f0100cd0:	e8 be 27 00 00       	call   f0103493 <cprintf>
		cprintf("Make sure the addr's low 12 bits is zero\n");
		return 0;
	}

	pte_t *pte = pgdir_walk((pde_t *)KADDR(rcr3()),(void *)va,false);
	if (pte && (*pte & PTE_P)){  
f0100cd5:	eb 10                	jmp    f0100ce7 <mon_setpermissions+0x16a>
	        *pte = *pte | perm;
	    cprintf("after setpermissions %p\n",va);
		cprintf("va: %p, pa: %p, PTE_P: %x, PTE_W: %x, PTE_U: %x\n", 
			va, *pte, *pte&PTE_P, *pte&PTE_W, *pte&PTE_U);		
	} else {
		cprintf("page mapping not exist: %x\n", va);
f0100cd7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100cdb:	c7 04 24 cc 47 10 f0 	movl   $0xf01047cc,(%esp)
f0100ce2:	e8 ac 27 00 00       	call   f0103493 <cprintf>
	}
	return 0;
}
f0100ce7:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cec:	83 c4 20             	add    $0x20,%esp
f0100cef:	5b                   	pop    %ebx
f0100cf0:	5e                   	pop    %esi
f0100cf1:	5d                   	pop    %ebp
f0100cf2:	c3                   	ret    

f0100cf3 <mon_dumpcontents>:
 
int 
mon_dumpcontents(int argc, char **argv, struct Trapframe *tf)
{ 
f0100cf3:	55                   	push   %ebp
f0100cf4:	89 e5                	mov    %esp,%ebp
f0100cf6:	57                   	push   %edi
f0100cf7:	56                   	push   %esi
f0100cf8:	53                   	push   %ebx
f0100cf9:	83 ec 1c             	sub    $0x1c,%esp
	if(argc != 4) {
f0100cfc:	83 7d 08 04          	cmpl   $0x4,0x8(%ebp)
f0100d00:	74 11                	je     f0100d13 <mon_dumpcontents+0x20>
   	  	cprintf("Make sure the correct style: dumpcontents [p|v :physical or virtual] 0x3000 10\n");
f0100d02:	c7 04 24 48 4b 10 f0 	movl   $0xf0104b48,(%esp)
f0100d09:	e8 85 27 00 00       	call   f0103493 <cprintf>
		return 0;
f0100d0e:	e9 9e 00 00 00       	jmp    f0100db1 <mon_dumpcontents+0xbe>
	}	  
	void** begin = NULL;
	long length = strtol(argv[3],0,0);
f0100d13:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100d1a:	00 
f0100d1b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100d22:	00 
f0100d23:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d26:	8b 40 0c             	mov    0xc(%eax),%eax
f0100d29:	89 04 24             	mov    %eax,(%esp)
f0100d2c:	e8 02 34 00 00       	call   f0104133 <strtol>
f0100d31:	89 c7                	mov    %eax,%edi
	uint32_t i; 
 	if (argv[1][0] == 'p') {
f0100d33:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d36:	8b 40 04             	mov    0x4(%eax),%eax
f0100d39:	0f b6 00             	movzbl (%eax),%eax
f0100d3c:	3c 70                	cmp    $0x70,%al
f0100d3e:	75 16                	jne    f0100d56 <mon_dumpcontents+0x63>
		begin = (void**)(jz_xtoi(argv[2]) + KERNBASE);  
f0100d40:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d43:	8b 40 08             	mov    0x8(%eax),%eax
f0100d46:	89 04 24             	mov    %eax,(%esp)
f0100d49:	e8 6d fc ff ff       	call   f01009bb <jz_xtoi>
f0100d4e:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi
f0100d54:	eb 1b                	jmp    f0100d71 <mon_dumpcontents+0x7e>
	} else if (argv[1][0] == 'v') {  
		begin = (void**)(jz_xtoi(argv[2])); 
	}
	if(begin > begin + length){
f0100d56:	89 fb                	mov    %edi,%ebx
{ 
	if(argc != 4) {
   	  	cprintf("Make sure the correct style: dumpcontents [p|v :physical or virtual] 0x3000 10\n");
		return 0;
	}	  
	void** begin = NULL;
f0100d58:	be 00 00 00 00       	mov    $0x0,%esi
	long length = strtol(argv[3],0,0);
	uint32_t i; 
 	if (argv[1][0] == 'p') {
		begin = (void**)(jz_xtoi(argv[2]) + KERNBASE);  
	} else if (argv[1][0] == 'v') {  
f0100d5d:	3c 76                	cmp    $0x76,%al
f0100d5f:	75 49                	jne    f0100daa <mon_dumpcontents+0xb7>
		begin = (void**)(jz_xtoi(argv[2])); 
f0100d61:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d64:	8b 40 08             	mov    0x8(%eax),%eax
f0100d67:	89 04 24             	mov    %eax,(%esp)
f0100d6a:	e8 4c fc ff ff       	call   f01009bb <jz_xtoi>
f0100d6f:	89 c6                	mov    %eax,%esi
	}
	if(begin > begin + length){
f0100d71:	89 fb                	mov    %edi,%ebx
f0100d73:	8d 04 be             	lea    (%esi,%edi,4),%eax
f0100d76:	39 c6                	cmp    %eax,%esi
f0100d78:	76 30                	jbe    f0100daa <mon_dumpcontents+0xb7>
		cprintf("out of range.");
f0100d7a:	c7 04 24 1b 48 10 f0 	movl   $0xf010481b,(%esp)
f0100d81:	e8 0d 27 00 00       	call   f0103493 <cprintf>
f0100d86:	eb 22                	jmp    f0100daa <mon_dumpcontents+0xb7>
	}
    for (i = 0; i < length; ++i){
        cprintf("va at %x is %x\n", begin+i, begin[i]);
f0100d88:	8b 06                	mov    (%esi),%eax
f0100d8a:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d8e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100d92:	c7 04 24 29 48 10 f0 	movl   $0xf0104829,(%esp)
f0100d99:	e8 f5 26 00 00       	call   f0103493 <cprintf>
		begin = (void**)(jz_xtoi(argv[2])); 
	}
	if(begin > begin + length){
		cprintf("out of range.");
	}
    for (i = 0; i < length; ++i){
f0100d9e:	83 c7 01             	add    $0x1,%edi
f0100da1:	83 c6 04             	add    $0x4,%esi
f0100da4:	39 df                	cmp    %ebx,%edi
f0100da6:	75 e0                	jne    f0100d88 <mon_dumpcontents+0x95>
f0100da8:	eb 07                	jmp    f0100db1 <mon_dumpcontents+0xbe>
	return 0;
}
 
int 
mon_dumpcontents(int argc, char **argv, struct Trapframe *tf)
{ 
f0100daa:	bf 00 00 00 00       	mov    $0x0,%edi
f0100daf:	eb f3                	jmp    f0100da4 <mon_dumpcontents+0xb1>
	}
    for (i = 0; i < length; ++i){
        cprintf("va at %x is %x\n", begin+i, begin[i]);
    }
	return 0; 
}
f0100db1:	b8 00 00 00 00       	mov    $0x0,%eax
f0100db6:	83 c4 1c             	add    $0x1c,%esp
f0100db9:	5b                   	pop    %ebx
f0100dba:	5e                   	pop    %esi
f0100dbb:	5f                   	pop    %edi
f0100dbc:	5d                   	pop    %ebp
f0100dbd:	c3                   	ret    

f0100dbe <jz_strstr>:
	}
	return res;
}

char *jz_strstr(const char*s1,const char*s2)
{
f0100dbe:	55                   	push   %ebp
f0100dbf:	89 e5                	mov    %esp,%ebp
f0100dc1:	53                   	push   %ebx
f0100dc2:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0100dc5:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100dc8:	89 c8                	mov    %ecx,%eax
    int n;
    if(*s2)
f0100dca:	80 3a 00             	cmpb   $0x0,(%edx)
f0100dcd:	74 2d                	je     f0100dfc <jz_strstr+0x3e>
f0100dcf:	eb 16                	jmp    f0100de7 <jz_strstr+0x29>
    {
        while(*s1)
        {
            for(n=0;*(s1+n)==*(s2+n);n++)
            {
                if(!*(s2+n+1))
f0100dd1:	80 7c 02 01 00       	cmpb   $0x0,0x1(%edx,%eax,1)
f0100dd6:	74 1b                	je     f0100df3 <jz_strstr+0x35>
    int n;
    if(*s2)
    {
        while(*s1)
        {
            for(n=0;*(s1+n)==*(s2+n);n++)
f0100dd8:	83 c0 01             	add    $0x1,%eax
f0100ddb:	0f b6 1c 02          	movzbl (%edx,%eax,1),%ebx
f0100ddf:	38 1c 01             	cmp    %bl,(%ecx,%eax,1)
f0100de2:	74 ed                	je     f0100dd1 <jz_strstr+0x13>
            {
                if(!*(s2+n+1))
                    return(char*)s1;
            }
            s1++;
f0100de4:	83 c1 01             	add    $0x1,%ecx
char *jz_strstr(const char*s1,const char*s2)
{
    int n;
    if(*s2)
    {
        while(*s1)
f0100de7:	80 39 00             	cmpb   $0x0,(%ecx)
f0100dea:	74 0b                	je     f0100df7 <jz_strstr+0x39>
f0100dec:	b8 00 00 00 00       	mov    $0x0,%eax
f0100df1:	eb e8                	jmp    f0100ddb <jz_strstr+0x1d>
f0100df3:	89 c8                	mov    %ecx,%eax
f0100df5:	eb 05                	jmp    f0100dfc <jz_strstr+0x3e>
                if(!*(s2+n+1))
                    return(char*)s1;
            }
            s1++;
        }
        return NULL;
f0100df7:	b8 00 00 00 00       	mov    $0x0,%eax
    }
    else
        return (char*)s1;
}
f0100dfc:	5b                   	pop    %ebx
f0100dfd:	5d                   	pop    %ebp
f0100dfe:	c3                   	ret    

f0100dff <mon_setcolor>:

int
mon_setcolor(int argc, char **argv, struct Trapframe *tf)
{ 
f0100dff:	55                   	push   %ebp
f0100e00:	89 e5                	mov    %esp,%ebp
f0100e02:	56                   	push   %esi
f0100e03:	53                   	push   %ebx
f0100e04:	83 ec 10             	sub    $0x10,%esp
f0100e07:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	if(argc < 3) {
f0100e0a:	83 7d 08 02          	cmpl   $0x2,0x8(%ebp)
f0100e0e:	7f 0e                	jg     f0100e1e <mon_setcolor+0x1f>
   	  	cprintf("Make sure the correct style: setcolor bg=[color] ch=[color]\n");
f0100e10:	c7 04 24 98 4b 10 f0 	movl   $0xf0104b98,(%esp)
f0100e17:	e8 77 26 00 00       	call   f0103493 <cprintf>
		return 0;
f0100e1c:	eb 3a                	jmp    f0100e58 <mon_setcolor+0x59>
	}	 
	setcolor(jz_strstr(argv[1],"=")+1,jz_strstr(argv[2],"=")+1); 
f0100e1e:	c7 44 24 04 39 48 10 	movl   $0xf0104839,0x4(%esp)
f0100e25:	f0 
f0100e26:	8b 43 08             	mov    0x8(%ebx),%eax
f0100e29:	89 04 24             	mov    %eax,(%esp)
f0100e2c:	e8 8d ff ff ff       	call   f0100dbe <jz_strstr>
f0100e31:	89 c6                	mov    %eax,%esi
f0100e33:	c7 44 24 04 39 48 10 	movl   $0xf0104839,0x4(%esp)
f0100e3a:	f0 
f0100e3b:	8b 43 04             	mov    0x4(%ebx),%eax
f0100e3e:	89 04 24             	mov    %eax,(%esp)
f0100e41:	e8 78 ff ff ff       	call   f0100dbe <jz_strstr>
f0100e46:	83 c6 01             	add    $0x1,%esi
f0100e49:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100e4d:	83 c0 01             	add    $0x1,%eax
f0100e50:	89 04 24             	mov    %eax,(%esp)
f0100e53:	e8 42 f5 ff ff       	call   f010039a <setcolor>
	return 0;
}
f0100e58:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e5d:	83 c4 10             	add    $0x10,%esp
f0100e60:	5b                   	pop    %ebx
f0100e61:	5e                   	pop    %esi
f0100e62:	5d                   	pop    %ebp
f0100e63:	c3                   	ret    

f0100e64 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100e64:	55                   	push   %ebp
f0100e65:	89 e5                	mov    %esp,%ebp
f0100e67:	57                   	push   %edi
f0100e68:	56                   	push   %esi
f0100e69:	53                   	push   %ebx
f0100e6a:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100e6d:	c7 04 24 d8 4b 10 f0 	movl   $0xf0104bd8,(%esp)
f0100e74:	e8 1a 26 00 00       	call   f0103493 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100e79:	c7 04 24 fc 4b 10 f0 	movl   $0xf0104bfc,(%esp)
f0100e80:	e8 0e 26 00 00       	call   f0103493 <cprintf>


	while (1) {
		buf = readline("K> ");
f0100e85:	c7 04 24 3b 48 10 f0 	movl   $0xf010483b,(%esp)
f0100e8c:	e8 1f 2f 00 00       	call   f0103db0 <readline>
f0100e91:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100e93:	85 c0                	test   %eax,%eax
f0100e95:	74 ee                	je     f0100e85 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100e97:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100e9e:	be 00 00 00 00       	mov    $0x0,%esi
f0100ea3:	eb 0a                	jmp    f0100eaf <monitor+0x4b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100ea5:	c6 03 00             	movb   $0x0,(%ebx)
f0100ea8:	89 f7                	mov    %esi,%edi
f0100eaa:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100ead:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100eaf:	0f b6 03             	movzbl (%ebx),%eax
f0100eb2:	84 c0                	test   %al,%al
f0100eb4:	74 63                	je     f0100f19 <monitor+0xb5>
f0100eb6:	0f be c0             	movsbl %al,%eax
f0100eb9:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ebd:	c7 04 24 3f 48 10 f0 	movl   $0xf010483f,(%esp)
f0100ec4:	e8 01 31 00 00       	call   f0103fca <strchr>
f0100ec9:	85 c0                	test   %eax,%eax
f0100ecb:	75 d8                	jne    f0100ea5 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f0100ecd:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100ed0:	74 47                	je     f0100f19 <monitor+0xb5>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100ed2:	83 fe 0f             	cmp    $0xf,%esi
f0100ed5:	75 16                	jne    f0100eed <monitor+0x89>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100ed7:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100ede:	00 
f0100edf:	c7 04 24 44 48 10 f0 	movl   $0xf0104844,(%esp)
f0100ee6:	e8 a8 25 00 00       	call   f0103493 <cprintf>
f0100eeb:	eb 98                	jmp    f0100e85 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f0100eed:	8d 7e 01             	lea    0x1(%esi),%edi
f0100ef0:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100ef4:	eb 03                	jmp    f0100ef9 <monitor+0x95>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100ef6:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100ef9:	0f b6 03             	movzbl (%ebx),%eax
f0100efc:	84 c0                	test   %al,%al
f0100efe:	74 ad                	je     f0100ead <monitor+0x49>
f0100f00:	0f be c0             	movsbl %al,%eax
f0100f03:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f07:	c7 04 24 3f 48 10 f0 	movl   $0xf010483f,(%esp)
f0100f0e:	e8 b7 30 00 00       	call   f0103fca <strchr>
f0100f13:	85 c0                	test   %eax,%eax
f0100f15:	74 df                	je     f0100ef6 <monitor+0x92>
f0100f17:	eb 94                	jmp    f0100ead <monitor+0x49>
			buf++;
	}
	argv[argc] = 0;
f0100f19:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100f20:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100f21:	85 f6                	test   %esi,%esi
f0100f23:	0f 84 5c ff ff ff    	je     f0100e85 <monitor+0x21>
f0100f29:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100f2e:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100f31:	8b 04 85 a0 4e 10 f0 	mov    -0xfefb160(,%eax,4),%eax
f0100f38:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f3c:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100f3f:	89 04 24             	mov    %eax,(%esp)
f0100f42:	e8 25 30 00 00       	call   f0103f6c <strcmp>
f0100f47:	85 c0                	test   %eax,%eax
f0100f49:	75 24                	jne    f0100f6f <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f0100f4b:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100f4e:	8b 55 08             	mov    0x8(%ebp),%edx
f0100f51:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100f55:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100f58:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100f5c:	89 34 24             	mov    %esi,(%esp)
f0100f5f:	ff 14 85 a8 4e 10 f0 	call   *-0xfefb158(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100f66:	85 c0                	test   %eax,%eax
f0100f68:	78 25                	js     f0100f8f <monitor+0x12b>
f0100f6a:	e9 16 ff ff ff       	jmp    f0100e85 <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100f6f:	83 c3 01             	add    $0x1,%ebx
f0100f72:	83 fb 07             	cmp    $0x7,%ebx
f0100f75:	75 b7                	jne    f0100f2e <monitor+0xca>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100f77:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100f7a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f7e:	c7 04 24 61 48 10 f0 	movl   $0xf0104861,(%esp)
f0100f85:	e8 09 25 00 00       	call   f0103493 <cprintf>
f0100f8a:	e9 f6 fe ff ff       	jmp    f0100e85 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100f8f:	83 c4 5c             	add    $0x5c,%esp
f0100f92:	5b                   	pop    %ebx
f0100f93:	5e                   	pop    %esi
f0100f94:	5f                   	pop    %edi
f0100f95:	5d                   	pop    %ebp
f0100f96:	c3                   	ret    
f0100f97:	66 90                	xchg   %ax,%ax
f0100f99:	66 90                	xchg   %ax,%ax
f0100f9b:	66 90                	xchg   %ax,%ax
f0100f9d:	66 90                	xchg   %ax,%ax
f0100f9f:	90                   	nop

f0100fa0 <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100fa0:	83 3d 3c 95 11 f0 00 	cmpl   $0x0,0xf011953c
f0100fa7:	75 11                	jne    f0100fba <boot_alloc+0x1a>
		//外部字符数组变量 edata 和 end，其中 edata 表示的是 bss 节在内
		//存中开始的位置，而 end 则是表示内核可执行程序在内存中结束的位置。
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100fa9:	ba 6f a9 11 f0       	mov    $0xf011a96f,%edx
f0100fae:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100fb4:	89 15 3c 95 11 f0    	mov    %edx,0xf011953c
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	// How to judge that out of bound? How to use base-mem or ext-mem?
	result = nextfree;  // 虚拟地址
f0100fba:	8b 0d 3c 95 11 f0    	mov    0xf011953c,%ecx
	nextfree = ROUNDUP(nextfree + n, PGSIZE);
f0100fc0:	8d 94 01 ff 0f 00 00 	lea    0xfff(%ecx,%eax,1),%edx
f0100fc7:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100fcd:	89 15 3c 95 11 f0    	mov    %edx,0xf011953c
	if((uint32_t)nextfree - KERNBASE > npages * PGSIZE){ //npages * PGSIZE是可用的物理地址上限
f0100fd3:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0100fd9:	a1 64 99 11 f0       	mov    0xf0119964,%eax
f0100fde:	c1 e0 0c             	shl    $0xc,%eax
f0100fe1:	39 c2                	cmp    %eax,%edx
f0100fe3:	76 22                	jbe    f0101007 <boot_alloc+0x67>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100fe5:	55                   	push   %ebp
f0100fe6:	89 e5                	mov    %esp,%ebp
f0100fe8:	83 ec 18             	sub    $0x18,%esp
	// LAB 2: Your code here.
	// How to judge that out of bound? How to use base-mem or ext-mem?
	result = nextfree;  // 虚拟地址
	nextfree = ROUNDUP(nextfree + n, PGSIZE);
	if((uint32_t)nextfree - KERNBASE > npages * PGSIZE){ //npages * PGSIZE是可用的物理地址上限
		panic("out of memory");
f0100feb:	c7 44 24 08 f4 4e 10 	movl   $0xf0104ef4,0x8(%esp)
f0100ff2:	f0 
f0100ff3:	c7 44 24 04 6f 00 00 	movl   $0x6f,0x4(%esp)
f0100ffa:	00 
f0100ffb:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0101002:	e8 8d f0 ff ff       	call   f0100094 <_panic>
	} 
	return result; 
}
f0101007:	89 c8                	mov    %ecx,%eax
f0101009:	c3                   	ret    

f010100a <page2kva>:
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp) //求出当前页的物理地址
{
	return (pp - pages) << PGSHIFT;
f010100a:	2b 05 6c 99 11 f0    	sub    0xf011996c,%eax
f0101010:	c1 f8 03             	sar    $0x3,%eax
f0101013:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101016:	89 c2                	mov    %eax,%edx
f0101018:	c1 ea 0c             	shr    $0xc,%edx
f010101b:	3b 15 64 99 11 f0    	cmp    0xf0119964,%edx
f0101021:	72 26                	jb     f0101049 <page2kva+0x3f>
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp) //根据页信息求物理地址，并转化为内核虚拟地址
{
f0101023:	55                   	push   %ebp
f0101024:	89 e5                	mov    %esp,%ebp
f0101026:	83 ec 18             	sub    $0x18,%esp

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101029:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010102d:	c7 44 24 08 a0 4a 10 	movl   $0xf0104aa0,0x8(%esp)
f0101034:	f0 
f0101035:	c7 44 24 04 54 00 00 	movl   $0x54,0x4(%esp)
f010103c:	00 
f010103d:	c7 04 24 0e 4f 10 f0 	movl   $0xf0104f0e,(%esp)
f0101044:	e8 4b f0 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101049:	2d 00 00 00 10       	sub    $0x10000000,%eax

static inline void*
page2kva(struct PageInfo *pp) //根据页信息求物理地址，并转化为内核虚拟地址
{
	return KADDR(page2pa(pp)); // see in the file
}
f010104e:	c3                   	ret    

f010104f <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f010104f:	89 d1                	mov    %edx,%ecx
f0101051:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0101054:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0101057:	a8 01                	test   $0x1,%al
f0101059:	74 5d                	je     f01010b8 <check_va2pa+0x69>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f010105b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101060:	89 c1                	mov    %eax,%ecx
f0101062:	c1 e9 0c             	shr    $0xc,%ecx
f0101065:	3b 0d 64 99 11 f0    	cmp    0xf0119964,%ecx
f010106b:	72 26                	jb     f0101093 <check_va2pa+0x44>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f010106d:	55                   	push   %ebp
f010106e:	89 e5                	mov    %esp,%ebp
f0101070:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101073:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101077:	c7 44 24 08 a0 4a 10 	movl   $0xf0104aa0,0x8(%esp)
f010107e:	f0 
f010107f:	c7 44 24 04 58 03 00 	movl   $0x358,0x4(%esp)
f0101086:	00 
f0101087:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f010108e:	e8 01 f0 ff ff       	call   f0100094 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0101093:	c1 ea 0c             	shr    $0xc,%edx
f0101096:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f010109c:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f01010a3:	89 c2                	mov    %eax,%edx
f01010a5:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f01010a8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01010ad:	85 d2                	test   %edx,%edx
f01010af:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01010b4:	0f 44 c2             	cmove  %edx,%eax
f01010b7:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f01010b8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f01010bd:	c3                   	ret    

f01010be <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f01010be:	55                   	push   %ebp
f01010bf:	89 e5                	mov    %esp,%ebp
f01010c1:	57                   	push   %edi
f01010c2:	56                   	push   %esi
f01010c3:	53                   	push   %ebx
f01010c4:	83 ec 4c             	sub    $0x4c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01010c7:	84 c0                	test   %al,%al
f01010c9:	0f 85 07 03 00 00    	jne    f01013d6 <check_page_free_list+0x318>
f01010cf:	e9 14 03 00 00       	jmp    f01013e8 <check_page_free_list+0x32a>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f01010d4:	c7 44 24 08 18 52 10 	movl   $0xf0105218,0x8(%esp)
f01010db:	f0 
f01010dc:	c7 44 24 04 9b 02 00 	movl   $0x29b,0x4(%esp)
f01010e3:	00 
f01010e4:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f01010eb:	e8 a4 ef ff ff       	call   f0100094 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f01010f0:	8d 55 d8             	lea    -0x28(%ebp),%edx
f01010f3:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01010f6:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01010f9:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp) //求出当前页的物理地址
{
	return (pp - pages) << PGSHIFT;
f01010fc:	89 c2                	mov    %eax,%edx
f01010fe:	2b 15 6c 99 11 f0    	sub    0xf011996c,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0101104:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f010110a:	0f 95 c2             	setne  %dl
f010110d:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0101110:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0101114:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0101116:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f010111a:	8b 00                	mov    (%eax),%eax
f010111c:	85 c0                	test   %eax,%eax
f010111e:	75 dc                	jne    f01010fc <check_page_free_list+0x3e>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0101120:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101123:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0101129:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010112c:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010112f:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0101131:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101134:	a3 40 95 11 f0       	mov    %eax,0xf0119540
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0101139:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010113e:	8b 1d 40 95 11 f0    	mov    0xf0119540,%ebx
f0101144:	eb 63                	jmp    f01011a9 <check_page_free_list+0xeb>
f0101146:	89 d8                	mov    %ebx,%eax
f0101148:	2b 05 6c 99 11 f0    	sub    0xf011996c,%eax
f010114e:	c1 f8 03             	sar    $0x3,%eax
f0101151:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0101154:	89 c2                	mov    %eax,%edx
f0101156:	c1 ea 16             	shr    $0x16,%edx
f0101159:	39 f2                	cmp    %esi,%edx
f010115b:	73 4a                	jae    f01011a7 <check_page_free_list+0xe9>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010115d:	89 c2                	mov    %eax,%edx
f010115f:	c1 ea 0c             	shr    $0xc,%edx
f0101162:	3b 15 64 99 11 f0    	cmp    0xf0119964,%edx
f0101168:	72 20                	jb     f010118a <check_page_free_list+0xcc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010116a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010116e:	c7 44 24 08 a0 4a 10 	movl   $0xf0104aa0,0x8(%esp)
f0101175:	f0 
f0101176:	c7 44 24 04 54 00 00 	movl   $0x54,0x4(%esp)
f010117d:	00 
f010117e:	c7 04 24 0e 4f 10 f0 	movl   $0xf0104f0e,(%esp)
f0101185:	e8 0a ef ff ff       	call   f0100094 <_panic>
			memset(page2kva(pp), 0x97, 128);
f010118a:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0101191:	00 
f0101192:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0101199:	00 
	return (void *)(pa + KERNBASE);
f010119a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010119f:	89 04 24             	mov    %eax,(%esp)
f01011a2:	e8 60 2e 00 00       	call   f0104007 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01011a7:	8b 1b                	mov    (%ebx),%ebx
f01011a9:	85 db                	test   %ebx,%ebx
f01011ab:	75 99                	jne    f0101146 <check_page_free_list+0x88>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f01011ad:	b8 00 00 00 00       	mov    $0x0,%eax
f01011b2:	e8 e9 fd ff ff       	call   f0100fa0 <boot_alloc>
f01011b7:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f01011ba:	8b 15 40 95 11 f0    	mov    0xf0119540,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f01011c0:	8b 0d 6c 99 11 f0    	mov    0xf011996c,%ecx
		assert(pp < pages + npages);
f01011c6:	a1 64 99 11 f0       	mov    0xf0119964,%eax
f01011cb:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f01011ce:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f01011d1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f01011d4:	89 4d d0             	mov    %ecx,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f01011d7:	bf 00 00 00 00       	mov    $0x0,%edi
f01011dc:	89 5d cc             	mov    %ebx,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f01011df:	e9 97 01 00 00       	jmp    f010137b <check_page_free_list+0x2bd>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f01011e4:	39 ca                	cmp    %ecx,%edx
f01011e6:	73 24                	jae    f010120c <check_page_free_list+0x14e>
f01011e8:	c7 44 24 0c 1c 4f 10 	movl   $0xf0104f1c,0xc(%esp)
f01011ef:	f0 
f01011f0:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f01011f7:	f0 
f01011f8:	c7 44 24 04 b5 02 00 	movl   $0x2b5,0x4(%esp)
f01011ff:	00 
f0101200:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0101207:	e8 88 ee ff ff       	call   f0100094 <_panic>
		assert(pp < pages + npages);
f010120c:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f010120f:	72 24                	jb     f0101235 <check_page_free_list+0x177>
f0101211:	c7 44 24 0c 3d 4f 10 	movl   $0xf0104f3d,0xc(%esp)
f0101218:	f0 
f0101219:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0101220:	f0 
f0101221:	c7 44 24 04 b6 02 00 	movl   $0x2b6,0x4(%esp)
f0101228:	00 
f0101229:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0101230:	e8 5f ee ff ff       	call   f0100094 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0101235:	89 d0                	mov    %edx,%eax
f0101237:	2b 45 d0             	sub    -0x30(%ebp),%eax
f010123a:	a8 07                	test   $0x7,%al
f010123c:	74 24                	je     f0101262 <check_page_free_list+0x1a4>
f010123e:	c7 44 24 0c 3c 52 10 	movl   $0xf010523c,0xc(%esp)
f0101245:	f0 
f0101246:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f010124d:	f0 
f010124e:	c7 44 24 04 b7 02 00 	movl   $0x2b7,0x4(%esp)
f0101255:	00 
f0101256:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f010125d:	e8 32 ee ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp) //求出当前页的物理地址
{
	return (pp - pages) << PGSHIFT;
f0101262:	c1 f8 03             	sar    $0x3,%eax
f0101265:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0101268:	85 c0                	test   %eax,%eax
f010126a:	75 24                	jne    f0101290 <check_page_free_list+0x1d2>
f010126c:	c7 44 24 0c 51 4f 10 	movl   $0xf0104f51,0xc(%esp)
f0101273:	f0 
f0101274:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f010127b:	f0 
f010127c:	c7 44 24 04 ba 02 00 	movl   $0x2ba,0x4(%esp)
f0101283:	00 
f0101284:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f010128b:	e8 04 ee ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0101290:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0101295:	75 24                	jne    f01012bb <check_page_free_list+0x1fd>
f0101297:	c7 44 24 0c 62 4f 10 	movl   $0xf0104f62,0xc(%esp)
f010129e:	f0 
f010129f:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f01012a6:	f0 
f01012a7:	c7 44 24 04 bb 02 00 	movl   $0x2bb,0x4(%esp)
f01012ae:	00 
f01012af:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f01012b6:	e8 d9 ed ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f01012bb:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f01012c0:	75 24                	jne    f01012e6 <check_page_free_list+0x228>
f01012c2:	c7 44 24 0c 70 52 10 	movl   $0xf0105270,0xc(%esp)
f01012c9:	f0 
f01012ca:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f01012d1:	f0 
f01012d2:	c7 44 24 04 bc 02 00 	movl   $0x2bc,0x4(%esp)
f01012d9:	00 
f01012da:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f01012e1:	e8 ae ed ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f01012e6:	3d 00 00 10 00       	cmp    $0x100000,%eax
f01012eb:	75 24                	jne    f0101311 <check_page_free_list+0x253>
f01012ed:	c7 44 24 0c 7b 4f 10 	movl   $0xf0104f7b,0xc(%esp)
f01012f4:	f0 
f01012f5:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f01012fc:	f0 
f01012fd:	c7 44 24 04 bd 02 00 	movl   $0x2bd,0x4(%esp)
f0101304:	00 
f0101305:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f010130c:	e8 83 ed ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0101311:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0101316:	76 58                	jbe    f0101370 <check_page_free_list+0x2b2>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101318:	89 c3                	mov    %eax,%ebx
f010131a:	c1 eb 0c             	shr    $0xc,%ebx
f010131d:	39 5d c4             	cmp    %ebx,-0x3c(%ebp)
f0101320:	77 20                	ja     f0101342 <check_page_free_list+0x284>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101322:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101326:	c7 44 24 08 a0 4a 10 	movl   $0xf0104aa0,0x8(%esp)
f010132d:	f0 
f010132e:	c7 44 24 04 54 00 00 	movl   $0x54,0x4(%esp)
f0101335:	00 
f0101336:	c7 04 24 0e 4f 10 f0 	movl   $0xf0104f0e,(%esp)
f010133d:	e8 52 ed ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101342:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101347:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f010134a:	76 2a                	jbe    f0101376 <check_page_free_list+0x2b8>
f010134c:	c7 44 24 0c 94 52 10 	movl   $0xf0105294,0xc(%esp)
f0101353:	f0 
f0101354:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f010135b:	f0 
f010135c:	c7 44 24 04 be 02 00 	movl   $0x2be,0x4(%esp)
f0101363:	00 
f0101364:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f010136b:	e8 24 ed ff ff       	call   f0100094 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0101370:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
f0101374:	eb 03                	jmp    f0101379 <check_page_free_list+0x2bb>
		else
			++nfree_extmem;
f0101376:	83 c7 01             	add    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0101379:	8b 12                	mov    (%edx),%edx
f010137b:	85 d2                	test   %edx,%edx
f010137d:	0f 85 61 fe ff ff    	jne    f01011e4 <check_page_free_list+0x126>
f0101383:	8b 5d cc             	mov    -0x34(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0101386:	85 db                	test   %ebx,%ebx
f0101388:	7f 24                	jg     f01013ae <check_page_free_list+0x2f0>
f010138a:	c7 44 24 0c 95 4f 10 	movl   $0xf0104f95,0xc(%esp)
f0101391:	f0 
f0101392:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0101399:	f0 
f010139a:	c7 44 24 04 c6 02 00 	movl   $0x2c6,0x4(%esp)
f01013a1:	00 
f01013a2:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f01013a9:	e8 e6 ec ff ff       	call   f0100094 <_panic>
	assert(nfree_extmem > 0);
f01013ae:	85 ff                	test   %edi,%edi
f01013b0:	7f 4d                	jg     f01013ff <check_page_free_list+0x341>
f01013b2:	c7 44 24 0c a7 4f 10 	movl   $0xf0104fa7,0xc(%esp)
f01013b9:	f0 
f01013ba:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f01013c1:	f0 
f01013c2:	c7 44 24 04 c7 02 00 	movl   $0x2c7,0x4(%esp)
f01013c9:	00 
f01013ca:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f01013d1:	e8 be ec ff ff       	call   f0100094 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f01013d6:	a1 40 95 11 f0       	mov    0xf0119540,%eax
f01013db:	85 c0                	test   %eax,%eax
f01013dd:	0f 85 0d fd ff ff    	jne    f01010f0 <check_page_free_list+0x32>
f01013e3:	e9 ec fc ff ff       	jmp    f01010d4 <check_page_free_list+0x16>
f01013e8:	83 3d 40 95 11 f0 00 	cmpl   $0x0,0xf0119540
f01013ef:	0f 84 df fc ff ff    	je     f01010d4 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01013f5:	be 00 04 00 00       	mov    $0x400,%esi
f01013fa:	e9 3f fd ff ff       	jmp    f010113e <check_page_free_list+0x80>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f01013ff:	83 c4 4c             	add    $0x4c,%esp
f0101402:	5b                   	pop    %ebx
f0101403:	5e                   	pop    %esi
f0101404:	5f                   	pop    %edi
f0101405:	5d                   	pop    %ebp
f0101406:	c3                   	ret    

f0101407 <page_init>:
/*
	区分可用与不可用的内存页，设置双向链表，正向可遍历所有内存页，反向可遍历所有可用内存页
*/
void
page_init(void)
{
f0101407:	55                   	push   %ebp
f0101408:	89 e5                	mov    %esp,%ebp
f010140a:	56                   	push   %esi
f010140b:	53                   	push   %ebx
	// 对于存于物理地址1M后的数据，其虚拟地址减去KERNBASE的值相当于该处与内核代码存储起点虚拟地址位置的差，
	// 而不是与0x0的差, 需要加上1M的空间
	// 1M = 256 page 
	// uint32_t num_kernelpages = (((uint32_t) boot_alloc(0)) - KERNBASE) / PGSIZE;
	//uint32_t page_PageInfoEnd = npages_basemem + num_pages_io_hole + num_kernelpages; 
	uint32_t page_PageInfoEnd = (((uint32_t) boot_alloc(0)) - KERNBASE) / PGSIZE + 256;    
f010140c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101411:	e8 8a fb ff ff       	call   f0100fa0 <boot_alloc>
f0101416:	8d b0 00 00 00 10    	lea    0x10000000(%eax),%esi
f010141c:	c1 ee 0c             	shr    $0xc,%esi
f010141f:	81 c6 00 01 00 00    	add    $0x100,%esi
	 
	page_free_list = NULL;
	size_t i;
	//pages数组与实际物理空间存在映射关系，但没有使用实际空间存储物理页位置
	for (i = 0; i < npages; i++) {
f0101425:	bb 00 00 00 00       	mov    $0x0,%ebx
f010142a:	b8 00 00 00 00       	mov    $0x0,%eax
f010142f:	eb 42                	jmp    f0101473 <page_init+0x6c>
		if(i==0 ||
f0101431:	85 c0                	test   %eax,%eax
f0101433:	74 0d                	je     f0101442 <page_init+0x3b>
f0101435:	39 f0                	cmp    %esi,%eax
f0101437:	73 18                	jae    f0101451 <page_init+0x4a>
f0101439:	3d 9f 00 00 00       	cmp    $0x9f,%eax
f010143e:	66 90                	xchg   %ax,%ax
f0101440:	76 0f                	jbe    f0101451 <page_init+0x4a>

			//(i>=page_IOPHYSMEM && i<page_EXTPHYSMEMBEGIN) ||
			//(i>=page_EXTPHYSMEMBEGIN && i<page_PageInfoEnd) ||
			(i>=page_IOPHYSMEMBEGIN && i<page_PageInfoEnd)
			){
			pages[i].pp_ref = 1;
f0101442:	8b 15 6c 99 11 f0    	mov    0xf011996c,%edx
f0101448:	66 c7 44 c2 04 01 00 	movw   $0x1,0x4(%edx,%eax,8)
			continue;	
f010144f:	eb 1f                	jmp    f0101470 <page_init+0x69>
f0101451:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		} 
		pages[i].pp_ref = 0;		
f0101458:	8b 0d 6c 99 11 f0    	mov    0xf011996c,%ecx
f010145e:	66 c7 44 11 04 00 00 	movw   $0x0,0x4(%ecx,%edx,1)
		//往回指的指针pp_link要越过非空物理页,这样page_free_list才能通过pp_link往回获取空闲空间
		//双向链表
		pages[i].pp_link = page_free_list;
f0101465:	89 1c c1             	mov    %ebx,(%ecx,%eax,8)
		page_free_list = &pages[i];
f0101468:	89 d3                	mov    %edx,%ebx
f010146a:	03 1d 6c 99 11 f0    	add    0xf011996c,%ebx
	uint32_t page_PageInfoEnd = (((uint32_t) boot_alloc(0)) - KERNBASE) / PGSIZE + 256;    
	 
	page_free_list = NULL;
	size_t i;
	//pages数组与实际物理空间存在映射关系，但没有使用实际空间存储物理页位置
	for (i = 0; i < npages; i++) {
f0101470:	83 c0 01             	add    $0x1,%eax
f0101473:	3b 05 64 99 11 f0    	cmp    0xf0119964,%eax
f0101479:	72 b6                	jb     f0101431 <page_init+0x2a>
f010147b:	89 1d 40 95 11 f0    	mov    %ebx,0xf0119540
		//往回指的指针pp_link要越过非空物理页,这样page_free_list才能通过pp_link往回获取空闲空间
		//双向链表
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f0101481:	5b                   	pop    %ebx
f0101482:	5e                   	pop    %esi
f0101483:	5d                   	pop    %ebp
f0101484:	c3                   	ret    

f0101485 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0101485:	55                   	push   %ebp
f0101486:	89 e5                	mov    %esp,%ebp
f0101488:	53                   	push   %ebx
f0101489:	83 ec 14             	sub    $0x14,%esp
	// Fill this function in 
	if(!page_free_list) 
f010148c:	8b 1d 40 95 11 f0    	mov    0xf0119540,%ebx
f0101492:	85 db                	test   %ebx,%ebx
f0101494:	0f 84 9a 00 00 00    	je     f0101534 <page_alloc+0xaf>
		return NULL;
	struct PageInfo *p = page_free_list;
	assert(p->pp_ref == 0);
f010149a:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010149f:	74 24                	je     f01014c5 <page_alloc+0x40>
f01014a1:	c7 44 24 0c c2 4f 10 	movl   $0xf0104fc2,0xc(%esp)
f01014a8:	f0 
f01014a9:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f01014b0:	f0 
f01014b1:	c7 44 24 04 64 01 00 	movl   $0x164,0x4(%esp)
f01014b8:	00 
f01014b9:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f01014c0:	e8 cf eb ff ff       	call   f0100094 <_panic>
	page_free_list = p->pp_link;
f01014c5:	8b 03                	mov    (%ebx),%eax
f01014c7:	a3 40 95 11 f0       	mov    %eax,0xf0119540
	p->pp_link = NULL;
f01014cc:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if(alloc_flags & ALLOC_ZERO){
		memset(page2kva(p),'\0',PGSIZE);
	}
	return p;
f01014d2:	89 d8                	mov    %ebx,%eax
		return NULL;
	struct PageInfo *p = page_free_list;
	assert(p->pp_ref == 0);
	page_free_list = p->pp_link;
	p->pp_link = NULL;
	if(alloc_flags & ALLOC_ZERO){
f01014d4:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f01014d8:	74 5f                	je     f0101539 <page_alloc+0xb4>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp) //求出当前页的物理地址
{
	return (pp - pages) << PGSHIFT;
f01014da:	2b 05 6c 99 11 f0    	sub    0xf011996c,%eax
f01014e0:	c1 f8 03             	sar    $0x3,%eax
f01014e3:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01014e6:	89 c2                	mov    %eax,%edx
f01014e8:	c1 ea 0c             	shr    $0xc,%edx
f01014eb:	3b 15 64 99 11 f0    	cmp    0xf0119964,%edx
f01014f1:	72 20                	jb     f0101513 <page_alloc+0x8e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01014f3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01014f7:	c7 44 24 08 a0 4a 10 	movl   $0xf0104aa0,0x8(%esp)
f01014fe:	f0 
f01014ff:	c7 44 24 04 54 00 00 	movl   $0x54,0x4(%esp)
f0101506:	00 
f0101507:	c7 04 24 0e 4f 10 f0 	movl   $0xf0104f0e,(%esp)
f010150e:	e8 81 eb ff ff       	call   f0100094 <_panic>
		memset(page2kva(p),'\0',PGSIZE);
f0101513:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010151a:	00 
f010151b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101522:	00 
	return (void *)(pa + KERNBASE);
f0101523:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101528:	89 04 24             	mov    %eax,(%esp)
f010152b:	e8 d7 2a 00 00       	call   f0104007 <memset>
	}
	return p;
f0101530:	89 d8                	mov    %ebx,%eax
f0101532:	eb 05                	jmp    f0101539 <page_alloc+0xb4>
struct PageInfo *
page_alloc(int alloc_flags)
{
	// Fill this function in 
	if(!page_free_list) 
		return NULL;
f0101534:	b8 00 00 00 00       	mov    $0x0,%eax
	p->pp_link = NULL;
	if(alloc_flags & ALLOC_ZERO){
		memset(page2kva(p),'\0',PGSIZE);
	}
	return p;
}
f0101539:	83 c4 14             	add    $0x14,%esp
f010153c:	5b                   	pop    %ebx
f010153d:	5d                   	pop    %ebp
f010153e:	c3                   	ret    

f010153f <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f010153f:	55                   	push   %ebp
f0101540:	89 e5                	mov    %esp,%ebp
f0101542:	83 ec 18             	sub    $0x18,%esp
f0101545:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	assert(pp!=NULL);
f0101548:	85 c0                	test   %eax,%eax
f010154a:	75 24                	jne    f0101570 <page_free+0x31>
f010154c:	c7 44 24 0c b8 4f 10 	movl   $0xf0104fb8,0xc(%esp)
f0101553:	f0 
f0101554:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f010155b:	f0 
f010155c:	c7 44 24 04 77 01 00 	movl   $0x177,0x4(%esp)
f0101563:	00 
f0101564:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f010156b:	e8 24 eb ff ff       	call   f0100094 <_panic>
	assert(pp->pp_ref == 0);
f0101570:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101575:	74 24                	je     f010159b <page_free+0x5c>
f0101577:	c7 44 24 0c c1 4f 10 	movl   $0xf0104fc1,0xc(%esp)
f010157e:	f0 
f010157f:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0101586:	f0 
f0101587:	c7 44 24 04 78 01 00 	movl   $0x178,0x4(%esp)
f010158e:	00 
f010158f:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0101596:	e8 f9 ea ff ff       	call   f0100094 <_panic>
  	assert(pp->pp_link == NULL);
f010159b:	83 38 00             	cmpl   $0x0,(%eax)
f010159e:	74 24                	je     f01015c4 <page_free+0x85>
f01015a0:	c7 44 24 0c d1 4f 10 	movl   $0xf0104fd1,0xc(%esp)
f01015a7:	f0 
f01015a8:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f01015af:	f0 
f01015b0:	c7 44 24 04 79 01 00 	movl   $0x179,0x4(%esp)
f01015b7:	00 
f01015b8:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f01015bf:	e8 d0 ea ff ff       	call   f0100094 <_panic>
	//struct PageInfo* t = page_free_list;
	//page_free_list = pp;
	//page_free_list->pp_link = t;
	pp->pp_link = page_free_list;
f01015c4:	8b 15 40 95 11 f0    	mov    0xf0119540,%edx
f01015ca:	89 10                	mov    %edx,(%eax)
  	page_free_list = pp;
f01015cc:	a3 40 95 11 f0       	mov    %eax,0xf0119540
}
f01015d1:	c9                   	leave  
f01015d2:	c3                   	ret    

f01015d3 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f01015d3:	55                   	push   %ebp
f01015d4:	89 e5                	mov    %esp,%ebp
f01015d6:	83 ec 18             	sub    $0x18,%esp
f01015d9:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f01015dc:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f01015e0:	8d 51 ff             	lea    -0x1(%ecx),%edx
f01015e3:	66 89 50 04          	mov    %dx,0x4(%eax)
f01015e7:	66 85 d2             	test   %dx,%dx
f01015ea:	75 08                	jne    f01015f4 <page_decref+0x21>
		page_free(pp);
f01015ec:	89 04 24             	mov    %eax,(%esp)
f01015ef:	e8 4b ff ff ff       	call   f010153f <page_free>
}
f01015f4:	c9                   	leave  
f01015f5:	c3                   	ret    

f01015f6 <pgdir_walk>:

	pgdir_walk()只负责创建二级页表，然后返回索引位置，不对页表做处理，也不做其对物理页映射
*/
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f01015f6:	55                   	push   %ebp
f01015f7:	89 e5                	mov    %esp,%ebp
f01015f9:	56                   	push   %esi
f01015fa:	53                   	push   %ebx
f01015fb:	83 ec 10             	sub    $0x10,%esp
f01015fe:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in 
	//首先获取页目录项位置,使用指针指向其索引位置
	pde_t *pde = &pgdir[PDX(va)];  
f0101601:	89 f3                	mov    %esi,%ebx
f0101603:	c1 eb 16             	shr    $0x16,%ebx
f0101606:	c1 e3 02             	shl    $0x2,%ebx
f0101609:	03 5d 08             	add    0x8(%ebp),%ebx
	if(!(*pde & PTE_P) && !create)	return NULL; 
f010160c:	f6 03 01             	testb  $0x1,(%ebx)
f010160f:	75 2c                	jne    f010163d <pgdir_walk+0x47>
f0101611:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101615:	74 6c                	je     f0101683 <pgdir_walk+0x8d>
	if(!(*pde & PTE_P) && create){ //create
		struct PageInfo *pp = page_alloc(1);
f0101617:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010161e:	e8 62 fe ff ff       	call   f0101485 <page_alloc>
		if(pp==NULL){
f0101623:	85 c0                	test   %eax,%eax
f0101625:	74 63                	je     f010168a <pgdir_walk+0x94>
			return NULL;
		}
		pp->pp_ref++; 
f0101627:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp) //求出当前页的物理地址
{
	return (pp - pages) << PGSHIFT;
f010162c:	2b 05 6c 99 11 f0    	sub    0xf011996c,%eax
f0101632:	c1 f8 03             	sar    $0x3,%eax
f0101635:	c1 e0 0c             	shl    $0xc,%eax
		//kern R/W, user R/W
		*pde = (page2pa(pp) | PTE_P | PTE_U | PTE_W); 
f0101638:	83 c8 07             	or     $0x7,%eax
f010163b:	89 03                	mov    %eax,(%ebx)
	}
	//二级页表物理地址是4K对齐的，将其低12位清零然后转化为内核地址，使用指针指向它
	//注意：页目录和页表存的是物理地址，而指向页目录和页表的指针需要使用内核地址!!!
	pte_t *tbase =  KADDR(PTE_ADDR(*pde));
f010163d:	8b 03                	mov    (%ebx),%eax
f010163f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101644:	89 c2                	mov    %eax,%edx
f0101646:	c1 ea 0c             	shr    $0xc,%edx
f0101649:	3b 15 64 99 11 f0    	cmp    0xf0119964,%edx
f010164f:	72 20                	jb     f0101671 <pgdir_walk+0x7b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101651:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101655:	c7 44 24 08 a0 4a 10 	movl   $0xf0104aa0,0x8(%esp)
f010165c:	f0 
f010165d:	c7 44 24 04 be 01 00 	movl   $0x1be,0x4(%esp)
f0101664:	00 
f0101665:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f010166c:	e8 23 ea ff ff       	call   f0100094 <_panic>
	return &tbase[PTX(va)]; 
f0101671:	c1 ee 0a             	shr    $0xa,%esi
f0101674:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f010167a:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f0101681:	eb 0c                	jmp    f010168f <pgdir_walk+0x99>
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
	// Fill this function in 
	//首先获取页目录项位置,使用指针指向其索引位置
	pde_t *pde = &pgdir[PDX(va)];  
	if(!(*pde & PTE_P) && !create)	return NULL; 
f0101683:	b8 00 00 00 00       	mov    $0x0,%eax
f0101688:	eb 05                	jmp    f010168f <pgdir_walk+0x99>
	if(!(*pde & PTE_P) && create){ //create
		struct PageInfo *pp = page_alloc(1);
		if(pp==NULL){
			return NULL;
f010168a:	b8 00 00 00 00       	mov    $0x0,%eax
	}
	//二级页表物理地址是4K对齐的，将其低12位清零然后转化为内核地址，使用指针指向它
	//注意：页目录和页表存的是物理地址，而指向页目录和页表的指针需要使用内核地址!!!
	pte_t *tbase =  KADDR(PTE_ADDR(*pde));
	return &tbase[PTX(va)]; 
}
f010168f:	83 c4 10             	add    $0x10,%esp
f0101692:	5b                   	pop    %ebx
f0101693:	5e                   	pop    %esi
f0101694:	5d                   	pop    %ebp
f0101695:	c3                   	ret    

f0101696 <boot_map_region>:
	todo...可能存在的问题是：映射的是256M的内存，但是实际上只有64M可用的内存空间，
	这些内存空间有对应的页面管理结构，其中一部分被作为映射256M内存空间时的二级页表。
*/
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{ 
f0101696:	55                   	push   %ebp
f0101697:	89 e5                	mov    %esp,%ebp
f0101699:	57                   	push   %edi
f010169a:	56                   	push   %esi
f010169b:	53                   	push   %ebx
f010169c:	83 ec 2c             	sub    $0x2c,%esp
f010169f:	89 c7                	mov    %eax,%edi
f01016a1:	8b 45 08             	mov    0x8(%ebp),%eax
		check_kern_pgdir()函数会针对npages大小检测KERNBASE以上的地址映射情况，
		超过64M以上的物理内存不会被检测到，所以并没有导致出错。
		但严谨来说应该使用第一种情况。
	*/
	int i;
    for (i = 0; i < size/PGSIZE; ++i, va += PGSIZE, pa += PGSIZE) {
f01016a4:	c1 e9 0c             	shr    $0xc,%ecx
f01016a7:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f01016aa:	89 c3                	mov    %eax,%ebx
f01016ac:	be 00 00 00 00       	mov    $0x0,%esi
f01016b1:	29 c2                	sub    %eax,%edx
f01016b3:	89 55 e0             	mov    %edx,-0x20(%ebp)
        pte_t *pte = pgdir_walk(pgdir, (void *) va, 1); //create
        if (pte == NULL) panic("boot_map_region panic, out of memory");
        *pte = pa | perm | PTE_P;
f01016b6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01016b9:	83 c8 01             	or     $0x1,%eax
f01016bc:	89 45 dc             	mov    %eax,-0x24(%ebp)
		check_kern_pgdir()函数会针对npages大小检测KERNBASE以上的地址映射情况，
		超过64M以上的物理内存不会被检测到，所以并没有导致出错。
		但严谨来说应该使用第一种情况。
	*/
	int i;
    for (i = 0; i < size/PGSIZE; ++i, va += PGSIZE, pa += PGSIZE) {
f01016bf:	eb 49                	jmp    f010170a <boot_map_region+0x74>
        pte_t *pte = pgdir_walk(pgdir, (void *) va, 1); //create
f01016c1:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01016c8:	00 
f01016c9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01016cc:	01 d8                	add    %ebx,%eax
f01016ce:	89 44 24 04          	mov    %eax,0x4(%esp)
f01016d2:	89 3c 24             	mov    %edi,(%esp)
f01016d5:	e8 1c ff ff ff       	call   f01015f6 <pgdir_walk>
        if (pte == NULL) panic("boot_map_region panic, out of memory");
f01016da:	85 c0                	test   %eax,%eax
f01016dc:	75 1c                	jne    f01016fa <boot_map_region+0x64>
f01016de:	c7 44 24 08 dc 52 10 	movl   $0xf01052dc,0x8(%esp)
f01016e5:	f0 
f01016e6:	c7 44 24 04 00 02 00 	movl   $0x200,0x4(%esp)
f01016ed:	00 
f01016ee:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f01016f5:	e8 9a e9 ff ff       	call   f0100094 <_panic>
        *pte = pa | perm | PTE_P;
f01016fa:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01016fd:	09 da                	or     %ebx,%edx
f01016ff:	89 10                	mov    %edx,(%eax)
		check_kern_pgdir()函数会针对npages大小检测KERNBASE以上的地址映射情况，
		超过64M以上的物理内存不会被检测到，所以并没有导致出错。
		但严谨来说应该使用第一种情况。
	*/
	int i;
    for (i = 0; i < size/PGSIZE; ++i, va += PGSIZE, pa += PGSIZE) {
f0101701:	83 c6 01             	add    $0x1,%esi
f0101704:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010170a:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f010170d:	75 b2                	jne    f01016c1 <boot_map_region+0x2b>
        pte_t *pte = pgdir_walk(pgdir, (void *) va, 1); //create
        if (pte == NULL) panic("boot_map_region panic, out of memory");
        *pte = pa | perm | PTE_P;
    }
}
f010170f:	83 c4 2c             	add    $0x2c,%esp
f0101712:	5b                   	pop    %ebx
f0101713:	5e                   	pop    %esi
f0101714:	5f                   	pop    %edi
f0101715:	5d                   	pop    %ebp
f0101716:	c3                   	ret    

f0101717 <page_lookup>:
//page_lookup() 根据线性地址返回二级页表项所指的物理页对应的数据结构
//pte_store存储的是二级页表项的地址,设计这个向量的含义是：
//	当通过page_remove()移除线性地址对应的物理页时，可以清空二级页表项的内容。
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101717:	55                   	push   %ebp
f0101718:	89 e5                	mov    %esp,%ebp
f010171a:	53                   	push   %ebx
f010171b:	83 ec 14             	sub    $0x14,%esp
f010171e:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	//获得二级页表项位置,不允许创建二级页表
	pte_t *pte = pgdir_walk(pgdir,va,false);
f0101721:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101728:	00 
f0101729:	8b 45 0c             	mov    0xc(%ebp),%eax
f010172c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101730:	8b 45 08             	mov    0x8(%ebp),%eax
f0101733:	89 04 24             	mov    %eax,(%esp)
f0101736:	e8 bb fe ff ff       	call   f01015f6 <pgdir_walk>
	if(pte == NULL) return NULL;
f010173b:	85 c0                	test   %eax,%eax
f010173d:	74 3f                	je     f010177e <page_lookup+0x67>
	if(!(*pte & PTE_P)) return NULL;
f010173f:	f6 00 01             	testb  $0x1,(%eax)
f0101742:	74 41                	je     f0101785 <page_lookup+0x6e>
 
	if(pte_store){
f0101744:	85 db                	test   %ebx,%ebx
f0101746:	74 02                	je     f010174a <page_lookup+0x33>
		*pte_store = pte;
f0101748:	89 03                	mov    %eax,(%ebx)
	} 
	//*pte的内容已经是物理地址，将其低12位清零
	return pa2page(PTE_ADDR(*pte));  
f010174a:	8b 00                	mov    (%eax),%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010174c:	c1 e8 0c             	shr    $0xc,%eax
f010174f:	3b 05 64 99 11 f0    	cmp    0xf0119964,%eax
f0101755:	72 1c                	jb     f0101773 <page_lookup+0x5c>
		panic("pa2page called with invalid pa");
f0101757:	c7 44 24 08 04 53 10 	movl   $0xf0105304,0x8(%esp)
f010175e:	f0 
f010175f:	c7 44 24 04 4d 00 00 	movl   $0x4d,0x4(%esp)
f0101766:	00 
f0101767:	c7 04 24 0e 4f 10 f0 	movl   $0xf0104f0e,(%esp)
f010176e:	e8 21 e9 ff ff       	call   f0100094 <_panic>
	return &pages[PGNUM(pa)];
f0101773:	8b 15 6c 99 11 f0    	mov    0xf011996c,%edx
f0101779:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f010177c:	eb 0c                	jmp    f010178a <page_lookup+0x73>
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	// Fill this function in
	//获得二级页表项位置,不允许创建二级页表
	pte_t *pte = pgdir_walk(pgdir,va,false);
	if(pte == NULL) return NULL;
f010177e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101783:	eb 05                	jmp    f010178a <page_lookup+0x73>
	if(!(*pte & PTE_P)) return NULL;
f0101785:	b8 00 00 00 00       	mov    $0x0,%eax
	if(pte_store){
		*pte_store = pte;
	} 
	//*pte的内容已经是物理地址，将其低12位清零
	return pa2page(PTE_ADDR(*pte));  
}
f010178a:	83 c4 14             	add    $0x14,%esp
f010178d:	5b                   	pop    %ebx
f010178e:	5d                   	pop    %ebp
f010178f:	c3                   	ret    

f0101790 <page_remove>:
// 另一种情况是不同的线性地址映射到不同的二级页表项，且它们通过page_insert映射到同一个物理页，
// 这代表的是不同的二级页表项存取同一个物理页地址。
// 通过page_remove即可解除情况1到二级页表项的映射，在这里，一旦线性地址对应到二级页表项，即将其清空。
void
page_remove(pde_t *pgdir, void *va)
{
f0101790:	55                   	push   %ebp
f0101791:	89 e5                	mov    %esp,%ebp
f0101793:	53                   	push   %ebx
f0101794:	83 ec 24             	sub    $0x24,%esp
f0101797:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *pte;//pte指向的是二级页表项
	struct PageInfo *pp = page_lookup(pgdir,va,&pte);
f010179a:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010179d:	89 44 24 08          	mov    %eax,0x8(%esp)
f01017a1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01017a5:	8b 45 08             	mov    0x8(%ebp),%eax
f01017a8:	89 04 24             	mov    %eax,(%esp)
f01017ab:	e8 67 ff ff ff       	call   f0101717 <page_lookup>
	if(pp==NULL) return;
f01017b0:	85 c0                	test   %eax,%eax
f01017b2:	74 14                	je     f01017c8 <page_remove+0x38>
	page_decref(pp); 
f01017b4:	89 04 24             	mov    %eax,(%esp)
f01017b7:	e8 17 fe ff ff       	call   f01015d3 <page_decref>
	*pte = (*pte & 0);
f01017bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01017bf:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01017c5:	0f 01 3b             	invlpg (%ebx)
	tlb_invalidate(pgdir,va); 
}
f01017c8:	83 c4 24             	add    $0x24,%esp
f01017cb:	5b                   	pop    %ebx
f01017cc:	5d                   	pop    %ebp
f01017cd:	c3                   	ret    

f01017ce <page_insert>:
// and page2pa.
//
// 将映射物理页的PageInfo数据结构的地址及访问权限存于线性地址所对应的二级页表项内。
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f01017ce:	55                   	push   %ebp
f01017cf:	89 e5                	mov    %esp,%ebp
f01017d1:	57                   	push   %edi
f01017d2:	56                   	push   %esi
f01017d3:	53                   	push   %ebx
f01017d4:	83 ec 1c             	sub    $0x1c,%esp
f01017d7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01017da:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in 
	pte_t *pte = pgdir_walk(pgdir,va,true); 
f01017dd:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01017e4:	00 
f01017e5:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01017e9:	8b 45 08             	mov    0x8(%ebp),%eax
f01017ec:	89 04 24             	mov    %eax,(%esp)
f01017ef:	e8 02 fe ff ff       	call   f01015f6 <pgdir_walk>
f01017f4:	89 c6                	mov    %eax,%esi
	if(pte == NULL) return -1; 
f01017f6:	85 c0                	test   %eax,%eax
f01017f8:	0f 84 86 00 00 00    	je     f0101884 <page_insert+0xb6>
	if(*pte & PTE_P){ //already a page mapped at 'va'
f01017fe:	8b 00                	mov    (%eax),%eax
f0101800:	a8 01                	test   $0x1,%al
f0101802:	74 5b                	je     f010185f <page_insert+0x91>
		//*pte的内容已经是物理地址，将其低12位清零
		//如果是相同页的话，应该允许修改权限,直接返回0。注意这里不能先remove再insert，因为一旦remove，
		//pp可能因为引用为0而被释放，进而page_free_list指向这块内存页，将其标记为可用，而此时pp的物理页是不可用的。
	    if(pa2page(PTE_ADDR(*pte)) == pp) {
f0101804:	25 00 f0 ff ff       	and    $0xfffff000,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101809:	89 c2                	mov    %eax,%edx
f010180b:	c1 ea 0c             	shr    $0xc,%edx
f010180e:	3b 15 64 99 11 f0    	cmp    0xf0119964,%edx
f0101814:	72 1c                	jb     f0101832 <page_insert+0x64>
		panic("pa2page called with invalid pa");
f0101816:	c7 44 24 08 04 53 10 	movl   $0xf0105304,0x8(%esp)
f010181d:	f0 
f010181e:	c7 44 24 04 4d 00 00 	movl   $0x4d,0x4(%esp)
f0101825:	00 
f0101826:	c7 04 24 0e 4f 10 f0 	movl   $0xf0104f0e,(%esp)
f010182d:	e8 62 e8 ff ff       	call   f0100094 <_panic>
	return &pages[PGNUM(pa)];
f0101832:	8b 0d 6c 99 11 f0    	mov    0xf011996c,%ecx
f0101838:	8d 14 d1             	lea    (%ecx,%edx,8),%edx
f010183b:	39 d3                	cmp    %edx,%ebx
f010183d:	75 11                	jne    f0101850 <page_insert+0x82>
	    	//允许修改权限，包括降低权限, 所以这里清空低12位
	    	*pte = PTE_ADDR(*pte) | perm | PTE_P;
f010183f:	8b 55 14             	mov    0x14(%ebp),%edx
f0101842:	83 ca 01             	or     $0x1,%edx
f0101845:	09 d0                	or     %edx,%eax
f0101847:	89 06                	mov    %eax,(%esi)
	    	return 0; 
f0101849:	b8 00 00 00 00       	mov    $0x0,%eax
f010184e:	eb 39                	jmp    f0101889 <page_insert+0xbb>
	    }
		else page_remove(pgdir,va);
f0101850:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101854:	8b 45 08             	mov    0x8(%ebp),%eax
f0101857:	89 04 24             	mov    %eax,(%esp)
f010185a:	e8 31 ff ff ff       	call   f0101790 <page_remove>
	}
	pp->pp_ref += 1;
f010185f:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	*pte = (page2pa(pp) | perm | PTE_P);
f0101864:	8b 45 14             	mov    0x14(%ebp),%eax
f0101867:	83 c8 01             	or     $0x1,%eax
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp) //求出当前页的物理地址
{
	return (pp - pages) << PGSHIFT;
f010186a:	2b 1d 6c 99 11 f0    	sub    0xf011996c,%ebx
f0101870:	c1 fb 03             	sar    $0x3,%ebx
f0101873:	c1 e3 0c             	shl    $0xc,%ebx
f0101876:	09 c3                	or     %eax,%ebx
f0101878:	89 1e                	mov    %ebx,(%esi)
f010187a:	0f 01 3f             	invlpg (%edi)
	tlb_invalidate(pgdir,va);
	return 0;
f010187d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101882:	eb 05                	jmp    f0101889 <page_insert+0xbb>
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	// Fill this function in 
	pte_t *pte = pgdir_walk(pgdir,va,true); 
	if(pte == NULL) return -1; 
f0101884:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	}
	pp->pp_ref += 1;
	*pte = (page2pa(pp) | perm | PTE_P);
	tlb_invalidate(pgdir,va);
	return 0;
}
f0101889:	83 c4 1c             	add    $0x1c,%esp
f010188c:	5b                   	pop    %ebx
f010188d:	5e                   	pop    %esi
f010188e:	5f                   	pop    %edi
f010188f:	5d                   	pop    %ebp
f0101890:	c3                   	ret    

f0101891 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101891:	55                   	push   %ebp
f0101892:	89 e5                	mov    %esp,%ebp
f0101894:	57                   	push   %edi
f0101895:	56                   	push   %esi
f0101896:	53                   	push   %ebx
f0101897:	83 ec 4c             	sub    $0x4c,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010189a:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
f01018a1:	e8 7d 1b 00 00       	call   f0103423 <mc146818_read>
f01018a6:	89 c3                	mov    %eax,%ebx
f01018a8:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f01018af:	e8 6f 1b 00 00       	call   f0103423 <mc146818_read>
f01018b4:	c1 e0 08             	shl    $0x8,%eax
f01018b7:	09 c3                	or     %eax,%ebx
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f01018b9:	89 d8                	mov    %ebx,%eax
f01018bb:	c1 e0 0a             	shl    $0xa,%eax
f01018be:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01018c4:	85 c0                	test   %eax,%eax
f01018c6:	0f 48 c2             	cmovs  %edx,%eax
f01018c9:	c1 f8 0c             	sar    $0xc,%eax
f01018cc:	a3 44 95 11 f0       	mov    %eax,0xf0119544
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01018d1:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f01018d8:	e8 46 1b 00 00       	call   f0103423 <mc146818_read>
f01018dd:	89 c3                	mov    %eax,%ebx
f01018df:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f01018e6:	e8 38 1b 00 00       	call   f0103423 <mc146818_read>
f01018eb:	c1 e0 08             	shl    $0x8,%eax
f01018ee:	09 c3                	or     %eax,%ebx
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f01018f0:	89 d8                	mov    %ebx,%eax
f01018f2:	c1 e0 0a             	shl    $0xa,%eax
f01018f5:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01018fb:	85 c0                	test   %eax,%eax
f01018fd:	0f 48 c2             	cmovs  %edx,%eax
f0101900:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101903:	85 c0                	test   %eax,%eax
f0101905:	74 0e                	je     f0101915 <mem_init+0x84>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem; //EXTPHYSMEM = 0x100000
f0101907:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f010190d:	89 15 64 99 11 f0    	mov    %edx,0xf0119964
f0101913:	eb 0c                	jmp    f0101921 <mem_init+0x90>
	else
		npages = npages_basemem;
f0101915:	8b 15 44 95 11 f0    	mov    0xf0119544,%edx
f010191b:	89 15 64 99 11 f0    	mov    %edx,0xf0119964

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f0101921:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem; //EXTPHYSMEM = 0x100000
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101924:	c1 e8 0a             	shr    $0xa,%eax
f0101927:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f010192b:	a1 44 95 11 f0       	mov    0xf0119544,%eax
f0101930:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem; //EXTPHYSMEM = 0x100000
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101933:	c1 e8 0a             	shr    $0xa,%eax
f0101936:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f010193a:	a1 64 99 11 f0       	mov    0xf0119964,%eax
f010193f:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem; //EXTPHYSMEM = 0x100000
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101942:	c1 e8 0a             	shr    $0xa,%eax
f0101945:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101949:	c7 04 24 24 53 10 f0 	movl   $0xf0105324,(%esp)
f0101950:	e8 3e 1b 00 00       	call   f0103493 <cprintf>
	uint32_t cr0;
	size_t n;

	// Find out how much memory the machine has (npages & npages_basemem).
	i386_detect_memory();
	cprintf("%dM\n",npages*PGSIZE/1024/1024);
f0101955:	a1 64 99 11 f0       	mov    0xf0119964,%eax
f010195a:	c1 e0 0c             	shl    $0xc,%eax
f010195d:	c1 e8 14             	shr    $0x14,%eax
f0101960:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101964:	c7 04 24 e5 4f 10 f0 	movl   $0xf0104fe5,(%esp)
f010196b:	e8 23 1b 00 00       	call   f0103493 <cprintf>
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	// 为页目录分配 4KB 的空间
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101970:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101975:	e8 26 f6 ff ff       	call   f0100fa0 <boot_alloc>
f010197a:	a3 68 99 11 f0       	mov    %eax,0xf0119968
	memset(kern_pgdir, 0, PGSIZE);
f010197f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101986:	00 
f0101987:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010198e:	00 
f010198f:	89 04 24             	mov    %eax,(%esp)
f0101992:	e8 70 26 00 00       	call   f0104007 <memset>
		页目录每一项存放的是每个页表的起始物理地址，而页目录本身也是页表，因此需要在页目录里记录自身位置。
		UVPT（0xef400000）是页目录外部访问的固定起始线性地址，使用PDX函数取其页目录索引，
		然后将申请得到的页目录空间线性地址转化为物理地址，存于此索引处。
	*/
	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101997:	a1 68 99 11 f0       	mov    0xf0119968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva) // 在哪里并如何维护 __FILE__ 和 __LINE__?

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010199c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01019a1:	77 20                	ja     f01019c3 <mem_init+0x132>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01019a3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01019a7:	c7 44 24 08 60 53 10 	movl   $0xf0105360,0x8(%esp)
f01019ae:	f0 
f01019af:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
f01019b6:	00 
f01019b7:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f01019be:	e8 d1 e6 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01019c3:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01019c9:	83 ca 05             	or     $0x5,%edx
f01019cc:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	// 初始化pages结构体数组，该数组将用于管理所有可用的基本内存和扩展内存 
	pages = (struct PageInfo*)boot_alloc(npages*sizeof(struct PageInfo));
f01019d2:	a1 64 99 11 f0       	mov    0xf0119964,%eax
f01019d7:	c1 e0 03             	shl    $0x3,%eax
f01019da:	e8 c1 f5 ff ff       	call   f0100fa0 <boot_alloc>
f01019df:	a3 6c 99 11 f0       	mov    %eax,0xf011996c
	memset(pages,0,npages*sizeof(struct PageInfo)); 
f01019e4:	8b 0d 64 99 11 f0    	mov    0xf0119964,%ecx
f01019ea:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f01019f1:	89 54 24 08          	mov    %edx,0x8(%esp)
f01019f5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01019fc:	00 
f01019fd:	89 04 24             	mov    %eax,(%esp)
f0101a00:	e8 02 26 00 00       	call   f0104007 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101a05:	e8 fd f9 ff ff       	call   f0101407 <page_init>

	check_page_free_list(1);
f0101a0a:	b8 01 00 00 00       	mov    $0x1,%eax
f0101a0f:	e8 aa f6 ff ff       	call   f01010be <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101a14:	83 3d 6c 99 11 f0 00 	cmpl   $0x0,0xf011996c
f0101a1b:	75 1c                	jne    f0101a39 <mem_init+0x1a8>
		panic("'pages' is a null pointer!");
f0101a1d:	c7 44 24 08 ea 4f 10 	movl   $0xf0104fea,0x8(%esp)
f0101a24:	f0 
f0101a25:	c7 44 24 04 d8 02 00 	movl   $0x2d8,0x4(%esp)
f0101a2c:	00 
f0101a2d:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0101a34:	e8 5b e6 ff ff       	call   f0100094 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101a39:	a1 40 95 11 f0       	mov    0xf0119540,%eax
f0101a3e:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101a43:	eb 05                	jmp    f0101a4a <mem_init+0x1b9>
		++nfree;
f0101a45:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101a48:	8b 00                	mov    (%eax),%eax
f0101a4a:	85 c0                	test   %eax,%eax
f0101a4c:	75 f7                	jne    f0101a45 <mem_init+0x1b4>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101a4e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a55:	e8 2b fa ff ff       	call   f0101485 <page_alloc>
f0101a5a:	89 c7                	mov    %eax,%edi
f0101a5c:	85 c0                	test   %eax,%eax
f0101a5e:	75 24                	jne    f0101a84 <mem_init+0x1f3>
f0101a60:	c7 44 24 0c 05 50 10 	movl   $0xf0105005,0xc(%esp)
f0101a67:	f0 
f0101a68:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0101a6f:	f0 
f0101a70:	c7 44 24 04 e0 02 00 	movl   $0x2e0,0x4(%esp)
f0101a77:	00 
f0101a78:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0101a7f:	e8 10 e6 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101a84:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a8b:	e8 f5 f9 ff ff       	call   f0101485 <page_alloc>
f0101a90:	89 c6                	mov    %eax,%esi
f0101a92:	85 c0                	test   %eax,%eax
f0101a94:	75 24                	jne    f0101aba <mem_init+0x229>
f0101a96:	c7 44 24 0c 1b 50 10 	movl   $0xf010501b,0xc(%esp)
f0101a9d:	f0 
f0101a9e:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0101aa5:	f0 
f0101aa6:	c7 44 24 04 e1 02 00 	movl   $0x2e1,0x4(%esp)
f0101aad:	00 
f0101aae:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0101ab5:	e8 da e5 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101aba:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101ac1:	e8 bf f9 ff ff       	call   f0101485 <page_alloc>
f0101ac6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101ac9:	85 c0                	test   %eax,%eax
f0101acb:	75 24                	jne    f0101af1 <mem_init+0x260>
f0101acd:	c7 44 24 0c 31 50 10 	movl   $0xf0105031,0xc(%esp)
f0101ad4:	f0 
f0101ad5:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0101adc:	f0 
f0101add:	c7 44 24 04 e2 02 00 	movl   $0x2e2,0x4(%esp)
f0101ae4:	00 
f0101ae5:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0101aec:	e8 a3 e5 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101af1:	39 f7                	cmp    %esi,%edi
f0101af3:	75 24                	jne    f0101b19 <mem_init+0x288>
f0101af5:	c7 44 24 0c 47 50 10 	movl   $0xf0105047,0xc(%esp)
f0101afc:	f0 
f0101afd:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0101b04:	f0 
f0101b05:	c7 44 24 04 e5 02 00 	movl   $0x2e5,0x4(%esp)
f0101b0c:	00 
f0101b0d:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0101b14:	e8 7b e5 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101b19:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b1c:	39 c6                	cmp    %eax,%esi
f0101b1e:	74 04                	je     f0101b24 <mem_init+0x293>
f0101b20:	39 c7                	cmp    %eax,%edi
f0101b22:	75 24                	jne    f0101b48 <mem_init+0x2b7>
f0101b24:	c7 44 24 0c 84 53 10 	movl   $0xf0105384,0xc(%esp)
f0101b2b:	f0 
f0101b2c:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0101b33:	f0 
f0101b34:	c7 44 24 04 e6 02 00 	movl   $0x2e6,0x4(%esp)
f0101b3b:	00 
f0101b3c:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0101b43:	e8 4c e5 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp) //求出当前页的物理地址
{
	return (pp - pages) << PGSHIFT;
f0101b48:	8b 15 6c 99 11 f0    	mov    0xf011996c,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101b4e:	a1 64 99 11 f0       	mov    0xf0119964,%eax
f0101b53:	c1 e0 0c             	shl    $0xc,%eax
f0101b56:	89 f9                	mov    %edi,%ecx
f0101b58:	29 d1                	sub    %edx,%ecx
f0101b5a:	c1 f9 03             	sar    $0x3,%ecx
f0101b5d:	c1 e1 0c             	shl    $0xc,%ecx
f0101b60:	39 c1                	cmp    %eax,%ecx
f0101b62:	72 24                	jb     f0101b88 <mem_init+0x2f7>
f0101b64:	c7 44 24 0c 59 50 10 	movl   $0xf0105059,0xc(%esp)
f0101b6b:	f0 
f0101b6c:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0101b73:	f0 
f0101b74:	c7 44 24 04 e7 02 00 	movl   $0x2e7,0x4(%esp)
f0101b7b:	00 
f0101b7c:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0101b83:	e8 0c e5 ff ff       	call   f0100094 <_panic>
f0101b88:	89 f1                	mov    %esi,%ecx
f0101b8a:	29 d1                	sub    %edx,%ecx
f0101b8c:	c1 f9 03             	sar    $0x3,%ecx
f0101b8f:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f0101b92:	39 c8                	cmp    %ecx,%eax
f0101b94:	77 24                	ja     f0101bba <mem_init+0x329>
f0101b96:	c7 44 24 0c 76 50 10 	movl   $0xf0105076,0xc(%esp)
f0101b9d:	f0 
f0101b9e:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0101ba5:	f0 
f0101ba6:	c7 44 24 04 e8 02 00 	movl   $0x2e8,0x4(%esp)
f0101bad:	00 
f0101bae:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0101bb5:	e8 da e4 ff ff       	call   f0100094 <_panic>
f0101bba:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101bbd:	29 d1                	sub    %edx,%ecx
f0101bbf:	89 ca                	mov    %ecx,%edx
f0101bc1:	c1 fa 03             	sar    $0x3,%edx
f0101bc4:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f0101bc7:	39 d0                	cmp    %edx,%eax
f0101bc9:	77 24                	ja     f0101bef <mem_init+0x35e>
f0101bcb:	c7 44 24 0c 93 50 10 	movl   $0xf0105093,0xc(%esp)
f0101bd2:	f0 
f0101bd3:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0101bda:	f0 
f0101bdb:	c7 44 24 04 e9 02 00 	movl   $0x2e9,0x4(%esp)
f0101be2:	00 
f0101be3:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0101bea:	e8 a5 e4 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101bef:	a1 40 95 11 f0       	mov    0xf0119540,%eax
f0101bf4:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101bf7:	c7 05 40 95 11 f0 00 	movl   $0x0,0xf0119540
f0101bfe:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101c01:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c08:	e8 78 f8 ff ff       	call   f0101485 <page_alloc>
f0101c0d:	85 c0                	test   %eax,%eax
f0101c0f:	74 24                	je     f0101c35 <mem_init+0x3a4>
f0101c11:	c7 44 24 0c b0 50 10 	movl   $0xf01050b0,0xc(%esp)
f0101c18:	f0 
f0101c19:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0101c20:	f0 
f0101c21:	c7 44 24 04 f0 02 00 	movl   $0x2f0,0x4(%esp)
f0101c28:	00 
f0101c29:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0101c30:	e8 5f e4 ff ff       	call   f0100094 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101c35:	89 3c 24             	mov    %edi,(%esp)
f0101c38:	e8 02 f9 ff ff       	call   f010153f <page_free>
	page_free(pp1);
f0101c3d:	89 34 24             	mov    %esi,(%esp)
f0101c40:	e8 fa f8 ff ff       	call   f010153f <page_free>
	page_free(pp2);
f0101c45:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c48:	89 04 24             	mov    %eax,(%esp)
f0101c4b:	e8 ef f8 ff ff       	call   f010153f <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101c50:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c57:	e8 29 f8 ff ff       	call   f0101485 <page_alloc>
f0101c5c:	89 c6                	mov    %eax,%esi
f0101c5e:	85 c0                	test   %eax,%eax
f0101c60:	75 24                	jne    f0101c86 <mem_init+0x3f5>
f0101c62:	c7 44 24 0c 05 50 10 	movl   $0xf0105005,0xc(%esp)
f0101c69:	f0 
f0101c6a:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0101c71:	f0 
f0101c72:	c7 44 24 04 f7 02 00 	movl   $0x2f7,0x4(%esp)
f0101c79:	00 
f0101c7a:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0101c81:	e8 0e e4 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101c86:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c8d:	e8 f3 f7 ff ff       	call   f0101485 <page_alloc>
f0101c92:	89 c7                	mov    %eax,%edi
f0101c94:	85 c0                	test   %eax,%eax
f0101c96:	75 24                	jne    f0101cbc <mem_init+0x42b>
f0101c98:	c7 44 24 0c 1b 50 10 	movl   $0xf010501b,0xc(%esp)
f0101c9f:	f0 
f0101ca0:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0101ca7:	f0 
f0101ca8:	c7 44 24 04 f8 02 00 	movl   $0x2f8,0x4(%esp)
f0101caf:	00 
f0101cb0:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0101cb7:	e8 d8 e3 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101cbc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101cc3:	e8 bd f7 ff ff       	call   f0101485 <page_alloc>
f0101cc8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101ccb:	85 c0                	test   %eax,%eax
f0101ccd:	75 24                	jne    f0101cf3 <mem_init+0x462>
f0101ccf:	c7 44 24 0c 31 50 10 	movl   $0xf0105031,0xc(%esp)
f0101cd6:	f0 
f0101cd7:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0101cde:	f0 
f0101cdf:	c7 44 24 04 f9 02 00 	movl   $0x2f9,0x4(%esp)
f0101ce6:	00 
f0101ce7:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0101cee:	e8 a1 e3 ff ff       	call   f0100094 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101cf3:	39 fe                	cmp    %edi,%esi
f0101cf5:	75 24                	jne    f0101d1b <mem_init+0x48a>
f0101cf7:	c7 44 24 0c 47 50 10 	movl   $0xf0105047,0xc(%esp)
f0101cfe:	f0 
f0101cff:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0101d06:	f0 
f0101d07:	c7 44 24 04 fb 02 00 	movl   $0x2fb,0x4(%esp)
f0101d0e:	00 
f0101d0f:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0101d16:	e8 79 e3 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101d1b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d1e:	39 c7                	cmp    %eax,%edi
f0101d20:	74 04                	je     f0101d26 <mem_init+0x495>
f0101d22:	39 c6                	cmp    %eax,%esi
f0101d24:	75 24                	jne    f0101d4a <mem_init+0x4b9>
f0101d26:	c7 44 24 0c 84 53 10 	movl   $0xf0105384,0xc(%esp)
f0101d2d:	f0 
f0101d2e:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0101d35:	f0 
f0101d36:	c7 44 24 04 fc 02 00 	movl   $0x2fc,0x4(%esp)
f0101d3d:	00 
f0101d3e:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0101d45:	e8 4a e3 ff ff       	call   f0100094 <_panic>
	assert(!page_alloc(0));
f0101d4a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101d51:	e8 2f f7 ff ff       	call   f0101485 <page_alloc>
f0101d56:	85 c0                	test   %eax,%eax
f0101d58:	74 24                	je     f0101d7e <mem_init+0x4ed>
f0101d5a:	c7 44 24 0c b0 50 10 	movl   $0xf01050b0,0xc(%esp)
f0101d61:	f0 
f0101d62:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0101d69:	f0 
f0101d6a:	c7 44 24 04 fd 02 00 	movl   $0x2fd,0x4(%esp)
f0101d71:	00 
f0101d72:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0101d79:	e8 16 e3 ff ff       	call   f0100094 <_panic>
f0101d7e:	89 f0                	mov    %esi,%eax
f0101d80:	2b 05 6c 99 11 f0    	sub    0xf011996c,%eax
f0101d86:	c1 f8 03             	sar    $0x3,%eax
f0101d89:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101d8c:	89 c2                	mov    %eax,%edx
f0101d8e:	c1 ea 0c             	shr    $0xc,%edx
f0101d91:	3b 15 64 99 11 f0    	cmp    0xf0119964,%edx
f0101d97:	72 20                	jb     f0101db9 <mem_init+0x528>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101d99:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101d9d:	c7 44 24 08 a0 4a 10 	movl   $0xf0104aa0,0x8(%esp)
f0101da4:	f0 
f0101da5:	c7 44 24 04 54 00 00 	movl   $0x54,0x4(%esp)
f0101dac:	00 
f0101dad:	c7 04 24 0e 4f 10 f0 	movl   $0xf0104f0e,(%esp)
f0101db4:	e8 db e2 ff ff       	call   f0100094 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101db9:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101dc0:	00 
f0101dc1:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0101dc8:	00 
	return (void *)(pa + KERNBASE);
f0101dc9:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101dce:	89 04 24             	mov    %eax,(%esp)
f0101dd1:	e8 31 22 00 00       	call   f0104007 <memset>
	page_free(pp0);
f0101dd6:	89 34 24             	mov    %esi,(%esp)
f0101dd9:	e8 61 f7 ff ff       	call   f010153f <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101dde:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101de5:	e8 9b f6 ff ff       	call   f0101485 <page_alloc>
f0101dea:	85 c0                	test   %eax,%eax
f0101dec:	75 24                	jne    f0101e12 <mem_init+0x581>
f0101dee:	c7 44 24 0c bf 50 10 	movl   $0xf01050bf,0xc(%esp)
f0101df5:	f0 
f0101df6:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0101dfd:	f0 
f0101dfe:	c7 44 24 04 02 03 00 	movl   $0x302,0x4(%esp)
f0101e05:	00 
f0101e06:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0101e0d:	e8 82 e2 ff ff       	call   f0100094 <_panic>
	assert(pp && pp0 == pp);
f0101e12:	39 c6                	cmp    %eax,%esi
f0101e14:	74 24                	je     f0101e3a <mem_init+0x5a9>
f0101e16:	c7 44 24 0c dd 50 10 	movl   $0xf01050dd,0xc(%esp)
f0101e1d:	f0 
f0101e1e:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0101e25:	f0 
f0101e26:	c7 44 24 04 03 03 00 	movl   $0x303,0x4(%esp)
f0101e2d:	00 
f0101e2e:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0101e35:	e8 5a e2 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp) //求出当前页的物理地址
{
	return (pp - pages) << PGSHIFT;
f0101e3a:	89 f0                	mov    %esi,%eax
f0101e3c:	2b 05 6c 99 11 f0    	sub    0xf011996c,%eax
f0101e42:	c1 f8 03             	sar    $0x3,%eax
f0101e45:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101e48:	89 c2                	mov    %eax,%edx
f0101e4a:	c1 ea 0c             	shr    $0xc,%edx
f0101e4d:	3b 15 64 99 11 f0    	cmp    0xf0119964,%edx
f0101e53:	72 20                	jb     f0101e75 <mem_init+0x5e4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101e55:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101e59:	c7 44 24 08 a0 4a 10 	movl   $0xf0104aa0,0x8(%esp)
f0101e60:	f0 
f0101e61:	c7 44 24 04 54 00 00 	movl   $0x54,0x4(%esp)
f0101e68:	00 
f0101e69:	c7 04 24 0e 4f 10 f0 	movl   $0xf0104f0e,(%esp)
f0101e70:	e8 1f e2 ff ff       	call   f0100094 <_panic>
f0101e75:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101e7b:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101e81:	80 38 00             	cmpb   $0x0,(%eax)
f0101e84:	74 24                	je     f0101eaa <mem_init+0x619>
f0101e86:	c7 44 24 0c ed 50 10 	movl   $0xf01050ed,0xc(%esp)
f0101e8d:	f0 
f0101e8e:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0101e95:	f0 
f0101e96:	c7 44 24 04 06 03 00 	movl   $0x306,0x4(%esp)
f0101e9d:	00 
f0101e9e:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0101ea5:	e8 ea e1 ff ff       	call   f0100094 <_panic>
f0101eaa:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101ead:	39 d0                	cmp    %edx,%eax
f0101eaf:	75 d0                	jne    f0101e81 <mem_init+0x5f0>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101eb1:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101eb4:	a3 40 95 11 f0       	mov    %eax,0xf0119540

	// free the pages we took
	page_free(pp0);
f0101eb9:	89 34 24             	mov    %esi,(%esp)
f0101ebc:	e8 7e f6 ff ff       	call   f010153f <page_free>
	page_free(pp1);
f0101ec1:	89 3c 24             	mov    %edi,(%esp)
f0101ec4:	e8 76 f6 ff ff       	call   f010153f <page_free>
	page_free(pp2);
f0101ec9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ecc:	89 04 24             	mov    %eax,(%esp)
f0101ecf:	e8 6b f6 ff ff       	call   f010153f <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101ed4:	a1 40 95 11 f0       	mov    0xf0119540,%eax
f0101ed9:	eb 05                	jmp    f0101ee0 <mem_init+0x64f>
		--nfree;
f0101edb:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101ede:	8b 00                	mov    (%eax),%eax
f0101ee0:	85 c0                	test   %eax,%eax
f0101ee2:	75 f7                	jne    f0101edb <mem_init+0x64a>
		--nfree;
	assert(nfree == 0);
f0101ee4:	85 db                	test   %ebx,%ebx
f0101ee6:	74 24                	je     f0101f0c <mem_init+0x67b>
f0101ee8:	c7 44 24 0c f7 50 10 	movl   $0xf01050f7,0xc(%esp)
f0101eef:	f0 
f0101ef0:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0101ef7:	f0 
f0101ef8:	c7 44 24 04 13 03 00 	movl   $0x313,0x4(%esp)
f0101eff:	00 
f0101f00:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0101f07:	e8 88 e1 ff ff       	call   f0100094 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101f0c:	c7 04 24 a4 53 10 f0 	movl   $0xf01053a4,(%esp)
f0101f13:	e8 7b 15 00 00       	call   f0103493 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101f18:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101f1f:	e8 61 f5 ff ff       	call   f0101485 <page_alloc>
f0101f24:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101f27:	85 c0                	test   %eax,%eax
f0101f29:	75 24                	jne    f0101f4f <mem_init+0x6be>
f0101f2b:	c7 44 24 0c 05 50 10 	movl   $0xf0105005,0xc(%esp)
f0101f32:	f0 
f0101f33:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0101f3a:	f0 
f0101f3b:	c7 44 24 04 6c 03 00 	movl   $0x36c,0x4(%esp)
f0101f42:	00 
f0101f43:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0101f4a:	e8 45 e1 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101f4f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101f56:	e8 2a f5 ff ff       	call   f0101485 <page_alloc>
f0101f5b:	89 c3                	mov    %eax,%ebx
f0101f5d:	85 c0                	test   %eax,%eax
f0101f5f:	75 24                	jne    f0101f85 <mem_init+0x6f4>
f0101f61:	c7 44 24 0c 1b 50 10 	movl   $0xf010501b,0xc(%esp)
f0101f68:	f0 
f0101f69:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0101f70:	f0 
f0101f71:	c7 44 24 04 6d 03 00 	movl   $0x36d,0x4(%esp)
f0101f78:	00 
f0101f79:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0101f80:	e8 0f e1 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101f85:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101f8c:	e8 f4 f4 ff ff       	call   f0101485 <page_alloc>
f0101f91:	89 c6                	mov    %eax,%esi
f0101f93:	85 c0                	test   %eax,%eax
f0101f95:	75 24                	jne    f0101fbb <mem_init+0x72a>
f0101f97:	c7 44 24 0c 31 50 10 	movl   $0xf0105031,0xc(%esp)
f0101f9e:	f0 
f0101f9f:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0101fa6:	f0 
f0101fa7:	c7 44 24 04 6e 03 00 	movl   $0x36e,0x4(%esp)
f0101fae:	00 
f0101faf:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0101fb6:	e8 d9 e0 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101fbb:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101fbe:	75 24                	jne    f0101fe4 <mem_init+0x753>
f0101fc0:	c7 44 24 0c 47 50 10 	movl   $0xf0105047,0xc(%esp)
f0101fc7:	f0 
f0101fc8:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0101fcf:	f0 
f0101fd0:	c7 44 24 04 71 03 00 	movl   $0x371,0x4(%esp)
f0101fd7:	00 
f0101fd8:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0101fdf:	e8 b0 e0 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101fe4:	39 c3                	cmp    %eax,%ebx
f0101fe6:	74 05                	je     f0101fed <mem_init+0x75c>
f0101fe8:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101feb:	75 24                	jne    f0102011 <mem_init+0x780>
f0101fed:	c7 44 24 0c 84 53 10 	movl   $0xf0105384,0xc(%esp)
f0101ff4:	f0 
f0101ff5:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0101ffc:	f0 
f0101ffd:	c7 44 24 04 72 03 00 	movl   $0x372,0x4(%esp)
f0102004:	00 
f0102005:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f010200c:	e8 83 e0 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0102011:	a1 40 95 11 f0       	mov    0xf0119540,%eax
f0102016:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0102019:	c7 05 40 95 11 f0 00 	movl   $0x0,0xf0119540
f0102020:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0102023:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010202a:	e8 56 f4 ff ff       	call   f0101485 <page_alloc>
f010202f:	85 c0                	test   %eax,%eax
f0102031:	74 24                	je     f0102057 <mem_init+0x7c6>
f0102033:	c7 44 24 0c b0 50 10 	movl   $0xf01050b0,0xc(%esp)
f010203a:	f0 
f010203b:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0102042:	f0 
f0102043:	c7 44 24 04 79 03 00 	movl   $0x379,0x4(%esp)
f010204a:	00 
f010204b:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0102052:	e8 3d e0 ff ff       	call   f0100094 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0102057:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010205a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010205e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102065:	00 
f0102066:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f010206b:	89 04 24             	mov    %eax,(%esp)
f010206e:	e8 a4 f6 ff ff       	call   f0101717 <page_lookup>
f0102073:	85 c0                	test   %eax,%eax
f0102075:	74 24                	je     f010209b <mem_init+0x80a>
f0102077:	c7 44 24 0c c4 53 10 	movl   $0xf01053c4,0xc(%esp)
f010207e:	f0 
f010207f:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0102086:	f0 
f0102087:	c7 44 24 04 7c 03 00 	movl   $0x37c,0x4(%esp)
f010208e:	00 
f010208f:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0102096:	e8 f9 df ff ff       	call   f0100094 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010209b:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01020a2:	00 
f01020a3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01020aa:	00 
f01020ab:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01020af:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f01020b4:	89 04 24             	mov    %eax,(%esp)
f01020b7:	e8 12 f7 ff ff       	call   f01017ce <page_insert>
f01020bc:	85 c0                	test   %eax,%eax
f01020be:	78 24                	js     f01020e4 <mem_init+0x853>
f01020c0:	c7 44 24 0c fc 53 10 	movl   $0xf01053fc,0xc(%esp)
f01020c7:	f0 
f01020c8:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f01020cf:	f0 
f01020d0:	c7 44 24 04 7f 03 00 	movl   $0x37f,0x4(%esp)
f01020d7:	00 
f01020d8:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f01020df:	e8 b0 df ff ff       	call   f0100094 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01020e4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020e7:	89 04 24             	mov    %eax,(%esp)
f01020ea:	e8 50 f4 ff ff       	call   f010153f <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01020ef:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01020f6:	00 
f01020f7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01020fe:	00 
f01020ff:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102103:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f0102108:	89 04 24             	mov    %eax,(%esp)
f010210b:	e8 be f6 ff ff       	call   f01017ce <page_insert>
f0102110:	85 c0                	test   %eax,%eax
f0102112:	74 24                	je     f0102138 <mem_init+0x8a7>
f0102114:	c7 44 24 0c 2c 54 10 	movl   $0xf010542c,0xc(%esp)
f010211b:	f0 
f010211c:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0102123:	f0 
f0102124:	c7 44 24 04 83 03 00 	movl   $0x383,0x4(%esp)
f010212b:	00 
f010212c:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0102133:	e8 5c df ff ff       	call   f0100094 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102138:	8b 3d 68 99 11 f0    	mov    0xf0119968,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp) //求出当前页的物理地址
{
	return (pp - pages) << PGSHIFT;
f010213e:	a1 6c 99 11 f0       	mov    0xf011996c,%eax
f0102143:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102146:	8b 17                	mov    (%edi),%edx
f0102148:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010214e:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102151:	29 c1                	sub    %eax,%ecx
f0102153:	89 c8                	mov    %ecx,%eax
f0102155:	c1 f8 03             	sar    $0x3,%eax
f0102158:	c1 e0 0c             	shl    $0xc,%eax
f010215b:	39 c2                	cmp    %eax,%edx
f010215d:	74 24                	je     f0102183 <mem_init+0x8f2>
f010215f:	c7 44 24 0c 5c 54 10 	movl   $0xf010545c,0xc(%esp)
f0102166:	f0 
f0102167:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f010216e:	f0 
f010216f:	c7 44 24 04 84 03 00 	movl   $0x384,0x4(%esp)
f0102176:	00 
f0102177:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f010217e:	e8 11 df ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0102183:	ba 00 00 00 00       	mov    $0x0,%edx
f0102188:	89 f8                	mov    %edi,%eax
f010218a:	e8 c0 ee ff ff       	call   f010104f <check_va2pa>
f010218f:	89 da                	mov    %ebx,%edx
f0102191:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0102194:	c1 fa 03             	sar    $0x3,%edx
f0102197:	c1 e2 0c             	shl    $0xc,%edx
f010219a:	39 d0                	cmp    %edx,%eax
f010219c:	74 24                	je     f01021c2 <mem_init+0x931>
f010219e:	c7 44 24 0c 84 54 10 	movl   $0xf0105484,0xc(%esp)
f01021a5:	f0 
f01021a6:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f01021ad:	f0 
f01021ae:	c7 44 24 04 85 03 00 	movl   $0x385,0x4(%esp)
f01021b5:	00 
f01021b6:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f01021bd:	e8 d2 de ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f01021c2:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01021c7:	74 24                	je     f01021ed <mem_init+0x95c>
f01021c9:	c7 44 24 0c 02 51 10 	movl   $0xf0105102,0xc(%esp)
f01021d0:	f0 
f01021d1:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f01021d8:	f0 
f01021d9:	c7 44 24 04 86 03 00 	movl   $0x386,0x4(%esp)
f01021e0:	00 
f01021e1:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f01021e8:	e8 a7 de ff ff       	call   f0100094 <_panic>
	assert(pp0->pp_ref == 1);
f01021ed:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021f0:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01021f5:	74 24                	je     f010221b <mem_init+0x98a>
f01021f7:	c7 44 24 0c 13 51 10 	movl   $0xf0105113,0xc(%esp)
f01021fe:	f0 
f01021ff:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0102206:	f0 
f0102207:	c7 44 24 04 87 03 00 	movl   $0x387,0x4(%esp)
f010220e:	00 
f010220f:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0102216:	e8 79 de ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010221b:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102222:	00 
f0102223:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010222a:	00 
f010222b:	89 74 24 04          	mov    %esi,0x4(%esp)
f010222f:	89 3c 24             	mov    %edi,(%esp)
f0102232:	e8 97 f5 ff ff       	call   f01017ce <page_insert>
f0102237:	85 c0                	test   %eax,%eax
f0102239:	74 24                	je     f010225f <mem_init+0x9ce>
f010223b:	c7 44 24 0c b4 54 10 	movl   $0xf01054b4,0xc(%esp)
f0102242:	f0 
f0102243:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f010224a:	f0 
f010224b:	c7 44 24 04 8a 03 00 	movl   $0x38a,0x4(%esp)
f0102252:	00 
f0102253:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f010225a:	e8 35 de ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010225f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102264:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f0102269:	e8 e1 ed ff ff       	call   f010104f <check_va2pa>
f010226e:	89 f2                	mov    %esi,%edx
f0102270:	2b 15 6c 99 11 f0    	sub    0xf011996c,%edx
f0102276:	c1 fa 03             	sar    $0x3,%edx
f0102279:	c1 e2 0c             	shl    $0xc,%edx
f010227c:	39 d0                	cmp    %edx,%eax
f010227e:	74 24                	je     f01022a4 <mem_init+0xa13>
f0102280:	c7 44 24 0c f0 54 10 	movl   $0xf01054f0,0xc(%esp)
f0102287:	f0 
f0102288:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f010228f:	f0 
f0102290:	c7 44 24 04 8b 03 00 	movl   $0x38b,0x4(%esp)
f0102297:	00 
f0102298:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f010229f:	e8 f0 dd ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f01022a4:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01022a9:	74 24                	je     f01022cf <mem_init+0xa3e>
f01022ab:	c7 44 24 0c 24 51 10 	movl   $0xf0105124,0xc(%esp)
f01022b2:	f0 
f01022b3:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f01022ba:	f0 
f01022bb:	c7 44 24 04 8c 03 00 	movl   $0x38c,0x4(%esp)
f01022c2:	00 
f01022c3:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f01022ca:	e8 c5 dd ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01022cf:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01022d6:	e8 aa f1 ff ff       	call   f0101485 <page_alloc>
f01022db:	85 c0                	test   %eax,%eax
f01022dd:	74 24                	je     f0102303 <mem_init+0xa72>
f01022df:	c7 44 24 0c b0 50 10 	movl   $0xf01050b0,0xc(%esp)
f01022e6:	f0 
f01022e7:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f01022ee:	f0 
f01022ef:	c7 44 24 04 8f 03 00 	movl   $0x38f,0x4(%esp)
f01022f6:	00 
f01022f7:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f01022fe:	e8 91 dd ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102303:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010230a:	00 
f010230b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102312:	00 
f0102313:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102317:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f010231c:	89 04 24             	mov    %eax,(%esp)
f010231f:	e8 aa f4 ff ff       	call   f01017ce <page_insert>
f0102324:	85 c0                	test   %eax,%eax
f0102326:	74 24                	je     f010234c <mem_init+0xabb>
f0102328:	c7 44 24 0c b4 54 10 	movl   $0xf01054b4,0xc(%esp)
f010232f:	f0 
f0102330:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0102337:	f0 
f0102338:	c7 44 24 04 92 03 00 	movl   $0x392,0x4(%esp)
f010233f:	00 
f0102340:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0102347:	e8 48 dd ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010234c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102351:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f0102356:	e8 f4 ec ff ff       	call   f010104f <check_va2pa>
f010235b:	89 f2                	mov    %esi,%edx
f010235d:	2b 15 6c 99 11 f0    	sub    0xf011996c,%edx
f0102363:	c1 fa 03             	sar    $0x3,%edx
f0102366:	c1 e2 0c             	shl    $0xc,%edx
f0102369:	39 d0                	cmp    %edx,%eax
f010236b:	74 24                	je     f0102391 <mem_init+0xb00>
f010236d:	c7 44 24 0c f0 54 10 	movl   $0xf01054f0,0xc(%esp)
f0102374:	f0 
f0102375:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f010237c:	f0 
f010237d:	c7 44 24 04 93 03 00 	movl   $0x393,0x4(%esp)
f0102384:	00 
f0102385:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f010238c:	e8 03 dd ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102391:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102396:	74 24                	je     f01023bc <mem_init+0xb2b>
f0102398:	c7 44 24 0c 24 51 10 	movl   $0xf0105124,0xc(%esp)
f010239f:	f0 
f01023a0:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f01023a7:	f0 
f01023a8:	c7 44 24 04 94 03 00 	movl   $0x394,0x4(%esp)
f01023af:	00 
f01023b0:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f01023b7:	e8 d8 dc ff ff       	call   f0100094 <_panic>
  
	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f01023bc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01023c3:	e8 bd f0 ff ff       	call   f0101485 <page_alloc>
f01023c8:	85 c0                	test   %eax,%eax
f01023ca:	74 24                	je     f01023f0 <mem_init+0xb5f>
f01023cc:	c7 44 24 0c b0 50 10 	movl   $0xf01050b0,0xc(%esp)
f01023d3:	f0 
f01023d4:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f01023db:	f0 
f01023dc:	c7 44 24 04 98 03 00 	movl   $0x398,0x4(%esp)
f01023e3:	00 
f01023e4:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f01023eb:	e8 a4 dc ff ff       	call   f0100094 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f01023f0:	8b 15 68 99 11 f0    	mov    0xf0119968,%edx
f01023f6:	8b 02                	mov    (%edx),%eax
f01023f8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01023fd:	89 c1                	mov    %eax,%ecx
f01023ff:	c1 e9 0c             	shr    $0xc,%ecx
f0102402:	3b 0d 64 99 11 f0    	cmp    0xf0119964,%ecx
f0102408:	72 20                	jb     f010242a <mem_init+0xb99>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010240a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010240e:	c7 44 24 08 a0 4a 10 	movl   $0xf0104aa0,0x8(%esp)
f0102415:	f0 
f0102416:	c7 44 24 04 9b 03 00 	movl   $0x39b,0x4(%esp)
f010241d:	00 
f010241e:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0102425:	e8 6a dc ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f010242a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010242f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0102432:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102439:	00 
f010243a:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102441:	00 
f0102442:	89 14 24             	mov    %edx,(%esp)
f0102445:	e8 ac f1 ff ff       	call   f01015f6 <pgdir_walk>
f010244a:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f010244d:	8d 51 04             	lea    0x4(%ecx),%edx
f0102450:	39 d0                	cmp    %edx,%eax
f0102452:	74 24                	je     f0102478 <mem_init+0xbe7>
f0102454:	c7 44 24 0c 20 55 10 	movl   $0xf0105520,0xc(%esp)
f010245b:	f0 
f010245c:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0102463:	f0 
f0102464:	c7 44 24 04 9c 03 00 	movl   $0x39c,0x4(%esp)
f010246b:	00 
f010246c:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0102473:	e8 1c dc ff ff       	call   f0100094 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0102478:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f010247f:	00 
f0102480:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102487:	00 
f0102488:	89 74 24 04          	mov    %esi,0x4(%esp)
f010248c:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f0102491:	89 04 24             	mov    %eax,(%esp)
f0102494:	e8 35 f3 ff ff       	call   f01017ce <page_insert>
f0102499:	85 c0                	test   %eax,%eax
f010249b:	74 24                	je     f01024c1 <mem_init+0xc30>
f010249d:	c7 44 24 0c 60 55 10 	movl   $0xf0105560,0xc(%esp)
f01024a4:	f0 
f01024a5:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f01024ac:	f0 
f01024ad:	c7 44 24 04 9f 03 00 	movl   $0x39f,0x4(%esp)
f01024b4:	00 
f01024b5:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f01024bc:	e8 d3 db ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01024c1:	8b 3d 68 99 11 f0    	mov    0xf0119968,%edi
f01024c7:	ba 00 10 00 00       	mov    $0x1000,%edx
f01024cc:	89 f8                	mov    %edi,%eax
f01024ce:	e8 7c eb ff ff       	call   f010104f <check_va2pa>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp) //求出当前页的物理地址
{
	return (pp - pages) << PGSHIFT;
f01024d3:	89 f2                	mov    %esi,%edx
f01024d5:	2b 15 6c 99 11 f0    	sub    0xf011996c,%edx
f01024db:	c1 fa 03             	sar    $0x3,%edx
f01024de:	c1 e2 0c             	shl    $0xc,%edx
f01024e1:	39 d0                	cmp    %edx,%eax
f01024e3:	74 24                	je     f0102509 <mem_init+0xc78>
f01024e5:	c7 44 24 0c f0 54 10 	movl   $0xf01054f0,0xc(%esp)
f01024ec:	f0 
f01024ed:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f01024f4:	f0 
f01024f5:	c7 44 24 04 a0 03 00 	movl   $0x3a0,0x4(%esp)
f01024fc:	00 
f01024fd:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0102504:	e8 8b db ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102509:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010250e:	74 24                	je     f0102534 <mem_init+0xca3>
f0102510:	c7 44 24 0c 24 51 10 	movl   $0xf0105124,0xc(%esp)
f0102517:	f0 
f0102518:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f010251f:	f0 
f0102520:	c7 44 24 04 a1 03 00 	movl   $0x3a1,0x4(%esp)
f0102527:	00 
f0102528:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f010252f:	e8 60 db ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0102534:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010253b:	00 
f010253c:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102543:	00 
f0102544:	89 3c 24             	mov    %edi,(%esp)
f0102547:	e8 aa f0 ff ff       	call   f01015f6 <pgdir_walk>
f010254c:	f6 00 04             	testb  $0x4,(%eax)
f010254f:	75 24                	jne    f0102575 <mem_init+0xce4>
f0102551:	c7 44 24 0c a0 55 10 	movl   $0xf01055a0,0xc(%esp)
f0102558:	f0 
f0102559:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0102560:	f0 
f0102561:	c7 44 24 04 a2 03 00 	movl   $0x3a2,0x4(%esp)
f0102568:	00 
f0102569:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0102570:	e8 1f db ff ff       	call   f0100094 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0102575:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f010257a:	f6 00 04             	testb  $0x4,(%eax)
f010257d:	75 24                	jne    f01025a3 <mem_init+0xd12>
f010257f:	c7 44 24 0c 35 51 10 	movl   $0xf0105135,0xc(%esp)
f0102586:	f0 
f0102587:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f010258e:	f0 
f010258f:	c7 44 24 04 a3 03 00 	movl   $0x3a3,0x4(%esp)
f0102596:	00 
f0102597:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f010259e:	e8 f1 da ff ff       	call   f0100094 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01025a3:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01025aa:	00 
f01025ab:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01025b2:	00 
f01025b3:	89 74 24 04          	mov    %esi,0x4(%esp)
f01025b7:	89 04 24             	mov    %eax,(%esp)
f01025ba:	e8 0f f2 ff ff       	call   f01017ce <page_insert>
f01025bf:	85 c0                	test   %eax,%eax
f01025c1:	74 24                	je     f01025e7 <mem_init+0xd56>
f01025c3:	c7 44 24 0c b4 54 10 	movl   $0xf01054b4,0xc(%esp)
f01025ca:	f0 
f01025cb:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f01025d2:	f0 
f01025d3:	c7 44 24 04 a6 03 00 	movl   $0x3a6,0x4(%esp)
f01025da:	00 
f01025db:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f01025e2:	e8 ad da ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f01025e7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01025ee:	00 
f01025ef:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01025f6:	00 
f01025f7:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f01025fc:	89 04 24             	mov    %eax,(%esp)
f01025ff:	e8 f2 ef ff ff       	call   f01015f6 <pgdir_walk>
f0102604:	f6 00 02             	testb  $0x2,(%eax)
f0102607:	75 24                	jne    f010262d <mem_init+0xd9c>
f0102609:	c7 44 24 0c d4 55 10 	movl   $0xf01055d4,0xc(%esp)
f0102610:	f0 
f0102611:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0102618:	f0 
f0102619:	c7 44 24 04 a7 03 00 	movl   $0x3a7,0x4(%esp)
f0102620:	00 
f0102621:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0102628:	e8 67 da ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f010262d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102634:	00 
f0102635:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010263c:	00 
f010263d:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f0102642:	89 04 24             	mov    %eax,(%esp)
f0102645:	e8 ac ef ff ff       	call   f01015f6 <pgdir_walk>
f010264a:	f6 00 04             	testb  $0x4,(%eax)
f010264d:	74 24                	je     f0102673 <mem_init+0xde2>
f010264f:	c7 44 24 0c 08 56 10 	movl   $0xf0105608,0xc(%esp)
f0102656:	f0 
f0102657:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f010265e:	f0 
f010265f:	c7 44 24 04 a8 03 00 	movl   $0x3a8,0x4(%esp)
f0102666:	00 
f0102667:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f010266e:	e8 21 da ff ff       	call   f0100094 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102673:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010267a:	00 
f010267b:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0102682:	00 
f0102683:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102686:	89 44 24 04          	mov    %eax,0x4(%esp)
f010268a:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f010268f:	89 04 24             	mov    %eax,(%esp)
f0102692:	e8 37 f1 ff ff       	call   f01017ce <page_insert>
f0102697:	85 c0                	test   %eax,%eax
f0102699:	78 24                	js     f01026bf <mem_init+0xe2e>
f010269b:	c7 44 24 0c 40 56 10 	movl   $0xf0105640,0xc(%esp)
f01026a2:	f0 
f01026a3:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f01026aa:	f0 
f01026ab:	c7 44 24 04 ab 03 00 	movl   $0x3ab,0x4(%esp)
f01026b2:	00 
f01026b3:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f01026ba:	e8 d5 d9 ff ff       	call   f0100094 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f01026bf:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01026c6:	00 
f01026c7:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01026ce:	00 
f01026cf:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01026d3:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f01026d8:	89 04 24             	mov    %eax,(%esp)
f01026db:	e8 ee f0 ff ff       	call   f01017ce <page_insert>
f01026e0:	85 c0                	test   %eax,%eax
f01026e2:	74 24                	je     f0102708 <mem_init+0xe77>
f01026e4:	c7 44 24 0c 78 56 10 	movl   $0xf0105678,0xc(%esp)
f01026eb:	f0 
f01026ec:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f01026f3:	f0 
f01026f4:	c7 44 24 04 ae 03 00 	movl   $0x3ae,0x4(%esp)
f01026fb:	00 
f01026fc:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0102703:	e8 8c d9 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102708:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010270f:	00 
f0102710:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102717:	00 
f0102718:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f010271d:	89 04 24             	mov    %eax,(%esp)
f0102720:	e8 d1 ee ff ff       	call   f01015f6 <pgdir_walk>
f0102725:	f6 00 04             	testb  $0x4,(%eax)
f0102728:	74 24                	je     f010274e <mem_init+0xebd>
f010272a:	c7 44 24 0c 08 56 10 	movl   $0xf0105608,0xc(%esp)
f0102731:	f0 
f0102732:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0102739:	f0 
f010273a:	c7 44 24 04 af 03 00 	movl   $0x3af,0x4(%esp)
f0102741:	00 
f0102742:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0102749:	e8 46 d9 ff ff       	call   f0100094 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f010274e:	8b 3d 68 99 11 f0    	mov    0xf0119968,%edi
f0102754:	ba 00 00 00 00       	mov    $0x0,%edx
f0102759:	89 f8                	mov    %edi,%eax
f010275b:	e8 ef e8 ff ff       	call   f010104f <check_va2pa>
f0102760:	89 c1                	mov    %eax,%ecx
f0102762:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102765:	89 d8                	mov    %ebx,%eax
f0102767:	2b 05 6c 99 11 f0    	sub    0xf011996c,%eax
f010276d:	c1 f8 03             	sar    $0x3,%eax
f0102770:	c1 e0 0c             	shl    $0xc,%eax
f0102773:	39 c1                	cmp    %eax,%ecx
f0102775:	74 24                	je     f010279b <mem_init+0xf0a>
f0102777:	c7 44 24 0c b4 56 10 	movl   $0xf01056b4,0xc(%esp)
f010277e:	f0 
f010277f:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0102786:	f0 
f0102787:	c7 44 24 04 b2 03 00 	movl   $0x3b2,0x4(%esp)
f010278e:	00 
f010278f:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0102796:	e8 f9 d8 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010279b:	ba 00 10 00 00       	mov    $0x1000,%edx
f01027a0:	89 f8                	mov    %edi,%eax
f01027a2:	e8 a8 e8 ff ff       	call   f010104f <check_va2pa>
f01027a7:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f01027aa:	74 24                	je     f01027d0 <mem_init+0xf3f>
f01027ac:	c7 44 24 0c e0 56 10 	movl   $0xf01056e0,0xc(%esp)
f01027b3:	f0 
f01027b4:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f01027bb:	f0 
f01027bc:	c7 44 24 04 b3 03 00 	movl   $0x3b3,0x4(%esp)
f01027c3:	00 
f01027c4:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f01027cb:	e8 c4 d8 ff ff       	call   f0100094 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f01027d0:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f01027d5:	74 24                	je     f01027fb <mem_init+0xf6a>
f01027d7:	c7 44 24 0c 4b 51 10 	movl   $0xf010514b,0xc(%esp)
f01027de:	f0 
f01027df:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f01027e6:	f0 
f01027e7:	c7 44 24 04 b5 03 00 	movl   $0x3b5,0x4(%esp)
f01027ee:	00 
f01027ef:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f01027f6:	e8 99 d8 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f01027fb:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102800:	74 24                	je     f0102826 <mem_init+0xf95>
f0102802:	c7 44 24 0c 5c 51 10 	movl   $0xf010515c,0xc(%esp)
f0102809:	f0 
f010280a:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0102811:	f0 
f0102812:	c7 44 24 04 b6 03 00 	movl   $0x3b6,0x4(%esp)
f0102819:	00 
f010281a:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0102821:	e8 6e d8 ff ff       	call   f0100094 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0102826:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010282d:	e8 53 ec ff ff       	call   f0101485 <page_alloc>
f0102832:	85 c0                	test   %eax,%eax
f0102834:	74 04                	je     f010283a <mem_init+0xfa9>
f0102836:	39 c6                	cmp    %eax,%esi
f0102838:	74 24                	je     f010285e <mem_init+0xfcd>
f010283a:	c7 44 24 0c 10 57 10 	movl   $0xf0105710,0xc(%esp)
f0102841:	f0 
f0102842:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0102849:	f0 
f010284a:	c7 44 24 04 b9 03 00 	movl   $0x3b9,0x4(%esp)
f0102851:	00 
f0102852:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0102859:	e8 36 d8 ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f010285e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102865:	00 
f0102866:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f010286b:	89 04 24             	mov    %eax,(%esp)
f010286e:	e8 1d ef ff ff       	call   f0101790 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102873:	8b 3d 68 99 11 f0    	mov    0xf0119968,%edi
f0102879:	ba 00 00 00 00       	mov    $0x0,%edx
f010287e:	89 f8                	mov    %edi,%eax
f0102880:	e8 ca e7 ff ff       	call   f010104f <check_va2pa>
f0102885:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102888:	74 24                	je     f01028ae <mem_init+0x101d>
f010288a:	c7 44 24 0c 34 57 10 	movl   $0xf0105734,0xc(%esp)
f0102891:	f0 
f0102892:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0102899:	f0 
f010289a:	c7 44 24 04 bd 03 00 	movl   $0x3bd,0x4(%esp)
f01028a1:	00 
f01028a2:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f01028a9:	e8 e6 d7 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01028ae:	ba 00 10 00 00       	mov    $0x1000,%edx
f01028b3:	89 f8                	mov    %edi,%eax
f01028b5:	e8 95 e7 ff ff       	call   f010104f <check_va2pa>
f01028ba:	89 da                	mov    %ebx,%edx
f01028bc:	2b 15 6c 99 11 f0    	sub    0xf011996c,%edx
f01028c2:	c1 fa 03             	sar    $0x3,%edx
f01028c5:	c1 e2 0c             	shl    $0xc,%edx
f01028c8:	39 d0                	cmp    %edx,%eax
f01028ca:	74 24                	je     f01028f0 <mem_init+0x105f>
f01028cc:	c7 44 24 0c e0 56 10 	movl   $0xf01056e0,0xc(%esp)
f01028d3:	f0 
f01028d4:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f01028db:	f0 
f01028dc:	c7 44 24 04 be 03 00 	movl   $0x3be,0x4(%esp)
f01028e3:	00 
f01028e4:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f01028eb:	e8 a4 d7 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f01028f0:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01028f5:	74 24                	je     f010291b <mem_init+0x108a>
f01028f7:	c7 44 24 0c 02 51 10 	movl   $0xf0105102,0xc(%esp)
f01028fe:	f0 
f01028ff:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0102906:	f0 
f0102907:	c7 44 24 04 bf 03 00 	movl   $0x3bf,0x4(%esp)
f010290e:	00 
f010290f:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0102916:	e8 79 d7 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f010291b:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102920:	74 24                	je     f0102946 <mem_init+0x10b5>
f0102922:	c7 44 24 0c 5c 51 10 	movl   $0xf010515c,0xc(%esp)
f0102929:	f0 
f010292a:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0102931:	f0 
f0102932:	c7 44 24 04 c0 03 00 	movl   $0x3c0,0x4(%esp)
f0102939:	00 
f010293a:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0102941:	e8 4e d7 ff ff       	call   f0100094 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102946:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010294d:	00 
f010294e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102955:	00 
f0102956:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010295a:	89 3c 24             	mov    %edi,(%esp)
f010295d:	e8 6c ee ff ff       	call   f01017ce <page_insert>
f0102962:	85 c0                	test   %eax,%eax
f0102964:	74 24                	je     f010298a <mem_init+0x10f9>
f0102966:	c7 44 24 0c 58 57 10 	movl   $0xf0105758,0xc(%esp)
f010296d:	f0 
f010296e:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0102975:	f0 
f0102976:	c7 44 24 04 c3 03 00 	movl   $0x3c3,0x4(%esp)
f010297d:	00 
f010297e:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0102985:	e8 0a d7 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref);
f010298a:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010298f:	75 24                	jne    f01029b5 <mem_init+0x1124>
f0102991:	c7 44 24 0c 6d 51 10 	movl   $0xf010516d,0xc(%esp)
f0102998:	f0 
f0102999:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f01029a0:	f0 
f01029a1:	c7 44 24 04 c4 03 00 	movl   $0x3c4,0x4(%esp)
f01029a8:	00 
f01029a9:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f01029b0:	e8 df d6 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_link == NULL);
f01029b5:	83 3b 00             	cmpl   $0x0,(%ebx)
f01029b8:	74 24                	je     f01029de <mem_init+0x114d>
f01029ba:	c7 44 24 0c 79 51 10 	movl   $0xf0105179,0xc(%esp)
f01029c1:	f0 
f01029c2:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f01029c9:	f0 
f01029ca:	c7 44 24 04 c5 03 00 	movl   $0x3c5,0x4(%esp)
f01029d1:	00 
f01029d2:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f01029d9:	e8 b6 d6 ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01029de:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01029e5:	00 
f01029e6:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f01029eb:	89 04 24             	mov    %eax,(%esp)
f01029ee:	e8 9d ed ff ff       	call   f0101790 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01029f3:	8b 3d 68 99 11 f0    	mov    0xf0119968,%edi
f01029f9:	ba 00 00 00 00       	mov    $0x0,%edx
f01029fe:	89 f8                	mov    %edi,%eax
f0102a00:	e8 4a e6 ff ff       	call   f010104f <check_va2pa>
f0102a05:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102a08:	74 24                	je     f0102a2e <mem_init+0x119d>
f0102a0a:	c7 44 24 0c 34 57 10 	movl   $0xf0105734,0xc(%esp)
f0102a11:	f0 
f0102a12:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0102a19:	f0 
f0102a1a:	c7 44 24 04 c9 03 00 	movl   $0x3c9,0x4(%esp)
f0102a21:	00 
f0102a22:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0102a29:	e8 66 d6 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102a2e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102a33:	89 f8                	mov    %edi,%eax
f0102a35:	e8 15 e6 ff ff       	call   f010104f <check_va2pa>
f0102a3a:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102a3d:	74 24                	je     f0102a63 <mem_init+0x11d2>
f0102a3f:	c7 44 24 0c 90 57 10 	movl   $0xf0105790,0xc(%esp)
f0102a46:	f0 
f0102a47:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0102a4e:	f0 
f0102a4f:	c7 44 24 04 ca 03 00 	movl   $0x3ca,0x4(%esp)
f0102a56:	00 
f0102a57:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0102a5e:	e8 31 d6 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102a63:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102a68:	74 24                	je     f0102a8e <mem_init+0x11fd>
f0102a6a:	c7 44 24 0c 8e 51 10 	movl   $0xf010518e,0xc(%esp)
f0102a71:	f0 
f0102a72:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0102a79:	f0 
f0102a7a:	c7 44 24 04 cb 03 00 	movl   $0x3cb,0x4(%esp)
f0102a81:	00 
f0102a82:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0102a89:	e8 06 d6 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102a8e:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102a93:	74 24                	je     f0102ab9 <mem_init+0x1228>
f0102a95:	c7 44 24 0c 5c 51 10 	movl   $0xf010515c,0xc(%esp)
f0102a9c:	f0 
f0102a9d:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0102aa4:	f0 
f0102aa5:	c7 44 24 04 cc 03 00 	movl   $0x3cc,0x4(%esp)
f0102aac:	00 
f0102aad:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0102ab4:	e8 db d5 ff ff       	call   f0100094 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102ab9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102ac0:	e8 c0 e9 ff ff       	call   f0101485 <page_alloc>
f0102ac5:	85 c0                	test   %eax,%eax
f0102ac7:	74 04                	je     f0102acd <mem_init+0x123c>
f0102ac9:	39 c3                	cmp    %eax,%ebx
f0102acb:	74 24                	je     f0102af1 <mem_init+0x1260>
f0102acd:	c7 44 24 0c b8 57 10 	movl   $0xf01057b8,0xc(%esp)
f0102ad4:	f0 
f0102ad5:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0102adc:	f0 
f0102add:	c7 44 24 04 cf 03 00 	movl   $0x3cf,0x4(%esp)
f0102ae4:	00 
f0102ae5:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0102aec:	e8 a3 d5 ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102af1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102af8:	e8 88 e9 ff ff       	call   f0101485 <page_alloc>
f0102afd:	85 c0                	test   %eax,%eax
f0102aff:	74 24                	je     f0102b25 <mem_init+0x1294>
f0102b01:	c7 44 24 0c b0 50 10 	movl   $0xf01050b0,0xc(%esp)
f0102b08:	f0 
f0102b09:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0102b10:	f0 
f0102b11:	c7 44 24 04 d2 03 00 	movl   $0x3d2,0x4(%esp)
f0102b18:	00 
f0102b19:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0102b20:	e8 6f d5 ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102b25:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f0102b2a:	8b 08                	mov    (%eax),%ecx
f0102b2c:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102b32:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102b35:	2b 15 6c 99 11 f0    	sub    0xf011996c,%edx
f0102b3b:	c1 fa 03             	sar    $0x3,%edx
f0102b3e:	c1 e2 0c             	shl    $0xc,%edx
f0102b41:	39 d1                	cmp    %edx,%ecx
f0102b43:	74 24                	je     f0102b69 <mem_init+0x12d8>
f0102b45:	c7 44 24 0c 5c 54 10 	movl   $0xf010545c,0xc(%esp)
f0102b4c:	f0 
f0102b4d:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0102b54:	f0 
f0102b55:	c7 44 24 04 d5 03 00 	movl   $0x3d5,0x4(%esp)
f0102b5c:	00 
f0102b5d:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0102b64:	e8 2b d5 ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102b69:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102b6f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b72:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102b77:	74 24                	je     f0102b9d <mem_init+0x130c>
f0102b79:	c7 44 24 0c 13 51 10 	movl   $0xf0105113,0xc(%esp)
f0102b80:	f0 
f0102b81:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0102b88:	f0 
f0102b89:	c7 44 24 04 d7 03 00 	movl   $0x3d7,0x4(%esp)
f0102b90:	00 
f0102b91:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0102b98:	e8 f7 d4 ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102b9d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102ba0:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102ba6:	89 04 24             	mov    %eax,(%esp)
f0102ba9:	e8 91 e9 ff ff       	call   f010153f <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102bae:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102bb5:	00 
f0102bb6:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f0102bbd:	00 
f0102bbe:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f0102bc3:	89 04 24             	mov    %eax,(%esp)
f0102bc6:	e8 2b ea ff ff       	call   f01015f6 <pgdir_walk>
f0102bcb:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102bce:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102bd1:	8b 15 68 99 11 f0    	mov    0xf0119968,%edx
f0102bd7:	8b 7a 04             	mov    0x4(%edx),%edi
f0102bda:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102be0:	8b 0d 64 99 11 f0    	mov    0xf0119964,%ecx
f0102be6:	89 f8                	mov    %edi,%eax
f0102be8:	c1 e8 0c             	shr    $0xc,%eax
f0102beb:	39 c8                	cmp    %ecx,%eax
f0102bed:	72 20                	jb     f0102c0f <mem_init+0x137e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102bef:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0102bf3:	c7 44 24 08 a0 4a 10 	movl   $0xf0104aa0,0x8(%esp)
f0102bfa:	f0 
f0102bfb:	c7 44 24 04 de 03 00 	movl   $0x3de,0x4(%esp)
f0102c02:	00 
f0102c03:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0102c0a:	e8 85 d4 ff ff       	call   f0100094 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102c0f:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f0102c15:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0102c18:	74 24                	je     f0102c3e <mem_init+0x13ad>
f0102c1a:	c7 44 24 0c 9f 51 10 	movl   $0xf010519f,0xc(%esp)
f0102c21:	f0 
f0102c22:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0102c29:	f0 
f0102c2a:	c7 44 24 04 df 03 00 	movl   $0x3df,0x4(%esp)
f0102c31:	00 
f0102c32:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0102c39:	e8 56 d4 ff ff       	call   f0100094 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102c3e:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
	pp0->pp_ref = 0;
f0102c45:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102c48:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp) //求出当前页的物理地址
{
	return (pp - pages) << PGSHIFT;
f0102c4e:	2b 05 6c 99 11 f0    	sub    0xf011996c,%eax
f0102c54:	c1 f8 03             	sar    $0x3,%eax
f0102c57:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c5a:	89 c2                	mov    %eax,%edx
f0102c5c:	c1 ea 0c             	shr    $0xc,%edx
f0102c5f:	39 d1                	cmp    %edx,%ecx
f0102c61:	77 20                	ja     f0102c83 <mem_init+0x13f2>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c63:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102c67:	c7 44 24 08 a0 4a 10 	movl   $0xf0104aa0,0x8(%esp)
f0102c6e:	f0 
f0102c6f:	c7 44 24 04 54 00 00 	movl   $0x54,0x4(%esp)
f0102c76:	00 
f0102c77:	c7 04 24 0e 4f 10 f0 	movl   $0xf0104f0e,(%esp)
f0102c7e:	e8 11 d4 ff ff       	call   f0100094 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102c83:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102c8a:	00 
f0102c8b:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f0102c92:	00 
	return (void *)(pa + KERNBASE);
f0102c93:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102c98:	89 04 24             	mov    %eax,(%esp)
f0102c9b:	e8 67 13 00 00       	call   f0104007 <memset>
	page_free(pp0);
f0102ca0:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102ca3:	89 3c 24             	mov    %edi,(%esp)
f0102ca6:	e8 94 e8 ff ff       	call   f010153f <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102cab:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102cb2:	00 
f0102cb3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102cba:	00 
f0102cbb:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f0102cc0:	89 04 24             	mov    %eax,(%esp)
f0102cc3:	e8 2e e9 ff ff       	call   f01015f6 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp) //求出当前页的物理地址
{
	return (pp - pages) << PGSHIFT;
f0102cc8:	89 fa                	mov    %edi,%edx
f0102cca:	2b 15 6c 99 11 f0    	sub    0xf011996c,%edx
f0102cd0:	c1 fa 03             	sar    $0x3,%edx
f0102cd3:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102cd6:	89 d0                	mov    %edx,%eax
f0102cd8:	c1 e8 0c             	shr    $0xc,%eax
f0102cdb:	3b 05 64 99 11 f0    	cmp    0xf0119964,%eax
f0102ce1:	72 20                	jb     f0102d03 <mem_init+0x1472>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102ce3:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102ce7:	c7 44 24 08 a0 4a 10 	movl   $0xf0104aa0,0x8(%esp)
f0102cee:	f0 
f0102cef:	c7 44 24 04 54 00 00 	movl   $0x54,0x4(%esp)
f0102cf6:	00 
f0102cf7:	c7 04 24 0e 4f 10 f0 	movl   $0xf0104f0e,(%esp)
f0102cfe:	e8 91 d3 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0102d03:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102d09:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102d0c:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102d12:	f6 00 01             	testb  $0x1,(%eax)
f0102d15:	74 24                	je     f0102d3b <mem_init+0x14aa>
f0102d17:	c7 44 24 0c b7 51 10 	movl   $0xf01051b7,0xc(%esp)
f0102d1e:	f0 
f0102d1f:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0102d26:	f0 
f0102d27:	c7 44 24 04 e9 03 00 	movl   $0x3e9,0x4(%esp)
f0102d2e:	00 
f0102d2f:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0102d36:	e8 59 d3 ff ff       	call   f0100094 <_panic>
f0102d3b:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102d3e:	39 d0                	cmp    %edx,%eax
f0102d40:	75 d0                	jne    f0102d12 <mem_init+0x1481>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102d42:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f0102d47:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102d4d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102d50:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102d56:	8b 7d d0             	mov    -0x30(%ebp),%edi
f0102d59:	89 3d 40 95 11 f0    	mov    %edi,0xf0119540

	// free the pages we took
	page_free(pp0);
f0102d5f:	89 04 24             	mov    %eax,(%esp)
f0102d62:	e8 d8 e7 ff ff       	call   f010153f <page_free>
	page_free(pp1);
f0102d67:	89 1c 24             	mov    %ebx,(%esp)
f0102d6a:	e8 d0 e7 ff ff       	call   f010153f <page_free>
	page_free(pp2);
f0102d6f:	89 34 24             	mov    %esi,(%esp)
f0102d72:	e8 c8 e7 ff ff       	call   f010153f <page_free>

	cprintf("check_page() succeeded!\n");
f0102d77:	c7 04 24 ce 51 10 f0 	movl   $0xf01051ce,(%esp)
f0102d7e:	e8 10 07 00 00       	call   f0103493 <cprintf>

	// PTE_W 没有置位时，默认为可读。置位时，则为可读可写。
	// PTE_U 没有置位时，默认为内核。置位时，则为内核/用户。

	//todo: pages itself -- kernel RW, user NONE  ????????????????????????????????????????????
	boot_map_region(kern_pgdir,UPAGES,PTSIZE,PADDR(pages),PTE_U | PTE_P);
f0102d83:	a1 6c 99 11 f0       	mov    0xf011996c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva) // 在哪里并如何维护 __FILE__ 和 __LINE__?

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102d88:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102d8d:	77 20                	ja     f0102daf <mem_init+0x151e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d8f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102d93:	c7 44 24 08 60 53 10 	movl   $0xf0105360,0x8(%esp)
f0102d9a:	f0 
f0102d9b:	c7 44 24 04 c9 00 00 	movl   $0xc9,0x4(%esp)
f0102da2:	00 
f0102da3:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0102daa:	e8 e5 d2 ff ff       	call   f0100094 <_panic>
f0102daf:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f0102db6:	00 
	return (physaddr_t)kva - KERNBASE;
f0102db7:	05 00 00 00 10       	add    $0x10000000,%eax
f0102dbc:	89 04 24             	mov    %eax,(%esp)
f0102dbf:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102dc4:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102dc9:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f0102dce:	e8 c3 e8 ff ff       	call   f0101696 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva) // 在哪里并如何维护 __FILE__ 和 __LINE__?

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102dd3:	bb 00 f0 10 f0       	mov    $0xf010f000,%ebx
f0102dd8:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0102dde:	77 20                	ja     f0102e00 <mem_init+0x156f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102de0:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0102de4:	c7 44 24 08 60 53 10 	movl   $0xf0105360,0x8(%esp)
f0102deb:	f0 
f0102dec:	c7 44 24 04 d9 00 00 	movl   $0xd9,0x4(%esp)
f0102df3:	00 
f0102df4:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0102dfb:	e8 94 d2 ff ff       	call   f0100094 <_panic>
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	//todo: [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) ????????????????????????????????????????????
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W | PTE_P);
f0102e00:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102e07:	00 
f0102e08:	c7 04 24 00 f0 10 00 	movl   $0x10f000,(%esp)
f0102e0f:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102e14:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102e19:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f0102e1e:	e8 73 e8 ff ff       	call   f0101696 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, 0xffffffff - KERNBASE + 1, 0, PTE_W | PTE_P);
f0102e23:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102e2a:	00 
f0102e2b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102e32:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102e37:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102e3c:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f0102e41:	e8 50 e8 ff ff       	call   f0101696 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102e46:	8b 3d 68 99 11 f0    	mov    0xf0119968,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102e4c:	a1 64 99 11 f0       	mov    0xf0119964,%eax
f0102e51:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102e54:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102e5b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102e60:	89 45 d0             	mov    %eax,-0x30(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102e63:	a1 6c 99 11 f0       	mov    0xf011996c,%eax
f0102e68:	89 45 cc             	mov    %eax,-0x34(%ebp)
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva) // 在哪里并如何维护 __FILE__ 和 __LINE__?

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102e6b:	89 45 c8             	mov    %eax,-0x38(%ebp)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
	return (physaddr_t)kva - KERNBASE;
f0102e6e:	05 00 00 00 10       	add    $0x10000000,%eax
f0102e73:	89 45 c4             	mov    %eax,-0x3c(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102e76:	be 00 00 00 00       	mov    $0x0,%esi
f0102e7b:	eb 6d                	jmp    f0102eea <mem_init+0x1659>
f0102e7d:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102e83:	89 f8                	mov    %edi,%eax
f0102e85:	e8 c5 e1 ff ff       	call   f010104f <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva) // 在哪里并如何维护 __FILE__ 和 __LINE__?

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102e8a:	81 7d c8 ff ff ff ef 	cmpl   $0xefffffff,-0x38(%ebp)
f0102e91:	77 23                	ja     f0102eb6 <mem_init+0x1625>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e93:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102e96:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102e9a:	c7 44 24 08 60 53 10 	movl   $0xf0105360,0x8(%esp)
f0102ea1:	f0 
f0102ea2:	c7 44 24 04 2b 03 00 	movl   $0x32b,0x4(%esp)
f0102ea9:	00 
f0102eaa:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0102eb1:	e8 de d1 ff ff       	call   f0100094 <_panic>
f0102eb6:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0102eb9:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0102ebc:	39 c2                	cmp    %eax,%edx
f0102ebe:	74 24                	je     f0102ee4 <mem_init+0x1653>
f0102ec0:	c7 44 24 0c dc 57 10 	movl   $0xf01057dc,0xc(%esp)
f0102ec7:	f0 
f0102ec8:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0102ecf:	f0 
f0102ed0:	c7 44 24 04 2b 03 00 	movl   $0x32b,0x4(%esp)
f0102ed7:	00 
f0102ed8:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0102edf:	e8 b0 d1 ff ff       	call   f0100094 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102ee4:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102eea:	39 75 d0             	cmp    %esi,-0x30(%ebp)
f0102eed:	77 8e                	ja     f0102e7d <mem_init+0x15ec>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102eef:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102ef2:	c1 e0 0c             	shl    $0xc,%eax
f0102ef5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102ef8:	be 00 00 00 00       	mov    $0x0,%esi
f0102efd:	eb 3b                	jmp    f0102f3a <mem_init+0x16a9>
f0102eff:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102f05:	89 f8                	mov    %edi,%eax
f0102f07:	e8 43 e1 ff ff       	call   f010104f <check_va2pa>
f0102f0c:	39 c6                	cmp    %eax,%esi
f0102f0e:	74 24                	je     f0102f34 <mem_init+0x16a3>
f0102f10:	c7 44 24 0c 10 58 10 	movl   $0xf0105810,0xc(%esp)
f0102f17:	f0 
f0102f18:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0102f1f:	f0 
f0102f20:	c7 44 24 04 30 03 00 	movl   $0x330,0x4(%esp)
f0102f27:	00 
f0102f28:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0102f2f:	e8 60 d1 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102f34:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102f3a:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0102f3d:	72 c0                	jb     f0102eff <mem_init+0x166e>
f0102f3f:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f0102f44:	81 c3 00 80 00 20    	add    $0x20008000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102f4a:	89 f2                	mov    %esi,%edx
f0102f4c:	89 f8                	mov    %edi,%eax
f0102f4e:	e8 fc e0 ff ff       	call   f010104f <check_va2pa>
f0102f53:	8d 14 33             	lea    (%ebx,%esi,1),%edx
f0102f56:	39 d0                	cmp    %edx,%eax
f0102f58:	74 24                	je     f0102f7e <mem_init+0x16ed>
f0102f5a:	c7 44 24 0c 38 58 10 	movl   $0xf0105838,0xc(%esp)
f0102f61:	f0 
f0102f62:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0102f69:	f0 
f0102f6a:	c7 44 24 04 34 03 00 	movl   $0x334,0x4(%esp)
f0102f71:	00 
f0102f72:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0102f79:	e8 16 d1 ff ff       	call   f0100094 <_panic>
f0102f7e:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102f84:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f0102f8a:	75 be                	jne    f0102f4a <mem_init+0x16b9>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102f8c:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102f91:	89 f8                	mov    %edi,%eax
f0102f93:	e8 b7 e0 ff ff       	call   f010104f <check_va2pa>
f0102f98:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102f9b:	75 0a                	jne    f0102fa7 <mem_init+0x1716>
f0102f9d:	b8 00 00 00 00       	mov    $0x0,%eax
f0102fa2:	e9 f0 00 00 00       	jmp    f0103097 <mem_init+0x1806>
f0102fa7:	c7 44 24 0c 80 58 10 	movl   $0xf0105880,0xc(%esp)
f0102fae:	f0 
f0102faf:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0102fb6:	f0 
f0102fb7:	c7 44 24 04 35 03 00 	movl   $0x335,0x4(%esp)
f0102fbe:	00 
f0102fbf:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0102fc6:	e8 c9 d0 ff ff       	call   f0100094 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102fcb:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102fd0:	72 3c                	jb     f010300e <mem_init+0x177d>
f0102fd2:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102fd7:	76 07                	jbe    f0102fe0 <mem_init+0x174f>
f0102fd9:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102fde:	75 2e                	jne    f010300e <mem_init+0x177d>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f0102fe0:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f0102fe4:	0f 85 aa 00 00 00    	jne    f0103094 <mem_init+0x1803>
f0102fea:	c7 44 24 0c e7 51 10 	movl   $0xf01051e7,0xc(%esp)
f0102ff1:	f0 
f0102ff2:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0102ff9:	f0 
f0102ffa:	c7 44 24 04 3d 03 00 	movl   $0x33d,0x4(%esp)
f0103001:	00 
f0103002:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0103009:	e8 86 d0 ff ff       	call   f0100094 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f010300e:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0103013:	76 55                	jbe    f010306a <mem_init+0x17d9>
				assert(pgdir[i] & PTE_P);
f0103015:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0103018:	f6 c2 01             	test   $0x1,%dl
f010301b:	75 24                	jne    f0103041 <mem_init+0x17b0>
f010301d:	c7 44 24 0c e7 51 10 	movl   $0xf01051e7,0xc(%esp)
f0103024:	f0 
f0103025:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f010302c:	f0 
f010302d:	c7 44 24 04 41 03 00 	movl   $0x341,0x4(%esp)
f0103034:	00 
f0103035:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f010303c:	e8 53 d0 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] & PTE_W);
f0103041:	f6 c2 02             	test   $0x2,%dl
f0103044:	75 4e                	jne    f0103094 <mem_init+0x1803>
f0103046:	c7 44 24 0c f8 51 10 	movl   $0xf01051f8,0xc(%esp)
f010304d:	f0 
f010304e:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0103055:	f0 
f0103056:	c7 44 24 04 42 03 00 	movl   $0x342,0x4(%esp)
f010305d:	00 
f010305e:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0103065:	e8 2a d0 ff ff       	call   f0100094 <_panic>
			} else
				assert(pgdir[i] == 0);
f010306a:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f010306e:	74 24                	je     f0103094 <mem_init+0x1803>
f0103070:	c7 44 24 0c 09 52 10 	movl   $0xf0105209,0xc(%esp)
f0103077:	f0 
f0103078:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f010307f:	f0 
f0103080:	c7 44 24 04 44 03 00 	movl   $0x344,0x4(%esp)
f0103087:	00 
f0103088:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f010308f:	e8 00 d0 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0103094:	83 c0 01             	add    $0x1,%eax
f0103097:	3d 00 04 00 00       	cmp    $0x400,%eax
f010309c:	0f 85 29 ff ff ff    	jne    f0102fcb <mem_init+0x173a>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01030a2:	c7 04 24 b0 58 10 f0 	movl   $0xf01058b0,(%esp)
f01030a9:	e8 e5 03 00 00       	call   f0103493 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01030ae:	a1 68 99 11 f0       	mov    0xf0119968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva) // 在哪里并如何维护 __FILE__ 和 __LINE__?

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01030b3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01030b8:	77 20                	ja     f01030da <mem_init+0x1849>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01030ba:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01030be:	c7 44 24 08 60 53 10 	movl   $0xf0105360,0x8(%esp)
f01030c5:	f0 
f01030c6:	c7 44 24 04 f3 00 00 	movl   $0xf3,0x4(%esp)
f01030cd:	00 
f01030ce:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f01030d5:	e8 ba cf ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01030da:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01030df:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01030e2:	b8 00 00 00 00       	mov    $0x0,%eax
f01030e7:	e8 d2 df ff ff       	call   f01010be <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f01030ec:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f01030ef:	83 e0 f3             	and    $0xfffffff3,%eax
f01030f2:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f01030f7:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01030fa:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103101:	e8 7f e3 ff ff       	call   f0101485 <page_alloc>
f0103106:	89 c3                	mov    %eax,%ebx
f0103108:	85 c0                	test   %eax,%eax
f010310a:	75 24                	jne    f0103130 <mem_init+0x189f>
f010310c:	c7 44 24 0c 05 50 10 	movl   $0xf0105005,0xc(%esp)
f0103113:	f0 
f0103114:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f010311b:	f0 
f010311c:	c7 44 24 04 04 04 00 	movl   $0x404,0x4(%esp)
f0103123:	00 
f0103124:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f010312b:	e8 64 cf ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0103130:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103137:	e8 49 e3 ff ff       	call   f0101485 <page_alloc>
f010313c:	89 c7                	mov    %eax,%edi
f010313e:	85 c0                	test   %eax,%eax
f0103140:	75 24                	jne    f0103166 <mem_init+0x18d5>
f0103142:	c7 44 24 0c 1b 50 10 	movl   $0xf010501b,0xc(%esp)
f0103149:	f0 
f010314a:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0103151:	f0 
f0103152:	c7 44 24 04 05 04 00 	movl   $0x405,0x4(%esp)
f0103159:	00 
f010315a:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0103161:	e8 2e cf ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0103166:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010316d:	e8 13 e3 ff ff       	call   f0101485 <page_alloc>
f0103172:	89 c6                	mov    %eax,%esi
f0103174:	85 c0                	test   %eax,%eax
f0103176:	75 24                	jne    f010319c <mem_init+0x190b>
f0103178:	c7 44 24 0c 31 50 10 	movl   $0xf0105031,0xc(%esp)
f010317f:	f0 
f0103180:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0103187:	f0 
f0103188:	c7 44 24 04 06 04 00 	movl   $0x406,0x4(%esp)
f010318f:	00 
f0103190:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0103197:	e8 f8 ce ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f010319c:	89 1c 24             	mov    %ebx,(%esp)
f010319f:	e8 9b e3 ff ff       	call   f010153f <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f01031a4:	89 f8                	mov    %edi,%eax
f01031a6:	e8 5f de ff ff       	call   f010100a <page2kva>
f01031ab:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01031b2:	00 
f01031b3:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f01031ba:	00 
f01031bb:	89 04 24             	mov    %eax,(%esp)
f01031be:	e8 44 0e 00 00       	call   f0104007 <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f01031c3:	89 f0                	mov    %esi,%eax
f01031c5:	e8 40 de ff ff       	call   f010100a <page2kva>
f01031ca:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01031d1:	00 
f01031d2:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f01031d9:	00 
f01031da:	89 04 24             	mov    %eax,(%esp)
f01031dd:	e8 25 0e 00 00       	call   f0104007 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f01031e2:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01031e9:	00 
f01031ea:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01031f1:	00 
f01031f2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01031f6:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f01031fb:	89 04 24             	mov    %eax,(%esp)
f01031fe:	e8 cb e5 ff ff       	call   f01017ce <page_insert>
	assert(pp1->pp_ref == 1);
f0103203:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0103208:	74 24                	je     f010322e <mem_init+0x199d>
f010320a:	c7 44 24 0c 02 51 10 	movl   $0xf0105102,0xc(%esp)
f0103211:	f0 
f0103212:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0103219:	f0 
f010321a:	c7 44 24 04 0b 04 00 	movl   $0x40b,0x4(%esp)
f0103221:	00 
f0103222:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0103229:	e8 66 ce ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f010322e:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0103235:	01 01 01 
f0103238:	74 24                	je     f010325e <mem_init+0x19cd>
f010323a:	c7 44 24 0c d0 58 10 	movl   $0xf01058d0,0xc(%esp)
f0103241:	f0 
f0103242:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f0103249:	f0 
f010324a:	c7 44 24 04 0c 04 00 	movl   $0x40c,0x4(%esp)
f0103251:	00 
f0103252:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0103259:	e8 36 ce ff ff       	call   f0100094 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f010325e:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0103265:	00 
f0103266:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010326d:	00 
f010326e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103272:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f0103277:	89 04 24             	mov    %eax,(%esp)
f010327a:	e8 4f e5 ff ff       	call   f01017ce <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f010327f:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0103286:	02 02 02 
f0103289:	74 24                	je     f01032af <mem_init+0x1a1e>
f010328b:	c7 44 24 0c f4 58 10 	movl   $0xf01058f4,0xc(%esp)
f0103292:	f0 
f0103293:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f010329a:	f0 
f010329b:	c7 44 24 04 0e 04 00 	movl   $0x40e,0x4(%esp)
f01032a2:	00 
f01032a3:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f01032aa:	e8 e5 cd ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f01032af:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01032b4:	74 24                	je     f01032da <mem_init+0x1a49>
f01032b6:	c7 44 24 0c 24 51 10 	movl   $0xf0105124,0xc(%esp)
f01032bd:	f0 
f01032be:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f01032c5:	f0 
f01032c6:	c7 44 24 04 0f 04 00 	movl   $0x40f,0x4(%esp)
f01032cd:	00 
f01032ce:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f01032d5:	e8 ba cd ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f01032da:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01032df:	74 24                	je     f0103305 <mem_init+0x1a74>
f01032e1:	c7 44 24 0c 8e 51 10 	movl   $0xf010518e,0xc(%esp)
f01032e8:	f0 
f01032e9:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f01032f0:	f0 
f01032f1:	c7 44 24 04 10 04 00 	movl   $0x410,0x4(%esp)
f01032f8:	00 
f01032f9:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f0103300:	e8 8f cd ff ff       	call   f0100094 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0103305:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f010330c:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f010330f:	89 f0                	mov    %esi,%eax
f0103311:	e8 f4 dc ff ff       	call   f010100a <page2kva>
f0103316:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f010331c:	74 24                	je     f0103342 <mem_init+0x1ab1>
f010331e:	c7 44 24 0c 18 59 10 	movl   $0xf0105918,0xc(%esp)
f0103325:	f0 
f0103326:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f010332d:	f0 
f010332e:	c7 44 24 04 12 04 00 	movl   $0x412,0x4(%esp)
f0103335:	00 
f0103336:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f010333d:	e8 52 cd ff ff       	call   f0100094 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0103342:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0103349:	00 
f010334a:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f010334f:	89 04 24             	mov    %eax,(%esp)
f0103352:	e8 39 e4 ff ff       	call   f0101790 <page_remove>
	assert(pp2->pp_ref == 0);
f0103357:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010335c:	74 24                	je     f0103382 <mem_init+0x1af1>
f010335e:	c7 44 24 0c 5c 51 10 	movl   $0xf010515c,0xc(%esp)
f0103365:	f0 
f0103366:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f010336d:	f0 
f010336e:	c7 44 24 04 14 04 00 	movl   $0x414,0x4(%esp)
f0103375:	00 
f0103376:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f010337d:	e8 12 cd ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0103382:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f0103387:	8b 08                	mov    (%eax),%ecx
f0103389:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp) //求出当前页的物理地址
{
	return (pp - pages) << PGSHIFT;
f010338f:	89 da                	mov    %ebx,%edx
f0103391:	2b 15 6c 99 11 f0    	sub    0xf011996c,%edx
f0103397:	c1 fa 03             	sar    $0x3,%edx
f010339a:	c1 e2 0c             	shl    $0xc,%edx
f010339d:	39 d1                	cmp    %edx,%ecx
f010339f:	74 24                	je     f01033c5 <mem_init+0x1b34>
f01033a1:	c7 44 24 0c 5c 54 10 	movl   $0xf010545c,0xc(%esp)
f01033a8:	f0 
f01033a9:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f01033b0:	f0 
f01033b1:	c7 44 24 04 17 04 00 	movl   $0x417,0x4(%esp)
f01033b8:	00 
f01033b9:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f01033c0:	e8 cf cc ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f01033c5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f01033cb:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01033d0:	74 24                	je     f01033f6 <mem_init+0x1b65>
f01033d2:	c7 44 24 0c 13 51 10 	movl   $0xf0105113,0xc(%esp)
f01033d9:	f0 
f01033da:	c7 44 24 08 28 4f 10 	movl   $0xf0104f28,0x8(%esp)
f01033e1:	f0 
f01033e2:	c7 44 24 04 19 04 00 	movl   $0x419,0x4(%esp)
f01033e9:	00 
f01033ea:	c7 04 24 02 4f 10 f0 	movl   $0xf0104f02,(%esp)
f01033f1:	e8 9e cc ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f01033f6:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f01033fc:	89 1c 24             	mov    %ebx,(%esp)
f01033ff:	e8 3b e1 ff ff       	call   f010153f <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0103404:	c7 04 24 44 59 10 f0 	movl   $0xf0105944,(%esp)
f010340b:	e8 83 00 00 00       	call   f0103493 <cprintf>
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
 
}
f0103410:	83 c4 4c             	add    $0x4c,%esp
f0103413:	5b                   	pop    %ebx
f0103414:	5e                   	pop    %esi
f0103415:	5f                   	pop    %edi
f0103416:	5d                   	pop    %ebp
f0103417:	c3                   	ret    

f0103418 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0103418:	55                   	push   %ebp
f0103419:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010341b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010341e:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0103421:	5d                   	pop    %ebp
f0103422:	c3                   	ret    

f0103423 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103423:	55                   	push   %ebp
f0103424:	89 e5                	mov    %esp,%ebp
f0103426:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010342a:	ba 70 00 00 00       	mov    $0x70,%edx
f010342f:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103430:	b2 71                	mov    $0x71,%dl
f0103432:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103433:	0f b6 c0             	movzbl %al,%eax
}
f0103436:	5d                   	pop    %ebp
f0103437:	c3                   	ret    

f0103438 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103438:	55                   	push   %ebp
f0103439:	89 e5                	mov    %esp,%ebp
f010343b:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010343f:	ba 70 00 00 00       	mov    $0x70,%edx
f0103444:	ee                   	out    %al,(%dx)
f0103445:	b2 71                	mov    $0x71,%dl
f0103447:	8b 45 0c             	mov    0xc(%ebp),%eax
f010344a:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f010344b:	5d                   	pop    %ebp
f010344c:	c3                   	ret    

f010344d <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010344d:	55                   	push   %ebp
f010344e:	89 e5                	mov    %esp,%ebp
f0103450:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0103453:	8b 45 08             	mov    0x8(%ebp),%eax
f0103456:	89 04 24             	mov    %eax,(%esp)
f0103459:	e8 c9 d2 ff ff       	call   f0100727 <cputchar>
	*cnt++;
}
f010345e:	c9                   	leave  
f010345f:	c3                   	ret    

f0103460 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103460:	55                   	push   %ebp
f0103461:	89 e5                	mov    %esp,%ebp
f0103463:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0103466:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010346d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103470:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103474:	8b 45 08             	mov    0x8(%ebp),%eax
f0103477:	89 44 24 08          	mov    %eax,0x8(%esp)
f010347b:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010347e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103482:	c7 04 24 4d 34 10 f0 	movl   $0xf010344d,(%esp)
f0103489:	e8 b0 04 00 00       	call   f010393e <vprintfmt>
	return cnt;
}
f010348e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103491:	c9                   	leave  
f0103492:	c3                   	ret    

f0103493 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103493:	55                   	push   %ebp
f0103494:	89 e5                	mov    %esp,%ebp
f0103496:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103499:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010349c:	89 44 24 04          	mov    %eax,0x4(%esp)
f01034a0:	8b 45 08             	mov    0x8(%ebp),%eax
f01034a3:	89 04 24             	mov    %eax,(%esp)
f01034a6:	e8 b5 ff ff ff       	call   f0103460 <vcprintf>
	va_end(ap);

	return cnt;
}
f01034ab:	c9                   	leave  
f01034ac:	c3                   	ret    

f01034ad <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01034ad:	55                   	push   %ebp
f01034ae:	89 e5                	mov    %esp,%ebp
f01034b0:	57                   	push   %edi
f01034b1:	56                   	push   %esi
f01034b2:	53                   	push   %ebx
f01034b3:	83 ec 10             	sub    $0x10,%esp
f01034b6:	89 c6                	mov    %eax,%esi
f01034b8:	89 55 e8             	mov    %edx,-0x18(%ebp)
f01034bb:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f01034be:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01034c1:	8b 1a                	mov    (%edx),%ebx
f01034c3:	8b 01                	mov    (%ecx),%eax
f01034c5:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01034c8:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f01034cf:	eb 77                	jmp    f0103548 <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f01034d1:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01034d4:	01 d8                	add    %ebx,%eax
f01034d6:	b9 02 00 00 00       	mov    $0x2,%ecx
f01034db:	99                   	cltd   
f01034dc:	f7 f9                	idiv   %ecx
f01034de:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01034e0:	eb 01                	jmp    f01034e3 <stab_binsearch+0x36>
			m--;
f01034e2:	49                   	dec    %ecx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01034e3:	39 d9                	cmp    %ebx,%ecx
f01034e5:	7c 1d                	jl     f0103504 <stab_binsearch+0x57>
f01034e7:	6b d1 0c             	imul   $0xc,%ecx,%edx
f01034ea:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f01034ef:	39 fa                	cmp    %edi,%edx
f01034f1:	75 ef                	jne    f01034e2 <stab_binsearch+0x35>
f01034f3:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01034f6:	6b d1 0c             	imul   $0xc,%ecx,%edx
f01034f9:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f01034fd:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0103500:	73 18                	jae    f010351a <stab_binsearch+0x6d>
f0103502:	eb 05                	jmp    f0103509 <stab_binsearch+0x5c>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0103504:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0103507:	eb 3f                	jmp    f0103548 <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0103509:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f010350c:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f010350e:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103511:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0103518:	eb 2e                	jmp    f0103548 <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f010351a:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010351d:	73 15                	jae    f0103534 <stab_binsearch+0x87>
			*region_right = m - 1;
f010351f:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103522:	48                   	dec    %eax
f0103523:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103526:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0103529:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010352b:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0103532:	eb 14                	jmp    f0103548 <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103534:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0103537:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f010353a:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f010353c:	ff 45 0c             	incl   0xc(%ebp)
f010353f:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103541:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0103548:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f010354b:	7e 84                	jle    f01034d1 <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010354d:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0103551:	75 0d                	jne    f0103560 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0103553:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0103556:	8b 00                	mov    (%eax),%eax
f0103558:	48                   	dec    %eax
f0103559:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010355c:	89 07                	mov    %eax,(%edi)
f010355e:	eb 22                	jmp    f0103582 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103560:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103563:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103565:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0103568:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010356a:	eb 01                	jmp    f010356d <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010356c:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010356d:	39 c1                	cmp    %eax,%ecx
f010356f:	7d 0c                	jge    f010357d <stab_binsearch+0xd0>
f0103571:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0103574:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0103579:	39 fa                	cmp    %edi,%edx
f010357b:	75 ef                	jne    f010356c <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f010357d:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0103580:	89 07                	mov    %eax,(%edi)
	}
}
f0103582:	83 c4 10             	add    $0x10,%esp
f0103585:	5b                   	pop    %ebx
f0103586:	5e                   	pop    %esi
f0103587:	5f                   	pop    %edi
f0103588:	5d                   	pop    %ebp
f0103589:	c3                   	ret    

f010358a <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010358a:	55                   	push   %ebp
f010358b:	89 e5                	mov    %esp,%ebp
f010358d:	57                   	push   %edi
f010358e:	56                   	push   %esi
f010358f:	53                   	push   %ebx
f0103590:	83 ec 3c             	sub    $0x3c,%esp
f0103593:	8b 75 08             	mov    0x8(%ebp),%esi
f0103596:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0103599:	c7 03 70 59 10 f0    	movl   $0xf0105970,(%ebx)
	info->eip_line = 0;
f010359f:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f01035a6:	c7 43 08 70 59 10 f0 	movl   $0xf0105970,0x8(%ebx)
	info->eip_fn_namelen = 9;
f01035ad:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f01035b4:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01035b7:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01035be:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01035c4:	76 12                	jbe    f01035d8 <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01035c6:	b8 9b e4 10 f0       	mov    $0xf010e49b,%eax
f01035cb:	3d a5 c4 10 f0       	cmp    $0xf010c4a5,%eax
f01035d0:	0f 86 d2 01 00 00    	jbe    f01037a8 <debuginfo_eip+0x21e>
f01035d6:	eb 1c                	jmp    f01035f4 <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f01035d8:	c7 44 24 08 7a 59 10 	movl   $0xf010597a,0x8(%esp)
f01035df:	f0 
f01035e0:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f01035e7:	00 
f01035e8:	c7 04 24 87 59 10 f0 	movl   $0xf0105987,(%esp)
f01035ef:	e8 a0 ca ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01035f4:	80 3d 9a e4 10 f0 00 	cmpb   $0x0,0xf010e49a
f01035fb:	0f 85 ae 01 00 00    	jne    f01037af <debuginfo_eip+0x225>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103601:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103608:	b8 a4 c4 10 f0       	mov    $0xf010c4a4,%eax
f010360d:	2d b0 5b 10 f0       	sub    $0xf0105bb0,%eax
f0103612:	c1 f8 02             	sar    $0x2,%eax
f0103615:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f010361b:	83 e8 01             	sub    $0x1,%eax
f010361e:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103621:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103625:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f010362c:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f010362f:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103632:	b8 b0 5b 10 f0       	mov    $0xf0105bb0,%eax
f0103637:	e8 71 fe ff ff       	call   f01034ad <stab_binsearch>
	if (lfile == 0)
f010363c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010363f:	85 c0                	test   %eax,%eax
f0103641:	0f 84 6f 01 00 00    	je     f01037b6 <debuginfo_eip+0x22c>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103647:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f010364a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010364d:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103650:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103654:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f010365b:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f010365e:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103661:	b8 b0 5b 10 f0       	mov    $0xf0105bb0,%eax
f0103666:	e8 42 fe ff ff       	call   f01034ad <stab_binsearch>

	if (lfun <= rfun) {
f010366b:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010366e:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103671:	39 d0                	cmp    %edx,%eax
f0103673:	7f 3d                	jg     f01036b2 <debuginfo_eip+0x128>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103675:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0103678:	8d b9 b0 5b 10 f0    	lea    -0xfefa450(%ecx),%edi
f010367e:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0103681:	8b 89 b0 5b 10 f0    	mov    -0xfefa450(%ecx),%ecx
f0103687:	bf 9b e4 10 f0       	mov    $0xf010e49b,%edi
f010368c:	81 ef a5 c4 10 f0    	sub    $0xf010c4a5,%edi
f0103692:	39 f9                	cmp    %edi,%ecx
f0103694:	73 09                	jae    f010369f <debuginfo_eip+0x115>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103696:	81 c1 a5 c4 10 f0    	add    $0xf010c4a5,%ecx
f010369c:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f010369f:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f01036a2:	8b 4f 08             	mov    0x8(%edi),%ecx
f01036a5:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f01036a8:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f01036aa:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01036ad:	89 55 d0             	mov    %edx,-0x30(%ebp)
f01036b0:	eb 0f                	jmp    f01036c1 <debuginfo_eip+0x137>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01036b2:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f01036b5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01036b8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f01036bb:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01036be:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01036c1:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f01036c8:	00 
f01036c9:	8b 43 08             	mov    0x8(%ebx),%eax
f01036cc:	89 04 24             	mov    %eax,(%esp)
f01036cf:	e8 17 09 00 00       	call   f0103feb <strfind>
f01036d4:	2b 43 08             	sub    0x8(%ebx),%eax
f01036d7:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f01036da:	89 74 24 04          	mov    %esi,0x4(%esp)
f01036de:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f01036e5:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f01036e8:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01036eb:	b8 b0 5b 10 f0       	mov    $0xf0105bb0,%eax
f01036f0:	e8 b8 fd ff ff       	call   f01034ad <stab_binsearch>
	if (lline > rline)
f01036f5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01036f8:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f01036fb:	7e 09                	jle    f0103706 <debuginfo_eip+0x17c>
	    info->eip_line = -1;
f01036fd:	c7 43 04 ff ff ff ff 	movl   $0xffffffff,0x4(%ebx)
f0103704:	eb 0d                	jmp    f0103713 <debuginfo_eip+0x189>
	else
	    info->eip_line = stabs[lline].n_desc;
f0103706:	6b c0 0c             	imul   $0xc,%eax,%eax
f0103709:	0f b7 80 b6 5b 10 f0 	movzwl -0xfefa44a(%eax),%eax
f0103710:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103713:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103716:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0103719:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010371c:	6b d0 0c             	imul   $0xc,%eax,%edx
f010371f:	81 c2 b0 5b 10 f0    	add    $0xf0105bb0,%edx
f0103725:	eb 06                	jmp    f010372d <debuginfo_eip+0x1a3>
f0103727:	83 e8 01             	sub    $0x1,%eax
f010372a:	83 ea 0c             	sub    $0xc,%edx
f010372d:	89 c6                	mov    %eax,%esi
f010372f:	39 45 c4             	cmp    %eax,-0x3c(%ebp)
f0103732:	7f 33                	jg     f0103767 <debuginfo_eip+0x1dd>
	       && stabs[lline].n_type != N_SOL
f0103734:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103738:	80 f9 84             	cmp    $0x84,%cl
f010373b:	74 0b                	je     f0103748 <debuginfo_eip+0x1be>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f010373d:	80 f9 64             	cmp    $0x64,%cl
f0103740:	75 e5                	jne    f0103727 <debuginfo_eip+0x19d>
f0103742:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0103746:	74 df                	je     f0103727 <debuginfo_eip+0x19d>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103748:	6b f6 0c             	imul   $0xc,%esi,%esi
f010374b:	8b 86 b0 5b 10 f0    	mov    -0xfefa450(%esi),%eax
f0103751:	ba 9b e4 10 f0       	mov    $0xf010e49b,%edx
f0103756:	81 ea a5 c4 10 f0    	sub    $0xf010c4a5,%edx
f010375c:	39 d0                	cmp    %edx,%eax
f010375e:	73 07                	jae    f0103767 <debuginfo_eip+0x1dd>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103760:	05 a5 c4 10 f0       	add    $0xf010c4a5,%eax
f0103765:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103767:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010376a:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010376d:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103772:	39 ca                	cmp    %ecx,%edx
f0103774:	7d 4c                	jge    f01037c2 <debuginfo_eip+0x238>
		for (lline = lfun + 1;
f0103776:	8d 42 01             	lea    0x1(%edx),%eax
f0103779:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010377c:	89 c2                	mov    %eax,%edx
f010377e:	6b c0 0c             	imul   $0xc,%eax,%eax
f0103781:	05 b0 5b 10 f0       	add    $0xf0105bb0,%eax
f0103786:	89 ce                	mov    %ecx,%esi
f0103788:	eb 04                	jmp    f010378e <debuginfo_eip+0x204>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f010378a:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f010378e:	39 d6                	cmp    %edx,%esi
f0103790:	7e 2b                	jle    f01037bd <debuginfo_eip+0x233>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103792:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0103796:	83 c2 01             	add    $0x1,%edx
f0103799:	83 c0 0c             	add    $0xc,%eax
f010379c:	80 f9 a0             	cmp    $0xa0,%cl
f010379f:	74 e9                	je     f010378a <debuginfo_eip+0x200>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01037a1:	b8 00 00 00 00       	mov    $0x0,%eax
f01037a6:	eb 1a                	jmp    f01037c2 <debuginfo_eip+0x238>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01037a8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01037ad:	eb 13                	jmp    f01037c2 <debuginfo_eip+0x238>
f01037af:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01037b4:	eb 0c                	jmp    f01037c2 <debuginfo_eip+0x238>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f01037b6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01037bb:	eb 05                	jmp    f01037c2 <debuginfo_eip+0x238>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01037bd:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01037c2:	83 c4 3c             	add    $0x3c,%esp
f01037c5:	5b                   	pop    %ebx
f01037c6:	5e                   	pop    %esi
f01037c7:	5f                   	pop    %edi
f01037c8:	5d                   	pop    %ebp
f01037c9:	c3                   	ret    
f01037ca:	66 90                	xchg   %ax,%ax
f01037cc:	66 90                	xchg   %ax,%ax
f01037ce:	66 90                	xchg   %ax,%ax

f01037d0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01037d0:	55                   	push   %ebp
f01037d1:	89 e5                	mov    %esp,%ebp
f01037d3:	57                   	push   %edi
f01037d4:	56                   	push   %esi
f01037d5:	53                   	push   %ebx
f01037d6:	83 ec 3c             	sub    $0x3c,%esp
f01037d9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01037dc:	89 d7                	mov    %edx,%edi
f01037de:	8b 45 08             	mov    0x8(%ebp),%eax
f01037e1:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01037e4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01037e7:	89 c3                	mov    %eax,%ebx
f01037e9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01037ec:	8b 45 10             	mov    0x10(%ebp),%eax
f01037ef:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01037f2:	b9 00 00 00 00       	mov    $0x0,%ecx
f01037f7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01037fa:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01037fd:	39 d9                	cmp    %ebx,%ecx
f01037ff:	72 05                	jb     f0103806 <printnum+0x36>
f0103801:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0103804:	77 69                	ja     f010386f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103806:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0103809:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f010380d:	83 ee 01             	sub    $0x1,%esi
f0103810:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103814:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103818:	8b 44 24 08          	mov    0x8(%esp),%eax
f010381c:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0103820:	89 c3                	mov    %eax,%ebx
f0103822:	89 d6                	mov    %edx,%esi
f0103824:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103827:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010382a:	89 54 24 08          	mov    %edx,0x8(%esp)
f010382e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0103832:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103835:	89 04 24             	mov    %eax,(%esp)
f0103838:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010383b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010383f:	e8 cc 09 00 00       	call   f0104210 <__udivdi3>
f0103844:	89 d9                	mov    %ebx,%ecx
f0103846:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010384a:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010384e:	89 04 24             	mov    %eax,(%esp)
f0103851:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103855:	89 fa                	mov    %edi,%edx
f0103857:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010385a:	e8 71 ff ff ff       	call   f01037d0 <printnum>
f010385f:	eb 1b                	jmp    f010387c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103861:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103865:	8b 45 18             	mov    0x18(%ebp),%eax
f0103868:	89 04 24             	mov    %eax,(%esp)
f010386b:	ff d3                	call   *%ebx
f010386d:	eb 03                	jmp    f0103872 <printnum+0xa2>
f010386f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103872:	83 ee 01             	sub    $0x1,%esi
f0103875:	85 f6                	test   %esi,%esi
f0103877:	7f e8                	jg     f0103861 <printnum+0x91>
f0103879:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010387c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103880:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103884:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103887:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010388a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010388e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103892:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103895:	89 04 24             	mov    %eax,(%esp)
f0103898:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010389b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010389f:	e8 9c 0a 00 00       	call   f0104340 <__umoddi3>
f01038a4:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01038a8:	0f be 80 95 59 10 f0 	movsbl -0xfefa66b(%eax),%eax
f01038af:	89 04 24             	mov    %eax,(%esp)
f01038b2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01038b5:	ff d0                	call   *%eax
}
f01038b7:	83 c4 3c             	add    $0x3c,%esp
f01038ba:	5b                   	pop    %ebx
f01038bb:	5e                   	pop    %esi
f01038bc:	5f                   	pop    %edi
f01038bd:	5d                   	pop    %ebp
f01038be:	c3                   	ret    

f01038bf <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01038bf:	55                   	push   %ebp
f01038c0:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01038c2:	83 fa 01             	cmp    $0x1,%edx
f01038c5:	7e 0e                	jle    f01038d5 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01038c7:	8b 10                	mov    (%eax),%edx
f01038c9:	8d 4a 08             	lea    0x8(%edx),%ecx
f01038cc:	89 08                	mov    %ecx,(%eax)
f01038ce:	8b 02                	mov    (%edx),%eax
f01038d0:	8b 52 04             	mov    0x4(%edx),%edx
f01038d3:	eb 22                	jmp    f01038f7 <getuint+0x38>
	else if (lflag)
f01038d5:	85 d2                	test   %edx,%edx
f01038d7:	74 10                	je     f01038e9 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01038d9:	8b 10                	mov    (%eax),%edx
f01038db:	8d 4a 04             	lea    0x4(%edx),%ecx
f01038de:	89 08                	mov    %ecx,(%eax)
f01038e0:	8b 02                	mov    (%edx),%eax
f01038e2:	ba 00 00 00 00       	mov    $0x0,%edx
f01038e7:	eb 0e                	jmp    f01038f7 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01038e9:	8b 10                	mov    (%eax),%edx
f01038eb:	8d 4a 04             	lea    0x4(%edx),%ecx
f01038ee:	89 08                	mov    %ecx,(%eax)
f01038f0:	8b 02                	mov    (%edx),%eax
f01038f2:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01038f7:	5d                   	pop    %ebp
f01038f8:	c3                   	ret    

f01038f9 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01038f9:	55                   	push   %ebp
f01038fa:	89 e5                	mov    %esp,%ebp
f01038fc:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01038ff:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103903:	8b 10                	mov    (%eax),%edx
f0103905:	3b 50 04             	cmp    0x4(%eax),%edx
f0103908:	73 0a                	jae    f0103914 <sprintputch+0x1b>
		*b->buf++ = ch;
f010390a:	8d 4a 01             	lea    0x1(%edx),%ecx
f010390d:	89 08                	mov    %ecx,(%eax)
f010390f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103912:	88 02                	mov    %al,(%edx)
}
f0103914:	5d                   	pop    %ebp
f0103915:	c3                   	ret    

f0103916 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103916:	55                   	push   %ebp
f0103917:	89 e5                	mov    %esp,%ebp
f0103919:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f010391c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010391f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103923:	8b 45 10             	mov    0x10(%ebp),%eax
f0103926:	89 44 24 08          	mov    %eax,0x8(%esp)
f010392a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010392d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103931:	8b 45 08             	mov    0x8(%ebp),%eax
f0103934:	89 04 24             	mov    %eax,(%esp)
f0103937:	e8 02 00 00 00       	call   f010393e <vprintfmt>
	va_end(ap);
}
f010393c:	c9                   	leave  
f010393d:	c3                   	ret    

f010393e <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f010393e:	55                   	push   %ebp
f010393f:	89 e5                	mov    %esp,%ebp
f0103941:	57                   	push   %edi
f0103942:	56                   	push   %esi
f0103943:	53                   	push   %ebx
f0103944:	83 ec 3c             	sub    $0x3c,%esp
f0103947:	8b 7d 0c             	mov    0xc(%ebp),%edi
f010394a:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010394d:	eb 14                	jmp    f0103963 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010394f:	85 c0                	test   %eax,%eax
f0103951:	0f 84 c7 03 00 00    	je     f0103d1e <vprintfmt+0x3e0>
				return;
			putch(ch, putdat);
f0103957:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010395b:	89 04 24             	mov    %eax,(%esp)
f010395e:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103961:	89 f3                	mov    %esi,%ebx
f0103963:	8d 73 01             	lea    0x1(%ebx),%esi
f0103966:	0f b6 03             	movzbl (%ebx),%eax
f0103969:	83 f8 25             	cmp    $0x25,%eax
f010396c:	75 e1                	jne    f010394f <vprintfmt+0x11>
f010396e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0103972:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0103979:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103980:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0103987:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
f010398e:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103993:	eb 1d                	jmp    f01039b2 <vprintfmt+0x74>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103995:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0103997:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f010399b:	eb 15                	jmp    f01039b2 <vprintfmt+0x74>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010399d:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f010399f:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f01039a3:	eb 0d                	jmp    f01039b2 <vprintfmt+0x74>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f01039a5:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01039a8:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01039ab:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01039b2:	8d 5e 01             	lea    0x1(%esi),%ebx
f01039b5:	0f b6 16             	movzbl (%esi),%edx
f01039b8:	0f b6 c2             	movzbl %dl,%eax
f01039bb:	83 ea 23             	sub    $0x23,%edx
f01039be:	80 fa 55             	cmp    $0x55,%dl
f01039c1:	0f 87 37 03 00 00    	ja     f0103cfe <vprintfmt+0x3c0>
f01039c7:	0f b6 d2             	movzbl %dl,%edx
f01039ca:	ff 24 95 20 5a 10 f0 	jmp    *-0xfefa5e0(,%edx,4)
f01039d1:	89 de                	mov    %ebx,%esi
f01039d3:	89 ca                	mov    %ecx,%edx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01039d5:	8d 14 92             	lea    (%edx,%edx,4),%edx
f01039d8:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
f01039dc:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f01039df:	8d 58 d0             	lea    -0x30(%eax),%ebx
f01039e2:	83 fb 09             	cmp    $0x9,%ebx
f01039e5:	77 31                	ja     f0103a18 <vprintfmt+0xda>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01039e7:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f01039ea:	eb e9                	jmp    f01039d5 <vprintfmt+0x97>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01039ec:	8b 45 14             	mov    0x14(%ebp),%eax
f01039ef:	8d 50 04             	lea    0x4(%eax),%edx
f01039f2:	89 55 14             	mov    %edx,0x14(%ebp)
f01039f5:	8b 00                	mov    (%eax),%eax
f01039f7:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01039fa:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f01039fc:	eb 1d                	jmp    f0103a1b <vprintfmt+0xdd>
f01039fe:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103a01:	85 c0                	test   %eax,%eax
f0103a03:	0f 48 c1             	cmovs  %ecx,%eax
f0103a06:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103a09:	89 de                	mov    %ebx,%esi
f0103a0b:	eb a5                	jmp    f01039b2 <vprintfmt+0x74>
f0103a0d:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103a0f:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f0103a16:	eb 9a                	jmp    f01039b2 <vprintfmt+0x74>
f0103a18:	89 55 d0             	mov    %edx,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0103a1b:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103a1f:	79 91                	jns    f01039b2 <vprintfmt+0x74>
f0103a21:	eb 82                	jmp    f01039a5 <vprintfmt+0x67>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103a23:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103a27:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0103a29:	eb 87                	jmp    f01039b2 <vprintfmt+0x74>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103a2b:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a2e:	8d 50 04             	lea    0x4(%eax),%edx
f0103a31:	89 55 14             	mov    %edx,0x14(%ebp)
f0103a34:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103a38:	8b 00                	mov    (%eax),%eax
f0103a3a:	89 04 24             	mov    %eax,(%esp)
f0103a3d:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103a40:	e9 1e ff ff ff       	jmp    f0103963 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103a45:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a48:	8d 50 04             	lea    0x4(%eax),%edx
f0103a4b:	89 55 14             	mov    %edx,0x14(%ebp)
f0103a4e:	8b 00                	mov    (%eax),%eax
f0103a50:	99                   	cltd   
f0103a51:	31 d0                	xor    %edx,%eax
f0103a53:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103a55:	83 f8 07             	cmp    $0x7,%eax
f0103a58:	7f 0b                	jg     f0103a65 <vprintfmt+0x127>
f0103a5a:	8b 14 85 80 5b 10 f0 	mov    -0xfefa480(,%eax,4),%edx
f0103a61:	85 d2                	test   %edx,%edx
f0103a63:	75 20                	jne    f0103a85 <vprintfmt+0x147>
				printfmt(putch, putdat, "error %d", err);
f0103a65:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103a69:	c7 44 24 08 ad 59 10 	movl   $0xf01059ad,0x8(%esp)
f0103a70:	f0 
f0103a71:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103a75:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a78:	89 04 24             	mov    %eax,(%esp)
f0103a7b:	e8 96 fe ff ff       	call   f0103916 <printfmt>
f0103a80:	e9 de fe ff ff       	jmp    f0103963 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f0103a85:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103a89:	c7 44 24 08 3a 4f 10 	movl   $0xf0104f3a,0x8(%esp)
f0103a90:	f0 
f0103a91:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103a95:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a98:	89 04 24             	mov    %eax,(%esp)
f0103a9b:	e8 76 fe ff ff       	call   f0103916 <printfmt>
f0103aa0:	e9 be fe ff ff       	jmp    f0103963 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103aa5:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0103aa8:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103aab:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103aae:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ab1:	8d 50 04             	lea    0x4(%eax),%edx
f0103ab4:	89 55 14             	mov    %edx,0x14(%ebp)
f0103ab7:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f0103ab9:	85 f6                	test   %esi,%esi
f0103abb:	b8 a6 59 10 f0       	mov    $0xf01059a6,%eax
f0103ac0:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f0103ac3:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f0103ac7:	0f 84 97 00 00 00    	je     f0103b64 <vprintfmt+0x226>
f0103acd:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0103ad1:	0f 8e 9b 00 00 00    	jle    f0103b72 <vprintfmt+0x234>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103ad7:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103adb:	89 34 24             	mov    %esi,(%esp)
f0103ade:	e8 b5 03 00 00       	call   f0103e98 <strnlen>
f0103ae3:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0103ae6:	29 c1                	sub    %eax,%ecx
f0103ae8:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
					putch(padc, putdat);
f0103aeb:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0103aef:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103af2:	89 75 d8             	mov    %esi,-0x28(%ebp)
f0103af5:	8b 75 08             	mov    0x8(%ebp),%esi
f0103af8:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103afb:	89 cb                	mov    %ecx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103afd:	eb 0f                	jmp    f0103b0e <vprintfmt+0x1d0>
					putch(padc, putdat);
f0103aff:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103b03:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103b06:	89 04 24             	mov    %eax,(%esp)
f0103b09:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103b0b:	83 eb 01             	sub    $0x1,%ebx
f0103b0e:	85 db                	test   %ebx,%ebx
f0103b10:	7f ed                	jg     f0103aff <vprintfmt+0x1c1>
f0103b12:	8b 75 d8             	mov    -0x28(%ebp),%esi
f0103b15:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0103b18:	85 c9                	test   %ecx,%ecx
f0103b1a:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b1f:	0f 49 c1             	cmovns %ecx,%eax
f0103b22:	29 c1                	sub    %eax,%ecx
f0103b24:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0103b27:	89 cf                	mov    %ecx,%edi
f0103b29:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0103b2c:	eb 50                	jmp    f0103b7e <vprintfmt+0x240>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103b2e:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103b32:	74 1e                	je     f0103b52 <vprintfmt+0x214>
f0103b34:	0f be d2             	movsbl %dl,%edx
f0103b37:	83 ea 20             	sub    $0x20,%edx
f0103b3a:	83 fa 5e             	cmp    $0x5e,%edx
f0103b3d:	76 13                	jbe    f0103b52 <vprintfmt+0x214>
					putch('?', putdat);
f0103b3f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103b42:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b46:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0103b4d:	ff 55 08             	call   *0x8(%ebp)
f0103b50:	eb 0d                	jmp    f0103b5f <vprintfmt+0x221>
				else
					putch(ch, putdat);
f0103b52:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103b55:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103b59:	89 04 24             	mov    %eax,(%esp)
f0103b5c:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103b5f:	83 ef 01             	sub    $0x1,%edi
f0103b62:	eb 1a                	jmp    f0103b7e <vprintfmt+0x240>
f0103b64:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0103b67:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0103b6a:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103b6d:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0103b70:	eb 0c                	jmp    f0103b7e <vprintfmt+0x240>
f0103b72:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0103b75:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0103b78:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103b7b:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0103b7e:	83 c6 01             	add    $0x1,%esi
f0103b81:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f0103b85:	0f be c2             	movsbl %dl,%eax
f0103b88:	85 c0                	test   %eax,%eax
f0103b8a:	74 27                	je     f0103bb3 <vprintfmt+0x275>
f0103b8c:	85 db                	test   %ebx,%ebx
f0103b8e:	78 9e                	js     f0103b2e <vprintfmt+0x1f0>
f0103b90:	83 eb 01             	sub    $0x1,%ebx
f0103b93:	79 99                	jns    f0103b2e <vprintfmt+0x1f0>
f0103b95:	89 f8                	mov    %edi,%eax
f0103b97:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0103b9a:	8b 75 08             	mov    0x8(%ebp),%esi
f0103b9d:	89 c3                	mov    %eax,%ebx
f0103b9f:	eb 1a                	jmp    f0103bbb <vprintfmt+0x27d>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103ba1:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103ba5:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0103bac:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103bae:	83 eb 01             	sub    $0x1,%ebx
f0103bb1:	eb 08                	jmp    f0103bbb <vprintfmt+0x27d>
f0103bb3:	89 fb                	mov    %edi,%ebx
f0103bb5:	8b 75 08             	mov    0x8(%ebp),%esi
f0103bb8:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0103bbb:	85 db                	test   %ebx,%ebx
f0103bbd:	7f e2                	jg     f0103ba1 <vprintfmt+0x263>
f0103bbf:	89 75 08             	mov    %esi,0x8(%ebp)
f0103bc2:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0103bc5:	e9 99 fd ff ff       	jmp    f0103963 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103bca:	83 7d d4 01          	cmpl   $0x1,-0x2c(%ebp)
f0103bce:	7e 16                	jle    f0103be6 <vprintfmt+0x2a8>
		return va_arg(*ap, long long);
f0103bd0:	8b 45 14             	mov    0x14(%ebp),%eax
f0103bd3:	8d 50 08             	lea    0x8(%eax),%edx
f0103bd6:	89 55 14             	mov    %edx,0x14(%ebp)
f0103bd9:	8b 50 04             	mov    0x4(%eax),%edx
f0103bdc:	8b 00                	mov    (%eax),%eax
f0103bde:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103be1:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103be4:	eb 34                	jmp    f0103c1a <vprintfmt+0x2dc>
	else if (lflag)
f0103be6:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0103bea:	74 18                	je     f0103c04 <vprintfmt+0x2c6>
		return va_arg(*ap, long);
f0103bec:	8b 45 14             	mov    0x14(%ebp),%eax
f0103bef:	8d 50 04             	lea    0x4(%eax),%edx
f0103bf2:	89 55 14             	mov    %edx,0x14(%ebp)
f0103bf5:	8b 30                	mov    (%eax),%esi
f0103bf7:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0103bfa:	89 f0                	mov    %esi,%eax
f0103bfc:	c1 f8 1f             	sar    $0x1f,%eax
f0103bff:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103c02:	eb 16                	jmp    f0103c1a <vprintfmt+0x2dc>
	else
		return va_arg(*ap, int);
f0103c04:	8b 45 14             	mov    0x14(%ebp),%eax
f0103c07:	8d 50 04             	lea    0x4(%eax),%edx
f0103c0a:	89 55 14             	mov    %edx,0x14(%ebp)
f0103c0d:	8b 30                	mov    (%eax),%esi
f0103c0f:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0103c12:	89 f0                	mov    %esi,%eax
f0103c14:	c1 f8 1f             	sar    $0x1f,%eax
f0103c17:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0103c1a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103c1d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103c20:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103c25:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103c29:	0f 89 97 00 00 00    	jns    f0103cc6 <vprintfmt+0x388>
				putch('-', putdat);
f0103c2f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103c33:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0103c3a:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0103c3d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103c40:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103c43:	f7 d8                	neg    %eax
f0103c45:	83 d2 00             	adc    $0x0,%edx
f0103c48:	f7 da                	neg    %edx
			}
			base = 10;
f0103c4a:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0103c4f:	eb 75                	jmp    f0103cc6 <vprintfmt+0x388>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0103c51:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0103c54:	8d 45 14             	lea    0x14(%ebp),%eax
f0103c57:	e8 63 fc ff ff       	call   f01038bf <getuint>
			base = 10;
f0103c5c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0103c61:	eb 63                	jmp    f0103cc6 <vprintfmt+0x388>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('0', putdat);
f0103c63:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103c67:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0103c6e:	ff 55 08             	call   *0x8(%ebp)
			num = getuint(&ap, lflag);
f0103c71:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0103c74:	8d 45 14             	lea    0x14(%ebp),%eax
f0103c77:	e8 43 fc ff ff       	call   f01038bf <getuint>
			base = 8;
f0103c7c:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number; 
f0103c81:	eb 43                	jmp    f0103cc6 <vprintfmt+0x388>

		// pointer
		case 'p':
			putch('0', putdat);
f0103c83:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103c87:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0103c8e:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0103c91:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103c95:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0103c9c:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0103c9f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ca2:	8d 50 04             	lea    0x4(%eax),%edx
f0103ca5:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0103ca8:	8b 00                	mov    (%eax),%eax
f0103caa:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0103caf:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0103cb4:	eb 10                	jmp    f0103cc6 <vprintfmt+0x388>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0103cb6:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0103cb9:	8d 45 14             	lea    0x14(%ebp),%eax
f0103cbc:	e8 fe fb ff ff       	call   f01038bf <getuint>
			base = 16;
f0103cc1:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103cc6:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f0103cca:	89 74 24 10          	mov    %esi,0x10(%esp)
f0103cce:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0103cd1:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103cd5:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103cd9:	89 04 24             	mov    %eax,(%esp)
f0103cdc:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103ce0:	89 fa                	mov    %edi,%edx
f0103ce2:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ce5:	e8 e6 fa ff ff       	call   f01037d0 <printnum>
			break;
f0103cea:	e9 74 fc ff ff       	jmp    f0103963 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0103cef:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103cf3:	89 04 24             	mov    %eax,(%esp)
f0103cf6:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103cf9:	e9 65 fc ff ff       	jmp    f0103963 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0103cfe:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103d02:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0103d09:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103d0c:	89 f3                	mov    %esi,%ebx
f0103d0e:	eb 03                	jmp    f0103d13 <vprintfmt+0x3d5>
f0103d10:	83 eb 01             	sub    $0x1,%ebx
f0103d13:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0103d17:	75 f7                	jne    f0103d10 <vprintfmt+0x3d2>
f0103d19:	e9 45 fc ff ff       	jmp    f0103963 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f0103d1e:	83 c4 3c             	add    $0x3c,%esp
f0103d21:	5b                   	pop    %ebx
f0103d22:	5e                   	pop    %esi
f0103d23:	5f                   	pop    %edi
f0103d24:	5d                   	pop    %ebp
f0103d25:	c3                   	ret    

f0103d26 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103d26:	55                   	push   %ebp
f0103d27:	89 e5                	mov    %esp,%ebp
f0103d29:	83 ec 28             	sub    $0x28,%esp
f0103d2c:	8b 45 08             	mov    0x8(%ebp),%eax
f0103d2f:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103d32:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103d35:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103d39:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103d3c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103d43:	85 c0                	test   %eax,%eax
f0103d45:	74 30                	je     f0103d77 <vsnprintf+0x51>
f0103d47:	85 d2                	test   %edx,%edx
f0103d49:	7e 2c                	jle    f0103d77 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103d4b:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d4e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103d52:	8b 45 10             	mov    0x10(%ebp),%eax
f0103d55:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103d59:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103d5c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d60:	c7 04 24 f9 38 10 f0 	movl   $0xf01038f9,(%esp)
f0103d67:	e8 d2 fb ff ff       	call   f010393e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103d6c:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103d6f:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103d72:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103d75:	eb 05                	jmp    f0103d7c <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103d77:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0103d7c:	c9                   	leave  
f0103d7d:	c3                   	ret    

f0103d7e <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103d7e:	55                   	push   %ebp
f0103d7f:	89 e5                	mov    %esp,%ebp
f0103d81:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103d84:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103d87:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103d8b:	8b 45 10             	mov    0x10(%ebp),%eax
f0103d8e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103d92:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103d95:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d99:	8b 45 08             	mov    0x8(%ebp),%eax
f0103d9c:	89 04 24             	mov    %eax,(%esp)
f0103d9f:	e8 82 ff ff ff       	call   f0103d26 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103da4:	c9                   	leave  
f0103da5:	c3                   	ret    
f0103da6:	66 90                	xchg   %ax,%ax
f0103da8:	66 90                	xchg   %ax,%ax
f0103daa:	66 90                	xchg   %ax,%ax
f0103dac:	66 90                	xchg   %ax,%ax
f0103dae:	66 90                	xchg   %ax,%ax

f0103db0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103db0:	55                   	push   %ebp
f0103db1:	89 e5                	mov    %esp,%ebp
f0103db3:	57                   	push   %edi
f0103db4:	56                   	push   %esi
f0103db5:	53                   	push   %ebx
f0103db6:	83 ec 1c             	sub    $0x1c,%esp
f0103db9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103dbc:	85 c0                	test   %eax,%eax
f0103dbe:	74 10                	je     f0103dd0 <readline+0x20>
		cprintf("%s", prompt);
f0103dc0:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103dc4:	c7 04 24 3a 4f 10 f0 	movl   $0xf0104f3a,(%esp)
f0103dcb:	e8 c3 f6 ff ff       	call   f0103493 <cprintf>

	i = 0;
	echoing = iscons(0);
f0103dd0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103dd7:	e8 6c c9 ff ff       	call   f0100748 <iscons>
f0103ddc:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0103dde:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103de3:	e8 4f c9 ff ff       	call   f0100737 <getchar>
f0103de8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0103dea:	85 c0                	test   %eax,%eax
f0103dec:	79 17                	jns    f0103e05 <readline+0x55>
			cprintf("read error: %e\n", c);
f0103dee:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103df2:	c7 04 24 a0 5b 10 f0 	movl   $0xf0105ba0,(%esp)
f0103df9:	e8 95 f6 ff ff       	call   f0103493 <cprintf>
			return NULL;
f0103dfe:	b8 00 00 00 00       	mov    $0x0,%eax
f0103e03:	eb 6d                	jmp    f0103e72 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103e05:	83 f8 7f             	cmp    $0x7f,%eax
f0103e08:	74 05                	je     f0103e0f <readline+0x5f>
f0103e0a:	83 f8 08             	cmp    $0x8,%eax
f0103e0d:	75 19                	jne    f0103e28 <readline+0x78>
f0103e0f:	85 f6                	test   %esi,%esi
f0103e11:	7e 15                	jle    f0103e28 <readline+0x78>
			if (echoing)
f0103e13:	85 ff                	test   %edi,%edi
f0103e15:	74 0c                	je     f0103e23 <readline+0x73>
				cputchar('\b');
f0103e17:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f0103e1e:	e8 04 c9 ff ff       	call   f0100727 <cputchar>
			i--;
f0103e23:	83 ee 01             	sub    $0x1,%esi
f0103e26:	eb bb                	jmp    f0103de3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103e28:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103e2e:	7f 1c                	jg     f0103e4c <readline+0x9c>
f0103e30:	83 fb 1f             	cmp    $0x1f,%ebx
f0103e33:	7e 17                	jle    f0103e4c <readline+0x9c>
			if (echoing)
f0103e35:	85 ff                	test   %edi,%edi
f0103e37:	74 08                	je     f0103e41 <readline+0x91>
				cputchar(c);
f0103e39:	89 1c 24             	mov    %ebx,(%esp)
f0103e3c:	e8 e6 c8 ff ff       	call   f0100727 <cputchar>
			buf[i++] = c;
f0103e41:	88 9e 60 95 11 f0    	mov    %bl,-0xfee6aa0(%esi)
f0103e47:	8d 76 01             	lea    0x1(%esi),%esi
f0103e4a:	eb 97                	jmp    f0103de3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f0103e4c:	83 fb 0d             	cmp    $0xd,%ebx
f0103e4f:	74 05                	je     f0103e56 <readline+0xa6>
f0103e51:	83 fb 0a             	cmp    $0xa,%ebx
f0103e54:	75 8d                	jne    f0103de3 <readline+0x33>
			if (echoing)
f0103e56:	85 ff                	test   %edi,%edi
f0103e58:	74 0c                	je     f0103e66 <readline+0xb6>
				cputchar('\n');
f0103e5a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0103e61:	e8 c1 c8 ff ff       	call   f0100727 <cputchar>
			buf[i] = 0;
f0103e66:	c6 86 60 95 11 f0 00 	movb   $0x0,-0xfee6aa0(%esi)
			return buf;
f0103e6d:	b8 60 95 11 f0       	mov    $0xf0119560,%eax
		}
	}
}
f0103e72:	83 c4 1c             	add    $0x1c,%esp
f0103e75:	5b                   	pop    %ebx
f0103e76:	5e                   	pop    %esi
f0103e77:	5f                   	pop    %edi
f0103e78:	5d                   	pop    %ebp
f0103e79:	c3                   	ret    
f0103e7a:	66 90                	xchg   %ax,%ax
f0103e7c:	66 90                	xchg   %ax,%ax
f0103e7e:	66 90                	xchg   %ax,%ax

f0103e80 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103e80:	55                   	push   %ebp
f0103e81:	89 e5                	mov    %esp,%ebp
f0103e83:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103e86:	b8 00 00 00 00       	mov    $0x0,%eax
f0103e8b:	eb 03                	jmp    f0103e90 <strlen+0x10>
		n++;
f0103e8d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103e90:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103e94:	75 f7                	jne    f0103e8d <strlen+0xd>
		n++;
	return n;
}
f0103e96:	5d                   	pop    %ebp
f0103e97:	c3                   	ret    

f0103e98 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103e98:	55                   	push   %ebp
f0103e99:	89 e5                	mov    %esp,%ebp
f0103e9b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103e9e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103ea1:	b8 00 00 00 00       	mov    $0x0,%eax
f0103ea6:	eb 03                	jmp    f0103eab <strnlen+0x13>
		n++;
f0103ea8:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103eab:	39 d0                	cmp    %edx,%eax
f0103ead:	74 06                	je     f0103eb5 <strnlen+0x1d>
f0103eaf:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0103eb3:	75 f3                	jne    f0103ea8 <strnlen+0x10>
		n++;
	return n;
}
f0103eb5:	5d                   	pop    %ebp
f0103eb6:	c3                   	ret    

f0103eb7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103eb7:	55                   	push   %ebp
f0103eb8:	89 e5                	mov    %esp,%ebp
f0103eba:	53                   	push   %ebx
f0103ebb:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ebe:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103ec1:	89 c2                	mov    %eax,%edx
f0103ec3:	83 c2 01             	add    $0x1,%edx
f0103ec6:	83 c1 01             	add    $0x1,%ecx
f0103ec9:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103ecd:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103ed0:	84 db                	test   %bl,%bl
f0103ed2:	75 ef                	jne    f0103ec3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103ed4:	5b                   	pop    %ebx
f0103ed5:	5d                   	pop    %ebp
f0103ed6:	c3                   	ret    

f0103ed7 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103ed7:	55                   	push   %ebp
f0103ed8:	89 e5                	mov    %esp,%ebp
f0103eda:	53                   	push   %ebx
f0103edb:	83 ec 08             	sub    $0x8,%esp
f0103ede:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103ee1:	89 1c 24             	mov    %ebx,(%esp)
f0103ee4:	e8 97 ff ff ff       	call   f0103e80 <strlen>
	strcpy(dst + len, src);
f0103ee9:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103eec:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103ef0:	01 d8                	add    %ebx,%eax
f0103ef2:	89 04 24             	mov    %eax,(%esp)
f0103ef5:	e8 bd ff ff ff       	call   f0103eb7 <strcpy>
	return dst;
}
f0103efa:	89 d8                	mov    %ebx,%eax
f0103efc:	83 c4 08             	add    $0x8,%esp
f0103eff:	5b                   	pop    %ebx
f0103f00:	5d                   	pop    %ebp
f0103f01:	c3                   	ret    

f0103f02 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103f02:	55                   	push   %ebp
f0103f03:	89 e5                	mov    %esp,%ebp
f0103f05:	56                   	push   %esi
f0103f06:	53                   	push   %ebx
f0103f07:	8b 75 08             	mov    0x8(%ebp),%esi
f0103f0a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103f0d:	89 f3                	mov    %esi,%ebx
f0103f0f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103f12:	89 f2                	mov    %esi,%edx
f0103f14:	eb 0f                	jmp    f0103f25 <strncpy+0x23>
		*dst++ = *src;
f0103f16:	83 c2 01             	add    $0x1,%edx
f0103f19:	0f b6 01             	movzbl (%ecx),%eax
f0103f1c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103f1f:	80 39 01             	cmpb   $0x1,(%ecx)
f0103f22:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103f25:	39 da                	cmp    %ebx,%edx
f0103f27:	75 ed                	jne    f0103f16 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103f29:	89 f0                	mov    %esi,%eax
f0103f2b:	5b                   	pop    %ebx
f0103f2c:	5e                   	pop    %esi
f0103f2d:	5d                   	pop    %ebp
f0103f2e:	c3                   	ret    

f0103f2f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103f2f:	55                   	push   %ebp
f0103f30:	89 e5                	mov    %esp,%ebp
f0103f32:	56                   	push   %esi
f0103f33:	53                   	push   %ebx
f0103f34:	8b 75 08             	mov    0x8(%ebp),%esi
f0103f37:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103f3a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103f3d:	89 f0                	mov    %esi,%eax
f0103f3f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103f43:	85 c9                	test   %ecx,%ecx
f0103f45:	75 0b                	jne    f0103f52 <strlcpy+0x23>
f0103f47:	eb 1d                	jmp    f0103f66 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103f49:	83 c0 01             	add    $0x1,%eax
f0103f4c:	83 c2 01             	add    $0x1,%edx
f0103f4f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103f52:	39 d8                	cmp    %ebx,%eax
f0103f54:	74 0b                	je     f0103f61 <strlcpy+0x32>
f0103f56:	0f b6 0a             	movzbl (%edx),%ecx
f0103f59:	84 c9                	test   %cl,%cl
f0103f5b:	75 ec                	jne    f0103f49 <strlcpy+0x1a>
f0103f5d:	89 c2                	mov    %eax,%edx
f0103f5f:	eb 02                	jmp    f0103f63 <strlcpy+0x34>
f0103f61:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f0103f63:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0103f66:	29 f0                	sub    %esi,%eax
}
f0103f68:	5b                   	pop    %ebx
f0103f69:	5e                   	pop    %esi
f0103f6a:	5d                   	pop    %ebp
f0103f6b:	c3                   	ret    

f0103f6c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103f6c:	55                   	push   %ebp
f0103f6d:	89 e5                	mov    %esp,%ebp
f0103f6f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103f72:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103f75:	eb 06                	jmp    f0103f7d <strcmp+0x11>
		p++, q++;
f0103f77:	83 c1 01             	add    $0x1,%ecx
f0103f7a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103f7d:	0f b6 01             	movzbl (%ecx),%eax
f0103f80:	84 c0                	test   %al,%al
f0103f82:	74 04                	je     f0103f88 <strcmp+0x1c>
f0103f84:	3a 02                	cmp    (%edx),%al
f0103f86:	74 ef                	je     f0103f77 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103f88:	0f b6 c0             	movzbl %al,%eax
f0103f8b:	0f b6 12             	movzbl (%edx),%edx
f0103f8e:	29 d0                	sub    %edx,%eax
}
f0103f90:	5d                   	pop    %ebp
f0103f91:	c3                   	ret    

f0103f92 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103f92:	55                   	push   %ebp
f0103f93:	89 e5                	mov    %esp,%ebp
f0103f95:	53                   	push   %ebx
f0103f96:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f99:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103f9c:	89 c3                	mov    %eax,%ebx
f0103f9e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103fa1:	eb 06                	jmp    f0103fa9 <strncmp+0x17>
		n--, p++, q++;
f0103fa3:	83 c0 01             	add    $0x1,%eax
f0103fa6:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103fa9:	39 d8                	cmp    %ebx,%eax
f0103fab:	74 15                	je     f0103fc2 <strncmp+0x30>
f0103fad:	0f b6 08             	movzbl (%eax),%ecx
f0103fb0:	84 c9                	test   %cl,%cl
f0103fb2:	74 04                	je     f0103fb8 <strncmp+0x26>
f0103fb4:	3a 0a                	cmp    (%edx),%cl
f0103fb6:	74 eb                	je     f0103fa3 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103fb8:	0f b6 00             	movzbl (%eax),%eax
f0103fbb:	0f b6 12             	movzbl (%edx),%edx
f0103fbe:	29 d0                	sub    %edx,%eax
f0103fc0:	eb 05                	jmp    f0103fc7 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103fc2:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103fc7:	5b                   	pop    %ebx
f0103fc8:	5d                   	pop    %ebp
f0103fc9:	c3                   	ret    

f0103fca <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103fca:	55                   	push   %ebp
f0103fcb:	89 e5                	mov    %esp,%ebp
f0103fcd:	8b 45 08             	mov    0x8(%ebp),%eax
f0103fd0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103fd4:	eb 07                	jmp    f0103fdd <strchr+0x13>
		if (*s == c)
f0103fd6:	38 ca                	cmp    %cl,%dl
f0103fd8:	74 0f                	je     f0103fe9 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103fda:	83 c0 01             	add    $0x1,%eax
f0103fdd:	0f b6 10             	movzbl (%eax),%edx
f0103fe0:	84 d2                	test   %dl,%dl
f0103fe2:	75 f2                	jne    f0103fd6 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0103fe4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103fe9:	5d                   	pop    %ebp
f0103fea:	c3                   	ret    

f0103feb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103feb:	55                   	push   %ebp
f0103fec:	89 e5                	mov    %esp,%ebp
f0103fee:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ff1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103ff5:	eb 07                	jmp    f0103ffe <strfind+0x13>
		if (*s == c)
f0103ff7:	38 ca                	cmp    %cl,%dl
f0103ff9:	74 0a                	je     f0104005 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0103ffb:	83 c0 01             	add    $0x1,%eax
f0103ffe:	0f b6 10             	movzbl (%eax),%edx
f0104001:	84 d2                	test   %dl,%dl
f0104003:	75 f2                	jne    f0103ff7 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0104005:	5d                   	pop    %ebp
f0104006:	c3                   	ret    

f0104007 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104007:	55                   	push   %ebp
f0104008:	89 e5                	mov    %esp,%ebp
f010400a:	57                   	push   %edi
f010400b:	56                   	push   %esi
f010400c:	53                   	push   %ebx
f010400d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104010:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104013:	85 c9                	test   %ecx,%ecx
f0104015:	74 36                	je     f010404d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104017:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010401d:	75 28                	jne    f0104047 <memset+0x40>
f010401f:	f6 c1 03             	test   $0x3,%cl
f0104022:	75 23                	jne    f0104047 <memset+0x40>
		c &= 0xFF;
f0104024:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104028:	89 d3                	mov    %edx,%ebx
f010402a:	c1 e3 08             	shl    $0x8,%ebx
f010402d:	89 d6                	mov    %edx,%esi
f010402f:	c1 e6 18             	shl    $0x18,%esi
f0104032:	89 d0                	mov    %edx,%eax
f0104034:	c1 e0 10             	shl    $0x10,%eax
f0104037:	09 f0                	or     %esi,%eax
f0104039:	09 c2                	or     %eax,%edx
f010403b:	89 d0                	mov    %edx,%eax
f010403d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f010403f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0104042:	fc                   	cld    
f0104043:	f3 ab                	rep stos %eax,%es:(%edi)
f0104045:	eb 06                	jmp    f010404d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104047:	8b 45 0c             	mov    0xc(%ebp),%eax
f010404a:	fc                   	cld    
f010404b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010404d:	89 f8                	mov    %edi,%eax
f010404f:	5b                   	pop    %ebx
f0104050:	5e                   	pop    %esi
f0104051:	5f                   	pop    %edi
f0104052:	5d                   	pop    %ebp
f0104053:	c3                   	ret    

f0104054 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104054:	55                   	push   %ebp
f0104055:	89 e5                	mov    %esp,%ebp
f0104057:	57                   	push   %edi
f0104058:	56                   	push   %esi
f0104059:	8b 45 08             	mov    0x8(%ebp),%eax
f010405c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010405f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104062:	39 c6                	cmp    %eax,%esi
f0104064:	73 35                	jae    f010409b <memmove+0x47>
f0104066:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104069:	39 d0                	cmp    %edx,%eax
f010406b:	73 2e                	jae    f010409b <memmove+0x47>
		s += n;
		d += n;
f010406d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0104070:	89 d6                	mov    %edx,%esi
f0104072:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104074:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010407a:	75 13                	jne    f010408f <memmove+0x3b>
f010407c:	f6 c1 03             	test   $0x3,%cl
f010407f:	75 0e                	jne    f010408f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0104081:	83 ef 04             	sub    $0x4,%edi
f0104084:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104087:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010408a:	fd                   	std    
f010408b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010408d:	eb 09                	jmp    f0104098 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010408f:	83 ef 01             	sub    $0x1,%edi
f0104092:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0104095:	fd                   	std    
f0104096:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104098:	fc                   	cld    
f0104099:	eb 1d                	jmp    f01040b8 <memmove+0x64>
f010409b:	89 f2                	mov    %esi,%edx
f010409d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010409f:	f6 c2 03             	test   $0x3,%dl
f01040a2:	75 0f                	jne    f01040b3 <memmove+0x5f>
f01040a4:	f6 c1 03             	test   $0x3,%cl
f01040a7:	75 0a                	jne    f01040b3 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01040a9:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01040ac:	89 c7                	mov    %eax,%edi
f01040ae:	fc                   	cld    
f01040af:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01040b1:	eb 05                	jmp    f01040b8 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01040b3:	89 c7                	mov    %eax,%edi
f01040b5:	fc                   	cld    
f01040b6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01040b8:	5e                   	pop    %esi
f01040b9:	5f                   	pop    %edi
f01040ba:	5d                   	pop    %ebp
f01040bb:	c3                   	ret    

f01040bc <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01040bc:	55                   	push   %ebp
f01040bd:	89 e5                	mov    %esp,%ebp
f01040bf:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f01040c2:	8b 45 10             	mov    0x10(%ebp),%eax
f01040c5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01040c9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01040cc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01040d0:	8b 45 08             	mov    0x8(%ebp),%eax
f01040d3:	89 04 24             	mov    %eax,(%esp)
f01040d6:	e8 79 ff ff ff       	call   f0104054 <memmove>
}
f01040db:	c9                   	leave  
f01040dc:	c3                   	ret    

f01040dd <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01040dd:	55                   	push   %ebp
f01040de:	89 e5                	mov    %esp,%ebp
f01040e0:	56                   	push   %esi
f01040e1:	53                   	push   %ebx
f01040e2:	8b 55 08             	mov    0x8(%ebp),%edx
f01040e5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01040e8:	89 d6                	mov    %edx,%esi
f01040ea:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01040ed:	eb 1a                	jmp    f0104109 <memcmp+0x2c>
		if (*s1 != *s2)
f01040ef:	0f b6 02             	movzbl (%edx),%eax
f01040f2:	0f b6 19             	movzbl (%ecx),%ebx
f01040f5:	38 d8                	cmp    %bl,%al
f01040f7:	74 0a                	je     f0104103 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01040f9:	0f b6 c0             	movzbl %al,%eax
f01040fc:	0f b6 db             	movzbl %bl,%ebx
f01040ff:	29 d8                	sub    %ebx,%eax
f0104101:	eb 0f                	jmp    f0104112 <memcmp+0x35>
		s1++, s2++;
f0104103:	83 c2 01             	add    $0x1,%edx
f0104106:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104109:	39 f2                	cmp    %esi,%edx
f010410b:	75 e2                	jne    f01040ef <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010410d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104112:	5b                   	pop    %ebx
f0104113:	5e                   	pop    %esi
f0104114:	5d                   	pop    %ebp
f0104115:	c3                   	ret    

f0104116 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104116:	55                   	push   %ebp
f0104117:	89 e5                	mov    %esp,%ebp
f0104119:	8b 45 08             	mov    0x8(%ebp),%eax
f010411c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010411f:	89 c2                	mov    %eax,%edx
f0104121:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0104124:	eb 07                	jmp    f010412d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104126:	38 08                	cmp    %cl,(%eax)
f0104128:	74 07                	je     f0104131 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010412a:	83 c0 01             	add    $0x1,%eax
f010412d:	39 d0                	cmp    %edx,%eax
f010412f:	72 f5                	jb     f0104126 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0104131:	5d                   	pop    %ebp
f0104132:	c3                   	ret    

f0104133 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104133:	55                   	push   %ebp
f0104134:	89 e5                	mov    %esp,%ebp
f0104136:	57                   	push   %edi
f0104137:	56                   	push   %esi
f0104138:	53                   	push   %ebx
f0104139:	8b 55 08             	mov    0x8(%ebp),%edx
f010413c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010413f:	eb 03                	jmp    f0104144 <strtol+0x11>
		s++;
f0104141:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104144:	0f b6 0a             	movzbl (%edx),%ecx
f0104147:	80 f9 09             	cmp    $0x9,%cl
f010414a:	74 f5                	je     f0104141 <strtol+0xe>
f010414c:	80 f9 20             	cmp    $0x20,%cl
f010414f:	74 f0                	je     f0104141 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0104151:	80 f9 2b             	cmp    $0x2b,%cl
f0104154:	75 0a                	jne    f0104160 <strtol+0x2d>
		s++;
f0104156:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0104159:	bf 00 00 00 00       	mov    $0x0,%edi
f010415e:	eb 11                	jmp    f0104171 <strtol+0x3e>
f0104160:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0104165:	80 f9 2d             	cmp    $0x2d,%cl
f0104168:	75 07                	jne    f0104171 <strtol+0x3e>
		s++, neg = 1;
f010416a:	8d 52 01             	lea    0x1(%edx),%edx
f010416d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104171:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0104176:	75 15                	jne    f010418d <strtol+0x5a>
f0104178:	80 3a 30             	cmpb   $0x30,(%edx)
f010417b:	75 10                	jne    f010418d <strtol+0x5a>
f010417d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0104181:	75 0a                	jne    f010418d <strtol+0x5a>
		s += 2, base = 16;
f0104183:	83 c2 02             	add    $0x2,%edx
f0104186:	b8 10 00 00 00       	mov    $0x10,%eax
f010418b:	eb 10                	jmp    f010419d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f010418d:	85 c0                	test   %eax,%eax
f010418f:	75 0c                	jne    f010419d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104191:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104193:	80 3a 30             	cmpb   $0x30,(%edx)
f0104196:	75 05                	jne    f010419d <strtol+0x6a>
		s++, base = 8;
f0104198:	83 c2 01             	add    $0x1,%edx
f010419b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f010419d:	bb 00 00 00 00       	mov    $0x0,%ebx
f01041a2:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01041a5:	0f b6 0a             	movzbl (%edx),%ecx
f01041a8:	8d 71 d0             	lea    -0x30(%ecx),%esi
f01041ab:	89 f0                	mov    %esi,%eax
f01041ad:	3c 09                	cmp    $0x9,%al
f01041af:	77 08                	ja     f01041b9 <strtol+0x86>
			dig = *s - '0';
f01041b1:	0f be c9             	movsbl %cl,%ecx
f01041b4:	83 e9 30             	sub    $0x30,%ecx
f01041b7:	eb 20                	jmp    f01041d9 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f01041b9:	8d 71 9f             	lea    -0x61(%ecx),%esi
f01041bc:	89 f0                	mov    %esi,%eax
f01041be:	3c 19                	cmp    $0x19,%al
f01041c0:	77 08                	ja     f01041ca <strtol+0x97>
			dig = *s - 'a' + 10;
f01041c2:	0f be c9             	movsbl %cl,%ecx
f01041c5:	83 e9 57             	sub    $0x57,%ecx
f01041c8:	eb 0f                	jmp    f01041d9 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f01041ca:	8d 71 bf             	lea    -0x41(%ecx),%esi
f01041cd:	89 f0                	mov    %esi,%eax
f01041cf:	3c 19                	cmp    $0x19,%al
f01041d1:	77 16                	ja     f01041e9 <strtol+0xb6>
			dig = *s - 'A' + 10;
f01041d3:	0f be c9             	movsbl %cl,%ecx
f01041d6:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f01041d9:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f01041dc:	7d 0f                	jge    f01041ed <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f01041de:	83 c2 01             	add    $0x1,%edx
f01041e1:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f01041e5:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f01041e7:	eb bc                	jmp    f01041a5 <strtol+0x72>
f01041e9:	89 d8                	mov    %ebx,%eax
f01041eb:	eb 02                	jmp    f01041ef <strtol+0xbc>
f01041ed:	89 d8                	mov    %ebx,%eax

	if (endptr)
f01041ef:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01041f3:	74 05                	je     f01041fa <strtol+0xc7>
		*endptr = (char *) s;
f01041f5:	8b 75 0c             	mov    0xc(%ebp),%esi
f01041f8:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f01041fa:	f7 d8                	neg    %eax
f01041fc:	85 ff                	test   %edi,%edi
f01041fe:	0f 44 c3             	cmove  %ebx,%eax
}
f0104201:	5b                   	pop    %ebx
f0104202:	5e                   	pop    %esi
f0104203:	5f                   	pop    %edi
f0104204:	5d                   	pop    %ebp
f0104205:	c3                   	ret    
f0104206:	66 90                	xchg   %ax,%ax
f0104208:	66 90                	xchg   %ax,%ax
f010420a:	66 90                	xchg   %ax,%ax
f010420c:	66 90                	xchg   %ax,%ax
f010420e:	66 90                	xchg   %ax,%ax

f0104210 <__udivdi3>:
f0104210:	55                   	push   %ebp
f0104211:	57                   	push   %edi
f0104212:	56                   	push   %esi
f0104213:	83 ec 0c             	sub    $0xc,%esp
f0104216:	8b 44 24 28          	mov    0x28(%esp),%eax
f010421a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f010421e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0104222:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0104226:	85 c0                	test   %eax,%eax
f0104228:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010422c:	89 ea                	mov    %ebp,%edx
f010422e:	89 0c 24             	mov    %ecx,(%esp)
f0104231:	75 2d                	jne    f0104260 <__udivdi3+0x50>
f0104233:	39 e9                	cmp    %ebp,%ecx
f0104235:	77 61                	ja     f0104298 <__udivdi3+0x88>
f0104237:	85 c9                	test   %ecx,%ecx
f0104239:	89 ce                	mov    %ecx,%esi
f010423b:	75 0b                	jne    f0104248 <__udivdi3+0x38>
f010423d:	b8 01 00 00 00       	mov    $0x1,%eax
f0104242:	31 d2                	xor    %edx,%edx
f0104244:	f7 f1                	div    %ecx
f0104246:	89 c6                	mov    %eax,%esi
f0104248:	31 d2                	xor    %edx,%edx
f010424a:	89 e8                	mov    %ebp,%eax
f010424c:	f7 f6                	div    %esi
f010424e:	89 c5                	mov    %eax,%ebp
f0104250:	89 f8                	mov    %edi,%eax
f0104252:	f7 f6                	div    %esi
f0104254:	89 ea                	mov    %ebp,%edx
f0104256:	83 c4 0c             	add    $0xc,%esp
f0104259:	5e                   	pop    %esi
f010425a:	5f                   	pop    %edi
f010425b:	5d                   	pop    %ebp
f010425c:	c3                   	ret    
f010425d:	8d 76 00             	lea    0x0(%esi),%esi
f0104260:	39 e8                	cmp    %ebp,%eax
f0104262:	77 24                	ja     f0104288 <__udivdi3+0x78>
f0104264:	0f bd e8             	bsr    %eax,%ebp
f0104267:	83 f5 1f             	xor    $0x1f,%ebp
f010426a:	75 3c                	jne    f01042a8 <__udivdi3+0x98>
f010426c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0104270:	39 34 24             	cmp    %esi,(%esp)
f0104273:	0f 86 9f 00 00 00    	jbe    f0104318 <__udivdi3+0x108>
f0104279:	39 d0                	cmp    %edx,%eax
f010427b:	0f 82 97 00 00 00    	jb     f0104318 <__udivdi3+0x108>
f0104281:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104288:	31 d2                	xor    %edx,%edx
f010428a:	31 c0                	xor    %eax,%eax
f010428c:	83 c4 0c             	add    $0xc,%esp
f010428f:	5e                   	pop    %esi
f0104290:	5f                   	pop    %edi
f0104291:	5d                   	pop    %ebp
f0104292:	c3                   	ret    
f0104293:	90                   	nop
f0104294:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104298:	89 f8                	mov    %edi,%eax
f010429a:	f7 f1                	div    %ecx
f010429c:	31 d2                	xor    %edx,%edx
f010429e:	83 c4 0c             	add    $0xc,%esp
f01042a1:	5e                   	pop    %esi
f01042a2:	5f                   	pop    %edi
f01042a3:	5d                   	pop    %ebp
f01042a4:	c3                   	ret    
f01042a5:	8d 76 00             	lea    0x0(%esi),%esi
f01042a8:	89 e9                	mov    %ebp,%ecx
f01042aa:	8b 3c 24             	mov    (%esp),%edi
f01042ad:	d3 e0                	shl    %cl,%eax
f01042af:	89 c6                	mov    %eax,%esi
f01042b1:	b8 20 00 00 00       	mov    $0x20,%eax
f01042b6:	29 e8                	sub    %ebp,%eax
f01042b8:	89 c1                	mov    %eax,%ecx
f01042ba:	d3 ef                	shr    %cl,%edi
f01042bc:	89 e9                	mov    %ebp,%ecx
f01042be:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01042c2:	8b 3c 24             	mov    (%esp),%edi
f01042c5:	09 74 24 08          	or     %esi,0x8(%esp)
f01042c9:	89 d6                	mov    %edx,%esi
f01042cb:	d3 e7                	shl    %cl,%edi
f01042cd:	89 c1                	mov    %eax,%ecx
f01042cf:	89 3c 24             	mov    %edi,(%esp)
f01042d2:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01042d6:	d3 ee                	shr    %cl,%esi
f01042d8:	89 e9                	mov    %ebp,%ecx
f01042da:	d3 e2                	shl    %cl,%edx
f01042dc:	89 c1                	mov    %eax,%ecx
f01042de:	d3 ef                	shr    %cl,%edi
f01042e0:	09 d7                	or     %edx,%edi
f01042e2:	89 f2                	mov    %esi,%edx
f01042e4:	89 f8                	mov    %edi,%eax
f01042e6:	f7 74 24 08          	divl   0x8(%esp)
f01042ea:	89 d6                	mov    %edx,%esi
f01042ec:	89 c7                	mov    %eax,%edi
f01042ee:	f7 24 24             	mull   (%esp)
f01042f1:	39 d6                	cmp    %edx,%esi
f01042f3:	89 14 24             	mov    %edx,(%esp)
f01042f6:	72 30                	jb     f0104328 <__udivdi3+0x118>
f01042f8:	8b 54 24 04          	mov    0x4(%esp),%edx
f01042fc:	89 e9                	mov    %ebp,%ecx
f01042fe:	d3 e2                	shl    %cl,%edx
f0104300:	39 c2                	cmp    %eax,%edx
f0104302:	73 05                	jae    f0104309 <__udivdi3+0xf9>
f0104304:	3b 34 24             	cmp    (%esp),%esi
f0104307:	74 1f                	je     f0104328 <__udivdi3+0x118>
f0104309:	89 f8                	mov    %edi,%eax
f010430b:	31 d2                	xor    %edx,%edx
f010430d:	e9 7a ff ff ff       	jmp    f010428c <__udivdi3+0x7c>
f0104312:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104318:	31 d2                	xor    %edx,%edx
f010431a:	b8 01 00 00 00       	mov    $0x1,%eax
f010431f:	e9 68 ff ff ff       	jmp    f010428c <__udivdi3+0x7c>
f0104324:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104328:	8d 47 ff             	lea    -0x1(%edi),%eax
f010432b:	31 d2                	xor    %edx,%edx
f010432d:	83 c4 0c             	add    $0xc,%esp
f0104330:	5e                   	pop    %esi
f0104331:	5f                   	pop    %edi
f0104332:	5d                   	pop    %ebp
f0104333:	c3                   	ret    
f0104334:	66 90                	xchg   %ax,%ax
f0104336:	66 90                	xchg   %ax,%ax
f0104338:	66 90                	xchg   %ax,%ax
f010433a:	66 90                	xchg   %ax,%ax
f010433c:	66 90                	xchg   %ax,%ax
f010433e:	66 90                	xchg   %ax,%ax

f0104340 <__umoddi3>:
f0104340:	55                   	push   %ebp
f0104341:	57                   	push   %edi
f0104342:	56                   	push   %esi
f0104343:	83 ec 14             	sub    $0x14,%esp
f0104346:	8b 44 24 28          	mov    0x28(%esp),%eax
f010434a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f010434e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0104352:	89 c7                	mov    %eax,%edi
f0104354:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104358:	8b 44 24 30          	mov    0x30(%esp),%eax
f010435c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0104360:	89 34 24             	mov    %esi,(%esp)
f0104363:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104367:	85 c0                	test   %eax,%eax
f0104369:	89 c2                	mov    %eax,%edx
f010436b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010436f:	75 17                	jne    f0104388 <__umoddi3+0x48>
f0104371:	39 fe                	cmp    %edi,%esi
f0104373:	76 4b                	jbe    f01043c0 <__umoddi3+0x80>
f0104375:	89 c8                	mov    %ecx,%eax
f0104377:	89 fa                	mov    %edi,%edx
f0104379:	f7 f6                	div    %esi
f010437b:	89 d0                	mov    %edx,%eax
f010437d:	31 d2                	xor    %edx,%edx
f010437f:	83 c4 14             	add    $0x14,%esp
f0104382:	5e                   	pop    %esi
f0104383:	5f                   	pop    %edi
f0104384:	5d                   	pop    %ebp
f0104385:	c3                   	ret    
f0104386:	66 90                	xchg   %ax,%ax
f0104388:	39 f8                	cmp    %edi,%eax
f010438a:	77 54                	ja     f01043e0 <__umoddi3+0xa0>
f010438c:	0f bd e8             	bsr    %eax,%ebp
f010438f:	83 f5 1f             	xor    $0x1f,%ebp
f0104392:	75 5c                	jne    f01043f0 <__umoddi3+0xb0>
f0104394:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0104398:	39 3c 24             	cmp    %edi,(%esp)
f010439b:	0f 87 e7 00 00 00    	ja     f0104488 <__umoddi3+0x148>
f01043a1:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01043a5:	29 f1                	sub    %esi,%ecx
f01043a7:	19 c7                	sbb    %eax,%edi
f01043a9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01043ad:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01043b1:	8b 44 24 08          	mov    0x8(%esp),%eax
f01043b5:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01043b9:	83 c4 14             	add    $0x14,%esp
f01043bc:	5e                   	pop    %esi
f01043bd:	5f                   	pop    %edi
f01043be:	5d                   	pop    %ebp
f01043bf:	c3                   	ret    
f01043c0:	85 f6                	test   %esi,%esi
f01043c2:	89 f5                	mov    %esi,%ebp
f01043c4:	75 0b                	jne    f01043d1 <__umoddi3+0x91>
f01043c6:	b8 01 00 00 00       	mov    $0x1,%eax
f01043cb:	31 d2                	xor    %edx,%edx
f01043cd:	f7 f6                	div    %esi
f01043cf:	89 c5                	mov    %eax,%ebp
f01043d1:	8b 44 24 04          	mov    0x4(%esp),%eax
f01043d5:	31 d2                	xor    %edx,%edx
f01043d7:	f7 f5                	div    %ebp
f01043d9:	89 c8                	mov    %ecx,%eax
f01043db:	f7 f5                	div    %ebp
f01043dd:	eb 9c                	jmp    f010437b <__umoddi3+0x3b>
f01043df:	90                   	nop
f01043e0:	89 c8                	mov    %ecx,%eax
f01043e2:	89 fa                	mov    %edi,%edx
f01043e4:	83 c4 14             	add    $0x14,%esp
f01043e7:	5e                   	pop    %esi
f01043e8:	5f                   	pop    %edi
f01043e9:	5d                   	pop    %ebp
f01043ea:	c3                   	ret    
f01043eb:	90                   	nop
f01043ec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01043f0:	8b 04 24             	mov    (%esp),%eax
f01043f3:	be 20 00 00 00       	mov    $0x20,%esi
f01043f8:	89 e9                	mov    %ebp,%ecx
f01043fa:	29 ee                	sub    %ebp,%esi
f01043fc:	d3 e2                	shl    %cl,%edx
f01043fe:	89 f1                	mov    %esi,%ecx
f0104400:	d3 e8                	shr    %cl,%eax
f0104402:	89 e9                	mov    %ebp,%ecx
f0104404:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104408:	8b 04 24             	mov    (%esp),%eax
f010440b:	09 54 24 04          	or     %edx,0x4(%esp)
f010440f:	89 fa                	mov    %edi,%edx
f0104411:	d3 e0                	shl    %cl,%eax
f0104413:	89 f1                	mov    %esi,%ecx
f0104415:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104419:	8b 44 24 10          	mov    0x10(%esp),%eax
f010441d:	d3 ea                	shr    %cl,%edx
f010441f:	89 e9                	mov    %ebp,%ecx
f0104421:	d3 e7                	shl    %cl,%edi
f0104423:	89 f1                	mov    %esi,%ecx
f0104425:	d3 e8                	shr    %cl,%eax
f0104427:	89 e9                	mov    %ebp,%ecx
f0104429:	09 f8                	or     %edi,%eax
f010442b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f010442f:	f7 74 24 04          	divl   0x4(%esp)
f0104433:	d3 e7                	shl    %cl,%edi
f0104435:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0104439:	89 d7                	mov    %edx,%edi
f010443b:	f7 64 24 08          	mull   0x8(%esp)
f010443f:	39 d7                	cmp    %edx,%edi
f0104441:	89 c1                	mov    %eax,%ecx
f0104443:	89 14 24             	mov    %edx,(%esp)
f0104446:	72 2c                	jb     f0104474 <__umoddi3+0x134>
f0104448:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f010444c:	72 22                	jb     f0104470 <__umoddi3+0x130>
f010444e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0104452:	29 c8                	sub    %ecx,%eax
f0104454:	19 d7                	sbb    %edx,%edi
f0104456:	89 e9                	mov    %ebp,%ecx
f0104458:	89 fa                	mov    %edi,%edx
f010445a:	d3 e8                	shr    %cl,%eax
f010445c:	89 f1                	mov    %esi,%ecx
f010445e:	d3 e2                	shl    %cl,%edx
f0104460:	89 e9                	mov    %ebp,%ecx
f0104462:	d3 ef                	shr    %cl,%edi
f0104464:	09 d0                	or     %edx,%eax
f0104466:	89 fa                	mov    %edi,%edx
f0104468:	83 c4 14             	add    $0x14,%esp
f010446b:	5e                   	pop    %esi
f010446c:	5f                   	pop    %edi
f010446d:	5d                   	pop    %ebp
f010446e:	c3                   	ret    
f010446f:	90                   	nop
f0104470:	39 d7                	cmp    %edx,%edi
f0104472:	75 da                	jne    f010444e <__umoddi3+0x10e>
f0104474:	8b 14 24             	mov    (%esp),%edx
f0104477:	89 c1                	mov    %eax,%ecx
f0104479:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f010447d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0104481:	eb cb                	jmp    f010444e <__umoddi3+0x10e>
f0104483:	90                   	nop
f0104484:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104488:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f010448c:	0f 82 0f ff ff ff    	jb     f01043a1 <__umoddi3+0x61>
f0104492:	e9 1a ff ff ff       	jmp    f01043b1 <__umoddi3+0x71>
