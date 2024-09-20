/*
 * T4240QDS_init.h
 * 32-bit mode 
 */

#ifndef T4240QDS_INIT_H_
#define T4240QDS_INIT_H_

#define MAX_NUM_OF_CORES	24
#define MASTER_CORE_ID		0

#define SET_GROUP_BASE(base) asm("xor	17, 17, 17");\
							 asm("oris  17, 17, %0" : : "n"((base) >> 16));\
							 asm("ori	17, 17, %0" : : "n" ((base) & 0xFFFF));

#define LD_VAL_W(value)		 asm("lis	19, %0" : : "n"((value) >> 16));\
							 asm("ori	19, 19, %0" : : "n" ((value) & 0xFFFF));

#define CCSR_SET_W(offset, value)  asm ("li   18, %0" : : "n" ((offset)));\
								   LD_VAL_W((value));\
								   asm ("stwx 19, 18, 17");


#define CCSR_SET_DUP_W(offset)     asm ("li   18, %0" : : "n" ((offset)));\
								   asm ("stwx 19, 18, 17");

#define CCSR_GET_W(offset)		   asm ("li   18, %0" : : "n" ((offset)));\
								   asm ("lwzx 19, 18, 17");


#define SET_BOOT_SPACE_TRANSLATION_ADDRESS				\
	asm ("lis  19,	__spin_table_loop@ha");				\
    asm ("addi  19, 19, __spin_table_loop@l");			\
    asm ("li  18, 0x24");			\
    asm ("stwx 19, 18, 17");

#define INIT_MMU_NOR 				\
	asm ("lis	5, 0x1004");		\
	asm ("ori 5, 5, 0");			\
	asm ("mtspr 624, 5");			\
									\
	asm ("lis	5, 0xC000");		\
	asm ("ori 5, 5, 0x0900");		\
	asm ("mtspr 625, 5");			\
									\
	asm ("lis	5, 0xe000");		\
	asm ("ori 5, 5, 0x000a");		\
	asm ("rlwinm 5, 5, 0, 0, 31");	\
	asm ("mtspr 626, 5");			\
									\
	asm ("lis	5, 0xe000");		\
	asm ("ori 5, 5, 0x0015");		\
	asm ("mtspr 627, 5");			\
									\
	asm ("tlbwe");					\
	asm ("msync");					\
	asm ("isync");	

#define INIT_MMU_DDR				\
	asm ("lis	5, 0x1002");		\
	asm ("ori 5, 5, 0");			\
	asm ("mtspr 624, 5");			\
									\
	asm ("lis	5, 0xC000");		\
	asm ("ori 5, 5, 0x0a80");		\
	asm ("mtspr 625, 5");			\
									\
	asm ("lis	5, 0x0000");		\
	asm ("ori 5, 5, 0x000C");		\
	asm ("rlwinm 5, 5, 0, 0, 31");	\
	asm ("mtspr 626, 5");			\
									\
	asm ("lis	5, 0x0000");		\
	asm ("ori 5, 5, 0x0015");		\
	asm ("mtspr 627, 5");			\
									\
	asm ("tlbwe");					\
	asm ("msync");					\
	asm ("isync");		

#endif /* T4240QDS_INIT_H_ */
