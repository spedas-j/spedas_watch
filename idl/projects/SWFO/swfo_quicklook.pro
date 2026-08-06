
; Does string replace on an array of strings,
; since that operation is not supported on a strarr:

function replace_substring_arr, arr, pattern, replacement
  n_arr = n_elements(arr)
  new_arr = strarr(n_arr)
  for i=0, n_arr - 1 do begin
    arr_i = arr[i]
    new_arr[i] = arr_i.replace(pattern, replacement)
  endfor
  return, new_arr
end

; Converts a descriptive string (e.g. '5 days'
; or '3 minutes') into a number of seconds.
; Intended for converting userfriendly
; strings into something that can be added/subtracted
; from Unix time objects.

function duration_str2dbl, duration_string

  ; Recursion for multiple strings:
  if n_elements(duration_string) ne 1 then begin
    durarr = dblarr(n_elements(duration_string)) 
    foreach durstrng_i, duration_string, i do begin
      durdble_i = duration_str2dbl(durstrng_i)
      durarr[i] = durdble_i
    endforeach
    return, durarr

  endif

  ; All lower case the string:
  ds = duration_string.tolower()

  ; First, check if seconds:
  has_seconds = ds.contains('s')
  if has_seconds then begin
    duration_s = (ds.split('s'))[0].trim()
    duration_s = double(duration_s)
  endif

  ; Next, check if minutes:
  has_min = ds.contains('m')
  if has_min then begin
    duration_min = (ds.split('m'))[0].trim()
    duration_s = 60d*double(duration_min)
  endif

  ; Next, hours:
  has_hr = ds.contains('h')
  if has_hr then begin
    duration_hr = (ds.split('h'))[0].trim()
    duration_s = 3600d*double(duration_hr)
  endif

  ; Next, hours:
  has_days = ds.contains('d')
  if has_days then begin
    duration_days = (ds.split('d'))[0].trim()
    duration_s = 3600d*24*double(duration_days)
  endif

  return, duration_s

end

; Function to produce start/end unix time arrays
; that end every X days and begin every Y days

pro plot_intervals, trange, end_cadence, durations, start_time, end_time

  ; Construct intervals to load and plot data over:
  cadence_s = duration_str2dbl(end_cadence)
  durations_s = duration_str2dbl(durations)
  n_durations = n_elements(durations)

  ; Create a list of days of days to end each plot on:
  tints = floor(time_double(trange)/cadence_s)
  ; print, tints
  ; print, time_string(tints*cadence_s)
  n_intervals = tints[1] - tints[0]

  ; empty arrays to fill:
  start_time = dblarr(n_intervals, n_durations)
  ; end_time = dblarr(n_intervals, n_durations)
  end_time = dblarr(n_intervals)

  for i= 0, n_intervals - 1 do begin
    tr = (tints[0] + i +[0,1]) *cadence_s

    ; Now make the plot duration times:
    for j=0, n_durations - 1 do begin
      new_tr = [tr[1] - durations_s[j], tr[1]]
      ; plot_tranges[i].add, new_tr
      start_time[i, j] = new_tr[0]
      ; end_time[i, j] = tr[1]
      ; stop
    endfor
    end_time[i] = tr[1]
    ; print, time_String(tr)
  endfor
  ; print, time_string(start_time)
  ; print, time_string(end_time)
  return
end


