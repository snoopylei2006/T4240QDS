##################################################################################
# Initialization file for T4240 QDS
# Clock Configuration:
#       CPU: 1666 MHz,	CCB:	666.6/733 MHz,
#       DDR: 1600/1867 MHz,	SYSCLK:	66.6 MHz
##################################################################################

# This initialization script assumes the whole available DDR range is split equally between the cores,
# so each core gets 64MB of memory. The remaining 2GB - 24*64MB = 512MB can be shared between cores.
# Platform initialization is done by the MASTER core only.
# The threads of a core share the same MMU & IVPR setup, so only the first thread does the initialization;
# The secondary thread assumes initialization for the primary thread has already been performed

# The constants below define the architecture and allow a generic initialization flow

variable NUM_CORES      	12
variable NUM_THREADS    	2
variable MASTER_CORE    	0
variable MAX_DDR        	0x80000000
variable PER_CORE_DDR   	[expr 1 << int(floor(log($MAX_DDR / ($NUM_CORES * $NUM_THREADS)) / log(2)))]
# GRANULE_SIZE for 3-way interleaving expressed in kilobytes
variable GRANULE_SIZE 	8

# Variable used to differentiate between the processor revisions
variable processor_revision	0

variable PIXISBAR 0xFFDF0000

# Utility procedures to retrieve the core and thread number based on the PIR definition below:

# Processor ID Register (PIR)
# Physical Core | Thread |   PIR Value
# ------------------------------------------
#        0      |    0   |  0x0000_0000
#        0      |    1   |  0x0000_0001
#        1      |    0   |  0x0000_0008
#        1      |    1   |  0x0000_0009
#        2      |    0   |  0x0000_0010
#        2      |    1   |  0x0000_0011
#        3      |    0   |  0x0000_0018
#        3      |    1   |  0x0000_0019
#        4      |    0   |  0x0000_0020
#        4      |    1   |  0x0000_0021
#		 .....
#        11     |    0   |  0x0000_0058
#        11     |    1   |  0x0000_0059

proc CORE {PIR} {
	return [expr { $PIR >> 3 }]
}

proc THREAD {PIR} {
	return [expr { $PIR % 8 }]
}

# This proc assumes that CCSR memory is mapped to physical 0x00_FE000000 address
proc CCSR_ADDR {offset} {
	return "i:0x00FE[format %06X $offset]"
}

proc PIXIS {reg_off} {
	global PIXISBAR

	return "i:0x[format %x [expr {$PIXISBAR + $reg_off}]]"
}

proc logToBaseTwo {value} {
	return [expr {log($value) / [expr log(2)]}]
}

