;+
; NAME:
;    ELF_MAP_STATE_T96_INTERVALS
;
; PURPOSE:
;    map ELFIN spacecraft to their magnetic footprints
;
; CATEGORY:
;    None
;
; CALLING SEQUENCE:
;    elf_map_state_t96_intervals,'2018-11-10/00:00:00'
;
; INPUTS:
;    tstart start time for the map
;
; OPTIONAL INPUTS:
;    None
;
; KEYWORD PARAMETERS:
;    gifout   generate a gif image at output
;    south    use southern hemisphere (otherwise, north)
;    noview   do not open window for display
;    move     move file to summary plot directory
;    model    specify Tsyganenko model like 't89' or 't01', default is 't96'
;    dir_move directory name to move plots to
;
; OUTPUTS:
;    None
;
; OPTIONAL OUTPUTS:
;    GIF images
;
; COMMON BLOCKS:
;    None
;
; SIDE EFFECTS:
;    Needs subroutines mpause_2
;
; RESTRICTIONS:
;    None
;
; EXAMPLE:
;    elf_map_state_t96_intervals,'2018-11-10/00:00:00'
;
; MODIFICATION HISTORY:
;    Written by: Harald Frey  some time 2007
;                Version 2.0 August, 25, 2011, fixed:
;     - T96
;
; VERSION:
;   $LastChangedBy:
;   $LastChangedDate:
;   $LastChangedRevision:
;   $URL:
;
;-

pro elf_map_state_t96_intervals, tstart, gifout=gifout, south=south, noview=noview,$
  move=move, model=model, dir_move=dir_move, insert_stop=insert_stop, $
  no_trace=no_trace, tstep=tstep, clean=clean

  ; ACN
  pro_start_time=SYSTIME(/SECONDS)
  print, SYSTIME(), ' -- Creating overview plots'

  if (time_double(tstart) lt time_double('2018-09-16')) then begin
    print,'Time before ELFIN launch'
    return
  endif

  ; some setup
  if keyword_set(dir_move) then begin
    dir_products=dir_move
  endif
  if ~keyword_set(quick) then quick=1

  elf_init
  aacgmidl
  loadct,39
  thm_init
  
  ;if !d.name EQ 'WIN' then set_plot,'win' else set_plot,'x'
  set_plot,'z'
  device,set_resolution=[750,500]
  tvlct,r,g,b,/get

  ; colors and symbols, closest numbers for loadct,39
  symbols=[4, 2]  ;[5,2,1,4,6]
  probes=['a','b']
  index=[254,253,252]  ;,252,253,254]

  ; color=253 will be dark blue for ELFIN A
  ;A dark blue  [0,0,255],    57 IDL symbol 4
  ;r[index[0]]=0   & g[index[0]]=0   & b[index[0]]=255
