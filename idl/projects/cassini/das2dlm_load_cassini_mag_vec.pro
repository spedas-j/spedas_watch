;+
; PRO: das2dlm_load_cassini_mag_vec, ...
;
; Description:
;    Loads Cassini Magnetometer Vector values data using das2dlm library
;    dataset: Cassini/MAG/<dataset>
;
; Keywords:
;    trange: Sets the time tange
;    source (optional): String that defines dataset: 
;     'VectorSC' (default) - Magnetometer Data in Spacecraft Coordinates from http://mapsview.engin.umich.edu/;
;     'VectorKSO' - Magnetometer Vector values in Kronocentric Solar Orbital coordinates from PDS volume CO-E_SW_J_S-MAG-4-SUMM-1SECAVG-V1.0         
;    
; CREATED BY:
;    Alexander Drozdov (adrozdov@ucla.edu)
;
; $LastChangedBy: adrozdov $
; $Date: 2020-07-10 22:45:53 -0700 (Fri, 10 Jul 2020) $
; $Revision: 28878 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/cassini/das2dlm_load_cassini_mag_vec.pro $
;-

pro das2dlm_load_cassini_mag_vec, trange=trange, source=source
  
  das2dlm_cassini_init
  
  if undefined(source) $
  then source = 'VectorSC'
  
 case strlowcase(source) of
  'vectorsc': begin
      t_name = 'time'
      x_name = 'x'
      y_name = 'y'
      z_name = 'z'
      b_name = 'total'      
    end 
  'vectorkso': begin
    t_name = 'time'
    x_name = 'X'
    y_name = 'Y'
    z_name = 'Z'
    b_name = 'magnitude'    
    end
  else: begin
        dprint, dlevel = 0, 'Unknown source. Accepatable sources are: VectorSC or VectorKSC'
        return    
        end    
 endcase
      
  if ~undefined(trange) && n_elements(trange) eq 2 $
   then tr = timerange(trange) $
   else tr = timerange()
       
  
  time_format = 'YYYY-MM-DDThh:mm:ss'
  
  ; todo: validate dataset
  
  url = 'http://planet.physics.uiowa.edu/das/das2Server?server=dataset'
  dataset = 'dataset=Cassini/MAG/' + source
  time1 = 'start_time=' + time_string( tr[0] , tformat=time_format)
  time2 = 'end_time=' + time_string( tr[1] , tformat=time_format)

  requestUrl = url + '&' + dataset + '&' + time1 + '&' + time2
  print, requestUrl

  query = das2c_readhttp(requestUrl)
  
  ; Get dataset
  ds = das2c_datasets(query)
  
  ; Get variables dimentions
  das2dlm_get_ds_var, ds, t_name, 'center', p=pt, v=vt, m=mt, d=dt  
  das2dlm_get_ds_var, ds, x_name, 'center', p=px, v=vx, m=mx, d=dx
  das2dlm_get_ds_var, ds, y_name, 'center', p=py, v=vy, m=my, d=dy
  das2dlm_get_ds_var, ds, z_name, 'center', p=pz, v=vz, m=mz, d=dz
  das2dlm_get_ds_var, ds, b_name, 'center', p=pb, v=vb, m=mb, d=db
    
  case strlowcase(vt.units) of
    'us2000': dt = das2dlm_us2000_to_unixtime(dt) ; convert time
    't2000': dt = das2dlm_t2000_to_unixtime(dt) ; convert time
  endcase
      
     
  ; Metadata
  str_element, DAS2, 'url', requestUrl, /add
  str_element, DAS2, 'name', source, /add ; ds.name does not contain usefull information in this case
  
  das2dlm_add_metadata, DAS2, p=pt, v=vt, m=mt, add='t'
  das2dlm_add_metadata, DAS2, p=px, v=vx, m=mx, add='x'
  das2dlm_add_metadata, DAS2, p=py, v=vy, m=my, add='y'
  das2dlm_add_metadata, DAS2, p=pz, v=vz, m=mz, add='z'
  
  ; Components variable 
  tvarname = 'cassini_mag_' + source
  store_data, tvarname, data={x:dt, y:[[dx], [dy], [dz]]}
  options, /default, tvarname, 'colors', ['r', 'g', 'b'] ; multiple colors  
  options, /default, tvarname, 'DAS2', DAS2 ; Store metadata (this should not affect graphics)  
  options, /default, tvarname, 'title', 'Magnetometer Vector' ; custom title
  
  ; Data Label
  ytitle = source + ', ' + DAS2.unitsx
  ; str_element, my[0], 'key', success=s
  ; if s eq 1 then str_element, my[0], 'value', ytitle    
  options, /default, tvarname, 'ytitle', ytitle ; Title from the properties
  
  ; Total variable 
    tvarname = 'cassini_mag_' + source + '_ave'
    store_data, tvarname, data={x:dt, y:db}
    options, /default, tvarname, 'colors', 0
    DAS2 = [] 
    ; Metadata
    str_element, DAS2, 'url', requestUrl, /add
    str_element, DAS2, 'name', source, /add ; ds.name does not contain usefull information in this case

    das2dlm_add_metadata, DAS2, p=pt, v=vt, m=mt, add='t'
    das2dlm_add_metadata, DAS2, p=pb, v=vb, m=mb ; no postfix
        
    options, /default, tvarname, 'DAS2', DAS2 ; Store metadata (this should not affect graphics)
    options, /default, tvarname, 'title', 'Magnetometer Vector' ; custom title
    ytitle = source + ', ' + DAS2.units
    options, /default, tvarname, 'ytitle', ytitle ; Title from the properties
    
  ; TODO: add check on null

end