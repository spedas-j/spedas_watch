;+
;NAME:
;   icon_load_data
;
;PURPOSE:
;   Loads ICON data
;
;KEYWORDS:
;
;
;HISTORY:
;$LastChangedBy: nikos $
;$LastChangedDate: 2018-06-12 18:19:47 -0700 (Tue, 12 Jun 2018) $
;$LastChangedRevision: 25351 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/icon/load/icon_load_data.pro $
;
;-------------------------------------------------------------------

function icon_euv_filesnames, relpathnames,remote_path, trange, fversion=fversion, frevision=frevision
  ; Find the EUV file names scanning the directory
  ;http://themis.ssl.berkeley.edu/data/icon/Repository/Archive/LEVEL.1/EUV/2010/143/Data/ICON_L1_EUV_Flux_2010-05-23_235959_v01r000.NC
  files = []

  t = time_string(trange)
  td = time_double(t)
  remote_path=!icon.remote_data_dir

  all_url = []
  for i=0, n_elements(relpathnames)-1 do begin
    url = remote_path + relpathnames[i]
    spd_download_expand, url
    all_url = [all_url, url]
  endfor
  url = all_url[sort(all_url)]

  ; Find max for version and revision
  v_all = 0
  for j=0, n_elements(url)-1 do begin
    ss = strsplit(strsplit(strsplit(url[j],'.+[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{6}_v',/extract,/regex), '.NC', /extract), 'r', /extract)
    v_all = [v_all, ss[0]]
  endfor
  v_max = max(v_all)
  if keyword_set(fversion) then v_max = fversion
  v_str = strmid('00' + strtrim(string(v_max), 2), 1, 2,/reverse_offset)

  r_all = 0
  for j=0, n_elements(url)-1 do begin
    ss = strsplit(strsplit(url[j],'.+[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{6}_v' + v_str + 'r',/extract,/regex), '.NC', /extract)
    r_all = [r_all, ss[0]]
  endfor
  r_max = max(r_all)
  if keyword_set(frevision) then r_max = frevision
  r_str = strmid('000' + strtrim(string(r_max), 2), 2, 3,/reverse_offset)

  for j=0, n_elements(url)-1 do begin
    file0 = STRSPLIT(url[j], !icon.remote_data_dir,/EXTRACT,/regex)
    pre0 = STRSPLIT(file0[0],'ICON_L1_EUV_Flux_',/EXTRACT,/regex)
    s0= STRSPLIT(file0[0],'.*ICON_L1_EUV_Flux_',/EXTRACT,/REGEX)
    t0 =  STRSPLIT(s0[0],'_v.*NC',/EXTRACT,/REGEX)
    ts0 = strmid(t0[0], 0, 10) + '/' + strmid(t0[0], 11, 2) + ':' + strmid(t0[0], 13, 2) + ':' + strmid(t0[0], 15, 2)
    td0 = time_double(ts0)
    if (td0 ge td[0]) and (td0 le td[1]) then begin
      files=[files, pre0[0] + 'ICON_L1_EUV_Flux_' + t0 + '_v' + v_str + 'r' + r_str +'.NC']
    endif
  endfor

  n_download = n_elements(files)
  dprint, 'Number of files to download: ', n_download
  if n_download gt 100 then dprint, "Warning! More than 100 files will be downloaded. Consider decreasing the time range."
  dprint, files

  return, files
end

