function elf_read_epd_cal_data, trange=trange, probe=probe, instrument=instrument, no_download=no_download

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

  remote_filename=remote_cal_dir+'/'+sc+'_'+instrument+'_cal_data.txt'
  local_filename=local_cal_dir+'/'+sc+'_'+instrument+'_cal_data.txt'
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

    ; open file and read first line (header)
    openr, lun, local_filename, /get_lun
    le_string=''
    count=0
    ; read header
    readf, lun, le_string
    ;extract the Date
    ; ignore blanks (if there are any)
    readf, lun, le_string
    if le_string EQ '' then readf, lun, le_string
    sidx=strpos(le_string,':')
    dtype=strlowcase(strmid(le_string,0,sidx))
    if dtype EQ 'date' then begin
      date=time_double(strmid(le_string, sidx+1))
      readf, lun, le_string
      sidx=strpos(le_string,':')
      gf=float(strmid(le_string, sidx+1))
      readf, lun, le_string
      sidx=strpos(le_string,':')
      overaccumulation_factors=float(strsplit(strmid(le_string, sidx+1), ',', /extract))
      readf, lun, le_string
      sidx=strpos(le_string,':')
      thresh_factors=float(strsplit(strmid(le_string, sidx+1), ',',/extract))
      readf, lun, le_string
      sidx=strpos(le_string,':')
      ch_efficiencies=float(strsplit(strmid(le_string, sidx+1), ',',/extract))
      readf, lun, le_string
      sidx=strpos(le_string,':')
      ebins=float(strsplit(strmid(le_string, sidx+1), ',',/extract))
    endif
    
    prev_date=date
    prev_gf=gf
    prev_overaccumulation_factors=overaccumulation_factors
    prev_thresh_factors=thresh_factors
    prev_ch_efficiencies=ch_efficiencies
    prev_ebins=ebins

    while (eof(lun) NE 1) do begin
      ; read
      readf, lun, le_string
      ;extract the type of data
      sidx=strpos(le_string,':')
      dtype=strlowcase(strmid(le_string,0,sidx))
      if dtype EQ 'date' then begin
        date=time_double(strmid(le_string, sidx+1))
        readf, lun, le_string
        sidx=strpos(le_string,':')
        gf=float(strmid(le_string, sidx+1))
        readf, lun, le_string
        sidx=strpos(le_string,':')
        overaccumulation_factors=float(strsplit(strmid(le_string, sidx+1), ',', /extract))
        readf, lun, le_string
        sidx=strpos(le_string,':')
        thresh_factors=float(strsplit(strmid(le_string, sidx+1), ',',/extract))
        readf, lun, le_string
        sidx=strpos(le_string,':')
        ch_efficiencies=float(strsplit(strmid(le_string, sidx+1), ',',/extract))
        readf, lun, le_string
        sidx=strpos(le_string,':')
        ebins=float(strsplit(strmid(le_string, sidx+1), ',',/extract))
      endif

      ; check to see if if input time is greater than file date
      if time_double(tr[0]) LT time_double(date) then begin
        date=prev_date
        gf=prev_gf
        overaccumulation_factors=prev_overaccumulation_factors
        thresh_factors=prev_thresh_factors
        ch_efficiencies=prev_ch_efficiencies
        ebins=prev_ebins
        break
      endif
      prev_date=date
      prev_gf=gf
      prev_overaccumulation_factors=overaccumulation_factors
      prev_thresh_factors=thresh_factors
      prev_ch_efficiencies=ch_efficiencies
      prev_ebins=ebins
    endwhile
    close, lun
    free_lun, lun
    
    if undefined(date) && undefined(prev_date) then begin
      dprint, 'No calibration data was found for: ' +trange[0]
      return, -1
    endif else begin
      if instrument eq 'epde' then begin
        epd_cal_logs = {date:date, $
          probe:probe, $
          gf:gf, $
          overaccumulation_factors:overaccumulation_factors, $
          thresh_factors:thresh_factors, $
          ch_efficiencies:ch_efficiencies, $
          ebins:ebins}
      endif else begin   ; else instrument equals epdi
        epd_cal_logs = {date:date, $
          probe:probe, $
          gf:gf, $
          overaccumulation_factors:overaccumulation_factors, $
          thresh_factors:thresh_factors, $
          ch_efficiencies:ch_efficiencies, $
          ebins:ebins}
      endelse
    endelse

  endelse

  if undefined(epd_cal_logs) then epd_cal_logs=-1

  return, epd_cal_logs

end