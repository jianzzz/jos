/* See COPYRIGHT for copyright information. */

#include <inc/mmu.h>
#include <inc/memlayout.h>
#include <inc/trap.h>



###################################################################
# exceptions/interrupts
###################################################################

/* TRAPHANDLER defines a globally-visible function for handling a trap.
 * It pushes a trap number onto the stack, then jumps to _alltraps.
 * Use TRAPHANDLER for traps where the CPU automatically pushes an error code.
 *
 * You shouldn't call a TRAPHANDLER function from C, but you may
 * need to _declare_ one in C (for instance, to get a function pointer
 * during IDT setup).  You can declare the function with
 *   void NAME();
 * where NAME is the argument passed to TRAPHANDLER.
 */
 /*
 	todo...automatically pushes an error code, but how???
 */
 #define TRAPHANDLER(name, num)						\
 	.globl name;		/* define global symbol for 'name' */	\
 	.type name, @function;	/* symbol type is function */		\
 	.align 2;		/* align function definition */		\
 	name:			/* function starts here */		\
 	pushl $(num);							\  	
 	jmp _alltraps

/* Use TRAPHANDLER_NOEC for traps where the CPU doesn't push an error code.
 * It pushes a 0 in place of the error code, so the trap frame has the same
 * format in either case.
 */
#define TRAPHANDLER_NOEC(name, num)					\
	.globl name;							\
	.type name, @function;						\
	.align 2;							\
	name:								\
	pushl $0;							\
	pushl $(num);							\
	jmp _alltraps

.text
 
/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */  
TRAPHANDLER(entry_point0,T_DIVIDE)
TRAPHANDLER(entry_point1,T_DEBUG) 
TRAPHANDLER(entry_point2,T_NMI)
TRAPHANDLER(entry_point3,T_BRKPT)
TRAPHANDLER(entry_point4,T_OFLOW)
TRAPHANDLER(entry_point5,T_BOUND)
TRAPHANDLER(entry_point6,T_ILLOP)
TRAPHANDLER(entry_point7,T_DEVICE)
TRAPHANDLER(entry_point8,T_DBLFLT)
# TRAPHANDLER(entry_point9,T_COPROC)
TRAPHANDLER(entry_point10,T_TSS)
TRAPHANDLER(entry_point11,T_SEGNP)
TRAPHANDLER(entry_point12,T_STACK)
TRAPHANDLER(entry_point13,T_GPFLT)
TRAPHANDLER(entry_point14,T_PGFLT)
# TRAPHANDLER(entry_point15,T_RES)
TRAPHANDLER(entry_point16,T_FPERR)
TRAPHANDLER(entry_point17,T_ALIGN)
TRAPHANDLER(entry_point18,T_MCHK)
TRAPHANDLER(entry_point19,T_SIMDERR) 
 
/*
 * Lab 3: Your code here for _alltraps
 */
 .globl _alltraps
_alltraps:
  # Build trap frame. //将用户进程的寄存器保存
  pushl %ds
  pushl %es 
  pushal
  //load GD_KD into %ds and %es
  movw $(GD_KD), %ax
  movw %ax, %ds
  movw %ax, %es 
  pushl %esp
  call trap


/*
 * add by jianzzz
 */ 
# entry point table
.data
.globl entry_points
entry_points:
  .long entry_point0
  .long entry_point1
  .long entry_point2
  .long entry_point3
  .long entry_point4
  .long entry_point5
  .long entry_point6
  .long entry_point7
  .long entry_point8
#  .long entry_point9
  .long entry_point10
  .long entry_point11
  .long entry_point12
  .long entry_point13
  .long entry_point14
