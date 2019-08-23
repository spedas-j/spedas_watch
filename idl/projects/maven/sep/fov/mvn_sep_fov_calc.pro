;20180419 Ali
;calculates a bunch of parameters for mvn_sep_fov

pro mvn_sep_fov_calc,times

  @mvn_sep_fov_common.pro
  @mvn_sep_handler_commonblock.pro

  objects=mvn_sep_fov0.objects
  toframe=mvn_sep_fov0.toframe
  rmars=mvn_sep_fov0.rmars

  nt=n_elements(times)
  nobj=n_elements(objects)
  fnan=!values.d_nan ;dnan really! Am I using double due to higher precision for dot products?
  pos=replicate({sun:fnan,ear:fnan,mar:fnan,pho:fnan,dem:fnan,cm1:fnan,sx1:fnan,ram:fnan},[3,nt])
  tal=pos ;tangent altitude (km) ['sphere','ellipsoid','areoid']
  pdm=reform(pos[0,*]) ;position dot mars (for occultation)
  rad=pdm ;radial distance from the center of the object (km)
  occ=pdm ;occultation flag

  observer='maven'
  check_maven=toframe eq 'maven_sep1' ? 'maven_spacecraft':'maven'
  for iobj=0,nobj-1 do begin
    pos.(iobj)=spice_body_pos(objects[iobj],observer,frame=toframe,utc=times,check_objects=[objects[iobj],observer,check_maven],/force_objects) ;position (km)
    rad.(iobj)=sqrt(total(pos.(iobj)^2,1)) ;distance (km)
    pos.(iobj)/=replicate(1.d,3)#rad.(iobj)
  endfor
  from_frame='j2000'
  pos.ram=spice_body_vel('mars',observer,frame=from_frame,utc=times,check_objects=['mars',observer,check_maven],/force_objects) ;maven velocity wrt Mars in J2000 (km/s)
  rad.ram=sqrt(total(pos.ram^2,1)) ;maven speed (km/s)
  pos.ram/=-replicate(1.d,3)#rad.ram ;MAVEN velocity unit vector wrt Mars in J2000

  qrot=spice_body_att(from_frame,toframe,times,/quaternion,check_objects=check_maven,/force_objects)
  ;  from_frame='IAU_MARS'
  ;  zdir=[0.,0.,1.] ;Mars North pole in IAU_MARS (oblate spheroid symmetry axis)
  ;  pos.mnp=spice_vector_rotate(zdir,times,from_frame,toframe,check_objects=check_maven,/force_objects) ;Mars North pole in sep1 coordinates
  qrot_iau=spice_body_att(toframe,'IAU_MARS',times,/quaternion,check_objects=check_maven,/force_objects)

  mvn_sep_fov=replicate({pos:pos[*,0],rad:rad[0],pdm:pdm[0],occ:occ[0],tal:tal[*,0],qrot:qrot[*,0],qrot_iau:qrot_iau[*,0],time:times[0],att:[0.,0.],crl:fltarr(2,6),crh:fltarr(2,6)},nt) ;saving results to common block

  ;m1=[0.102810,0.921371,0.374841] ;crab nebula coordinates in J2000 from NAIF
  ;cbnm1rd=[05h 34m 31.94s , +22° 00′ 52.2″] ;Crab Nebula (M1) Right Ascention/Declination
  ;scox1rd=[16h 19m 55.07s , −15° 38' 24.8"] ;Scorpius X-1 (from wiki)
  ;cygx1rd=[19h 58m 21.67s , +35° 12′ 05.8″] ;Cygnus X-1
  cm1r=!const.pi*[360.*(5.0+34./60.+31.94/60./60.)/24.,+(22.+00./60.+52.2/60./60.)]/180. ;radians
  sx1r=!const.pi*[360.*(16.+19./60.+55.07/60./60.)/24.,-(15.+38./60.+24.8/60./60.)]/180.
  cx1r=!const.pi*[360.*(19.+58./60.+21.67/60./60.)/24.,+(35.+12./60.+05.8/60./60.)]/180.
  cm1=[cos(cm1r[0])*cos(cm1r[1]),sin(cm1r[0])*cos(cm1r[1]),sin(cm1r[1])] ;should be equal to m1 above
  sx1=[cos(sx1r[0])*cos(sx1r[1]),sin(sx1r[0])*cos(sx1r[1]),sin(sx1r[1])]
  cx1=[cos(cx1r[0])*cos(cx1r[1]),sin(cx1r[0])*cos(cx1r[1]),sin(cx1r[1])]
  pos.cm1=quaternion_rotation(cm1,qrot,/last_ind)
  pos.sx1=quaternion_rotation(sx1,qrot,/last_ind)
  pos.ram=quaternion_rotation(pos.ram,qrot,/last_ind) ;MAVEN velocity unit vector wrt Mars in SEP1 frame
  ;  pos.cx1=quaternion_rotation(cx1,qrot,/last_ind)


  if keyword_set(sep1_svy) then begin
    map1=mvn_sep_get_bmap(9,1)
    if mvn_sep_fov0.arc then begin
      sep1=*(sep1_arc.x)
      sep2=*(sep2_arc.x)
    endif else begin
      sep1=*(sep1_svy.x)
      sep2=*(sep2_svy.x)
    endelse
    ndet=n_elements(mvn_sep_fov0.detlab)
    for idet=0,ndet-1 do begin
      ;get_data,'mvn_'+lrs+'sep'+strtrim(isep+1,2)+'_'+detlab[idet]+'_Rate_Energy',dat=sepdat
      ind=where(map1.name eq mvn_sep_fov0.detlab[idet])
      mvn_sep_fov.crl[0,idet]=total(sep1.data[ind[0]+0:ind[0]+5],1)/sep1.delta_time ;low  energy count rate
      mvn_sep_fov.crh[0,idet]=total(sep1.data[ind[0]+6:ind[0]+9],1)/sep1.delta_time ;high energy count rate (for hi background elimination)
      sep2crl_before_interpol=total(sep2.data[ind[0]+0:ind[0]+5],1)/sep2.delta_time
      sep2crh_before_interpol=total(sep2.data[ind[0]+6:ind[0]+9],1)/sep2.delta_time
      ;    mvn_sep_fov.crl[1,idet]=exp(interpol(alog(sep2crl_before_interpol),sep2.time,times,/nan))
      ;    mvn_sep_fov.crh[1,idet]=exp(interpol(alog(sep2crh_before_interpol),sep2.time,times,/nan))
      mvn_sep_fov.crl[1,idet]=interpol(sep2crl_before_interpol,sep2.time,times,/nan)
      mvn_sep_fov.crh[1,idet]=interpol(sep2crh_before_interpol,sep2.time,times,/nan)
    endfor

    sep2_att=exp(interpol(alog(sep2.att),sep2.time,times,/nan))
    att=transpose([[sep1.att],[sep2_att]])
  endif else att=replicate(1.,[2,nt])

  occalt=mvn_sep_fov0.occalt ;crossing altitude (km) maximum altitude for along path integration
  occos=cos(!dtor*14.) ;within 14 degrees of detector fov center
  alt=rad.mar-rmars ;altitude (km)
  npos=n_tags(pos)
  for ipos=0,npos-1 do begin
    pdm.(ipos)=total(pos.(ipos)*pos.mar,1)
    tal[0,*].(ipos)=transpose(rad.mar*sqrt(1.d0-pdm.(ipos)^2)-rmars) ;temporary inaccurate tangent altitude
    wpdmlt0=where(pdm.(ipos) lt 0.,/null) ;where line of sight away from Mars
    if n_elements(wpdmlt0) gt 0 then tal[0,wpdmlt0].(ipos)=transpose(alt[wpdmlt0]) ;set tangent altitude equal to altitude
    horcro=((tal[0,*].(ipos)-occalt)*shift((tal[0,*].(ipos)-occalt),1)) lt 0. ;crossed the occalt
    occ.(ipos)=0
    occ[where((pos[0,*].(ipos) gt +occos) and horcro and att[0,*] eq 1.,/null)].(ipos)=1 ;sep1f
    occ[where((pos[2,*].(ipos) gt +occos) and horcro and att[1,*] eq 1.,/null)].(ipos)=2 ;sep2f
    occ[where((pos[0,*].(ipos) lt -occos) and horcro and att[0,*] eq 1.,/null)].(ipos)=3 ;sep1r
    occ[where((pos[2,*].(ipos) lt -occos) and horcro and att[1,*] eq 1.,/null)].(ipos)=4 ;sep2r
  endfor
  pdm.mar=sqrt(1.-(rmars/rad.mar)^2) ;dot product of mars surface by mars center
  pdm.ram=sqrt(1.-((rmars+occalt)/rad.mar)^2) ;dot product of mars occalt by mars center
  ;  tal.mar=alt
  ;  occtimes=where(occ.sx1 ne 0,/null)

  ;  cspice_bodvrd, 'MARS', 'RADII', 3, radii ;rmars=[3396.2,3396.2,3376.2] km
  ;  re = total(radii[0:1])/2. ;equatorial radius (km)
  ;  rp = radii[2] ;polar radius (km)
  ;  mdz=-total(pos.mar*pos.mnp,1) ;maven dot mars north pole (cosine of polar angle)
  ones3=replicate(1d,3)
  talsx1=(ones3#rad.mar)*((ones3#pdm.sx1)*pos.sx1-pos.mar) ;sco x-1 tangent altitude vector from Mars center (km)
  ;  tdz=total(talsx1*pos.mnp,1)/sqrt(total(talsx1^2,1)) ;cosine of polar angle (90-latitude) of sub-tangent altitude point
  ;  rad.mnp=sqrt((re^4*(1.-mdz^2)+rp^4*mdz^2)/(re^2*(1.-mdz^2)+rp^2*mdz^2)) ;radius of sub-maven surface point (km)
  ;  tal.mnp=sqrt((re^4*(1.-tdz^2)+rp^4*tdz^2)/(re^2*(1.-tdz^2)+rp^2*tdz^2)) ;radius of sub-tangent altitude point (km)
  posmar_iau=quaternion_rotation(-pos.mar,qrot_iau,/last_ind)*(ones3#rad.mar) ;MAVEN position from Mars center in IAU_MARS
  possx1_iau=quaternion_rotation( pos.sx1,qrot_iau,/last_ind)
  talsx1_iau=quaternion_rotation(  talsx1,qrot_iau,/last_ind)
  mvn_altitude,cart=posmar_iau,datum='sphere',result=adat
  tal[0,*].mar=transpose(adat.alt)
  mvn_altitude,cart=posmar_iau,datum='ellips',result=adat
  tal[1,*].mar=transpose(adat.alt)
  mvn_altitude,cart=posmar_iau,datum='areoid',result=adat
  tal[2,*].mar=transpose(adat.alt)
  mvn_altitude,cart=talsx1_iau,datum='sphere',result=adat
  tal[0,*].sx1=transpose(adat.alt)
  mvn_altitude,cart=talsx1_iau,datum='ellips',result=adat
  tal[1,*].sx1=transpose(adat.alt)
  mvn_altitude,cart=talsx1_iau,datum='areoid',result=adat
  tal[2,*].sx1=transpose(adat.alt)

  wpdmlt0=where(pdm.sx1 lt 0.,/null)
  if n_elements(wpdmlt0) gt 0 then tal[*,wpdmlt0].sx1=tal[*,wpdmlt0].mar ;set the tangent altitude equal to altitude

  ;  wtal=where((abs(pos[0,*].sx1) gt occos or abs(pos[2,*].sx1) gt occos) and tal[2,*].sx1 gt 0. and tal[2,*].sx1 lt occalt,ntal,/null)
  ntal=nt
  wtal=lindgen(nt)
  if ntal eq 0 then return
  tadsx1=sqrt((rmars+2.*occalt)^2-(rmars+reform(tal[2,wtal].sx1))^2); distance between tangent altitude and 2*occalt
  psx1n=rad[wtal].mar*pdm[wtal].sx1 ;distance from MAVEN to tanalt point (km)

  nd=1000 ;integration elements
  dtad=tadsx1/double(nd) ;distance element (km)
  optdep=replicate(0d,[ntal,2])
  for id=0,nd do begin
    psx1v=(ones3#(psx1n+dtad*double(id)))*possx1_iau[*,wtal]+posmar_iau[*,wtal] ;sco x-1 path integration vector from Mars center in IAU_MARS coordinates
    mvn_altitude,cart=psx1v,datum='areoid',result=adat
    dens=10^(16-adat.alt/25.) ;density (cm-3)
    denswarm=10^(-1.3-adat.alt/20.) ;warm density (kg/m3)
    denscold=10^(-1.4-adat.alt/18.) ;cold density (kg/m3)
    optdep+=[[denswarm],[denscold]] ;kg/m3
  endfor
  sigma=1e-21 ;x-ray cross section (cm2)
  sco2=2.4 ;12 keV xsec (cm2/g)
  optdep*=2.*(sco2*1e-3)*(rebin(dtad,[ntal,2])*1e5)
  transm=exp(-optdep)

  store_data,'mvn_sep_xray_tanalt_d_(km)',times[wtal],tadsx1
  store_data,'mvn_sep_xray_optical_depth',data={x:times[wtal],y:optdep},dlim={ylog:1,yrange:[.01,100],constant:1,colors:'rb',labels:['warm','cold'],labflag:-1}
  store_data,'mvn_sep_xray_transmittance',data={x:times[wtal],y:transm},dlim={ylog:1,yrange:[.01,1],colors:'rb',labels:['warm','cold'],labflag:-1}
  store_data,'mvn_sep_xray_crate_model',data={x:times[wtal],y:5.*transm},dlim={ylog:1,yrange:[.1,10],colors:'rb',labels:['warm','cold'],labflag:-1}
  store_data,'mvn_sep1_xray_model-data',data='mvn_sep1_xray_crate mvn_sep_xray_crate_model
  store_data,'mvn_sep2_xray_model-data',data='mvn_sep2_xray_crate mvn_sep_xray_crate_model

  mvn_sep_fov.pos=pos
  mvn_sep_fov.tal=tal
  mvn_sep_fov.pdm=pdm
  mvn_sep_fov.rad=rad
  mvn_sep_fov.occ=occ
  mvn_sep_fov.att=att
  mvn_sep_fov.qrot=qrot
  mvn_sep_fov.qrot_iau=qrot_iau
  mvn_sep_fov.time=times


  dprint,'successfully saved sep fov data to mvn_sep_fov common block'

end