;  r[index[0]]=30   & g[index[0]]=144   & b[index[0]]=255
  ; color=254 will be green for ELFIN B
  ;A dark blue  [0,0,255],    57 IDL symbol 4
  ;A orange
   r[index[0]]=255 & g[index[0]]=99 & b[index[0]]=71
  ;B blue     [0,255,0],   30 IDL symbol 6
   r[index[1]]=0 & g[index[1]]=0  & b[index[1]]=255
  ;  r[index[1]]=138 & g[index[1]]=43   & b[index[1]]=226
  r[index[2]]=170 & g[index[2]]=170 & b[index[2]]=170
  tvlct,r,g,b

  ; time input
  timespan,tstart,1,/day
  tr=timerange()
  tr[1]=tr[1]+60.*30
  tend=time_string(time_double(tstart)+86400.0d0)
  sphere=1
  lim=2
  earth=findgen(361)

  ; average solar wind conditions
  dst=-10.
  dynp=2.
  bswx=2.
  bswy=-2.
  bswz=-1.
  swv=400.  ; default
  bp = sqrt(bswy^2 + bswz^2)/40.
  hb = (bp^2)/(1.+bp)
  bs = abs(bswz<0)
  th = atan(bswy,bswz)
  g1 = swv*hb*sin(th/2.)^3
  g2 = 0.005 * swv*bs
  if keyword_set(model) then tsyg_mod=model else tsyg_mod='t96'

  ; now loop through spacecraft
  for sc=0,1 do begin

    ; need to reset timespan (attitude solution could be days old)
    timespan,tstart,88200.,/sec
    tr=timerange()
    elf_load_state,probe=probes[sc]
    get_data,'el'+probes[sc]+'_pos_gei',data=dats, dlimits=dl, limits=l  ; position in GEI

    ; Coordinate transform from gei to sm
    cotrans, 'el'+probes[sc]+'_pos_gei', 'el'+probes[sc]+'_pos_gse', /gei2gse
    cotrans, 'el'+probes[sc]+'_pos_gei', 'el'+probes[sc]+'_pos_geo', /gei2geo
    cotrans, 'el'+probes[sc]+'_pos_gse', 'el'+probes[sc]+'_pos_gsm', /gse2gsm
    cotrans, 'el'+probes[sc]+'_pos_gsm', 'el'+probes[sc]+'_pos_sm', /gsm2sm
    get_data,'el'+probes[sc]+'_pos_sm',data=dats  ; position in SM

    count=n_elements(dats.x)
    num=n_elements(dats.x)-1
    
    ; prepare parameter for input into Tsyganenko models
    case 1 of
      (tsyg_mod eq 't89'): tsyg_parameter=2.0d
      (tsyg_mod eq 't96'): tsyg_parameter=[[replicate(dynp,count)],[replicate(dst,count)],$
        [replicate(bswy,count)],[replicate(bswz,count)],$
        [replicate(0.,count)],[replicate(0.,count)],[replicate(0.,count)],$
        [replicate(0.,count)],[replicate(0.,count)],[replicate(0.,count)]]
      (tsyg_mod eq 't01'): tsyg_parameter=[[replicate(dynp,count)],[replicate(dst,count)],$
        [replicate(bswy,count)],[replicate(bswz,count)],$
        [replicate(g1,count)],[replicate(g2,count)],[replicate(0.,count)],$
        [replicate(0.,count)],[replicate(0.,count)],[replicate(0.,count)]]
      ELSE: begin
        print,'Unknown Tsyganenko model'
        return
      endcase
    endcase

    ; for development convenience only (ttrace2iono takes a long time)
    if keyword_set(no_trace) then goto, skip_trace

    if keyword_set(south) then begin
      ttrace2iono,'el'+probes[sc]+'_pos_sm',newname='el'+probes[sc]+'_ifoot_geo', $
        external_model=tsyg_mod,par=tsyg_parameter,/km,in_coord='sm',out_coord='geo',/south
    endif else begin
      ttrace2iono,'el'+probes[sc]+'_pos_sm',newname='el'+probes[sc]+'_ifoot_geo', $
        external_model=tsyg_mod,par=tsyg_parameter,/km,in_coord='sm',out_coord='geo'
    endelse

    skip_trace:

    cotrans, 'el'+probes[sc]+'_ifoot_geo', 'el'+probes[sc]+'_ifoot_gei', /geo2gei
    cotrans, 'el'+probes[sc]+'_ifoot_gei', 'el'+probes[sc]+'_ifoot_gse', /gei2gse
    cotrans, 'el'+probes[sc]+'_ifoot_gse', 'el'+probes[sc]+'_ifoot_gsm', /gse2gsm
    cotrans, 'el'+probes[sc]+'_ifoot_gsm', 'el'+probes[sc]+'_ifoot_sm', /gsm2sm
    get_data,'el'+probes[sc]+'_ifoot_sm',data=d
    get_data,'el'+probes[sc]+'_pos_geo',data=dpos

    Case sc of
      0: begin
        ; convert to lat lon
        cart_to_sphere, d.y[*,0], d.y[*,1], d.y[*,2], ra, lat, lon
        ; clean up data that's out of scope
        if keyword_set(south) then begin
          junk=where(dpos.y[*,2] gt 0.,count)
        endif else begin
          junk=where(dpos.y[*,2] lt 0.,count)
        endelse
        if (count gt 0) then begin
          lat[junk]=!values.f_nan
          lon[junk]=!values.f_nan
        endif
      end

      1: begin
        ; convert to lat lon
        cart_to_sphere, d.y[*,0], d.y[*,1], d.y[*,2], ra, lat2, lon2
        ; clean up data that's out of scope
        if keyword_set(south) then begin
          junk=where(dpos.y[*,2] gt 0.,count2)
        endif else begin
          junk=where(dpos.y[*,2] lt 0.,count2)
        endelse
        if (count2 gt 0) then begin
          lat2[junk]=!values.f_nan
          lon2[junk]=!values.f_nan
        endif
      end
    Endcase

    print,'Done '+tsyg_mod+' ',probes[sc]

  endfor  ; end of sc loop

  ; retrieve fgm and epd data if available
  elf_load_epd
  elf_load_fgm
  ; get all the science data collected and append times
  get_data, 'ela_pef', data=pefa
  if size(pefa, /type) EQ 8 then append_array, sci_timea, pefa.x
  get_data, 'ela_pif', data=pifa
  if size(pifa, /type) EQ 8 then append_array, sci_timea, pifa.x
  get_data, 'elb_pef', data=pefb
  if size(pefb, /type) EQ 8 then append_array, sci_timeb, pefb.x
  get_data, 'elb_pif', data=pifb
  if size(pifb, /type) EQ 8 then append_array, sci_timeb, pifb.x
  get_data, 'ela_fgf', data=fgfa
  if size(fgfa, /type) EQ 8 then append_array, sci_timea, fgfa.x
  get_data, 'ela_fgs', data=fgsa
  if size(fgsa, /type) EQ 8 then append_array, sci_timea, fgsa.x
  get_data, 'elb_fgf', data=fgfb
  if size(fgfb, /type) EQ 8 then append_array, sci_timeb, fgfb.x
  get_data, 'elb_fgs', data=fgsb
  if size(fgsb, /type) EQ 8 then append_array, sci_timeb, fgsb.x
  if ~undefined(sci_timea) then sci_timesa=sci_timea[UNIQ(sci_timea), SORT(sci_timea)]
  if ~undefined(sci_timeb) then sci_timesb=sci_timeb[UNIQ(sci_timeb), SORT(sci_timeb)]

  ; get positions for orbit plots
  get_data,'ela_pos_sm',data=ela_state_pos_sm
  get_data,'elb_pos_sm',data=elb_state_pos_sm

  elf_mlt_l_lat,'ela_pos_sm',MLT0=MLTA,L0=LA,LAT0=latA ;;subroutine to calculate mlt,l,mlat under dipole configuration
  elf_mlt_l_lat,'elb_pos_sm',MLT0=MLTB,L0=LB,LAT0=latB ;;subroutine to calculate mlt,l,mlat under dipole configuration

  ; load attitude data
  elf_get_att, trange=tr, probe='a'
  elf_get_att, trange=tr, probe='b'
  ; get attitude info for plot text
  get_data, 'ela_spin_norm_ang', data=norma
  get_data, 'ela_spin_sun_ang', data=suna
  get_data, 'ela_att_last_solution', data=solna
  get_data, 'elb_spin_norm_ang', data=normb
  get_data, 'elb_spin_sun_ang', data=sunb
  get_data, 'elb_att_last_solution', data=solnb
  if size(norma, /type) EQ 8 then norma_str=strmid(strtrim(string(norma.y[0]),1),0,7) $
  else norma_str = 'No att data'
  if size(suna, /type) EQ 8 then suna_str=strmid(strtrim(string(suna.y[0]),1),0,7) $
  else suna_str = 'No att data'
  if size(solna, /type) EQ 8 then solna_str=time_string(solna.x[0]) $
  else solna_str = 'No att data'
  if size(normb, /type) EQ 8 then normb_str=strmid(strtrim(string(normb.y[0]),1),0,7) $
  else normb_str = 'No att data'
  if size(sunb, /type) EQ 8 then sunb_str=strmid(strtrim(string(sunb.y[0]),1),0,7) $
  else sunb_str = 'No att data'
  if size(solnb, /type) EQ 8 then solnb_str=time_string(solnb.x[0]) $
  else solnb_str = 'No att data'
  ;reset time frame since attitude data might be several days old
  timespan,tstart,88200.,/day
  tr=timerange()

  ;mlat contours
  ;the call of cnv_aacgm here converts from geomagnetic to geographic
  if keyword_set(south) then begin
    latstep=-10
    latstart=0
    latend=-90
  endif else begin
    latstep=10   ; 5.
    latstart=0; 40.
    latend=90
  endelse

  lonstep=30
  lonstart=0
  lonend=360
  nmlats=round((latend-latstart)/float(latstep)+1)
  mlats=latstart+findgen(nmlats)*latstep
  n2=150
  v_lat=fltarr(nmlats,n2)
  v_lon=fltarr(nmlats,n2)
  height=100.
  for i=0,nmlats-1 do begin
    for j=0,n2-1 do begin
      cnv_aacgm,mlats[i],j/float(n2-1)*360,height,u,v,r1,error,/geo
      v_lat[i,j]=u
      v_lon[i,j]=v
    endfor
  endfor

  ;mlon contours
  ;get magnetic lat/lons
  nmlons=12 ;mlons shown at intervals of 15 degrees or one hour of MLT
  mlon_step=round(360/float(nmlons))
  n2=20
  u_lat=fltarr(nmlons,n2)
  u_lon=fltarr(nmlons,n2)
  cnv_aacgm, 56.35, 265.34, height, outlat,outlon,r1,error   ;Gillam
  mlats=latstart+findgen(n2)/float(n2-1)*(latend-latstart)
  for i=0,nmlons-1 do begin
    for j=0,n2-1 do begin
      cnv_aacgm,mlats[j],((outlon+mlon_step*i) mod 360),height,u,v,r1,error
      u_lat[i,j]=u
      u_lon[i,j]=v
    endfor
  endfor
  ;
  for i=0,nmlons-1 do begin
    for j=0,n2-1 do begin
      cnv_aacgm,mlats[j],((outlon+mlon_step*i) mod 360),height,u,v,r1,error,/geo
      u_lat[i,j]=u
      u_lon[i,j]=v
    endfor
  endfor

  ; setup for orbits
  ; 1 24 hour plot, 4 6 hr plots, 12 2 hr plots
  hr_arr = indgen(25)   ;[0, 6*indgen(4), 2*indgen(12)]
  hr_ststr = string(hr_arr, format='(i2.2)')
  ; Strings for labels, filenames
  for m=0,23 do begin
    this_s = tr[0] + m*3600.
    this_e = this_s + 90.*60.
    idx = where(ela_state_pos_sm.x GE this_s AND ela_state_pos_sm.x LT this_e, ncnt)
    if ncnt GT 10 then begin
      append_array, min_st, idx[0]
      append_array, min_en, idx[n_elements(idx)-1]
      this_lbl = ' ' + hr_ststr[m] + ':00 to ' + hr_ststr[m+1] + ':30'
      append_array, plot_lbl, this_lbl
      this_file = '_'+hr_ststr[m]
      append_array, file_lbl, this_file
    endif
  endfor
  nplots = n_elements(min_st)

  ;  hr_ststr = string(hr_st, format='(i2.2)')
  ;  plot_lbl=strarr(25)
  ;  for m=0,23 do plot_lbl[m] = ' ' + hr_ststr[m] + ':00 to ' + hr_ststr[m+1] + ':30'  ;+'-'+hr_enstr
  ;  file_lbl = '_'+hr_ststr   ;+hr_enstr
  ;  min_st = hr_st*3600.    ;*60.  ;*3600.   ;*res
  ;  min_en = min_st + 90.*60
  ;  idx=where(min_en GT n_elements(ela_state_pos_sm.x), ncnt)
  ;  if ncnt GT 0 then min_en[idx]=n_elements(ela_state_pos_sm.x)-1
  ;  nplots = n_elements(min_st)

  ; Get auroral zones and plot
  ovalget,6,pwdboundlonlat,ewdboundlonlat
  if keyword_set(south) then begin
    pwdboundlonlat[*, 1]=-pwdboundlonlat[*, 1]
    ewdboundlonlat[*, 1]=-ewdboundlonlat[*, 1]
  endif
  ; mirror to south
  rp=make_array(n_elements(pwdboundlonlat[*,0]), /double)+100.
  t=make_array(n_elements(pwdboundlonlat[*,0]), /double)+ela_state_pos_sm.x[0]
  sphere_to_cart, rp, pwdboundlonlat[*,1], pwdboundlonlat[*,0], vec=oval_sm
  store_data, 'oval_sm', data={x:t, y:oval_sm}
  cotrans, 'oval_sm', 'oval_gsm', /sm2gsm
  cotrans, 'oval_gsm', 'oval_gse', /gsm2gse
  cotrans, 'oval_gse', 'oval_gei', /gse2gei
  cotrans, 'oval_gei', 'oval_geo', /gei2geo
  get_data, 'oval_geo', data=d
  cart_to_sphere, d.y[*,0], d.y[*,1], d.y[*,2], rp, theta, phi
  pwdboundlonlat[*,0]=phi
  pwdboundlonlat[*,1]=theta
  ;if keyword_set(south) then pwdboundlonlat[*,1]=-theta else pwdboundlonlat[*,1]=theta

  sphere_to_cart, rp, ewdboundlonlat[*,1], ewdboundlonlat[*,0], vec=oval_sm
  store_data, 'oval_sm', data={x:t, y:oval_sm}
  cotrans, 'oval_sm', 'oval_gsm', /sm2gsm
  cotrans, 'oval_gsm', 'oval_gse', /gsm2gse
  cotrans, 'oval_gse', 'oval_gei', /gse2gei
  cotrans, 'oval_gei', 'oval_geo', /gei2geo
  get_data, 'oval_geo', data=d
  cart_to_sphere, d.y[*,0], d.y[*,1], d.y[*,2], rp, theta, phi
  ewdboundlonlat[*,0]=phi
  ewdboundlonlat[*,1]=theta

  ; determine times at orbit apogee (needed for determining total orbital period)
  ; Elfin A
  ax=ela_state_pos_sm.y[*,0]
  ay=ela_state_pos_sm.y[*,1]
  az=ela_state_pos_sm.y[*,2]
  find_orbits, ax, ay, az, a_ind_pg, a_ind_ag, /nostop
  at_ag=ela_state_pos_sm.x[a_ind_ag]
  an_ag = n_elements(at_ag)

  ; Elfin B
  bx=elb_state_pos_sm.y[*,0]
  by=elb_state_pos_sm.y[*,1]
  bz=elb_state_pos_sm.y[*,2]
  find_orbits, bx, by, bz, b_ind_pg, b_ind_ag, /nostop
  bt_ag=ela_state_pos_sm.x[b_ind_ag]
  bn_ag = n_elements(bt_ag)

  ; for gif-output
  date=strmid(tstart,0,10)
  timespan, tstart
  tr=timerange()

  ;----------------------------------
  ; Start Plots
  ;----------------------------------
  for k=0,nplots-1 do begin

    !p.multi=0
    if keyword_set(gifout) then begin
      set_plot,'z'
      device,set_resolution=[800,600]
      charsize=1
    endif else begin
      set_plot,'win'   ;'x'
      window,xsize=800,ysize=600
      charsize=1.5
    endelse

    ; annotate constants
    xann=10
    yann=463

    ; find midpt MLT for this orbit track
    midx=min_st[k] + (min_en[k] - min_st[k])/2.
    mid_time_struc=time_struct(ela_state_pos_sm.x[midx])
    mid_hr=mid_time_struc.hour + mid_time_struc.min/60.

    ; -------------------------------------
    ; MAP PLOT
    ; -------------------------------------
    ; set up map
    if keyword_set(south) then begin
      title='Southern footprints '+strmid(tstart,0,10)+plot_lbl[k]+' UTC'
      this_rot=180. + mid_hr*15.
      map_set,-90.,-90.,this_rot,/orthographic,/conti,limit=[0.,-180.,-90.,180.],$
        title=title,position=[0.005,0.005,600./800.*0.96,0.96]
      map_grid,latdel=-10.,londel=30.
    endif else begin
      title='Northern footprints '+strmid(tstart,0,10)+plot_lbl[k]+' UTC'
      this_rot=180. - mid_hr*15.
      map_set,90.,-90.,this_rot,/orthographic, /conti,limit=[10.,-180.,90.,180.],$
        title=title,position=[0.005,0.005,600./800.*0.96,0.96]
      map_grid,latdel=10.,londel=30.
    endelse

    ; display latitude/longitude
    if keyword_set(south) then begin
      for i=0,nmlats-1 do oplot,v_lon[i,*],v_lat[i,*],color=250,thick=contour_thick,linestyle=1
      for i=0,nmlons-1 do begin
        idx=where(u_lon[i,*] NE 0)
        oplot,u_lon[i,idx],u_lat[i,idx],color=250,thick=contour_thick,linestyle=1
      endfor
      ;      for i=0,nmlats-1 do oplot,v_lon[i,*]+mid_hr*15.,v_lat[i,*],color=250,thick=contour_thick,linestyle=1
      ;      for i=0,nmlons-1 do begin
      ;        idx=where(u_lon[i,*] NE 0)
      ;        oplot,u_lon[i,idx]+mid_hr*15.,u_lat[i,idx],color=250,thick=contour_thick,linestyle=1
      ;      endfor
    endif else begin
      for i=0,nmlats-1 do oplot,v_lon[i,*],v_lat[i,*],color=250,thick=contour_thick,linestyle=1
      for i=0,nmlons-1 do begin
        idx=where(u_lon[i,*] NE 0)
        oplot,u_lon[i,idx],u_lat[i,idx],color=250,thick=contour_thick,linestyle=1
      endfor
      ;      for i=0,nmlats-1 do oplot,v_lon[i,*]+ mid_hr*15.,v_lat[i,*],color=250,thick=contour_thick,linestyle=1
      ;      for i=0,nmlons-1 do begin
      ;        idx=where(u_lon[i,*] NE 0)
      ;        oplot,u_lon[i,idx]+ mid_hr*15.,u_lat[i,idx],color=250,thick=contour_thick,linestyle=1
      ;      endfor
    endelse

    ; Set up data for ELFIN A for this time span
    this_time=ela_state_pos_sm.x[min_st[k]:min_en[k]]
    nptsa=n_elements(this_time)
    if ~keyword_set(south) then this_lon=lon[min_st[k]:min_en[k]]-mid_hr*15. $
    else this_lon=lon[min_st[k]:min_en[k]]-mid_hr*15.
    this_lat=lat[min_st[k]:min_en[k]]
    this_ax=ela_state_pos_sm.y[min_st[k]:min_en[k],0]
    this_ay=ela_state_pos_sm.y[min_st[k]:min_en[k],1]
    this_az=ela_state_pos_sm.y[min_st[k]:min_en[k],2]
    this_a_alt = median(sqrt(this_ax^2 + this_ay^2 + this_az^2))-6371.
    this_a_alt_str = strtrim(string(this_a_alt),1)
    
    ; repeat for ELFIN B
    this_time2=elb_state_pos_sm.x[min_st[k]:min_en[k]]
    nptsb=n_elements(this_time2)
    if ~keyword_set(south) then this_lon2=lon2[min_st[k]:min_en[k]]-mid_hr*15. $
    else this_lon2=lon2[min_st[k]:min_en[k]]-mid_hr*15.
    this_lat2=lat2[min_st[k]:min_en[k]]
    this_bx=elb_state_pos_sm.y[min_st[k]:min_en[k],0]
    this_by=elb_state_pos_sm.y[min_st[k]:min_en[k],1]
    this_bz=elb_state_pos_sm.y[min_st[k]:min_en[k],2]
    this_b_alt = median(sqrt(this_bx^2 + this_by^2 + this_bz^2))-6371.
    this_b_alt_str = strtrim(string(this_b_alt),1)

    ; Check for gaps/anomalous points in the magnetic tracks
    if keyword_set(clean) then begin
      npts=n_elements(this_lat)
      diff=this_lat[1:npts-1] - this_lat[0:npts-2]
      idx = where(abs(diff) GT 1.5, ncnt)

      if ncnt EQ 0 then begin
        plots, this_lon[0:npts-1], this_lat[0:npts-1], psym=2, symsize=.08, color=253   ; thick=3
      endif
      idxs=idx[0]
      idxe=idx[ncnt-1]
      if ncnt GT 2 then begin
        plots, this_lon[0:idxs], this_lat[0:idxs], psym=2, symsize=.08, color=253   ; thick=3
        plots, this_lon[idxe+1:npts-1], this_lat[idxe+1:npts-1], psym=2, symsize=.08, color=253   ; thick=3
      endif

      npts=n_elements(this_lat2)
      diff=this_lat2[1:npts-1] - this_lat2[0:npts-2]
      idx = where(abs(diff) GT 1.5, ncnt)

      if ncnt EQ 0 then begin
        plots, this_lon2[0:npts-1], this_lat2[0:npts-1], psym=2, symsize=.08, color=254   ; thick=3
      endif
      idxs=idx[0]
      idxe=idx[ncnt-1]
      if ncnt GT 2 then begin
        plots, this_lon2[0:idxs], this_lat2[0:idxs], psym=2, symsize=.08, color=254    ; thick=3
        plots, this_lon2[idxe+1:npts-1], this_lat2[idxe+1:npts-1], psym=2, symsize=.08, color=254    ; thick=3
      endif
      ; Plot everything
    endif else begin
