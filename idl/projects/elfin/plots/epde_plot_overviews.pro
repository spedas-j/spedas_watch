;+
;
;PROCEDURE:
;  epde_plot_overviews
;
;PURPOSE:
; Loads EPDE, performs pitch angle determination and plotting of energy and pitch angle spectra
; Including precipitating and trapped spectra separately. EPDI can be treated similarly, but not done yet
; Regularize keyword performs rebinning of data on regular sector centers starting at zero (rel.to the time
; of dBzdt 0 crossing which corresponds to Pitch Angle = 90 deg and Spin Phase angle = 0 deg.).
; If the data has already been collected at regular sectors there is no need to perform this.
;
;KEYWORDS:
; trange - time range of interest [starttime, endtime] with the format
;          ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;          ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
; probe - 'a' or 'b'
; no_download - set this flag to not download data from the server and use local files only
; sci_zone - if set this flag will plot epd overview plots by science zone (rather than by day)
;
;TO DO:
; elb can be done similarly but the code has not been generalized to either a or b yet. But this is straightforward.
;
;-
pro epde_plot_overviews, trange=trange, probe=probe, no_download=no_download, $
  sci_zone=sci_zone, quick_run=quick_run

  ; initialize parameters
  num=0 ; keeps track of number of science zones in entire time range (a whole day) for appending purposes
  defsysv,'!elf',exists=exists
  if not keyword_set(exists) then elf_init

  if (~undefined(trange) && n_elements(trange) eq 2) && (time_double(trange[1]) lt time_double(trange[0])) then begin
    dprint, dlevel = 0, 'Error, endtime is before starttime; trange should be: [starttime, endtime]'
    return
  endif
  if ~undefined(trange) && n_elements(trange) eq 2 $
    then tr = timerange(trange) $
  else tr = timerange()
  if undefined(probe) then probe = 'a'
  if ~undefined(no_download) then no_download=1 else no_download=0
  t0=systime(/sec)

  timeduration=time_double(trange[1])-time_double(trange[0])
  timespan,tr[0],timeduration,/seconds
  tr=timerange()

  elf_init
  aacgmidl

  ; set up plot options
  loadct,39
  thm_init

  set_plot,'z'
  device,/close
  set_plot,'z'
  device,set_resolution=[775,1000]
  tvlct,r,g,b,/get
  ; color=253 will be yellow
  r[253]=255 & g[253]=255  & b[253]=0
  ; color=252 will be red
  r[252]=254 & g[252]=0 & b[252]=0
  ; color=251 will be blue
  r[251]=0 & g[251]=0 & b[251]=254
 
  tvlct,r,g,b
  set_plot,'z'
  charsize=1
  tplot_options, 'xmargin', [16,11]
  tplot_options, 'ymargin', [7,4]

  ; close and free any logical units opened by calc
  luns=lindgen(124)+5
  for j=0,n_elements(luns)-1 do free_lun, luns[j]

  ; remove any existing pef tplot vars
  del_data, '*_pef_nflux'
  del_data, '*_all'
  elf_load_epd, probes=probe, datatype='pef', level='l1', type='nflux', no_download=no_download
  get_data, 'el'+probe+'_pef_nflux', data=pef_nflux
  if size(pef_nflux, /type) NE 8 then begin
    dprint, dlevel=0, 'No data was downloaded for el' + probe + '_pef_nflux.'
    dprint, dlevel=0, 'No plots were producted.
  endif

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; Get position data
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  elf_load_state, probes=probe, no_download=no_download
  get_data, 'el'+probe+'_pos_gei', data=dat_gei
  cotrans,'el'+probe+'_pos_gei','el'+probe+'_pos_gse',/GEI2GSE
  cotrans,'el'+probe+'_pos_gse','el'+probe+'_pos_gsm',/GSE2GSM
  cotrans,'el'+probe+'_pos_gsm','el'+probe+'_pos_sm',/GSM2SM ; in SM

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; Calculate IGRF
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  threeones=[1,1,1]
  ; quick_run -> do only every 60th point (i.e. per minute)
  if keyword_set(quick_run) then begin
    get_data, 'el'+probe+'_pos_gsm', data=datgsm, dlimits=dl, limits=l
    store_data, 'el'+probe+'_pos_gsm_mins', data={x: datgsm.x[0:*:60], y: datgsm.y[0:*:60,*]}, dlimits=dl, limits=l
    tt89,'el'+probe+'_pos_gsm_mins',/igrf_only,newname='el'+probe+'_bt89_gsm_mins',period=1.
    ; interpolate the minute-by-minute data back to the full array
    get_data,'el'+probe+'_bt89_gsm_mins',data=gsm_mins
    store_data,'el'+probe+'_bt89_gsm',data={x: datgsm.x, y: interp(gsm_mins.y[*,*], gsm_mins.x, datgsm.x)}
    ; clean up the temporary data
    del_data, '*_mins'
  endif else begin
    tt89,'el'+probe+'_pos_gsm',/igrf_only,newname='el'+probe+'_bt89_gsm',period=1.
  endelse

  get_data, 'el'+probe+'_pos_sm', data=state_pos_sm
  ; calculate IGRF in nT
  cotrans,'el'+probe+'_bt89_gsm','el'+probe+'_bt89_sm',/GSM2SM ; Bfield in SM coords as well
  ;calc,' "bt89_SMdown" = -(total("bt89_sm"*"pos_sm",2)#threeones)/sqrt(total("pos_sm"^2,2)) '
  xyz_to_polar,'el'+probe+'_pos_sm',/co_latitude
  get_data,'el'+probe+'_pos_sm_th',data=pos_sm_th,dlim=myposdlim,lim=myposlim
  get_data,'el'+probe+'_pos_sm_phi',data=pos_sm_phi
  csth=cos(!PI*pos_sm_th.y/180.)
  csph=cos(!PI*pos_sm_phi.y/180.)
  snth=sin(!PI*pos_sm_th.y/180.)
  snph=sin(!PI*pos_sm_phi.y/180.)
  rot2rthph=[[[snth*csph],[csth*csph],[-snph]],[[snth*snph],[csth*snph],[csph]],[[csth],[-snth],[0.*csth]]]
  store_data,'rot2rthph',data={x:pos_sm_th.x,y:rot2rthph},dlim=myposdlim,lim=myposlim
  tvector_rotate,'rot2rthph','el'+probe+'_bt89_sm',newname='el'+probe+'_bt89_sm_sph'
  rotSMSPH2NED=[[[snth*0.],[snth*0.],[snth*0.-1.]],[[snth*0.-1.],[snth*0.],[snth*0.]],[[snth*0.],[snth*0.+1.],[snth*0.]]]
  store_data,'rotSMSPH2NED',data={x:pos_sm_th.x,y:rotSMSPH2NED},dlim=myposdlim,lim=myposlim
  tvector_rotate,'rotSMSPH2NED','el'+probe+'_bt89_sm_sph',newname='el'+probe+'_bt89_sm_NED' ; North (-Spherical_theta), East (Spherical_phi), Down (-Spherical_r)
  options,'el'+probe+'_bt89_sm_NED','ytitle','IGRF [nT]'
  options,'el'+probe+'_bt89_sm_NED','labels',['N','E','D']
  options,'el'+probe+'_bt89_sm_NED','databar',0.
  options,'el'+probe+'_bt89_sm_NED','ysubtitle','North, East, Down'
  options, 'el'+probe+'_bt89_sm_NED', colors=[251, 155, 252]

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; Get MLT amd LAT
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  elf_mlt_l_lat,'el'+probe+'_pos_sm',MLT0=MLT0,L0=L0,lat0=lat0 ;;subroutine to calculate mlt,l,mlat under dipole configuration
  get_data, 'el'+probe+'_pos_sm', data=elfin_pos
  store_data,'el'+probe+'_MLT',data={x:elfin_pos.x,y:MLT0}
  store_data,'el'+probe+'_L',data={x:elfin_pos.x,y:L0}
  store_data,'el'+probe+'_LAT',data={x:elfin_pos.x,y:lat0*180./!pi}
  options,'el'+probe+'_MLT',ytitle='MLT'
  options,'el'+probe+'_L',ytitle='L'
  options,'el'+probe+'_LAT',ytitle='LAT'
  alt = median(sqrt(elfin_pos.y[*,0]^2 + elfin_pos.y[*,1]^2 + elfin_pos.y[*,2]^2))-6371.

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; Get Pseudo_ae data
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  del_data, 'pseudo_ae'
  tr=timerange()
  elf_load_pseudo_ae, trange=[tr[0],tr[1]+5400.], /smooth, no_download=no_download
  get_data, 'pseudo_ae', data=pseudo_ae, dlimits=dl, limits=l
  if size(pseudo_ae,/type) NE 8 then begin
    elf_load_pseudo_ae, trange=['2019-12-05','2019-12-06']
    get_data, 'pseudo_ae', data=pseudo_ae, dlimits=ae_dl, limits=ae_l
  endif
  if ~undefined(pseudo_ae) then begin
    pseudo_ae.y = median(pseudo_ae.y, 10.)
    store_data, 'pseudo_ae', data=pseudo_ae, dlimits=ae_dl, limits=ae_l
    if size(pseudo_ae,/type) NE 8 then begin
      dprint, level=1, 'No data available for proxy_ae'
    endif
    options, 'pseudo_ae', ysubtitle='[nT]', colors=251
    options, 'pseudo_ae', yrange=[0,150]     
  endif else begin
    options, 'pseudo_ae', ztitle=''    
  endelse
  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; ... shadow/sunlight bar 0 (shadow) or 1 (sunlight)
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  elf_load_sun_shadow_bar, tplotname='el'+probe+'_pos_gse', no_download=no_download
  options,'shadow_bar',thick=5.5,xstyle=4,ystyle=4,yrange=[-0.1,0.1],ytitle='',$
    ticklen=0,panel_size=0.1, charsize=2., ztitle=''
  options,'sun_bar',thick=5.5,xstyle=4,ystyle=4,yrange=[-0.1,0.1],ytitle='',$
    ticklen=0,panel_size=0.1,colors=253, charsize=2., ztitle=''
    
  ; create one bar for both sun and shadow
  store_data, 'sunlight_bar', data=['sun_bar','shadow_bar']
  options, 'sunlight_bar', panel_size=0.1
  options, 'sunlight_bar',ticklen=0
  options, 'sunlight_bar', 'ystyle',4
  options, 'sunlight_bar', 'xstyle',4
  options, 'sunlight_bar', 'ztitle',''
  options, 'sunlight_bar', yrange=[-0.1,0.1]

  ; ... EPD fast bar
  del_data, 'epd_fast_bar'
  elf_load_epd_fast_segments, tplotname='el'+probe+'_pef_nflux', no_download=no_download
  get_data, 'epd_fast_bar', data=epdef_fast_bar_x
  ;elf_load_epd_survey_segments, tplotname='el'+probe+'_pes_nflux'
  ;get_data, 'epdes_survey_bar', data=epdes_survey_bar_x

  ;if isa(epdef_fast_bar_x) && isa(epdes_fast_bar_x) then store_data, 'epd_bar', data=['epdef_fast_bar','epdes_survey_bar']
  ;if ~isa(epdef_fast_bar_x) && isa(epdes_survey_bar_x) then store_data, 'epd_bar', data=['epdef_survey_bar']
  ;if isa(epdef_fast_bar_x) && ~isa(epdes_survey_bar_x) then store_data, 'epd_bar', data=['epdef_fast_bar']
  options, 'epd_fast_bar', panel_size=0.1
  options, 'epd_fast_bar',ticklen=0
  options, 'epd_fast_bar', 'ystyle',4
  options, 'epd_fast_bar', 'xstyle',4
  options, 'epd_fast_bar', 'color',252
  options, 'epd_fast_bar', 'ztitle',''

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; ... fgm status bar
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;elf_load_fgm_fast_segments, probe=probe
  ;get_data, 'fgf_bar', data=fgf_bar_x
  ; ... fgf status bar
  ;elf_load_fgm_survey_segments, probe=probe
  ;get_data, 'fgs_bar', data=fgs_bar_x

  ;if isa(fgs_bar_x) && isa(fgf_bar_x) then store_data, 'fgm_bar', data=['fgs_bar','fgf_bar']
  ;if ~isa(fgs_bar_x) && isa(fgf_bar_x) then store_data, 'fgm_bar', data=['fgf_bar']
  ;if isa(fgs_bar_x) && ~isa(fgf_bar_x) then store_data, 'fgm_bar', data=['fgs_bar']

  ;options, 'fgm_bar', panel_size=0.
  ;options, 'fgm_bar',ticklen=0
  ;options, 'fgm_bar', 'ystyle',4
  ;options, 'fgm_bar', 'xstyle',4
  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; Prep FOR ORBITS
  ; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; setup for orbits by the hour
  ; 1 plot at start of each hour (for 1.5 hours) and 1 24 hour plot
  hr_arr = indgen(25)   ;[0, 6*indgen(4), 2*indgen(12)]
  hr_ststr = string(hr_arr, format='(i2.2)')
  ; Strings for labels, filenames
  ; Use smaller array if they are not the same
  for m=0,23 do begin
    this_s = tr[0] + m*3600.
    this_e = this_s + 90.*60. + 1
    idx = where(dat_gei.x GE this_s AND dat_gei.x LT this_e, ncnt)
    if ncnt GT 10 then begin
      append_array, min_st, idx[0]
      append_array, min_en, idx[n_elements(idx)-1]
      if m NE 23 then this_lbl = ' ' + hr_ststr[m] + ':00 to ' + hr_ststr[m+1] + ':30' else $
        this_lbl = ' ' + hr_ststr[m] + ':00 to ' + hr_ststr[m+1] + ':00'
      append_array, plot_lbl, this_lbl
      this_file = '_'+hr_ststr[m]
      append_array, file_lbl, this_file
    endif
  endfor
  ; append info for 24 hour plot
  append_array, min_st, 0
  append_array, min_en, n_elements(dat_gei.x)-1
  append_array, plot_lbl, ' 00:00 to 24:00'
  append_array, file_lbl, '_24hr'
  st_hr = dat_gei.x[min_st]
  en_hr = dat_gei.x[min_en]

  ; set up for plots by science zone
  if (size(pef_nflux, /type)) EQ 8 then begin
    tdiff = pef_nflux.x[1:n_elements(pef_nflux.x)-1] - pef_nflux.x[0:n_elements(pef_nflux.x)-2]
    idx = where(tdiff GT 90., ncnt)   ; note: 90 seconds is an arbitary time
    append_array, idx, n_elements(pef_nflux.x)-1 ;add on last element (end time of last sci zone) to pick up last sci zone
    if ncnt EQ 0 then begin
      ; if ncnt is zero then there is only one science zone for this time frame
      sz_starttimes=[pef_nflux.x[0]]
      sz_min_st=[0]
      sz_endtimes=pef_nflux.x[n_elements(pef_nflux.x)-1]
      sz_min_en=[n_elements(pef_nflux.x)-1]
      ts=time_struct(sz_starttimes[0])
      te=time_struct(sz_endtimes[0])
    endif else begin
      for sz=0,ncnt do begin ;changed from ncnt-1
        if sz EQ 0 then begin
          this_s = pef_nflux.x[0]
          sidx = 0
          this_e = pef_nflux.x[idx[sz]]
          eidx = idx[sz]
        endif else begin
          this_s = pef_nflux.x[idx[sz-1]+1]
          sidx = idx[sz-1]+1
          this_e = pef_nflux.x[idx[sz]]
          eidx = idx[sz]
        endelse
        if (this_e-this_s) lt 60. then continue
        append_array, sz_starttimes, this_s
        append_array, sz_endtimes, this_e
        append_array, sz_min_st, sidx
        append_array, sz_min_en, eidx
        endfor
      endelse
    endif

  nplots = n_elements(min_st) ;number of starting hours (NOT number of sci zones)
  
  num_szs = n_elements(sz_starttimes)
  completed_szs=make_array(1, /double) ;list of completed sci zones

  ; set up science zone plot options
  tplot_options, 'xmargin', [16,11]
  tplot_options, 'ymargin', [5,4]

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; MAIN LOOP for PLOTs
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   for i=0,num_szs-1 do begin ;changed from 0,nplots-1

      sz_tr=[sz_starttimes[i],sz_endtimes[i]]
      tdur=sz_tr[1]-sz_tr[0]
      timespan, sz_tr[0], tdur, /sec
      if total(where(sz_tr[0] eq completed_szs)) ne -1 then continue ; if science zone is found in completed_szs, skip

      ; get EPD data
      del_data, 'el'+probe+'_pef_nflux'
      elf_load_epd, probes=probe, datatype='pef', level='l1', type='nflux',/no_download
      
      ; get sector and phase delay for this zone
      phase_delay = elf_find_phase_delay(trange=sz_tr, probe=probe, instrument='epde', no_download=no_download)
      if finite(phase_delay.dsect2add[0]) then dsect2add=fix(phase_delay.dsect2add[0]) $
         else dsect2add=phase_delay.dsect2add[0]
      ;dsect2add=fix(phase_delay.dsect2add[0])
      dphang2add=float(phase_delay.dphang2add[0])
      medianflag=fix(phase_delay.medianflag)
      if ~finite(phase_delay.dsect2add[0]) then medianflag=2
      if ~finite(phase_delay.dphang2add[0]) then medianflag=2
      badflag=fix(phase_delay.badflag)
      case medianflag of
        0: phase_msg = 'Phase delay values dSect2add='+strtrim(string(dsect2add),1) + ' and dPhAng2add=' +strmid(strtrim(string(dphang2add),1),0,4)
        1: phase_msg = 'Median Phase delay values dSect2add='+strtrim(string(dsect2add),1) + ' and dPhAng2add=' +strmid(strtrim(string(dphang2add),1),0,4)
        2: phase_msg = 'No phase delay available. Data is not regularized.'
      endcase
    
      spin_str=''
      if spd_data_exists('el'+probe+'_pef_nflux',sz_tr[0],sz_tr[1]) then begin
        completed_szs=[completed_szs,sz_tr[0]] ;append science zone start time to list
        if medianflag NE 2 then begin
           batch_procedure_error_handler, 'elf_getspec', /regularize, probe=probe, dSect2add=dsect2add, dSpinPh2add=dphang2add, no_download=no_download
           if not spd_data_exists('el'+probe+'_pef_pa_reg_spec2plot_ch0',sz_tr[0],sz_tr[1]) then begin
             elf_getspec, probe=probe
           endif
         endif else begin
           elf_getspec, probe=probe
         endelse
         ; find spin period
         get_data, 'el'+probe+'_pef_spinper', data=spin
         med_spin=median(spin.y)
         spin_var=stddev(spin.y)*100.
         spin_str='Median Spin Period, s: '+strmid(strtrim(string(med_spin), 1),0,4) + ', ' +$
           strmid(strtrim(string(spin_var), 1),0,4)+'% of Median'
      endif
      
      ; handle scaling of y axis
      if size(pseudo_ae, /type) EQ 8 then begin
        ae_idx = where(pseudo_ae.x GE sz_tr[0] and pseudo_ae.x LT sz_tr[1], ncnt)
        if ncnt GT 0 then ae_max=minmax(pseudo_ae.y[ae_idx])
        if ncnt EQ 0 then ae_max=[0,140.]
        if ae_max[1] LT 145. then options, 'pseudo_ae', yrange=[0,150] $
          else options, 'pseudo_ae', yrange=[0,ae_max[1]+ae_max[1]*.1]
        if ae_max[1] LT 145. then options, 'pseudo_ae', yrange=[0,150] $
          else options, 'pseudo_ae', yrange=[0,ae_max[1]+ae_max[1]*.1]
      endif else begin
        options, 'pseudo_ae', yrange=[0,150]
      endelse
      
      ; Figure out which hourly label to assign    
      ; Figure out which science zone
      get_data,'el'+probe+'_LAT',data=this_lat
      lat_idx=where(this_lat.x GE sz_tr[0] AND this_lat.x LE sz_tr[1], ncnt)
      if ncnt GT 0 then begin ;change to num_scz?
        sz_tstart=time_string(sz_tr[0])
        sz_lat=this_lat.y[lat_idx]
        median_lat=median(sz_lat)
        dlat = sz_lat[1:n_elements(sz_lat)-1] - sz_lat[0:n_elements(sz_lat)-2]
          if median_lat GT 0 then begin
            if median(dlat) GT 0 then sz_plot_lbl = ', North Ascending' else $
              sz_plot_lbl = ', North Descending'
            if median(dlat) GT 0 then sz_name = '_nasc' else $
              sz_name = '_ndes'
          endif else begin
            if median(dlat) GT 0 then sz_plot_lbl = ', South Ascending' else $
              sz_plot_lbl = ', South Descending'
            if median(dlat) GT 0 then sz_name = '_sasc' else $
              sz_name =  '_sdes'
          endelse
      endif


      ;;;;;;;;;;;;;;;;;;;;;;
      ; PLOT
      if tdur Lt 194. then version=6 else version=7
      tplot_options, version=version   ;6
      tplot_options, 'ygap',0
      tplot_options, 'charsize',.9
      tr=timerange()
      elf_set_overview_options, probe=probe, trange=tr            
      options, 'el'+probe+'_bt89_sm_NED', colors=[251, 155, 252]   ; force color scheme
      tplot,['pseudo_ae', $
        'epd_fast_bar', $
        'sunlight_bar', $
        'el'+probe+'_pef_en_spec2plot_omni', $
        'el'+probe+'_pef_en_spec2plot_anti', $
        'el'+probe+'_pef_en_spec2plot_perp', $
        'el'+probe+'_pef_en_spec2plot_para', $
        'el'+probe+'_pef_pa_reg_spec2plot_ch[0,1]LC', $
        'el'+probe+'_pef_pa_spec2plot_ch[2,3]LC', $
        'el'+probe+'_bt89_sm_NED'], $
        var_label='el'+probe+'_'+['LAT','MLT','L']
  
      tr=timerange()
      fd=file_dailynames(trange=tr[0], /unique, times=times)
      tstring=strmid(fd,0,4)+'-'+strmid(fd,4,2)+'-'+strmid(fd,6,2)+sz_plot_lbl
      title='PRELIMINARY ELFIN-'+strupcase(probe)+' EPDE, alt='+strmid(strtrim(alt,1),0,3)+'km, '+tstring
      xyouts, .175, .975, title, /normal, charsize=1.1
      tplot_apply_databar
  
      ; add time of creation
      xyouts,  .725, .005, 'Created: '+systime(),/normal,color=1, charsize=.75
      ; add phase delay message
      if spd_data_exists('el'+probe+'_pef_nflux',sz_tr[0],sz_tr[1]) then begin
        xyouts, .0085, .012, spin_str, /normal, charsize=.75
        xyouts, .0085, .001, phase_msg, /normal, charsize=.75
      endif

      ; save for later
      get_data, 'el'+probe+'_pef_en_spec2plot_omni', data=omni_d, dlimits=omni_dl, limits=omni_l   
      get_data, 'el'+probe+'_pef_en_spec2plot_anti', data=anti_d, dlimits=anti_dl, limits=anti_l
      get_data, 'el'+probe+'_pef_en_spec2plot_perp', data=perp_d, dlimits=perp_dl, limits=perp_l
      get_data, 'el'+probe+'_pef_en_spec2plot_para', data=para_d, dlimits=para_dl, limits=para_l
  
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ; Create GIF file
      tr=timerange()
      fd=file_dailynames(trange=tr[0], /unique, times=times)
      ; Create small plot
      image=tvrd()
      device,/close
      set_plot,'z'
      image[where(image eq 255)]=1
      image[where(image eq 0)]=255
      gif_path = !elf.local_data_dir+'el'+probe+'/overplots/'+strmid(fd,0,4)+'/'+strmid(fd,4,2)+'/'+strmid(fd,6,2)+'/'
      file_mkdir, gif_path

      ; Figure out which sci zone numbers need to be created 
      for nhrs=0,23 do begin
        idx=where((sz_tr[0] GE st_hr[nhrs] AND sz_tr[0] LE en_hr[nhrs]) OR $
                  (sz_tr[1] GE st_hr[nhrs] AND sz_tr[1] LE en_hr[nhrs]),ncnt)
        if ncnt LE 0 then continue
        sz_file_lbl = file_lbl[i] + '_sasc' 
        gif_file = gif_path+'el'+probe+'_l2_overview_'+fd+file_lbl[nhrs]+sz_name
        dprint, 'Making gif file '+gif_file+'.gif'
        write_gif, gif_file+'.gif',image,r,g,b
        dprint, dlevel=2, 'Sci Zone plot time: '+strtrim(systime(/sec)-t0,2)+' sec'
      endfor 
      
      ;*************************;
      ;  ADD TPLOT APPEND HERE
      ;*************************;
      ;Now store as unique tplot variables with diff sz number
      num+=1
      copy_data, 'el'+probe+'_pef_en_spec2plot_omni', 'el'+probe+'_pef_en_spec2plot_omni_sz'+strtrim(string(num),2)
      copy_data, 'el'+probe+'_pef_en_spec2plot_anti', 'el'+probe+'_pef_en_spec2plot_anti_sz'+strtrim(string(num),2)
      copy_data, 'el'+probe+'_pef_en_spec2plot_perp', 'el'+probe+'_pef_en_spec2plot_perp_sz'+strtrim(string(num),2)
      copy_data, 'el'+probe+'_pef_en_spec2plot_para', 'el'+probe+'_pef_en_spec2plot_para_sz'+strtrim(string(num),2)
      copy_data, 'el'+probe+'_pef_pa_reg_spec2plot_ch0', 'el'+probe+'_pef_pa_reg_spec2plot_ch0_sz'+strtrim(string(num),2)
      copy_data, 'el'+probe+'_pef_pa_reg_spec2plot_ch1', 'el'+probe+'_pef_pa_reg_spec2plot_ch1_sz'+strtrim(string(num),2)
      copy_data, 'el'+probe+'_pef_pa_reg_spec2plot_ch2', 'el'+probe+'_pef_pa_reg_spec2plot_ch2_sz'+strtrim(string(num),2)
      copy_data, 'el'+probe+'_pef_pa_reg_spec2plot_ch3', 'el'+probe+'_pef_pa_reg_spec2plot_ch3_sz'+strtrim(string(num),2)
      copy_data, 'el'+probe+'_pef_pa_spec2plot_ch0', 'el'+probe+'_pef_pa_spec2plot_ch0_sz'+strtrim(string(num),2)
      copy_data, 'el'+probe+'_pef_pa_spec2plot_ch1', 'el'+probe+'_pef_pa_spec2plot_ch1_sz'+strtrim(string(num),2)
      copy_data, 'el'+probe+'_pef_pa_spec2plot_ch2', 'el'+probe+'_pef_pa_spec2plot_ch2_sz'+strtrim(string(num),2)
      copy_data, 'el'+probe+'_pef_pa_spec2plot_ch3', 'el'+probe+'_pef_pa_spec2plot_ch3_sz'+strtrim(string(num),2)

    endfor
  
  ; Create concatenating (24-hour) tplot variables
  omni_str=''
  anti_str=''
  perp_str=''
  para_str=''
  pa_ch0_str=''
  pa_ch1_str=''
  pa_ch2_str=''
  pa_ch3_str=''
  pa_ch0_reg_str=''
  pa_ch1_reg_str=''
  pa_ch2_reg_str=''
  pa_ch3_reg_str=''
  for n=1,num do begin ;append all science zone data
    omni_str+=' el'+probe+'_pef_en_spec2plot_omni_sz'+strtrim(string(n),2)
    anti_str+=' el'+probe+'_pef_en_spec2plot_anti_sz'+strtrim(string(n),2)
    perp_str+=' el'+probe+'_pef_en_spec2plot_perp_sz'+strtrim(string(n),2)
    para_str+=' el'+probe+'_pef_en_spec2plot_para_sz'+strtrim(string(n),2)
    pa_ch0_str+=' el'+probe+'_pef_pa_spec2plot_ch0_sz'+strtrim(string(n),2)
    pa_ch1_str+=' el'+probe+'_pef_pa_spec2plot_ch1_sz'+strtrim(string(n),2)
    pa_ch2_str+=' el'+probe+'_pef_pa_spec2plot_ch2_sz'+strtrim(string(n),2)
    pa_ch3_str+=' el'+probe+'_pef_pa_spec2plot_ch3_sz'+strtrim(string(n),2)
    pa_ch0_reg_str+=' el'+probe+'_pef_pa_reg_spec2plot_ch0_sz'+strtrim(string(n),2)
    pa_ch1_reg_str+=' el'+probe+'_pef_pa_reg_spec2plot_ch1_sz'+strtrim(string(n),2)
    pa_ch2_reg_str+=' el'+probe+'_pef_pa_reg_spec2plot_ch2_sz'+strtrim(string(n),2)
    pa_ch3_reg_str+=' el'+probe+'_pef_pa_reg_spec2plot_ch3_sz'+strtrim(string(n),2)
  endfor
  
  store_data, 'el'+probe+'_pef_en_spec2plot_omni_all', data=omni_str, dlimits=omni_dl, limits=omni_l
  store_data, 'el'+probe+'_pef_en_spec2plot_anti_all', data=anti_str, dlimits=anti_dl, limits=anti_l
  store_data, 'el'+probe+'_pef_en_spec2plot_perp_all', data=perp_str, dlimits=perp_dl, limits=perp_l
  store_data, 'el'+probe+'_pef_en_spec2plot_para_all', data=para_str, dlimits=para_dl, limits=para_l
  
  ; Overwrite losscone/antilosscone tplot variable with full day from elf_getspec
  if nplots eq 25 then this_tr=[dat_gei.x[min_st[24]], dat_gei.x[min_en[24]]] $
     else this_tr=trange
  tdur=this_tr[1]-this_tr[0]
  timespan, this_tr[0], tdur, /sec
  elf_load_state, probes=probe, /no_download
  elf_load_epd, probes=probe, datatype='pef', level='l1', type='nflux', /no_download
  if spd_data_exists('el'+probe+'_pef_nflux',this_tr[0],this_tr[1]) then $
  elf_getspec, probe=probe, /only_loss_cone ;this should overwrite 'lossconedeg' and 'antilossconedeg' with full day

  for jthchan=0,3 do begin ;reg
    if jthchan eq 0 then mystr=pa_ch0_reg_str
    if jthchan eq 1 then mystr=pa_ch1_reg_str
    if jthchan eq 2 then mystr=pa_ch2_reg_str
    if jthchan eq 3 then mystr=pa_ch3_reg_str
    datastr=mystr+' lossconedeg antilossconedeg'
    str2exec="store_data,'el"+probe+"_pef_pa_reg_spec2plot_ch"+strtrim(string(jthchan),2)+"LC_all',data=datastr"
    dummy=execute(str2exec)
  endfor
  for jthchan=0,3 do begin ;non-reg
    if jthchan eq 0 then mystr=pa_ch0_str
    if jthchan eq 1 then mystr=pa_ch1_str
    if jthchan eq 2 then mystr=pa_ch2_str
    if jthchan eq 3 then mystr=pa_ch3_str
    datastr=mystr+' lossconedeg antilossconedeg'
    str2exec="store_data,'el"+probe+"_pef_pa_spec2plot_ch"+strtrim(string(jthchan),2)+"LC_all',data=datastr"
    dummy=execute(str2exec)
  endfor

  ; this chunk might not be necessary since it's repeated later
  ylim,'el?_p?f_pa*spec2plot* *losscone* el?_p?f_pa*spec2plot_ch?LC*',0,180.
  zlim,'el?_p?f_pa*spec2plot_ch0LC*',1e2,1e6
  zlim,'el?_p?f_pa*spec2plot_ch1LC*',1e2,1e6
  zlim,'el?_p?f_pa*spec2plot_ch2LC*',1e2,1e6
  zlim,'el?_p?f_pa*spec2plot_ch3LC*',10,1e4
  options,'el?_p?f_pa*spec2plot_ch*LC*','ztitle','#/(scm!U2!NstrMeV)'
  
  timeduration=time_double(trange[1])-time_double(trange[0])
  timespan,trange[0],timeduration,/seconds
  get_data, 'antilossconedeg', data=d, dlimits=dl, limits=l 
  if size(d, /type) EQ 8 then store_data, 'antilossconedeg', data={x:d.x[0:*:60], y:d.y[0:*:60]}

  ; handle scaling of y axis
  get_data,'pseudo_ae',data=pseudo_ae
  if size(pseudo_ae, /type) EQ 8 then begin
    idx = where(pseudo_ae.x GE this_tr[0] and pseudo_ae.x LT this_tr[1], ncnt)
    if ncnt GT 0 then ae_max=minmax(pseudo_ae.y)
    if ncnt EQ 0 then ae_max=[0,140.]
    if ae_max[1] LT 145. then options, 'pseudo_ae', yrange=[0,150] $
          else options, 'pseudo_ae', yrange=[0,ae_max[1]+ae_max[1]*.1]
  endif
  
  ; Do hourly plots and 24hr plot
