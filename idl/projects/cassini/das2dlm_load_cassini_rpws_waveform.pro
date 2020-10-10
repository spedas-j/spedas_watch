;+
; PRO: das2dlm_load_cassini_rpws_waveform, ...
;
; Description: Cassini data from Radio and Plasma Wave Science, waveformw (PSD level 3 filed), das2 dataset: /Cassini/RPWS/...; 
;   Available datasets:
;     'HiRes_LoFreq_Waveform' - Collection: 100 Hz and 7.14 kHz sample rate, correlated 5-Component waveforms from the WFR
;     'HiRes_MidFreq_Waveform' - Collection: 27.8 kHz and 222 kHz sample rate waveforms from the WBR (PDS level 3 files)
;            
; Keywords:
;    trange: Sets the time tange
;    source (optional): String that defines dataset: 'MidFreq', 'LoFreq' (default: 'LoFreq')             
;    resolution (optional): string of the resolution, e.g. '.21' (default, '')         
;    parameter (optional): string of optional das2 parameters  
;   
; CREATED BY:
;    Alexander Drozdov (adrozdov@ucla.edu)
;
; $LastChangedBy: adrozdov $
; $Date: 2020-10-09 17:22:43 -0700 (Fri, 09 Oct 2020) $
; $Revision: 29235 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/cassini/das2dlm_load_cassini_rpws_waveform.pro $
;-

pro das2dlm_load_cassini_rpws_waveform, trange=trange, source=source, resolution=resolution
  
  das2dlm_cassini_init
  
  if ~undefined(trange) && n_elements(trange) eq 2 $
   then tr = timerange(trange) $
   else tr = timerange()
      
   if undefined(source) $
     then source = 'LoFreq'
     
   case strlowcase(source) of
    'lofreq': begin
      source = 'HiRes_LoFreq_Waveform'
      t_name = 'time'
      v_name = 'Ex'  
      end 
    'midfreq': begin
      source = 'HiRes_MidFreq_Waveform'
      t_name = 'time'
      v_name = 'WBR'  
      end
      else: begin
       dprint, dlevel = 0, 'Unknown source. Accepatable sources are: LoFreq or MidFreq'
       return
      end
    endcase
    
    if undefined(parameter) then parameter = ''
    if parameter ne '' then parameter = '&params=' + parameter.Replace(' ','+')
     
   if undefined(resolution) $
     then resolution = ''
     
   if resolution ne '' $
    then resolution = '&resolution=' + resolution
  
  time_format = 'YYYY-MM-DDThh:mm:ss'
  
  url = 'http://planet.physics.uiowa.edu/das/das2Server?server=dataset'
  dataset = 'dataset=Cassini/RPWS/' + source
  time1 = 'start_time=' + time_string( tr[0] , tformat=time_format)
  time2 = 'end_time=' + time_string( tr[1] , tformat=time_format)

  requestUrl = url + '&' + dataset + '&' + time1 + '&' + time2 + resolution + parameter
  print, requestUrl

  query = das2c_readhttp(requestUrl)
  
  ; Get dataset
  nset = 0
  ds = das2c_datasets(query, nset)
  
  ; Get time
  das2dlm_get_ds_var, ds, 'time', 'center', p=pt, v=vt, m=mt, d=dt
  
  ; Exit on empty data
  if undefined(dt) then begin
    dprint, dlevel = 0, 'Dataset has no data for the selected period.'
    return
  endif
  
  ; Get variables
  das2dlm_get_ds_var, ds, v_name, 'center', p=pf, v=vf, m=mf, d=df
     
  ; Convert time
  dt = das2dlm_time_to_unixtime(dt, vt.units)
  
  ; Manually fix the dimentions according to variable's rank
  dt=dt[*]
  df=df[*]  
  ;dt = transpose(dt[0, *],[1, 0])  
  ;df = df[*, 0]
  ;da = transpose(da, [1, 0])
 
  tvarname = 'cassini_rpws_' + strlowcase(source)  + '_' + ds[0].name
  store_data, tvarname, data={x:dt, y:df}, $
    dlimits={spec:0, ylog:0, zlog:0} 
        
  ; Metadata
  das2dlm_get_ds_meta, ds[0], meta=mds, title=das2name
  
  str_element, DAS2, 'url', requestUrl, /add
  str_element, DAS2, 'name', das2name, /add
  str_element, DAS2, 'propds', mds, /add ; add data set property

  das2dlm_add_metadata, DAS2, p=pt, v=vt, m=mt, add='t'
  das2dlm_add_metadata, DAS2, p=pf, v=vf, m=mf, add='y' 
  
  options, /default, tvarname, 'DAS2', DAS2 ; Store metadata (this should not affect graphics)
  
  options, /default, tvarname, 'title', DAS2.name
  ; Data Label
  ytitle = DAS2.namey + ', ' + DAS2.unitsy
  options, /default, tvarname, 'ytitle', ytitle ;
  
  ; Cleaning up
  res = das2c_free(query)  
end