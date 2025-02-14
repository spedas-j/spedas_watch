;swfo_test
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2025-01-17 04:27:14 -0800 (Fri, 17 Jan 2025) $
; $LastChangedRevision: 33069 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu:36867/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_ccsds_frame_read_crib.pro $



if 1 || ~keyword_set(files) then begin

  run_proc = 1

  ;stop
  
  
  
  files = '/Users/davin/Downloads/stis_e2e4_rfr_realtime.bin'

  hexprint,files
  
  stop



  if ~isa(rdr) then begin
    swfo_stis_apdat_init,/save_flag
    rdr = ccsds_reader(/no_widget,verbose=verbose,run_proc=run_proc)
    !p.charsize = 1.2
  endif


endif

rdr.file_read,files





swfo_apdat_info,/create_tplot_vars,/all;,/print  ;  ,verbose=0

if 0 then begin

  swfo_apdat_info,/print,/all


  printdat,rdr.dyndata.array
  wi,2
  swfo_frame_header_plot, rdr.dyndata.array

  stop




  swfo_stis_tplot,/set
  tplot,'*SEQN *SEQN_DELTA',trange=trange

  stop
  swfo_apdat_info,/sort,/all,/print
  delta_data,'*SEQN',modulo=2^14
  options,'*_delta',psym=-1,symsize=.4,yrange=[-10,10]


  tplot,'*SEQN *SEQN_delta'

  stop
  ;swfo_apdat_info,/make_ncdf,trange=time_double(trange),file_resolution=1800d

endif

swfo_stis_tplot,'cpt2',/set

end
