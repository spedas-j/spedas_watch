function elf_get_epd_calibration_log, trange=trange, probe=probe, instrument=instrument, no_download=no_download

  defsysv,'!elf',exists=exists
  if not keyword_set(exists) then elf_init

  if (~undefined(trange) && n_elements(trange) eq 2) && (time_double(trange[1]) lt time_double(trange[0])) then begin
    dprint, dlevel = 0, 'Error, endtime is before starttime; trange should be: [starttime, endtime]'
    return, -1
  endif

  if ~undefined(trange) && n_elements(trange) eq 2 $
    then tr = timerange(trange) else tr = timerange()

  if not keyword_set(probe) then probe = 'a'
  if not keyword_set(instrument) then instrument='epde'
  
  ; create calibration file name
  sc='el'+probe
  remote_cal_dir=!elf.REMOTE_DATA_DIR+sc+'/calibration_files'
  local_cal_dir=!elf.LOCAL_DATA_DIR+sc+'/calibration_files'
  if strlowcase(!version.os_family) eq 'windows' then local_cal_dir = strjoin(strsplit(local_cal_dir, '/', /extract), path_sep())

  remote_filename=remote_cal_dir+'/'+sc+'_epd_calibration.log'
  local_filename=local_cal_dir+'/'+sc+'_epd_calibration.log'
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
      this_data=strsplit(le_string, ',', /extract)
      if time_double(tr[0]) LT time_double(this_data[0]) then begin
        this_data=prev_data
        break
      endif
      prev_data=this_data
    endwhile
    close, lun
    free_lun, lun
    
    if undefined(this_data) && undefined(prev_data) then begin
       dprint, 'No calibration data was found for: ' +trange[0] 
       return, -1
    endif else begin
      if instrument eq 'epde' then begin
        epd_cal_logs = {cal_date:time_double(this_data[0]), $
          probe:probe, $
          epd_thresh_factors:float(this_data[18:23]), $
          epd_ch_efficiencies:float(this_data[92:107]), $
          epd_ebins:float(this_data[58:73])}
      endif else begin   ; else instrument equals epdi
        epd_cal_logs = {cal_date:time_double(this_data[0]), $
          probe:probe, $
          epd_thresh_factors:float(this_data[24:25]), $
          epd_ch_efficiencies:float(this_data[108:123]), $
          epd_ebins:float(this_data[74:89])}
      endelse      
    endelse
 
  endelse

  if undefined(epd_cal_logs) then epd_cal_logs=-1

  return, epd_cal_logs

end