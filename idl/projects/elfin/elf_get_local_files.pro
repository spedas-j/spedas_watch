;+
;Procedure:
;  elf_get_local_files
;
;Purpose:
;  Search for local ELFIN files in case a list cannot be retrieved from the
;  remote server.  Returns a sorted list of file paths.
;
;Calling Sequence:
;
;  files = elf_get_local_file_info( probe=probe, instrument=instrument, $
;            data_rate=data_rate, level=level, datatype=datatype, trange=trange)
;
;Input:
;  probe:  (string) Full spacecraft designation, e.g. 'ela'
;  instrument:  (string) Instrument designation, e.g. 'fgm'
;  data_rate:  (string) Data collection mode?  e.g. 'srvy'
;  level:  (string) Data processing level, e.g. 'l1'
;  trange:  (string/double) Two element time range, e.g. ['2015-06-22','2015-06-23']
;  datatype:  (string) Optional datatype specification, e.g. 'pos'
;
;Output:
;  return value:  Sorted string array of file paths, if successful; 0 otherwise
;
;Notes:
;  -Input strings should not contain wildcards (datatype may be '*')
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2018-04-09 12:14:36 -0700 (Mon, 09 Apr 2018) $
;$LastChangedRevision: 25023 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/elf/common/elf_get_local_files.pro $
;-

function elf_get_local_files, probe = probe, instrument = instrument, data_rate = data_rate, $
  level = level, datatype = datatype, trange = trange_in, cdf_version = cdf_version, $
  latest_version = latest_version, min_version = min_version, mirror = mirror

  compile_opt idl2, hidden

  ;return value in case of error
  error = 0

  ;verify all inputs are present
  if undefined(probe) || $
    undefined(instrument) || $
    undefined(data_rate) || $
    undefined(level) || $
    undefined(trange_in) then begin
    dprint, dlevel=0, 'Missing required input to search for local files'
    return, error
  endif

  trange = time_double(trange_in)

  ;----------------------------------------------------------------
  ;Get list of files by probe and type of data
  ;----------------------------------------------------------------

  ;path & filename separators
  s = path_sep()
  f = '_'

  ;inputs common to all file paths and folder names
  basic_inputs = [probe, level, instrument]

;  if undefined(datatype) || datatype eq '*' then begin
;    dir_datatype = '[^'+s+']+'
;    file_datatype = '[^'+f+']+'
;  endif else begin
;    dir_datatype = datatype
;    file_datatype = datatype
;  endelse
;stop
  ;directory and file name search patterns
  ;  -assume directories are of the form:
  ;     /spacecraft/level/instrument/
  ;  -assume file names are of the form:
  ;     spacecraft_level_instrument_YYYYMMDD_version.cdf
  dir_pattern = strjoin(basic_inputs, s) + s   ; + '('+s+dir_datatype+')?' +s+ '[0-9]{4}' +s+ '[0-9]{2}' + s
  file_pattern = strjoin( basic_inputs, f) + f + '([0-9]{8})' 

  ;escape backslash in case of Windows
  ;search_pattern =  dir_pattern + file_pattern 
  search_pattern = escape_string(dir_pattern  + file_pattern, list='\')
  ;get list of all .cdf files in local directory
  instr_data_dir = filepath('', ROOT_DIR=!elf.local_data_dir, $
      SUBDIRECTORY=[probe, level, instrument])
  files = file_search(instr_data_dir,'*.cdf')

  ;perform search
;  filedate = dir_pattern + strjoin( basic_inputs, f) + f + time_string(trange_in[0], format=6, precision=-3) + '_v01.cdf' 
;  idx = where(all_files EQ filedate, n_files) 
;  ;idx = where( stregex( all_files, search_pattern, /bool, /fold_case), n_files)
;  idx = where( stregex( all_files, file_pattern, /bool, /fold_case), n_files);

;  if n_files eq 0 then begin
;    ; suppress redundant error message
;    ; dprint, dlevel=2, 'No local files found for: '+strjoin(basic_inputs,' ') + ' ' +$
;    ;                   (undefined(datatype) ? '':datatype)
;    return, error
;  endif

;  files = all_files

  ;----------------------------------------------------------------
  ;Restrict list to files within the time range
  ;----------------------------------------------------------------

  ;extract file info from file names
  ;  [file name sans version, data type, time]
  file_strings = stregex( files, file_pattern, /subexpr, /extract, /fold_case)

  ;get file start times
  time_strings = file_strings[1,*]
  times = time_double(time_strings, tformat=tformat)
  time_idx = where( times ge trange[0] and times lt trange[1], n_times)

  if n_times eq 0 then begin
    ; suppress redundant error message
    ;dprint, dlevel=2, 'No local files found between '+time_string(trange[0])+' and '+time_string(trange[1])
    return, error
  endif

  ;restrict list of files to those in the time range
  files = files[time_idx]
  file_strings = file_strings[*,time_idx]
  ;ensure files are in chronological order, just in case (see note in elf_load_data)
  files_out = files[bsort(files)]

  return, files_out

end
