;20191002 Ali
;models the optical depth and transmittance of x-ray through the atmosphere of Mars as seen by MAVEN/SEP

pro mvn_sep_fov_xray_model

  @mvn_sep_fov_common.pro

  if ~keyword_set(mvn_sep_fov) then begin
    dprint,'sep fov data not loaded. Please run mvn_sep_fov first! returning...'
    return
  endif

  t1=systime(1)
  rmars=mvn_sep_fov0.rmars
  occalt=mvn_sep_fov0.occalt ;crossing altitude (km) maximum altitude for along path integration
  rad   =mvn_sep_fov.rad
  pos   =mvn_sep_fov.pos
  pdm   =mvn_sep_fov.pdm
  tal   =mvn_sep_fov.tal
  times =mvn_sep_fov.time
  ones3=replicate(1d,3)
  posmar_iau=quaternion_rotation(-pos.mar,mvn_sep_fov.qrot_iau,/last_ind)*(ones3#rad.mar) ;MAVEN position from Mars center in IAU_MARS
  possx1_iau=quaternion_rotation( pos.sx1,mvn_sep_fov.qrot_iau,/last_ind)

  nt=n_elements(times)
  ;  wtal=where((abs(pos[0,*].sx1) gt occos or abs(pos[2,*].sx1) gt occos) and tal[2,*].sx1 gt 0. and tal[2,*].sx1 lt occalt,ntal,/null)
  ntal=nt ;this ignores wtal above
  wtal=lindgen(nt)
  if ntal eq 0 then return
  tadsx1=sqrt((rmars+2.*occalt[1])^2-(rmars+reform(tal[2,wtal].sx1))^2); distance between tangent altitude and 2*occalt
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
  store_data,'mvn_sep1_xray_model-data',data='mvn_sep1_lowe_crate mvn_sep_xray_crate_model',dlim={yrange:[.1,1e2]}
  store_data,'mvn_sep2_xray_model-data',data='mvn_sep2_lowe_crate mvn_sep_xray_crate_model',dlim={yrange:[.1,1e2]}

  dprint,'elapsed time (s):',systime(1)-t1

end