// Simple command-line kernel monitor useful for
// controlling the kernel and exploring the system interactively.

#include <inc/stdio.h>
#include <inc/string.h>
#include <inc/memlayout.h>
#include <inc/assert.h>
#include <inc/x86.h>

#include <kern/console.h>
#include <kern/monitor.h>
#include <kern/kdebug.h>

#define CMDBUF_SIZE	80	// enough for one VGA text line


struct Command {
	const char *name;
	const char *desc;
	// return -1 to force monitor to exit
	int (*func)(int argc, char** argv, struct Trapframe* tf);
};

static struct Command commands[] = {
	{ "help", "Display this list of commands", mon_help },
	{ "kerninfo", "Display information about the kernel", mon_kerninfo },
	{ "setcolor", "Setcolor bg=[black|white|red|green|blue] ch=[black|white|red|green|blue]", mon_setcolor },
	{ "backtrace", "Display the file name and line within that file of the stack frame's eip", mon_backtrace },
};
#define NCOMMANDS (sizeof(commands)/sizeof(commands[0]))

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{ 
	// Your code here.
	uint32_t *ebp, eip;
	uint32_t arg0, arg1, arg2, arg3, arg4;
	ebp = (uint32_t*)read_ebp();
	eip = ebp[1];
	arg0 = ebp[2];
	arg1 = ebp[3];
	arg2 = ebp[4];
	arg3 = ebp[5];
	arg4 = ebp[6]; 
	cprintf("Stack backtrace:\n");
	/*
	当发现 ebp 的值为 0 时便停止循环。
	因为最外层的程序是 kern/entry.S 中的入口程序，记得在之前我们看到过入口程序中有一句
	代码是“ movl $0x0,%ebp”，也就是说在入口程序调用 i386_init 函数之前便把 ebp 的值置
	为 0，也就是说入口程序的 ebp 实际上为 0
	*/
	while(ebp != 0){
		cprintf("ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n",
			ebp,eip,arg0,arg1,arg2,arg3,arg4);
		struct Eipdebuginfo info;

		if(debuginfo_eip(eip, &info) == 0){
			//file name : line
	    	cprintf("\t%s:%d: ", info.eip_file, info.eip_line);
	    	//function name + the offset of the eip from the first instruction of the function
	    	//注意：printf("%.*s", length, string)打印string的至多length个字符
	      	cprintf("%.*s+%d\n", info.eip_fn_namelen, info.eip_fn_name, eip - info.eip_fn_addr);
	    } 

		ebp = (uint32_t*)ebp[0];
		eip = ebp[1];
		arg0 = ebp[2];
		arg1 = ebp[3];
		arg2 = ebp[4];
		arg3 = ebp[5];
		arg4 = ebp[6]; 
	} 
	return 0;
}


/***** 
	setcolor command add by zhuangjian, 2016/07/17 
*****/
char *strstr(const char*s1,const char*s2)
{
    int n;
    if(*s2)
    {
        while(*s1)
        {
            for(n=0;*(s1+n)==*(s2+n);n++)
            {
                if(!*(s2+n+1))
                    return(char*)s1;
            }
            s1++;
        }
        return NULL;
    }
    else
        return (char*)s1;
}

int
mon_setcolor(int argc, char **argv, struct Trapframe *tf)
{ 
	if(argc < 3) {
   	  	cprintf("Make sure the correct style: setcolor bg=[color] ch=[color]\n");
		return 0;
	}	 
	setcolor(strstr(argv[1],"=")+1,strstr(argv[2],"=")+1); 
	return 0;
}



/***** Kernel monitor command interpreter *****/

#define WHITESPACE "\t\r\n "
#define MAXARGS 16

static int
runcmd(char *buf, struct Trapframe *tf)
{
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
		if (*buf == 0)
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
	}
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
	return 0;
}

void
monitor(struct Trapframe *tf)
{
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
