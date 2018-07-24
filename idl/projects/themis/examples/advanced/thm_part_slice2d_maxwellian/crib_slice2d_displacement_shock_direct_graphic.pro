;+
;Crib:
;  crib_slice2d_displacement_shock_direct_graphic
;
;Purpose:
; This example follows crib_slice2d_displacment but operates with real data and 
; represents the case of the real distribution during the shock event.
; The crib can work in 2 modes with and without displacement
; 4 coordinate system can be used: DSL, GSE, GSM, Shock frame
; Displacement can be set to none, to maximum from 2d slices, to bulk velocity 
; and to custom vector   
; 
;Notes:
; This exmaple uses Direct Graphics to produce the image.
;
;$LastChangedBy: adrozdov $
;$LastChangedDate: 2018-07-23 16:27:29 -0700 (Mon, 23 Jul 2018) $
;$LastChangedRevision: 25510 $
;$URL:
;-

; === Setup ===

; flags and parameters
; DISPMODE - Displacement mode
;   'none' - don't use displacement, set to [0., 0., 0.]
;   'max' - calculate displacement, from 2d distributions Vx, Vy -> max(DF at x,y), Vz -> max(Df at x,z)
;   'bulk' - displacement is equal to the bulk velocity
;   'custom' - use cutrom_displacement vector
; CORDSYS - Coordinate system
;   'dsl' - DSL
;   'gse' - GSE
;   'gsm' - GSM
;   'shock' - shock frame defined by shock_l and shock_n vectors (x and normal)
; CROSSMODE - Shock cross on the figure
;   'none' - no cross
;   'max'  - determined max
;   'bulk' - bulk velocity
;   'disp' - displacement
; NORMPSD - Normalize DF
;    1 - f = DF/max(DF)
;    0 - f = DF
; 
; SAVEPS - Flag. Save graphics into ps file
;    psfilename - ps file name
;
; time_start - Time of the first frame 
; secwin - time window of frames.
; cutrom_displacement - vector of the custom center of the coordinate system (DISPMODE = 'custom')
; Vs - Shock speed. The axis in normalized to this value
; 

DISPMODE  = 'bulk' ; [none], [max], [bulk], [custom]
CORDSYS   = 'gse'  ; [dsl], [gse], [gsm], [shock]
CROSSMODE = 'none' ; [none], [max], [bulk], [disp]
NORMPSD  = 0 ; Normalize DF to max

SAVEPS  = 0 ; Output graphics into PostScript file
psfilename = 'crib_shock' ; ps filename if SAVEPS=1     

; basic settings
time_start = [time_double('2013-07-09/20:39:38')] ; Shock time is 2013-07-09/20:39:42
secwin = 4. ; time window
cutrom_displacement = [0., 0., 0.]
Vs = 146.0  ;shock speed. Vj = Vj/Vs

; load data
trange = '2013-07-09/' + ['20:39:00','20:40:20']
dist_arr = thm_part_dist_array(probe='c',type='peib', trange=trange) ;esa ion burst data
thm_load_fgm, probe='c', datatype = 'fgl', level=2, coord='gse', trange=trange
mag_data = 'thc_fgl_gse'

; Shock frame rotation
shock_l = [-0.166, 0.494, 0.853]
shock_n = [0.972, 0.227, 0.059]

; === Processing ===

; displacment variable
origin_shift = [0., 0., 0.]

xtitle=['V!Dx!N','V!Dx!N','V!Dy!N']
ytitle=['V!Dy!N','V!Dz!N','V!Dz!N']
ztitle=['V!Dz!N','V!Dy!N','V!Dx!N']

if CORDSYS eq 'shock' then begin
  xtitle=['V!Dn!N','V!Dn!N','V!Dm!N']
  ytitle=['V!Dm!N','V!Dl!N','V!Dl!N']
  ztitle=['V!Dl!N','V!Dm!N','V!Dn!N']
endif else begin
  ctitle = STRUPCASE(CORDSYS) + ' '
  xtitle=[ctitle+xtitle[0],ctitle+xtitle[1],ctitle+xtitle[2]]
  ytitle=[ctitle+ytitle[0],ctitle+ytitle[1],ctitle+ytitle[2]]
  ztitle=[ctitle+ztitle[0],ctitle+ztitle[1],ctitle+ztitle[2]]
endelse

rotation = ['xy','xz','yz']
letters=[['a','b','c'],['d','e','f'],['g','h','j']]

; image settings
tabno = 22 ; colors
defaulttabno = 43 ; colors

; axis ranges
xrange=[-4, 4]
yrange=[-4, 4]

;annotation position
textx = -1
texty = -3.5

; post-process
if NORMPSD then begin
  maxlog= 0
  minlog=-4
  psd_str = 'DF/max(DF)'
endif else begin
  maxlog=-6
  minlog=-10
  psd_str = 'DF'
