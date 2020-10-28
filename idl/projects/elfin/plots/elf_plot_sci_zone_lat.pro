pro elf_plot_sci_zone_lat, probe=probe, tstart=tstart, dur=dur

  tstart=time_double('2020-08-01')
  dur=40
  probe='b'
  if undefined(probe) then probe='a' else probe=probe
  
;  for i=0,37 do begin

;    this_start=tstart + i*86400.
;    this_end=this_start + 86400.

    timespan, tstart, 40., /days

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
          smag=mag_lat.y[midx]
          mdiff=min(abs(mag_lat.x - this_e),midx)
          emag=mag_lat.y[midx]
        endelse
        if (this_e-this_s) lt 60. then continue
        append_array, sz_starttimes, this_s
        append_array, sz_endtimes, this_e
        append_array, sz_min_st, sidx
        append_array, sz_min_en, eidx
        append_array, s_lats, smag
        append_array, e_lats, emag
      endfor
    endelse

  ; figure out mag lats for starts
  if probe eq 'a' then begin  
    idx=where(s_lats GT 0, ncnt)
    if ncnt GT 0 then begin
      na_starts=sz_starttimes[idx]
      na_smags=s_lats[idx]
    endif
    idx=where(s_lats LT 0, ncnt)
    if ncnt GT 0 then begin
      sa_starts=sz_starttimes[idx]
      sa_smags=s_lats[idx]
    endif
  endif else begin
    idx=where(s_lats GT 0, ncnt)
    if ncnt GT 0 then begin
      nb_starts=sz_starttimes[idx]
      nb_smags=s_lats[idx]
    endif
    idx=where(s_lats LT 0, ncnt)
    if ncnt GT 0 then begin
      sb_starts=sz_starttimes[idx]
      sb_smags=s_lats[idx]
    endif    
  endelse

  if probe EQ 'a' then save, file='test_mag'+probe+'_starts.sav', na_starts, na_smags, sa_starts, sa_smags, tstart
  if probe EQ 'b' then save, file='test_mag'+probe+'_starts.sav', nb_starts, nb_smags, sb_starts, sb_smags, tstart

; REPEAT for ends figure out mag lats for ends
if probe eq 'a' then begin
  idx=where(e_lats GT 0, ncnt)
  if ncnt GT 0 then begin
    na_ends=sz_endtimes[idx]
    na_emags=e_lats[idx]
  endif
  idx=where(e_lats LT 0, ncnt)
  if ncnt GT 0 then begin
    sa_ends=sz_endtimes[idx]
    sa_emags=e_lats[idx]
  endif
endif else begin
  idx=where(e_lats GT 0, ncnt)
  if ncnt GT 0 then begin
    nb_ends=sz_endtimes[idx]
    nb_emags=e_lats[idx]
  endif
  idx=where(e_lats LT 0, ncnt)
  if ncnt GT 0 then begin
    sb_ends=sz_endtimes[idx]
    sb_emags=e_lats[idx]
  endif
endelse

if probe EQ 'a' then save, file='test_mag'+probe+'_ends.sav', na_ends, na_emags, sa_ends, sa_emags, tstart
if probe EQ 'b' then save, file='test_mag'+probe+'_ends.sav', nb_ends, nb_emags, sb_ends, sb_emags, tstart


del_data, '*'
undefine, sz_starttimes
undefine, sz_endtimes
undefine, sz_min_st
undefine, sz_min_en
undefine, s_lats
undefine, s_lats
 
restore, file='test_maga_starts.sav'
t0=time_double('2020-08-01')
sdays_na=(na_starts-t0)/86400.
sdays_sa=(sa_starts-t0)/86400.
smags_na=na_smags
smags_sa=sa_smags

restore, file='test_magb_starts.sav'
t0=time_double('2020-08-01')
sdays_nb=(nb_starts-t0)/86400.
sdays_sb=(sb_starts-t0)/86400.
smags_nb=nb_smags
smags_sb=sb_smags

restore, file='test_maga_ends.sav'
t0=time_double('2020-08-01')
edays_na=(na_ends-t0)/86400.
edays_sa=(sa_ends-t0)/86400.
emags_na=na_emags
emags_sa=sa_emags

restore, file='test_magb_ends.sav'
t0=time_double('2020-08-01')
edays_nb=(nb_ends-t0)/86400.
edays_sb=(sb_ends-t0)/86400.
emags_nb=nb_emags
emags_sb=sb_emags

thm_init
!p.multi=[0,2,2,0,0]
window, xsize=850, ysize=950

title='ELFIN A North Science Zones'
xtitle='Days since August 1, 2020'
ytitle='Starting/Ending Magnetic Latitude, deg'
subtitle='Start - Blue Square, End = Red Diamond'
;plot, sdays_na, smags_na, title=title, xtitle=xtitle, ytitle=ytitle, $
;    yrange=[0,90], linestyle=1, subtitle=subtitle
  plot, sdays_na, smags_na, title=title, xtitle=xtitle, ytitle=ytitle, $
    yrange=[0,90], psym=6, subtitle=subtitle
oplot, sdays_na, smags_na, color=80, psym=6
;oplot, edays_na, emags_na, linestyle=1
oplot, edays_na, emags_na, color=250, psym=4

title='ELFIN B North Science Zones'
xtitle='Days since August 1, 2020'
ytitle='Starting/Ending Magnetic Latitude, deg'
;plot, sdays_nb, smags_nb, title=title, xtitle=xtitle, ytitle=ytitle, $
 ; yrange=[0,90], linestyle=1, subtitle=subtitle
  plot, sdays_nb, smags_nb, title=title, xtitle=xtitle, ytitle=ytitle, $
    yrange=[0,90], psym=6, subtitle=subtitle
oplot, sdays_nb, smags_nb, color=80, psym=6
;oplot, edays_nb, emags_nb, linestyle=1
oplot, edays_nb, emags_nb, color=250, psym=4

title='ELFIN A South Science Zones'
subtitle='Start - Blue Square, End = Red Diamond'
plot, sdays_sa, smags_sa, title=title, xtitle=xtitle, ytitle=ytitle, $
  yrange=[0,-90], psym=6, subtitle=subtitle
oplot, sdays_sa, smags_sa, color=80, psym=6
;oplot, edays_sa, emags_sa, linestyle=1
oplot, edays_sa, emags_sa, color=250, psym=4

title='ELFIN B South Science Zones'
plot, sdays_sb, smags_sb, title=title, xtitle=xtitle, ytitle=ytitle, $
  yrange=[0,-90], psym=6, subtitle=subtitle
oplot, sdays_sb, smags_sb, color=80, psym=6
;oplot, edays_sb, emags_sb, linestyle=1
oplot, edays_sb, emags_sb, color=250, psym=4

makejpg, 'C:\Users\clrussell\Desktop\Starting and Ending Magnetic Latitudes in Science Zones 20200801'


end