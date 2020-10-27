;+
; PROCEDURE:
;         elf_write_data_availability_table
;
; PURPOSE:
;         Write to and update the data availability
;
; KEYWORDS:
;         filename: name of the csv file
;         newdat: structure containing the availability data, start times, stop
;               times and science zone
;         instrument: instrument name, insturments include 'epd', 'fgm', 'mrm'
;         probe: probe name, probes include 'a' and 'b'
;
; OUTPUT:
;
; EXAMPLE:
;         elf_write_data_availability_table, filename, data_avail, 'epd', 'a'
;
;-
pro elf_write_data_availability_table, filename, newdat, instrument, probe

  ; initialize parameters
  if undefined(filename) then begin
    print, 'You must provide a name for the csv file.'
    return
  endif
  if undefined(newdat) then begin
    print, 'You must provide data availability for the csv file.'
    return
  endif

  if instrument NE 'mrm' then begin
    
    zone_names=['sasc','nasc','sdes','ndes']  
    for i=0,3 do begin
      idx=where(newdat.zones eq zone_names[i], ncnt)
      if ncnt LE 0 then continue
      data_nasc=newdat[idx]
      this_file = filename + '_' + zone_names[i] + '.csv'  
      
      ;writing the header
      if i eq 0 then pos = ' South Ascending'
      if i eq 1 then pos = ' North Ascending'
      if i eq 2 then pos = ' South Descending'
      if i eq 3 then pos = ' North Descending'
      print, pos
      header = [['ELFIN ' + strupcase(probe) + ' - '+ strupcase(instrument) + pos + ' Science Collections'],['']]
      
      ;reading the data
      olddat = READ_CSV(this_file, RECORD_START = 1)

      ;finding the start/end index
      olddat_doub = {name:'olddat_doub', starttimes: time_double(olddat.field1), endtimes: time_double(olddat.field2)}
      starttimes = [olddat_doub.starttimes, newdat.starttimes]
      endtimes = [olddat_doub.endtimes, newdat.endtimes]
      
      ;sorting
      sorting = sort(starttimes)
      starttimes = starttimes[sorting]
      endtimes = endtimes[sorting]

      unique = uniq(time_string(starttimes))
      starttimes = starttimes[unique]
      endtimes = endtimes[unique]

      ;rewriting existing file
      write_csv, this_file, time_string(starttimes), time_string(endtimes), HEADER = header
      print, 'Finished Writing to File:'
      close, /all
      newentries = n_elements(starttimes) - n_elements(olddat.field1)
      
    endfor
    
 endif else begin
      ;  handle mrm data (should only be one entry)
      ;reading the data
      this_file = 'el'+probe+'_'+instrument+'.csv'

      ;writing the header
      
      header = [['ELFIN '+ strupcase(probe) + ' - '+ strupcase(instrument)],['']]
      
      ;reading the data
      olddat = READ_CSV(this_file, RECORD_START = 1)

      ;finding the start/end index
      olddat_doub = {name:'olddat_doub', starttimes: time_double(olddat.field1), endtimes: time_double(olddat.field2)}
      starttimes = [olddat_doub.starttimes, newdat.starttimes]
      endtimes = [olddat_doub.endtimes, newdat.endtimes]

      ;sorting (do not use the sort parameter within uniq, it doesn't work)
      sorting = sort(starttimes)
      starttimes = starttimes[sorting]
      endtimes = endtimes[sorting]

      unique = uniq(time_string(starttimes))
      starttimes = starttimes[unique]
      endtimes = endtimes[unique]

      ;rewriting existing file
      write_csv, this_file, time_string(starttimes), time_string(endtimes), HEADER = header
      print, 'Finished Writing to File:'
      close, /all
      newentries =  n_elements(starttimes) - n_elements(olddat.field1)
      
 endelse
      print, 'there are ', newentries, ' new entries'
end