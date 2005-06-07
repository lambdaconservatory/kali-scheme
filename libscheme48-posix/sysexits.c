/* Copyright (c) 1993-2004 by Richard Kelsey and Jonathan Rees.
   See file COPYING. */

#include "scheme48/libscheme48/scheme48.h"
#include "scheme48/libscheme48-posix/sysdep.h"

void
s48_init_sysexits(void)
{
  /* For SRFI 22 */
  s48_define_exported_binding("EX_SOFTWARE", s48_enter_integer(70L));
}
