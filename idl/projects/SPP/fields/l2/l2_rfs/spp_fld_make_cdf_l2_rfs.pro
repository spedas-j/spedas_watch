pro spp_fld_make_cdf_l2_rfs, $
  l2_master_cdf, l2_cdf, $
  rec, $
  trange = trange, $
  l1_cdf_dir = l1_cdf_dir, $
  make_master = make_master

  if n_elements(rec) EQ 0 then rec = 'hfr'

  if rec EQ 'lfr' then $
    datatypes = ['auto_averages','auto_peaks','hires_averages','hires_peaks'] $
  else $
    datatypes = ['auto_averages','auto_peaks','cross_im','cross_re','coher','phase']
  channels = ['ch0','ch1','']
  ch0_sources = ['V1V2','V1V3','SCM','V1','V3','GND']
  ch1_sources = ['V3V4','V3V2','V1V2','SCM','V2','V4','GND']
  cross_sources = ['V1V2_V3V4']
  hk_items = ['auto_peaks','auto_averages',$
    'auto_ch0','auto_ch0_string','auto_ch1',$
    'auto_ch1_string','auto_nsum','auto_gain','auto_hl']

  if n_elements(make_master) GT 0 then begin

    template = spp_fld_l2_cdf_skt_file('rfs_template')

    openr, unit, template, /get_lun

    line = ''
    lines_start = []
    lines_loop = []
    lines_end = []

    lines_out = []

    loop_start = 0
    loop_end = 0

    while not eof(unit) do begin

      readf, unit, line

      skip_line = 0
      if line.StartsWith('!! Start RFS loop') then begin
        skip_line = 1
        loop_start = 1
      endif
      if line.StartsWith('!! End RFS loop') then begin
        skip_line = 1
        loop_end = 1
      endif

      if skip_line EQ 0 then begin

        line = line.Replace('<receiver>', strlowcase(rec))
        line = line.Replace('<RECEIVER>', strupcase(rec))

        if loop_start EQ 0 then begin
          lines_start = [lines_start, line]
        endif else if loop_end EQ 1 then begin
          lines_end = [lines_end, line]
        endif else begin
          lines_loop = [lines_loop, line]
        endelse

      endif

    endwhile

    free_lun, unit

    lines_out = lines_start

    foreach dt, datatypes do begin
      foreach ch, channels do begin
        if ch EQ 'ch0' then begin
          sources = ch0_sources
        endif else if ch EQ 'ch1' then begin
          sources = ch1_sources
        endif else begin
          sources = cross_sources
        endelse
        foreach src, sources do begin

          cross_linear_set = 0
          phase_lim_set = 0
          coher_lim_set = 0

          foreach ln, lines_loop do begin

            ln = ln.Replace('<DATATYPE>', dt)
            ln = ln.Replace('<CHANNEL>', ch)
            ln = ln.Replace('<SOURCE>', src)
            if dt NE 'coher' and dt NE 'phase' then $
              ln = ln.Replace('<LABLAXIS>', 'PSD')


            ln = ln.Replace('__','_')

            if dt EQ 'cross_im' or dt EQ 'cross_re' then begin

              ln = ln.Replace('0.0e+0','-1.0e+30')

              if cross_linear_set EQ 0 and ln.Contains('log') then begin
                ln = ln.Replace('log','linear')
                cross_linear_set = 1
              end
            end

            if dt EQ 'coher' then begin

              ln = ln.Replace('1.0e+30','1.0')
              ln = ln.Replace('<LABLAXIS>', 'Coherence')
              ln = ln.Replace('"Volts^2/Hz"','"None"')
              ln = ln.Replace('"1.0>Volts^2/Hz"','"1.0>1.0"')

              if coher_lim_set EQ 0 then begin
                coher_lim_set = 1
              end
            end

            if dt EQ 'phase' then begin

              ln = ln.Replace('0.0e+0','-180.0')
              ln = ln.Replace('1.0e+30','180.0')
              ln = ln.Replace('<LABLAXIS>', 'Phase')
              ln = ln.Replace('"Volts^2/Hz"','"Degrees"')
              ln = ln.Replace('"1.0>Volts^2/Hz"','"1.0>1.0"')

              if phase_lim_set EQ 0 and ln.Contains('log') then begin
                ln = ln.Replace('log','linear')
                phase_lim_set = 1
              end
            end

            lines_out = [lines_out, ln]

          endforeach
        endforeach
      endforeach
    endforeach

    lines_out = [lines_out, lines_end]

    l2_master_cdf = template.Replace('rfs_template', 'rfs_' + rec)

    openw, unit, l2_master_cdf, /get_lun

    foreach ln, lines_out do printf, unit, ln

    free_lun, unit

    return

  endif

  if n_elements(l2_master_cdf) EQ 0 or n_elements(l2_cdf) EQ 0 then begin

    dprint, dlevel = 1, 'L2 master CDF or L2 CDF not specified'
    return

  endif

  l2 = read_master_cdf(l2_master_cdf,l2_cdf)

  buffer_tags = tag_names(l2)

  ep_vars_del = []
  sp_vars_del = []
  f_vars_del = []

  foreach dt, datatypes do begin
    foreach ch, channels do begin
      if ch EQ 'ch0' then begin
        sources = ch0_sources
      endif else if ch EQ 'ch1' then begin
        sources = ch1_sources
      endif else begin
        sources = cross_sources
      endelse
      foreach src, sources do begin

        item = 'spp_fld_rfs_' + rec + '_' + dt + '_' + ch + '_' + $
          'corrected_' + src

        item = item.Replace('__','_')

        if tnames(item) NE '' then begin

          get_data, item, data = data

          unix_time = data.x
          y = transpose(data.y)
          f = data.v

          ; TODO: fix time here

          met_time = unix_time - time_double('2010-01-01/00:00:00')
          t = long64((add_tt2000_offset(unix_time) - $
            time_double('2000-01-01/12:00:00'))*1.e9)

          if ndimen(f) EQ 1 then f = transpose(rebin(transpose(f), n_elements(t), n_elements(f))) else f= transpose(f)

          ep_tag = strupcase('epoch_' + dt + '_' + ch + '_' + src)
          sp_tag = strupcase(dt + '_' + ch + '_' + src)
          f_tag = strupcase('frequency_' + dt + '_' + ch + '_' + src)

          ep_tag = ep_tag.Replace('__','_')
          sp_tag = sp_tag.Replace('__','_')
          f_tag = f_tag.Replace('__','_')

          ep_tag_ind = (where(buffer_tags EQ ep_tag))[0]
          sp_tag_ind = (where(buffer_tags EQ sp_tag))[0]
          f_tag_ind = (where(buffer_tags EQ f_tag))[0]

          if ep_tag_ind GE 0 then *l2.(ep_tag_ind).data = t
          if sp_tag_ind GE 0 then *l2.(sp_tag_ind).data = y
          if f_tag_ind GE 0 then *l2.(f_tag_ind).data = f

        endif else begin

          ; TODO: fix time here too

          ep_var_del = 'epoch_' + dt + '_' + ch + '_' + src
          sp_var_del = dt + '_' + ch + '_' + src
          f_var_del = 'frequency_' + dt + '_' + ch + '_' + src

          ep_var_del = ep_var_del.Replace('__','_')
          sp_var_del = sp_var_del.Replace('__','_')
          f_var_del = f_var_del.Replace('__','_')

          ep_vars_del = [ep_vars_del, ep_var_del]
          sp_vars_del = [sp_vars_del, sp_var_del]
          f_vars_del = [f_vars_del, f_var_del]

        endelse

      endforeach
    endforeach
  endforeach

  hk_time_set = 0

  foreach hk_item, hk_items do begin

    item = 'spp_fld_rfs_' + rec + '_' + hk_item

    print, item, tnames(item) NE ''

    cdf_hk_epoch = 'epoch_' + rec

    cdf_item = hk_item.Replace('auto_','')

    ep_hk_tag_ind = (where(buffer_tags EQ strupcase(cdf_hk_epoch)))[0]
    hk_tag_ind = (where(buffer_tags EQ strupcase(cdf_item)))[0]

    if hk_tag_ind GE 0 and ep_hk_tag_ind GE 0 then begin

      get_data, item, dat = d

      if size(/type, d) EQ 8 then begin

        unix_time=d.x
        y=d.y

        if hk_time_set EQ 0 then begin

          ; TODO: fix time here

          met_time = unix_time - time_double('2010-01-01/00:00:00')
          t = long64((add_tt2000_offset(unix_time) - $
            time_double('2000-01-01/12:00:00'))*1.e9)

          *l2.(ep_hk_tag_ind).data = t

          hk_time_set = 1

        end

        *l2.(hk_tag_ind).data = y

      endif

    endif

  endforeach

  l2_write_status = write_data_to_cdf(l2_cdf, l2)

  cdf_id = cdf_open(l2_cdf)

  foreach ep_var_del, ep_vars_del do  CDF_VARDELETE, cdf_id, ep_var_del, /ZVARIABLE
  foreach sp_var_del, sp_vars_del do  CDF_VARDELETE, cdf_id, sp_var_del, /ZVARIABLE
  foreach f_var_del, f_vars_del do  CDF_VARDELETE, cdf_id, f_var_del, /ZVARIABLE

  ;  attexst = cdf_attexists(cdf_id,'l1_mago_survey_file')
  ;  if (attexst) then begin
  ;    attid = cdf_attnum(cdf_id, 'l1_mago_survey_file')
  ;    cdf_attput, cdf_id, attid, 0L, 'placeholder_for_input_filename'
  ;    dprint, dlevel = 3, 'Changed l1_mago_survey_file attribute to ','placeholder_for_input_filename'
  ;  endif

  cdf_close, cdf_id

end