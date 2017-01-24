// implement fork from user space

#include <inc/string.h>
#include <inc/lib.h>

// PTE_COW marks copy-on-write page table entries.
// It is one of the bits explicitly allocated to user processes (PTE_AVAIL).
#define PTE_COW		0x800
extern void _pgfault_upcall(void);

//
// Custom page fault handler - if faulting page is copy-on-write,
// map in our own private writable copy.
//
static void
pgfault(struct UTrapframe *utf)
{
	void *addr = (void *) utf->utf_fault_va;
	uint32_t err = utf->utf_err;
	int r;
	// Check that the faulting access was (1) a write, and (2) to a
	// copy-on-write page.  If not, panic.
	// Hint:
	//   Use the read-only page table mappings at uvpt
	//   (see <inc/memlayout.h>).

	// LAB 4: Your code here.
	if ((err & FEC_WR) == 0)
		panic("pgfault: faulting address [%08x] not a write\n", addr);

	if( (uvpd[PDX(addr)] & PTE_P) != PTE_P || 
	    (uvpt[PGNUM(addr)] & PTE_P) != PTE_P || 
	    (uvpt[PGNUM(addr)] & PTE_COW) != PTE_COW){ 
		//cprintf("(uvpt[PTX(addr)] & PTE_P)=%x,PTE_P=%x\n",(uvpt[PGNUM(addr)] & PTE_P),PTE_P);
		panic("not copy-on-write, addr: %x",addr);
	}
	// Allocate a new page, map it at a temporary location (PFTEMP),
	// copy the data from the old page to the new page, then move the new
	// page to the old page's address.
	// Hint:
	//   You should make three system calls.

	// LAB 4: Your code here.

	//panic("pgfault not implemented");
	addr = ROUNDDOWN(addr, PGSIZE);
	if ((r = sys_page_alloc(0, PFTEMP, PTE_P|PTE_U|PTE_W)) < 0)
		panic("allocating at %x in page fault handler: %e", addr, r);
	memmove(PFTEMP, addr, PGSIZE);
	//cprintf("in user pgfault,envid = %x\n",thisenv->env_id);
	if ((r = sys_page_map(0, PFTEMP, 0, addr, PTE_P|PTE_U|PTE_W)) < 0)
		panic("sys_page_map: %e", r);
	if ((r = sys_page_unmap(0, PFTEMP)) < 0)
		panic("sys_page_unmap: %e", r);
}

//
// Map our virtual page pn (address pn*PGSIZE) into the target envid
// at the same virtual address.  If the page is writable or copy-on-write,
// the new mapping must be created copy-on-write, and then our mapping must be
// marked copy-on-write as well.  (Exercise: Why do we need to mark ours
// copy-on-write again if it was already copy-on-write at the beginning of
// this function?)
//
// Returns: 0 on success, < 0 on error.
// It is also OK to panic on error.
//
static int
duppage(envid_t envid, unsigned pn)
{
	int r;

	// LAB 4: Your code here.
	//panic("duppage not implemented"); 
	void *addr = (void *)(pn*PGSIZE);
	if ( (uvpt[pn] & PTE_SHARE) == PTE_SHARE ) { 
		if ((r = sys_page_map(0, (void *)addr, envid, (void *)addr, uvpt[pn] & PTE_SYSCALL)) < 0)
			panic("sys_page_map: %e\n", r);
	} else if( (uvpt[pn] & PTE_W) == PTE_W || 
	    (uvpt[pn] & PTE_COW) == PTE_COW){ 
 		if ((r = sys_page_map(0, (void *)addr, envid, (void *)addr, PTE_P|PTE_U|PTE_COW)) < 0){
			panic("sys_page_map: %e", r);
 		} 
 		if ((r = sys_page_map(0, (void *)addr, 0, (void *)addr, PTE_P|PTE_U|PTE_COW)) < 0){
			panic("sys_page_map: %e", r);
 		} 
	}else{
		if ((r = sys_page_map(0, (void *)addr, envid, (void *)addr, PTE_P|PTE_U)) < 0){
			panic("sys_page_map: %e", r);
 		}
	}
	return 0;
}

