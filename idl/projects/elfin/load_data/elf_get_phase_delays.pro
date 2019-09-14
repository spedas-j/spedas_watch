function elf_get_phase_delays, no_download=no_download, trange=trange, probe=probe, instrument=instrument

  defsysv,'!elf',exists=exists
  if not keyword_set(exists) then elf_init

  if (~undefined(trange) && n_elements(trange) eq 2) && (time_double(trange[1]) lt time_double(trange[0])) then begin
    dprint, dlevel = 0, 'Error, endtime is before starttime; trange should be: [starttime, endtime]'
    return, -1
  endif

;  if ~undefined(trange) && n_elements(trange) eq 2 $
;    then tr = timerange(trange) $
;  else tr = timerange()

  if not keyword_set(probe) then probe = 'a'

  if ~undefined(instrument) then instrument='epde'
  instrument='epde'
  ; create calibration file name
  sc='el'+probe
  remote_cal_dir=!elf.REMOTE_DATA_DIR+sc+'/calibration_files'
  local_cal_dir=!elf.LOCAL_DATA_DIR+sc+'/calibration_files'
;  daily_name = file_dailynames(trange=tr, /unique, times=times)
  fname = sc+'epde_phase_delays.txt'
  if strlowcase(!version.os_family) eq 'windows' then local_cal_dir = strjoin(strsplit(local_cal_dir, '/', /extract), path_sep())

  remote_filename=remote_cal_dir+'/'+sc+'_'+instrument+'_phase_delays.txt'
  local_filename=local_cal_dir+'/'+sc+'_'+instrument+'_phase_delays.txt'
  paths = ''

  if keyword_set(no_download) then no_download=1

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
    ; read header
    readf, lun, le_string
    dtypes=strsplit(le_string, ',', /extract)
    
    while (eof(lun) NE 1) do begin  
      readf, lun, le_string
      data=strsplit(le_string, ',', /extract)
      append_array, starttimes, time_double(data[0])
      append_array, endtimes, time_double(data[1])
      append_array, tspin, float(data[2])
      append_array, dsect2add, fix(data[3])
      append_array, dphang2add, float(data[4])
      append_array, sectrconfig, float(data[5])
      append_array, phangconfig, float(data[6])
      append_array, latestmediansectr, fix(data[7])
      append_array, latestmedianphang, float(data[8])
      append_array, badflag, fix(data[9])
    endwhile

  endelse  

  phase_delay = { $
    start:starttimes, $
    endtimes:endtimes, $
    tspin:tpsin, $
    sect2add:dsect2add, $
    phang2add:dphang2add, $
    sectrconfig:sectrconfig, $
    phangconfig:phangconfig, $
    lastestmediansectr:latestmediansector, $
    latestmedianphang:latestmedianphang, $
    badflag:badflag }
    
  return, phase_delay
  
end