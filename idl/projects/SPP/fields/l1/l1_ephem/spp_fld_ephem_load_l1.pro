pro spp_fld_ephem_load_l1, file, prefix = prefix

  cdf2tplot, /get_support_data, file, prefix = prefix

  frame = strjoin((strsplit(/ex, prefix, '_'))[3:*],'_')

  rs = 695508d
  re = 6371d
  rv = 6052d
  rm = 2440d

  ;  options, prefix + 'position', 'colors', 'bgr'

  get_data, prefix + 'position', data = pos_dat
  get_data, prefix + 'velocity', data = vel_dat

  store_data, prefix + 'position_rs', $
    data = {x:pos_dat.x, y:pos_dat.y/rs}

  options, prefix + 'position_rs', 'ysubtitle', '[Rs]'

  if frame EQ 'spp_rtn' or frame EQ 'spp_hertn' then begin

    store_data, prefix + 'radial_distance', $
      data = {x:pos_dat.x, y:total(pos_dat.y,2)}

    store_data, prefix + 'radial_distance_rs', $
      data = {x:pos_dat.x, y:total(pos_dat.y,2)/rs}

    options, '*radial_distance*', 'ynozero', 1

    store_data, prefix + 'radial_velocity', $
      data = {x:vel_dat.x, y:total(vel_dat.y,2)}

    options, prefix + 'radial_distance', 'ysubtitle', '[km]'
    options, prefix + 'radial_velocity', 'ysubtitle', '[km/s]'
    options, prefix + 'radial_distance_rs', 'ysubtitle', '[Rs]'

  endif
  
  if frame EQ 'spp_vso' then begin
    
    store_data, prefix + 'position_rv', $
      data = {x:pos_dat.x, y:pos_dat.y/rv}

    store_data, prefix + 'radial_distance', $
      data = {x:pos_dat.x, y:sqrt(total(pos_dat.y^2,2))}

    store_data, prefix + 'radial_distance_rv', $
      data = {x:pos_dat.x, y:sqrt(total(pos_dat.y^2,2))/rv}

    options, '*radial_distance*', 'ynozero', 1
    options, prefix + 'position_rv', 'ysubtitle', '[Rv]'
    options, prefix + 'radial_distance', 'ysubtitle', '[km]'
    options, prefix + 'radial_distance_rv', 'ysubtitle', '[Rv]'
    
  endif

  if frame EQ 'spp_mso' then begin

    store_data, prefix + 'position_rm', $
      data = {x:pos_dat.x, y:pos_dat.y/rv}

    store_data, prefix + 'radial_distance', $
      data = {x:pos_dat.x, y:sqrt(total(pos_dat.y^2,2))}

    store_data, prefix + 'radial_distance_rm', $
      data = {x:pos_dat.x, y:sqrt(total(pos_dat.y^2,2))/rv}

    options, '*radial_distance*', 'ynozero', 1
    options, prefix + 'position_rm', 'ysubtitle', '[Rm]'
    options, prefix + 'radial_distance', 'ysubtitle', '[km]'
    options, prefix + 'radial_distance_rm', 'ysubtitle', '[Rm]'

  endif

  if frame EQ 'spp_gse' then begin

    store_data, prefix + 'position_re', $
      data = {x:pos_dat.x, y:pos_dat.y/rv}

    store_data, prefix + 'radial_distance', $
      data = {x:pos_dat.x, y:sqrt(total(pos_dat.y^2,2))}

    store_data, prefix + 'radial_distance_re', $
      data = {x:pos_dat.x, y:sqrt(total(pos_dat.y^2,2))/rv}

    options, '*radial_distance*', 'ynozero', 1
    options, prefix + 'position_re', 'ysubtitle', '[Re]'
    options, prefix + 'radial_distance', 'ysubtitle', '[km]'
    options, prefix + 'radial_distance_re', 'ysubtitle', '[Re]'

  endif

  options, prefix + '*vector*', 'ysubtitle', ''

  options, prefix + '*vector*', 'yrange', [-1.0,1.0]
  options, prefix + '*vector*', 'ystyle', 1
  options, prefix + '*vector*', 'yticklen', 1
  options, prefix + '*vector*', 'ygridstyle', 1

  ephem_names = tnames(prefix + '*')

  if ephem_names[0] NE '' then begin

    if (frame EQ 'spp_rtn' or frame EQ 'spp_hertn') then labels = ['R', 'T', 'N'] else labels = ['X', 'Y', 'Z']

    foreach name, ephem_names do begin

      name_no_prefix = name.Remove(0, prefix.Strlen()-1)

      rs_strpos = strpos(name_no_prefix, '_rs')

      if rs_strpos GT 0 then name_no_prefix = strmid(name_no_prefix,0,rs_strpos)

      get_data, name, data = d

      ndims = size(d.y, /n_dimensions)
      dims = size(d.y, /dimensions)

      if ndims EQ 2 then begin
        if dims[1] EQ 3 then begin
          options, name, 'colors', 'rgb'

          options, name, 'labels', labels
          
          if strpos(name, 'vector') NE -1 then begin
            
            options, name, 'labels', 'SC' + strupcase(strmid(name_no_prefix, 3, 1)) + '-' + labels
            
          endif
          
        endif
      endif

      options, name, 'ynozero', 1

      options, name, 'ytitle', 'PSP!C' + strupcase(frame) + '!C' + name_no_prefix
      options, name, 'psym_lim', 100
      options, name, 'datagap', 600d
      options, name, 'symsize', 0.75

    endforeach

  endif




end