;  for i=0,24 do begin ; plots full day on hr=24
  for i=0,nplots-1 do begin ; plots full day on hr=24
    ; Set hourly start and stop times
    if min_en[i] GT n_elements(dat_gei.x)-1 then continue
    this_tr=[dat_gei.x[min_st[i]], dat_gei.x[min_en[i]]]
    tdur=this_tr[1]-this_tr[0]
    timespan, this_tr[0], tdur, /sec
    elf_load_state, probes=probe, /no_download
    
    if size(pseudo_ae,/type) eq 8 then begin
      pseudo_ae_sub=pseudo_ae.y(where(pseudo_ae.x ge time_double(this_tr[0]) and pseudo_ae.x le time_double(this_tr[1])))
      ae_max=minmax(pseudo_ae_sub)
      if ae_max[1] LT 145. then options, 'pseudo_ae', yrange=[0,150] $
        else options, 'pseudo_ae', yrange=[0,ae_max[1]+ae_max[1]*.1]
    endif

    if tdur GT 10802. or i EQ 24 then begin   ; at least need to orbits for 24 hour plots
      tr=timerange()
      tr[1]=tr[1]+5400.
      elf_load_kp, trange=[tr],/day
      elf_load_dst,trange=tr
    endif
    
    ; Below chunk of code to fix y-labels might be messing up 24hr loss cone? If not, likely caused by interpolation in elf_getspec_v2
    ; 
    ; use copy_data instead
    copy_data,'el'+probe+'_pef_en_spec2plot_omni_all','el'+probe+'_pef_en_spec2plot_omni'
    copy_data,'el'+probe+'_pef_en_spec2plot_anti_all','el'+probe+'_pef_en_spec2plot_anti'
    copy_data,'el'+probe+'_pef_en_spec2plot_perp_all','el'+probe+'_pef_en_spec2plot_perp'
    copy_data,'el'+probe+'_pef_en_spec2plot_para_all','el'+probe+'_pef_en_spec2plot_para'
    copy_data,'el'+probe+'_pef_pa_reg_spec2plot_ch0LC_all','el'+probe+'_pef_pa_reg_spec2plot_ch0LC'
    copy_data,'el'+probe+'_pef_pa_reg_spec2plot_ch1LC_all','el'+probe+'_pef_pa_reg_spec2plot_ch1LC'
    copy_data,'el'+probe+'_pef_pa_spec2plot_ch2LC_all','el'+probe+'_pef_pa_spec2plot_ch2LC'
    copy_data,'el'+probe+'_pef_pa_spec2plot_ch3LC_all','el'+probe+'_pef_pa_spec2plot_ch3LC'
    
    options, 'el'+probe+'_pef_en_spec2plot_omni', 'ysubtitle', '[keV]'
    options, 'el'+probe+'_pef_en_spec2plot_anti', 'ysubtitle', '[keV]'
    options, 'el'+probe+'_pef_en_spec2plot_perp', 'ysubtitle', '[keV]'
    options, 'el'+probe+'_pef_en_spec2plot_para', 'ysubtitle', '[keV]'
