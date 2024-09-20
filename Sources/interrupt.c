#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

void InterruptHandler(long cause);
extern void __init_hardware(void);

#ifdef __cplusplus
}
#endif

void InterruptHandler(long cause)
{
	unsigned long proc_id;
	
	/* recover computation mode */
	__init_hardware();

#ifdef ALTIVEC
	/* recover altivec enable in MSR */
	asm ("lis    5, 0x0200"
		 "mfmsr 0;"
		 "or 0, 0, 5;" /* set MSR[SPV] */
		 "mtmsr 0 \n"
		 : /* no output */
		 : /* no input */
		 : "0", "5"  /* clobbered register */
		 );
#endif		 
	
	/* read processor id 
	
	Processor ID Register (PIR)
	 Physical Core | Thread |   PIR Value
	 ------------------------------------------
	        0      |    0   |  0x0000_0000
	        0      |    1   |  0x0000_0001
	        1      |    0   |  0x0000_0008
	        1      |    1   |  0x0000_0009
	        2      |    0   |  0x0000_0010
	        2      |    1   |  0x0000_0011
	        3      |    0   |  0x0000_0018
	        3      |    1   |  0x0000_0019
	        4      |    0   |  0x0000_0020
	        4      |    1   |  0x0000_0021
			...
			11     |    0   |  0x0000_0058
			11     |    1   |  0x0000_0059			
	*/
	asm ("mfpir %0" : "=r" (proc_id));
	
	printf("Core%lu-Thread%lu: InterruptHandler: %#lx exception.\r\n", proc_id >> 3, proc_id % 8, cause);
}
