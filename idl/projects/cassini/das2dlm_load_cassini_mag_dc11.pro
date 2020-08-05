;+
; PRO: das2dlm_load_cassini_mag_dc11, ...
;
; Description:
;    Loads Difference between the C11 model field and Cassini MAG 1-second observations using das2dlm library
;    dataset: Cassini/MAG/Differential_C11
;
; Keywords:
;    trange: Sets the time tange
;    
; NOTE:
;    This is password protected data set. This function does not work with password protected datasets.
;    
; CREATED BY:
;    Alexander Drozdov (adrozdov@ucla.edu)
;
; $LastChangedBy: adrozdov $
; $Date: 2020-08-03 20:45:11 -0700 (Mon, 03 Aug 2020) $
; $Revision: 28983 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/cassini/das2dlm_load_cassini_mag_dc11.pro $
;-

pro das2dlm_load_cassini_mag_dc11, trange=trange
  
  das2dlm_cassini_init
      
  if ~undefined(trange) && n_elements(trange) eq 2 $
   then tr = timerange(trange) $
   else tr = timerange()
       
  
  time_format = 'YYYY-MM-DDThh:mm:ss'
  
  url = 'http://planet.physics.uiowa.edu/das/das2Server?server=dataset'
  dataset = 'dataset=Cassini/MAG/Differential_C11'
  time1 = 'start_time=' + time_string( tr[0] , tformat=time_format)
  time2 = 'end_time=' + time_string( tr[1] , tformat=time_format)

  requestUrl = url + '&' + dataset + '&' + time1 + '&' + time2
  print, requestUrl

  query = das2c_readhttp(requestUrl)
  
  ; Get dataset
  ds = das2c_datasets(query, 0)
  
  ; Get time
  das2dlm_get_ds_var, ds, 'time', 'center', p=pt, v=vt, m=mt, d=dt
  
 ; Convert time
  dt = das2dlm_time_to_unixtime(dt, vt.units)
  
  ; get Var
  pdims = das2c_pdims(ds)
  varname = pdims[1].name
  das2dlm_get_ds_var, ds, varname, 'center', p=py, v=vy, m=my, d=dy
    
  ; Metadata
  str_element, DAS2, 'url', requestUrl, /add
  str_element, DAS2, 'name', ds.name, /add ; ds.name does not contain usefull information in this case

  das2dlm_add_metadata, DAS2, p=pt, v=vt, m=mt, add='t'
  das2dlm_add_metadata, DAS2, p=py, v=vy, m=my, add=''
  
  tvarname = 'cassini_mag_' + py.pdim
  store_data, tvarname, data={x:dt, y:dy}
  options, /default, tvarname, 'colors', 0
  options, /default, tvarname, 'DAS2', DAS2 ; Store metadata (this should not affect graphics)
  options, /default, tvarname, 'title', ds.name ; custom title
  
  ytitle = DAS2.name + ', ' + DAS2.units
  options, /default, tvarname, 'ytitle', ytitle ; Title from the properties

end