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
#include <kern/trap.h>


#include <kern/pmap.h> //e.g. KADDR

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
	{ "showmappings", "Enter 'showmappings 0x3000 0x5000' to display the physical page mappings and corresponding permission bits that apply to the pages at virtual addresses 0x3000, 0x4000, and 0x5000.", mon_showmappings},
	{ "setpermissions", "Enter 'setpermissions 0x3000 [0|1 :clear or set] [P|W|U]' to clear or set the permissions of page mapping at virtual addresses 0x3000.", mon_setpermissions},
	{ "dumpcontents", "Enter 'dumpcontents [p|v :physical or virtual] 0x3000 10' to view 10 4-bytes contents from addr 0x3000.", mon_dumpcontents}
};
#define NCOMMANDS (sizeof(commands)/sizeof(commands[0]))

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%d: %s - %s\n\n",i+1, commands[i].name, commands[i].desc);
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
int jz_atoi(char* pstr) {
    int intVal = 0;              // 返回值
    int sign = 1;                // 符号, 正数为 1, 负数为 -1
    if(pstr == 0) return 0;      // 判断指针是否为空 pstr == NULL
    while(' '== *pstr) pstr++;   // 跳过前面的空格字符 ' ' 的 ascii 值 0x20
    if('-'==*pstr) sign = -1;    // 判断正负号
    if('-'==*pstr || '+'==*pstr) pstr++;// 如果是符号, 指针后移
    while(*pstr >= '0' && *pstr <= '9') {// 逐字符转换成整数
        // 转换说明
        // ascii 的 '0' = 0x30 转换为int以后 - 0x30即为整型的0
        // ascii 的 '1' = 0x31 转换为int以后 - 0x30即为整型的1
        // ...
        intVal = intVal * 10 + (((int)*pstr)-0x30);// 十进制即每位乘10, 结果累加保存
        pstr++;// 指针后移
    }
    return intVal * sign;// 返回结果,int32 范围是: 2147483647 ~ -2147483648, 此处会进行溢出运算
     
}

uint32_t jz_xtoi(char* pstr){
	uint32_t res = 0;
	pstr += 2;//0x...
	while(*pstr){
		if(*pstr >= 'a' && *pstr <= 'z') *pstr = *pstr - 'a' + 10 + '0';
		else if(*pstr >= 'A' && *pstr <= 'Z') *pstr = *pstr - 'A' + 10 + '0';
		res = res*16 + *pstr - '0';
		++pstr;
	}
	return res;
}

char *jz_strstr(const char*s1,const char*s2)
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
	setcolor(jz_strstr(argv[1],"=")+1,jz_strstr(argv[2],"=")+1); 
	return 0;
}

int
mon_showmappings(int argc, char **argv, struct Trapframe *tf)
{ 
	if(argc != 3) {
   	  	cprintf("Make sure the correct style: showmappings 0xbegin_addr 0xend_addr\n");
		return 0;
	}	 
	//将地址字符串转换int，然后判断低12位是不是0
	uint32_t begin = jz_xtoi(argv[1]), end = jz_xtoi(argv[2]);
	if((begin & 0xfff) != 0 || (end & 0xfff) != 0 ){
		cprintf("Make sure the addr's low 12 bits is zero\n");
		return 0;
	}
	cprintf("Attention! You may test addr above UPAGES(0xef000000)\n");
	cprintf("begin:%p, end:%p\n",begin,end);
	pde_t *kpgdir = KADDR(rcr3()), *pde; 
	pte_t *pte, *p;
	uint32_t va;
	for (va = begin; va <= end; va += PGSIZE) 
	{ 
		//or you can use pgdir_walk
		pde = &kpgdir[PDX(va)];
		if (*pde & PTE_P){ 
			pte = (pte_t*) KADDR(PTE_ADDR(*pde)); 
			if (*pte & PTE_P){ 
				p = &pte[PTX(va)];
				cprintf("va: %p, pa: %p, PTE_P: %x, PTE_W: %x, PTE_U: %x\n", 
					va, *p, *p&PTE_P, *p&PTE_W, *p&PTE_U);			
			} else {
				cprintf("page mapping not exist: %x\n", va);
			}
		} else {
			cprintf("page mapping not exist: %x\n", va);
		}
	}
	return 0;
}

int 
mon_setpermissions(int argc, char **argv, struct Trapframe *tf)
{ 
	if(argc != 4) {
   	  	cprintf("Make sure the correct style: setpermissions 0xaddr [0|1 :clear or set] [P|W|U]\n");
		return 0;
	}	 
	//将地址字符串转换int，然后判断低12位是不是0
	uint32_t va = jz_xtoi(argv[1]);
	if((va & 0xfff) != 0 ){
		cprintf("Make sure the addr's low 12 bits is zero\n");
		return 0;
	}

	pte_t *pte = pgdir_walk((pde_t *)KADDR(rcr3()),(void *)va,false);
	if (pte && (*pte & PTE_P)){  
		cprintf("before setpermissions %p\n",va);
		cprintf("va: %p, pa: %p, PTE_P: %x, PTE_W: %x, PTE_U: %x\n", 
			va, *pte, *pte&PTE_P, *pte&PTE_W, *pte&PTE_U);			
		uint32_t perm = 0;
	    if (argv[3][0] == 'P') perm = PTE_P;
	    if (argv[3][0] == 'W') perm = PTE_W;
	    if (argv[3][0] == 'U') perm = PTE_U;
	    if (argv[2][0] == '0')  //clear
	        *pte = *pte & ~perm;
	    else    //set
	        *pte = *pte | perm;
	    cprintf("after setpermissions %p\n",va);
		cprintf("va: %p, pa: %p, PTE_P: %x, PTE_W: %x, PTE_U: %x\n", 
			va, *pte, *pte&PTE_P, *pte&PTE_W, *pte&PTE_U);		
	} else {
		cprintf("page mapping not exist: %x\n", va);
	}
	return 0;
}
 
int 
mon_dumpcontents(int argc, char **argv, struct Trapframe *tf)
{ 
	if(argc != 4) {
   	  	cprintf("Make sure the correct style: dumpcontents [p|v :physical or virtual] 0x3000 10\n");
		return 0;
	}	  
	void** begin = NULL;
	long length = strtol(argv[3],0,0);
	uint32_t i; 
 	if (argv[1][0] == 'p') {
		begin = (void**)(jz_xtoi(argv[2]) + KERNBASE);  
	} else if (argv[1][0] == 'v') {  
		begin = (void**)(jz_xtoi(argv[2])); 
	}
	if(begin > begin + length){
		cprintf("out of memory.\n");
		return 0;
	}
    for (i = 0; i < length; ++i){
        cprintf("va at %x is %x\n", begin+i, begin[i]);
    }
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

	if (tf != NULL)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
