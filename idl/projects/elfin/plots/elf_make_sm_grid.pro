;+
; PROCEDURE:
;         elf_make_sm_grid
;
; PURPOSE:
;         Create latitude rings and longitude spokes
;         (for use with ELFIN orbit plots)
;
; KEYWORDS:
;         tdate: time to be used for calculation
;                (format can be time string '2020-03-20'
;                or time double)
;         south: use this flag for grids in southern hemisphere
;
; OUTPUT:
;         sm_grids: structure with lat rings, lon spokes, and poles
;
; EXAMPLE:
;         sm_grid = elf_make_sm_grid('2020-03-20')
;         sm_grid = elf_make_sm_grid('2020-03-20', /south)
;
;-
function elf_make_sm_grid, tdate=tdate,south=south

  ;------------------------
  ; Create Latitude rings
  ;------------------------
  ; create geographic rings (from 0 to 90 deg every 10 deg)
  thisllon=findgen(360)
  for i=0,8 do begin
    thisllat=make_array(360,/float)+i*10.
    append_array, ulats, thisllat
    append_array, ulons, thisllon 
  endfor

  ; convert lat rings from geo to sm
  r=make_array(360*9,/float)+0.1
  sphere_to_cart, r,ulats,ulons,x,y,z
  times=make_array(n_elements(ulons),/double)+tdate
  store_data, 'cart_latlons_geo', data={x:times, y:[[x],[y],[z]]}
  cotrans, 'cart_latlons_geo', 'cart_latlons_gei', /geo2gei
  cotrans, 'cart_latlons_gei', 'cart_latlons_gse', /gei2gse
  cotrans, 'cart_latlons_gse', 'cart_latlons_gsm', /gse2gsm
  cotrans, 'cart_latlons_gsm', 'cart_latlons_sm', /gsm2sm
  get_data, 'cart_latlons_sm', data=d
  cart_to_sphere, d.y[*,0], d.y[*,1], d.y[*,2], r, usmlats, usmlons

  ;-------------------------
  ; Create Longitude Spokes
  ;-------------------------
  ; geographic spokes go from 0 to 360 deg every 30 deg
  thislat=findgen(90)
  for i=0,11 do begin
    thislon=make_array(90,/float)+i*30.
    append_array, vlons, thislon
    append_array, vlats, thislat
  endfor
  
  ; convert longitude spokes to sm coordinates
  r=make_array(360*9,/float)+0.1
  sphere_to_cart, r,vlats,vlons,x,y,z
  times=make_array(n_elements(vlats),/double)+tdate
  store_data, 'cart_latlons_geo', data={x:times, y:[[x],[y],[z]]}
  cotrans, 'cart_latlons_geo', 'cart_latlons_gei', /geo2gei
  cotrans, 'cart_latlons_gei', 'cart_latlons_gse', /gei2gse
  cotrans, 'cart_latlons_gse', 'cart_latlons_gsm', /gse2gsm
  cotrans, 'cart_latlons_gsm', 'cart_latlons_sm', /gsm2sm
  get_data, 'cart_latlons_sm', data=d
  cart_to_sphere, d.y[*,0], d.y[*,1], d.y[*,2], r, vsmlats, vsmlons

  ;--------------------------
  ; Calculate magnetic pole
  ;--------------------------
  if ~keyword_set(south) then lat_geo_pole=90. else lat_geo_pole=-90.
  sphere_to_cart, 1.,lat_geo_pole,0.1,x,y,z
  store_data, 'cart_pole_geo', data={x:tdate, y:[[x],[y],[z]]}
  cotrans, 'cart_pole_geo', 'cart_pole_gei', /geo2gei
  cotrans, 'cart_pole_gei', 'cart_pole_gse', /gei2gse
  cotrans, 'cart_pole_gse', 'cart_pole_gsm', /gse2gsm
  cotrans, 'cart_pole_gsm', 'cart_pole_sm', /gsm2sm
  get_data, 'cart_pole_sm', data=d
  cart_to_sphere, d.y[*,0], d.y[*,1], d.y[*,2], r, psmlats, psmlons
  
  sm_grid={lat_circles:[[usmlons], [usmlats]], $
           lon_lines:[[vsmlons], [vsmlats]], $
           pole: [psmlats, psmlons]}

  return, sm_grid

end
