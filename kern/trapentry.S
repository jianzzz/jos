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
TRAPHANDLER_NOEC(entry_point0,T_DIVIDE)
TRAPHANDLER_NOEC(entry_point1,T_DEBUG) 
TRAPHANDLER_NOEC(entry_point2,T_NMI)
TRAPHANDLER_NOEC(entry_point3,T_BRKPT)
TRAPHANDLER_NOEC(entry_point4,T_OFLOW)
TRAPHANDLER_NOEC(entry_point5,T_BOUND)
TRAPHANDLER_NOEC(entry_point6,T_ILLOP)
TRAPHANDLER_NOEC(entry_point7,T_DEVICE)
TRAPHANDLER(entry_point8,T_DBLFLT)
# TRAPHANDLER(entry_point9,T_COPROC)
TRAPHANDLER(entry_point10,T_TSS)
TRAPHANDLER(entry_point11,T_SEGNP)
TRAPHANDLER(entry_point12,T_STACK)
TRAPHANDLER(entry_point13,T_GPFLT)
TRAPHANDLER(entry_point14,T_PGFLT)
# TRAPHANDLER(entry_point15,T_RES)
TRAPHANDLER_NOEC(entry_point16,T_FPERR) 
   
TRAPHANDLER_NOEC(entry_point48,T_SYSCALL) 

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
  .long 0   #attendion: instead we should fill the hole with 0, or it will cause entry_points array's wrong index
  .long entry_point10
  .long entry_point11
  .long entry_point12
  .long entry_point13
  .long entry_point14
