// implement fork from user space

#include <inc/string.h>
#include <inc/lib.h>

// PTE_COW marks copy-on-write page table entries.
// It is one of the bits explicitly allocated to user processes (PTE_AVAIL).
#define PTE_COW		0x800

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
	    (uvpt[PTX(addr)] & PTE_P) != PTE_P || 
	    (uvpt[PTX(addr)] & PTE_COW) != PTE_COW){
		cprintf("addr=%x,PTX(addr)=%x,PGNUM(addr)=%x\n",addr,PTX(addr),PGNUM(addr));
		//cprintf("(uvpt[PTX(addr)] & PTE_P)=%x,PTE_P=%x\n",(uvpt[PGNUM(addr)] & PTE_P),PTE_P);
		panic("not copy-on-write");
	}
	// Allocate a new page, map it at a temporary location (PFTEMP),
	// copy the data from the old page to the new page, then move the new
	// page to the old page's address.
	// Hint:
	//   You should make three system calls.

	// LAB 4: Your code here.

	//panic("pgfault not implemented");
	addr = ROUNDDOWN(addr, PGSIZE);
	if ((r = sys_page_alloc(thisenv->env_id, PFTEMP, PTE_P|PTE_U|PTE_W)) < 0)
		panic("allocating at %x in page fault handler: %e", addr, r);
	memmove(addr, PFTEMP, PGSIZE);
	if ((r = sys_page_map(thisenv->env_id, PFTEMP, thisenv->env_id, addr, PTE_P|PTE_U|PTE_W)) < 0)
		panic("sys_page_map: %e", r);
	if ((r = sys_page_unmap(thisenv->env_id, PFTEMP)) < 0)
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
	if( (uvpt[PTX(addr)] & PTE_W) == PTE_W || 
	    (uvpt[PTX(addr)] & PTE_COW) == PTE_COW){ 
 		if ((r = sys_page_map(0, (void *)addr, envid, (void *)addr, PTE_P|PTE_U|PTE_COW)) < 0){
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
		set_pgfault_handler(pgfault);
		thisenv = &envs[ENVX(sys_getenvid())];
		return 0;
	}

	// We're the parent. 
	// map the page copy-on-write into the address space of the child 
	// and then remap the page copy-on-write in its own address space
	for (addr = UTEXT; addr < (unsigned)end; addr += PGSIZE){
		duppage(envid, PGNUM(addr));
		duppage(0, PGNUM(addr));
	} 
	// map the stack we are currently running on.
	duppage(envid, PGNUM(ROUNDDOWN((void*)USTACKTOP - PGSIZE, PGSIZE))); 
	duppage(0, PGNUM(ROUNDDOWN((void*)USTACKTOP - PGSIZE, PGSIZE))); 
  
	// Start the child environment running
	if ((r = sys_env_set_status(envid, ENV_RUNNABLE)) < 0)
		panic("sys_env_set_status: %e", r);
 
	return envid;
}

// Challenge!
int
sfork(void)
{
	panic("sfork not implemented");
	return -E_INVAL;
}
