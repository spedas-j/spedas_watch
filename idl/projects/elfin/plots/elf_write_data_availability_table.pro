;+
; PROCEDURE:
;         elf_write_data_availability_table
;
; PURPOSE:
;         Write to and update the data availability
;
; KEYWORDS:
;         tdate: time to be used for calculation
;                (format can be time string '2020-03-20'
;                or time double)
;         probe: probe name, probes include 'a' and 'b'
;         instrument: instrument name, insturments include 'epd', 'fgm', 'mrm'
;         data: structure containing the availability data, start times, stop
;               times and science zone 
;
; OUTPUT:
;
; EXAMPLE:
;         elf_write_data_availability_table, filename, data_avail
;
;-
pro elf_write_data_availability_table, filename, data

  ; initialize parameters
  if undefined(filename) then begin
    print, 'You must provide a name for the csv file.'
    return
  endif
  if undefined(data) then begin
    print, 'You must provide data availability for the csv file.'
    return
  endif

  if instrument NE 'mrm' then begin 
    
    zone_names=['sasc','nasc','sdes','ndes']  
    for i=0,3 do begin
      idx=where(data.zones eq zone_names[i],ncnt)
      if ncnt LE 0 then continue
      data_nasc=data[idx]
      this_file = filename + '_' + zone_names[i] + '.csv'  

       ; open csv file
       ; read down to the date data.starttimes[0]
       ; delete existing data for the date
       ; write new data
       ; close csv file  
    endfor
    
  endif else begin
    ;  handle mrm data (should only be one entry)
  endelse
  
  
end