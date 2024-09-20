#ifndef SMP_TARGET_H_
#define SMP_TARGET_H_

#include "T4240QDS_init.h"

void initSmp(void);
unsigned int getCoreId(void);

#if __cplusplus
	extern "C" {void __spin_table_loop(void);}
#endif
	
#define GET_SPIN_TABLE_ADDRESS					\
	__asm__ (									\
	"mfpir   3 \n"								\
	"srwi     4,3,2 \n"							\
	"andi.	  5,3,1\n"							\
	"add 3, 4, 5\n"								\
	"li       6,8 \n" /* 8 sizeof long long */	\
	"mullw    7,3,6 \n"							\
	"lis      8,spin_table@h \n" /*unsigned long long spin_table[MAX_NUM_OF_CORES]*/	\
	"ori      8,8,spin_table@l \n"				\
	"add      9,8,7 \n"							\
	"lwz      11,0(9) \n"						\
	);

#define SMP_STACK_INIT 							\
	__asm__ (									\
	".macro	INIT_STACK_CORE core=0 \n"			\
	".ifgt	%0 - \\core \n"						\
	"cmpwi	7, \\core \n"						\
	"bne	0x10 \n"							\
	"lis	1, _stack_addr\\@@ha \n"			\
	"addi	1, 1, _stack_addr\\@@l \n"			\
	"bl 	end_sp \n"							\
	".set	next_core, \\core + 1 \n"			\
	"INIT_STACK_CORE next_core \n"				\
	".endif \n"									\
	".endm \n"									\
												\
	"mfpir   7 \n"								\
	"srwi    4,7,2 \n"							\
	"andi.	  5,7,1\n"							\
	"add 	7, 4, 5\n"								\
												\
	"INIT_STACK_CORE \n"						\
	"end_sp: \n"								\
	: : "i" (MAX_NUM_OF_CORES)					\
    );
	
#endif /* SMP_TARGET_H_ */
