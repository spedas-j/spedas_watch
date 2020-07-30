;+
; FUNCTION:
;         elf_get_data_availability
;
; PURPOSE:
;         Get start and stop science zone collection data for a
;         given instrument, probe and date
;
; KEYWORDS:
;         tdate: time to be used for calculation
;                (format can be time string '2020-03-20'
;                or time double)
;         probe: probe name, probes include 'a' and 'b'
;         instrument: instrument name, insturments include 'epd', 'fgm', 'mrm'
;
; OUTPUT:
;         data_availability: structure with start times, stop times and science 
;         zone names. Note: mrm data does not have a science zone associated 
;         with it.
;
; EXAMPLE:
;         data_struct=elf_get_data_availability('2020-03-20', probe='a', instrument='epd'
;
;-
function elf_get_data_availability, tdate=tdate, instrument=instrument, probe=probe

  ; initialize parameters
  if undefined(tdate) then begin
     print, 'You must provide a date. Example: 2020-01-01'
     return, -1 
  endif
  ;timespan, tdate-30.*86400., 30.d
  timespan, tdate, 1.0d
  trange=timerange()
  ;current_time=systime() 
   
  if undefined(instrument) then instrument='epd' else instrument=strlowcase(instrument)
  if instrument ne 'epd' and instrument ne 'fgm' and $
    instrument ne 'mrm' then begin
    print, instrument + ' is not a valid instrument'
    print, 'Valid instruments include epd, fgm, and mrm.'
    return, -1
  endif

  if undefined(probe) then probe='a' else probe=strlowcase(probe)
  if probe ne 'a' and probe ne 'b' then begin
     print, probe+' is not a valid probe name.'
     print, 'Valid probe names are a or b.'
     return, -1
  endif
  sc='el'+probe

  ; GET DATA
  Case instrument of
    'epd': begin
      elf_load_epd, probe=probe, trange=trange, type='cps'
      get_data, sc+'_pef_cps', data=d
    end
    'fgm': begin
      elf_load_fgm, probe=probe, trange=trange
      get_data, sc+'_fgs', data=d
    end
    'mrm': begin
      elf_load_mrma, probe=probe, trange=trange
      get_data, sc+'_mrma', data=d
    end
  Endcase
    
  ; check for collections
  if ~undefined(d) && size(d,/type) EQ 8 then begin
    npts=n_elements(d.x)
    tdiff=d.x[1:npts-1] - d.x[0:npts-2]
    idx = where(tdiff GT 600., ncnt)   ; note: 600 seconds is an arbitary time
    append_array, idx, n_elements(d.x)-1 ;add on last element (end time of last sci zone) to pick up last sci zone

    if ncnt EQ 0 then begin
      ; if ncnt is zero then there is only one science zone for this time frame
      sz_starttimes=[d.x[0]]
      sz_endtimes=d.x[n_elements(d.x)-1]
      ts=time_struct(sz_starttimes[0])
      te=time_struct(sz_endtimes[0])
    endif else begin

      for sz=0,ncnt do begin ;changed from ncnt-1
        if sz EQ 0 then begin
          this_s = d.x[0]
          this_e = d.x[idx[sz]]
        endif else begin
          this_s = d.x[idx[sz-1]+1]
          this_e = d.x[idx[sz]]
;          eidx = idx[sz]
        endelse
        if (this_e-this_s) lt 60. then continue
        append_array, sz_starttimes, this_s
        append_array, sz_endtimes, this_e
      endfor
    endelse
  endif else begin
    ; no data
    print, 'There is no data for '+instrument+' on '+tdate
    return, -1 
  endelse
  
  ; Find which size zone
  if instrument EQ 'epd' or instrument EQ 'fgm' then begin

    ; get position data and convert to SM coordinates
    elf_load_state, probe=probe, trange=trange
    get_data, sc+'_pos_gei', data=dat_gei
    cotrans,sc+'_pos_gei','el'+probe+'_pos_gse',/GEI2GSE
    cotrans,sc+'_pos_gse','el'+probe+'_pos_gsm',/GSE2GSM
    cotrans,sc+'_pos_gsm','el'+probe+'_pos_sm',/GSM2SM ; in SM
    ; check that it exsits
    if not spd_data_exists(sc+'_pos_sm', trange[0],trange[1]) then begin
       print, 'There is no state data '+ ' on '+tdate
       return, -1
    endif 
    
    ; get position data to determine whether s/c is ascending or descending
    get_data, sc+'_pos_sm', data=pos   
    ; get latitude of science collection (needed to determine zone)
    elf_mlt_l_lat,sc+'_pos_sm',MLT0=MLT0,L0=L0,lat0=lat0 ;;subroutine to calculate mlt,l,mlat under dipole configuration
    
    ; Determine which science zone data was collected for  
    for i=0,n_elements(sz_starttimes)-1 do begin
      this_start=sz_starttimes[i]
      this_end=sz_endtimes[i] 
      idx=where(pos.x GE this_start AND pos.x LE this_end, ncnt)
      if ncnt eq 0 then begin
        print, 'There is no state data for start: '+time_string(this_start)+' to '+time_string(this_end)
        return, -1
      endif
      sz_lat=lat0[idx] 
      median_lat=median(sz_lat)
      dlat = sz_lat[1:n_elements(sz_lat)-1] - sz_lat[0:n_elements(sz_lat)-2]
      if median_lat GT 0 then begin
        if median(dlat) GT 0 then sz_name = 'nasc' else sz_name = 'ndes'
      endif else begin
        if median(dlat) GT 0 then sz_name = 'sasc' else sz_name =  'sdes'
      endelse
      append_array, sz_names, sz_name
    endfor     
    data_availability={starttimes:sz_starttimes, endtimes:sz_endtimes, zones:sz_names}

  ; Handle MRM data (only 1 collection every other day)      
  endif else begin
    mrm_start = d.x[0]
    mrm_end = d.x[n_elements(d.x)-1]  
    data_availability={starttimes:sz_starttimes, endtimes:sz_endtimes} 
  endelse
  
  return, data_availability
   
end