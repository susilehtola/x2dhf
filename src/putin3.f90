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
! c ### putin3 ###

! c     Immerses FUN array into WORK and adds boundary values:
! c     the interior subgrid
module putin3_m
  implicit none
contains
  subroutine putin3 (nni,nmi,fun,work)
    use params
    use solver
    use blas_m

    implicit none
    integer :: i,j,jj,nmi,nni,n9

    real (PREC), dimension(nni,*):: fun
    real (PREC), dimension(nni+8,nmi+8) :: work
    real (PREC), dimension(maxmu,4) :: fint
    data n9/9/

    !   muoffs=iemu(ig-1)
    !   fill the interior of work array

    do i=1,nmi
       do j=1,nni
          work(j+4,i+4)=fun(j,muoffs+i)
       enddo
    enddo

    !   values over i=1 bondary are determined from the interpolation formula
    !   mu=2,...,4 from interpolation (coefficients from cint3l)

    do i=2,4
       call gemv (nni,n9,fun(1,iadint3l(i)),cint3l(1,i),fint(1,i))
    enddo

    do i=2,4
       do j=1,nni
          work(j+4,i)= fint(j,i)
       enddo
    enddo

    !   values over i=nmi bondary are determined from the interpolation formula
    !   mu=nmu+5....nmu+8 from interpolation (coefficients from cint3r)

    do i=1,4
       call gemv (nni,n9,fun(1,iadint3r(i)),cint3r(1,i),fint(1,i))
    enddo

    do i=1,4
       do j=1,nni
          work(j+4,nmi+4+i)= fint(j,i)
       enddo
    enddo

    !   isym = 1 - even symmetry, isym =-1 - odd symmetry

    if (isym.eq.1) then

       ! ni=1...4
       do i=1,nmi
          do j=2,5
             work(6-j,i+4)= fun(j,muoffs+i)
          enddo
       enddo

       ! ni=ni+4...ni+8
       do i=1,nmi
          jj=0
          do j=nni-4,nni-1
             jj=jj+1
             work(nni+9-jj,i+4)= fun(j,muoffs+i)
          enddo
       enddo
    else
       do i=1,nmi
          do j=2,5
             work(6-j,i+4)=-fun(j,muoffs+i)
          enddo
       enddo

       do i=1,nmi
          jj=0
          do j=nni-4,nni-1
             jj=jj+1
             work(nni+9-jj,i+4)=-fun(j,muoffs+i)
          enddo
       enddo
    endif

  end subroutine putin3
end module putin3_m
