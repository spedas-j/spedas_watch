function elf_make_sm_grid, tdate=tdate

  ; create lat rings
  thisllon=findgen(360)
  for i=0,8 do begin
    thisllat=make_array(360,/float)+i*10.
    append_array, ulats, thisllat
    append_array, ulons, thisllon 
  endfor

  r=make_array(360*9,/float)+1
  sphere_to_cart, r,ulats,ulons,x,y,z
  times=make_array(n_elements(ulons),/double)+tdate
  store_data, 'cart_latlons_geo', data={x:times, y:[[x],[y],[z]]}
  cotrans, 'cart_latlons_geo', 'cart_latlons_gei', /geo2gei
  cotrans, 'cart_latlons_gei', 'cart_latlons_gse', /gei2gse
  cotrans, 'cart_latlons_gse', 'cart_latlons_gsm', /gse2gsm
  cotrans, 'cart_latlons_gsm', 'cart_latlons_sm', /gsm2sm
  get_data, 'cart_latlons_sm', data=d
  cart_to_sphere, d.y[*,0], d.y[*,1], d.y[*,2], r, usmlats, usmlons

  thislat=findgen(90)
  for i=0,11 do begin
    thislon=make_array(90,/float)+i*30.
    append_array, vlons, thislon
    append_array, vlats, thislat
  endfor
  sphere_to_cart, r,vlats,vlons,x,y,z
  times=make_array(n_elements(vlats),/double)+tdate
  store_data, 'cart_latlons_geo', data={x:times, y:[[x],[y],[z]]}
  cotrans, 'cart_latlons_geo', 'cart_latlons_gei', /geo2gei
  cotrans, 'cart_latlons_gei', 'cart_latlons_gse', /gei2gse
  cotrans, 'cart_latlons_gse', 'cart_latlons_gsm', /gse2gsm
  cotrans, 'cart_latlons_gsm', 'cart_latlons_sm', /gsm2sm
  get_data, 'cart_latlons_sm', data=d
  cart_to_sphere, d.y[*,0], d.y[*,1], d.y[*,2], r, vsmlats, vsmlons

  ; calculate magnetic pole
  sphere_to_cart, 1., 90.,0.,x,y,z
  store_data, 'cart_npole_geo', data={x:tdate, y:[[x],[y],[z]]}
  cotrans, 'cart_npole_geo', 'cart_npole_gei', /geo2gei
  cotrans, 'cart_npole_gei', 'cart_npole_gse', /gei2gse
  cotrans, 'cart_npole_gse', 'cart_npole_gsm', /gse2gsm
  cotrans, 'cart_npole_gsm', 'cart_npole_sm', /gsm2sm
  get_data, 'cart_npole_sm', data=d
  cart_to_sphere, d.y[*,0], d.y[*,1], d.y[*,2], r, npsmlats, npsmlons
  
  sm_grid={lat_circles:[[usmlons], [usmlats]], $
           lon_lines:[[vsmlons], [vsmlats]], $
           npole: [npsmlats, npsmlons]}

  return, sm_grid

end
