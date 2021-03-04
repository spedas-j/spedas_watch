;+
; PROCEDURE:
;         elf_get_phase_delay
;
; PURPOSE:
;         This routine will download and retrieve the phase delay values for a given
;         time range. All values in the file are returned in a structure of arrays.
;         phase_delay = { $
;            starttimes:starttimes, $
;              endtimes:endtimes, $
;              tspin:tspin, $
;              sect2add:dsect2add, $
;              phang2add:dphang2add, $
;              ticksconfig:ticksconfig, $
;              lastestmediansectr:latestmediansectr, $
;              latestmedianphang:latestmedianphang, $
;              chisq:chisq, $
;              attunc:attunc, $
;              badflag:badflag, $
;              HQflag:HQflag, $
;              minpa:minpa }
;
;
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         probe:        'a' or 'b'
;         no_download:  set this flag to search for the file on your local disk
;         hourly:       set this flag to find the nearest science zone within an hour of the
;                       trange
;
;-
function elf_get_phase_delays, no_download=no_download, trange=trange, probe=probe, instrument=instrument

  defsysv,'!elf',exists=exists
  if not keyword_set(exists) then elf_init

;  if (~undefined(trange) && n_elements(trange) eq 2) && (time_double(trange[1]) lt time_double(trange[0])) then begin
;    dprint, dlevel = 0, 'Error, endtime is before starttime; trange should be: [starttime, endtime]'
;    return, -1
;  endif

;  if ~undefined(trange) && n_elements(trange) eq 2 $
;    then tr = timerange(trange) $
;  else tr = timerange()

  if not keyword_set(probe) then probe = 'a'

  if ~undefined(instrument) then instrument='epde'
  instrument='epde'
  
  ; check for existing phase_delays tplot var
  get_data, 'el'+probe+'_epd_phase_delays', data=pd_struct
  if is_struct(pd_struct) then begin
    phase_delays=pd_struct.phase_delays[0]
    return, phase_delays
  endif
  
  ; create calibration file name
  sc='el'+probe
  remote_cal_dir=!elf.REMOTE_DATA_DIR+sc+'/calibration_files'
  local_cal_dir=!elf.LOCAL_DATA_DIR+sc+'/calibration_files'
  if strlowcase(!version.os_family) eq 'windows' then local_cal_dir = strjoin(strsplit(local_cal_dir, '/', /extract), path_sep())

  remote_filename=remote_cal_dir+'/'+sc+'_'+instrument+'_phase_delays.txt'
  local_filename=local_cal_dir+'/'+sc+'_'+instrument+'_phase_delays.txt'
  paths = ''

  if keyword_set(no_download) then no_download=1 else no_download=0

  if no_download eq 0 then begin
    ; NOTE: directory is temporarily password protected. this will be
    ;       removed when data is made public.
    if undefined(user) OR undefined(pw) then authorization = elf_get_authorization()
    user=authorization.user_name
    pw=authorization.password
    ; only query user if authorization file not found
    If user EQ '' OR pw EQ '' then begin
      print, 'Please enter your ELFIN user name and password'
      read,user,prompt='User Name: '
      read,pw,prompt='Password: '
    endif
    if file_test(local_cal_dir,/dir) eq 0 then file_mkdir2, local_cal_dir
    dprint, dlevel=1, 'Downloading ' + remote_filename + ' to ' + local_cal_dir
    paths = spd_download(remote_file=remote_filename, $   ;remote_path=remote_cal_dir, $
      local_file=local_filename, $   ;local_path=local_cal_dir, $
      url_username=user, url_password=pw, ssl_verify_peer=1, $
      ssl_verify_host=1)
    if undefined(paths) or paths EQ '' then $
      dprint, devel=1, 'Unable to download ' + local_filename
  endif
  ; check that there is a local file
  if file_test(local_filename) NE 1 then begin
    dprint, dlevel=1, 'Unable to find local file ' + local_filename
    return, -1
  endif else begin  
    ; open file and read first 7 lines (these are just headers)
    openr, lun, local_filename, /get_lun
    le_string=''    
    count=0  
    ; read header
    readf, lun, le_string
    dtypes=strsplit(le_string, ',', /extract) 
    while (eof(lun) NE 1) do begin  
      readf, lun, le_string
      if le_string eq '' then continue
      data=strsplit(le_string, ',', /extract)
      append_array, starttimes, time_double(data[0])
      append_array, endtimes, time_double(data[1])
      append_array, tspin, data[2]
      this_bflag=fix(data[10])
      idxn=strpos(data[3],'NaN')
      if idxn NE -1 then thisdsect=!values.f_nan else thisdsect=fix(data[3])
;      if data[3] EQ ' NaN' then thisdsect=!values.f_nan else thisdsect=fix(data[3])
      append_array, dsect2add, thisdsect
      idxn=strpos(data[4],'NaN')
      if idxn NE -1 then thisdph=!values.f_nan else thisdph=float(data[4])
      append_array, dphang2add, thisdph
      append_array, ticksconfig, float(data[5])
      idxn=strpos(data[6],'NaN')
      if idxn GE 0 then begin
        thislms=fix(data[6])
      endif else begin
        if this_bflag then thislms=thisdsect else thislms=!values.f_nan
      endelse
      append_array, latestmediansectr, thislms
      idxn=strpos(data[7],'NaN')
      if idxn GE 0 then begin
        thislmpa=float(data[7])
      endif else begin
        if this_bflag then thislmpa=thisdph else thislmpa=!values.f_nan 
      endelse
      append_array, latestmedianphang, thislmpa
      append_array, chisq, float(data[8])
      append_array, attunc, float(data[9])
      append_array, badflag, fix(data[10])
      append_array, HQflag, fix(data[11])
      append_array, minpa, float(data[12])
      count=count+1
    endwhile
    close, lun
    free_lun, lun
  endelse  
  
  phase_delay = { $
    starttimes:starttimes, $
    endtimes:endtimes, $
    tspin:tspin, $
    sect2add:dsect2add, $
    phang2add:dphang2add, $
    ticksconfig:ticksconfig, $
    lastestmediansectr:latestmediansectr, $
    latestmedianphang:latestmedianphang, $
    chisq:chisq, $
    attunc:attunc, $
    badflag:badflag, $
    HQflag:HQflag, $
    minpa:minpa }

   store_data, 'el'+probe+'_epd_phase_delays', data={phase_delays:phase_delay}
   
  return, phase_delay
  
end