pro icon_load_data, trange = trange, instrument = instrument, datal1type = datal1type, datal2type = datal2type, suffix = suffix, $
  downloadonly = downloadonly, no_time_clip = no_time_clip, level = level, fversion=fversion, frevision=frevision, $
  tplotnames = tplotnames, varformat = varformat, get_support_data = get_support_data, noephem = noephem

  compile_opt idl2

  icon_init

  ; handle possible loading errors
  catch, errstats
  if errstats ne 0 then begin
    dprint, dlevel=1, 'Error in icon_load_data: ', !ERROR_STATE.MSG
    catch, /cancel
    return
  endif

  if undefined(suffix) then suffix = ''
  if keyword_set(fversion) then begin
    v_str = strmid('00' + strtrim(string(fversion), 2), 1, 2,/reverse_offset)
  endif else v_str ='??'
  if keyword_set(frevision) then begin
    r_str = strmid('000' + strtrim(string(frevision), 2), 2, 3,/reverse_offset)
  endif else r_str ='???'

  ; set the default datatype to FUV data
  if not keyword_set(instrument) then instrument = ['fuv']
  if not keyword_set(datal1type) then datal1type = ''
  if not keyword_set(datal2type) then datal2type = ''
  if not keyword_set(source) then source = !icon
  if (keyword_set(trange) && n_elements(trange) eq 2) $
    then tr = timerange(trange) $
  else tr = timerange()

  tn_list_before = tnames('*')
  pathformat = []


  if strlowcase(instrument) eq 'fuv' then begin
    if datal1type[0] eq '*' then datal1type=['lwp', 'sli', 'ssi', 'swp']
    if datal2type[0] eq '*' then datal2type=['Oxygen-Profile-Night', 'Daytime-ON2']
    if datal2type[0] eq 'O-daytime' then datal2type=['Daytime-ON2']
    if datal2type[0] eq 'O-nighttime' then datal2type=['Oxygen-Profile-Night']

    if datal1type[0] ne '' then begin
      level = '1'
      remote_path1 = 'LEVEL.' + level + '/' + strupcase(instrument) + '/YYYY/DOY/ICON_L' + level + '_' + strupcase(instrument) + '_' + strupcase(datal1type) + '_YYYY-MM-DD_v' + v_str + 'r' + r_str + '.NC'
      pathformat = [pathformat, remote_path1]
    endif
    if datal2type[0] ne '' then begin
      ;LEVEL.2/FUV/2010/146/ICON_L2_FUV_Oxygen-Profile-Night_2010-05-26_v01r000.NC
      level = '2'
      remote_path2 = 'LEVEL.' + level + '/' + strupcase(instrument) + '/YYYY/DOY/ICON_L' + level + '_' + strupcase(instrument) + '_' + datal2type + '_YYYY-MM-DD_v' + v_str + 'r' + r_str + '.NC'
      pathformat = [pathformat, remote_path2]
    endif

  endif else if strlowcase(instrument) eq 'ivm' then begin
    ; /LEVEL.1/IVM-A/2010/141/Data/ICON_L1_IVM-A_2010-05-21_v01r000.NC
    level = '1'
    instrument = 'IVM-A'
    if datal1type[0] ne '' then begin
      level = '1'
    endif
    if datal2type[0] ne '' then begin
      level = '2'
    endif
    remote_path = 'LEVEL.' + level + '/' + strupcase(instrument)  + '/YYYY/DOY/Data/ICON_L' + level + '_' + strupcase(instrument) + '_YYYY-MM-DD_v' + v_str + 'r' + r_str + '.NC'
    pathformat = [pathformat, remote_path]

  endif else if strlowcase(instrument) eq 'euv' then begin
    ;data/icon/Repository/Archive/Simulated-Data/LEVEL.1/EUV/2010/141/Data/ICON_L1_EUV_Flux_2010-05-21_000011_v01r000.NC
    level = '1'
    instrument = 'euv'
    datal1type = '*'
    datal2type = ''
    ;minutes = ['000010', '000022', '000034', '000046', '000058', '000110', '000122', '000134', '000146', '000158', '000210']
    minutes = '*'
    remote_path = 'LEVEL.' + level + '/' + strupcase(instrument)  + '/YYYY/DOY/Data/ICON_L' + level + '_' + strupcase(instrument) + '_Flux_YYYY-MM-DD_' + minutes +'_v' + v_str + 'r' + r_str + '.NC'
    pathformat = [pathformat, remote_path]
  endif else if strlowcase(instrument) eq 'inst3' then begin

  endif

  dprint,dlevel=2,verbose=source.verbose,'Loading ICON-', strupcase('level ' + string(level)), ' ', strupcase(instrument), ' ', strupcase(datal1type), ' data'

  if not keyword_set(pathformat) then begin
    dprint,'No data found. Try a different probe.'
    return
  endif

  for j = 0, n_elements(pathformat)-1 do begin
    relpathnames = file_dailynames(file_format=pathformat[j],trange=tr,addmaster=addmaster, /unique)

    if instrument eq 'euv' then begin
      ; For EUV with have to search and find the actual filenames
      relpathnames = icon_euv_filesnames(relpathnames, !icon.remote_data_dir, trange, fversion=fversion, frevision=frevision)
    endif

    files = spd_download(remote_file=relpathnames, remote_path=!icon.remote_data_dir, $
      local_path = !icon.local_data_dir, last_version=1)

    if keyword_set(downloadonly) then continue

    result = file_test(files[0], /read)
    if result then begin
      netcdf_struct = icon_netcdf_load_vars(files)
      cdf_struct = icon_struct_to_cdfstruct(netcdf_struct)
      cdf_info_to_tplot, cdf_struct, verbose = verbose, prefix=prefix, suffix=suffix
    endif

  endfor

  ; make sure some tplot variables were loaded
  tn_list_after = tnames('*')
  new_tnames = ssl_set_complement([tn_list_before], [tn_list_after])

  tplotnames = tnames('*')
  if ~undefined(tr) && ~undefined(tplotnames) then begin
    if (n_elements(tr) eq 2) and (tplotnames[0] ne '') then begin
      time_clip, tplotnames, tr[0], tr[1], replace=1, error=error
    endif
  endif

  ;For testing: 
  ;print, 'TPLOT variables: ', tnames()
end