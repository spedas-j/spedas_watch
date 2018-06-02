;+
;Procedure:
;           ts07_download
;
;Purpose:
;           Downloads all parameter files
;
;           http://themis.ssl.berkeley.edu/data/themis/spedas/geopack/tailpar/
;           http://themis.ssl.berkeley.edu/data/themis/spedas/geopack/spdf/
;
;Keywords:
;          dir (optional): the directory where the files will be stored
;          year (optional): the year of
;
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-

pro ts07_local_dir_create, dir=dir
  ; Create local directory for parameter files
  if ~keyword_set(dir) then begin
    cdfdir = !spedas.temp_cdf_dir
    if cdfdir eq '' then begin
      spedas_init, reset=1
      dir = !spedas.temp_cdf_dir
    endif else begin
      dir = spd_string_replacen(cdfdir, 'cdaweb', 'geopack_par')
      if strmid(dir, 0,1, /reverse_offset) ne path_sep() then dir += path_sep()
      if ~STRMATCH(dir, '*geopack_par*' , /FOLD_CASE ) then dir = dir + 'geopack_par' + path_sep()
    endelse
  endif
  FILE_MKDIR, dir
  !spedas.geopack_param_dir = dir
  spedas_write_config
end

pro ts07_local_dir_check
  ; Check if local geopack parameters dir is defined
  ; if it is not, then define it
  spedas_init

  if !spedas.geopack_param_dir eq '' then begin
    print, 'Directory for Geopack parameters is not specified. It will be created.'
    ts07_local_dir_create
  endif

  result = FILE_TEST(!spedas.geopack_param_dir, /DIRECTORY)
  if result ne 1 then begin
    print, 'Directory for Geopack parameters does not exist. It will be created.'
    ts07_local_dir_create, dir = !spedas.geopack_param_dir
  endif

end

pro ts07_get_files, local_dir=local_dir, years=years
  ; Return a list of ts07 parameter filenames

  if ~keyword_set(local_dir) then local_dir=!spedas.geopack_param_dir

  ; 1. Download all files from
  ; http://themis.ssl.berkeley.edu/data/themis/spedas/geopack/tailpar/
  remote_data_dir = "http://themis.ssl.berkeley.edu/data/themis/spedas/geopack/tailpar/"
  relpathnames = "*"
  files = spd_download(remote_file=relpathnames, remote_path=remote_data_dir,local_path = local_dir)

  ; 2. Download year files from
  ; http://themis.ssl.berkeley.edu/data/themis/spedas/geopack/spdf/
  remote_data_dir = "http://themis.ssl.berkeley.edu/data/themis/spedas/geopack/spdf/"
  if ~keyword_set(years) then begin
    relpathnames = "*"
    files2 = spd_download(remote_file=relpathnames, remote_path=remote_data_dir,local_path = local_dir)
  endif else begin
    for i=0, n_elements(years)-1 do begin
      relpathnames = "*" + strtrim(years[i],2) + "*"
      files2 = spd_download(remote_file=relpathnames, remote_path=remote_data_dir,local_path = local_dir)
    endfor
  endelse

  all_files = [files, files2]
  print, "Files downloaded: ", all_files
  
end



pro ts07_download, local_dir=local_dir, years=years

  COMPILE_OPT IDL2, hidden
  
  if ts07_supported() eq 0 then return

  ; Check if local directory exists
  ts07_local_dir_check

  ; Get a list of parameter filenames
  ts07_get_files, local_dir=local_dir, years=years

end