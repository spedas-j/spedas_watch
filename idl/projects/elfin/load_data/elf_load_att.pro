;+
; FUNCTION:
;         elf_load_att
;
; PURPOSE:
;         Load data from a csv file on the elfin server.
;         The attitude data is a by-product of the attitude
;         determination software.
;
;
; KEYWORDS:
;         probe:        specify which ELFIN probe to load 'a' or 'b'
;         tdate:        time and date of interest with the format
;                       'YYYY-MM-DD/hh:mm:ss'
;         no_download:  set this flag to search for the file on your local disk
;
;-
function elf_load_att, probe=probe, tdate=tdate, no_download=no_download

  defsysv,'!elf',exists=exists
  if not keyword_set(exists) then elf_init

  if undefined(tdate) then begin
    dprint, 'You must enter a date (e.g. 2020-02-24/03:45:00)'
    return, -1 
  endif else begin
    tdate=time_double(tdate)
  endelse

  if undefined(probe) then probe = 'a' else probe = strlowcase(probe)

  ; create file name
  att_filename='el'+probe+'_attitudes.csv'
  remote_att_dir=!elf.REMOTE_DATA_DIR+'/attitude'
  local_att_dir=!elf.LOCAL_DATA_DIR+'/attitude'
  if strlowcase(!version.os_family) eq 'windows' then local_att_dir = strjoin(strsplit(local_att_dir, '/', /extract), path_sep())

  remote_filename=remote_att_dir+'/'+att_filename
  local_filename=local_att_dir+'/'+att_filename
  paths = ''

  if keyword_set(no_download) then no_download=1 else no_download=0

  paths = ''
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
    if file_test(local_att_dir,/dir) eq 0 then file_mkdir2, local_att_dir
    dprint, dlevel=1, 'Downloading ' + remote_filename + ' to ' + local_att_dir
    paths = spd_download(remote_file=remote_filename, local_file=local_filename, $
      url_username=user, url_password=pw, ssl_verify_peer=1, ssl_verify_host=1)
    if undefined(paths) or paths EQ '' then $
      dprint, devel=1, 'Unable to download ' + local_filename
  endif

  ; if file not found on server then
  if paths[0] EQ '' || no_download EQ 1 then begin
    ; check that there is a local file
    if file_test(local_filename) NE 1 then begin
      dprint, dlevel=1, 'Unable to find local file ' + local_filename
      return, -1
    endif
  endif

  ; check that the file exists
  if file_test(local_filename) NE 1 then begin
    dprint, dlevel=1, 'Unable to find file '+ local_filename
    return, -1
  endif
  att_fields = read_csv(local_filename)
  td=time_double(att_fields.field1)
  rpm=att_fields.field6
    
  ; interpolate data
  ; find start and end points for interpolation
  npts=n_elements(att_fields.field1)
  if td[npts-1] GT tdate then edate=td[npts-1] else edate=tdate+3600.
  if td[0] LT tdate then sdate=td[0] else sdate=tdate-3600.
  ; create time for interpolation
  num_min=fix((edate-sdate)/86400.)*1440.
  ntime=(findgen(num_min)*60)+sdate
  int_rpm=interp(rpm, td, ntime)
  tdiff=min(abs(ntime-tdate),midx)
  
  return, int_rpm[midx]

end