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
! ### initPotentials ###
!     This routine initializes Coulomb potentials using the Thomas-Fermi model
!      or SAP and exchange potentials via the local exchange or 1/r approximation

module initPotentials_m
  implicit none
contains
  subroutine initCoulomb (pot,f4)
    use params
    use discret
    use memory
    use commons8
    use util

    use blas_m
    use pottf_m
    use prepwexch_m
    use slaterp_m
    use wtdexch_m
    use zeroArray_m

    implicit none

    integer :: i3beg,igp,imu,in,inioff,iorb,iorb1,iorb2,iorb2t,irec,ishift,k,ngrid
    real (PREC) :: ch1,ch2,crt1,crt2,ez1,ez2,ra1,ra2,slim,vetat,vxit,zc1,zc2
    real (PREC), dimension(*) :: pot,f4

    if (imethod.eq.2.or.ini.eq.4) return

    print *,'... initializing Coulomb potentials (pottf) ...'
    
    if (ini.ne.6) then
       ! Initialization of Coulomb potentials
       slim=1.0_PREC
       zc1= 2.0_PREC
       zc2= 2.0_PREC

       ! loop over orbitals

       do iorb=1,norb
          if (inhyd(iorb).eq.0) goto 10
          ngrid=i1si(iorb)
          ishift=i1b(iorb)-1
          ez1=eza1(iorb)
          ez2=eza2(iorb)

          ch1=-1.00_PREC
          ch2=-1.00_PREC
          if (ez1.lt.precis) ch1=-2.00_PREC
          if (ez2.lt.precis) ch2=-2.00_PREC

          crt1=abs(co1(iorb))
          crt2=abs(co2(iorb))

          do imu=1,mxnmu
             inioff=(imu-1)*nni
             vxit=vxi(imu)
             do in=1,nni
                igp=ishift+inioff+in
                vetat=veta(in)
                if (imu.eq.1.and.in.eq.1) then
                   pot(igp)=0.0_PREC
                else
                   pot(igp)=pottf(r, vetat,vxit,zc1,ch1,slim)*crt1+pottf(r,(-vetat),vxit,zc2,ch2,slim)*crt2
                endif
             enddo
          enddo
          call prod(ngrid,f4,pot(i1b(iorb)))
10        continue
       enddo
    endif


  end subroutine initCoulomb

  ! This routine initializes exchange potentials via the local exchange or 1/r approximation
  subroutine initExchange (psi,excp,f4)
    use params
    use discret
    use memory
    use commons8
    use util

    use blas_m
    use pottf_m
    use prepwexch_m
    use slaterp_m
    use wtdexch_m
    use zeroArray_m

    implicit none

    integer :: i3beg,igp,imu,in,inioff,iorb,iorb1,iorb2,iorb2t,irec,ishift,k,ngrid
    real (PREC) :: ch1,ch2,crt1,crt2,ez1,ez2,ra1,ra2,slim,vetat,vxit,zc1,zc2
    real (PREC), dimension(*) :: psi,excp,f4

    if (imethod.eq.2.or.ini.eq.4) return

    ! Initialization of exchange potentials

    call zeroArray(length3,excp)

    if (imethod.eq.3.or.imethod.eq.4.or.imethod.eq.5) then
       call slaterp(psi,excp,f4)
       print *,'... initializing Slater exchange potential ...'
       return
    elseif (iform.eq.1.or.iform.eq.3) then

       print *,'... initializing exchange potentials ...'

       !        Initialization of exchange potentials that are all kept in memory

       !        loop over orbitals

       do iorb1=1,norb
          do iorb2=iorb1,norb
             k=iorb1+iorb2*(iorb2-1)/2
             if (iorb1.eq.iorb2.and.ll(iorb2).eq.0) goto 50
             ngrid=i3si(k)
             ishift=i3b(k)-1

             !              loop over grid points

             do imu=1,mxnmu
                if (imu.eq.1) goto 40
                inioff=(imu-1)*nni
                vxit=vxi(imu)
                do in=1,nni
                   if (in.eq.1.or.in.eq.nni) goto 30
                   igp=ishift+inioff+in
                   vetat=veta(in)
                   ra1=(r/2.0_PREC)*(vxit+vetat)
                   ra2=(r/2.0_PREC)*(vxit-vetat)

                   if (ra1.gt.1.d-8) then
                      excp(igp)=co1(iorb1)/ra1
                   else
                      excp(igp)=0.0_PREC
                   endif
                   if (ra2.gt.1.d-8) then
                      excp(igp)=excp(igp)+co2(iorb1)/ra2
                   endif
30                 continue
                enddo