# Platform resources
proc init_platform {} {
	global processor_revision
	global GRANULE_SIZE
	global PIXISBAR

	if {$processor_revision == 1} {
		# IFC WA
		# IFC_FTIM0
		mem [CCSR_ADDR 0x1241c0] = 0xf03f3f3f
		# IFC_FTIM1
		mem [CCSR_ADDR 0x1241c4] = 0xff003f3f
		# CSPR
		mem [CCSR_ADDR 0x124010] = 0x00000101
		# CSOR
		mem [CCSR_ADDR 0x124130] = 0x0000000c
	}
	
	##################################################################################
	# Local Access Windows Setup

	global MAX_DDR	
	set DDR_LAW_SIZE [expr {[format %02x [expr {int(ceil(log($MAX_DDR - 1) / log(2)) - 1)}]]}]

	## LAW0 to DDR
	# LAWBARH
	mem [CCSR_ADDR 0x000C00] = 0x00000000
	# LAWBARL
	mem [CCSR_ADDR 0x000C04] = 0x00000000
	# LAWAR
	if {$processor_revision == 1} {
		# Memory Complex 1
		mem [CCSR_ADDR 0x000C08] = 0x810000${DDR_LAW_SIZE}
	} else {
		# Interleaved Memory Complex 1-3
		mem [CCSR_ADDR 0x000C08] = 0x817000${DDR_LAW_SIZE}
	}

	## LAW1 to IFC- QIXIS
	# LAWBARH
	mem [CCSR_ADDR 0x000C10] = 0x00000000
	# LAWBARL
	mem [CCSR_ADDR 0x000C14] = $PIXISBAR
	# LAWAR
	mem [CCSR_ADDR 0x000C18] = 0x81F0000B

	## LAW2 to IFC - NOR
	# LAWBARH
	mem [CCSR_ADDR 0x000C20] = 0x00000000
	# LAWBARL
	mem [CCSR_ADDR 0x000C24] = 0xE8000000
	# LAWAR
	mem [CCSR_ADDR 0x000C28] = 0x81f0001a

	## LAW3 to IFC - NAND
	# LAWBARH
	mem [CCSR_ADDR 0x000C30] = 0x00000000
	# LAWBARL
	mem [CCSR_ADDR 0x000C34] = 0xFF800000
	# LAWAR
	mem [CCSR_ADDR 0x000C38] = 0x81f00013
		
	## LAW4 to DCSR
	# LAWBARH
	mem [CCSR_ADDR 0x000C40] = 0x00000000
	# LAWBARL
	mem [CCSR_ADDR 0x000C44] = 0xC0000000
	# LAWAR
	mem [CCSR_ADDR 0x000C48] = 0x81D0001c

	##################################################################################
	# IFC Controller Setup

	set QIXIS_CS 	3
	# clear the other CSPRs to be able to read from QIXIS before the final configuration
	mem [CCSR_ADDR [expr 0x124010 + 0 * 0x0C]] = 0x00000000
	mem [CCSR_ADDR [expr 0x124010 + 1 * 0x0C]] = 0x00000000
	mem [CCSR_ADDR [expr 0x124010 + 2 * 0x0C]] = 0x00000000

	# QIXIS,   addr 0xFFDF0000,   4k size,  8-bit, GPCM, Valid 
	# CSPR_EXT
	mem [CCSR_ADDR [expr 0x12400C + $QIXIS_CS * 0x0C]] = 0x00000000
	# CSPR
	mem [CCSR_ADDR [expr 0x124010 + $QIXIS_CS * 0x0C]] = 0xFFDF0085
	# AMASK
	mem [CCSR_ADDR [expr 0x1240A0 + $QIXIS_CS * 0x0C]] = 0xFFFF0000
	# CSOR
	mem [CCSR_ADDR [expr 0x124130 + $QIXIS_CS * 0x0C]] = 0x00000000

	# IFC_FTIM0
	mem [CCSR_ADDR [expr 0x1241C0 + $QIXIS_CS * 0x30]] = 0xE00E000E
	# IFC_FTIM1
	mem [CCSR_ADDR [expr 0x1241C4 + $QIXIS_CS * 0x30]] = 0x0E001F00
	# IFC_FTIM2
	mem [CCSR_ADDR [expr 0x1241C8 + $QIXIS_CS * 0x30]] = 0x0E00001F
	# IFC_FTIM3
	mem [CCSR_ADDR [expr 0x1241CC + $QIXIS_CS * 0x30]] = 0x00000000

	# Now read BRDCFG0[LBMAP] and initialize the rest of the CSs accordingly
	if { [expr [mem [PIXIS 0x50] 8bit -np] & 0x8] } {
		set NOR_CS 		1
		set NAND_CS 	0
	} else {
		set NOR_CS 		0
		set NAND_CS 	2
	}

	# NOR Flash, addr 0xE8000000, 128MB size, 16-bit NOR
	# CSPR_EXT
	mem [CCSR_ADDR [expr 0x12400C + $NOR_CS * 0x0C]] = 0x00000000
	# CSPR
	mem [CCSR_ADDR [expr 0x124010 + $NOR_CS * 0x0C]] = 0xE8000101
	# AMASK
	mem [CCSR_ADDR [expr 0x1240A0 + $NOR_CS * 0x0C]] = 0xF8000000
	# CSOR
	mem [CCSR_ADDR [expr 0x124130 + $NOR_CS * 0x0C]] = 0x0000000c

	# IFC_FTIM0
	mem [CCSR_ADDR [expr 0x1241C0 + $NOR_CS * 0x30]] = 0x40050005
	# IFC_FTIM1
	mem [CCSR_ADDR [expr 0x1241C4 + $NOR_CS * 0x30]] = 0x35001A13
	# IFC_FTIM2
	mem [CCSR_ADDR [expr 0x1241C8 + $NOR_CS * 0x30]] = 0x0410381C
	# IFC_FTIM3
	mem [CCSR_ADDR [expr 0x1241CC + $NOR_CS * 0x30]] = 0x00000000


	# NAND Flash, addr 0xFF800000, 64k size, 8-bit NAND
	# CSPR_EXT
	mem [CCSR_ADDR [expr 0x12400C + $NAND_CS * 0x0C]] = 0x00000000
	# CSPR
	mem [CCSR_ADDR [expr 0x124010 + $NAND_CS * 0x0C]] = 0xFF800083
	# AMASK
	mem [CCSR_ADDR [expr 0x1240A0 + $NAND_CS * 0x0C]] = 0xFFFF0000
	# CSOR
	mem [CCSR_ADDR [expr 0x124130 + $NAND_CS * 0x0C]] = 0x01082100

	# IFC_FTIM0
	mem [CCSR_ADDR [expr 0x1241C0 + $NAND_CS * 0x30]] = 0x0E18070A
	# IFC_FTIM1
	mem [CCSR_ADDR [expr 0x1241C4 + $NAND_CS * 0x30]] = 0x32390E18
	# IFC_FTIM2
	mem [CCSR_ADDR [expr 0x1241C8 + $NAND_CS * 0x30]] = 0x01E0501E
	# IFC_FTIM3
	mem [CCSR_ADDR [expr 0x1241CC + $NAND_CS * 0x30]] = 0x00000000


	##################################################################################
	# eSPI Setup
	# ESPI_SPMODE 
	mem [CCSR_ADDR 0x110000] = 0x80000403
	# ESPI_SPIM - catch all events
	mem [CCSR_ADDR 0x110008] = 0x00000000
	# ESPI_SPMODE0
	mem [CCSR_ADDR 0x110020] = 0x30170008


	##################################################################################
	# DDR Controllers Setup
	
	set SYS_VER [mem [PIXIS 0x01] 8bit -np]

	if {$processor_revision == 1} {
		# DDR_SDRAM_CFG
		mem [CCSR_ADDR 0x8110] = 0x67040000
		# CS0_BNDS
		mem [CCSR_ADDR 0x8000] = 0x0000007F
		# CS1_BNDS
		mem [CCSR_ADDR 0x8008] = 0x00000000
		# CS0_CONFIG
		mem [CCSR_ADDR 0x8080] = 0x80014302
		# CS1_CONFIG
		mem [CCSR_ADDR 0x8084] = 0x00000000
		# CS0_CONFIG_2
		mem [CCSR_ADDR 0x80C0] = 0x00000000
		# TIMING_CFG_0
		mem [CCSR_ADDR 0x8104] = 0x50110004
		# TIMING_CFG_1
		mem [CCSR_ADDR 0x8108] = 0xbbb58c46
		# TIMING_CFG_2
		mem [CCSR_ADDR 0x810C] = 0x0040c8d4
		# TIMING_CFG_3
		mem [CCSR_ADDR 0x8100] = 0x00071000
		# DDR_SDRAM_CFG_2
		mem [CCSR_ADDR 0x8114] = 0x00401110 
		# DDR_SDRAM_MODE
		mem [CCSR_ADDR 0x8118] = 0x00441c70
		# DDR_SDRAM_MODE_2
		mem [CCSR_ADDR 0x811C] = 0x00180000
		# DDR_SDRAM_INTERVAL
		mem [CCSR_ADDR 0x8124] = 0x18600100
		# DDR_DATA_INIT
		mem [CCSR_ADDR 0x8128] = 0xDEADBEEF
		# DDR_SDRAM_CLK_CNTL
		mem [CCSR_ADDR 0x8130] = 0x02800000
		# DDR_INIT_ADDR
		mem [CCSR_ADDR 0x8148] = 0x00000000
		# DDR_INIT_EXT_ADDRESS
		mem [CCSR_ADDR 0x814C] = 0x00000000
		# TIMING_CFG_4
		mem [CCSR_ADDR 0x8160] = 0x00000001
		# TIMING_CFG_5
		mem [CCSR_ADDR 0x8164] = 0x04401400
		# DDR_ZQ_CNTL
		mem [CCSR_ADDR 0x8170] = 0x89080600 
		# DDR_WRLVL_CNTL
		mem [CCSR_ADDR 0x8174] = 0x8675f608
		# DDR_WRLVL_CNTL_2
		mem [CCSR_ADDR 0x8190] = 0x080a0a0c 
		# DDR_WRLVL_CNTL_3
		mem [CCSR_ADDR 0x8194] = 0x0c0d0e0a 
		# DDR1_DDR_SDRAM_MODE_3
		mem [CCSR_ADDR 0x8200] = 0x00001c70
		# DDR1_DDR_SDRAM_MODE_4
		mem [CCSR_ADDR 0x8204] = 0x00180000
		# DDR1_DDR_SDRAM_MODE_5
		mem [CCSR_ADDR 0x8208] = 0x00001c70
		# DDR1_DDR_SDRAM_MODE_6
		mem [CCSR_ADDR 0x820C] = 0x00180000
		# DDR1_DDR_SDRAM_MODE_7
		mem [CCSR_ADDR 0x8210] = 0x00001c70
		# DDR1_DDR_SDRAM_MODE_8
		mem [CCSR_ADDR 0x8214] = 0x00180000	
		# DDR1_DDRDSR_1
		mem [CCSR_ADDR 0x8B20] = 0x00008080
		# DDR1_DDRDSR_2
		mem [CCSR_ADDR 0x8B24] = 0x80000000	
		# DDRCDR_1
		mem [CCSR_ADDR 0x8B28] = 0x80040000
		# DDRCDR_2
		mem [CCSR_ADDR 0x8B2C] = 0x00000001
		# ERR_DISABLE - DISABLE
		mem [CCSR_ADDR 0x8E44] = 0x0000000C
		# ERR_SBE
		mem [CCSR_ADDR 0x8E58] = 0x00000000
		
		# WA for erratum A_004934 
		mem [CCSR_ADDR 0x8f70] = 0x30003000	
		
		wait 100
		# DDR_SDRAM_CFG
		mem [CCSR_ADDR 0x8110] = 0xE7040000
		wait 1000
		# ERR_DISABLE - ENABLE
		mem [CCSR_ADDR 0x8E44] = 0x00000000
	} else {
		# DDR1 Controller Setup
		if {$SYS_VER == 0x13} {
			# DDR1_DDR_SDRAM_CFG
			mem [CCSR_ADDR 0x8110] = 0x67040000
			# DDR1_CS1_BNDS
			mem [CCSR_ADDR 0x8008] = 0x00000000
			# DDR1_CS0_CONFIG
			mem [CCSR_ADDR 0x8080] = 0xaf014302
			# DDR1_CS1_CONFIG
			mem [CCSR_ADDR 0x8084] = 0x00000000
			# DDR1_TIMING_CFG_1
			mem [CCSR_ADDR 0x8108] = 0xdfd9ee57
			# DDR1_TIMING_CFG_2
			mem [CCSR_ADDR 0x810C] = 0x0048e8d8
			# DDR1_TIMING_CFG_3
			mem [CCSR_ADDR 0x8100] = 0x01081000
			# DDR1_DDR_SDRAM_CFG_2
			mem [CCSR_ADDR 0x8114] = 0x00401110
			# DDR1_DDR_WRLVL_CNTL_2
			mem [CCSR_ADDR 0x8190] = 0x080a0a0c
			# DDR1_DDR_WRLVL_CNTL_3
			mem [CCSR_ADDR 0x8194] = 0x0e0e0f0a
		} else {
			# DDR1_DDR_SDRAM_CFG
			mem [CCSR_ADDR 0x8110] = 0x67044000
			# DDR1_CS1_BNDS
			mem [CCSR_ADDR 0x8008] = 0x0000007F
			# DDR1_CS0_CONFIG
			mem [CCSR_ADDR 0x8080] = 0xaf054402
			# DDR1_CS1_CONFIG
			mem [CCSR_ADDR 0x8084] = 0xaf004402
			# DDR1_TIMING_CFG_1
			mem [CCSR_ADDR 0x8108] = 0xd0d9be57
			# DDR1_TIMING_CFG_2
			mem [CCSR_ADDR 0x810C] = 0x0048e8da
			# DDR1_TIMING_CFG_3
			mem [CCSR_ADDR 0x8100] = 0x020e1000
			# DDR1_DDR_SDRAM_CFG_2
			mem [CCSR_ADDR 0x8114] = 0x00401111
			# DDR1_DDR_WRLVL_CNTL_2
			mem [CCSR_ADDR 0x8190] = 0x090a0b0e
			# DDR1_DDR_WRLVL_CNTL_3
			mem [CCSR_ADDR 0x8194] = 0x0f11120c
		}
		# DDR1_CS0_BNDS
		mem [CCSR_ADDR 0x8000] = 0x0000007F
		# DDR1_CS0_CONFIG_2
		mem [CCSR_ADDR 0x80C0] = 0x00000000
		# DDR1_TIMING_CFG_0
		mem [CCSR_ADDR 0x8104] = 0x90110004
		# DDR1_DDR_SDRAM_MODE
		mem [CCSR_ADDR 0x8118] = 0x00441014
		# DDR1_DDR_SDRAM_MODE_2
		mem [CCSR_ADDR 0x811C] = 0x00200000
		# DDR1_DDR_SDRAM_INTERVAL
		mem [CCSR_ADDR 0x8124] = 0x1c700100
		# DDR1_DDR_DATA_INIT
		mem [CCSR_ADDR 0x8128] = 0xDEADBEEF
		# DDR1_DDR_SDRAM_CLK_CNTL
		mem [CCSR_ADDR 0x8130] = 0x02000000
		# DDR1_DDR_INIT_ADDR
		mem [CCSR_ADDR 0x8148] = 0x00000000
		# DDR1_DDR_INIT_EXT_ADDRESS
		mem [CCSR_ADDR 0x814C] = 0x00000000
		# DDR1_TIMING_CFG_4
		mem [CCSR_ADDR 0x8160] = 0x00000001
		# DDR1_TIMING_CFG_5
		mem [CCSR_ADDR 0x8164] = 0x05401400
		# DDR1_DDR_ZQ_CNTL
		mem [CCSR_ADDR 0x8170] = 0x89080600
		# DDR1_DDR_WRLVL_CNTL
		mem [CCSR_ADDR 0x8174] = 0x8675f608
		# DDR1_DDR_SDRAM_MODE_3
		mem [CCSR_ADDR 0x8200] = 0x00001014
		# DDR1_DDR_SDRAM_MODE_4
		mem [CCSR_ADDR 0x8204] = 0x00200000
		# DDR1_DDR_SDRAM_MODE_5
		mem [CCSR_ADDR 0x8208] = 0x00001014
		# DDR1_DDR_SDRAM_MODE_6
		mem [CCSR_ADDR 0x820C] = 0x00200000
		# DDR1_DDR_SDRAM_MODE_7
		mem [CCSR_ADDR 0x8210] = 0x00001014
		# DDR1_DDR_SDRAM_MODE_8
		mem [CCSR_ADDR 0x8214] = 0x00200000
		# DDR1_DDRDSR_1
		mem [CCSR_ADDR 0x8B20] = 0x00008080
		# DDR1_DDRDSR_2
		mem [CCSR_ADDR 0x8B24] = 0x80000000
		# DDR1_DDRCDR_1
		mem [CCSR_ADDR 0x8B28] = 0x80040000
		# DDRCDR_2
		mem [CCSR_ADDR 0x8B2C] = 0x00000001
		# DDR1_ERR_DISABLE - DISABLE
		mem [CCSR_ADDR 0x8E44] = 0x0000000C
		# DDR1_ERR_SBE
		mem [CCSR_ADDR 0x8E58] = 0x00000000

		# DDR2 Controller Setup
		if {$SYS_VER == 0x13} {
			# DDR2_DDR_SDRAM_CFG
			mem [CCSR_ADDR 0x9110] = 0x67040000
			# DDR2_CS1_BNDS
			mem [CCSR_ADDR 0x9008] = 0x00000000
			# DDR2_CS0_CONFIG
			mem [CCSR_ADDR 0x9080] = 0xaf014302
			# DDR2_CS1_CONFIG
			mem [CCSR_ADDR 0x9084] = 0x00000000
			# DDR2_TIMING_CFG_1
			mem [CCSR_ADDR 0x9108] = 0xdfd9ee57
			# DDR2_TIMING_CFG_2
			mem [CCSR_ADDR 0x910C] = 0x0048e8d8
			# DDR2_TIMING_CFG_3
			mem [CCSR_ADDR 0x9100] = 0x01081000
			# DDR2_DDR_SDRAM_CFG_2
			mem [CCSR_ADDR 0x9114] = 0x00401110
			# DDR2_DDR_WRLVL_CNTL_2
			mem [CCSR_ADDR 0x9190] = 0x080a0a0c
			# DDR2_DDR_WRLVL_CNTL_3
			mem [CCSR_ADDR 0x9194] = 0x0e0e0f0a
		} else {
			# DDR2_DDR_SDRAM_CFG
			mem [CCSR_ADDR 0x9110] = 0x67044000
			# DDR2_CS1_BNDS
			mem [CCSR_ADDR 0x9008] = 0x0000007F
			# DDR2_CS0_CONFIG
			mem [CCSR_ADDR 0x9080] = 0xaf054402
			# DDR2_CS1_CONFIG
			mem [CCSR_ADDR 0x9084] = 0xaf004402
			# DDR2_TIMING_CFG_1
			mem [CCSR_ADDR 0x9108] = 0xd0d9be57
			# DDR2_TIMING_CFG_2
			mem [CCSR_ADDR 0x910C] = 0x0048e8da
			# DDR2_TIMING_CFG_3
			mem [CCSR_ADDR 0x9100] = 0x020e1000
			# DDR2_DDR_SDRAM_CFG_2
			mem [CCSR_ADDR 0x9114] = 0x00401111
			# DDR2_DDR_WRLVL_CNTL_2
			mem [CCSR_ADDR 0x9190] = 0x090a0b0e
			# DDR2_DDR_WRLVL_CNTL_3
			mem [CCSR_ADDR 0x9194] = 0x0f11120c
		}
		# DDR2_CS0_BNDS
		mem [CCSR_ADDR 0x9000] = 0x0000007F
		# DDR2_CS0_CONFIG_2
		mem [CCSR_ADDR 0x90C0] = 0x00000000
		# DDR2_TIMING_CFG_0
		mem [CCSR_ADDR 0x9104] = 0x90110004
		# DDR2_DDR_SDRAM_MODE
		mem [CCSR_ADDR 0x9118] = 0x00441014
		# DDR2_DDR_SDRAM_MODE_2
		mem [CCSR_ADDR 0x911C] = 0x00200000
		# DDR2_DDR_SDRAM_INTERVAL
		mem [CCSR_ADDR 0x9124] = 0x1c700100
		# DDR2_DDR_DATA_INIT
		mem [CCSR_ADDR 0x9128] = 0xDEADBEEF
		# DDR2_DDR_SDRAM_CLK_CNTL
		mem [CCSR_ADDR 0x9130] = 0x02000000
		# DDR2_DDR_INIT_ADDR
		mem [CCSR_ADDR 0x9148] = 0x00000000
		# DDR2_DDR_INIT_EXT_ADDRESS
		mem [CCSR_ADDR 0x914C] = 0x00000000
		# DDR2_TIMING_CFG_4
		mem [CCSR_ADDR 0x9160] = 0x00000001
		# DDR2_TIMING_CFG_5
		mem [CCSR_ADDR 0x9164] = 0x05401400
		# DDR2_DDR_ZQ_CNTL
		mem [CCSR_ADDR 0x9170] = 0x89080600
		# DDR2_DDR_WRLVL_CNTL
		mem [CCSR_ADDR 0x9174] = 0x8675f608
		# DDR2_DDR_SDRAM_MODE_3
		mem [CCSR_ADDR 0x9200] = 0x00001014
		# DDR2_DDR_SDRAM_MODE_4
		mem [CCSR_ADDR 0x9204] = 0x00200000
		# DDR2_DDR_SDRAM_MODE_5
		mem [CCSR_ADDR 0x9208] = 0x00001014
		# DDR2_DDR_SDRAM_MODE_6
		mem [CCSR_ADDR 0x920C] = 0x00200000
		# DDR2_DDR_SDRAM_MODE_7
		mem [CCSR_ADDR 0x9210] = 0x00001014
		# DDR2_DDR_SDRAM_MODE_8
		mem [CCSR_ADDR 0x9214] = 0x00200000
		# DDR2_DDRDSR_1
		mem [CCSR_ADDR 0x9B20] = 0x00008080
		# DDR2_DDRDSR_2
		mem [CCSR_ADDR 0x9B24] = 0x80000000
		# DDR2_DDRCDR_1
		mem [CCSR_ADDR 0x9B28] = 0x80040000
		# DDR2_DDRCDR_2
		mem [CCSR_ADDR 0x9B2C] = 0x00000001
		# DDR2_ERR_DISABLE - DISABLE
		mem [CCSR_ADDR 0x9E44] = 0x0000000C
		# DDR2_ERR_SBE
		mem [CCSR_ADDR 0x9E58] = 0x00000000

		# DDR3 Controller Setup
		if {$SYS_VER == 0x13} {
			# DDR3_DDR_SDRAM_CFG
			mem [CCSR_ADDR 0xa110] = 0x67040000
			# DDR3_CS1_BNDS
			mem [CCSR_ADDR 0xa008] = 0x00000000
			# DDR3_CS0_CONFIG
			mem [CCSR_ADDR 0xa080] = 0xaf014302
			# DDR3_CS1_CONFIG
			mem [CCSR_ADDR 0xa084] = 0x00000000
			# DDR3_TIMING_CFG_1
			mem [CCSR_ADDR 0xa108] = 0xdfd9ee57
			# DDR3_TIMING_CFG_2
			mem [CCSR_ADDR 0xa10C] = 0x0048e8d8
			# DDR3_TIMING_CFG_3
			mem [CCSR_ADDR 0xa100] = 0x01081000
			# DDR3_DDR_SDRAM_CFG_2
			mem [CCSR_ADDR 0xa114] = 0x00401110
			# DDR3_DDR_WRLVL_CNTL_2
			mem [CCSR_ADDR 0xa190] = 0x080a0a0c
			# DDR3_DDR_WRLVL_CNTL_3
			mem [CCSR_ADDR 0xa194] = 0x0e0e0f0a
		} else {
			# DDR3_DDR_SDRAM_CFG
			mem [CCSR_ADDR 0xa110] = 0x67044000
			# DDR3_CS1_BNDS
			mem [CCSR_ADDR 0xa008] = 0x0000007F
			# DDR3_CS0_CONFIG
			mem [CCSR_ADDR 0xa080] = 0xaf054402
			# DDR3_CS1_CONFIG
			mem [CCSR_ADDR 0xa084] = 0xaf004402
			# DDR3_TIMING_CFG_1
			mem [CCSR_ADDR 0xa108] = 0xd0d9be57
			# DDR3_TIMING_CFG_2
			mem [CCSR_ADDR 0xa10C] = 0x0048e8da
			# DDR3_TIMING_CFG_3
			mem [CCSR_ADDR 0xa100] = 0x020e1000
			# DDR3_DDR_SDRAM_CFG_2
			mem [CCSR_ADDR 0xa114] = 0x00401111
			# DDR3_DDR_WRLVL_CNTL_2
			mem [CCSR_ADDR 0xa190] = 0x090a0b0e
			# DDR3_DDR_WRLVL_CNTL_3
			mem [CCSR_ADDR 0xa194] = 0x0f11120c
		}
		# DDR3_CS0_BNDS
		mem [CCSR_ADDR 0xa000] = 0x0000007F
		# DDR3_CS0_CONFIG_2
		mem [CCSR_ADDR 0xa0C0] = 0x00000000
		# DDR3_TIMING_CFG_0
		mem [CCSR_ADDR 0xa104] = 0x90110004
		# DDR3_DDR_SDRAM_MODE
		mem [CCSR_ADDR 0xa118] = 0x00441014
		# DDR3_DDR_SDRAM_MODE_2
		mem [CCSR_ADDR 0xa11C] = 0x00200000
		# DDR3_DDR_SDRAM_INTERVAL
		mem [CCSR_ADDR 0xa124] = 0x1c700100
		# DDR3_DDR_DATA_INIT
		mem [CCSR_ADDR 0xa128] = 0xDEADBEEF
		# DDR3_DDR_SDRAM_CLK_CNTL
		mem [CCSR_ADDR 0xa130] = 0x02000000
		# DDR3_DDR_INIT_ADDR
		mem [CCSR_ADDR 0xa148] = 0x00000000
		# DDR3_DDR_INIT_EXT_ADDRESS
		mem [CCSR_ADDR 0xa14C] = 0x00000000
		# DDR3_TIMING_CFG_4
		mem [CCSR_ADDR 0xa160] = 0x00000001
		# DDR3_TIMING_CFG_5
		mem [CCSR_ADDR 0xa164] = 0x05401400
		# DDR3_DDR_ZQ_CNTL
		mem [CCSR_ADDR 0xa170] = 0x89080600
		# DDR3_DDR_WRLVL_CNTL
		mem [CCSR_ADDR 0xa174] = 0x8675f608
		# DDR3_DDR_SDRAM_MODE_3
		mem [CCSR_ADDR 0xa200] = 0x00001014
		# DDR3_DDR_SDRAM_MODE_4
		mem [CCSR_ADDR 0xa204] = 0x00200000
		# DDR3_DDR_SDRAM_MODE_5
		mem [CCSR_ADDR 0xa208] = 0x00001014
		# DDR3_DDR_SDRAM_MODE_6
		mem [CCSR_ADDR 0xa20C] = 0x00200000
		# DDR3_DDR_SDRAM_MODE_7
		mem [CCSR_ADDR 0xa210] = 0x00001014
		# DDR3_DDR_SDRAM_MODE_8
		mem [CCSR_ADDR 0xa214] = 0x00200000
		# DDR3_DDRDSR_1
		mem [CCSR_ADDR 0xaB20] = 0x00008080
		# DDR3_DDRDSR_2
		mem [CCSR_ADDR 0xaB24] = 0x80000000
		# DDR3_DDRCDR_1
		mem [CCSR_ADDR 0xaB28] = 0x80040000
		# DDR3_DDRCDR_2
		mem [CCSR_ADDR 0xaB2C] = 0x00000001
		# DDR3_ERR_DISABLE - DISABLE
		mem [CCSR_ADDR 0xaE44] = 0x0000000C
		# DDR3_ERR_SBE
		mem [CCSR_ADDR 0xaE58] = 0x00000000

		wait 100
		if {$SYS_VER == 0x13} {
			# DDR1_DDR_SDRAM_CFG
			mem [CCSR_ADDR 0x8110] = 0xE7040000
			# DDR2_DDR_SDRAM_CFG
			mem [CCSR_ADDR 0x9110] = 0xE7040000
			# DDR3_DDR_SDRAM_CFG
			mem [CCSR_ADDR 0xa110] = 0xE7040000
		} else {
			# DDR1_DDR_SDRAM_CFG
			mem [CCSR_ADDR 0x8110] = 0xE7044000
			# DDR2_DDR_SDRAM_CFG
			mem [CCSR_ADDR 0x9110] = 0xE7044000
			# DDR3_DDR_SDRAM_CFG
			mem [CCSR_ADDR 0xa110] = 0xE7044000
		}
		wait 1000

		# DDR1_ERR_DISABLE - ENABLE
		mem [CCSR_ADDR 0x8E44] = 0x00000000
		# DDR2_ERR_DISABLE - ENABLE
		mem [CCSR_ADDR 0x9E44] = 0x00000000
		# DDR3_ERR_DISABLE - ENABLE
		mem [CCSR_ADDR 0xaE44] = 0x00000000

		# CCF_MCINTLV3R - enable 3-way interleaving
		# CCF_MCINTLV3R[27–31]: GRANULE_SIZE
		#	01010 1 KB granule size
		#	01100 4 KB granule size
		#	01101 8 KB granule size
		mem [CCSR_ADDR 0x18004] = 0x800000[format %02x [format %.0f [expr 10 + [logToBaseTwo $GRANULE_SIZE]]]]
	}

	##################################################################################
	# Serial RapidIO workaround
	# Enable timeouts such that cores can be stopped succesfully

	# set timers to max values
	# SRIO_PLTOCCSR
	mem [CCSR_ADDR 0xC0120] = 0xFFFFFF00
	# SRIO_PRTOCCSR
	mem [CCSR_ADDR 0xC0124] = 0xFFFFFF00

	# SRIO_P1LOPTTLCR
	mem [CCSR_ADDR 0xD0124] = 0xFFFFFF00
	# SRIO_P2LOPTTLCR
	mem [CCSR_ADDR 0xD01A4] = 0xFFFFFF00

	# set all bits
	# SRIO_P1ERECSR
	mem [CCSR_ADDR 0xC0644] = 0x007E0037
	# SRIO_P2ERECSR
	mem [CCSR_ADDR 0xC0684] = 0x007E0037


	##################################################################################
	# Timers (TMR) workaround
	# Reading TMR registers without activating the clock will cause memory reading errors.
	# By default clock is disabled, timer modules will not get any toggling clock.

	# STMR_CTRL_0
	mem [CCSR_ADDR 0x8F3000] = 0x00000001
	# STMR_CTRL_1
	mem [CCSR_ADDR 0x8F3004] = 0x00000001
	# STMR_CTRL_2
	mem [CCSR_ADDR 0x8F3008] = 0x00000001
	# STMR_CTRL_3
	mem [CCSR_ADDR 0x8F300C] = 0x00000001
	# STMR_CTRL_4
	mem [CCSR_ADDR 0x8F3010] = 0x00000001
	# STMR_CTRL_5
	mem [CCSR_ADDR 0x8F3014] = 0x00000001
	# STMR_CTRL_6
	mem [CCSR_ADDR 0x8F3018] = 0x00000001
	# STMR_CTRL_7
	mem [CCSR_ADDR 0x8F301C] = 0x00000001
	
	# set DCSRCR
	mem [CCSR_ADDR 0x0E0704] = 0x00000003
	
	if {$processor_revision == 2} { 
		# A-006593
		mem [CCSR_ADDR 0x010f00] = 0x[format %x [expr [mem [CCSR_ADDR 0x010f00] -np] | 0x00000400]]
		mem [CCSR_ADDR 0x011f00] = 0x[format %x [expr [mem [CCSR_ADDR 0x011f00] -np] | 0x00000400]]
		mem [CCSR_ADDR 0x012f00] = 0x[format %x [expr [mem [CCSR_ADDR 0x012f00] -np] | 0x00000400]]
	}
}

