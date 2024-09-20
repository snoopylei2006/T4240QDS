/*  Copyright © 2010 Freescale Semiconductor, Inc.  All rights reserved.
 *
 *  e6500 (32-bit) - C startup code
 *
 */

/*
 *  Stack and heap pointers and size
 *  These should be defined in gcc linker script
 */
extern char		*_stack_addr;	/* starting address for stack */
extern char     *_stack_end;	/* address after end byte of stack */
extern char		*_heap_addr;	/* starting address for heap */
extern char 	*_heap_end;	    /* address after end byte of heap */

/*
 *	Small Data pointers
 *  These should be defined in gcc linker script
 */

extern char		*_SDA_BASE_;	/* Small Data Area (<=8 bytes) base addr */
									/* used for .sdata, .sbss */

extern char		 	__fsl_bss_start;	/* starting address for bss section */
extern char 		__fsl_bss_end;	    /* ending   address for bss section */

extern char     _etext, _data, _edata, _esdata, _sdata, _fsdata;

#if defined(__cplusplus)
extern void (* __CTOR_LIST__[1]) (void) __attribute__ ((section (".ctors")));
extern void (* __CTOR_END__[1]) (void) __attribute__ ((section (".ctors")));
extern void (* __DTOR_LIST__[1]) (void) __attribute__ ((section (".dtors")));
extern void (* __DTOR_END__[1]) (void) __attribute__ ((section (".dtors")));

typedef void (*voidfunctionptr) (void);	/* ptr to function returning void */

/* dummy definition: this is for loading shared library which is not supported */
void *__dso_handle = (void*) &__dso_handle;
#endif

#include <stddef.h>

#if SMPTARGET
#include "smp_target.h"
#endif

