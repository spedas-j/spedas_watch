pro elf_plot_sci_zone_lat, probe=probe, tstart=tstart, dur=dur

  tstart=time_double('2020-06-01')
  dur=38
  probe='b'
  if undefined(probe) then probe='a' else probe=probe
  
;  for i=0,37 do begin

;    this_start=tstart + i*86400.
;    this_end=this_start + 86400.

    timespan, tstart, 38., /days

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Get position data
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    elf_load_state, probes=probe;, trange=[this_start, this_end]
    get_data, 'el'+probe+'_pos_gei', data=dat_gei
    cotrans,'el'+probe+'_pos_gei','el'+probe+'_pos_gse',/GEI2GSE
    cotrans,'el'+probe+'_pos_gse','el'+probe+'_pos_gsm',/GSE2GSM
    cotrans,'el'+probe+'_pos_gsm','el'+probe+'_pos_sm',/GSM2SM ; in SM
  
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Get MLT amd LAT
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    elf_mlt_l_lat,'el'+probe+'_pos_sm',MLT0=MLT0,L0=L0,lat0=lat0 ;;subroutine to calculate mlt,l,mlat under dipole configuration
    get_data, 'el'+probe+'_pos_sm', data=elfin_pos
    store_data,'el'+probe+'_LAT',data={x:elfin_pos.x,y:lat0*180./!pi}
    get_data, 'el'+probe+'_LAT', data=mag_lat

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Get EPD data
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    elf_load_epd, probes=probe, datatype='pef', level='l1', type='nflux', no_download=no_download
    get_data, 'el'+probe+'_pef_nflux', data=pef_nflux
    if size(pef_nflux, /type) NE 8 then begin
      dprint, dlevel=0, 'No data was downloaded for el' + probe + '_pef_nflux.'
      dprint, dlevel=0, 'No plots were producted.
    endif

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Find science zone starts
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
          mdiff=min(abs(mag_lat.x - this_s),midx)
          this_mag=mag_lat.y[midx]
        endif else begin
          this_s = pef_nflux.x[idx[sz-1]+1]
          sidx = idx[sz-1]+1
          this_e = pef_nflux.x[idx[sz]]
          eidx = idx[sz]
          mdiff=min(abs(mag_lat.x - this_s),midx)
          this_mag=mag_lat.y[midx]
        endelse
        if (this_e-this_s) lt 60. then continue
        append_array, sz_starttimes, this_s
        append_array, sz_endtimes, this_e
        append_array, sz_min_st, sidx
        append_array, sz_min_en, eidx
        append_array, mag_lats, this_mag
      endfor
    endelse

  if probe eq 'a' then begin  
    idx=where(mag_lats GT 0, ncnt)
    if ncnt GT 0 then begin
      na_starts=sz_starttimes[idx]
      na_mags=mag_lats[idx]
    endif
    idx=where(mag_lats LT 0, ncnt)
    if ncnt GT 0 then begin
      sa_starts=sz_starttimes[idx]
      sa_mags=mag_lats[idx]
    endif
  endif else begin
    idx=where(mag_lats GT 0, ncnt)
    if ncnt GT 0 then begin
      nb_starts=sz_starttimes[idx]
      nb_mags=mag_lats[idx]
    endif
    idx=where(mag_lats LT 0, ncnt)
    if ncnt GT 0 then begin
      sb_starts=sz_starttimes[idx]
      sb_mags=mag_lats[idx]
    endif    
  endelse
  if probe EQ 'a' then save, file='test_mag'+probe+'.sav', na_starts, na_mags, sa_starts, sa_mags, tstart
  if probe EQ 'b' then save, file='test_mag'+probe+'.sav', nb_starts, nb_mags, sb_starts, sb_mags, tstart
    stop

del_data, '*'
undefine, sz_starttimes
undefine, sz_endtimes
undefine, sz_min_st
undefine, sz_min_en
undefine, sz_mag_lats
  
restore, file='test_maga.sav'
t0=time_double('2020-06-01')
days_na=(na_starts-t0)/86400.
days_sa=(sa_starts-t0)/86400.
mags_na=na_mags
mags_sa=sa_mags

restore, file='test_magb.sav'
t0=time_double('2020-06-01')
days_nb=(nb_starts-t0)/86400.
days_sb=(sb_starts-t0)/86400.
mags_nb=nb_mags
mags_sb=sb_mags

thm_init
!p.multi=[0,0,2,0,0]
window, xsize=750, ysize=950
title='North Ascending Science Zone'
xtitle='Days since June 1, 2020'
ytitle='Starting Magnetic Latitude, deg'

plot, days_na, na_mags, title=title, xtitle=xtitle, ytitle=ytitle, $
  yrange=[0,75], linestyle=1
oplot, days_na, na_mags, color=80, psym=6
oplot, days_nb, nb_mags, linestyle=1
oplot, days_nb, nb_mags, color=250, psym=4

title='Souh Ascending Science Zone'
xtitle='Days since June 1, 2020'
ytitle='Starting Magnetic Latitude, deg'
subtitle='ELF A - Blue Square, ELF B = Red Diamond'

plot, days_sb, sb_mags, title=title, xtitle=xtitle, ytitle=ytitle, subtitle=subtitle, $
  yrange=[-75,0], linestyle=1
oplot, days_sa, sa_mags, linestyle=1
oplot, days_sa, sa_mags, color=80, psym=6, symsize=1.25
oplot, days_sb, sb_mags, color=250, psym=4
makejpg, 'C:\Users\clrussell\Desktop\Starting Magnetic Latitudes in Science Zones'
 
 
end