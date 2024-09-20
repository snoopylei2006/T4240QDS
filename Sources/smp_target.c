#include "smp_target.h"
#include "T4240QDS_init.h"

extern char			*ret_from_spin_loop;

unsigned long long spin_table[MAX_NUM_OF_CORES] = {0x1, 0x1, 0x1, 0x1, 0x1, 0x1, 0x1, 0x1, 0x1, 0x1, 0x1, 0x1,
													0x1, 0x1, 0x1, 0x1, 0x1, 0x1, 0x1, 0x1, 0x1, 0x1, 0x1, 0x1};

unsigned int getCoreId(void)
{
	unsigned long proc_id;
	asm ("mfpir %0" : "=r" (proc_id));
	return proc_id / 4 + proc_id % 2;
}
#if ROMTARGET
	void __spin_table_loop (void) __attribute__ ((section (".spin")));
#endif

	void __spin_table_loop (void)
	{
		#if ROMTARGET
		__asm__ (
			".equ __spin_table_size, __spin_table_loop_end - __spin_table_start \n"
			".org 0xFFC - __spin_table_size \n"
			"__spin_table_start:	 \n"
			);
			INIT_MMU_DDR
		#endif

			GET_SPIN_TABLE_ADDRESS

			#if ROMTARGET
				INIT_MMU_NOR
				/* enable the second thread */
				asm("mfpir  7");
				asm("andi. 7, 7, 1");
				asm("cmpwi  7, 0");
				asm("bne loop");
				asm("li 3, 0x2");
				asm("mtspr 438, 3");
			#endif

			__asm__(
			"loop:	 \n"
				"lwz      12,4(9) \n"
				"cmpwi    12,0x0001 \n"
				"beq      loop \n"
				"mtlr     12 \n"
				"blrl \n"
				"ori 0, 0, 0 \n"

			#if ROMTARGET
			".global __spin_table_loop_end \n"
			"__spin_table_loop_end:"
				"b __spin_table_start \n"
			#endif
		);
	}
void initSmp(void)
{
	if (getCoreId() == MASTER_CORE_ID)
	{
		unsigned long startAddr = (unsigned long)&ret_from_spin_loop;
		int coreId;	
		for (coreId = 0; coreId < MAX_NUM_OF_CORES; coreId++)
		{
			if ( coreId != MASTER_CORE_ID )
			{
				spin_table[coreId] = startAddr;
			}
		}
	}
}

