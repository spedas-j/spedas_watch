;swfo_stis_ar_crib.pro
;

station = 'S2'
trange = ['23 7 26 4','23 7 26 5']
trange = ['23 7 27 4','23 7 27 24']    ; Calibration with ion gun
trange = ['23 7 27 17 ','23 7 27 19']  & station='S2'   ; High flux ions from calibration
trange = ['23 6 1','23 6 1 4']  & station='S0'     ; 1/r^2 test with x-ray source
stop


if 0 then begin
  ;swfo_stis_load,station = 'S2',trange=trange ,reader=rdr,no_widget=1,file='cmblk'
  swfo_stis_load,station = 'S0',trange=trange,reader=rdr,no_widget=1,file='cmblk'
  
endif else begin

  swfo_stis_apdat_init,/save_flag

  no_download = 0    ;set to 1 to prevent download from the web
  no_update = 0      ; set to 1 to prevent checking for updates

  source = {$
    remote_data_dir:'http://sprg.ssl.berkeley.edu/data/', $
    master_file: 'swfo/.master', $
    no_update : no_update ,$
    no_download :no_download ,$
    resolution: 3600L  }

  ;pathname = 'swfo/data/sci/stis/prelaunch/realtime/S2/gsemsg/YYYY/MM/DD/swfo_stis_socket_YYYYMMDD_hh.dat.gz'     
  ;pathname = 'swfo/data/sci/stis/prelaunch/realtime/S2/cmblk/YYYY/MM/DD/swfo_stis_cmblk_YYYYMMDD_hh.dat.gz'
  pathname = 'swfo/data/sci/stis/prelaunch/realtime/'+station+'/cmblk/YYYY/MM/DD/swfo_stis_cmblk_YYYYMMDD_hh.dat.gz'

  files = file_retrieve(pathname,_extra=source,trange=trange)
  ;w=where(file_test(files),/null)
  ;files = files[w]
  
  
  ;rdr = gsemsg_reader(mission='SWFO',/no_widget,verbose=verbose,run_proc=run_proc)
  rdr = cmblk_reader(mission='SWFO',/no_widget,verbose=verbose,run_proc=run_proc)
  rdr.add_handler, 'raw_tlm',  gsemsg_reader(name='SWFO_reader',/no_widget,mission='SWFO')
  rdr.add_handler, 'raw_ball', ccsds_reader(/no_widget,name='BALL_reader' , sync_pattern = ['2b'xb,  'ad'xb ,'ca'xb, 'fe'xb], sync_mask= [0xef,0xff,0xff,0xff] )


  rdr.file_read,files
  
  swfo_apdat_info,/print,/all,/create_tplot_var
  tplot_names
endelse

swfo_stis_plot,param=param
printdat,param.lim
param.range = 10

sciobj = swfo_apdat('stis_sci')    ; This gets the object that contains all science products
level_0b_da = sciobj.getattr('level_0b')  ; this a (dynamic) array of structures that contain all level_0B data
level_1A_da = sciobj.getattr('level_1a')
level_1b_da = sciobj.getattr('level_1b')


;Additional examples of how to extract data from the object and then recompute the data

level_0b_structs = level_0b_da.array
level_1a_structs =   swfo_stis_sci_level_1a(level_0b_structs)
level_1b_structs =   swfo_stis_sci_level_1a(level_1a_structs)



swfo_stis_tplot,/set,'dl1'
swfo_stis_tplot,/set,'iongun',/add


ctime,/silent,t,routine_name="swfo_stis_plot"


end