;    options, 'el'+probe+'_pef_en_spec2plot_omni', 'ytitle', '[keV]'
;    options, 'el'+probe+'_pef_en_spec2plot_anti', 'ytitle', '[keV]'
;    options, 'el'+probe+'_pef_en_spec2plot_perp', 'ytitle', '[keV]'
;    options, 'el'+probe+'_pef_en_spec2plot_para', 'ytitle', '[keV]'
    options, 'el'+probe+'_pef_pa_reg_spec2plot_ch0LC', 'ysubtitle', '[deg]'
    options, 'el'+probe+'_pef_pa_reg_spec2plot_ch1LC', 'ysubtitle', '[deg]'
    options, 'el'+probe+'_pef_pa_spec2plot_ch2LC', 'ysubtitle', '[deg]'
    options, 'el'+probe+'_pef_pa_spec2plot_ch3LC', 'ysubtitle', '[deg]'
    
    ylim,'el?_p?f_pa*spec2plot* *losscone* el?_p?f_pa*spec2plot_ch?LC*',0,180.
    zlim,'el?_p?f_pa*spec2plot_ch0LC*',1e2,1e6
    zlim,'el?_p?f_pa*spec2plot_ch1LC*',1e2,1e6
    zlim,'el?_p?f_pa*spec2plot_ch2LC*',1e2,1e6
    zlim,'el?_p?f_pa*spec2plot_ch3LC*',10,1e4
    zlim,'el?_p?f_en_spec2plot*',1e1,1e6
    options,'el?_p?f_pa*spec2plot_ch0LC*','ztitle',''
    options,'el?_p?f_pa*spec2plot_ch0LC*','ztitle','#/(scm!U2!NstrMeV)'
    options,'el?_p?f_pa*spec2plot_ch1LC*','ztitle',''
    options,'el?_p?f_pa*spec2plot_ch1LC*','ztitle','#/(scm!U2!NstrMeV)'
    options,'el?_p?f_pa*spec2plot_ch*LC*','ztitle',''
    options,'el?_p?f_pa*spec2plot_ch*LC*','ztitle','#/(scm!U2!NstrMeV)'
    options,'el?_p?f_en_spec2plot_omni','ztitle',''
    options,'el?_p?f_en_spec2plot_omni','ztitle','#/(scm!U2!NstrMeV)'
    options,'el?_p?f_en_spec2plot_anti','ztitle',''
    options,'el?_p?f_en_spec2plot_anti','ztitle','#/(scm!U2!NstrMeV)'
    options,'el?_p?f_en_spec2plot_perp','ztitle',''
    options,'el?_p?f_en_spec2plot_perp','ztitle','#/(scm!U2!NstrMeV)'
    options,'el?_p?f_en_spec2plot_para','ztitle',''
    options,'el?_p?f_en_spec2plot_para','ztitle','#/(scm!U2!NstrMeV)'
    options, 'antilossconedeg', 'linestyle', 2
    ;options, 'antilossconedeg', linestyle=2
    
    if tdur Lt 194. then version=6 else version=7
    ;if i eq 23 then version=6
    tplot_options, version=version   ;6
    tplot_options, 'ygap',0
    tplot_options, 'charsize',.9   
    if tdur LT 16200. or i LT 24 then begin
      tplot,['pseudo_ae', $
        'epd_fast_bar', $
        'sunlight_bar', $
        'el'+probe+'_pef_en_spec2plot_omni', $ ; fixed labels so that units are included and 'all' doesn't appear
        'el'+probe+'_pef_en_spec2plot_anti', $
        'el'+probe+'_pef_en_spec2plot_perp', $
        'el'+probe+'_pef_en_spec2plot_para', $
        'el'+probe+'_pef_pa_reg_spec2plot_ch[0,1]LC', $
        'el'+probe+'_pef_pa_spec2plot_ch[2,3]LC', $
        'el'+probe+'_bt89_sm_NED'], $
        var_label='el'+probe+'_'+['LAT','MLT','L']
    endif else begin

      tplot,['pseudo_ae', $
;        'kp', $
;        'dst',$
        'epd_fast_bar', $
        'sunlight_bar', $
        'el'+probe+'_pef_en_spec2plot_omni', $ ; fixed labels so that units are included and 'all' doesn't appear
        'el'+probe+'_pef_en_spec2plot_anti', $
        'el'+probe+'_pef_en_spec2plot_perp', $
        'el'+probe+'_pef_en_spec2plot_para', $
        'el'+probe+'_pef_pa_reg_spec2plot_ch[0,1]LC', $
        'el'+probe+'_pef_pa_spec2plot_ch[2,3]LC', $
        'el'+probe+'_bt89_sm_NED'], $
        var_label='el'+probe+'_'+['LAT','MLT','L']      
    endelse
    
      ; Save plots
      tr=timerange()
      fd=file_dailynames(trange=tr[0], /unique, times=times)
      tstring=strmid(fd,0,4)+'-'+strmid(fd,4,2)+'-'+strmid(fd,6,2)+plot_lbl[i]
      title='PRELIMINARY ELFIN-'+strupcase(probe)+' EPDE, alt='+strmid(strtrim(alt,1),0,3)+'km, '+tstring
      xyouts, .2, .975, title, /normal, charsize=1.1
      tplot_apply_databar
  
      ; add time of creation
      xyouts,  .76, .005, 'Created: '+systime(),/normal,color=1, charsize=.75

      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ; Create GIF file
      ; Create small plot
      image=tvrd()
      device,/close
      set_plot,'z'
      image[where(image eq 255)]=1
      image[where(image eq 0)]=255
      gif_path = !elf.local_data_dir+'el'+probe+'/overplots/'+strmid(fd,0,4)+'/'+strmid(fd,4,2)+'/'+strmid(fd,6,2)+'/'
      file_mkdir, gif_path
      gif_file = gif_path+'el'+probe+'_l2_overview_'+fd+file_lbl[i]
      dprint, 'Making gif file '+gif_file+'.gif'
      write_gif, gif_file+'.gif',image,r,g,b

      luns=lindgen(124)+5
      for j=0,n_elements(luns)-1 do free_lun, luns[j]
      dprint, dlevel=2, 'Hourly plot time: '+strtrim(systime(/sec)-t0,2)+' sec'
      
  endfor
  
  dprint, dlevel=2, 'Total time: '+strtrim(systime(/sec)-t0,2)+' sec'

end
