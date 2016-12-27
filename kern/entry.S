/* See COPYRIGHT for copyright information. */

#include <inc/mmu.h>
#include <inc/memlayout.h>
#include <inc/trap.h>

# Shift Right Logical 
#define SRL(val, shamt)		(((val) >> (shamt)) & ~(-1 << (32 - (shamt))))


###################################################################
# The kernel (this code) is linked at address ~(KERNBASE + 1 Meg), 
# but the bootloader loads it at address ~1 Meg.
#	
# RELOC(x) maps a symbol x from its link address to its actual
# location in physical memory (its load address).	 
###################################################################

#define	RELOC(x) ((x) - KERNBASE)

#define MULTIBOOT_HEADER_MAGIC (0x1BADB002)
#define MULTIBOOT_HEADER_FLAGS (0)
#define CHECKSUM (-(MULTIBOOT_HEADER_MAGIC + MULTIBOOT_HEADER_FLAGS))

###################################################################
# entry point
###################################################################

.text

# The Multiboot header
.align 4
.long MULTIBOOT_HEADER_MAGIC
.long MULTIBOOT_HEADER_FLAGS
.long CHECKSUM

# '_start' specifies the ELF entry point.  Since we haven't set up
# virtual memory when the bootloader enters this code, we need the
# bootloader to jump to the *physical* address of the entry point.
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot

	# We haven't set up virtual memory yet, so we're running from
	# the physical address the boot loader loaded the kernel at: 1MB
	# (plus a few bytes).  However, the C code is linked to run at
	# KERNBASE+1MB.  Hence, we set up a trivial page directory that
	# translates virtual addresses [KERNBASE, KERNBASE+4MB) to
	# physical addresses [0, 4MB).  This 4MB region will be
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# 注意到内核代码的执行是从KERNBASE+1MB开始的，而不是KERNBASE!!!
	# 由于虚拟内存机制还没建立，所以在kern/entrypgdir.c里面手写了4MB的页表，
	# 把[0,4MB)物理地址同时映射到线性地址[0, 4MB)和[KERNBASE, KERNBASE+4MB)中
	
	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	# 此时还没开启分页，需要RELOC将线性地址转化为物理地址
	movl	$(RELOC(entry_pgdir)), %eax
	movl	%eax, %cr3
	# Turn on paging.
	movl	%cr0, %eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
	movl	%eax, %cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	# 线性地址[0, 4MB)和[KERNBASE, KERNBASE+4MB)同时映射到[0,4MB)物理地址
	# 如果不映射线性地址[0, 4MB)，则low eip的线性地址不在可访问线性地址范围内，将出现非法访问
	mov	$relocated, %eax
	jmp	*%eax # jmp 之后eip将会加上KERNBASE !!!
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer

	# 可以看到在这里定义了两个全局变量 bootstack 和 bootstacktop， bootstack 标识了内存中
	# 的一个位置，表示从这里开始的 KSTKSIZE 个字节的区域都是属于这个临时堆栈的
	# (KSTKSIZE 在 inc/memlayout.h 中定义为 32k)，而 bootstacktop 则指向的是这段区域后的第
	# 一个字节，由于刚开始的时候堆栈是空的，所以栈顶便是 bootstacktop 所指向的位置，于是
	# 程序便将 bootstacktop 的值赋给了 esp 寄存器。

	# Set the stack pointer
	movl	$(bootstacktop),%esp

	# now to C code
	call	i386_init

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin


.data
###################################################################
# boot stack
###################################################################
	.p2align	PGSHIFT		# force page alignment
	.globl		bootstack
bootstack:
	.space		KSTKSIZE
	.globl		bootstacktop   
bootstacktop:

