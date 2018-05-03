;20180405 Ali
;calculates a range of sep fov parameters for different celestial objects and stores them in common block and tplot variables
;fov calculations are done in maven_sep1 coordinates
;lowres: load sep lowres (5min average) data (use with /load keyword)
;tplot: tplot results
;load: load sep data
;spice: load spice data
;trange: specify trange
;
pro mvn_sep_fov,lowres=lowres,tplot=tplot,load=load,spice=spice,trange=trange,arc=arc

  @mvn_sep_fov_common.pro
  @mvn_sep_handler_commonblock.pro
  rmars=3390.d ;km

;  if keyword_set(lowres) then lrs='5min_' else lrs=''
  if keyword_set(trange) then timespan,trange
  if keyword_set(spice) then mvn_spice_load
  if keyword_set(load) then mvn_sep_var_restore,lowres=lowres,/basic,units='Rate'

  if ~keyword_set(sep1_svy) then begin
    dprint,'sep data not loaded. Please run with /load keyword. returning...'
    return
  endif
  
  if keyword_set(tplot) then begin
    mvn_sep_fov_tplot,/tplot,lowres=lowres
    return
  endif

  if keyword_set(arc) then sep1=*(sep1_arc.x) else sep1=*(sep1_svy.x)
  if ~keyword_set(sep1) then begin
    dprint,'no sep data available for selected time range. returning...'
    return
  endif

  times=sep1.time
  nt=n_elements(times)
 
  objects=['sun','earth','mars','phobos','deimos']
  nobj=n_elements(objects)
  fnan=!values.d_nan ;dnan really!
  pos=replicate({sun:fnan,ear:fnan,mar:fnan,pho:fnan,dem:fnan,cm1:fnan,sx1:fnan},[3,nt])
  rad=reform(pos[0,*]) ;radial distance from the center of the object (km)
  pdm=rad ;position dot mars (for occultation)
  tal=rad ;tangent altitude (km)

  observer='maven'
  to_frame='maven_sep1'
  for iobj=0,nobj-1 do begin
    pos.(iobj)=spice_body_pos(objects[iobj],observer,frame=to_frame,utc=times,check_objects=[objects[iobj],observer,'maven_spacecraft'],/force_objects) ;position (km)
    rad.(iobj)=sqrt(total(pos.(iobj)^2,1)) ;distance (km)
    pos.(iobj)/=replicate(1.d,3)#rad.(iobj)
  endfor

  from_frame='j2000'
  qrot=spice_body_att(from_frame,to_frame,times,/quaternion,check_objects=[observer,'maven_spacecraft'],/force_objects)

  detlab=['A-F','B-F','B-O','A-O','A-T','B-T'] ;single detector label
  mvn_sep_fov=replicate({pos:pos[*,0],rad:rad[0],pdm:pdm[0],tal:tal[0],qrot:qrot[*,0],time:times[0],occsx1:0,att:[0.,0.],crl:fltarr(2,6),crh:fltarr(2,6)},nt) ;saving results to common block
  mvn_sep_fov.pos=pos
  mvn_sep_fov.rad=rad
  mvn_sep_fov.qrot=qrot
  mvn_sep_fov.time=times

  mvn_sep_fov_calc,arc=arc
end