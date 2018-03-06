
! ### vpolyq ###
!
!     This function uses the Horner scheme to calculate value of the polynomial
!     stored in array a at a particular point

module vpolyq_m
  implicit none
contains
  function vpolyq (mup,a,vmuq)
    use params
    use commons16

    implicit none
    integer :: i,mup
    real (PREC16) :: vpolyq
    real (PREC16) :: x
    real (PREC16), dimension(kend) :: a
    real (PREC16), dimension(maxmu) :: vmuq

    x=vmuq(mup)
    vpolyq=0.0_PREC16
    do i=iord,2,-1
       vpolyq=(vpolyq+a(i))*x
    enddo
    vpolyq=vpolyq+a(1)

  end function vpolyq
end module vpolyq_m
