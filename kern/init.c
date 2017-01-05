/* See COPYRIGHT for copyright information. */

#include <inc/stdio.h>
#include <inc/string.h>
#include <inc/assert.h>

#include <kern/monitor.h>
#include <kern/console.h>
#include <kern/pmap.h>
#include <kern/kclock.h>
#include <kern/env.h>
#include <kern/trap.h>
#include <kern/sched.h>
#include <kern/picirq.h>
#include <kern/cpu.h>
#include <kern/spinlock.h>

static void boot_aps(void);


void
i386_init(void)
{
	//see kernel.ld !!!
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	
	/* 
	可以看到两个外部字符数组变量 edata 和 end，其中 edata 表示的是 bss 节起始位置（虚拟地址）,
    而 end 则是表示内核可执行程序结束位置（虚拟地址）。由 2.1 节中对 ELF
	文件的讲解我们可以知道 bss 节是文件在内存中的最后一部分，于是 edata 与 end 之间的部
	分便是 bss 节的部分，我们又知道 bss 节的内容是未初始化的变量，而这些变量是默认为零
	的，所以在一开始的时候程序要用 memset(edata, 0, end - edata)这句代码将这些变量都置为
	零。
	*/

	memset(edata, 0, end - edata);

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
 
	cprintf("6828 decimal is %o octal!\n", 6828);

	// Lab 2 memory management initialization functions
	mem_init();

 
	// Lab 3 user environment initialization functions
	env_init();
	trap_init();

	// Lab 4 multiprocessor initialization functions
	mp_init();//see in mpconfig.c
	lapic_init();

	// Lab 4 multitasking initialization functions
	pic_init();

	// Acquire the big kernel lock before waking up APs
	// Your code here:
	lock_kernel();
	// Starting non-boot CPUs
	boot_aps(); 

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
#else 
	// Touch all you want.  
	//ENV_CREATE(user_primes, ENV_TYPE_USER);
	/* 
	ENV_CREATE_PRIORITY(user_yield, ENV_TYPE_USER, ENV_PRIORITY_HIGH);
	ENV_CREATE_PRIORITY(user_yield, ENV_TYPE_USER, ENV_PRIORITY_1);
	ENV_CREATE_PRIORITY(user_yield, ENV_TYPE_USER, ENV_PRIORITY_2);
	ENV_CREATE_PRIORITY(user_yield, ENV_TYPE_USER, ENV_PRIORITY_3);
	ENV_CREATE_PRIORITY(user_yield, ENV_TYPE_USER, ENV_PRIORITY_4);
	ENV_CREATE_PRIORITY(user_yield, ENV_TYPE_USER, ENV_PRIORITY_5);
	ENV_CREATE_PRIORITY(user_yield, ENV_TYPE_USER, ENV_PRIORITY_LOW);
	ENV_CREATE(user_dumbfork, ENV_TYPE_USER); 
	*/
	ENV_CREATE(user_envpriority, ENV_TYPE_USER);
#endif // TEST*
	// Schedule and run the first user environment!
	sched_yield();
}

// While boot_aps is booting a given CPU, it communicates the per-core
// stack pointer that should be loaded by mpentry.S to that CPU in
// this variable.
void *mpentry_kstack;

// Start the non-boot (AP) processors.
static void
boot_aps(void)
{
	extern unsigned char mpentry_start[], mpentry_end[];
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR); //0x7000
	memmove(code, mpentry_start, mpentry_end - mpentry_start);

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
		//cpunum() see in lapic.c
		if (c == cpus + cpunum())  // We've started already.
			continue;

		// Tell mpentry.S what stack to use 
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE; //used in mpentry.S
		// Start the CPU at mpentry_start
		//cprintf("c->cpu_id=%d\n", c->cpu_id);
		lapic_startap(c->cpu_id, PADDR(code));// cpus has been initialized in mpconfig.c/mp_init()
		// Wait for the CPU to finish some basic setup in mp_main()
		while(c->cpu_status != CPU_STARTED)
			;
	}  
}

// Setup code for APs
void
mp_main(void)
{
	// We are in high EIP now, safe to switch to kern_pgdir 
	lcr3(PADDR(kern_pgdir));
	cprintf("SMP: CPU %d starting\n", cpunum());

	lapic_init();
	env_init_percpu();
	trap_init_percpu();
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up

	// Now that we have finished some basic setup, call sched_yield()
	// to start running processes on this CPU.  But make sure that
	// only one CPU can enter the scheduler at a time!
	//
	// Your code here: 
	lock_kernel();
	sched_yield(); 
	// Remove this after you finish Exercise 4
	//for (;;);
}

/*
 * Variable panicstr contains argument to first call to panic; used as flag
 * to indicate that the kernel has already called panic.
 */
const char *panicstr;

/*
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
	va_list ap;

	if (panicstr)
		goto dead;
	panicstr = fmt;

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");

	va_start(ap, fmt);
	cprintf("kernel panic on CPU %d at %s:%d: ", cpunum(), file, line);
	vcprintf(fmt, ap);
	cprintf("\n");
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
	va_list ap;

	va_start(ap, fmt);
	cprintf("kernel warning at %s:%d: ", file, line);
	vcprintf(fmt, ap);
	cprintf("\n");
	va_end(ap);
}
