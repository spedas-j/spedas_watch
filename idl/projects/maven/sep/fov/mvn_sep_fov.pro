;20180405 Ali
;calculates a range of sep fov parameters for different celestial objects and stores them in common block and tplot variables
;fov calculations are done in maven_sep1 coordinates
;lowres: load sep lowres (5min average) data (use with /load keyword)
;tplot: tplot results
;load: load sep data
;spice: load spice data
;trange: specify trange
;arc: loads sep archive (burst) data
;restore: restore the 5min averaged (lowres) results in the common block
;occalt: tangent altitude at which occultation happens
;times: manually input times. e.g., useful for future predict calculations where no sep data is available
;
pro mvn_sep_fov,lowres=lowres,tplot=tplot,load=load,spice=spice,trange=trange,arc=arc,restore=restore,occalt=occalt,times=times

  @mvn_sep_fov_common.pro
  @mvn_sep_handler_commonblock.pro

  if keyword_set(restore) then begin
    restore,file='/home/rahmati/Desktop/sep/sep x-rays/mvn_sep_fov_5min_140922_180630.sav'
    ;   restore,file='/home/rahmati/Desktop/sep/sep x-rays/sep_svy_5min_data_140922_180630.sav'
    return
  endif

  if keyword_set(trange) then timespan,trange
  if keyword_set(times) then timespan,minmax(times)
  if keyword_set(spice) then mvn_spice_load
  if keyword_set(load) then mvn_sep_var_restore,lowres=lowres,/basic,units='Rate'

  if ~keyword_set(times) then begin
    if ~keyword_set(sep1_svy) then begin
      dprint,'sep data not loaded. Please run with /load keyword. returning...'
      return
    endif

    if keyword_set(arc) then sep1=*(sep1_arc.x) else sep1=*(sep1_svy.x)
    if ~keyword_set(sep1) then begin
      dprint,'no sep data available for selected time range. returning...'
      return
    endif
    times=sep1.time
    to_frame='maven_sep1'
  endif else to_frame='MSO'

  if ~keyword_set(occalt) then occalt=110.
  objects=['sun','earth','mars','phobos','deimos']
  mvn_sep_fov0={rmars:3390.d,$ ;km (not accurate)
    detlab:['A-O','A-T','A-F','B-O','B-T','B-F'],$ ;single detector label
    detcol:['k',  'g',  'r',  'b',  'c',  'm']  ,$ ;single detector color
    lowres:keyword_set(lowres)                  ,$
    arc:keyword_set(arc)                        ,$
    occalt:occalt                               ,$
    objects:objects                              $
  }

  nt=n_elements(times)
  nobj=n_elements(objects)
  fnan=!values.d_nan ;dnan really!
  pos=replicate({sun:fnan,ear:fnan,mar:fnan,pho:fnan,dem:fnan,cm1:fnan,sx1:fnan,mnp:fnan},[3,nt])
  tal=pos ;tangent altitude (km) ['sphere','ellipsoid','areoid']
  pdm=reform(pos[0,*]) ;position dot mars (for occultation)
  rad=pdm ;radial distance from the center of the object (km)
  occ=pdm ;occultation flag

  observer='maven'
  check_maven=to_frame eq 'maven_sep1' ? 'maven_spacecraft':'maven'
  for iobj=0,nobj-1 do begin
    pos.(iobj)=spice_body_pos(objects[iobj],observer,frame=to_frame,utc=times,check_objects=[objects[iobj],observer,check_maven],/force_objects) ;position (km)
    rad.(iobj)=sqrt(total(pos.(iobj)^2,1)) ;distance (km)
    pos.(iobj)/=replicate(1.d,3)#rad.(iobj)
  endfor

  from_frame='j2000'
  qrot=spice_body_att(from_frame,to_frame,times,/quaternion,check_objects=check_maven,/force_objects)
  ;  from_frame='IAU_MARS'
  ;  zdir=[0.,0.,1.] ;Mars North pole in IAU_MARS (oblate spheroid symmetry axis)
  ;  pos.mnp=spice_vector_rotate(zdir,times,from_frame,to_frame,check_objects=check_maven,/force_objects) ;Mars North pole in sep1 coordinates
  qrot_iau=spice_body_att(to_frame,'IAU_MARS',times,/quaternion,check_objects=check_maven,/force_objects)

  mvn_sep_fov=replicate({pos:pos[*,0],rad:rad[0],pdm:pdm[0],occ:occ[0],tal:tal[*,0],qrot:qrot[*,0],qrot_iau:qrot_iau[*,0],time:times[0],att:[0.,0.],crl:fltarr(2,6),crh:fltarr(2,6)},nt) ;saving results to common block
  mvn_sep_fov.pos=pos
  mvn_sep_fov.rad=rad
  mvn_sep_fov.qrot=qrot
  mvn_sep_fov.qrot_iau=qrot_iau
  mvn_sep_fov.time=times

  mvn_sep_fov_calc

  if keyword_set(tplot) then mvn_sep_fov_tplot,/tplot,/store,/nofrac

end