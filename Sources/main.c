//////////////////////////
//	Project Stationery  //
//////////////////////////

#include <stdio.h>

typedef void (IntHndlr)(long);
extern void InterruptHandler(long cause);
#if SMPTARGET
	#include "smp_target.h"
#endif

int main()
{
	/*
	Because the interrupt vector code is shared, each thread needs to register
	its own InterruptHandeler routine in SPRG0 (SPR 272)
	*/
	register IntHndlr* isr = InterruptHandler;
	asm("mtspr 272, %0" : : "r" (isr));
	
	int i=0;
		
	unsigned long proc_id;
	
	asm ("mfpir %0" : "=r" (proc_id));

#if SMPTARGET
	initSmp();
#endif

	printf("Core%lu-Thread%lu: Welcome to CodeWarrior!\r\n", proc_id >> 3, proc_id % 8);
	asm("sc"); // generate a system call exception to demonstrate the ISR
		
	while (1) { i++; } // loop forever
}