endelse
; Settings for the images
i_struct = { zrange:[minlog, maxlog], xrange:xrange, yrange:yrange}
; Settings for the countour
c_struct = { overplot:1, levels:[minlog:maxlog], c_labels:intarr(abs(maxlog-minlog+1))+1}
; Settings for the data
t_struct = {timewin:secwin, count_threshold:1,MAG_DATA:mag_data,UNITS:'DF',smooth:2, three_d_interp:1, coord:'dsl'}

if CORDSYS eq 'gse' then t_struct.coord = 'gse'
if CORDSYS eq 'gsm' then t_struct.coord = 'gsm'

if CORDSYS eq 'shock' then begin
  t_struct.coord = 'gse'
  str_element, t_struct,'slice_norm',shock_l,/add
  str_element, t_struct,'slice_x',shock_n,/add
endif

;display
if SAVEPS then begin 
  popen, psfilename, /encap, /land, options={charsize:0.5}
endif else begin
  window, 0, xsize=1200, ysize=1000
endelse

loadct2, tabno

for r_idx=0,2 do begin
   
  if DISPMODE eq 'max' or CROSSMODE eq 'max' or DISPMODE eq 'bulk' or CROSSMODE eq 'bulk' then begin
    xyzarr = FLTARR(3,3)
    time = time_start + (r_idx)*secwin
    for c_idx=0,1 do begin
      thm_part_slice2d, dist_arr, rotation=rotation[c_idx], part_slice=slice, slice_time=time, _extra = t_struct
      xyidx = ARRAY_INDICES(slice.data, where(slice.data eq max(slice.data)))
      account = max(slice.data) gt 1e-8
      xyzarr[c_idx,*] = [slice.xgrid[xyidx[0]]*account, slice.ygrid[xyidx[1]]*account, account]
      if DISPMODE eq 'bulk' and (CROSSMODE eq 'bulk' or CROSSMODE eq 'disp') then c_idx = 1
    endfor

    if CROSSMODE eq 'bulk' then xyzarr2 = slice.bulk / Vs
    if DISPMODE  eq 'bulk' then origin_shift = slice.bulk / Vs    
    if CROSSMODE eq 'max'  then xyzarr2 = [xyzarr[0,0], xyzarr[0,1], xyzarr[1,1]] / Vs
    if DISPMODE  eq 'max' then origin_shift = xyzarr
  endif  
   if DISPMODE eq 'custom' then origin_shift = cutrom_displacement
   if CROSSMODE eq 'disp' then xyzarr2 = origin_shift
   
      
  for c_idx=0,2 do begin
    ; Time
    time = time_start + (r_idx)*secwin
    stitle = string(format='(%"%s-%s")', time_string(time, TFORMAT='hh:mm:ss'), time_string(time+secwin, TFORMAT='hh:mm:ss'))
        
    disp = origin_shift * Vs 
    
    thm_part_slice2d, dist_arr, rotation=rotation[c_idx], part_slice=slice, slice_time=time, $
      displacement=disp, _extra = t_struct    
         
    ; post_process
    if NORMPSD then begin
      log_psd=(alog10(slice.data/max(slice.data)))
    endif else begin
      log_psd=(alog10(slice.data))
    endelse
    
    slice.XGRID = (slice.XGRID)/Vs
    slice.YGRID = (slice.YGRID)/Vs


    ; === Direct Graphics Plot ===    
    mpanelstr = string(format='(%"%d,%d")',c_idx,r_idx)
    no_color_scale_opt = 1
    add_opt = 1
    if c_idx eq 2 then  no_color_scale_opt = 0
    if c_idx+r_idx eq 0 then begin
    plotxyz, slice.xgrid, slice.ygrid, log_psd, multi='3,3', mpanel = mpanelstr, no_color_scale=no_color_scale_opt, $ 
      xtitle = xtitle[c_idx], ytitle = ytitle[c_idx],ztitle = 'Log!D10!N('+ psd_str +')', title= letters[c_idx,r_idx] + ') ' + stitle, $
      mmargin=[0.01,0.005,0.01,0.02], xsize=1200, ysize=1000, _extra = i_struct
    endif else begin
      plotxyz, slice.xgrid, slice.ygrid, log_psd, mpanel = mpanelstr, no_color_scale=no_color_scale_opt, /addpanel, $
        xtitle = xtitle[c_idx], ytitle = ytitle[c_idx],ztitle = 'Log!D10!N('+ psd_str +')', title= letters[c_idx,r_idx] + ') ' + stitle, _extra = i_struct
    endelse
    contour, log_psd, slice.xgrid, slice.ygrid, _extra = c_struct
    xyouts, textx, texty, string(format='(%"%s = %5.2f")',ztitle[c_idx],origin_shift[2-c_idx])
  endfor
endfor

print, "ORIENTATION MATRIX:"
print, slice.ORIENT_MATRIX
if SAVEPS then pclose
loadct2, defaulttabno

end