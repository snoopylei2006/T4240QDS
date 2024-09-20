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
}