//
// User-level fork with copy-on-write.
// Set up our page fault handler appropriately.
// Create a child.
// Copy our address space and page fault handler setup to the child.
// Then mark the child as runnable and return.
//
// Returns: child's envid to the parent, 0 to the child, < 0 on error.
// It is also OK to panic on error.
//
// Hint:
//   Use uvpd, uvpt, and duppage.
//   Remember to fix "thisenv" in the child process.
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
envid_t
fork(void)
{
	// LAB 4: Your code here.
	//panic("fork not implemented");
	set_pgfault_handler(pgfault);

	envid_t envid;
	unsigned addr;
	int r;
	extern unsigned char end[]; 

	envid = sys_exofork();
	if (envid < 0)
		panic("sys_exofork: %e", envid);
	if (envid == 0) {
		// We're the child. 
		// DO NOT CALL set_pgfault_handler DIRECTLY! Cause we are forked from parent who has
		// called "set_pgfault_handler", so the variable named "_pgfault_handler" in pgfault.c has been set,
		// and child-env will not call "sys_page_alloc" and "sys_env_set_pgfault_upcall"
		// do not call: set_pgfault_handler(pgfault); 
		
		// DO NOT SET USER EXCEPTION STACK IN CHILD! Cause we set COW on user stack(not user exception stack), so function call
		// like "sys_page_alloc" and "sys_env_set_pgfault_upcall"(which want to stack user excettion stack) 
		// will cause page fault, and kern will use user excettion stack, but it has not been set!!
		// do not call:
	  	// if (sys_page_alloc(0, (void *)(UXSTACKTOP-PGSIZE), PTE_P|PTE_U|PTE_W) < 0)
		//	 panic("in fork, sys_page_alloc failed");
		// if (sys_env_set_pgfault_upcall(0, (void*) _pgfault_upcall) < 0) 
		// 	 panic("in fork, sys_env_set_pgfault_upcall failed");
		//  

		thisenv = &envs[ENVX(sys_getenvid())];
		return 0;
	}

	// We're the parent. 
	// map the page copy-on-write into the address space of the child 
	// and then remap the page copy-on-write in its own address space
	for (addr = 0; addr < USTACKTOP; addr += PGSIZE)
		if ((uvpd[PDX(addr)] & PTE_P) && (uvpt[PGNUM(addr)] & PTE_P)
		    && (uvpt[PGNUM(addr)] & PTE_U)) {
		    duppage(envid, PGNUM(addr)); 
		} 
	// fix lab4!!! can not use the following!!!
	// we may use some addr above end[] but below USTACKTOP in parent, even make it a shared-page,
	// if we use the following, child will not map the addr and child may cause page fault when use it,
	// however, it's not a copy-on-write addr at all, it will panic in pgfault
	/*
	for (addr = UTEXT; addr < (unsigned)end; addr += PGSIZE){
		duppage(envid, PGNUM(addr)); 
	} 
	// map the stack we are currently running on.
	duppage(envid, PGNUM(USTACKTOP - PGSIZE));    
    */

	if (sys_page_alloc(envid, (void *)(UXSTACKTOP-PGSIZE), PTE_P|PTE_U|PTE_W) < 0)
		panic("in fork, sys_page_alloc failed");
	if (sys_env_set_pgfault_upcall(envid, (void*) _pgfault_upcall) < 0)
		panic("in fork, sys_env_set_pgfault_upcall failed");

	// Start the child environment running
	if ((r = sys_env_set_status(envid, ENV_RUNNABLE)) < 0)
		panic("sys_env_set_status: %e", r);
 
	return envid;
}

// Challenge!
int
sfork(void)
{ 
	set_pgfault_handler(pgfault);

	envid_t envid;
	unsigned addr;
	int r;
	extern unsigned char end[]; 

	envid = sys_exofork();
	if (envid < 0)
		panic("sys_exofork: %e", envid);
	if (envid == 0) { 
		thisenv = &envs[ENVX(sys_getenvid())];
		return 0;
	}

	// We're the parent. 
	// share memory
	for (addr = 0; addr < USTACKTOP; addr += PGSIZE){
		// pte's low 12 bits,that means perm,
		// however, in sys_page_map, no other bits may be set except PTE_SYSCALL
		// #define PTE_SYSCALL	(PTE_AVAIL | PTE_P | PTE_W | PTE_U)
		if ((uvpd[PDX(addr)] & PTE_P) && (uvpt[PGNUM(addr)] & PTE_P)
		    && (uvpt[PGNUM(addr)] & PTE_U)){
			int perm = uvpt[PGNUM(addr)] & PTE_SYSCALL;
			if ((r = sys_page_map(0, (void *)addr, envid, (void *)addr, perm)) < 0){
				panic("sys_page_map: %e", r);
	 		} 
		}
	} 
	// map the stack we are currently running on, set copy-on-write.
	duppage(envid, PGNUM(USTACKTOP - PGSIZE));  

	// fix lab4!!! can not use the following!!!
	// we may use some addr above end[] but below USTACKTOP in parent, even make it a shared-page,
	// if we use the following, child will not map the addr and child may cause page fault when use it,
	// however, it's not a copy-on-write addr at all, it will panic in pgfault
	/*
	for (addr = UTEXT; addr < (unsigned)end; addr += PGSIZE){
		// pte's low 12 bits,that means perm,
		// however, in sys_page_map, no other bits may be set except PTE_SYSCALL
		// #define PTE_SYSCALL	(PTE_AVAIL | PTE_P | PTE_W | PTE_U)
		int perm = uvpt[PGNUM(addr)] & PTE_SYSCALL;
		if ((r = sys_page_map(0, (void *)addr, envid, (void *)addr, perm)) < 0){
			panic("sys_page_map: %e", r);
 		} 
	} 
	// map the stack we are currently running on, set copy-on-write.
	duppage(envid, PGNUM(USTACKTOP - PGSIZE));   
	*/

	if (sys_page_alloc(envid, (void *)(UXSTACKTOP-PGSIZE), PTE_P|PTE_U|PTE_W) < 0)
		panic("in fork, sys_page_alloc failed");
	if (sys_env_set_pgfault_upcall(envid, (void*) _pgfault_upcall) < 0)
		panic("in fork, sys_env_set_pgfault_upcall failed");

	// Start the child environment running
	if ((r = sys_env_set_status(envid, ENV_RUNNABLE)) < 0)
		panic("sys_env_set_status: %e", r);
 
	return envid; 
}
