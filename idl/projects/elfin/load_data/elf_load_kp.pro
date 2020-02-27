;+
; PROCEDURE:
;         elf_load_kp
;
; PURPOSE:
;         Load data from a csv file downloaded from a csv file stored on the 
;         elfin server. 
;         The original data was downloaded from the ftp site:
;            ftp://ftp.gfz-potsdam.de/pub/home/obs/kp-nowcast-archive/wdc/
;            
;
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         no_download:  set this flag to search for the file on your local disk 
;         day:          set this flag to return an array of values for the day
;
;-
pro elf_load_kp, no_download=no_download, trange=trange, day=day

  defsysv,'!elf',exists=exists
  if not keyword_set(exists) then elf_init

  if (~undefined(trange) && n_elements(trange) eq 2) && (time_double(trange[1]) lt time_double(trange[0])) then begin
     dprint, dlevel = 0, 'Error, endtime is before starttime; trange should be: [starttime, endtime]'
  endif

  if ~undefined(trange) && n_elements(trange) eq 2 then tr = timerange(trange) else tr = timerange()

  ; create file name
;  ts=time_string(tr[0])
  kp_filename='elfin_kp.csv'
  remote_kp_dir=!elf.REMOTE_DATA_DIR+'/kp'
  local_kp_dir=!elf.LOCAL_DATA_DIR+'/kp'
  if strlowcase(!version.os_family) eq 'windows' then local_kp_dir = strjoin(strsplit(local_kp_dir, '/', /extract), path_sep())

  remote_filename=remote_kp_dir+'/'+kp_filename
  local_filename=local_kp_dir+'/'+kp_filename
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
    if file_test(local_kp_dir,/dir) eq 0 then file_mkdir2, local_kp_dir
    dprint, dlevel=1, 'Downloading ' + remote_filename + ' to ' + local_kp_dir
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
      return
    endif 
  endif

  kp_values = read_csv(local_filename)
  td=time_double(kp_values.field1)

  if ~keyword_set(day) then begin
    ; find closest point to midpoint of this timerange 
    tmid=tr[0]+(tr[1]-tr[0])/2.
    tdiff=abs(td-tmid)
    tclose=min(tdiff,tcidx)
    kp_value=round(kp_values.field3[tcidx])
    kp_time=td[tcidx]
    ; check range if not between 0 and 8 then default to 2
    if kp_value LT 0 or kp_value GT 8 then begin
      kp_value=2
      dprint, devel=1, 'Kp value was out of range. Defaulting to 2."
    endif
  endif else begin
    ; return all points for this day
    idx = where(td GE tr[0]-10800. AND td LE tr[1]+10800., ncnt)
    if ncnt GT 1 then begin
      kp_value=round(kp_values.field3[idx])
      kp_time=td[idx]
    endif
  endelse
   
  if ~undefined(kp_time) && ~undefined(kp_value) then begin
    dt=2700.    ; kp values are every 3 hours dt/2 is 45 min
    kp={x:kp_time-dt, y:kp_value} 
    store_data, 'kp', data=kp
    options, 'kp', colors=251
    options, 'kp', psym=10
    options, 'kp', yrange=[-1,9]
    options, 'kp', ystyle=1
  endif else begin
     dprint, dlevel=1, 'No KP data was loaded!'
  endelse 

end