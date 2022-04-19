pro elf_create_instrument_all, trange = trange, nodownload = nodownload, probe = probe, instrument = instrument, update = update
  ;if the badflag is activated, it will mark the fits with a bad flag as not fit.
  ;fits with a bad flag will then be included in the missing szs result.

  ; define local and remote paths

  if keyword_set(probe) then probes = probe else probes = ['a', 'b']
  if keyword_set(instrument) then instruments = instrument else instruments = ['epd', 'fgm', 'mrm']
  if keyword_set(update) then update = update else update = 0
  
  foreach instrument, instruments do begin 
    foreach probe, probes do begin 
      
      ; find file
      local_path=!elf.LOCAL_DATA_DIR+'el'+probe+ '/data_availability/'
      remote_path=!elf.REMOTE_DATA_DIR+'el'+probe+ '/data_availability/'
      
      ;figure out whether user wants stuff downloaded
      if !elf.NO_DOWNLOAD EQ 0 then udownload = 1 else udownload = 0
      if keyword_set(nodownload) then udownload = 0
            
      file_prefix = 'el'+probe+'_'+instrument+'_'
      
      sz_directions = ['nasc', 'ndes', 'sasc', 'sdes', 'eq']
      
      sz_start = []
      sz_end = []
      lshells = []
      mlt = []
      directions = []
  
        ;obtain file
     if update then begin
       tdate = trange[1]
       days = 1
       days = (time_double(trange[1])-time_double(trange[0]))/(86400)
       elf_update_data_availability_table, tdate, probe=probe, instrument='epd', days = days
     endif
        
     foreach element, sz_directions do begin
       
       if udownload then begin
        this_file = file_prefix+element+'.csv'
         paths = spd_download(remote_file=this_file, remote_path=remote_path, $
           local_file=this_file, local_path=local_path, ssl_verify_peer=1, $
           ssl_verify_host=1)
         if undefined(paths) or paths EQ '' then $
           dprint, devel=1, 'Unable to download ' + remote_file
       endif
       
       this_file = local_path+file_prefix+element+'.csv'
       if file_test(this_file) then begin
          
          szs = READ_CSV(this_file, N_TABLE_HEADER = 2)
          
          sz_start = [sz_start, szs.field1]
          sz_end = [sz_end, szs.field2]
          lshells = [lshells, szs.field3]
          mlt = [mlt, szs.field4]
          
          if element eq 'nasc' then direction = 'North Ascending' $
          else if element eq 'ndes' then direction = 'North Descending' $
          else if element eq 'sasc' then direction = 'South Ascending'$ 
          else if element eq 'sdes' then direction = 'South Descending'$
          else if element eq 'eq' then direction = 'Equatorial'
          
          directions = [directions, make_array(n_elements(mlt), /STRING, VALUE = direction)]
       endif
        
     endforeach
      
      sorted = sort(sz_start)
      sz_start = sz_start[sorted]
      sz_end = sz_end[sorted]
      lshells = lshells[sorted]
      mlt = mlt[sorted]
      directions = directions[sorted]
  
      write_csv, local_path+'el'+probe+'_'+instrument+'_all.csv', sz_start, sz_end, lshells, mlt, directions, TABLE_HEADER = 'EL-'+strupcase(probe)+' '+strupcase(instrument)+' Science Collections', HEADER = ['Time Start', 'Time End', 'L-Shell Range', 'MLT Median', 'Direction']
      print, 'Data written to: ', local_path + 'el'+probe+'_'+instrument+'_all.csv'
   endforeach
 endforeach
  
end