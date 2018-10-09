pro spp_fld_ephem_load_l1, file, prefix = prefix

  cdf2tplot, file, prefix = prefix

  frame = strjoin((strsplit(/ex, prefix, '_'))[3:*],'_')

  rs = 695508d

  ;  options, prefix + 'position', 'colors', 'bgr'

  get_data, prefix + 'position', data = pos_dat
  get_data, prefix + 'velocity', data = vel_dat

  store_data, prefix + 'position_rs', $
    data = {x:pos_dat.x, y:pos_dat.y/rs}

  if frame EQ 'spp_rtn' then begin

    store_data, prefix + 'radial_distance', $
      data = {x:pos_dat.x, y:total(pos_dat.y,2)}

    store_data, prefix + 'radial_distance_rs', $
      data = {x:pos_dat.x, y:total(pos_dat.y,2)/rs}

    options, '*radial_distance*', 'ynozero', 1

    store_data, prefix + 'radial_velocity', $
      data = {x:vel_dat.x, y:total(vel_dat.y,2)}

  endif

  options, prefix + 'radial_distance', 'ysubtitle', '[km]'
  options, prefix + 'radial_velocity', 'ysubtitle', '[km/s]'
  options, prefix + 'radial_distance_rs', 'ysubtitle', '[Rs]'

  options, prefix + '*vector*', 'ysubtitle', ''


  ephem_names = tnames(prefix + '*')

  if ephem_names[0] NE '' then begin

    if frame EQ 'spp_rtn' then labels = ['R', 'T', 'N'] else labels = ['X', 'Y', 'Z']

    foreach name, ephem_names do begin

      name_no_prefix = name.Remove(0, prefix.Strlen()-1)

      get_data, name, data = d

      ndims = size(d.y, /n_dimensions)
      dims = size(d.y, /dimensions)

      if ndims EQ 2 then begin
        if dims[1] EQ 3 then begin
          options, name, 'colors', 'rgb'

          options, name, 'labels', labels
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