;      plots, this_lon, this_lat, psym=2, symsize=.08, color=253   ; thick=3
;      plots, this_lon2, this_lat2, psym=2, symsize=.08, color=254    ; thick=3
      plots, this_lon2, this_lat2, psym=2, symsize=.08, color=254    ; thick=3
      plots, this_lon, this_lat, psym=2, symsize=.08, color=253   ; thick=3
    endelse

    ; check if there were any science collected this time frame
    ; and oplot sci collection times
;    if ~undefined(sci_timesa) then begin
;      sci_idxa=where(sci_timesa GE this_time[0] AND sci_timesa LT this_time[nptsa-1], ncnt)
;      if ncnt GT 5 then begin 
;        find_interval, sci_idxa, sa_idx, ea_idx
;        ta0 = sci_timesa[sci_idxa[sa_idx]]
;        ta1 = sci_timesa[sci_idxa[ea_idx]]
;        for sci=0, n_elements(ta0)-1 do begin
;          tidx=where(this_time GE ta0[sci] and this_time LT ta1[sci], ncnt)
;          if ncnt GT 5 then begin
;             plots, this_lon[tidx], this_lat[tidx], psym=2, symsize=.4, color=253   ; thick=3
;          endif
;        endfor
;      endif
;    endif
    
    ; check if there were any science collected this time frame
    ; and oplot sci collection times
    if ~undefined(sci_timesb) then begin
      sci_idxb=where(sci_timesb GE this_time2[0] AND sci_timesb LT this_time2[nptsb-1], ncnt)
      if ncnt GT 5 then begin
        find_interval, sci_idxb, sb_idx, eb_idx
        tb0 = sci_timesb[sb_idx]
        tb1 = sci_timesb[eb_idx]
        for sci=0, n_elements(tb0)-1 do begin
          tidx=where(this_time2 GE tb0[sci] and this_time2 LT tb1[sci], ncnt)
          if ncnt GT 5 then begin
            plots, this_lon2[tidx], this_lat2[tidx], psym=2, symsize=.5, color=254   ; thick=3
          endif
        endfor
      endif
    endif

    ; Repeat for A
    if ~undefined(sci_timesa) then begin
      sci_idxa=where(sci_timesa GE this_time[0] AND sci_timesa LT this_time[nptsa-1], ncnt)
      if ncnt GT 5 then begin
        find_interval, sci_idxa, sa_idx, ea_idx
        ta0 = sci_timesa[sa_idx]
        ta1 = sci_timesa[ea_idx]
        for sci=0, n_elements(ta0)-1 do begin
          tidx=where(this_time GE ta0[sci] and this_time LT ta1[sci], ncnt)
          if ncnt GT 5 then begin
            plots, this_lon[tidx], this_lat[tidx], psym=2, symsize=.5, color=253   ; thick=3
          endif
        endfor
      endif
    endif
    
    ; Plot dataset start/stop position markers
    if keyword_set(south) then idx=where(this_bz lt 0.,count) else idx=where(this_bz gt 0.,count)
    plots, this_lon2[idx[0]], this_lat2[idx[0]], psym=symbols[0], symsize=1.9, color=254
    plots, this_lon2[idx[count/2]], this_lat2[idx[count/2]], psym=5, symsize=1.9, color=254
    plots, this_lon2[idx[count-1]], this_lat2[idx[count-1]], psym=2, symsize=1.9, color=254
    plots, this_lon2[0], this_lat2[0], psym=symbols[0], symsize=1.75
    plots, this_lon2[idx[count-1]], this_lat2[idx[count-1]], psym=2, symsize=1.75
    plots, this_lon2[0], this_lat2[0], psym=symbols[0], symsize=1.6, color=254
    plots, this_lon2[idx[count-1]], this_lat2[idx[count-1]], psym=2, symsize=1.6, color=254
    bs_string='Start time (diamond): ' + strmid(time_string(this_time2[idx[0]]),11,5)
    be_string='End time (asterisk): ' + strmid(time_string(this_time2[idx[count-1]]),11,5)
    if keyword_set(south) then idx=where(this_az lt 0.,count) else idx=where(this_az gt 0.,count)
    plots, this_lon[idx[0]], this_lat[idx[0]], psym=symbols[0], symsize=1.9, color=253
    plots, this_lon[idx[count/2]], this_lat[idx[count/2]], psym=5, symsize=1.9, color=253
    plots, this_lon[idx[count-1]], this_lat[idx[count-1]], psym=2, symsize=1.9, color=253
    plots, this_lon[idx[0]], this_lat[idx[0]], psym=symbols[0], symsize=1.75
    plots, this_lon[idx[count-1]], this_lat[idx[count-1]], psym=2, symsize=1.75
    plots, this_lon[idx[0]], this_lat[idx[0]], psym=symbols[0], symsize=1.6, color=253
    plots, this_lon[idx[count-1]], this_lat[idx[count-1]], psym=2, symsize=1.6, color=253
    as_string='Start time (diamond): ' + strmid(time_string(this_time[idx[0]]),11,5)
    ae_string='End time (asterisk): ' + strmid(time_string(this_time[idx[count-1]]),11,5)

    if keyword_set(tstep) then begin
      tstep=300.
      ; add tick marks for B
      res=this_time2[1] - this_time2[0]
      istep=tstep/res
      last = n_elements(this_time2)
      steps=lindgen(last/istep+1)*istep
      tmp=max(steps,nmax)
      if tmp gt (last-1) then steps=steps[0:nmax-1]
      tsteps0=this_time2[steps[0]]
      dummy=min(abs(this_time2-tsteps0),istep0)
      isteps=steps+istep0
      plots, this_lon2[isteps], this_lat2[isteps], psym=1, symsize=1.35, color=254
      ; add tick marks for A
      res=this_time[1] - this_time[0]
      istep=tstep/res
      last = n_elements(this_time)
      steps=lindgen(last/istep+1)*istep
      tmp=max(steps,nmax)
      if tmp gt (last-1) then steps=steps[0:nmax-1]
      tsteps0=this_time[steps[0]]
      dummy=min(abs(this_time-tsteps0),istep0)
      isteps=steps+istep0
      plots, this_lon[isteps], this_lat[isteps], psym=1, symsize=1.35, color=253
    endif

    ; find total orbit time for this plot
    idx = where(this_time[0] GT at_ag, ncnt)
    if ncnt EQ 0 then a_period=at_ag[1]-at_ag[0]
    if ncnt EQ 1 then a_period=at_ag[an_ag-1]-at_ag[an_ag-2]
    if ncnt GE 2 then a_period=at_ag[idx[1]]-at_ag[idx[0]]
    a_period_str = strmid(strtrim(string(a_period/60.), 1),0,6)
    idx = where(this_time2[0] GT bt_ag, ncnt)
    if ncnt EQ 0 then b_period=bt_ag[1]-bt_ag[0]
    if ncnt EQ 1 then b_period=bt_ag[bn_ag-1]-bt_ag[bn_ag-2]
    if ncnt GE 2 then b_period=bt_ag[idx[1]]-bt_ag[idx[0]]
    b_period_str = strmid(strtrim(string(b_period/60.), 1),0,6)

    ; Plot auroral zones and plot
    if keyword_set(south) then begin
      plots,pwdboundlonlat[*,0]-mid_hr*15.,pwdboundlonlat[*,1],color=155, thick=1.05
      plots,ewdboundlonlat[*,0]-mid_hr*15.,ewdboundlonlat[*,1],color=155, thick=1.05
    endif else begin
      plots,pwdboundlonlat[*,0]-mid_hr*15.,pwdboundlonlat[*,1],color=155, thick=1.05
      plots,ewdboundlonlat[*,0]-mid_hr*15.,ewdboundlonlat[*,1],color=155, thick=1.05
    endelse

    ; annotate
    xyouts,xann,yann+12.5*8,'ELFIN (A)',/device,charsize=.75,color=253
    xyouts,xann,yann+12.5*7,'Period, min: '+a_period_str,/device,charsize=.65,color=253
    xyouts,xann,yann+12.5*6,as_string,/device,charsize=.65,color=253
    xyouts,xann,yann+12.5*5,ae_string,/device,charsize=.65,color=253
    xyouts,xann,yann+12.5*4,'Spin Angle w/Sun, deg: '+suna_str,/device,charsize=.65,color=253
    xyouts,xann,yann+12.5*3,'Spin Angle w/OrbNorm, deg: '+norma_str,/device,charsize=.65,color=253
    xyouts,xann,yann+12.5*2,'Time Att Soln: '+solna_str,/device,charsize=.65,color=253
    xyouts,xann,yann+12.5*1,'Altitude, km: '+this_a_alt_str,/device,charsize=.65,color=253

    yann=0.02
    xyouts,xann,yann+12.5*8,'ELFIN (B)',/device,charsize=.75,color=254
    xyouts,xann,yann+12.5*7.,'Period, min: '+b_period_str,/device,charsize=.65,color=254
    xyouts,xann,yann+12.5*6.,bs_string,/device,charsize=.65,color=254
    xyouts,xann,yann+12.5*5.,be_string,/device,charsize=.65,color=254
    xyouts,xann,yann+12.5*4,'Spin Angle w/Sun, deg: '+sunb_str,/device,charsize=.65,color=254
    xyouts,xann,yann+12.5*3,'Spin Angle w/OrbNorm, deg: '+normb_str,/device,charsize=.65,color=254
    xyouts,xann,yann+12.5*2,'Time Att Soln: '+solnb_str,/device,charsize=.65,color=254
    xyouts,xann,yann+12.5*1,'Altitude, km: '+this_b_alt_str,/device,charsize=.65,color=254

    case 1 of
      tsyg_mod eq 't89': xyouts,.6182,.82,'Tsyganenko-1989',/normal,charsize=.65,color=255
      tsyg_mod eq 't96': xyouts,.6182,.82,'Tsyganenko-1996',/normal,charsize=.65,color=255
      tsyg_mod eq 't01': xyouts,.6182,.82,'Tsyganenko-2001',/normal,charsize=.65,color=255
    endcase
    xyouts, .5,0.94,'Earth/Oval View Center Time (triangle)',/normal,color=255,charsize=.65
    xyouts, .525,0.92,'Geo Lat/Lon - Black dotted lines',/normal,color=255,charsize=.65
    xyouts, .5325,0.9,'Mag Lat/Lon - Red dotted lines',/normal,color=251,charsize=.65
    xyouts, .57,0.88,'Auroral Oval - Green lines',/normal,color=155,charsize=.65
    xyouts, .595,0.84,'Thick - Sci Collection',/normal,color=255,charsize=.65
    xyouts, .592,0.86,'Tick Marks every 5min',/normal,color=255,charsize=.65

    xyouts, .01, .475, '00:00', charsize=1.15, /normal
    xyouts, .663, .475, '12:00', charsize=1.15, /normal
    if keyword_set(south) then begin
      xyouts, .335, .935, '06:00', charsize=1.15, /normal
      xyouts, .335, .0185, '18:00', charsize=1.15, /normal
    endif else begin
      xyouts, .335, .935, '18:00', charsize=1.15, /normal
      xyouts, .335, .0185, '06:00', charsize=1.15, /normal
    endelse

    ; add time of creation
    xyouts,  .52, 0.0185, 'Created: '+systime(),/normal,color=255, charsize=.65
    
    ; SM X-Z
    plot,findgen(10),xrange=[-2,2],yrange=[-2,2],$
      xstyle=5,ystyle=5,/nodata,/noerase,xtickname=replicate(' ',30),ytickname=replicate(' ',30),$
      position=[600./800.,0.005+0.96*2./3.,0.985,0.96*3./3.],$
      title='SM orbit'
    ; plot the earth
    oplot,cos(earth*!dtor),sin(earth*!dtor)
    ; plot long axes
    oplot,fltarr(100),findgen(100),line=1
    oplot,fltarr(100),-findgen(100),line=1
    oplot,-findgen(100),fltarr(100),line=1
    oplot,findgen(100),fltarr(100),line=1
    xyouts,-1.95, .05,'-X'
    xyouts,1.75,.05,'X'
    xyouts,.05,-1.85,'-Z'
    xyouts,.05,1.7,'Z'
    ; plot short axes
    for dd=-30,30,10 do oplot,[dd,dd],[-0.5,0.5]
    for dd=-30,30,10 do oplot,[-0.5,0.5],[dd,dd]

    ; plot orbit behind of earth
    idx = where(this_by lt 0, ncnt)
    if ncnt gt 0 then begin
      find_interval,idx,istart,iend
      for sidx = 0, n_elements(istart)-1 do oplot, this_bx[istart[sidx]:iend[sidx]]/6378., this_bz[istart[sidx]:iend[sidx]]/6378., color=252, linestyle = 1  ;, thick=.75
    endif
    idx = where(this_by ge 0, ncnt)
    if ncnt GT 0 then begin
      find_interval,idx,istart,iend
      for sidx = 0, n_elements(istart)-1 do oplot, this_bx[istart[sidx]:iend[sidx]]/6378., this_bz[istart[sidx]:iend[sidx]]/6378., color=254, thick=1.25
    endif

    ; repeat for A
    idx = where(this_ay lt 0, ncnt)
    if ncnt gt 0 then begin
      find_interval,idx,istart,iend
      for sidx = 0, n_elements(istart)-1 do oplot, this_ax[istart[sidx]:iend[sidx]]/6378., this_az[istart[sidx]:iend[sidx]]/6378., color=252, psym = 3  ;, thick=.75
    endif
    ; plot orbit in front of earth
    idx = where(this_ay ge 0, ncnt)
    if ncnt GT 0 then begin
      find_interval,idx,istart,iend
      for sidx = 0, n_elements(istart)-1 do oplot, this_ax[istart[sidx]:iend[sidx]]/6378., this_az[istart[sidx]:iend[sidx]]/6378., color=253, thick=1.25
    endif

    ;plot start/end points
    npts = n_elements(this_ax)-1
    plots, this_bx[0]/6378.,this_bz[0]/6378.,color=254,psym=symbols[0],symsize=0.8
    plots, this_ax[0]/6378.,this_az[0]/6378.,color=253,psym=symbols[0],symsize=0.8
    plots, this_bx[npts]/6378.,this_bz[npts]/6378.,color=254,psym=2,symsize=0.8
    plots, this_ax[npts]/6378.,this_az[npts]/6378.,color=253,psym=2,symsize=0.8

    ; plot lines to separate plots
    plots,[600./800.*0.96,1.],[0.005+0.96*3./3.,0.005+0.96*3./3.]-0.007,/normal
    plots,[600./800.*0.96,1.],[0.005+0.96*2./3.,0.005+0.96*2./3.]-0.005,/normal

    ; SM X-Y
    plot,findgen(10),xrange=[-2,2],yrange=[-2,2],$
      xstyle=5,ystyle=5,/nodata,/noerase,xtickname=replicate(' ',30),ytickname=replicate(' ',30),$
      position=[600./800.,0.005+0.96*1./3.,0.985,0.96*2./3.]
    ; plot the earth
    oplot,cos(earth*!dtor),sin(earth*!dtor)
    ; plot long axes
    oplot,fltarr(100),findgen(100),line=1
    oplot,fltarr(100),-findgen(100),line=1
    oplot,-findgen(100),fltarr(100),line=1
    oplot,findgen(100),fltarr(100),line=1
    xyouts,-1.95, .05,'-X'
    xyouts,1.75,.05,'X'
    xyouts,.05,-1.85,'-Y'
    xyouts,.05,1.7,'Y'
    ; plot short axes
    for dd=-30,30,10 do oplot,[dd,dd],[-0.5,0.5]
    for dd=-30,30,10 do oplot,[-0.5,0.5],[dd,dd]

    ; plot orbit behind of earth
    idx = where(this_bz lt 0, ncnt)
    if ncnt gt 0 then begin
      find_interval,idx,istart,iend
      for sidx = 0, n_elements(istart)-1 do oplot, this_bx[istart[sidx]:iend[sidx]]/6378., this_by[istart[sidx]:iend[sidx]]/6378., color=252, linestyle = 2, thick=.75
    endif
    idx = where(this_bz ge 0, ncnt)
    if ncnt GT 0 then begin
      find_interval,idx,istart,iend
      for sidx = 0, n_elements(istart)-1 do oplot, this_bx[istart[sidx]:iend[sidx]]/6378., this_by[istart[sidx]:iend[sidx]]/6378., color=254, thick=1.25
    endif
    ; repeat for a
    idx = where(this_az lt 0, ncnt)
    if ncnt gt 0 then begin
      find_interval,idx,istart,iend
      for sidx = 0, n_elements(istart)-1 do oplot, this_ax[istart[sidx]:iend[sidx]]/6378., this_ay[istart[sidx]:iend[sidx]]/6378., color=252, linestyle = 2, thick=.75
    endif
    ; plot orbit in front of earth
    idx = where(this_az ge 0, ncnt)
    if ncnt GT 0 then begin
      find_interval,idx,istart,iend
      for sidx = 0, n_elements(istart)-1 do oplot, this_ax[istart[sidx]:iend[sidx]]/6378., this_ay[istart[sidx]:iend[sidx]]/6378., color=253, thick=1.25
    endif

    ;plot start and end points
    plots, this_bx[0]/6378., this_by[0]/6378.,color=254,psym=symbols[0],symsize=0.8
    plots, this_ax[0]/6378.,this_ay[0]/6378.,color=253,psym=symbols[0],symsize=0.8
    plots, this_bx[npts]/6378., this_by[npts]/6378.,color=254,psym=2,symsize=0.8
    plots, this_ax[npts]/6378.,this_ay[npts]/6378.,color=253,psym=2,symsize=0.8

    ; plot lines to separate plots
    plots,[600./800.*0.96,1.],[0.005+0.96*1./3.,0.005+0.96*1./3.]-0.0025,/normal

    ; SM Y-Z
    plot,findgen(10),xrange=[-2,2],yrange=[-2,2],$
      xstyle=5,ystyle=5,/nodata,/noerase,xtickname=replicate(' ',30),ytickname=replicate(' ',30),$
      position=[600./800.,0.005+0.96*0./3.,0.985,0.96*1./3.]
    ; plot the earth
    oplot,cos(earth*!dtor),sin(earth*!dtor)
    ; plot long axes
    oplot,fltarr(100),findgen(100),line=1
    oplot,fltarr(100),-findgen(100),line=1
    oplot,-findgen(100),fltarr(100),line=1
    oplot,findgen(100),fltarr(100),line=1
    xyouts,-1.95, .05,'-Y'
    xyouts,1.75,.05,'Y'
    xyouts,.05,-1.85,'-Z'
    xyouts,.05,1.7,'Z'
    ; plot short axes
    for dd=-30,30,10 do oplot,[dd,dd],[-0.5,0.5]
    for dd=-30,30,10 do oplot,[-0.5,0.5],[dd,dd]

    ; plot orbit behind of earth
    plots, this_by[0]/6378.,this_bz[0]/6378.,color=254,psym=symbols[0],symsize=0.8
    idx = where(this_bx lt 0, ncnt)
    if ncnt gt 0 then begin
      find_interval,idx,istart,iend
      for sidx = 0, n_elements(istart)-1 do oplot, this_by[istart[sidx]:iend[sidx]]/6378., this_bz[istart[sidx]:iend[sidx]]/6378., color=252, linestyle = 2, thick=.75
    endif
    idx = where(this_bx ge 0, ncnt)
    if ncnt GT 0 then begin
      find_interval,idx,istart,iend
      for sidx = 0, n_elements(istart)-1 do oplot, this_by[istart[sidx]:iend[sidx]]/6378., this_bz[istart[sidx]:iend[sidx]]/6378., color=254, thick=1.25
    endif

    ; repeat for a
    idx = where(this_ax lt 0, ncnt)
    if ncnt gt 0 then begin
      find_interval,idx,istart,iend
      for sidx = 0, n_elements(istart)-1 do oplot, this_ay[istart[sidx]:iend[sidx]]/6378., this_az[istart[sidx]:iend[sidx]]/6378., color=252, linestyle = 2, thick=.75
    endif
    ; plot orbit in front of earth
    idx = where(this_ax ge 0, ncnt)
    if ncnt GT 0 then begin
      find_interval,idx,istart,iend
      for sidx = 0, n_elements(istart)-1 do oplot, this_ay[istart[sidx]:iend[sidx]]/6378., this_az[istart[sidx]:iend[sidx]]/6378., color=253, thick=1.25
    endif

    ;plot start and end points
    plots, this_by[0]/6378.,this_bz[0]/6378.,color=254,psym=symbols[0],symsize=0.8
    plots, this_ay[0]/6378.,this_az[0]/6378.,color=253,psym=symbols[0],symsize=0.8
    plots, this_by[npts]/6378.,this_bz[npts]/6378.,color=254,psym=2,symsize=0.8
    plots, this_ay[npts]/6378.,this_az[npts]/6378.,color=253,psym=2,symsize=0.8

    ; plot lines to separate plots
    plots,[600./800.*0.96,1.],[0.005+0.96*0./3.,0.005+0.96*0./3.],/normal

    ; gif-output
    if keyword_set(gifout) then begin
      image=tvrd()
      device,/close
      set_plot,'z'
      ;set_plot,'z'
      image[where(image eq 255)]=1
      image[where(image eq 0)]=255
      if not keyword_set(noview) then window,3,xsize=800,ysize=600
      if not keyword_set(noview) then tv,image
      dir_products = !elf.local_data_dir + 'gtrackplots/'+ strmid(date,0,4)+'/'+strmid(date,5,2)+'/'+strmid(date,8,2)+'/'
      file_mkdir, dir_products
      filedate=file_dailynames(trange=tr, /unique, times=times)

      if keyword_set(south) then begin
        plot_name = 'southtrack'
      endif else begin
        plot_name = 'northtrack'
      endelse

      if keyword_set(move) then gif_name=dir_products+'/'+'elf_l2_'+plot_name+'_'+filedate+file_lbl[k] else $
        gif_name='elf_l2_'+plot_name+'_'+filedate+file_lbl[k]

      write_gif,gif_name+'.gif',image,r,g,b
      print,'Output in ',gif_name+'.gif'
    endif

    if keyword_set(insert_stop) then stop

  endfor ; end of plotting loop


  pro_end_time=SYSTIME(/SECONDS)
  print, SYSTIME(), ' -- Finished creating overview plots'
  print, 'Duration (s): ', pro_end_time - pro_start_time

end