# Shared resources
proc init_core {PIR} {
	global NUM_CORES
	global NUM_THREADS
	global MAX_DDR
	global PER_CORE_DDR
	global MASTER_CORE
	global processor_revision

	##################################################################################
	# Enable cores
	# DCFG_BRRL
	set BRRL [mem [CCSR_ADDR 0x0E00E4] %x -np]	
	mem [CCSR_ADDR 0x0E00E4] = 0x[format %x [expr {$BRRL | (1 << [CORE $PIR])}]]

	variable SPR_GROUP "e6500 Special Purpose Registers/"
	variable CAM_GROUP "regPPCTLB1/"

	##################################################################################
	#	
	#	Memory Map
	#
	#   0x00000000  0x7FFFFFFF  TLB1_2 DDR       2048M
	#   0xC0000000  0xDFFFFFFF  TLB1_6 DCSR       512M
	#   0xE8000000  0xEFFFFFFF  TLB1_4 NOR        128M
	#   0xFE000000  0xFEFFFFFF  TLB1_1 CCSR Space  16M
	#   0xFF800000  0xFF8FFFFF  TLB1_5 NAND         1M
	#   0xFFDF0000  0xFFDF0FFF  TLB1_3 QIXIS        4k

	##################################################################################
	# MMU initialization
	#

	set CCSR_EPN 000000[string range [CCSR_ADDR 1] 4 14]
	set CCSR_RPN [string range [CCSR_ADDR 0] 4 14]	
	set DDR_TLB_SIZE [expr {[format %02x [expr {int(ceil(log($MAX_DDR / 1024) / log(2)))} << 3]]}]

	# define 16MB TLB entry  1 : 0xFE000000 - 0xFEFFFFFF for CCSR    cache inhibited, guarded
	reg ${CAM_GROUP}L2MMU_CAM1  = 0x7000000A1C080000000000${CCSR_RPN}${CCSR_EPN}
		
	# define MAX_DDR TLB entry  2 : 0x00000000 - 0x7FFFFFFF for DDR     cache-inhibited, M
	reg ${CAM_GROUP}L2MMU_CAM2  = 0x${DDR_TLB_SIZE}00000C1C08000000000000000000000000000000000001

	# define   4k TLB entry  3 : 0xFFDF0000 - 0xFFDF0FFF for QIXIS   cache-inhibited, guarded
	reg ${CAM_GROUP}L2MMU_CAM3  = 0x1000000A1C08000000000000FFDF000000000000FFDF0001

	# define 256M TLB entry  4 : 0xE0000000 - 0xEFFFFFFF for NOR   cache-inhibited, guarded
	reg ${CAM_GROUP}L2MMU_CAM4  = 0x9000000A1C08000000000000E000000000000000E0000001

	# define   1M TLB entry  5 : 0xFF800000 - 0xFF8FFFFF for NAND   cache-inhibited, guarded
	reg ${CAM_GROUP}L2MMU_CAM5  = 0x5000000A1C08000000000000FF80000000000000FF800001

	# define 512M TLB entry  6 : 0xC0000000 - 0xDFFFFFFF for DCSR   cache-inhibited, guarded
	reg ${CAM_GROUP}L2MMU_CAM6  = 0x9800000A1C08000000000000C000000000000000C0000001

	##################################################################################

	# init platform only on the master core
	if { [CORE $PIR] == $MASTER_CORE } {
		   init_platform
	}

	##################################################################################
	# interrupt vectors initialization

	###
	# interrupt vectors in RAM at PER_CORE_DDR  * (Core * NUM_THREADS + Thread)
	#
	set Ret [catch {evaluate __start__SMP}]
	if {$Ret} {
		variable IVPR_ADDR [expr {([CORE $PIR] * $NUM_THREADS + [THREAD $PIR]) * $PER_CORE_DDR}]
	} else {
		variable IVPR_ADDR 0x0
	}
	# IVPR	
	reg ${SPR_GROUP}IVPR = 0x[format %016x $IVPR_ADDR]

	# interrupt vector offset registers 
	# IVOR0 - critical input
	reg ${SPR_GROUP}IVOR0 = 0x00000100	
	# IVOR1 - machine check
	reg ${SPR_GROUP}IVOR1 = 0x00000200	
	# IVOR2 - data storage
	reg ${SPR_GROUP}IVOR2 = 0x00000300
	# IVOR3 - instruction storage	
	reg ${SPR_GROUP}IVOR3 = 0x00000400	
	# IVOR4 - external input
	reg ${SPR_GROUP}IVOR4 = 0x00000500	
	# IVOR5 - alignment
	reg ${SPR_GROUP}IVOR5 = 0x00000600	
	# IVOR6 - program
	reg ${SPR_GROUP}IVOR6 = 0x00000700
	# IVOR7 - Floating point unavailable
	reg ${SPR_GROUP}IVOR7 = 0x00000800
	# IVOR8 - system call
	reg ${SPR_GROUP}IVOR8 = 0x00000c00	
	# IVOR10 - decrementer
	reg ${SPR_GROUP}IVOR10 = 0x00000900	
	# IVOR11 - fixed-interval timer interrupt
	reg ${SPR_GROUP}IVOR11 = 0x00000f00	
	# IVOR12 - watchdog timer interrupt
	reg ${SPR_GROUP}IVOR12 = 0x00000b00	
	# IVOR13 - data TLB errror
	reg ${SPR_GROUP}IVOR13 = 0x00001100
	# IVOR14 - instruction TLB error	
	reg ${SPR_GROUP}IVOR14 = 0x00001000
	# IVOR15 - debug	
	reg ${SPR_GROUP}IVOR15 = 0x00001500	
	# IVOR32 - altivec unavailable
	reg ${SPR_GROUP}IVOR32 = 0x00001600
	# IVOR33 - altivec assist
	reg ${SPR_GROUP}IVOR33 = 0x00001700
	# IVOR35 - performance monitor
	reg ${SPR_GROUP}IVOR35 = 0x00001800
	# IVOR36 - processor doorbell
	reg ${SPR_GROUP}IVOR36 = 0x00001900
	# IVOR37 - processor doorbell critical
	reg ${SPR_GROUP}IVOR37 = 0x00001a00
	# IVOR40 - hypervisor system call
	reg ${SPR_GROUP}IVOR40 = 0x00001b00
	# IVOR41 - hypervisor privilege
	reg ${SPR_GROUP}IVOR41 = 0x00001c00
	# IVOR42 - LRAT error
	reg ${SPR_GROUP}IVOR42 = 0x00001d00
	
	if {$processor_revision == 1} {
		# A-004792, A-004809
		reg ${SPR_GROUP}HDBCR0 = 0x[format %08x [expr {[reg ${SPR_GROUP}HDBCR0 %x -np] | 0x0100C000}]]

		# A-004786
		reg ${SPR_GROUP}HDBCR7 = 0x[format %08x [expr {[reg ${SPR_GROUP}HDBCR7 %x -np] | 0x80000000}]]	
	}	
	
	##################################################################################
	# debugger settings

	# infinite loop at program exception to prevent taking the exception again
	mem v:0x[format %x [expr { $IVPR_ADDR + 0x700 }]] = 0x48000000
}

