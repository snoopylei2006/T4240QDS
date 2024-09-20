/*
 * Project Stationery - use this 'C' sample to create your own application
 */

#if SMPTARGET
#if E500V2_EABI
	#include "smp_target_eabi.h"
#else
	#include "smp_target.h"
#endif
#endif
 
int recursive(int x)
{
	if (x < 3)
		x = recursive(++x);
		
	return x;
}

int funcb(int m, int n)
{
	register int x = 3, y = 7;

	m += x * y;
	n = m + y;

	return (x * m + n * y);
}

int funca(int k)
{
	register int x = 0, y = 1;

	x = k + 1;
	y -= x;

	k = funcb(x, y);

	return k;
}

int main(void)
{
	int counter = 0;
	
#if SMPTARGET
	initSmp();
#endif
	
	counter = recursive(counter);

	funca(counter);
	
	while (1) { counter++; } // loop forever
}
