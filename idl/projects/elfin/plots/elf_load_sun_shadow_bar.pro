;+
; PROCEDURE:
;         elf_load_sun_shadow_bar
;
; PURPOSE:
;         Loads the survey segment intervals into a bar that can be plotted
;
; KEYWORDS:
;         tplotname:    name of tplot variable (should be ela_fgs or elb_fgs)
;         probe:        name of probe 'a', or 'b'
;         type:         type 'fgf' or 'fgs'
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-08-08 09:33:48 -0700 (Tue, 08 Aug 2017) $
;$LastChangedRevision: 23763 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/elf/common/data_status_bar/elf_load_fast_segments.pro $
;-

pro elf_load_sun_shadow_bar, tplotname=tplotname

  get_data, tplotname, data=elfin_pos
  shadflag = intarr(n_elements(elfin_pos.x))
  yre=elfin_pos.y[*,1]/6378.
  zre=elfin_pos.y[*,2]/6378.
  yz_re=yre^2 + zre^2
  shad_idx = where(elfin_pos.y[*,0] LT 0.0 AND yz_re LT 1.0, n_shadow)
  shadflag[shad_idx] = 1
  find_interval, shad_idx, sidx, eidx
  start_times=elfin_pos.x[sidx]
  end_times=elfin_pos.x[eidx]

  for idx=0,n_elements(sidx)-1 do begin  
    append_array, shadow_bar_x, [start_times[idx], start_times[idx], end_times[idx], end_times[idx]]
    append_array, shadow_bar_y, [!values.f_nan, 0.,0., !values.f_nan]
  endfor

  if undefined(shadow_bar_x) then return
 
  store_data, 'shadow_bar', data={x:shadow_bar_x, y:shadow_bar_y} 
  options,'shadow_bar',thick=5.5,xstyle=4,ystyle=4,yrange=[-0.1,0.1],ytitle='',$
    ticklen=0,panel_size=0.1, charsize=2.

  sun_bar_x=[elfin_pos.x[0],elfin_pos.x[0],elfin_pos.x[n_elements(elfin_pos.x)-1],elfin_pos.x[n_elements(elfin_pos.x)-1]]
  sun_bar_y=[!values.f_nan, 0.,0., !values.f_nan]
  store_data, 'sun_bar', data={x:sun_bar_x, y:sun_bar_y}
  options,'sun_bar',thick=5.5,xstyle=4,ystyle=4,yrange=[-0.1,0.1],ytitle='',$
    ticklen=0,panel_size=0.1,colors=5, charsize=2.

  store_data, 'sunlight_bar', data=['sun_bar','shadow_bar']
  options, 'sunlight_bar', panel_size=0.1
  options, 'sunlight_bar',ticklen=0
  options, 'sunlight_bar', 'ystyle',4
  options, 'sunlight_bar', 'xstyle',4
  options, 'sunlight_bar', yrange=[-0.1,0.1]
end