#if __cplusplus
extern "C" {
#endif

void * memset(void * dst, int val, size_t n);
extern void exit(int status);
extern void usr_init();
extern void _ExitProcess(void);
extern void abort(void);

#if __cplusplus
extern void __init_cpp(void);
extern void __fini_cpp(void);
extern char __eh_frame_start[];
extern void __register_frame (void *);
extern void __deregister_frame (void *);
#endif

#if SMPTARGET
void __start(register int argc, register char **argv, register char **envp) __attribute__ ((weak, alias ("__start__SMP")));
#endif

#if ROMTARGET
void __init_hardware(void) __attribute__ ((section (".init")));
#if SMPTARGET
void __start__SMP(register int argc, register char **argv, register char **envp) __attribute__ ((section (".init")));
#else
void __start(register int argc, register char **argv, register char **envp) __attribute__ ((section (".init")));
#endif
#endif

void __init_hardware(void)
{
    /* init here according to hardware specification */
    /* MSR, FP, SPE, CACHE, etc */
}

extern void __init_data(void)
{
    char *bss_start = &_edata;
	char *bss_end   = &__fsl_bss_end;
    unsigned long size = bss_end - bss_start;

#if ROMTARGET
    /* ROM has .sdata at end of .text; copy it */
    char *src = &_etext;
    char *dst = &_sdata;

    while (dst < &_fsdata) {
       *dst++ = *src++;
    }

    /* ROM has .data at end of .sdata; copy it. */
    src = &_esdata;
    dst = &_data;
    while (dst < &_edata) {
       *dst++ = *src++;
    }
#endif

    if (size)
    {
        memset(bss_start, 0, size);
    }
}

#if SMPTARGET
void __start__SMP(register int argc, register char **argv, register char **envp)
#else
void __start(register int argc, register char **argv, register char **envp)
#endif
{

    /* init command line arguments */
    __asm__ (

    "mr     14, %0 \n"
    "mr     15, %1 \n"
    "mr     16, %2 \n"
    :
    : "r" (argc), "r" (argv), "r" (envp)
    );

#if defined (SMPTARGET) && defined (ROMTARGET)
    __asm__ (
	".global ret_from_spin_loop \n"
	"ret_from_spin_loop: \n"
    
    );
	/* secondary cores initialize their MSR*/
    asm("mfpir  7");
    asm("srwi  4, 7, 2");
    asm("andi. 5, 7, 1");
    asm("add   7, 4, 5");	
    asm("cmpwi  7, 0");
    asm("beq skip_init_msr");
	asm("bl     usr_init_reg \n");
	asm("skip_init_msr:");


    
#endif

#if ROMTARGET

	asm("bl usr_init1");
	asm("mfpir  7");
	asm("srwi  4, 7, 2");
	asm("andi. 5, 7, 1");
	asm("add   7, 4, 5");	
	asm("cmpwi  7, 0");  //For ROM target MASTER_CORE_ID is always 0
	asm("beq  usr_init_core0");
	asm("bl usr_init2");
	asm("b usr_init_end");
	asm("usr_init_core0:");
	asm("mfmsr 6");
	asm("lis 7,switch@h");
	asm("ori 7,7,switch@l");
	asm("mtspr 26,7");
	asm("mtspr 27,6");
	asm("rfi");
	asm("switch:");
	asm("bl usr_init2");
	asm("usr_init_end:");

#endif

#ifndef SMPTARGET
 __asm__ ( "lis    1, _stack_addr@ha \n"
    "addi   1, 1, _stack_addr@l \n"
	);
#else
	SMP_STACK_INIT
#endif

	__asm__ (
    /* no _SDA2_BASE_ because r2 is reserved for thread pointer under LinuxABI */
    "lis    13, _SDA_BASE_@ha \n"
    "addi   13, 13, _SDA_BASE_@l \n"
    );

/* init hardware */
    __asm__ (
    "bl     __init_hardware \n"
    );

	/* Memory access is assumed safe now after board init above */

	/* Prepare a terminating stack record */
	__asm__ (

	"stwu	1, -16(1)   \n"			/* SP Alignment 16-byte */
	"li		0, 0x0000	\n"			/* load up r0 with 0x00000000 */
	"stw	0,	0(1)	\n"			/* SysVr4 Supp indicated that initial back chain word should be null */
	"li		0, 0xFFFFFFFF	\n"			/* load up r0 with 0xFFFFFFFF */
	"stw	0, 4(1)	    \n"			/* Make an illegal return address of 0xFFFFFFFF */
    );

#if defined (SMPTARGET)
	__asm__ ("mfpir  7 \n");
	asm("srwi  4, 7, 2");
    asm("andi. 5, 7, 1");
    asm("add   7, 4, 5");
	asm("cmpwi  7, %0" : : "i" (MASTER_CORE_ID));

#if defined (ROMTARGET)
	/* only core0 should initialize the .data and .bss segment, the other cores should jump over this segment */
	__asm__ ("bne main_section \n");
#else
	__asm__ ("bne __spin_table_loop \n");
#endif
#endif

    /* data and bss init */
    __asm__ (

    "lis    6, __init_data@ha \n"
    "addi   6, 6, __init_data@l \n"
    "mtlr   6 \n"
    "blrl         \n"
    );

#if defined (SMPTARGET) && !defined (ROMTARGET)
    __asm__ (
	".global ret_from_spin_loop \n"
	"ret_from_spin_loop: \n"
    );
#endif

#if defined (SMPTARGET) && defined (ROMTARGET)
    asm("bl init_boot_space_translation");    
    /* core 0 enables the second thread */
    asm("li 3, 0x2");
    asm("mtspr 438, 3");
#endif


#if __cplusplus
	/* init cpp */
    __asm__ (
    "bl     __init_cpp \n"
    );
#endif

    /* branch to main() */
    __asm__ (
    "main_section: \n"
    "lis    6, main@ha \n"
    "addi   6, 6, main@l \n"
    "mtlr   6 \n"
    "mr     3, 14 \n"
    "mr     4, 15 \n"
    "mr     5, 16 \n"
    "blrl         \n"
    );

    /* branch to exit() */
    __asm__ (

    "lis    6, exit@ha \n"
    "addi   6, 6, exit@l \n"
    "mtlr   6 \n"
    "blrl         \n"
    );

    return;
}

extern void abort(void)
{
	_ExitProcess();
}

extern void exit(int status)
{
#if defined(__cplusplus)
    __fini_cpp();
#endif
    _ExitProcess();
}

extern void _ExitProcess(void)
{
	__asm__ (".long 0x4cE0F18c\n"); /* break trap for p4080/p5020 (32-bit) */
}

#if defined(__cplusplus)
/*  C++ initialization before calling main().  Calls constructors of which the
 *  cpp exception handling initialization is the first constructor,
 *  if exceptions are used.
 */
extern void __init_cpp(void)
{
    voidfunctionptr* constructor;
	/*
	 *	call static initializers
	 */
    for (constructor = __CTOR_LIST__ ; constructor != __CTOR_END__; constructor++) {
	    (*constructor)();
    }

    /* exception handling frame information */
    __register_frame (&__eh_frame_start);
}

/*  Calls destructors */
extern void __fini_cpp(void)
{
	 voidfunctionptr* destructor;
	/*
	 *	call destructors
	 */
	for (destructor = __DTOR_LIST__ ; destructor != __DTOR_END__; destructor++) {
		(*destructor)();
	}

	/* exception handling shutdown */
	__deregister_frame (&__eh_frame_start);
}
#endif

#if __cplusplus
}
#endif
