pro elf_create_l2_epd_cdf, probe=probe, trange=trange, species
  ;
  compile_opt idl2
  elf_init
  pival=!PI
  Re=6378.1 ; Earth equatorial radius in km
  Ree=6378.1 ; Earth equatorial radius in km
  Rem=6371.0 ; Earth mean radius in km
  ;
  ; pick an event
  ;
  tstart='2021-03-20';/06:23:00'
  tend='2021-03-21';/06:27:00'
  ;
  time2plot=[tstart,tend]
  timeduration=time_double(tend)-time_double(tstart)
  timespan,tstart,timeduration,/seconds ; set the analysis time interval
  ;
  sclet='b'
  species='e'
  ;
  elf_load_state,probe=sclet,/get_supp
  ;
;  elf_load_epd,probe=sclet,datatype='p'+species+'f',type = 'nflux', level='l1'

  elf_load_epd,probe=sclet,datatype='p'+species+'f',type = 'raw', level='l1'
  get_data, 'el'+sclet+'_pef_raw', data=pef_nflux
;stop
  ; set up for plots by science zone
  if (size(pef_nflux, /type)) EQ 8 then begin
    tdiff = pef_nflux.x[1:n_elements(pef_nflux.x)-1] - pef_nflux.x[0:n_elements(pef_nflux.x)-2]
    idx = where(tdiff GT 270., ncnt)
    append_array, idx, n_elements(pef_nflux.x)-1 ;add on last element (end time of last sci zone) to pick up last sci zone
    if ncnt EQ 0 then begin
      ; if ncnt is zero then there is only one science zone for this time frame
      sz_starttimes=[pef_nflux.x[0]]
      sz_endtimes=pef_nflux.x[n_elements(pef_nflux.x)-1]
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
        if (this_e-this_s) lt 15. then continue
        append_array, sz_starttimes, this_s
        append_array, sz_endtimes, this_e
      endfor
    endelse
  endif

  if undefined(sz_starttimes) then begin
    print, 'There is no EPD data for ' + tstart
    return
  endif
  num_sz=n_elements(sz_starttimes) 
    
  for i=0,0 do begin ;num_sz-1 do begin

    this_st=sz_starttimes[i]
    this_en=sz_endtimes[i]
    this_dur=this_en-this_st
    timespan, this_st, this_dur, /sec
    
    elf_load_epd,probe=sclet,datatype='p'+species+'f',type = 'raw'

    elf_getspec,probe=sclet,datatype='p'+species+'f',type ='raw',/get3Dspec,/fullspin; both full and halfspin exist

    ; compute the errors for params to use below (this is the only chance to do it, so do more now if you may need later)
    ; Use these raw counts to produce the df/f error estimate = 1/sqrt(counts) for all quantities you need to. Use calc with globing:
    ;tplot_names
    copy_data,'elx_pxf_val_full','el'+sclet+'_p'+species+'f_val_full_raw' ; this is the time series of counts/sector adjusted for gaps etc
    calc," 'elx_pxf_val_full_err'=1/sqrt('elx_pxf_val_full') "
    ;
    ; extract ancillary data to accompany time series
    copy_data,'elx_pxf_sectnum','el'+sclet+'_p'+species+'f_sectnum' ; this is the sector number where the point was collected
    copy_data,'elx_pxf_spinper','el'+sclet+'_p'+species+'f_tspin' ; this is the spin period (EPD determined) at same times as tseries
    copy_data,'elx_pxf_nspinsinsum','el'+sclet+'_p'+species+'f_nspinsinsum' ; this is the number of spins summed to compute this data
    copy_data,'spinphasedeg','el'+sclet+'_p'+species+'f_spinphase' ; this is the spinphase of the satellite in deg at each collection time
    copy_data,'elx_pxf_pa','el'+sclet+'_p'+species+'f_pa' ; this is the pitch-angle for each time determined using IGRF and spin-axis attitude
    ; compute err from raw counts for nflux and eflux at each point in 2D spectra, for both half-spin and full-spin organization
    copy_data,'elx_pxf_val_full_err','el'+sclet+'_p'+species+'f_val_full_err'
    copy_data,'el'+sclet+'_p'+species+'f_pa_spec2plot_full','el'+sclet+'_p'+species+'f_pa_spec2plot_full_raw' ; this is half-spin res

    calc," 'el?_p?f_pa_spec2plot_full_err' = 1/sqrt('el?_p?f_pa_spec2plot_full_raw') " ; <-- what I will use later, err means df/f
    copy_data,'el'+sclet+'_p'+species+'f_pa_fulspn_spec2plot_full','el'+sclet+'_p'+species+'f_pa_fulspn_spec2plot_full_raw'; this is full-spin res

    calc," 'el?_p?f_pa_fulspn_spec2plot_full_err' = 1/sqrt('el?_p?f_pa_fulspn_spec2plot_full_raw') " ; <-- what I will use later, err means df/f
    tplot_names
   
    ; reload data in nflux, and eflux units next (two calls each: first reload data, then recompute spectra)
    elf_load_epd,probe=sclet,datatype='p'+species+'f',type = 'nflux'
    elf_getspec,probe=sclet,datatype='p'+species+'f',type = 'nflux',/get3Dspec,/fullspin;,LCpartol2use=11.;,fullspin=myfulspn,/delsplitspins;,/nodegaps
    copy_data,'elx_pxf_val_full','el'+sclet+'_p'+species+'f_val_full_nflux' ; this is the time series of nflux adjusted for gaps etc
    copy_data,'el'+sclet+'_p'+species+'f_pa_spec2plot_full','el'+sclet+'_p'+species+'f_pa_spec2plot_full_nflux' ; this is half-spin res
    copy_data,'el'+sclet+'_p'+species+'f_pa_fulspn_spec2plot_full','el'+sclet+'_p'+species+'f_pa_fulspn_spec2plot_full_nflux'; this is full-spin res
    ;
    ; reload data in eflux, eflux units now (two calls each: first reload data, then recompute spectra)
    elf_load_epd,probe=sclet,datatype='p'+species+'f',type = 'eflux'
    elf_getspec,probe=sclet,datatype='p'+species+'f',type = 'eflux',/get3Dspec,/fullspin;,LCpartol2use=11.;,fullspin=myfulspn,/delsplitspins;,/nodegaps
    copy_data,'elx_pxf_val_full','el'+sclet+'_p'+species+'f_val_full_eflux' ; this is the time series of nflux adjusted for gaps etc
    copy_data,'el'+sclet+'_p'+species+'f_pa_spec2plot_full','el'+sclet+'_p'+species+'f_pa_spec2plot_full_eflux' ; this is half-spin res
    copy_data,'el'+sclet+'_p'+species+'f_pa_fulspn_spec2plot_full','el'+sclet+'_p'+species+'f_pa_fulspn_spec2plot_full_eflux'; this is full-spin res

    ; need to interpoloate since some variables padded to include full spin
    tinterpol_mxn, 'el'+sclet+'_p'+species+'f_sectnum','el'+sclet+'_p'+species+'f_spinphase', suffix=''
    tinterpol_mxn, 'el'+sclet+'_p'+species+'f_nspinsinsum','el'+sclet+'_p'+species+'f_spinphase', suffix=''
    tinterpol_mxn, 'el'+sclet+'_p'+species+'f_nsectors','el'+sclet+'_p'+species+'f_spinphase', suffix=''
    copy_data, 'el'+sclet+'_p'+species+'f_sectnum_interp', 'el'+sclet+'_p'+species+'f_sectnum'
    copy_data, 'el'+sclet+'_p'+species+'f_nspinsinsum_interp', 'el'+sclet+'_p'+species+'f_nspinsinsum'
    copy_data, 'el'+sclet+'_p'+species+'f_nsectors_interp', 'el'+sclet+'_p'+species+'f_nsectors'
  
    ; retrieve phase delay values
    myphasedelay = elf_find_phase_delay(probe=sclet, instrument='epde', trange=[tstart,tend]) ; for reference only
    mysect2add=myphasedelay.DSECT2ADD ; record in file for reference
    mydSpinPh2add=myphasedelay.DPHANG2ADD ; record in file for reference
    get_data, 'el'+sclet+'_p'+species+'f_spinphase', data=d
    sect2add=make_array(n_elements(d.x), /double) + mysect2add
    spinph2add=make_array(n_elements(d.x), /double) + mydspinph2add
    store_data, 'el'+sclet+'_p'+species+'f_sect2add', data={x:d.x, y:sect2add}
    store_data, 'el'+sclet+'_p'+species+'f_spinph2add', data={x:d.x, y:spinph2add}
  
    options,'el'+sclet+'_p'+species+'f_val_full_?flux',spec=0
    tplot,'el'+sclet+'_p'+species+'f_'+['val_full_?flux','pa','spinphasedeg','spinper','sectnum'] ; just to see

    ; Convert names to match mastercdf (To Do: use correct names to begin with(
    copy_data, 'el'+sclet+'_p'+species+'f_val_full_nflux', 'el'+sclet+'_p'+species+'f_Et_nflux'
    copy_data, 'el'+sclet+'_p'+species+'f_val_full_eflux', 'el'+sclet+'_p'+species+'f_Et_eflux'
    copy_data, 'el'+sclet+'_p'+species+'f_val_full_err', 'el'+sclet+'_p'+species+'f_Et_dfovf'
    copy_data, 'el'+sclet+'_p'+species+'f_spinphasedeg', 'el'+sclet+'_p'+species+'f_spinphase'
    copy_data, 'el'+sclet+'_p'+species+'f_pa_spec2plot_full_nflux', 'el'+sclet+'_p'+species+'f_hs_Epat_nflux'
    copy_data, 'el'+sclet+'_p'+species+'f_pa_spec2plot_full_eflux', 'el'+sclet+'_p'+species+'f_hs_Epat_eflux'
    copy_data, 'el'+sclet+'_p'+species+'f_pa_spec2plot_full_err', 'el'+sclet+'_p'+species+'f_hs_Epat_dfovf'
    copy_data, 'el'+sclet+'_p'+species+'f_pa_fulspn_spec2plot_full_nflux', 'el'+sclet+'_p'+species+'f_fs_Epat_nflux'
    copy_data, 'el'+sclet+'_p'+species+'f_pa_fulspn_spec2plot_full_eflux', 'el'+sclet+'_p'+species+'f_fs_Epat_eflux'
    copy_data, 'el'+sclet+'_p'+species+'f_pa_fulspn_spec2plot_full_err', 'el'+sclet+'_p'+species+'f_fs_Epat_dfovf'
;stop
    ; these are the variables to be stored in the cdf
    variables2store='el'+sclet+'_p'+species+'f_'+['Et_nflux','Et_eflux','Et_dfovf',$ ; this is timeseries flux information and err
      'pa','spinphase','tspin','sectnum','nspinsinsum','nsectors','spinph2add','sect2add', $ ; this is ancillary timeseries data
      'hs_Epat_nflux','hs_Epat_eflux','hs_Epat_dfovf',$ ; this is 2D half-spin resolution spectra
      'fs_Epat_nflux','fs_Epat_eflux','fs_Epat_dfovf',$
      'hs_epa_spec', 'fs_epa_spec']


    ; Science zones need to be run one at a time. This section appends each science zone to be used when ready to write to CDF
    get_data, variables2store[0], data=dat, dlimits=dldat, limits=ldat
print, variables2store[0]
help, dldat
help, ldat
;stop
    append_array, et_time_arr, dat.x
    append_array, et_nflux_arr, dat.y
    et_nflux_dl = dldat
    et_nflux_l=ldat
    get_data, variables2store[1], data=dat, dlimits=dldat, limits=ldat
print, variables2store[1]
et_eflux_dl=dldat
et_eflux_l=ldat
help, dldat
help, ldat
;stop
    append_array, et_eflux_arr, dat.y
    get_data, variables2store[2], data=dat, dlimits=dldat, limits=ldat
    print, variables2store[2]
    et_eflux_dl=dldat
    et_eflux_l=ldat
    help, dldat
    help, ldat
;    stop
    append_array, et_dfovf_arr, dat.y
    get_data, variables2store[3], data=dat, dlimits=dldat, limits=ldat
    print, variables2store[3]
    et_dfovf_dl=dldat
    et_dfovf_l=ldat
    help, dldat
    help, ldat
;    stop
    append_array, pa_arr, dat.y
    get_data, variables2store[4], data=dat, dlimits=dldat, limits=ldat
    print, variables2store[4]
    spinphase_dl = dldat
    spinphase_l=ldat
    help, dldat
    help, ldat
;    stop
    append_array, spinphase_arr, dat.y
    get_data, variables2store[5], data=dat, dlimits=dldat, limits=ldat
    print, variables2store[5]
    tspin_dl = dldat
    tspin_l=ldat
    help, dldat
    help, ldat
;    stop
    append_array, tspin_arr, dat.y
    tspin_dl = dldat
    tspin_l=ldat
    get_data, variables2store[6], data=dat, dlimits=dldat, limits=ldat
    print, variables2store[6]
    append_array, sectnum_arr, dat.y
    sectnum_dl = dldat
    sectnum_l=ldat
stop
    get_data, variables2store[7], data=dat, dlimits=dldat, limits=ldat
    print, variables2store[7]
    help, dldat
    help, ldat
;stop
    append_array, nspinsinsum_arr, dat.y
    nspinsinsum_dl = dldat
    nspinsinsum_l=ldat
    get_data, variables2store[8], data=dat, dlimits=dldat, limits=ldat
    print, variables2store[8]
    help, dldat
    help, ldat
;stop
    append_array, nsectors_arr, dat.y
    nsectors_dl = dldat
    nsectors_l=ldat
    get_data, variables2store[9], data=dat, dlimits=dldat, limits=ldat
    print, variables2store[9]
    help, dldat
    help, ldat
;stop
    append_array, spinph2add_arr, dat.y
    spinph2add_dl = dldat
    spinph2add_l=ldat
    get_data, variables2store[10], data=dat, dlimits=dldat, limits=ldat
    print, variables2store[10]
    help, dldat
    help, ldat
;    stop
    append_array, sect2add_arr, dat.y
    sect2add_dl = dldat
    sect2add_l=ldat
    get_data, variables2store[11], data=dat, dlimits=dldat, limits=ldat
    print, variables2store[11]
    help, dldat
    help, ldat
;    stop
    append_array, hs_time_arr, dat.x
    append_array, hs_nflux_arr, dat.y
    append_array, hs_epa_spec_arr, dat.v
    hs_nflux_dl = dldat
    hs_nflux_l=ldat
    hs_epa_spec_dl = dldat
    hs_epa_spec_l=ldat
    get_data, variables2store[12], data=dat, dlimits=dldat, limits=ldat
    print, variables2store[12]
    help, dldat
    help, ldat
;    stop
    append_array, hs_eflux_arr, dat.y
    hs_eflux_dl = dldat
    hs_eflux_l=ldat
    get_data, variables2store[13], data=dat, dlimits=dldat, limits=ldat
    print, variables2store[13]
    help, dldat
    help, ldat
;    stop
    append_array, hs_dfovf_arr, dat.y
    get_data, variables2store[14], data=dat, dlimits=dldat, limits=ldat
    print, variables2store[14]
    help, dldat
    help, ldat
;    stop
    append_array, fs_time_arr, dat.x
    append_array, fs_nflux_arr, dat.y
    append_array, fs_epa_spec_arr, dat.v
    fs_nflux_dl = dldat
    fs_nflux_l=ldat
    fs_epa_spec_dl = dldat
    fs_epa_spec_l=ldat
    get_data, variables2store[15], data=dat, dlimits=dldat, limits=ldat
    print, variables2store[15]
    help, dldat
    help, ldat
;    stop
    append_array, fs_eflux_arr, dat.y
    fs_eflux_dl = dldat
    fs_eflux_l=ldat
    get_data, variables2store[16], data=dat, dlimits=dldat, limits=ldat
    print, variables2store[16]
    help, dldat
    help, ldat
;    stop
    append_array, fs_dfovf_arr, dat.y

;del_data, '*'
;    tstart='2022-05-14';/06:23:00'
;    tend='2022-05-15';/06:27:00'
    ;
;    time2plot=[tstart,tend]
;    timeduration=time_double(tend)-time_double(tstart)
;    timespan,tstart,timeduration,/seconds ; set the analysis time interval
    ;
;    sclet='b'
;    species='e'
    ;
;    elf_load_state,probe=sclet,/get_supp

  endfor

data_file_name=!elf.local_data_dir+'\el'+sclet+'_l2_epd_data_save'
limits_file_name=!elf.local_data_dir+'\el'+sclet+'_l2_epd_limits_save'
stop
tplot_save, variables2store, filename=data_file_name
tplot_save, variables2store, filename=limits_file_name, /limits
stop
;  varstosave=[fs_eflux_dl, fs_eflux_l, fs_nflux_dl, fs_nflux_l, fs_epa_spec_dl, fs_epa_spec_l, $
;              hs_eflux_dl, hs_eflux_l, hs_nflux_dl, hs_nflux_l, hs_epa_spec_dl, hs_epa_spec_l, $
;              eflux_dl, eflux_l, nflux_dl, nflux_l, spinph2add_dl, spinph2add_l, nspinsinsum_dl, $
;              nspinsinsum_l, sect2add_dl, sect2add_l, nsectors_dl, nsectors_l, sectnum_dl, $
;              sectnum_l, tspin_dl, tspin_l, spinphase_dl, spinphase_l, pa_dl, pa_l]
              
  ;savefile='C:\Users\clrussell\Desktop\epd_l2_limits.sav'
;  stop
  ; Reset time 
  tr=time_double([tstart, tend])
  dur=time_double(tend)-time_double(tstart)
  timespan, tstart, dur, /sec

  ; set up file names
  daily_names = file_dailynames(trange=tr, /unique, times=times)
  if n_elements(daily_names) GT 1 then daily_names=daily_names[0]
  if species EQ 'e' then subdir='electron' else subdir='ion'
  year=strmid(daily_names, 0,4)
  local_cdf_file=!elf.local_data_dir+'\el'+sclet+'\l2\epd\fast\'+subdir+'\'+year+'\el'+sclet+'_l2_epd'+species+'f_'+daily_names+'_v01.cdf'
  mastercdf_file=!elf.local_data_dir+'\el'+sclet+'\el'+sclet+'_l2_epd'+species+'f_00000000_v01.cdf'
  ; if there is already a cdf file delete it (cdf can't overwrite)
  fileresult=FILE_SEARCH(local_cdf_file)
  if size(fileresult,/dimen) eq 1 then FILE_DELETE,local_cdf_file ; delete old folder
 
  ; get mastercdf struc
  epd_cdf_struc=cdf_load_vars(mastercdf_file, /all)
  mastertags=epd_cdf_struc.vars.name
  epd_vars=variables2store

  ; times
  ; convert times to tt2000
  for k=0, n_elements(et_time_arr)-1 do append_array, et_tt2000_arr, unix_to_tt2000(et_time_arr[k])
  for k=0, n_elements(hs_time_arr)-1 do append_array, hs_tt2000_arr, unix_to_tt2000(hs_time_arr[k])
  for k=0, n_elements(fs_time_arr)-1 do append_array, fs_tt2000_arr, unix_to_tt2000(fs_time_arr[k])
  time_vars='el'+sclet+'_p'+species+'f_'+['et_time', 'hs_time', 'fs_time']
  time_vars_arr=[et_tt2000_arr, hs_tt2000_arr, fs_tt2000_arr]
  index=where(time_vars[0] eq mastertags)
  epd_cdf_struc.vars[index].dataptr=ptr_new(et_tt2000_arr)
  index=where(time_vars[1] eq mastertags)
  epd_cdf_struc.vars[index].dataptr=ptr_new(hs_tt2000_arr)
  index=where(time_vars[2] eq mastertags)
  epd_cdf_struc.vars[index].dataptr=ptr_new(fs_tt2000_arr)
  
; science
  index=where(epd_vars[0] eq mastertags)
  epd_cdf_struc.vars[index].dataptr=ptr_new(et_nflux_arr)
  index=where(epd_vars[1] eq mastertags)
  epd_cdf_struc.vars[index].dataptr=ptr_new(et_eflux_arr)
  index=where(epd_vars[2] eq mastertags)
  epd_cdf_struc.vars[index].dataptr=ptr_new(et_dfovf_arr)
  index=where(epd_vars[3] eq mastertags)
  epd_cdf_struc.vars[index].dataptr=ptr_new(pa_arr)
  index=where(epd_vars[4] eq mastertags)
  epd_cdf_struc.vars[index].dataptr=ptr_new(spinphase_arr)
  index=where(epd_vars[5] eq mastertags)
  epd_cdf_struc.vars[index].dataptr=ptr_new(tspin_arr)
  index=where(epd_vars[6] eq mastertags)
  epd_cdf_struc.vars[index].dataptr=ptr_new(sectnum_arr)
  index=where(epd_vars[7] eq mastertags)
  epd_cdf_struc.vars[index].dataptr=ptr_new(nspinsinsum_arr)
  index=where(epd_vars[8] eq mastertags)
  epd_cdf_struc.vars[index].dataptr=ptr_new(nsectors_arr)
  index=where(epd_vars[9] eq mastertags)
  epd_cdf_struc.vars[index].dataptr=ptr_new(spinph2add_arr)
  index=where(epd_vars[10] eq mastertags)
  epd_cdf_struc.vars[index].dataptr=ptr_new(sect2add_arr)
  index=where(epd_vars[11] eq mastertags)
  epd_cdf_struc.vars[index].dataptr=ptr_new(hs_nflux_arr)
  index=where(epd_vars[12] eq mastertags)
  epd_cdf_struc.vars[index].dataptr=ptr_new(hs_eflux_arr)
  index=where(epd_vars[13] eq mastertags)
  epd_cdf_struc.vars[index].dataptr=ptr_new(hs_dfovf_arr)
  index=where(epd_vars[14] eq mastertags)
  epd_cdf_struc.vars[index].dataptr=ptr_new(fs_nflux_arr)
  index=where(epd_vars[15] eq mastertags)
  epd_cdf_struc.vars[index].dataptr=ptr_new(fs_eflux_arr)
  index=where(epd_vars[16] eq mastertags)
  epd_cdf_struc.vars[index].dataptr=ptr_new(fs_dfovf_arr)
  index=where(epd_vars[17] eq mastertags)
  epd_cdf_struc.vars[index].dataptr=ptr_new(hs_epa_spec_arr)
  index=where(epd_vars[18] eq mastertags)
  epd_cdf_struc.vars[index].dataptr=ptr_new(fs_epa_spec_arr)
 
  epd_cdf_struc.g_attributes.generation_date=systime()
stop 
  dummy=cdf_save_vars2(epd_cdf_struc, local_cdf_file)
  print, 'L2 EPDE CDF file written! Filename: ', local_cdf_file
 
  ptr_free 

end
