;+
; PRO: das2dlm_load_cassini_mag_ec, ...
;
; Description:
;    Loads Electron Cyclotron Resonance Frequency from Cassini using das2dlm library
;    dataset: Cassini/MAG/ElectronCyclotron
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
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/cassini/das2dlm_load_cassini_mag_ec.pro $
;-

pro das2dlm_load_cassini_mag_ec, trange=trange
  
  das2dlm_cassini_init
  
  if ~undefined(trange) && n_elements(trange) eq 2 $
   then tr = timerange(trange) $
   else tr = timerange()
       
  
  time_format = 'YYYY-MM-DDThh:mm:ss'
  
  url = 'http://planet.physics.uiowa.edu/das/das2Server?server=dataset'
  dataset = 'dataset=Cassini/MAG/ElectronCyclotron'
  time1 = 'start_time=' + time_string( tr[0] , tformat=time_format)
  time2 = 'end_time=' + time_string( tr[1] , tformat=time_format)

  requestUrl = url + '&' + dataset + '&' + time1 + '&' + time2
  print, requestUrl

  query = das2c_readhttp(requestUrl)
  
  ; Get dataset
  ds = das2c_datasets(query, 0)
  
  ; Get time
  das2dlm_get_ds_var, ds, 'time', 'center', p=pt, v=vt, m=mt, d=dt
  
  ; Exit on empty data
  if undefined(dt) then begin
    dprint, dlevel = 0, 'Dataset has no data for the selected period.'
    return
  endif
  
   ; Convert time
  dt = das2dlm_time_to_unixtime(dt, vt.units)
  
  ; get Fce
  das2dlm_get_ds_var, ds, 'Fce', 'center', p=py, v=vy, m=my, d=dy
    
  ; Metadata
  das2dlm_get_ds_meta, ds, meta=mds, title=das2name
  
  str_element, DAS2, 'url', requestUrl, /add
  str_element, DAS2, 'name', das2name, /add ; ds.name does not contain usefull information in this case
  str_element, DAS2, 'propds', mds, /add ; add data set property

  das2dlm_add_metadata, DAS2, p=pt, v=vt, m=mt, add='t'
  das2dlm_add_metadata, DAS2, p=py, v=vy, m=my, add='y'
  
  tvarname = 'cassini_mag_' + py.pdim
  store_data, tvarname, data={x:dt, y:dy}
  options, /default, tvarname, 'colors', 0
  options, /default, tvarname, 'DAS2', DAS2 ; Store metadata (this should not affect graphics)
  options, /default, tvarname, 'title', DAS2.name ; custom title
  
  ytitle = py.pdim + ', ' + DAS2.units
  options, /default, tvarname, 'ytitle', ytitle ; Title from the properties

end