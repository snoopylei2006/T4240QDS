#include "T4240QDS_init.h"
#if SMPTARGET
#include "smp_target.h"
#endif
#pragma section code_type ".init"

#ifdef __cplusplus
extern "C" {
#endif

void __reset(void) __attribute__ ((section (".init")));
void usr_init_reg()  __attribute__ ((section (".init")));
void usr_init1() __attribute__ ((section (".init")));
void usr_init2();

#ifdef SMPTARGET
void init_boot_space_translation() __attribute__ ((section (".init")));
#endif

extern void __start();
extern unsigned long gInterruptVectorTable;
extern unsigned long gInterruptVectorTableEnd;



#ifdef __cplusplus
}
#endif

void __reset(void)
{
	asm("bl     usr_init_reg \n");
	asm("b		__start");
}

#define CCSRBAR 			0xFE000000ULL
#define LAW_GROUP_OFFSET	0x00000000
#define DDR1_GROUP_OFFSET	0x00008000
#define IFC_GROUP_OFFSET	0x00124000
#define SRIO_GROUP_OFFSET1	0x000C0000
#define SRIO_GROUP_OFFSET2	0x000D0000
#define TMR_GROUP_OFFSET	0x008F3000
#define ESPI_GROUP_OFFSET	0x00110000

#define LCC_GROUP_OFFSET	0x00000000
#define DCFG_GROUP_OFFSET	0x000E0000
#define RCPM_GROUP_OFFSET	0x000E2000
#define CCF_GROUP_OFFSET	0x00018000
#define CPC_GROUP_OFFSET	0x00010000

// reserve registers r17-r19 for accessing CCSR
register unsigned int  	r_base asm ("r17");
register unsigned short r_off  asm ("r18");
register unsigned int 	r_val  asm ("r19");

// variable used to differentiate between the processor revisions
register unsigned int revision asm ("r20");
register unsigned int sys_ver asm ("r21");

void usr_init_reg()
{
	//
	//   Enable machine check exceptions, floating-point, Altivec
	//
	asm("lis		3, 0x0200");
	asm("ori		3, 3, 0x3000\n");
	asm("mtmsr	3");
}

