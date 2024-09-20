#-------------------------------------------------------------------------------------
#	T4240 QDS README
#-------------------------------------------------------------------------------------

This stationery project is designed to get you up and running
quickly with CodeWarrior for Power Architecture Development Studio.

The New Power Architecture Project wizard can create 24 projects, one for each
execution unit of T4240 (12 cores x 2 threads). Threads show up as
cores in CodeWarrior, thus:
	core0 corresponds to physical core#0-thread#0
	core1 corresponds to physical core#0-thread#1
	...
	core22 corresponds to physical core#11-thread#0
	core23 corresponds to physical core#11-thread#1
 
The two threads of a physical core share the same MMU and interrupt vectors setup.
The secondary thread assumes initialization for the primary thread has already been performed.
Projects for even cores (corresponding to thread0) initialize the core-specific options,
and projects for odd cores (corresponding to thread1) initialize only the thread-specific
options. Therefore launching projects for odd cores (1, 3, .. 23) requires the project for
the corresponding even core (0, 2, .. 22 respectively) to have already been launched.
 
The first core's project (core 0) is responsible for initializing the platform.
The projects for cores other than core0 only initialize core specific
options, not the whole platform. Therefore launching projects for other cores
requires that the core 0's project to have already been launched.

The example assumes the available 2GB DDR is split equally between the execution cores, the application
for each thread uses a range of 0x04000000. 

#-------------------------------------------------------------------------------------
#	T4240 QDS README
#-------------------------------------------------------------------------------------


	Switch settings for T4240 Rev 1.0 QDS - PROTO3
#------------------------------------------#

NOR_BOOT:
---------

 SW1 : 0x24 = 00100100		 SW2 : 0xFE = 11111110		 SW3 : 0x0C = 00001100		SW4 : 0x10 = 00010000
 SW5 : 0xE2 = 11100010		 SW6 : 0x0F = 00001111		 SW7 : 0xFA = 11111010		SW8 : 0xCC = 11001100
 SW9 : 0x1F = 00011111

Where '1' = up/ON

Default RCW:

	140c0019 0c10190c 00000000 00000000
	70023060 0055bc00 1c020000 09000000
	00000000 ee0000ee 00000000 000187fc
	00000000 00000000 00000000 00000008

	When you receive your board, please check several switches to make sure they match what RCW is using.
	SW1[1:8]+SW2[1] decodes as the RCW source. We use I2C (extended) as the primary RCW and eMMC as secondary. It is not recommended to update primary RCW source. 
					Also the RCW can be also fetched from eSPI flash.


	Switch settings for T4240 Rev 1.0 QDS - PROTO4 (board rev X2, schematics rev C)
#------------------------------------------#

NOR_BOOT:
---------

 SW1 : 0x24 = 00100100		 SW2 : 0xFE = 11111110		 SW3 : 0x0C = 00001100		SW4 : 0x50 = 01010000
 SW5 : 0xE2 = 11100010		 SW6 : 0x0F = 00001111		 SW7 : 0xFA = 11111010		SW8 : 0xCD = 11001101
 SW9 : 0x1F = 00011111 
 
Where '1' = up/ON

	When you receive your board, please check several switches to make sure they match what RCW is using.
	SW1[1:8]+SW2[1] decodes as the RCW source. We use I2C (extended) as the primary RCW and eMMC as secondary. It is not recommended to update primary RCW source. 
					Also the RCW can be also fetched from eSPI flash.

Default RCW:

	140c0019 0c101914 00000000 00000000
	04383063 30548c00 1c020000 1d000000
	00000000 ee0000ee 00000000 000307fc
	00000000 00000000 00000000 00000020


	Switch settings for T4240 Rev 1.0 QDS (schematics rev D1)
#------------------------------------------#

NOR_BOOT:
---------

 SW1 : 0x24 = 00100100		 SW2 : 0xFE = 11111110		 SW3 : 0x0C = 00001100		SW4 : 0x50 = 01010000
 SW5 : 0xE2 = 11100010		 SW6 : 0x0F = 00001111		 SW7 : 0xF8 = 11111000		SW8 : 0xCD = 11001101
 SW9 : 0x1F = 00011111 

Where '1' = up/ON

The above settings are for processor revision 1.0 and configure the board for:    
       CPU:1666 MHz,    CCB: 667 MHz,
       DDR:1600 MHz, SYSCLK:  67 MHz
       RCW  from: IFC - NOR Flash 16-bit
       Boot from: IFC flash bank 0


	Switch settings for T4240 Rev 2.0 QDS - PROTO4 (board rev X2, schematics rev C)
#------------------------------------------#

NOR_BOOT:
---------

 SW1 : 0x17 = 00010111		 SW2 : 0xFE = 11111110		 SW3 : 0x0C = 00001100		SW4 : 0x50 = 01010000
 SW5 : 0xE2 = 11100010		 SW6 : 0x0F = 00001111		 SW7 : 0xFA = 11111010		SW8 : 0xCD = 11001101
 SW9 : 0x1F = 00011111