pro swfo_quicklook, trange=trange, plot_cadence=plot_cadence

  ; timespan, '2026 1 19', 2
  ; timespan, '2026 6 23', 1
  ; loadct2, 33

  plot_types = ['health', 'summ', 'ace', 'noise']

  ; Information on directory to write file to:
  ; destination_dir = '/Users/rjolitz/Desktop/test_dir'
  destination_dir = root_data_dir()

  if ~destination_dir.endswith('/') then destination_dir = destination_dir + '/'

  destination_fname = destination_dir +$
    'swfo/data/plots/{PLOTNAME}/YYYY/MM/swfo_ql_{PLOTNAME}_{PLOTDURATION}_{CADENCE}_YYYYMMDD'

  if ~keyword_set(trange) then trange =   timerange(trange)   ; time_double(['2025 9 24','now'])
  trange = time_double(trange)

  if trange[0] lt time_double('2025-09-30') then begin
    dprint, 'Date too early: '+time_string(trange)
    return
  endif

  ; Output plot types:
  if ~keyword_set(plot_cadence) then plot_cadence = '1d'  ; frequency of plots (e.g. 1d - every day, 3d, every 3 days)
  n_plot_types = n_elements(plot_types)
  ace_in_plot_types = where(plot_types eq 'ace', load_ace)

  swfo_types = ['stis_l0b', 'stis_l1a', 'stis_l1b']


  data_resolution = ['fr', '30s', '300s']
  data_resolution = ['fr']
  data_resolution_label = ['', '30-sec ', '5-min ']

  plot_durations = ['7d', '3d', '1d']  ; Order in descending
  ; plot_durations = ['3d', '7d']
  plot_durations = ['1d']

  ; Set up plot intervals that end every 1-3d 
  ; (depending on plot_cadence) and start every 1-7d before
  ; that end.
  plot_intervals, trange, plot_cadence, plot_durations, start_time_unix, end_time_unix
  n_intervals = n_elements(end_time_unix)
  n_durations = n_elements(plot_durations)

  ; print, time_String(start_time_unix[0, *])
  ; print, time_String(end_time_unix[0])

  ; Variables for plots:
  ; - Health:
  hkp_var = ['FPGA_REV', 'VOLTAGE_1P5_VD',$
             'VOLTAGE_3P3_VD', 'VOLTAGE_5P0_VD', 'VOLTAGE_DFE_POS_VA',$
             'VOLTAGE_DFE_NEG_VA', 'BIAS_CURRENT_MICROAMPS', 'ADC_BIAS_VOLTAGE',$
             'TEMP_DAP', 'TEMP_SENSOR1', 'TEMP_SENSOR2']
  tplot_hkp_var = 'swfo_stis_l0b_{}_' + hkp_var

  ; set nominal ranges
  hkp_nominal = dictionary()
  hkp_nominal["ADC_BIAS_VOLTAGE"] = [-40, -32]
  hkp_nominal["TEMP_DAP"] = [-40, 55]
  hkp_nominal["VOLTAGE_1P5_VD"] = [1.4, 1.6]
  hkp_nominal["VOLTAGE_3P3_VD"] = [3.1, 3.5]
  hkp_nominal["VOLTAGE_5P0_VD"] = [4.5, 5.5]
  hkp_nominal["VOLTAGE_DFE_POS_VA"] = [4.5, 6.5]
  hkp_nominal["VOLTAGE_DFE_NEG_VA"] = [-6.5, -4.5]
  hkp_nominal["BIAS_CURRENT_MICROAMPS"] = [3, 4] ; [-4, -3]
  hkp_nominal["TEMP_SENSOR1"] = [-55, 50]
  hkp_nominal["TEMP_SENSOR2"] = [-55, 50]
  hkp_nominal["FPGA_REV"] = [208, 210]

  ; - Summary:
  summ_var = ['swfo_stis_l0b_{}_HKP_GAP', 'swfo_stis_l0b_{}_SCI_GAP', 'swfo_stis_l0b_{}_NSE_GAP',$
              'swfo_stis_l1b_{}_HDR_ION_EFLUX', 'swfo_stis_l1b_{}_HDR_ELEC_EFLUX',$
              'swfo_stis_l1a_{}_NOISE_SIGMA', 'swfo_stis_l0b_{}_VALID_RATES']
  ; - ACE compare:
  ace_var = ['stis_l2_{}_ION_FLUX', 'stis_l2_{}_ELEC_FLUX',$
             'ace_rtsw_epam_proton_flux', 'ace_rtsw_epam_elec_flux']

  ; - NOISE:
  noise_var = ['swfo_stis_l0b_{}_NSE_GAP', 'swfo_stis_l1a_{}_NOISE_*',$
               'swfo_stis_l1a_{}_REACTION_WHEEL_SPEED_RPM',$
               'swfo_stis_l1a_{}_IRU_BITS']


  foreach resolution_str, data_resolution, res_index do begin

    ; Resolution of observation finagling:
    ; swfo_load keyword: lowres = 0 (full), 1 (30s), 2 (300s)
    ; Have to leave a crazy value for non-lowres bc it
    ; will keep appending '30s' to the swfo_types ad infinitum
    ; Instead, add the cadence kw to the swfo_types here
    ; and set the cadence kw to 5
    if resolution_str.endswith('s') then begin
      res_tplot_prefix = resolution_str
      res_kw = 5
      swfo_types_i = swfo_types + '_' + resolution_str
    endif else begin
      res_kw = 0
      res_tplot_prefix = 'fr'
      swfo_types_i = swfo_types
    endelse

    ; fill in the tplot variable info:
    tplot_hkp_var_i = replace_substring_arr(tplot_hkp_var, '{}', res_tplot_prefix)
    summ_var_i = replace_substring_arr(summ_var, '{}', res_tplot_prefix)
    ace_var_i = replace_substring_arr(ace_var, '{}', res_tplot_prefix)
    noise_var_i = replace_substring_arr(noise_var, '{}', res_tplot_prefix)

    for interval=0, n_intervals-1 do begin
      ; Get the end time of the interval:
      end_time_unix_i = end_time_unix[interval]

      ; Get the EARLIEST start time, so we can subset
      ; this to smaller inclusive ranges afterwards without
      ; having to reload the same data repeatedly.
      min_start_time_unix_i = min(start_time_unix[interval, *])

      ; Clear out all previously present data
      ; (tplot bogs down when it 'alters' variables, it is
      ; quicker to just delete em all).
      del_data, '*'

      ; Load the range:
      tr = [min_start_time_unix_i, end_time_unix_i]
      swfo_load, types=swfo_types_i, trange=tr, lowres=res_kw

      ; Sets the common tplot variables and appearances:
      swfo_stis_tplot, /setl

      ; if doing ace, load that as well
      if load_ace then ace_load, trange=tr

      for dur=0, n_durations - 1 do begin
        start_time_unix_i = start_time_unix[interval, dur]
        subset_tr = [start_time_unix_i, end_time_unix_i]
        ; print, tr
        print, time_String(subset_tr)
        ; stop

        ; Iterate through the possible plots to make:
        foreach plot_name, plot_types do begin
          ; stop
          ; Now create the plot png name:
          fname_i = time_string(subset_tr[1], tformat=destination_fname)
          fname_i = fname_i.replace('{PLOTNAME}', plot_name)
          fname_i = fname_i.replace('{PLOTDURATION}', plot_durations[dur])
          fname_i = fname_i.replace("{CADENCE}", res_tplot_prefix)
          ; stop

          ; Health plot
          if plot_name.startswith('health') then begin
            wi, 2, wsize=[800, 900]  ; [900, 1000]
            tplot, tplot_hkp_var_i, window=2
            tplot_options, 'charsize', 1.2
            tplot_options,'xmargin',[20,5]
            tplot_options, 'ygap', 0.4

            ; Apply ylimit & tlimit:
            foreach hkpname, hkp_var do begin
              hkp_tplot_name_i = 'swfo_stis_l0b_'+res_tplot_prefix+'_'+hkpname
              nom = hkp_nominal[hkpname]
              plot_yrange = [nom[0] - 0.25*(nom[1] - nom[0]), nom[1] + 0.25*(nom[1] - nom[0])]
              ylim, hkp_tplot_name_i, plot_yrange[0], plot_yrange[1]
            endforeach
            tlimit, subset_tr

            foreach hkpname, hkp_var do begin
              hkp_tplot_name_i = 'swfo_stis_l0b_'+res_tplot_prefix+'_'+hkpname
              nom = hkp_nominal[hkpname]

              if hkp_tplot_name_i.contains("FPGA") then continue

              timebar, nom[0], /databar, varname=hkp_tplot_name_i, color='g'
              timebar, nom[1], /databar, varname=hkp_tplot_name_i, color='g'
            endforeach

            timebar, 1.5, /databar, varname='swfo_stis_l0b_'+res_tplot_prefix+'_VOLTAGE_1P5_VD',$
              linestyle=5, color='m'
            timebar, 3.3, /databar, varname='swfo_stis_l0b_'+res_tplot_prefix+'_VOLTAGE_3P3_VD',$
              linestyle=5, color='m'
            timebar, 5.0, /databar, varname='swfo_stis_l0b_'+res_tplot_prefix+'_VOLTAGE_5P0_VD',$
              linestyle=5, color='m'
          endif else if plot_name.startswith('summ') then begin

            wi, 2, wsize=[900, 1000]
            tplot_options, 'charsize', 1.2
            tplot_options,'xmargin',[10,10]
            tplot_options, 'ygap', 0.4

            if res_tplot_prefix eq 'fr' then begin
             valid_yrange = [1, 2e5]
             eflux_zrange = [1, 1e5]
            endif else begin 
              valid_yrange=[0.2, 2e5]
              eflux_zrange = [0.2, 1e5]
            endelse

            ylim, 'swfo_stis_l0b_' + res_tplot_prefix +'_*_GAP', 0, 1, 0
            options, 'swfo_stis_l0b_' + res_tplot_prefix +'_*_GAP',$
              colors=6, panel_size=0.1, yticks=1, yminor=1

            options, 'swfo_stis_l0b_'+res_tplot_prefix+'_HKP_GAP',ytitle='Hkp', ysubtitle='Gap'
            options, 'swfo_stis_l0b_'+res_tplot_prefix+'_NSE_GAP',ytitle='Nse', ysubtitle='Gap'
            options, 'swfo_stis_l0b_'+res_tplot_prefix+'_SCI_GAP',ytitle='Sci', ysubtitle='Gap'

            options, 'swfo_stis_l1b_'+res_tplot_prefix+'_HDR_ION_EFLUX',$
              ytitle='Ion Energy [keV]', ztitle='HDR EFLUX', zrange=eflux_zrange
            options, 'swfo_stis_l1b_'+res_tplot_prefix+'_HDR_ELEC_EFLUX',$
              ytitle='Elec Energy [keV]', ztitle='HDR EFLUX', zrange=eflux_zrange

            options, 'swfo_stis_l1a_'+res_tplot_prefix+'_NOISE_SIGMA',$
              ytitle='Noise Sigma', panel_size=0.5
            options, 'swfo_stis_l0b_'+res_tplot_prefix+'_VALID_RATES',$
              ytitle='Valid Rates', ysubtitle='[counts/s]', yrange=valid_yrange

            tplot, summ_var_i, window=2
            tlimit, subset_tr
            ; stop

          endif else if plot_name.startswith('ace') then begin

            wi, 2, wsize=[900, 1000]
            tplot_options, 'charsize', 1.2
            tplot_options,'xmargin',[10,10]
            tplot_options, 'ygap', 0.4

            options, 'ace_rtsw_epam_elec_flux',$
              ytitle='5-min ACE Elec Flux', ysubtitle='[#/cm2-s-ster-keV]'
            options, 'ace_rtsw_epam_proton_flux',$
              ytitle='5-min ACE Proton Flux', ysubtitle='[#/cm2-s-ster-keV]'

            options, 'stis_l2_'+res_tplot_prefix+'_ION_FLUX',$
              ytitle=data_resolution_label[res_index] +'STIS Ion Flux', ysubtitle='[#/cm2-s-ster-keV]'
            options, 'stis_l2_'+res_tplot_prefix+'_ELEC_FLUX',$
              ytitle=data_resolution_label[res_index] +'STIS Elec Flux', ysubtitle='[#/cm2-s-ster-keV]'

            tplot, ace_var_i, window=2
            tlimit, subset_tr
            ; stop

          endif else if plot_name.startswith('noise') then begin

            wi, 2, wsize=[900, 1000]
            tplot_options, 'charsize', 1.2
            tplot_options,'xmargin',[10,10]
            tplot_options, 'ygap', 0.4


            ylim, 'swfo_stis_l0b_' + res_tplot_prefix +'_NSE_GAP', 0, 1, 0
            options, 'swfo_stis_l0b_' + res_tplot_prefix +'_NSE_GAP',$
              colors=6, panel_size=0.1, yticks=1, yminor=1
            options, 'swfo_stis_l0b_'+res_tplot_prefix+'_NSE_GAP',ytitle='Nse', ysubtitle='Gap'

            options, 'swfo_stis_l1a_' + res_tplot_prefix + '_NOISE_RES',$
              yrange=[0, 7], yminor=1, yticks=7, panel_size=0.5
            options, 'swfo_stis_l1a_' + res_tplot_prefix + '_NOISE_PERIOD',$
              yrange=[0, 250], yminor=1, panel_size=0.5


            options, 'swfo_stis_l1a_' + res_tplot_prefix + '_REACTION_WHEEL_SPEED_RPM',$
              yrange=[-2200, 2200]
            options, 'swfo_stis_l1a_' + res_tplot_prefix + '_NOISE_BASELINE',$
              yrange=[-10, 5]

            tplot, noise_var_i, window=2
            tlimit, subset_tr
            ; stop

          endif

          ; Write the pngs:

          makepng, fname_i, /mkdir, window=2
          tlimit, 0, 0


        endforeach
      endfor   ; day
    endfor
  endforeach

  return

end