void usr_init1() {

	//##################################################################################
	//# Initialization file for T4240 QDS
	//# Clock Configuration:
	//#       CPU: 1666 MHz,    CCB:   666.6/733 MHz,
	//#       DDR: 1600/1867 MHz, SYSCLK:    66.6 MHz
	//##################################################################################
	//
	//##################################################################################
	//#
	//#	Memory Map
	//#
	//#   0x00000000  0x7FFFFFFF  TLB1_2 DDR       2048M
	//#   0xC0000000  0xDFFFFFFF  TLB1_6 DCSR       512M
	//#   0xE8000000  0xEFFFFFFF  TLB1_4 NOR        128M
	//#   0xFE000000  0xFEFFFFFF  TLB1_1 CCSR Space  16M
	//#   0xFF800000  0xFF8FFFFF  TLB1_5 NAND         1M
	//#   0xFFDF0000  0xFFDF0FFF  TLB1_3 QIXIS        4k
	//#
	//##################################################################################
	//
	//
	//##################################################################################

	// Read SVR register
	asm ("mfspr %0, 1023" : "=r" (revision));
	revision = (revision & 0x000000FF) >> 4;

	//# MMU initialization
	//

	//# define 16MB  TLB entry  1: 0xFE000000 - 0xFEFFFFFF for CCSR    cache inhibited, guarded
	asm ("lis	5, 0x1001");
	asm ("ori 5, 5, 0");
	asm ("mtspr 624, 5");

	asm ("lis	5, 0xC000");
	asm ("ori 5, 5, 0x0700");
	asm ("mtspr 625, 5");

	asm ("lis	5, 0xfe00");
	asm ("ori 5, 5, 0x000a");
	asm ("rlwinm 5, 5, 0, 0, 31");
	asm ("mtspr 626, 5");

	asm ("lis	5, 0xfe00");
	asm ("ori 5, 5, 0x0015");
	asm ("mtspr 627, 5");

	asm ("tlbwe");
	asm ("msync");
	asm ("isync");

	//# define   2GB TLB entry  2: 0x00000000 - 0x7FFFFFFF for DDR     cache inhibited, M
	INIT_MMU_DDR

	//# define   4KB TLB entry 3: 0xFFDF0000 - 0xFFDF0FFF for QIXIS   cache inhibited, guarded
	asm ("lis	5, 0x1003");
	asm ("ori 5, 5, 0");
	asm ("mtspr 624, 5");

	asm ("lis	5, 0xC000");
	asm ("ori 5, 5, 0x0100");
	asm ("mtspr 625, 5");

	asm ("lis	5, 0xffdf");
	asm ("ori 5, 5, 0x000a");
	asm ("rlwinm 5, 5, 0, 0, 31");
	asm ("mtspr 626, 5");

	asm ("lis	5, 0xffdf");
	asm ("ori 5, 5, 0x0015");
	asm ("mtspr 627, 5");

	asm ("tlbwe");
	asm ("msync");
	asm ("isync");

	//# define 256MB TLB entry  4: 0xE0000000 - 0xEFFFFFFF for IFC-NOR      cache inhibited, guarded
	INIT_MMU_NOR
	
	//# define   1MB TLB entry 5: 0xFF800000 - 0xFF8FFFFF for NAND    cache inhibited, guarded
	asm ("lis	5, 0x1005");
	asm ("ori 5, 5, 0");
	asm ("mtspr 624, 5");

	asm ("lis	5, 0xC000");
	asm ("ori 5, 5, 0x0500");
	asm ("mtspr 625, 5");

	asm ("lis	5, 0xff80");
	asm ("ori 5, 5, 0x0f00a");
	asm ("rlwinm 5, 5, 0, 0, 31");
	asm ("mtspr 626, 5");

	asm ("lis	5, 0xff80");
	asm ("ori 5, 5, 0x0015");
	asm ("mtspr 627, 5");

	asm ("tlbwe");
	asm ("msync");
	asm ("isync");

	//# define   4MB TLB entry 6 : 0xFF000000 - 0xFF3FFFFF for DCSR    cache inhibited, guarded
	asm ("lis	5, 0x1006");
	asm ("ori 5, 5, 0");
	asm ("mtspr 624, 5");

	asm ("lis	5, 0xC000");
	asm ("ori 5, 5, 0x0900");
	asm ("mtspr 625, 5");

	asm ("lis	5, 0xc000");
	asm ("ori 5, 5, 0x000a");
	asm ("rlwinm 5, 5, 0, 0, 31");
	asm ("mtspr 626, 5");

	asm ("lis	5, 0xc000");
	asm ("ori 5, 5, 0x0015");
	asm ("mtspr 627, 5");

	asm ("tlbwe");
	asm ("msync");
	asm ("isync");

#if SMPTARGET
	/* only core 0 should initialize the LAW registers */
	asm("mfpir  7");
	asm("srwi  4, 7, 2");
	asm("andi. 5, 7, 1");
	asm("add   7, 4, 5");
	asm("cmpwi  7, %0" : : "i" (MASTER_CORE_ID));
	asm("bne  usr_init1_end");
#endif

	SET_GROUP_BASE(CCSRBAR + IFC_GROUP_OFFSET);

	if (revision == 1)
	{
		//# IFC WA
		//# IFC_FTIM0
		CCSR_SET_W(0x1c0, 0xf03f3f3f);
		//# IFC_FTIM1
		CCSR_SET_W(0x1c4, 0xff003f3f);
		//# CSPR
		CCSR_SET_W(0x010, 0x00000101);
		//# CSOR
		CCSR_SET_W(0x130, 0x0000000c);
	}
	//
	//##################################################################################
	//# Local Access Windows Setup

	SET_GROUP_BASE(CCSRBAR + LAW_GROUP_OFFSET);
	//
	//# LAW0 to DDR - 2GB
	CCSR_SET_W(0xC00, 0x00000000);
	CCSR_SET_W(0xC04, 0x00000000);
	if (revision == 1)
	{
		// Memory Complex 1
		CCSR_SET_W(0xC08, 0x8100001E);
	}
	else
	{
		// Interleaved Memory Complex 1-3
		CCSR_SET_W(0xC08, 0x8170001E);
	}

	//
	//# LAW1 to IFC- QIXIS
	CCSR_SET_W(0xC10, 0x00000000);
	CCSR_SET_W(0xC14, 0xFFDF0000);
	CCSR_SET_W(0xC18, 0x81F0000B);
	//
	//# LAW2 to IFC - NOR
	CCSR_SET_W(0xC20, 0x00000000);
	CCSR_SET_W(0xC24, 0xE8000000);
	CCSR_SET_W(0xC28, 0x81f0001a);
	//
	//# LAW3 to IFC - NAND
	CCSR_SET_W(0xC30, 0x00000000);
	CCSR_SET_W(0xC34, 0xFF800000);
	CCSR_SET_W(0xC38, 0x81f00013);
	//
	//# LAW4 to DCSR
	CCSR_SET_W(0xC40, 0x00000000);
	CCSR_SET_W(0xC44, 0xC0000000);
	CCSR_SET_W(0xC48, 0x81D0001C);

#if SMPTARGET
	asm ("usr_init1_end:");
#endif
}

