cdis    Forecast Systems Laboratory
cdis    NOAA/OAR/ERL/FSL
cdis    325 Broadway
cdis    Boulder, CO     80303
cdis 
cdis    Forecast Research Division
cdis    Local Analysis and Prediction Branch
cdis    LAPS 
cdis 
cdis    This software and its documentation are in the public domain and 
cdis    are furnished "as is."  The United States government, its 
cdis    instrumentalities, officers, employees, and agents make no 
cdis    warranty, express or implied, as to the usefulness of the software 
cdis    and documentation for any purpose.  They assume no responsibility 
cdis    (1) for the use of the software and documentation; or (2) to provide
cdis     technical support to users.
cdis    
cdis    Permission to use, copy, modify, and distribute this software is
cdis    hereby granted, provided that the entire disclaimer notice appears
cdis    in all copies.  All modifications to this software must be clearly
cdis    documented, and are solely the responsibility of the agent making 
cdis    the modifications.  If significant modifications or enhancements 
cdis    are made to this software, the FSL Software Policy Manager  
cdis    (softwaremgr@fsl.noaa.gov) should be notified.
cdis 
cdis 
cdis 
cdis 
cdis 
cdis 
cdis 
c
c
	subroutine solar_normal(ni,nj,topo,dx,dy,lat,lon
     1                         ,sol_alt,sol_azi,alt_norm)

c       Compute solar altitude normal to the terrain

        include 'trigd.inc'

        angleunitvectors(a1,a2,a3,b1,b2,b3) = acosd(a1*b1+a2*b2+a3*b3)

	real topo(ni,nj)                 ! I Terrain elevation (m)
        real lat(ni,nj)                  ! I Lat (deg)
        real lon(ni,nj)                  ! I Lon (deg)
        real sol_alt(ni,nj)              ! I Solar Altitude (deg)
        real sol_azi(ni,nj)              ! I Solar Azimuth (deg)
        real alt_norm(ni,nj)             ! O Solar Alt w.r.t. terrain normal

	real dx(ni,nj)                   ! I Grid spacing in X direction (m)
	real dy(ni,nj)                   ! I Grid spacing in Y direction (m)

        real rot(ni,nj)                  ! L Rotation Angle (deg)
        real*8 vecx(3),vecy(3),vecz(3),vecn(3),maga
    
        write(6,*)' Subroutine solar_normal'

!       call get_grid_spacing_array(lat,lon,ni,nj,dx,dy)

!       Default value
        alt_norm = sol_alt

        call projrot_latlon_2d(lat,lon,ni,nj,rot,istatus)

	dircos_tz_min = 1.0

	do j=2,nj-1
	do i=2,ni-1

!           Determine centered terrain slope
            dterdx = (topo(i+1,j  )-topo(i-1,j  )) / (2. * dx(i,j))
            dterdy = (topo(i  ,j+1)-topo(i  ,j-1)) / (2. * dy(i,j))

            terrain_slope = sqrt(dterdx**2 + dterdy**2)

            if(terrain_slope .gt. .001)then ! machine/terrain epsilon threshold

!             See http://www.web-formulas.com/Math_Formulas/Trigonometry_Conversion_of_Trigonometric_Functions.aspx	       
!             Vecx = 1,0,dterdx
!             Vecy = 0,1,dterdy
!             Vecn = Vecx x Vecy

	      vecx(1) = 1.
	      vecx(2) = 0.
	      vecx(3) = dterdx

	      vecy(1) = 0.
	      vecy(2) = 1.
	      vecy(3) = dterdy

	      call crossproduct(vecx(1),vecx(2),vecx(3)
     1                 ,vecy(1),vecy(2),vecy(3),vecz(1),vecz(2),vecz(3))
              call normalize(vecz(1),vecz(2),vecz(3),maga)

!             Direction cosines of terrain normal
!             dircos_tx = -dterdx / (sqrt(dterdx**2 + 1.))
!             dircos_ty = -dterdy / (sqrt(dterdy**2 + 1.))
!             dircos_tz = 1.0 / sqrt(1.0 + terrain_slope**2)
!             dircos_tz = sqrt(1.0 - (dircos_tx**2+dircos_ty**2))

	      dircos_tx = vecz(1)
	      dircos_ty = vecz(2)
	      dircos_tz = vecz(3)

              sol_azi_grid = sol_azi(i,j) - rot(i,j) 

!             Direction cosines of sun
              dircos_sx = cosd(sol_alt(i,j)) * sind(sol_azi_grid)
              dircos_sy = cosd(sol_alt(i,j)) * cosd(sol_azi_grid)
              dircos_sz = sind(sol_alt(i,j))

!             Angle between terrain normal and sun
!             result = angleunitvectors(dircos_tx,dircos_ty,dircos_tz
!    1                                 ,dircos_sx,dircos_sy,dircos_sz)	      

              product = dircos_tx*dircos_sx + dircos_ty*dircos_sy
     1                                      + dircos_tz*dircos_sz
              if(abs(product) .gt. 1.0)then ! facing the sun
                  write(6,1)product,terrain_slope,sol_alt(i,j)
     1                     ,dircos_tx,dircos_ty,dircos_tz
1	          format('warning: solar normal product = ',6f9.3)	  
                  result = 0.
              else
		  result = acosd(product)
	      endif

              alt_norm(i,j) = 90. - result 
            
              if(i .eq. ni/2 .and. j .eq. nj/2)then
                write(6,*)' solar alt/az, dterdx, dterdy, alt_norm',
     1             sol_alt(i,j),sol_azi(i,j),dterdx,dterdy,alt_norm(i,j)        
                write(6,*)' dircos_t ',dircos_tx,dircos_ty,dircos_tz
                write(6,*)' dircos_s ',dircos_sx,dircos_sy,dircos_sz
                write(6,*)' terrain slope angle: ',90.-asind(dircos_tz)
                write(6,*)' rot = ',rot(i,j)
              endif

	      dircos_tz_min = min(dircos_tz,dircos_tz_min)
	      if(dircos_tz .eq. dircos_tz_min)then
                  dircos_tx_min = dircos_tx
                  dircos_ty_min = dircos_ty
                  dterdx_min = dterdx
                  dterdy_min = dterdy
                  imin = i
		  jmin = j
              endif

            else 
              alt_norm(i,j) = sol_alt(i,j) ! terrain virtually flat

              if(i .eq. ni/2 .and. j .eq. nj/2)then
                write(6,*)'solar alt/az, alt_norm',
     1             sol_alt(i,j),sol_azi(i,j),alt_norm(i,j)        
              endif

            endif

	enddo !i
	enddo !j

        write(6,*)' Range of alt_norm is ',minval(alt_norm)
     1                                    ,maxval(alt_norm)	

	write(6,*)' Max terrain slope is '
     1            ,dircos_tx_min,dircos_ty_min,dircos_tz_min
     1            ,acosd(dircos_tz_min)
     1            ,dterdx_min,dterdy_min
     1            ,dx(imin,jmin),dy(imin,jmin)
     1            ,topo(imin-1:imin+1,jmin-1:jmin+1)

	return
	end


