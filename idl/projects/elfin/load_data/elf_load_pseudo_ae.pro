pro elf_load_pseudo_ae, no_download=no_download, trange=trange, probe=probe

  defsysv,'!elf',exists=exists
  if not keyword_set(exists) then elf_init

  if (~undefined(trange) && n_elements(trange) eq 2) && (time_double(trange[1]) lt time_double(trange[0])) then begin
    dprint, dlevel = 0, 'Error, endtime is before starttime; trange should be: [starttime, endtime]'
    return
  endif

  if ~undefined(trange) && n_elements(trange) eq 2 $
    then tr = timerange(trange) $
  else tr = timerange()

  if not keyword_set(probe) then probe = 'a'
  
  ; create calibration file name
  sc='el'+probe
  remote_ae_dir=!elf.REMOTE_DATA_DIR+'/pseudo_ae'
  local_ae_dir=!elf.LOCAL_DATA_DIR+'/pseudo_ae'
  daily_name = file_dailynames(trange=tr, /unique, times=times)
  fname = daily_name + '_ProxyAE.csv'
  if strlowcase(!version.os_family) eq 'windows' then local_ae_dir = strjoin(strsplit(local_ae_dir, '/', /extract), path_sep())

  remote_filename=remote_ae_dir+'/' + daily_name + '_ProxyAE.csv'
  local_filename=local_ae_dir+'/'+ daily_name + '_ProxyAE.csv'
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
    if file_test(local_ae_dir,/dir) eq 0 then file_mkdir2, local_ae_dir
    dprint, dlevel=1, 'Downloading ' + remote_filename + ' to ' + local_ae_dir
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
     return
  endif else begin
     pseudo_ae = read_csv(local_filename)
     t0=time_double(strmid(time_string(tr[0]),0,10))
     pseudo_ae_x = (pseudo_ae.field1 * 60.) + t0 
     pseudo_ae_y = double([pseudo_ae.field4])
     dl = {ytitle:'proxy_ae', labels:['proxy_AE'], colors:[2]}
     store_data, 'pseudo_ae', data={x:pseudo_ae_x, y:pseudo_ae_y}, dlimits=dl
  endelse

end