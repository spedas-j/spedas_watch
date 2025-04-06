;+
; Procedure:
;  lmn_matrix_make
;
; Purpose:
;  Creates a tplot variable, using the GSM to LMN transformation gsm2lmn.
;
; Parameters (required):
;     pos_var_name: Time and position in GSM coorinates.
;     mag_var_name: B field in GSM coordinates.
;     
; Keywords (optional):
;     swdata:  Solar wind data array (times, dynamic pressure, Bz).
;               If provided, this will be used instead of swdata_var_name.
;     swdata_var_name: Name of tplot variable containing solar wind data (times, dynamic pressure, Bz).
;     loadsolarwind: Flag indicating whether to load solar wind data from OMNI.
;     interpol_to_pos: Flag. If set, pos_var_name will be used for interpolation. If it is not set, mag_var_name will be used.
;     newname: Name for the output tplot variable. If not set, newname will be mag_var_name + "_lmn_mat"
;
; Notes:
;   This procedure uses solarwind_load for the solar wind parameters.
;
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2025-04-05 09:43:07 -0700 (Sat, 05 Apr 2025) $
;$LastChangedRevision: 33228 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/cotrans/lmn_transform/lmn_matrix_make.pro $
;-

pro lmn_matrix_make, pos_var_name, mag_var_name, swdata=swdata, swdata_var_name=swdata_var_name, loadsolarwind=loadsolarwind, $
   interpol_to_pos, newname=newname, _Extra=ex

  if ~keyword_set(pos_var_name) then begin
    dprint,'lmn_matrix_make requires pos_var_name to be set'
    return
  endif
  if ~keyword_set(mag_var_name) then begin
    dprint,'lmn_matrix_make requires mag_var_name to be set'
    return
  endif
  if ~keyword_set(newname) then begin
    newname = mag_var_name + "_lmn_mat"
  endif

  if keyword_set(interpol_to_pos) then begin
    ; Interpolate to position
    interpol_name = pos_var_name
    mag_temp = mag_var_name + '_temp'
    tinterpol, mag_var_name, interpol_name, newname=mag_temp

    get_data, mag_temp, data=db, limits=lb, dlimits=dlb
    Bxyz = db.y

    get_data, pos_var_name, data=dp, limits=lp, dlimits=dlp
    times = dp.x
    txyz = findgen(n_elements(times), 4)
    txyz[*, 0] = times
    txyz[*, 1] = dp.y[*, 0]
    txyz[*, 2] = dp.y[*, 1]
    txyz[*, 3] = dp.y[*, 2]
  endif else begin
    ; Interpolate to B field, the default
    interpol_name = mag_var_name
    pos_temp = pos_var_name + '_temp'
    tinterpol, pos_var_name, interpol_name, newname=pos_temp

    get_data, mag_var_name, data=db, limits=lb, dlimits=dlb
    Bxyz = db.y

    get_data, pos_temp, data=dp, limits=lp, dlimits=dlp
    times = dp.x
    txyz = findgen(n_elements(times), 4)
    txyz[*, 0] = times
    txyz[*, 1] = dp.y[*, 0]
    txyz[*, 2] = dp.y[*, 1]
    txyz[*, 3] = dp.y[*, 2]
  endelse

  if keyword_set(loadsolarwind) then begin
    ; If loadsolarwind keyword is set, use solarwind_load
    trange = [times[0], times[n_elements(times)-1]]
    solarwind_load, swdata, dst, trange, resol=3, hro=1, _Extra=ex
  endif else if keyword_set(swdata) then begin
    ; If swdata is set, use that (no changes)
  endif else if keyword_set(swdata_var_name) then begin
    ; If swdata_var_name is set, use that for swdata
    swdata_temp = swdata_var_name + '_temp'
    tinterpol, swdata_var_name, interpol_name, newname=swdata_temp
    get_data, swdata_temp, data=ds, limits=l, dlimits=dl
    swdata = ds.y
  endif

  ; Apply GSM to LMN
  gsm2lmn, txyz, Bxyz, Blmn, swdata

  ; Store output in tplot
  d_new = dlb
  str_element, d_new, 'ytitle', /delete
  str_element, d_new, 'ysubtitle', '[LMN]', /add
  str_element, d_new, 'data_att.coord_sys', 'LMN', /add
  str_element, d_new, 'labels', ['Bl', 'Bm', 'Bn'], /add
  store_data, newname, data={x:times, y:Blmn}, dlimits=d_new

  dprint, "LMN data saved in tplot variable: " + newname

end
