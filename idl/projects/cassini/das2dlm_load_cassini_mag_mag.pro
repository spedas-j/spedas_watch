;+
; PRO: das2dlm_load_cassini_mag_mag, ...
;
; Description:
;    Loads Magnetic Field Magnitude from Cassini using das2dlm library
;    dataset: Cassini/MAG/Magnitude
;
; Keywords:
;    trange: Sets the time tange
;    
; CREATED BY:
;    Alexander Drozdov (adrozdov@ucla.edu)
;
; $LastChangedBy: adrozdov $
; $Date: 2020-06-01 17:27:59 -0700 (Mon, 01 Jun 2020) $
; $Revision: 28753 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/cassini/das2dlm_load_cassini_mag_mag.pro $
;-

pro das2dlm_load_cassini_mag_mag, trange=trange
  
  das2dlm_cassini_init
  
  if ~undefined(trange) && n_elements(trange) eq 2 $
   then tr = timerange(trange) $
   else tr = timerange()
       
  
  time_format = 'YYYY-MM-DDThh:mm:ss'
  
  url = 'http://planet.physics.uiowa.edu/das/das2Server?server=dataset'
  dataset = 'dataset=Cassini/MAG/Magnitude'
  time1 = 'start_time=' + time_string( tr[0] , tformat=time_format)
  time2 = 'end_time=' + time_string( tr[1] , tformat=time_format)

  requestUrl = url + '&' + dataset + '&' + time1 + '&' + time2
  print, requestUrl

  query = das2c_readhttp(requestUrl)
  
  ; Get dataset
  ds = das2c_datasets(query, 0)
  
  ; Get physical dimentions
  px = das2c_pdims(ds, 'time')
  py = das2c_pdims(ds, 'B_mag')
  
  vx = das2c_vars(px, 'center')
  vy = das2c_vars(py, 'center')
  
  mx = das2c_props(px) ; properties (metadata)
  my = das2c_props(py) ; properties (metadata)
  
  x = das2c_data(vx)
  y = das2c_data(vy)
  
  dt = time_double('2000-01-01')-time_double('1970-01-01')
  x = x/1d6 + dt
  
  tvarname = 'cassini_mag_' + ds.name
  store_data, tvarname, data={x:x, y:y}
  options, /default, tvarname, 'colors', 0
  
  ; Metadata
  str_element, DAS2, 'url', requestUrl, /add
  str_element, DAS2, 'name', ds.name, /add

  str_element, DAS2, 'namex', px.pdim, /add
  str_element, DAS2, 'namey', py.pdim, /add
  
  str_element, DAS2, 'usex', px.use, /add
  str_element, DAS2, 'usey', py.use, /add
    
  str_element, DAS2, 'unitsx', vx.units, /add
  str_element, DAS2, 'unitsy', vy.units, /add
  
  str_element, DAS2, 'propsx', mx, /add
  str_element, DAS2, 'propsy', my, /add

  
  options, /default, tvarname, 'DAS2', DAS2 ; Store metadata (this should not affect graphics)
  
  options, /default, tvarname, 'title', tvarname
  
  ; Data Label
  ytitle = DAS2.namey + ', ' + DAS2.unitsy
  str_element, my[0], 'key', success=s
  if s eq 1 then str_element, my[0], 'value', ytitle    
  options, /default, tvarname, 'ytitle', ytitle ; Title from the properties
    
  ; TODO: add check on null
  ; us2000 – Microseconds since midnight January 1st 2000, ignoring leap seconds

end