! ***************************************************************************
! *                                                                         *
! *   Copyright (C) 1996 Leif Laaksonen, Dage Sundholm                      *
! *   Copyright (C) 1996-2010 Jacek Kobus <jkob@fizyka.umk.pl>              *
! *                                                                         *
! *   This program is free software; you can redistribute it and/or modify  *
! *   it under the terms of the GNU General Public License version 2 as     *
! *   published by the Free Software Foundation.                            *
! *                                                                         *
! ***************************************************************************
! ### norm ###

!     Normalizes a given orbital.

subroutine norm (iorb,psi,f4,wgt2,wk0)
  use params
  use commons8

  implicit none
  integer :: i,ibeg,iorb,ngrid
  real (PREC) :: xnorm,zarea
  real (PREC), dimension(*) :: psi,f4,wgt2,wk0
  real (PREC), external :: dot

  if (ifix(iorb).ne.0) return

  ibeg = i1b (iorb)
  ngrid= i1si(iorb)

  do i=1,ngrid
     wk0(i)=psi(ibeg-1+i)*psi(ibeg-1+i)
  enddo
  call prod  (ngrid,f4,wk0)

  xnorm=dot (ngrid,wgt2,ione,wk0,ione)

  area(iorb)=xnorm
  zarea = one/sqrt(xnorm)

  call scal (ngrid,zarea,psi(ibeg),ione)

  if (iprint(36).ne.0) then
     write(*,'("norm: ",i4,1x,a8,a1,3x,e16.2)') iorn(iorb),bond(iorb),gut(iorb),abs(one-area(iorb))
  endif

end subroutine norm

