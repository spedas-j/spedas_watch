;+
;PROCEDURE: elf_get_att
;
;PURPOSE:
; This routine will get the latest elfin attitude information. tplot variables created include
;     ela_att_gei, ela_att_last_solution, ela_spin_norm_ang, and ela_spin_sun_ang, ela_pos_gei
;     and ela_vel_gei 
;     NOTE: This routine can also be called from the elf_load_state routine by using the keyword
;           /get_att
; 
;KEYWORDS
;    trange: time range of interest [starttime, endtime] with the format
;                ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;                ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;    probe:  elf probes include 'a', or 'b'
;
;EXAMPLE:
;    ela_get_att, trange=['2019-07-15','2019-07-16'], probe='a'
;
;-
pro elf_get_att, trange=trange, probe=probe

  ;Initialize variables if not set as parameters
  if undefined(probe) then probe='a'
  sc='el'+probe
  if (~undefined(trange) && n_elements(trange) eq 2) && (time_double(trange[1]) lt time_double(trange[0])) then begin
    dprint, dlevel = 0, 'Error, endtime is before starttime; trange should be: [starttime, endtime]'
    return
  endif
  if ~undefined(trange) && n_elements(trange) eq 2 $
    then tr = timerange(trange) $
  else tr = timerange()

  ; check if attitude data already exists for this timeframe (if so no need to reload)
  if spd_data_exists(sc+'_att_gei',time_string(tr[0]),time_string(tr[1])) then begin
     get_data, sc+'_att_gei', data=att
     store_data, sc+'_att_last_solution', data={x:att.x}  
  endif else begin
    ; remove any other att data
    del_data, sc+'_att_gei'
    del_data, sc+'_att_last_solution'    
    day_count = 0
    ; find the most recent attitude solution  
    while (day_count LT 50) do begin
        elf_load_state, probe=probe, trange=tr, suffix='_temp'
        if tnames(sc+'_att_gei_temp') eq sc+'_att_gei_temp' then break
        tr=tr-86400.
        day_count = day_count + 1
    endwhile 
    ; fix time stamp if not on same day
    ; create att last solution var
    if tnames(sc+'_att_gei_temp') ne sc+'_att_gei_temp' then begin
       print, 'Unable to retrieve attitude data within 50 days of start time.' 
    endif else begin
       midtr=time_double(tr[0])+(86400./2.)
       get_data, sc+'_att_gei_temp', data=att, dlimits=dl, limits=l
       last_solution = att.x[0]
       att.x[0] = midtr
       store_data, sc+'_att_gei', data=att, dlimits=dl, limits=l
       store_data, sc+'_att_last_solution', data={x:last_solution}    
    endelse
    tn=tnames(sc+'*_temp')
    if tn[0] ne '' then del_data, tn
  endelse
  
  ; load pos and vel data if needed
  if ~spd_data_exists(sc+'_pos_gei',time_string(tr[0]),time_string(tr[1])) then elf_load_state, probe=probe, trange=tr
  get_data, sc+'_pos_gei', data=pos
  if size(pos, /type) ne 8 then begin
    print, 'No position data available.'
    return
  endif
  if ~spd_data_exists(sc+'_vel_gei',time_string(tr[0]),time_string(tr[1])) then elf_load_state, probe=probe, trange=tr
  get_data, sc+'_vel_gei', data=vel1
  if size(vel1, /type) ne 8 then begin
    print, 'No velocity data available.'
    return
  endif

  ; interpolate pos and velocity to attitude time  
  posx=interp(pos.y[*,0], pos.x, att.x)
  posy=interp(pos.y[*,1], pos.x, att.x)
  posz=interp(pos.y[*,2], pos.x, att.x)
  velx=interp(vel1.y[*,0], vel1.x, att.x)
  vely=interp(vel1.y[*,1], vel1.x, att.x)
  velz=interp(vel1.y[*,2], vel1.x, att.x)
  pos1=[[posx],[posy],[posz]]
  vel1=[[velx],[vely],[velz]]
  ; calculate angle between spin vector and orbit normal
  orb_norm=crossp2(reform(pos1), reform(vel1))
  spin_norm_ang=get_vec_ang(reform(att.y),(orb_norm))
  store_data, sc+'_spin_norm_ang', data={x:att.x, y:spin_norm_ang}
 
  ; get the sun position 
  thm_load_slp, datatype='sun_pos', trange=tr
  get_data, 'slp_sun_pos', data=sun1
  if size(sun1, /type) ne 8 then begin
    print, 'No sun position data available.'
    return
  endif
  sunx=interp(sun1.y[*,0], sun1.x, att.x)
  suny=interp(sun1.y[*,1], sun1.x, att.x)
  sunz=interp(sun1.y[*,2], sun1.x, att.x)
  sun1=[[sunx],[suny],[sunz]]
  spin_sun_ang=get_vec_ang(reform(att.y),reform(sun1))
  store_data, sc+'_spin_sun_ang', data={x:att.x, y:spin_sun_ang}
  
  ; remove tplot variable for sun position
  del_data, 'slp_sun_pos'
  
end