Where '1' = up/ON

Default RCW:

	16070019 0c101912 00000000 00000000
	04383060 30548c00 ec020000 19000000
	00000000 ee0000ee 00000000 000307fc
	00000000 00000000 00000000 00000010

	Revision 2 supports fetching the RCW from NOR.

The above settings are for processor revision 2.0 and configure the board for:      
       CPU:1666 MHz,    CCB: 733 MHz,
       DDR:1867 MHz, SYSCLK:  67 MHz
       RCW  from: IFC - NOR Flash 16-bit
       Boot from: IFC flash bank 0


	Switch settings for T4240 Rev 2.0 QDS (schematics rev D5)
#------------------------------------------#

NOR_BOOT:
---------

 SW1 : 0x17 = 00010111		 SW2 : 0xFE = 11111110		 SW3 : 0x0C = 00001100		SW4 : 0x50 = 01010000
 SW5 : 0xE2 = 11100010		 SW6 : 0x0F = 00001111		 SW7 : 0xFA = 11111010		SW8 : 0xCD = 11001101
 SW9 : 0x1F = 00011111

Where '1' = up/ON

Default RCW:

	16070019 18101916 00000000 00000000
	04383060 30548c00 ec020000 f5000000
	00000000 ee0000ee 00000000 000307fc
	00000000 00000000 00000000 00000028

	Revision 2 supports fetching the RCW from NOR.
	
	Additional Connection settings: Reset delay must be enabled for at least 2000 ms
 
The above settings are for processor revision 2.0 and configure the board for:      
       CPU:1666 MHz,    CCB: 733 MHz,
       DDR:1867 MHz, SYSCLK:  67 MHz
       RCW  from: IFC - NOR Flash 16-bit
       Boot from: IFC flash bank 0

#-------------------------------------------------------------------------------------
 	Recommended JTAG clock speeds T4240 QDS
#-------------------------------------------------------------------------------------

USB TAP      : 10230 KHz
Ethernet TAP : 16000 KHz
Gigabit TAP  : 16000 KHz

#-------------------------------------------------------------------------------------
 	Overriding RCW from JTAG
#-------------------------------------------------------------------------------------

You can have CodeWarrior override RCW values through JTAG at reset. For this you
need to use a JTAG config file that specifies the values to override. You can see
examples of JTAG config files for T4240QDS (with comments inline) in
<CWInstallDir>\PA_10.0\PA_Support\Initialization_Files\jtag_chains\

#-------------------------------------------------------------------------------------
 	Including the FPGA on the JTAG chain
#-------------------------------------------------------------------------------------

You can have the FPGA show up as a device on the JTAG chain. For this you need to use
the <CWInstallDir>\PA\PA_Support\Initialization_Files\jtag_chain\T4240QDS_J2I2CS.txt
JTAG config file 

#-------------------------------------------------------------------------------------
 	Memory map and initialization
#-------------------------------------------------------------------------------------

   0x00000000  0x7FFFFFFF  DDR        2G    (LAW 0)
   0xC0000000  0xDFFFFFFF  DCSR       512M  (LAW 4)   
   0xE8000000  0xEFFFFFFF  NOR        128M  (LAW 2)
   0xFE000000  0xFEFFFFFF  CCSR Space 16M
   0xFF800000  0xFF8FFFFF  NAND       1M    (LAW 3)
   0xFFDF0000  0xFFDF0FFF  QIXIS      4k    (LAW 1)
   0xFFFFF000  0xFFFFFFFF  Boot Page  4k

#-------------------------------------------------------------------------------------
 	NOR Flash
#-------------------------------------------------------------------------------------

Please consult the Flash Programmer Release Notes for more details on flash programming

The flash address range on T4240 QDS is 0xE8000000 - 0xEFFFFFFF.
Each flash sector is 128KB and there are 1024 sectors for a total of 128MB of NOR flash space. 

The flash space is further divided into 8 virtual banks.

_________
|Bank7	| <----- RCW for the u-boot at Bank 0 is in this bank at address 0xe8000000 (not working yet due a silicon issue)
|Bank6	|
|Bank5	|
|Bank4	|
|Bank3	|
|Bank2	|
|Bank1	|
|Bank0	| <----- Bank 0 starts at 0xef000000; u-boot at address 0xeff80000 in this bank
---------

Changing SW1[1:8] alter the LBMAP which swaps the banks. Adjust SW1[1:4] to the bank number you want to use.
By default Bank 0 is used (SW1[1:4] = 0000). This means bootcode will is always NOR Flash Bank 0,
and the RCW is at Bank 7 (address 0xe8000000).
RCW for Bank i is in Bank (7-i) 


If you want to use Flash Programmer, you have to select S29GL01GP. 
A preconfigured target task already exists in:
<CWInstallDir>\bin\plugins\support\TargetTask\FlashProgrammer\Qonverge\T4240QDS_NOR_FLASH.xml.