40              continue
             enddo

             call prod(ngrid,f4,excp(i3b(k)))
             if (iorb1.eq.iorb2) goto 50
             if (ll(iorb1).eq.0.or.ll(iorb2).eq.0) goto 50
             ishift=ishift+ngrid
             call copy(ngrid,excp(i3b(k)),ione,excp(i3b(k)+ngrid),ione)
50           continue
          enddo
       enddo

    elseif (iform.eq.0.or.iform.eq.2) then

       print *,'... initializing exchange potentials ...'

       call prepwexch
       do iorb1=1,norb
          do iorb2=1,i3nexcp(iorb1)
             k=i3breck(iorb1,iorb2)
             i3beg=i3brec(iorb1,iorb2)
             iorb2t=i3orb2(k)
             i3b(k)=i3beg
             ngrid=i3si(k)
             if (ilc(k).eq.1) then
                irec=i3xpair(iorb1,iorb2)
                ishift=i3b(k)-1

                !                 loop over grid points

                if (iwexch(k).ne.0) then
                   do imu=1,mxnmu
                      if (imu.eq.1) goto 41
                      inioff=(imu-1)*nni
                      vxit=vxi(imu)
                      do in=1,nni
                         if (in.eq.1.or.in.eq.nni) goto 31
                         igp=ishift+inioff+in
                         vetat=veta(in)
                         ra1=(r/2.0_PREC)*(vxit+vetat)
                         ra2=(r/2.0_PREC)*(vxit-vetat)

                         if (ra1.gt.1.d-8) then
                            excp(igp)=co1(iorb1)/ra1
                         else
                            excp(igp)=0.0_PREC
                         endif
                         if (ra2.gt.1.e-8_PREC) then
                            excp(igp)=excp(igp)+co2(iorb1)/ra2
                         endif
31                       continue
                      enddo
41                    continue
                   enddo
                endif
                call prod(ngrid,f4,excp(i3b(k)))
             elseif (ilc(k).eq.2) then
                irec=i3xpair(iorb1,iorb2)
                call copy(ngrid,excp(i3beg-ngrid),ione,excp(i3beg),ione)
             endif
          enddo

          !           save exchange potential involving iorb1 on disk
          call wtdexch(iorb1,excp)
       enddo
    endif

  end subroutine initExchange
  

  subroutine initCoulombSAP (pot,f4)
    !USE, INTRINSIC :: IEEE_ARITHMETIC, ONLY: IEEE_IS_FINITE    
    use params
    use discret
    use memory
    use commons8
    use util

    use blas_m
    use pottf_m
    use prepwexch_m
    use sap_potential_m
    use slaterp_m
    use wtdexch_m
    use zeroArray_m

    implicit none

    integer :: i3beg,igp,imu,in,inioff,iorb,iorb1,iorb2,iorb2t,irec,ishift,iz1,iz2,k,ngrid
    real (PREC) :: crt1,crt2,ra1,ra2,r1t,r2t,vetat,vxit
    real (PREC) :: infinity
    real (PREC), dimension(*) :: pot,f4

    infinity=huge(one)
    
    if (imethod.eq.2.or.ini.eq.4) return

    print *,'... initializing Coulomb potentials (effective_coulomb_charge) ...'
    
    if (ini.ne.6) then
       ! Initialization of Coulomb potentials

       iz1=nint(z1)
       iz2=nint(z2)
       
       do iorb=1,norb

          ngrid=i1si(iorb)
          ishift=i1b(iorb)-1

          crt1=abs(co1(iorb))
          crt2=abs(co2(iorb))

          !  loop over grid points
          do imu=1,mxnmu
             inioff=(imu-1)*nni
             vxit=vxi(imu)
             do in=1,nni
                igp=ishift+inioff+in
                vetat=veta(in)
                r1t=(r/2.0_PREC)*(vxi(imu)+veta(in))
                r2t=(r/2.0_PREC)*(vxi(imu)-veta(in))
                
                pot(igp)=z1-effective_coulomb_charge(iz1,r1t)*crt1+&
                     z2-effective_coulomb_charge(iz2,r2t)*crt2

                !if (.not.IEEE_IS_FINITE(pot(igp))) then
                if (abs(pot(igp))>infinity) then
                   print *,'initCoulombSAP',iorn(iorb),bond(iorb),imu,in,r1t,effective_coulomb_charge(iz1,r1t)
                   pot(igp)=pot(igp-1)
                endif
             enddo
          enddo
          call prod(ngrid,f4,pot(i1b(iorb)))
       enddo
    endif


  end subroutine initCoulombSAP

end module initPotentials_m
