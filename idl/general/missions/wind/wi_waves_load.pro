;+
;
; Procedure: wi_waves_load
;
; Purpose:   Loads Wind WAVES data from CDF files available at SPDF.
;
; Keywords:
;   TRANGE   : Time range of interest
;   /VERBOSE : Set to output some useful info
;
;Example:
;
;   Load Level 2 RAD1 and RAD2 files:
;
;     IDL> wi_waves_load
;
;   Load Level 3 direction finding data:
;
;     IDL> wi_waves_load, 'rad1_l3_df'
;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2023-12-15 15:08:41 -0800 (Fri, 15 Dec 2023) $
; $LastChangedRevision: 32291 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/wind/wi_waves_load.pro $
;
;-

pro wi_waves_load, type, files = files, trange = trange, $
  verbose = verbose, level = level, prefix = prefix, $
  source_options = source_options, $
  version = ver
  compile_opt idl2

  if not keyword_set(source_options) then begin
    istp_init
    source_options = !istp
    source_options.min_age_limit = 3600
  endif

  if not keyword_set(level) then level = 2

  level_str = 'l' + string(level, format = '(I1)')

  if not keyword_set(type) then begin
    if level eq 2 then begin
      wi_waves_load, 'rad2', files = files, trange = trange, $
        verbose = verbose, level = level, prefix = prefix, $
        source_options = source_options, $
        version = ver
      wi_waves_load, 'rad1', files = files, trange = trange, $
        verbose = verbose, level = level, prefix = prefix, $
        source_options = source_options, $
        version = ver
      return
    endif else if level eq 3 then begin
      if n_elements(type) eq 0 then type = 'rad1_l3_df'
      wi_waves_load, type, files = files, trange = trange, $
        verbose = verbose, level = level, prefix = prefix, $
        source_options = source_options, $
        version = ver
      return
    endif else begin
      type = '_avg'
    endelse
  endif

  if not keyword_set(prefix) then begin
    prefix_unset = 1
    if level eq 2 then begin
      prefix = 'wi_' + level_str + '_wav_' + type + '_'
    endif else if level eq 3 then begin
      prefix = 'wi_wa_' + type + '_
    endif
  endif else begin
    prefix_unset = 0
  endelse

  res = 3600l * 24 ; one day resolution in the files
  tr = floor(timerange(trange) / res) * res
  n = ceil((tr[1] - tr[0]) / res) > 1
  dates = dindgen(n) * res + tr[0]

  path = 'wind/waves/' + type + '_' + level_str + $
    '/YYYY/wi_' + level_str + '_wav_' + type + '_YYYYMMDD_v??.cdf'

  if level eq 3 then begin
    if type eq 'dust_impact_l3' then $
      path = 'wind/waves/' + type + $
        '/YYYY/wi_l3-dustimpact_waves_YYYYMMDD_v???.cdf' else $
      path = 'wind/waves/' + type + $
        '/YYYY/wi_wa_' + type + '_YYYYMMDD_v??.cdf'
  endif

  relpathnames = time_string(dates, tformat = path)

  files = spd_download(remote_file = relpathnames, _extra = source_options)

  cdf2tplot, files, prefix = prefix

  if level eq 2 then begin
    options, prefix + ['PSD*'], 'ystyle', 1
    options, prefix + ['PSD*'], 'ztitle', '[V^2/Hz]'
    options, prefix + ['PSD*'], 'ysubtitle', '[Hz]'

    foreach tname, tnames(prefix + 'PSD*') do begin
      options, tname, 'ytitle', $
        'Wind' + '!C' + strupcase(strmid(tname, 10, 4)) + ' ' + $
        strmid(tname, 22)
    endforeach
  endif else begin

  endelse

  if prefix_unset then prefix = !null

  if type eq 'rad1_l3_df' then begin
    options, 'wi_wa_rad1_l3_df_STOKES_I', 'ylog', 1
    options, 'wi_wa_rad1_l3_df_WAVE_COLATITUDE_SRF', 'yrange', [0, 180]
    options, 'wi_wa_rad1_l3_df_WAVE_AZIMUTH_SRF', 'yrange', [-90, 90]
    options, 'wi_wa_rad1_l3_df_SOURCE_SIZE', 'yrange', [0, 90]
    options, 'wi_wa_rad1_l3_df_QUALITY_FLAG', 'yrange', [-0.5, 4.5]
    options, 'wi_wa_rad1_l3_df*', 'ystyle', 1
    options, 'wi_wa_rad1_l3_df*', 'psym', 3
  endif
end