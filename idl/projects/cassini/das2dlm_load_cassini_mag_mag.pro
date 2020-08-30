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
; $Date: 2020-08-28 20:48:35 -0700 (Fri, 28 Aug 2020) $
; $Revision: 29093 $
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
  
  ; Get variables
  das2dlm_get_ds_var, ds, 'time', 'center', p=px, v=vx, m=mx, d=x
  das2dlm_get_ds_var, ds, 'B_mag', 'center', p=py, v=vy, m=my, d=y

  ; Exit on empty data
  if undefined(x) then begin
    dprint, dlevel = 0, 'Dataset has no data for the selected period.'
    return
  endif

  ; Convert time
  x = das2dlm_time_to_unixtime(x, vx.units)
      
  tvarname = 'cassini_mag_' + ds.name
  store_data, tvarname, data={x:x, y:y}
  options, /default, tvarname, 'colors', 0
  
  ; Metadata
  das2dlm_get_ds_meta, ds, meta=mds, title=das2name

  str_element, DAS2, 'url', requestUrl, /add
  str_element, DAS2, 'name', das2name, /add
  str_element, DAS2, 'propds', mds, /add ; add data set property

  das2dlm_add_metadata, DAS2, p=px, v=vx, m=mx, add='t'
  das2dlm_add_metadata, DAS2, p=py, v=vy, m=my, add='t'
    
  options, /default, tvarname, 'DAS2', DAS2 ; Store metadata (this should not affect graphics)
  options, /default, tvarname, 'title', DAS2.name
  
  ; Data Label
  ytitle = DAS2.namey + ', ' + DAS2.unitsy
  str_element, my[0], 'key', success=s
  if s eq 1 then str_element, my[0], 'value', ytitle    
  options, /default, tvarname, 'ytitle', ytitle ; Title from the properties
end