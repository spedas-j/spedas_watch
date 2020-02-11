function elf_make_sm_grid, trange=trange

  ulons=make_array(361*9,/float)
  ulats=make_array(361*9,/float)
  r=make_array(361*9,/float)+1
  ;trange=time_double(['2019-09-28','2019-09-29'])
  tmid=trange[0]+(trange[1]-trange[0])/2.
  times=make_array(n_elements(ulons),/double)+tmid

  ; create lat rings
  for i=0,8 do begin
    ulats[i*360:(i+1)*360]=i*10
    ulons[i*360:(i+1)*360]=findgen(361)
  endfor
  sphere_to_cart, r,ulats,ulons,x,y,z
  store_data, 'cart_latlons_geo', data={x:times, y:[[x],[y],[z]]}
  cotrans, 'cart_latlons_geo', 'cart_latlons_gei', /geo2gei
  cotrans, 'cart_latlons_gei', 'cart_latlons_gse', /gei2gse
  cotrans, 'cart_latlons_gse', 'cart_latlons_gsm', /gse2gsm
  cotrans, 'cart_latlons_gsm', 'cart_latlons_sm', /gsm2sm
  get_data, 'cart_latlons_sm', data=d
  cart_to_sphere, d.y[*,0], d.y[*,1], d.y[*,2], r, usmlats, usmlons

  thislat=findgen(80)
  for i=0,11 do begin
    thislon=make_array(80,/float)+i*30.
    append_array, vlons, thislon
    append_array, vlats, thislat
  endfor
  sphere_to_cart, r,vlats,vlons,x,y,z
  times=make_array(n_elements(vlats),/double)+tmid
  store_data, 'cart_latlons_geo', data={x:times, y:[[x],[y],[z]]}
  cotrans, 'cart_latlons_geo', 'cart_latlons_gei', /geo2gei
  cotrans, 'cart_latlons_gei', 'cart_latlons_gse', /gei2gse
  cotrans, 'cart_latlons_gse', 'cart_latlons_gsm', /gse2gsm
  cotrans, 'cart_latlons_gsm', 'cart_latlons_sm', /gsm2sm
  get_data, 'cart_latlons_sm', data=d
  cart_to_sphere, d.y[*,0], d.y[*,1], d.y[*,2], r, vsmlats, vsmlons

  sm_grid={lat_circles:[[usmlons], [usmlats]], lon_lines:[[vsmlons], [vsmlats]]}

  return, sm_grid

end
