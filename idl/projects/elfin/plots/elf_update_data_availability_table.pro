;+
; PROCEDURE:
;         elf_update_data_availability_table
;
; PURPOSE:
;         Update the data availability page
;
; KEYWORDS:
;         tdate: time to be used for calculation
;                (format can be time string '2020-03-20'
;                or time double)
;         probe: probe name, probes include 'a' and 'b'
;         instrument: instrument name, insturments include 'epd', 'fgm', 'mrm'
;
; OUTPUT:
;
; EXAMPLE:
;         elf_update_data_availability_table, '2020-03-20', probe='a', instrument='mrm'
;
;-
pro elf_update_data_availability_table, tdate, probe=probe, instrument=instrument, days = days
 
  ; initialize parameters
  if undefined(tdate) then begin
    print, 'You must provide a date. Example: 2020-01-01'
    return
  endif
  
  timespan, time_double(tdate)-31.*86400., 31d
  trange=timerange()

  if undefined(instrument) then instrument='epd' else instrument=strlowcase(instrument)
  if instrument ne 'epd' and instrument ne 'fgm' and $
    instrument ne 'mrm' then begin
    print, instrument + ' is not a valid instrument'
    print, 'Valid instruments include epd, fgm, and mrm.'
    return
  endif
  
  if undefined(probe) then probe='a' else probe=strlowcase(probe)
  if probe ne 'a' and probe ne 'b' then begin
    print, probe+' is not a valid probe name.'
    print, 'Valid probe names are a or b.'
    return
  endif
  sc='el'+probe

  ; Determine what data is available
  data_avail=elf_get_data_availability(tdate, probe=probe, instrument=instrument)
  ; Update the csv file
  if ~undefined(data_avail) && size(data_avail, /type) EQ 8 then begin
    print, 'Data available'
    filename='el'+probe+'_'+instrument
    print, filename
    elf_write_data_availability_table, filename, data_avail, instrument, probe
  endif else begin
    print, 'There is no data for probe '+probe+' , instrument '+instrument+' on '+time_string(tdate)     
  endelse
  Beep
 
end