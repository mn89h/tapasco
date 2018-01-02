/**
 *  @file	generate_preload.c
 *  @brief	
 *  @author	J. Korinth, TU Darmstadt (jk@esa.cs.tu-darmstadt.de)
 **/
#include <stdio.h>
int main()
{
  for (int i = 0; i < 640 * 480 * 4; ++i)
    printf("%08x\n", i);
}

/* vim: set foldmarker=@{,@} foldlevel=0 foldmethod=marker : */

