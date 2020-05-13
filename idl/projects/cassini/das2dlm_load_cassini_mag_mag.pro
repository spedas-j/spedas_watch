; PRO das2dlm_load_cassini_mag_mag
;
; :Description:
;    Magnetic Field Magnitude
;
;:Params:
;
;:Keywords:
;  trange: If a time range is set, timespan is executed with it at the end of this program

pro das2dlm_load_cassini_mag_mag, trange=trange
  
  if ~undefined(trange) && n_elements(trange) eq 2 $
   then tr = timerange(trange) $
   else tr = timerange()
       
  
  time_format = 'YYYY-MM-DDThh:mm:ss'
  
  url = 'http://planet.physics.uiowa.edu/das/das2Server?server=dataset'
  dataset = 'dataset=Cassini/MAG/Magnitude'
  time1 = 'start_time=' + time_string( tr[0] , tformat=time_format)
  time2 = 'end_time=' + time_string( tr[1] , tformat=time_format)

  requestUrl = url + '&' + dataset + '&' + time1 + '&' + time2

  query = das2c_readhttp(requestUrl)
  
  ; Get dataset
  ds = das2c_datasets(query, 0)
  
  ; Get physical dimentions
  px = das2c_pdims(ds, 'time')
  py = das2c_pdims(ds, 'B_mag')
  
  vx = das2c_vars(px, 'center')
  vy = das2c_vars(py, 'center')
  
  x = das2c_data(vx)
  y = das2c_data(vy)
  
  dt = time_double('2000-01-01')-time_double('1970-01-01')
  x = x/1d6 + dt
  
  tvarname = 'cassini_mag_' + ds.name
  store_data, tvarname, data={x:x, y:y}
  ; TODO: add options
  ; TODO: add check on null
  ; TODO: add limits
  ; TODO: add times
  ; us2000 – Microseconds since midnight January 1st 2000, ignoring leap seconds
  
   
end