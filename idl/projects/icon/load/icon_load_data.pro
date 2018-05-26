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
;$LastChangedDate: 2018-05-25 12:50:52 -0700 (Fri, 25 May 2018) $
;$LastChangedRevision: 25272 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/icon/load/icon_load_data.pro $
;
;-------------------------------------------------------------------

pro icon_load_data, trange = trange, instrument = instrument, datal1type = datal1type, datal2type = datal2type, suffix = suffix, $
  downloadonly = downloadonly, no_time_clip = no_time_clip, level = level, $
  tplotnames = tplotnames, varformat = varformat, get_support_data = get_support_data, noephem = noephem

  compile_opt idl2

  icon_init

  if undefined(suffix) then suffix = ''

  ; handle possible loading errors
  catch, errstats
  if errstats ne 0 then begin
    dprint, dlevel=1, 'Error in icon_load_data: ', !ERROR_STATE.MSG
    catch, /cancel
    return
  endif

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
      remote_path1 = 'LEVEL.' + level + '/' + strupcase(instrument) + '/YYYY/DOY/ICON_L' + level + '_' + strupcase(instrument) + '_' + strupcase(datal1type) + '_YYYY-MM-DD_v0?r0??.NC'
      pathformat = [pathformat, remote_path1]
    endif
    if datal2type[0] ne '' then begin
      ;LEVEL.2/FUV/2010/146/ICON_L2_FUV_Oxygen-Profile-Night_2010-05-26_v01r000.NC
      level = '2'
      remote_path2 = 'LEVEL.' + level + '/' + strupcase(instrument) + '/YYYY/DOY/ICON_L' + level + '_' + strupcase(instrument) + '_' + datal2type + '_YYYY-MM-DD_v0?r0??.NC'
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
    remote_path = 'LEVEL.' + level + '/' + strupcase(instrument)  + '/YYYY/DOY/Data/ICON_L' + level + '_' + strupcase(instrument) + '_YYYY-MM-DD_v0?r0??.NC'
    pathformat = [pathformat, remote_path]

  endif else if strlowcase(instrument) eq 'inst2' then begin

  endif else if strlowcase(instrument) eq 'inst3' then begin

  endif


  ; http://themis.ssl.berkeley.edu/data/icon/Repository/Archive/LEVEL.1/FUV/2017/149/ICON_L1_FUV_SSI_2017-05-29_v01r000.NC
  ; http://themis.ssl.berkeley.edu/data/icon/Repository/Archive/LEVEL.1/FUV/2010/140/ICON_L1_FUV_LWP_2010-05-20_v01r000.NC
  ; doy 115, 2017-04-25

  dprint,dlevel=2,verbose=source.verbose,'Loading ICON-', strupcase('level ' + string(level)), ' ', strupcase(instrument), ' ', strupcase(datal1type), ' data'

  if not keyword_set(pathformat) then begin
    dprint,'No data found. Try a different probe.'
    return
  endif

  for j = 0, n_elements(pathformat)-1 do begin
    relpathnames = file_dailynames(file_format=pathformat[j],trange=tr,addmaster=addmaster, /unique)

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

  ; load the ephemeris data in GEI coordinates
  ;if undefined(noephem) && new_tnames[0] ne -1 then begin

  ;endif

  tplotnames = tnames('*')
  if ~undefined(tr) && ~undefined(tplotnames) then begin
    if (n_elements(tr) eq 2) and (tplotnames[0] ne '') then begin
      time_clip, tplotnames, tr[0], tr[1], replace=1, error=error
    endif
  endif

  ;For testing:
  print, 'TPLOT variables: '
  tplot_names
end