CodeWarrior provides a flash programmer cheat-sheet that will guide you through the steps
needed to program the flash.You can access the cheat-sheet from Eclipse 
Help->Cheat Sheets->Using Flash Programmer.

#-------------------------------------------------------------------------------------
 	Cache support
#-------------------------------------------------------------------------------------

The default stationery project for T4240QDS also contains a launch configuration with all L1, L2 and L3 caches enabled.

#-------------------------------------------------------------------------------------
	 CodeWarrior Debugger Console I/O
#-------------------------------------------------------------------------------------

Every project will print "Welcome to CodeWarrior from Core x - Thread y!"

* The stationery projects use UART I/O. If you need to redirect output to a debugger console instead
of UART port, please modify the build settings (PowerPC AEABI e6500 Linker > Miscellaneous panel) to
change replace the UART library with "-lconsole"; also make sure you "Activate Support for System Services"
in the "System Call Services" sub-tab from the "Debugger" tab in the corresponding debug launch configuration. 

#-------------------------------------------------------------------------------------
	 CodeWarrior Debugger Console I/O
#-------------------------------------------------------------------------------------

Every project will print "Welcome to CodeWarrior from Core x - Thread y!" out of the common 
serial port (DUART1). To view the output, connect a null-modem serial cable from 
the serial port to your computer. Open a terminal program and set it up to match 
these settings:

Baud Rate: 115200
Data Bits: 8
Parity: None
Stop Bits: 1
Flow Control: None

NOTES:
*  For SMP projects you should synchronize printf/cout calls because they are not thread safe. Also, you can
use cartridge return and new line terminators (\r\n) in this calls to avoid the side effects of desynchronization.

* To be able to debug into the UART library you need to do the following steps:
1. Create a stationary project using the UART option.
2. Build the project
3. Right click on the elf file and select properties.
4. On the "File Mappings" tab see the unmapped files, select them, and click the "Add" button.
5. Browse the local file system path according to the UART source files. Default located in
<CWInstallDir>\PA\PA_Support\Serial\T4240QDS_aeabi_32bit_serial\Source
(or T4240QDS_aeabi_64bit_serial, depending on your type of project)
Now you can debug into the UART source files.

* The UART libraries are compiled with a specific CCSRBAR address. For a different
value of the CCSRBAR you need to rebuild the UART library:
1. From your CW install directory, import the 
<CWInstallDir>\PA\PA_Support\Serial\T4240QDS_aeabi_32bit_serial (or T4240QDS_aeabi_64bit_serial) project
2. Switch to the correspondent Build Target (eg DUARTA_UC_32bit).
Open duart_config.h file and change the value of the "MMR_BASE" accordingly
3. Re-build the project (and copy the output library in you project) 

* The stationery projects use UART1 output by default. If you need to use UART2, please
check the corresponding UART library in the build target and uncheck the default one
(both UART1_T4240QDS.aeabi.UC.[32|64]bit.a and UART2_T4240QDS.aeabi.UC.[32|64]bit.a are included in the
project's Lib folder).
Also please make sure you have the correct library listed in the "Other objects" panel in the project's
Properties > C/C++ Build > Settings > Power AEABI e6500 Linker > Miscellaneous.

* If you want to redirect output to a debugger console instead of UART driver, 
please follow above instruction to remove UART1_T4240QDS library from the project and instead use the ‘libconsole.a’ 
library from the project Lib Folder. Please make sure you have the correct library listed in the "Other objects" panel in the project's
Properties > C/C++ Build > Settings > Power Linux Linker > Miscellaneous (replace the UART library with "-lconsole")
Also please make sure you "Activate Support for System Services" in the "System Call Services" sub-tab
from the "Debugger" tab in the corresponding debug launch configuration. 

* The default baud rate is set at ‘115200’. For changing the baud rate in a default project define 
function “UARTBaudRate SetUARTBaudRate (void)” to an appropriate value in the application code.
 
 
#-------------------------------------------------------------------------------------
# 	Adding your own code
#-------------------------------------------------------------------------------------

Once everything is working as expected, you can begin adding your own code
to the project.  Keep in mind that we provide this as an example of how to
get up and running quickly with CodeWarrior.  There are certainly other 
ways to set up your linker command file or handle interrupts.  Feel free
to modify any of the source provided. 

#-------------------------------------------------------------------------------------
# 	Contacting Freescale
#-------------------------------------------------------------------------------------

You can contact us via email, newsgroups, voice, fax or the 
CodeWarrior website.  For details on contacting Freescale, visit 
http://www.freescale.com/codewarrior, or refer to the front of any 
CodeWarrior manual.

For questions, bug reports, and suggestions, please use the email 
report forms in the Release Notes folder.

For the latest news, offers, and updates for CodeWarrior, browse
Freescale Worldwide.

<http://www.freescale.com>
 