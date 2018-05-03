;20180419 Ali
;calculates a bunch of parameters for mvn_sep_fov

pro mvn_sep_fov_calc,arc=arc

  @mvn_sep_fov_common.pro
  @mvn_sep_handler_commonblock.pro

  pos=mvn_sep_fov.pos
  rad=mvn_sep_fov.rad
  pdm=mvn_sep_fov.pdm
  tal=mvn_sep_fov.tal
  qrot=mvn_sep_fov.qrot

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
  ;  pos.cx1=quaternion_rotation(cx1,qrot,/last_ind)

  marsur=sqrt(1.-(rmars/rad.mar)^2) ;dot product of mars surface by mars center
  mar100=sqrt(1.-((rmars+100.)/rad.mar)^2)
  alt=rad.mar-rmars ;altitude (km)
  npos=n_tags(pos)
  for ipos=0,npos-1 do begin
    pdm.(ipos)=total(pos.(ipos)*pos.mar,1)
    tal.(ipos)=rad.mar*sqrt(1.d0-pdm.(ipos)^2)-rmars
    wpdmlt0=where(pdm.(ipos) lt 0.,/null)
    if n_elements(wpdmlt0) gt 0 then tal[wpdmlt0].(ipos)=alt[wpdmlt0]
  endfor
  pdm.mar=marsur
  tal.mar=alt

  map1=mvn_sep_get_bmap(9,1)
  if keyword_set(arc) then begin
    sep1=*(sep1_arc.x)
    sep2=*(sep2_arc.x)
  endif else begin
    sep1=*(sep1_svy.x)
    sep2=*(sep2_svy.x)
  endelse
  times=sep1.time
  nt=n_elements(times)
  ndet=n_elements(detlab)
  for idet=0,ndet-1 do begin
    ;get_data,'mvn_'+lrs+'sep'+strtrim(isep+1,2)+'_'+detlab[idet]+'_Rate_Energy',dat=sepdat
    ind=where(map1.name eq detlab[idet])
    mvn_sep_fov.crl[0,idet]=total(sep1.data[ind[0]+0:ind[0]+5],1)/sep1.delta_time ;low  energy count rate
    mvn_sep_fov.crh[0,idet]=total(sep1.data[ind[0]+6:ind[0]+9],1)/sep1.delta_time ;high energy count rate (for hi background elimination)
    sep2crl_before_interpol=total(sep2.data[ind[0]+0:ind[0]+5],1)/sep2.delta_time
    sep2crh_before_interpol=total(sep2.data[ind[0]+6:ind[0]+9],1)/sep2.delta_time
    mvn_sep_fov.crl[1,idet]=exp(interpol(alog(sep2crl_before_interpol),sep2.time,times,/nan))
    mvn_sep_fov.crh[1,idet]=exp(interpol(alog(sep2crh_before_interpol),sep2.time,times,/nan))
  endfor

  sep2_att=exp(interpol(alog(sep2.att),sep2.time,times,/nan))
  att=transpose([[sep1.att],[sep2_att]])

  occsx1=replicate(0,nt) ;occultation flag
  crosalt=100. ;crossing altitude
  horcro=((tal.sx1-crosalt)*shift((tal.sx1-crosalt),1)) lt 0. ;crossed the crosalt
  occos=cos(!dtor*10.) ;within 10 degrees of detector fov center
  occsx1[where((pos[0,*].sx1 gt +occos) and horcro and att[0,*] eq 1.,/null)]=1 ;sep1f
  occsx1[where((pos[2,*].sx1 gt +occos) and horcro and att[1,*] eq 1.,/null)]=2 ;sep2f
  occsx1[where((pos[0,*].sx1 lt -occos) and horcro and att[0,*] eq 1.,/null)]=3 ;sep1r
  occsx1[where((pos[2,*].sx1 lt -occos) and horcro and att[1,*] eq 1.,/null)]=4 ;sep2r
  occtimes=where(occsx1 ne 0,/null)

  mvn_sep_fov.pos=pos
  mvn_sep_fov.pdm=pdm
  mvn_sep_fov.tal=tal
  mvn_sep_fov.att=att
  mvn_sep_fov.occsx1=occsx1
  dprint,'successfully saved sep fov data to mvn_sep_fov common block'

end