# Private resources
proc init_thread {} {
	global processor_revision

	variable GPR_GROUP "General Purpose Registers/" 
	variable SPR_GROUP "e6500 Special Purpose Registers/"
	variable TMR_GROUP "Thread Management Registers/"

	variable SVR [reg ${SPR_GROUP}SVR %d -np]

	set processor_revision [expr ($SVR & 0x000000FF) >> 4];
	
	# set CM=1 = 64-bit to allow MMU configuration with high addresses
	reg ${SPR_GROUP}MSR = 0x80000000

	# prevent stack unwinding at entry_point/reset when stack pointer is not initialized
	reg ${GPR_GROUP}SP = 0x0000000F		

	# init shared resources only on the first thread
	variable PIR [reg ${SPR_GROUP}PIR %d -np]

	if {[expr {[THREAD $PIR] == 0} ] }  {
		init_core $PIR
	} else {
		variable TENSR [reg ${SPR_GROUP}TENSR %d -np]
		if {[expr ($TENSR & 0x3) != 0x3]} {

			reg ${SPR_GROUP}TENS = 0x00000003
		
			# workaround: the thread needs to run before being enabled
		
			# chose an address inside IV0R6 vector
			set B_ADDR [format %016x [expr { [reg ${SPR_GROUP}IVPR %d -np] + [reg ${SPR_GROUP}IVOR6 %d -np] + 4 }]]
			# save the original opcode
			set SAVED_OPCODE [format %08x [mem v:0x$B_ADDR -np]]
		
			# write a branch-to-self instruction at the chosen address
			mem v:0x$B_ADDR = 0x48000000
		
			# point the PC to it and run & stop		
			reg ${GPR_GROUP}PC = 0x$B_ADDR
			reg ${TMR_GROUP}INIA1 = 0x$B_ADDR
			config runcontrolsync off
			go
			wait 1
			config runcontrolsync on
			stop
		
			# restore the original opcode and PC
			mem v:0x$B_ADDR = $SAVED_OPCODE
			reg ${GPR_GROUP}PC = 0xFFFFFFFC		
		}
	}

	# enable floating point and AltiVec, CM=0 - 32-bit support; 64-bit will be enabled part of the startup code in the 64-bit projects
	reg ${SPR_GROUP}MSR = 0x02002000
}

proc envsetup {} {
	# Environment Setup
	radix x 
	config hexprefix 0x
	config MemIdentifier v
	config MemWidth 32 
	config MemAccess 32 
	config MemSwap off
}

#-------------------------------------------------------------------------------
# Main                                                                          
#-------------------------------------------------------------------------------

envsetup

init_thread

