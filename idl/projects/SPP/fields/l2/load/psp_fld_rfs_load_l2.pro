pro psp_fld_rfs_load_l2, files, hfr_only = hfr_only, lfr_only = lfr_only

  if n_elements(files) EQ 0 and n_elements(hfr_only) EQ 0 and n_elements(lfr_only) EQ 0 then begin

    psp_fld_rfs_load_l2, /hfr_only
    psp_fld_rfs_load_l2, /lfr_only

    return

  endif else if n_elements(files) EQ 0 then begin

    if keyword_set(hfr_only) then rec = 'hfr' else rec = 'lfr'

    spp_fld_load, type = 'rfs_' + rec, /no_load, files = files

    valid_files = where(file_test(files) EQ 1, valid_count)

    if valid_count GT 0 then begin
      filenames = files[valid_files]
      psp_fld_rfs_load_l2, filenames
    end

    return

  endif

  vars_fmt = []

  for i = 0, n_elements(files) -1 do begin

    file = files[i]

    cdf_id = cdf_open(file)

    info = cdf_info(cdf_id,verbose=verbose)

    for j = 0, info.nv - 1 do begin
      name = info.vars[j].name
      if strmid(name,0,7) EQ 'psp_fld' then begin
        cdf_control,cdf_id,variable=name, get_var_info=vinfo
        ;print, name, vinfo.maxrecs, vinfo.maxrec, file
        if vinfo.maxrec GE 0 and where(vars_fmt EQ name) EQ -1 then vars_fmt = [vars_fmt, name]
      endif
    endfor

    cdf_close, cdf_id

  endfor

  cdf2tplot, files, varformat = vars_fmt, varnames = varnames

  meta_end = ['averages', 'peaks', 'ch0', 'ch1', 'string', $
    'nsum', 'gain', 'hl']

  meta = ['averages', 'peaks', 'ch0', 'ch0_string', 'ch1', 'ch1_string', $
    'nsum', 'gain', 'hl']

  types = ['auto_averages', 'auto_peaks', 'cross_im', 'cross_re', 'coher', 'phase']

  if file_basename(getenv('IDL_CT_FILE')) EQ 'spp_fld_colors.tbl' then set_colors = 1 else set_colors = 0

  for i = 0, n_elements(varnames) - 1 do begin

    var = varnames[i]

    if tnames(var) EQ var and var NE 'psp_fld_l2_quality_flags' then begin

      split = strsplit(var,'_',/extract)

      rec = ''
      type = ''

      if strpos(var, '_hfr_') GT 0 then rec = 'HFR'
      if strpos(var, '_lfr_') GT 0 then rec = 'LFR'

      if rec EQ 'HFR' then colors = [2] else colors = [6]

      is_meta = (where(meta_end EQ split[-1]) GT -1)

      if is_meta then begin

        options, var, 'colors', colors
        options, var, 'ysubtitle', ''
        options, var, 'psym_lim', 100

        if strpos(var, '_string') GT 0 then begin

          options, var, 'tplot_routine', 'strplot'
          options, var, 'noclip', 0
          options, var, 'ytickformat', 'spp_fld_ticks_blank'
          type = split[-2]

        endif else begin

          type = split[-1]

          get_data, var, dat = d

          if type EQ 'ch0' or type EQ 'ch1' then begin

            options, var, 'yrange', [-1,8]
            options, var, 'yticks', 7
            options, var, 'yminor', 0
            options, var, 'ytickv', [0,1,2,3,4,5,6,7]
            options, var, 'panel_size', 1.0

          endif else if type EQ 'nsum' then begin

            options, var, 'yrange', [0,100]

          endif else if type EQ 'hl' then begin

            options, var, 'yrange', [-0.5,3.5]
            options, var, 'yticks', 3
            options, var, 'yminor', 0
            options, var, 'ytickv', [0,1,2,3]
            options, var, 'panel_size', 0.5

          endif else begin

            if min(d.y) GE 0 and max(d.y) LE 1 then begin

              options, var, 'yticks', 1
              options, var, 'yminor', 0
              options, var, 'yrange', [-0.25,1.25]
              options, var, 'ystyle', 1
              options, var, 'ytickv', [0,1]
              options, var, 'psym_lim', 100
              options, var, 'panel_size', 0.5

            endif

          endelse

        endelse

        ytitle = rec + '!C' + strupcase(type)

        str_replace, ytitle, 'AVERAGES', 'AV'
        str_replace, ytitle, 'PEAKS', 'PK'

        ; don't reset the title if it's already set with a source appended

        get_data, var, lim = l

        str_element, l, 'ytitle', ytitle0, success = ytitle_found

        if ytitle_found NE 0 then begin

          if ytitle0.StartsWith(ytitle) then begin
            ytitle = ytitle0
          endif else begin
            ytitle = ytitle + ytitle0
          endelse

        end

        options, var, 'ytitle', ytitle

      endif else begin

        print, var

        src = ''

        if strpos(var, '_auto_') GT 0 then begin
          if strpos(var, '_auto_averages_') GT 0 then type = 'AV'
          if strpos(var, '_auto_peaks_') GT 0 then type = 'PK'
          src = split[-1]
          if set_colors then options, var, 'color_table', 129
          options, var, 'zlog', 1
          options, var, 'auto_downsample', 1
          options, var, 'ztitle', '[V2/Hz]'
        endif

        if strpos(var, '_hires_') GT 0 then begin
          if strpos(var, '_hires_averages_') GT 0 then type = 'HR AV'
          if strpos(var, '_hires_peaks_') GT 0 then type = 'HR PK'
          src = split[-1]
          if set_colors then options, var, 'color_table', 129
          options, var, 'zlog', 1
          options, var, 'ylog', 0
          options, var, 'auto_downsample', 1
          options, var, 'ztitle', '[V2/Hz]'
        endif

        if strpos(var, '_coher_') GT 0 then begin
          type = 'COH'
          src = split[-2] + '-'  + split[-1]
          if set_colors then options, var, 'color_table', 117
          options, var, 'zlog', 1
          options, var, 'zrange', [0.001,1]
          options, var, 'ztitle', ''
        endif

        if strpos(var, '_phase_') GT 0 then begin
          type = 'PHA'
          src = split[-2] + '-'  + split[-1]
          if set_colors then options, var, 'color_table', 75
          options, var, 'zlog', 0
          options, var, 'zrange', [-180,180]
          options, var, 'ztickv', [-180,-90,0,90,180]
          options, var, 'zticks', 4
          options, var, 'ztitle', '[Deg]'
        endif

        if strpos(var, '_cross_') GT 0 then begin
          if strpos(var, '_cross_im_') GT 0 then type = 'X IM'
          if strpos(var, '_cross_re_') GT 0 then type = 'X RE'
          src = split[-2] + '-'  + split[-1]
          if set_colors then options, var, 'color_table', 129
          options, var, 'zlog', 0
          options, var, 'ztitle', '[V2/Hz]'
        endif

        get_data, var, data = d

        options, var, 'yrange', minmax(d.v)
        options, var, 'datagap', 180d
        options, var, 'ystyle', 1
        if strpos(var, '_hires_') EQ 0 then options, var, 'ylog', 1
        options, var, 'no_interp', 1
        options, var, 'panel_size', 2

        options, var, 'ysubtitle', '[Hz]'

        ytitle = rec + '!C' + strupcase(type) + '!C' + src

        options, var, 'ytitle', ytitle

        ; add source information to metavariables

        related_meta_vars = tnames(var + '_*')

        foreach rm_var, related_meta_vars do begin

          get_data, rm_var, lim = lim

          str_element, lim, 'ytitle', ytitle0, success = ytitle_found

          if ytitle_found NE 0 then begin
            options, rm_var, 'ytitle', ytitle0 + '!C' + src
          endif else begin
            options, rm_var, 'ytitle', '!C' + src
          endelse


        endforeach

        ;      stop

      endelse

    endif

  endfor

end