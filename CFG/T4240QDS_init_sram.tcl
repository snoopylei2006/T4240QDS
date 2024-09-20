##################################################################################
# Initialization file for T4240 QDS
# Clock Configuration:
#       CPU: 1666 MHz,    CCB:   666.6/733 MHz,
#       SYSCLK:  66.6 MHz
################################################################################## 
# Platform initialization is done by the MASTER core only.
# The threads of a core share the same MMU & IVPR setup, so only the first thread does the initialization;
# The secondary thread assumes initialization for the primary thread has already been performed

# The constants below define the architecture and allow a generic initialization flow

variable NUM_CORES 		12
variable NUM_THREADS 	2
variable MASTER_CORE	0
variable SRAM_SIZE		0x00180000
variable PER_CORE_SRAM	[expr 1 << int(floor(log($SRAM_SIZE / (1)) / log(2)))]

# Variable used to differentiate between the processor revisions
variable processor_revision 0

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

# Platform resources
proc init_platform {} {
	global processor_revision

	if {$processor_revision == 1} {
		# IFC WA
		mem [CCSR_ADDR 0x1241c0] = 0xf03f3f3f
		mem [CCSR_ADDR 0x1241c4] = 0xff003f3f
		mem [CCSR_ADDR 0x124010] = 0x00000101
		mem [CCSR_ADDR 0x124130] = 0x0000000c
	}

	##################################################################################
	# Local Access Windows Setup
	
	## LAW1 to IFC- QIXIS
	# LAWBARH
	mem [CCSR_ADDR 0x000C10] = 0x00000000
	# LAWBARL
	mem [CCSR_ADDR 0x000C14] = 0xFFDF0000
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
	
	## LAW5 to SRAM1
	# LAWBARH
	mem [CCSR_ADDR 0x000C50] = 0x00000000
	# LAWBARL
	mem [CCSR_ADDR 0x000C54] = 0x00000000
	# LAWAR
	mem [CCSR_ADDR 0x000C58] = 0x81000012
	
	## LAW6 to SRAM2
	# LAWBARH
	mem [CCSR_ADDR 0x000C60] = 0x00000000
	# LAWBARL
	mem [CCSR_ADDR 0x000C64] = 0x00080000
	# LAWAR
	mem [CCSR_ADDR 0x000C68] = 0x81100012
	
	## LAW7 to SRAM3
	# LAWBARH
	mem [CCSR_ADDR 0x000C70] = 0x00000000
	# LAWBARL
	mem [CCSR_ADDR 0x000C74] = 0x00100000
	# LAWAR
	mem [CCSR_ADDR 0x000C78] = 0x81200012	
	
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
	if { [expr [mem i:0xFFDF0050 8bit -np] & 0x8] } {
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
	# configure internal CPC as SRAM at 0x00000000

	# CPC1 - 0x01_0000
	# CPC2 - 0x01_1000
	# CPC3 - 0x01_2000

	#CPCCSR0
	#0   0  00 0000 00 1  0   0000 0000 1   1 00 0000 0000       
	#DIS ECCdis        FI               FL LFC
	#1                  1                1   0

	#flush
	mem [CCSR_ADDR 0x010000] = 0x00200C00 
	#enable
	mem [CCSR_ADDR 0x010000] = 0x80200800

	#CPCEWCR0 - disable stashing
	mem [CCSR_ADDR 0x010010] = 0x00000000

	#CPCSRCR1 - SRBARU=0
	mem [CCSR_ADDR 0x010100] = 0x00000000
	
	#CPCSRCR0 - SRBARL=0, INTLVEN=0, SRAMSZ=4(16ways), SRAMEN=1
	mem [CCSR_ADDR 0x010104] = 0x00000009

	#CPCERRDIS 
	mem [CCSR_ADDR 0x010E44] = 0x00000080
	
	#CPCHDBCR0
	#enable SPEC_DIS from CPC1_CPCHDBCR0 
    mem [CCSR_ADDR 0x10F00] = 0x[format %x [expr {[mem [CCSR_ADDR 0x10F00] -np] | 0x8000000}]]

	
	#flush
	mem [CCSR_ADDR 0x011000] = 0x00200C00 
	#enable
	mem [CCSR_ADDR 0x011000] = 0x80200800

	#CPCEWCR0 - disable stashing
	mem [CCSR_ADDR 0x011010] = 0x00000000

	#CPCSRCR1 - SRBARU=0
	mem [CCSR_ADDR 0x011100] = 0x00000000
	
	#CPCSRCR0 - SRBARL=0x0008_0000, INTLVEN=0, SRAMSZ=4(16ways), SRAMEN=1
	mem [CCSR_ADDR 0x011104] = 0x00080009

	#CPCERRDIS 
	mem [CCSR_ADDR 0x011E44] = 0x00000080
	
	#CPCHDBCR0
	#enable SPEC_DIS from CPC2_CPCHDBCR0 
    mem [CCSR_ADDR 0x11F00] = 0x[format %x [expr {[mem [CCSR_ADDR 0x11F00] -np] | 0x8000000}]]

	
	#flush
	mem [CCSR_ADDR 0x012000] = 0x00200C00 
	#enable
	mem [CCSR_ADDR 0x012000] = 0x80200800

	#CPCEWCR0 - disable stashing
	mem [CCSR_ADDR 0x012010] = 0x00000000

	#CPCSRCR1 - SRBARU=0
	mem [CCSR_ADDR 0x012100] = 0x00000000
	
	#CPCSRCR0 - SRBARL=0x0008_0000, INTLVEN=0, SRAMSZ=4(16ways), SRAMEN=1
	mem [CCSR_ADDR 0x012104] = 0x00100009

	#CPCERRDIS 
	mem [CCSR_ADDR 0x012E44] = 0x00000080
	
	#CPCHDBCR0
	#enable SPEC_DIS from CPC3_CPCHDBCR0 
    mem [CCSR_ADDR 0x12F00] = 0x[format %x [expr {[mem [CCSR_ADDR 0x12F00] -np] | 0x8000000}]]

	
	##################################################################################
	# eSPI Setup
	
	# ESPI_SPMODE 
	mem [CCSR_ADDR 0x110000] = 0x80000403
	# ESPI_SPIM - catch all events
	mem [CCSR_ADDR 0x110008] = 0x00000000
	# ESPI_SPMODE0
	mem [CCSR_ADDR 0x110020] = 0x30170008

	
	###################################################################
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
	global MASTER_CORE
	global PER_CORE_SRAM
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
	#	0x00000000	0x001FFFFF	TLB1_1	SRAM 	  2M
	#   0xE8000000  0xEFFFFFFF  TLB1_4  NOR     128M
	#	0xFE000000	0xFEFFFFFF	TLB1_2	CCSR 	 16M
	#   0xFF800000  0xFF8FFFFF  TLB1_5  NAND      1M
	#   0xFFDF0000	0xFFDF0FFF	TLB1_3	QIXIS 	  4k

	##################################################################################
	# MMU initialization
	#

	set CCSR_EPN 000000[string range [CCSR_ADDR 1] 4 14]
	set CCSR_RPN [string range [CCSR_ADDR 0] 4 14]	

	# define 16MB TLB entry  1 : 0xFE000000 - 0xFEFFFFFF for CCSR    cache inhibited, guarded
	reg ${CAM_GROUP}L2MMU_CAM1  = 0x7000000A1C080000000000${CCSR_RPN}${CCSR_EPN}
		
	# define  1MB TLB entry  2 : 0x00000000 - 0x000FFFFF for SRAM cache-inhibited
	reg ${CAM_GROUP}L2MMU_CAM2  = 0x580000081C08000000000000000000000000000000000001
	
	# define  1MB TLB entry  3 : 0x00100000 - 0x001FFFFF for SRAM cache-inhibited
	reg ${CAM_GROUP}L2MMU_CAM3  = 0x580000081C08000000000000001000000000000000100001

	# define   4k TLB entry  4 : 0xFFDF0000 - 0xFFDF0FFF for QIXIS   cache-inhibited, guarded
	reg ${CAM_GROUP}L2MMU_CAM4  = 0x1000000A1C08000000000000FFDF000000000000FFDF0001

	# define 256M TLB entry  5 : 0xE0000000 - 0xEFFFFFFF for NOR   cache-inhibited, guarded
	reg ${CAM_GROUP}L2MMU_CAM5  = 0x9000000A1C08000000000000E000000000000000E0000001

	# define   1M TLB entry  6 : 0xFF800000 - 0xFF8FFFFF for NAND   cache-inhibited, guarded
	reg ${CAM_GROUP}L2MMU_CAM6  = 0x5000000A1C08000000000000FF80000000000000FF800001
	
	##################################################################################

	# init platform only on the master core
	if { [CORE $PIR] == $MASTER_CORE } {
		init_platform
	}

	##################################################################################
	# interrupt vectors initialization
	#
	# Interrupt vectors in SRAM are located at PER_CORE_SRAM  * (Core * NUM_THREADS + Thread)
	#
	set Ret [catch {evaluate __start__SMP}]
	if {$Ret} {
		variable IVPR_ADDR [expr {([CORE $PIR] * $NUM_THREADS + [THREAD $PIR]) * $PER_CORE_SRAM}]
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
	set processor_revision [expr [expr {$SVR & 0x000000FF}] >> 4]
	
	# set CM=0 = 32-bit
	reg ${SPR_GROUP}MSR = 0x00000000

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
		
			# workaround: the thread needs to run before being enabled on the simulator
		
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
			mem v:0x$B_ADDR = 0x[format %08X $SAVED_OPCODE]
			reg ${GPR_GROUP}PC = 0xFFFFFFFC		
		}
	}

	# enable floating point and AltiVec
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

