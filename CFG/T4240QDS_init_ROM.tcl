########################################################################################
# Initialization file for T4240 QDS board - ROM (NOR)
# Clock Configuration:
#       CPU: 1666 MHz,    CCB:   666.6/733 MHz,
#       DDR: 1600/1867 MHz, SYSCLK:    66.6 MHz
########################################################################################

proc envsetup {} {
	# Environment Setup
	radix x 
	config hexprefix 0x
	config MemIdentifier v
	config MemWidth 32 
	config MemAccess 32 
	config MemSwap off
}

envsetup
  
#######################################################################
# debugger settings

# prevent stack unwinding at entry_point/reset when stack pointer is not initialized
reg	"General Purpose Registers/SP" = 0x0000000F