#  .long entry_point15
  .long 0   #attendion: instead we should fill the hole with 0, or it will cause entry_points array's wrong index
  .long entry_point16
  
  .long 0#entry_point17
  .long 0#entry_point18
  .long 0#entry_point19
  .long 0#entry_point20
  .long 0#entry_point21
  .long 0#entry_point22
  .long 0#entry_point23
  .long 0#entry_point24
  .long 0#entry_point25
  .long 0#entry_point26
  .long 0#entry_point27
  .long 0#entry_point28
  .long 0#entry_point29
  .long 0#entry_point30
  .long 0#entry_point31
  .long 0#entry_point32
  .long 0#entry_point33
  .long 0#entry_point34
  .long 0#entry_point35
  .long 0#entry_point36
  .long 0#entry_point37
  .long 0#entry_point38
  .long 0#entry_point39
  .long 0#entry_point40
  .long 0#entry_point41
  .long 0#entry_point42
  .long 0#entry_point43
  .long 0#entry_point44
  .long 0#entry_point45
  .long 0#entry_point46
  .long 0#entry_point47
  .long entry_point48
  .long 0#entry_point49
  .long 0#entry_point50
  .long 0#entry_point51
  .long 0#entry_point52
  .long 0#entry_point53
  .long 0#entry_point54
  .long 0#entry_point55
  .long 0#entry_point56
  .long 0#entry_point57
  .long 0#entry_point58
  .long 0#entry_point59
  .long 0#entry_point60
  .long 0#entry_point61
  .long 0#entry_point62
  .long 0#entry_point63
  .long 0#entry_point64
  .long 0#entry_point65
  .long 0#entry_point66
  .long 0#entry_point67
  .long 0#entry_point68
  .long 0#entry_point69
  .long 0#entry_point70
  .long 0#entry_point71
  .long 0#entry_point72
  .long 0#entry_point73
  .long 0#entry_point74
  .long 0#entry_point75
  .long 0#entry_point76
  .long 0#entry_point77
  .long 0#entry_point78
  .long 0#entry_point79
  .long 0#entry_point80
  .long 0#entry_point81
  .long 0#entry_point82
  .long 0#entry_point83
  .long 0#entry_point84
  .long 0#entry_point85
  .long 0#entry_point86
  .long 0#entry_point87
  .long 0#entry_point88
  .long 0#entry_point89
  .long 0#entry_point90
  .long 0#entry_point91
  .long 0#entry_point92
  .long 0#entry_point93
  .long 0#entry_point94
  .long 0#entry_point95
  .long 0#entry_point96
  .long 0#entry_point97
  .long 0#entry_point98
  .long 0#entry_point99
  .long 0#entry_point100
  .long 0#entry_point101
  .long 0#entry_point102
  .long 0#entry_point103
  .long 0#entry_point104
  .long 0#entry_point105
  .long 0#entry_point106
  .long 0#entry_point107
  .long 0#entry_point108
  .long 0#entry_point109
  .long 0#entry_point110
  .long 0#entry_point111
  .long 0#entry_point112
  .long 0#entry_point113
  .long 0#entry_point114
  .long 0#entry_point115
  .long 0#entry_point116
  .long 0#entry_point117
  .long 0#entry_point118
  .long 0#entry_point119
  .long 0#entry_point120
  .long 0#entry_point121
  .long 0#entry_point122
  .long 0#entry_point123
  .long 0#entry_point124
  .long 0#entry_point125
  .long 0#entry_point126
  .long 0#entry_point127
  .long 0#entry_point128
  .long 0#entry_point129
  .long 0#entry_point130
  .long 0#entry_point131
  .long 0#entry_point132
  .long 0#entry_point133
  .long 0#entry_point134
  .long 0#entry_point135
  .long 0#entry_point136
  .long 0#entry_point137
  .long 0#entry_point138
  .long 0#entry_point139
  .long 0#entry_point140
  .long 0#entry_point141
  .long 0#entry_point142
  .long 0#entry_point143
  .long 0#entry_point144
  .long 0#entry_point145
  .long 0#entry_point146
  .long 0#entry_point147
  .long 0#entry_point148
  .long 0#entry_point149
  .long 0#entry_point150
  .long 0#entry_point151
  .long 0#entry_point152
  .long 0#entry_point153
  .long 0#entry_point154
  .long 0#entry_point155
  .long 0#entry_point156
  .long 0#entry_point157
  .long 0#entry_point158
  .long 0#entry_point159
  .long 0#entry_point160
  .long 0#entry_point161
  .long 0#entry_point162
  .long 0#entry_point163
  .long 0#entry_point164
  .long 0#entry_point165
  .long 0#entry_point166
  .long 0#entry_point167
  .long 0#entry_point168
  .long 0#entry_point169
  .long 0#entry_point170
  .long 0#entry_point171
  .long 0#entry_point172
  .long 0#entry_point173
  .long 0#entry_point174
  .long 0#entry_point175
  .long 0#entry_point176
  .long 0#entry_point177
  .long 0#entry_point178
  .long 0#entry_point179
  .long 0#entry_point180
  .long 0#entry_point181
  .long 0#entry_point182
  .long 0#entry_point183
  .long 0#entry_point184
  .long 0#entry_point185
  .long 0#entry_point186
  .long 0#entry_point187
  .long 0#entry_point188
  .long 0#entry_point189
  .long 0#entry_point190
  .long 0#entry_point191
  .long 0#entry_point192
  .long 0#entry_point193
  .long 0#entry_point194
  .long 0#entry_point195
  .long 0#entry_point196
  .long 0#entry_point197
  .long 0#entry_point198
  .long 0#entry_point199
  .long 0#entry_point200
  .long 0#entry_point201
  .long 0#entry_point202
  .long 0#entry_point203
  .long 0#entry_point204
  .long 0#entry_point205
  .long 0#entry_point206
  .long 0#entry_point207
  .long 0#entry_point208
  .long 0#entry_point209
  .long 0#entry_point210
  .long 0#entry_point211
  .long 0#entry_point212
  .long 0#entry_point213
  .long 0#entry_point214
  .long 0#entry_point215
  .long 0#entry_point216
  .long 0#entry_point217
  .long 0#entry_point218
  .long 0#entry_point219
  .long 0#entry_point220
  .long 0#entry_point221
  .long 0#entry_point222
  .long 0#entry_point223
  .long 0#entry_point224
  .long 0#entry_point225
  .long 0#entry_point226
  .long 0#entry_point227
  .long 0#entry_point228
  .long 0#entry_point229
  .long 0#entry_point230
  .long 0#entry_point231
  .long 0#entry_point232
  .long 0#entry_point233
  .long 0#entry_point234
  .long 0#entry_point235
  .long 0#entry_point236
  .long 0#entry_point237
  .long 0#entry_point238
  .long 0#entry_point239
  .long 0#entry_point240
  .long 0#entry_point241
  .long 0#entry_point242
  .long 0#entry_point243
  .long 0#entry_point244
  .long 0#entry_point245
  .long 0#entry_point246
  .long 0#entry_point247
  .long 0#entry_point248
  .long 0#entry_point249
  .long 0#entry_point250
  .long 0#entry_point251
  .long 0#entry_point252
  .long 0#entry_point253
  .long 0#entry_point254
  .long 0#entry_point255
   