void usr_init2() {

	// Read SVR register
	asm ("mfspr %0, 1023" : "=r" (revision));
	revision = (revision & 0x000000FF) >> 4;

#if SMPTARGET
	/* only core 0 must initialize the IFC controller */
	asm("mfpir  7");
	asm("srwi  4, 7, 2");
	asm("andi. 5, 7, 1");
	asm("add   7, 4, 5");
	asm("cmpwi  7, %0" : : "i" (MASTER_CORE_ID));
	asm("bne  init_vectors");
#endif


	//##################################################################################
	//# IFC Controller Setup

	SET_GROUP_BASE(CCSRBAR + IFC_GROUP_OFFSET);

	// CS0 - NOR Flash, addr 0xE8000000, 128MB size, 16-bit NOR
	// CSPR_EXT
	CCSR_SET_W(0x00C, 0x00000000);
	// CSPR
	CCSR_SET_W(0x010, 0xE8000101);
	// AMASK
	CCSR_SET_W(0x0A0, 0xF8000000);
	// CSOR
	CCSR_SET_W(0x130, 0x0000000c);

	// IFC_FTIM0
	CCSR_SET_W(0x1C0, 0x10010020);
	// IFC_FTIM1
	CCSR_SET_W(0x1C4, 0x35001A13);
	// IFC_FTIM2
	CCSR_SET_W(0x1C8, 0x0138381C);
	// IFC_FTIM3
	CCSR_SET_W(0x1CC, 0x00000000);


	// CS2 - NAND Flash, addr 0xFF800000, 64k size, 8-bit NAND
	// CSPR_EXT
	CCSR_SET_W(0x024, 0x00000000);
	// CSPR
	CCSR_SET_W(0x028, 0xFF800083);
	// AMASK
	CCSR_SET_W(0x0B8, 0xFFFF0000);
	// CSOR
	CCSR_SET_W(0x148, 0x01082100);

	// IFC_FTIM0
	CCSR_SET_W(0x220, 0x0E18070A);
	// IFC_FTIM1
	CCSR_SET_W(0x224, 0x32390E18);
	// IFC_FTIM2
	CCSR_SET_W(0x228, 0x01E0501E);
	// IFC_FTIM3
	CCSR_SET_W(0x22C, 0x00000000);


	// CS3 - QIXIS,   addr 0xFFDF0000,   4k size,  8-bit, GPCM, Valid
	// CSPR_EXT
	CCSR_SET_W(0x030, 0x00000000);
	// CSPR
	CCSR_SET_W(0x034, 0xFFDF0085);
	// AMASK
	CCSR_SET_W(0x0C4, 0xFFFF0000);
	// CSOR
	CCSR_SET_W(0x154, 0x00000000);

	// IFC_FTIM0
	CCSR_SET_W(0x250, 0xE00E000E);
	// IFC_FTIM1
	CCSR_SET_W(0x254, 0x0E001F00);
	// IFC_FTIM2
	CCSR_SET_W(0x258, 0x0E00001F);
	// IFC_FTIM3
	CCSR_SET_W(0x25c, 0x00000000);

	//#################################################################################
	// eSPI Setup
	SET_GROUP_BASE(CCSRBAR + ESPI_GROUP_OFFSET);
	// ESPI_SPMODE
	CCSR_SET_W(0x000, 0x80000403);
	// ESPI_SPIM - catch all events
	CCSR_SET_W(0x008, 0x00000000);
	// ESPI_SPMODE0
	CCSR_SET_W(0x008, 0x30170008);


	//##################################################################################
	//# DDR Controllers Setup

	// Read sys_ver (board revision)
	asm ("lis 22, 0xffdf");
	asm ("ori 22, 22, 0x0001");
	asm ("lbz %0,0(22)" : "=r" (sys_ver));

	SET_GROUP_BASE(CCSRBAR + DDR1_GROUP_OFFSET);
	if (revision == 1)
	{
		//# DDR_SDRAM_CFG
		CCSR_SET_W(0x110, 0x67040000);
		//# CS0_BNDS
		CCSR_SET_W(0x0000, 0x0000007F);
		//# CS1_BNDS
		CCSR_SET_W(0x008, 0x00000000);
		//# CS0_CONFIG
		CCSR_SET_W(0x080, 0x80014302);
		//# CS1_CONFIG
		CCSR_SET_W(0x084, 0x00000000);
		//# CS0_CONFIG_2
		CCSR_SET_W(0x0c0, 0x00000000);
		//# TIMING_CFG_3
		CCSR_SET_W(0x100, 0x00071000);
		//# TIMING_CFG_0
		CCSR_SET_W(0x104, 0x50110004);
		//# TIMING_CFG_1
		CCSR_SET_W(0x108, 0xbbb58c46);
		//# TIMING_CFG_2
		CCSR_SET_W(0x10c, 0x0040c8d4);
		//# DDR_SDRAM_CFG_2
		CCSR_SET_W(0x114, 0x00401110);
		//# DDR_SDRAM_MODE
		CCSR_SET_W(0x118, 0x00441c70);
		//# DDR_SDRAM_MODE_2
		CCSR_SET_W(0x11c, 0x00180000);
		//# DDR_SDRAM_INTERVAL
		CCSR_SET_W(0x124, 0x18600100);
		//# DDR_DATA_INIT
		CCSR_SET_W(0x128, 0xdeadbeef);
		//# DDR_SDRAM_CLK_CNTL
		CCSR_SET_W(0x130, 0x02800000);
		//# DDR_INIT_ADDR
		CCSR_SET_W(0x148, 0x00000000);
		//# DDR_INIT_EXT_ADDR
		CCSR_SET_DUP_W(0x14c);
		//# TIMING_CFG_4
		CCSR_SET_W(0x160, 0x00000001);
		//# TIMING_CFG_5
		CCSR_SET_W(0x164, 0x04401400);
		//# DDR_ZQ_CNTL
		CCSR_SET_W(0x170, 0x89080600);
		//# DDR_WRLVL_CNTL
		CCSR_SET_W(0x174, 0x8675f608);
		//# DDR_WRLVL_CNTL_2
		CCSR_SET_W(0x190, 0x080a0a0c);
		//# DDR_WRLVL_CNTL_3
		CCSR_SET_W(0x194, 0x0c0d0e0a);
		//# DDRCDR_1
		CCSR_SET_W(0xb28, 0x80040000);
		//# DDRCDR_2
		CCSR_SET_W(0xb2c, 0x00000001);
		//# ERR_DISABLE - DISABLE
		CCSR_SET_W(0xe44, 0x0000000C);
		//# DDR1_DDR_SDRAM_MODE_3
		CCSR_SET_W(0x200, 0x00001c70);
		//# DDR1_DDR_SDRAM_MODE_4
		CCSR_SET_W(0x204, 0x00180000);
		//# DDR1_DDR_SDRAM_MODE_5
		CCSR_SET_W(0x208, 0x00001c70);
		//# DDR1_DDR_SDRAM_MODE_6
		CCSR_SET_W(0x20C, 0x00180000);
		//DDR1_DDR_SDRAM_MODE_7
		CCSR_SET_W(0x210, 0x00001c70);
		//# DDR1_DDR_SDRAM_MODE_8
		CCSR_SET_W(0x214, 0x00180000);
		//# DDR1_DDRDSR_1
		CCSR_SET_W(0xB20, 0x00008080);
		//# DDR1_DDRDSR_2
		CCSR_SET_W(0xB24, 0x80000000);
		//# ERR_SBE
		CCSR_SET_W(0xe58, 0x00000000);

		//# delay before enable
		asm ("lis	5, 0x0000");
		asm ("ori	5, 5, 0x0fff");
		asm ("mtspr 9 ,5");
		asm ("wait_loop1:");
		asm ("bc    16, 0, wait_loop1 ");

		//# A-004934
		CCSR_SET_W(0xF70, 0x30003000);

		//# DDR_SDRAM_CFG
		CCSR_SET_W(0x110, 0xE7040000);
		//	CCSR_SET_DUP_W(0x1110);

		//# wait for DRAM data initialization
		asm ("lis	5, 0x0000");
		asm ("ori	5, 5, 0x2ffd");
		asm ("mtspr 9 ,5");
		asm ("wait_loop2:");
		asm ("bc    16,0,wait_loop2 ");

		CCSR_SET_W(0xe44, 0x00000000);

		//# wait for D_INIT bits to clear
		asm ("xor 5, 5, 5");
		asm ("wait_loop3:");
		CCSR_GET_W(0x114);
		asm ("mr 5, 19");
		CCSR_GET_W(0x1114);
		asm ("or 5, 5, 19");
		asm ("rlwinm 5, 5, 0, 27, 27");
		asm ("cmpwi 5, 0x0010");
		asm ("bt eq, wait_loop3");
	}
	else
	{
		if (sys_ver == 0x13)
		{
			//# DDR_SDRAM_CFG
			CCSR_SET_W(0x110, 0x67040000);
			CCSR_SET_DUP_W(0x1110);
			CCSR_SET_DUP_W(0x2110);
			//# CS1_BNDS
			CCSR_SET_W(0x008, 0x00000000);
			CCSR_SET_DUP_W(0x1008);
			CCSR_SET_DUP_W(0x2008);
			//# CS0_CONFIG
			CCSR_SET_W(0x080, 0xaf014302);
			CCSR_SET_DUP_W(0x1080);
			CCSR_SET_DUP_W(0x2080);
			//# CS1_CONFIG
			CCSR_SET_W(0x084, 0x00000000);
			CCSR_SET_DUP_W(0x1084);
			CCSR_SET_DUP_W(0x2084);
			//# TIMING_CFG_3
			CCSR_SET_W(0x100, 0x01081000);
			CCSR_SET_DUP_W(0x1100);
			CCSR_SET_DUP_W(0x2100);
			//# TIMING_CFG_1
			CCSR_SET_W(0x108, 0xdfd9ee57);
			CCSR_SET_DUP_W(0x1108);
			CCSR_SET_DUP_W(0x2108);
			//# TIMING_CFG_2
			CCSR_SET_W(0x10c, 0x0048e8d8);
			CCSR_SET_DUP_W(0x110c);
			CCSR_SET_DUP_W(0x210c);
			//# DDR_SDRAM_CFG_2
			CCSR_SET_W(0x114, 0x00401110);
			CCSR_SET_DUP_W(0x1114);
			CCSR_SET_DUP_W(0x2114);
			//# DDR_WRLVL_CNTL_2
			CCSR_SET_W(0x190, 0x080a0a0c);
			CCSR_SET_DUP_W(0x1190);
			CCSR_SET_DUP_W(0x2190);
			//# DDR_WRLVL_CNTL_3
			CCSR_SET_W(0x194, 0x0e0e0f0a);
			CCSR_SET_DUP_W(0x1194);
			CCSR_SET_DUP_W(0x2194);
		}
		else
			{
			//# DDR_SDRAM_CFG
			CCSR_SET_W(0x110, 0x67044000);
			CCSR_SET_DUP_W(0x1110);
			CCSR_SET_DUP_W(0x2110);
			//# CS1_BNDS
			CCSR_SET_W(0x008, 0x0000007F);
			CCSR_SET_DUP_W(0x1008);
			CCSR_SET_DUP_W(0x2008);
			//# CS0_CONFIG
			CCSR_SET_W(0x080, 0xaf054402);
			CCSR_SET_DUP_W(0x1080);
			CCSR_SET_DUP_W(0x2080);
			//# CS1_CONFIG
			CCSR_SET_W(0x084, 0xaf004402);
			CCSR_SET_DUP_W(0x1084);
			CCSR_SET_DUP_W(0x2084);
			//# TIMING_CFG_3
			CCSR_SET_W(0x100, 0x020e1000);
			CCSR_SET_DUP_W(0x1100);
			CCSR_SET_DUP_W(0x2100);
			//# TIMING_CFG_1
			CCSR_SET_W(0x108, 0xd0d9be57);
			CCSR_SET_DUP_W(0x1108);
			CCSR_SET_DUP_W(0x2108);
			//# TIMING_CFG_2
			CCSR_SET_W(0x10c, 0x0048e8da);
			CCSR_SET_DUP_W(0x110c);
			CCSR_SET_DUP_W(0x210c);
			//# DDR_SDRAM_CFG_2
			CCSR_SET_W(0x114, 0x00401111);
			CCSR_SET_DUP_W(0x1114);
			CCSR_SET_DUP_W(0x2114);
			//# DDR_WRLVL_CNTL_2
			CCSR_SET_W(0x190, 0x090a0b0e);
			CCSR_SET_DUP_W(0x1190);
			CCSR_SET_DUP_W(0x2190);
			//# DDR_WRLVL_CNTL_3
			CCSR_SET_W(0x194, 0x0f11120c);
			CCSR_SET_DUP_W(0x1194);
			CCSR_SET_DUP_W(0x2194);
		}
		//# CS0_BNDS
		CCSR_SET_W(0x0000, 0x0000007F);
		CCSR_SET_DUP_W(0x1000);
		CCSR_SET_DUP_W(0x2000);
		//# CS0_CONFIG_2
		CCSR_SET_W(0x0c0, 0x00000000);
		CCSR_SET_DUP_W(0x10c0);
		CCSR_SET_DUP_W(0x20c0);
		//# TIMING_CFG_0
		CCSR_SET_W(0x104, 0x90110004);
		CCSR_SET_DUP_W(0x1104);
		CCSR_SET_DUP_W(0x2104);
		//# DDR_SDRAM_MODE
		CCSR_SET_W(0x118, 0x00441014);
		CCSR_SET_DUP_W(0x1118);
		CCSR_SET_DUP_W(0x2118);
		//# DDR_SDRAM_MODE_2
		CCSR_SET_W(0x11c, 0x00200000);
		CCSR_SET_DUP_W(0x111c);
		CCSR_SET_DUP_W(0x211c);
		//# DDR_SDRAM_INTERVAL
		CCSR_SET_W(0x124, 0x1c700100);
		CCSR_SET_DUP_W(0x1124);
		CCSR_SET_DUP_W(0x2124);
		//# DDR_DATA_INIT
		CCSR_SET_W(0x128, 0xdeadbeef);
		CCSR_SET_DUP_W(0x1128);
		CCSR_SET_DUP_W(0x2128);
		//# DDR_SDRAM_CLK_CNTL
		CCSR_SET_W(0x130, 0x02000000);
		CCSR_SET_DUP_W(0x1130);
		CCSR_SET_DUP_W(0x2130);
		//# DDR_INIT_ADDR
		CCSR_SET_W(0x148, 0x00000000);
		CCSR_SET_DUP_W(0x1148);
		CCSR_SET_DUP_W(0x2148);
		//# DDR_INIT_EXT_ADDR
		CCSR_SET_DUP_W(0x14c);
		CCSR_SET_DUP_W(0x114c);
		CCSR_SET_DUP_W(0x214c);
		//# TIMING_CFG_4
		CCSR_SET_W(0x160, 0x00000001);
		CCSR_SET_DUP_W(0x1160);
		CCSR_SET_DUP_W(0x2160);
		//# TIMING_CFG_5
		CCSR_SET_W(0x164, 0x05401400);
		CCSR_SET_DUP_W(0x1164);
		CCSR_SET_DUP_W(0x2164);
		//# DDR_ZQ_CNTL
		CCSR_SET_W(0x170, 0x89080600);
		CCSR_SET_DUP_W(0x1170);
		CCSR_SET_DUP_W(0x2170);
		//# DDR_WRLVL_CNTL
		CCSR_SET_W(0x174, 0x8675f608);
		CCSR_SET_DUP_W(0x1174);
		CCSR_SET_DUP_W(0x2174);
		//# DDRCDR_1
		CCSR_SET_W(0xb28, 0x80040000);
		CCSR_SET_DUP_W(0x1b28);
		CCSR_SET_DUP_W(0x2b28);
		//# DDRCDR_2
		CCSR_SET_W(0xb2c, 0x00000001);
		CCSR_SET_DUP_W(0x1b2c);
		CCSR_SET_DUP_W(0x2b2c);
		//# ERR_DISABLE - DISABLE
		CCSR_SET_W(0xe44, 0x0000000C);
		CCSR_SET_DUP_W(0x1e44);
		CCSR_SET_DUP_W(0x2e44);
		//# DDR1_DDR_SDRAM_MODE_3
		CCSR_SET_W(0x200, 0x00001014);
		CCSR_SET_DUP_W(0x1200);
		CCSR_SET_DUP_W(0x2200);
		//# DDR1_DDR_SDRAM_MODE_4
		CCSR_SET_W(0x204, 0x00200000);
		CCSR_SET_DUP_W(0x1204);
		CCSR_SET_DUP_W(0x2204);
		//# DDR1_DDR_SDRAM_MODE_5
		CCSR_SET_W(0x208, 0x00001014);
		CCSR_SET_DUP_W(0x1208);
		CCSR_SET_DUP_W(0x2208);
		//# DDR1_DDR_SDRAM_MODE_6
		CCSR_SET_W(0x20C, 0x00200000);
		CCSR_SET_DUP_W(0x120c);
		CCSR_SET_DUP_W(0x220c);
		//DDR1_DDR_SDRAM_MODE_7
		CCSR_SET_W(0x210, 0x00001014);
		CCSR_SET_DUP_W(0x1210);
		CCSR_SET_DUP_W(0x2210);
		//# DDR1_DDR_SDRAM_MODE_8
		CCSR_SET_W(0x214, 0x00200000);
		CCSR_SET_DUP_W(0x1214);
		CCSR_SET_DUP_W(0x2214);
		//# DDR1_DDRDSR_1
		CCSR_SET_W(0xB20, 0x00008080);
		CCSR_SET_DUP_W(0x1B20);
		CCSR_SET_DUP_W(0x2B20);
		//# DDR1_DDRDSR_2
		CCSR_SET_W(0xB24, 0x80000000);
		CCSR_SET_DUP_W(0x1B24);
		CCSR_SET_DUP_W(0x2B24);
		//# ERR_SBE
		CCSR_SET_W(0xe58, 0x00000000);
		CCSR_SET_DUP_W(0x1e58);
		CCSR_SET_DUP_W(0x2e58);

		//# delay before enable
		asm ("lis	5, 0x0000");
		asm ("ori	5, 5, 0x0fff");
		asm ("mtspr 9 ,5");
		asm ("wait_loop4:");
		asm ("bc    16, 0, wait_loop4 ");

		if (sys_ver == 0x13)
		{
			//# DDR_SDRAM_CFG
			CCSR_SET_W(0x110, 0xE7040000);
			CCSR_SET_DUP_W(0x1110);
			CCSR_SET_DUP_W(0x2110);
		}
		else
		{
			//# DDR_SDRAM_CFG
			CCSR_SET_W(0x110, 0xE7044000);
			CCSR_SET_DUP_W(0x1110);
			CCSR_SET_DUP_W(0x2110);
		}

		//# wait for DRAM data initialization
		asm ("lis	5, 0x0000");
		asm ("ori	5, 5, 0x2ffd");
		asm ("mtspr 9 ,5");
		asm ("wait_loop5:");
		asm ("bc    16,0,wait_loop5 ");

		CCSR_SET_W(0xe44, 0x00000000);
		CCSR_SET_DUP_W(0x1e44);
		CCSR_SET_DUP_W(0x2e44);

		//# wait for D_INIT bits to clear
		asm ("xor 5, 5, 5");
		asm ("wait_loop6:");
		CCSR_GET_W(0x114);
		asm ("mr 5, 19");
		CCSR_GET_W(0x1114);
		asm ("or 5, 5, 19");
		CCSR_GET_W(0x2114);
		asm ("or 5, 5, 19");
		asm ("rlwinm 5, 5, 0, 27, 27");
		asm ("cmpwi 5, 0x0010");
		asm ("bt eq, wait_loop6");

		// CCF_MCINTLV3R - enable 3-way interleaving
		// CCF_MCINTLV3R[27–31]: GRANULE_SIZE
		//	01010 1 KB granule size
		//	01100 4 KB granule size
		//	01101 8 KB granule size
		SET_GROUP_BASE(CCSRBAR + CCF_GROUP_OFFSET);
		CCSR_SET_W(0x004, 0x8000000D);
	}


	//##################################################################################
	//# Serial RapidIO workaround

	SET_GROUP_BASE(CCSRBAR + SRIO_GROUP_OFFSET1);
	CCSR_SET_W(0x0120, 0xFFFFFF00);
	CCSR_SET_DUP_W(0x0124);

	SET_GROUP_BASE(CCSRBAR + SRIO_GROUP_OFFSET2);
	CCSR_SET_W(0x0124, 0xFFFFFF00);
	CCSR_SET_DUP_W(0x01A4);

	SET_GROUP_BASE(CCSRBAR + SRIO_GROUP_OFFSET1);
	CCSR_SET_W(0x0644, 0x007E0037);
	CCSR_SET_DUP_W(0x0684);


	//##################################################################################
	//# Timers (TMR) workaround
	//# Reading TMR registers without activating the clock will cause memory reading errors.
	//# By default clock is disabled, timer modules will not get any toggling clock.

	SET_GROUP_BASE(CCSRBAR + TMR_GROUP_OFFSET);
	CCSR_SET_W(0x000, 0x00000001);
	CCSR_SET_DUP_W(0x004);
	CCSR_SET_DUP_W(0x008);
	CCSR_SET_DUP_W(0x00C);
	CCSR_SET_DUP_W(0x010);
	CCSR_SET_DUP_W(0x014);
	CCSR_SET_DUP_W(0x018);
	CCSR_SET_DUP_W(0x01C);

	if (revision == 2)
	{
		// A-006593
		SET_GROUP_BASE(CCSRBAR + CPC_GROUP_OFFSET);
		CCSR_SET_W(0xF00, 0x00000400);
		CCSR_SET_DUP_W(0x1F00);
		CCSR_SET_DUP_W(0x2F00);
	}


#if SMPTARGET
	asm("init_vectors: ");
#endif


	//##################################################################################
	//# Interrupt vectors initialization
	//
	//
	//# interrupt vectors in RAM at 0x00000000
	//writereg	IVPR 0x00000000 	# IVPR (default reset value)
	asm ("lis	5, 0x0000");
	asm ("ori	5, 5, 0x0000");
	asm ("mtspr 63, 5");
	//
	//# interrupt vector offset registers
	//writespr	400 0x00000100	# IVOR0 - critical input
	asm ("lis	5, 0x0000");
	asm ("ori	5, 5, 0x0100");
	asm ("mtspr 400, 5");
	//writespr	401 0x00000200	# IVOR1 - machine check
	asm ("lis	5, 0x0000");
	asm ("ori	5, 5, 0x0200");
	asm ("mtspr 401, 5");
	//writespr	402 0x00000300	# IVOR2 - data storage
	asm ("lis	5, 0x0000");
	asm ("ori	5, 5, 0x0300");
	asm ("mtspr 402, 5");
	//writespr	403 0x00000400	# IVOR3 - instruction storage
	asm ("lis	5, 0x0000");
	asm ("ori	5, 5, 0x0400");
	asm ("mtspr 403, 5");
	//writespr	404 0x00000500	# IVOR4 - external input
	asm ("lis	5, 0x0000");
	asm ("ori	5, 5, 0x0500");
	asm ("mtspr 404, 5");
	//writespr	405 0x00000600	# IVOR5 - alignment
	asm ("lis	5, 0x0000");
	asm ("ori	5, 5, 0x0600");
	asm ("mtspr 405, 5");
	//writespr	406 0x00000700	# IVOR6 - program
	asm ("lis	5, 0x0000");
	asm ("ori	5, 5, 0x0700");
	asm ("mtspr 406, 5");
	//writespr	408 0x00000c00	# IVOR8 - system call
	asm ("lis	5, 0x0000");
	asm ("ori	5, 5, 0x0c00");
	asm ("mtspr 408, 5");
	//writespr	410 0x00000900	# IVOR10 - decrementer
	asm ("lis	5, 0x0000");
	asm ("ori	5, 5, 0x0900");
	asm ("mtspr 410, 5");
	//writespr	411 0x00000f00	# IVOR11 - fixed-interval timer interrupt
	asm ("lis	5, 0x0000");
	asm ("ori	5, 5, 0x0f00");
	asm ("mtspr 411, 5");
	//writespr	412 0x00000b00	# IVOR12 - watchdog timer interrupt
	asm ("lis	5, 0x0000");
	asm ("ori	5, 5, 0x0b00");
	asm ("mtspr 412, 5");
	//writespr	413 0x00001100	# IVOR13 - data TLB errror
	asm ("lis	5, 0x0000");
	asm ("ori	5, 5, 0x1100");
	asm ("mtspr 413, 5");
	//writespr	414 0x00001000	# IVOR14 - instruction TLB error
	asm ("lis	5, 0x0000");
	asm ("ori	5, 5, 0x1000");
	asm ("mtspr 414, 5");
	//writespr	415 0x00001500	# IVOR15 - debug
	asm ("lis	5, 0x0000");
	asm ("ori	5, 5, 0x1500");
	asm ("mtspr 415, 5");
	//writespr	528 0x00001600	# IVOR32 - altivec unavailable
	asm ("lis	5, 0x0000");
	asm ("ori	5, 5, 0x1600");
	asm ("mtspr 528, 5");
	//writespr	529 0x00001700	# IVOR33 - altivec assist
	asm ("lis	5, 0x0000");
	asm ("ori	5, 5, 0x1700");
	asm ("mtspr 529, 5");
	//writespr	531 0x00001800	# IVOR35 - performance monitor
	asm ("lis	5, 0x0000");
	asm ("ori	5, 5, 0x1800");
	asm ("mtspr 531, 5");
	//writespr	532 0x00001900	# IVOR36 - processor doorbell
	asm ("lis	5, 0x0000");
	asm ("ori	5, 5, 0x1900");
	asm ("mtspr 532, 5");
	//writespr	533 0x00001a00	# IVOR37 - processor doorbell critical
	asm ("lis	5, 0x0000");
	asm ("ori	5, 5, 0x1a00");
	asm ("mtspr 533, 5");
	//writespr	434 0x00001b00	# IVOR40 - hypervisor system call
	asm ("lis	5, 0x0000");
	asm ("ori	5, 5, 0x1b00");
	asm ("mtspr 434, 5");
	//writespr	435 0x00001c00	# IVOR41 - hypervisor privilege
	asm ("lis	5, 0x0000");
	asm ("ori	5, 5, 0x1c00");
	asm ("mtspr 435, 5");
	//writespr	436 0x00001d00	# IVOR42 - LRAT error
	asm ("lis	5, 0x0000");
	asm ("ori	5, 5, 0x1d00");
	asm ("mtspr 436, 5");

	if (revision == 1)
	{
		//# A-004792, A-004809
		asm ("msync");
		asm ("isync");
		asm ("mfspr	5, 976");
		asm ("oris	5, 5, 0x0100");
		asm ("ori	5, 5, 0xC000");
		asm ("mtspr	976, 5");

		//# A-004786
		asm ("msync");
		asm ("isync");
		asm ("mfspr	5, 631");
		asm ("oris	5, 5, 0x8000");
		asm ("mtspr	631, 5");
		asm ("isync");
	}

	//
	//##################################################################################
	//# Debugger settings
	//

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	// Copy the exception vectors from ROM to RAM
	//
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	asm ("__copy_vectors:");

	asm ("xor 		3, 3, 3");
	asm ("oris		3, 3, gInterruptVectorTable@h");
	asm ("ori		3, 3, gInterruptVectorTable@l");
	asm ("subi		3, 3, 0x0004");

	asm ("xor		4, 4, 4");
	asm ("oris		4, 4, gInterruptVectorTableEnd@h");
	asm ("ori		4, 4, gInterruptVectorTableEnd@l");

	asm ("xor  		5, 5, 5");
	asm ("subi		5, 5, 0x0004");

	asm ("loop:");
	asm ("	lwzu	6, 4(3)");
	asm ("	stwu	6, 4(5)");

	asm ("	cmpw	3, 4");
	asm ("	blt		loop");

	asm ("msync");
	asm ("isync");
}

#ifdef SMPTARGET
void init_boot_space_translation() {

	SET_GROUP_BASE(CCSRBAR + LCC_GROUP_OFFSET);

	//LCC_BSTRH (Boot space translation register high)
	CCSR_SET_W(0x20, 0x0);

	//SET LCC_BSTRL (Boot space translation register low)
	SET_BOOT_SPACE_TRANSLATION_ADDRESS;

	//LCC_BSTAR (Boot space translation attribute register)
	CCSR_SET_W(0x28, 0x81f0000b);

	SET_GROUP_BASE(CCSRBAR + DCFG_GROUP_OFFSET);

	//set DCFG_BRR to 0x00000FFF
	CCSR_SET_W(0xe4, 0x00000FFF);

	SET_GROUP_BASE(CCSRBAR + RCPM_GROUP_OFFSET);

	//set PCTBENR to 0x00000FFF
	CCSR_SET_W(0x1A0, 0x00000FFF);
}
#endif
