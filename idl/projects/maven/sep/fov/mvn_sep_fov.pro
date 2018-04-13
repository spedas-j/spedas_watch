;20180405 Ali
;calculates a range of sep fov parameters for different celestial objects and stores them in common block and tplot variables
;fov calculations are done in maven_sep1 coordinates
;lowres: load sep lowres (5min average) data (use with /load keyword)
;tplot: save results in tplot variables and plot them
;load: load sep data
;spice: load spice data
;trange: specify trange
;resdeg: angular resolution for fov fraction calculations
;
pro mvn_sep_fov,lowres=lowres,tplot=tplot,load=load,spice=spice,trange=trange,resdeg=resdeg

  common mvn_sep_fov,mvn_sep_fov
  @mvn_sep_handler_commonblock.pro
  rmars=3390. ;km

  if keyword_set(lowres) then lrs='5min_' else lrs=''
  if keyword_set(trange) then timespan,trange
  if keyword_set(spice) then mvn_spice_load
  if keyword_set(load) then mvn_sep_var_restore,lowres=lowres,/basic,units='Rate'

  if ~keyword_set(sep1_svy) then begin
    dprint,'sep data not loaded. Please run with /load keyword. returning...'
    return
  endif

  fnan=!values.f_nan
  map1=mvn_sep_get_bmap(9,1)
  sep1=*(sep1_svy.x)
  sep2=*(sep2_svy.x)
  times=sep1.time
  nt=n_elements(times)
  ones3 =replicate(1.,3)

  objects=['sun','earth','mars','jupiter_barycenter']
  nobj=n_elements(objects)
  pos=replicate({sun:fnan,ear:fnan,mar:fnan,jup:fnan,cm1:fnan,sx1:fnan,cx1:fnan},[3,nt])
  observer='maven'
  to_frame='maven_sep1'
  for iobj=0,nobj-1 do begin
    pos.(iobj)=spice_body_pos(objects[iobj],observer,frame=to_frame,utc=times,check_objects=[objects[iobj],observer,'maven_spacecraft'],/force_objects) ;position (km)
    dist=sqrt(total(pos.(iobj)^2,1)) ;distance (km)
    if objects[iobj] eq 'mars' then begin
      mvnrad=dist ;maven radial distance from mars (km)
      posmar=pos.(iobj)
    endif
    pos.(iobj)/=(ones3#dist)
  endfor

  marsur=sqrt(1.-(rmars/mvnrad)^2) ;dot product of mars surface by mars center
  mar100=sqrt(1.-((rmars+100.)/mvnrad)^2)
  alt=mvnrad-rmars ;altitude (km)
  hialt=alt gt 1000.
  ;new=times gt time_double('18-2-4') lt time_double('18-2-5')
  whr=where(hialt)
  ;whr=lindgen(nt)

  from_frame='j2000'
  qrot=spice_body_att(from_frame,to_frame,times,/quaternion,check_objects=[observer,'maven_spacecraft'],/force_objects)
  ;m1=[0.102810,0.921371,0.374841] ;crab nebula coordinates in J2000 from NAIF
  ;cbnm1rd=[05h 34m 31.94s , +22° 00′ 52.2″] ;Crab Nebula (M1) Right Ascention/Declination
  ;scox1rd=[16h 19m 55.07s , −15° 38' 24.8"] ;Scorpius X-1
  ;cygx1rd=[19h 58m 21.67s , +35° 12′ 05.8″] ;Cygnus X-1
  cm1r=!pi*[360.*(5. +34./60.+31.94/60./60.)/24., 22.+00./60.+52.2/60./60.]/180. ;radians
  sx1r=!pi*[360.*(16.+19./60.+55.07/60./60.)/24.,-15.+38./60.+52.2/60./60.]/180.
  cx1r=!pi*[360.*(19.+58./60.+21.67/60./60.)/24.,+35.+12./60.+05.8/60./60.]/180.
  cm1=[cos(cm1r[0])*cos(cm1r[1]),sin(cm1r[0])*cos(cm1r[1]),sin(cm1r[1])] ;should be equal to m1 above
  sx1=[cos(sx1r[0])*cos(sx1r[1]),sin(sx1r[0])*cos(sx1r[1]),sin(sx1r[1])]
  cx1=[cos(cx1r[0])*cos(cx1r[1]),sin(cx1r[0])*cos(cx1r[1]),sin(cx1r[1])]
  pos.cm1=quaternion_rotation(cm1,qrot,/last_ind)
  pos.sx1=quaternion_rotation(sx1,qrot,/last_ind)
  pos.cx1=quaternion_rotation(cx1,qrot,/last_ind)

  pdm=reform(pos[0,*]) ;position dot mars (for occultation)
  tal=pdm ;tangent altitude (km)
  tag=strlowcase(tag_names(pdm))
  npos=n_tags(pos)
  for ipos=0,npos-1 do begin
    pdm.(ipos)=total(pos.(ipos)*pos.mar,1)
    tal.(ipos)=mvnrad*sqrt(1.-pdm.(ipos)^2)-rmars
    wpdmlt0=where(pdm.(ipos) lt 0.,/null)
    if n_elements(wpdmlt0) gt 0 then tal[wpdmlt0].(ipos)=alt[wpdmlt0]
    if keyword_set(tplot) then store_data,'mvn_sep_dot_'+tag[ipos],times,transpose(pos.(ipos)),dlim={yrange:[-1,1],constant:0.,colors:'bgr',labels:['SEP1','SEP1y','SEP2'],labflag:-1,ystyle:2}
  endfor
  pdm.mar=marsur

  detlab=['A-F','B-F','B-O','A-O','A-T','B-T']
  ndet=n_elements(detlab)
  sep1crl=replicate(fnan,[nt,ndet])
  sep1crh=sep1crl
  sep2crl=sep1crl
  sep2crh=sep1crl
  for idet=0,ndet-1 do begin
    ;get_data,'mvn_'+lrs+'sep'+strtrim(isep+1,2)+'_'+detlab[idet]+'_Rate_Energy',dat=sepdat
    ind=where(map1.name eq detlab[idet])
    sep1crl[*,idet]=total(sep1.data[ind[0]+0:ind[0]+5],1,/nan)/sep1.delta_time ;low  energy count rate
    sep1crh[*,idet]=total(sep1.data[ind[0]+6:ind[0]+9],1,/nan)/sep1.delta_time ;high energy count rate (for hi background elimination)
    sep2crlinterpol=total(sep2.data[ind[0]+0:ind[0]+5],1,/nan)/sep2.delta_time
    sep2crhinterpol=total(sep2.data[ind[0]+6:ind[0]+9],1,/nan)/sep2.delta_time
    sep2crlinterpol[where(sep2crlinterpol eq 0.,/null)]=fnan ;getting rid of zeros (kluge)
    sep2crhinterpol[where(sep2crhinterpol eq 0.,/null)]=fnan
    sep2crl[*,idet]=interpol(sep2crlinterpol,sep2.time,times,/nan)
    sep2crh[*,idet]=interpol(sep2crhinterpol,sep2.time,times,/nan)
  endfor

  occsx1=replicate(0,nt) ;occultation flag
  horcro=(tal.sx1*shift(tal.sx1,1)) lt 0. ;crossed the horizon
  occsx1[where((pos[0,*].sx1 gt +.9) and horcro,/null)]=1 ;sep1f
  occsx1[where((pos[2,*].sx1 gt +.9) and horcro,/null)]=2 ;sep2f
  occsx1[where((pos[0,*].sx1 lt -.9) and horcro,/null)]=3 ;sep1r
  occsx1[where((pos[2,*].sx1 lt -.9) and horcro,/null)]=4 ;sep2r

  if keyword_set(tplot) then begin
    store_data,'mvn_mars_dot_object',data={x:times,y:[[pdm.cm1],[pdm.sx1],[pdm.cx1],[pdm.jup],[pdm.sun],[pdm.mar]]},dlim={colors:'kbcmrg',labels:['Crab','Sco X1','Cyg X1','Jupiter','Sun','Surface'],labflag:-1,ystyle:2,constant:0}
    store_data,'mvn_mars_tanalt(km)',data={x:times,y:[[tal.cm1],[tal.sx1],[tal.cx1],[tal.jup],[tal.sun]]},dlim={colors:'kbcmr',labels:['Crab','Sco X1','Cyg X1','Jupiter','Sun'],labflag:-1,ystyle:2,constant:0}
    store_data,'mvn_sep_sx1_occultation',data={x:times,y:occsx1},dlim={panel_size:.5,yrange:[0,5]}

    dlim={colors:'rmbkgc',labels:detlab,labflag:-1,ystyle:2,ylog:1}
    store_data,'mvn_sep1_xray_crate',data={x:times,y:sep1crl},dlim=dlim
    store_data,'mvn_sep2_xray_crate',data={x:times,y:sep2crl},dlim=dlim
    store_data,'mvn_sep1_xray_crate_hi',data={x:times,y:sep1crh},dlim=dlim
    store_data,'mvn_sep2_xray_crate_hi',data={x:times,y:sep2crh},dlim=dlim

    dprint,'calculating mars shine. this might take a while to complete...'
    fraction=mvn_sep_fov_mars_shine(rmars,posmar,pos.sun,resdeg=resdeg,/fov)
;   fraction2=mvn_sep_anc_fov_mars_fraction(times,check_objects=['MAVEN_SC_BUS']) ;Rob's routine (slow)
    for isep=0,3 do store_data,'mvn_sep'+(['1f','2f','1r','2r'])[isep]+'_fov_fraction',data={x:times,y:transpose([fraction.mars_surfa[isep,*],fraction.mars_shine[isep,*],fraction.mshine_fov[isep,*]])},dlim={colors:'brm',labels:['Disc','Shine','shfov'],labflag:-1,ystyle:2,ylog:1,yrange:[.01,1]}

    tplot,'mvn_sep??_fov_fraction mvn_sep_dot_sun mvn_sep_dot_sx1 mvn_mars_dot_object mvn_mars_tanalt(km) mvn_sep_sx1_occultation mvn_sep?_xray_crate* mvn_'+lrs+'SEPS_svy_ATT'
  endif
  ;tplot,mvn_'+lrs+'sep?_?-?_Rate_Energy,/add

  ;p=plot(sep2sx1[whr],sep2ao.y[whr,0],'.',/ylog,xtitle='sep2.m1',ytitle='sep2_AO_0')
  ;crsep2bfbin=average_hist(sep2crl[whr,1],tal[whr].sx1,binsize=10.,xbins=taltsx1bin)
  ;p=plot(sep2crl[whr,1],tal[whr].sx1,/xlog,xrange=[.1,10],yrange=[-100,200],'.',xtitle='SEP2-BF Count Rate (Hz)',ytitle='Sco X-1 Tangent Altitude (km)')
  ;p=plot(crsep2bfbin,taltsx1bin,/o)

  watt1=where(sep1.att gt 1.,/null) ;closed attenuator
  sepcrl=[[[sep1crl]],[[sep2crl]]]
  sepcrh=[[[sep1crh]],[[sep2crh]]]
  wgcr=where(sepcrh gt 3.,/null) ;high background
  sepcrl[wgcr]=fnan

  mvn_sep_fov={pos:pos,pdm:pdm,tal:tal,times:times,rmars:rmars,posmar:posmar} ;saving results to common block
  dprint,'successfully saved sep fov data to mvn_sep_fov common block'
end