#  .long entry_point15
  .long entry_point16
  .long entry_point17
  .long entry_point18
  .long entry_point19
  /*
  .long entry_point20
  .long entry_point21
  .long entry_point22
  .long entry_point23
  .long entry_point24
  .long entry_point25
  .long entry_point26
  .long entry_point27
  .long entry_point28
  .long entry_point29
  .long entry_point30
  .long entry_point31
  .long entry_point32
  .long entry_point33
  .long entry_point34
  .long entry_point35
  .long entry_point36
  .long entry_point37
  .long entry_point38
  .long entry_point39
  .long entry_point40
  .long entry_point41
  .long entry_point42
  .long entry_point43
  .long entry_point44
  .long entry_point45
  .long entry_point46
  .long entry_point47
  .long entry_point48
  .long entry_point49
  .long entry_point50
  .long entry_point51
  .long entry_point52
  .long entry_point53
  .long entry_point54
  .long entry_point55
  .long entry_point56
  .long entry_point57
  .long entry_point58
  .long entry_point59
  .long entry_point60
  .long entry_point61
  .long entry_point62
  .long entry_point63
  .long entry_point64
  .long entry_point65
  .long entry_point66
  .long entry_point67
  .long entry_point68
  .long entry_point69
  .long entry_point70
  .long entry_point71
  .long entry_point72
  .long entry_point73
  .long entry_point74
  .long entry_point75
  .long entry_point76
  .long entry_point77
  .long entry_point78
  .long entry_point79
  .long entry_point80
  .long entry_point81
  .long entry_point82
  .long entry_point83
  .long entry_point84
  .long entry_point85
  .long entry_point86
  .long entry_point87
  .long entry_point88
  .long entry_point89
  .long entry_point90
  .long entry_point91
  .long entry_point92
  .long entry_point93
  .long entry_point94
  .long entry_point95
  .long entry_point96
  .long entry_point97
  .long entry_point98
  .long entry_point99
  .long entry_point100
  .long entry_point101
  .long entry_point102
  .long entry_point103
  .long entry_point104
  .long entry_point105
  .long entry_point106
  .long entry_point107
  .long entry_point108
  .long entry_point109
  .long entry_point110
  .long entry_point111
  .long entry_point112
  .long entry_point113
  .long entry_point114
  .long entry_point115
  .long entry_point116
  .long entry_point117
  .long entry_point118
  .long entry_point119
  .long entry_point120
  .long entry_point121
  .long entry_point122
  .long entry_point123
  .long entry_point124
  .long entry_point125
  .long entry_point126
  .long entry_point127
  .long entry_point128
  .long entry_point129
  .long entry_point130
  .long entry_point131
  .long entry_point132
  .long entry_point133
  .long entry_point134
  .long entry_point135
  .long entry_point136
  .long entry_point137
  .long entry_point138
  .long entry_point139
  .long entry_point140
  .long entry_point141
  .long entry_point142
  .long entry_point143
  .long entry_point144
  .long entry_point145
  .long entry_point146
  .long entry_point147
  .long entry_point148
  .long entry_point149
  .long entry_point150
  .long entry_point151
  .long entry_point152
  .long entry_point153
  .long entry_point154
  .long entry_point155
  .long entry_point156
  .long entry_point157
  .long entry_point158
  .long entry_point159
  .long entry_point160
  .long entry_point161
  .long entry_point162
  .long entry_point163
  .long entry_point164
  .long entry_point165
  .long entry_point166
  .long entry_point167
  .long entry_point168
  .long entry_point169
  .long entry_point170
  .long entry_point171
  .long entry_point172
  .long entry_point173
  .long entry_point174
  .long entry_point175
  .long entry_point176
  .long entry_point177
  .long entry_point178
  .long entry_point179
  .long entry_point180
  .long entry_point181
  .long entry_point182
  .long entry_point183
  .long entry_point184
  .long entry_point185
  .long entry_point186
  .long entry_point187
  .long entry_point188
  .long entry_point189
  .long entry_point190
  .long entry_point191
  .long entry_point192
  .long entry_point193
  .long entry_point194
  .long entry_point195
  .long entry_point196
  .long entry_point197
  .long entry_point198
  .long entry_point199
  .long entry_point200
  .long entry_point201
  .long entry_point202
  .long entry_point203
  .long entry_point204
  .long entry_point205
  .long entry_point206
  .long entry_point207
  .long entry_point208
  .long entry_point209
  .long entry_point210
  .long entry_point211
  .long entry_point212
  .long entry_point213
  .long entry_point214
  .long entry_point215
  .long entry_point216
  .long entry_point217
  .long entry_point218
  .long entry_point219
  .long entry_point220
  .long entry_point221
  .long entry_point222
  .long entry_point223
  .long entry_point224
  .long entry_point225
  .long entry_point226
  .long entry_point227
  .long entry_point228
  .long entry_point229
  .long entry_point230
  .long entry_point231
  .long entry_point232
  .long entry_point233
  .long entry_point234
  .long entry_point235
  .long entry_point236
  .long entry_point237
  .long entry_point238
  .long entry_point239
  .long entry_point240
  .long entry_point241
  .long entry_point242
  .long entry_point243
  .long entry_point244
  .long entry_point245
  .long entry_point246
  .long entry_point247
  .long entry_point248
  .long entry_point249
  .long entry_point250
  .long entry_point251
  .long entry_point252
  .long entry_point253
  .long entry_point254
  .long entry_point255
  */