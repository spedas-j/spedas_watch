
pro misc2
  spp_apid_data,'36E'x,apdata=hkp
  s=hkp.dataptr
  def = (*s).acc_dac * sign((*s).adc_vmon_def1 - (*s).adc_vmon_def2)
  store_data,'DEF1-DEF2',(*s).time,float(def)

end



pro spane_center_energy,tranges=tt,emid=emid,ntot=ntot

  channels = [3,2,1,0,8,9,10,11,12,13,14,15,7,6,5,4]
  rotation = [-108.,-84,-60,-36,-21,-15,-9,-3,3.,9,15,21,36,60,84,108]
  emid = replicate(0.,16)
  ntot = replicate(0.,16)
  xlim,lim,4500,5500
  
  for i=0,15 do begin
    trange=tt[*,i]
    scat_plot,'spp_spane_hkp_ACC_DAC','spp_spane_spec_CNTS2',trange=trange,lim=lim,xvalue=x,yvalue=y,ydimen= channels[i]
    ntot[i] = total(y)
    emid[i] = total(x*y)/total(y)
  endfor

;  Emid = [5070, 5107, 5112,

end


pro spane_deflector_scan,tranges = trange
    scat_plot,/swap_interp,'DEF1-DEF2','spp_spane_spec_CNTS2',trange=trange,lim=lim,xvalue=x,yvalue=y,ydimen= 4
end


pro spane_threshold_scan,tranges=trange,lim=lim
  swap_interp=0
  xlim,lim,0,512
  ylim,lim,10,10000,1
  options,lim,psym=4  
  scat_plot,swap_interp=swap_interp,'spp_spane_hkp_ACC_DAC','spp_spane_spec_CNTS2',trange=trange[*,1],lim=lim,xvalue=x,yvalue=y,ydimen= 4;,color=4
  scat_plot,swap_interp=swap_interp,'spp_spane_hkp_ACC_DAC','spp_spane_spec_CNTS2',trange=trange[*,0],lim=lim,xvalue=x,yvalue=y,ydimen= 4,color=6,/overplot
  scat_plot,swap_interp=swap_interp,'spp_spane_hkp_ACC_DAC','spp_spane_spec_CNTS2',trange=trange[*,2],lim=lim,xvalue=x,yvalue=y,ydimen= 4,color=2,/overplot
end


pro spane_threshold_scan_phd,tranges=trange,lim=lim
  
  if ~keyword_set(trange) then ctime,trange,npo=2
  swap_interp=0
  xlim,lim,0,550
  ylim,lim,10,5000,1
  options,lim,psym=4
  scat_plot,swap_interp=swap_interp,'spp_spane_hkp_ACC_DAC','spp_spane_p1_CNTS',trange=trange,lim=lim,xvalue=dac,yvalue=cnts,ydimen= 4;,color=4
  range = [80,500]
  xp = dgen(8,range=range)
  yp = xp*0+500
  xv = dgen()
  !p.multi = [0,1,2]
  yv = spline_fit3(xv,xp,yp,param=p,/ylog)
  fit,dac,cnts,param=p
  pf,p,/over
 ; wi,2
  plot,dac,cnts,psym=4,xtitle='Threshold DAC level',ytitle='Counts'
  ;pf,p,/over
  plt1 = get_plot_state()
  xv = dgen(range=range)
;  wi,3
  plot,xv,-deriv(xv,func(xv,param=p)),xtitle='Threshold DAC level',ytitle='PHD'
  plt2= get_plot_state()
  
end




f= spp_file_retrieve( 'spp/data/sci/sweap/prelaunch/gsedata/EM/z320/20160331_125002_/PTP_data.dat' )
f= spp_file_retrieve( 'spp/data/sci/sweap/prelaunch/gsedata/EM/mgsehires1/20160801_092658_flightToFlight_contd/PTP_data.dat' )


;files = spp_swp_spane_functiontest1_files()

files = f

spp_swp_startup



spp_ptp_file_read, spp_file_retrieve( 'spp/data/sci/sweap/prelaunch/gsedata/EM/mgsehires1/20160729_150358_FLTAE_digital/PTP_data.dat' )

spp_ptp_file_read, spp_file_retrieve( 'spp/data/sci/sweap/prelaunch/gsedata/EM/mgsehires1/20160801_092658_flightToFlight_contd/PTP_data.dat' )
spp_msg_file_read, spp_file_retrieve( 'spp/data/sci/sweap/prelaunch/gsedata/EM/mgsehires1/20160801_092658_flightToFlight_contd/GSE_all_msg.dat' )
spp_ptp_file_read, spp_file_retrieve( 'spp/data/sci/sweap/prelaunch/gsedata/EM/mgsehires1/20160802_081922_flightToFlight_contd2/PTP_data.dat' )
spp_msg_file_read, spp_file_retrieve( 'spp/data/sci/sweap/prelaunch/gsedata/EM/mgsehires1/20160802_081922_flightToFlight_contd2/GSE_all_msg.dat' )


spp_ptp_file_read, spp_file_retrieve( 'spp/data/sci/sweap/prelaunch/gsedata/EM/SWEAP-2/20160727_115654_large_packet_test/PTP_data.dat')
spp_msg_file_read, spp_file_retrieve( 'spp/data/sci/sweap/prelaunch/gsedata/EM/SWEAP-2/20160727_115654_large_packet_test/GSE_all_msg.dat')

spp_msg_file_read, spp_file_retrieve( 'spp/data/sci/sweap/prelaunch/gsedata/EM/SWEAP-2/20160805_125639_ramp_up/GSE_all_msg.dat')  ; Ion ramp in which SWEMULATOR reset?


spp_ptp_file_read, spp_file_retrieve('spp/data/sci/sweap/prelaunch/gsedata/EM/SWEAP-3/20160920_084426_BfltBigCalChamberEAscan/PTP_data.dat.gz')

spp_ptp_file_read, spp_file_retrieve('spp/data/sci/sweap/prelaunch/gsedata/EM/SWEAP-3/20160923_165136_BfltContinuedPHDscan/PTP_data.dat')

;   spane B flight CO pre conformal coat
files = spp_file_retrieve(/elec,/cal,trange=['2016 9 28 12','2016 9 29 8']) 




 trange =  '2016 10 '+ ['18/04','19/22']   ; SPANE - A flght in Cal chamber:  MCP test
 
 files = spp_file_retrieve(/elec,/cal,trange=trange)



;  Get recent data files:
files = spp_file_retrieve(/elec,/cal,recent=1/24.)   ; get last 1 hour of data from server


; Read  (Load) files
spp_ptp_file_read,files


; Real time data collection:
spp_init_realtime,/spanea,/cal,/exec


tplot, 'manip',/add
spp_swp_tplot,/setlim
spp_swp_tplot,'SE'
spp_swp_tplot,'SE_hv'
spp_swp_tplot,'SE_lv'
spp_swp_tplot,'SE'


; print information on collected data
spp_apdat_info,/print



; get SPANE-A HKP data:
hkp = spp_apdat('36e'x)

hkp.help

hkp.print

printdat, hkp.strct

printdat, hkp.data

printdat, hkp.data.array

printdat, hkp.data.size

printdat, hkp.data.typename

printdat,  hkp.data.array[-1]








; Get info on 




tplot,'*CNTS *DCMD_REC *VMON_MCP *VMON_RAW *ACC*'


if 0 then begin
  tplot,'spp_spane_?_ar_????_p1*',/names
  
  
  
  
endif





if 1 then begin
  options,'spp_spane_spec_CNTS',spec=0,yrange=[.5,5000],ystyle=1,ylog=1,colors='mbcgdr'
  options,'spp_spane_spec_CNTS1',spec=0,yrange=[.5,5000],ystyle=1,ylog=1,colors='mbcgdr'
  options,'spp_spane_spec_CNTS2',spec=0,yrange=[.5,5000],ystyle=1,ylog=1,colors='mbcgdr'
endif else begin
  options,'spp_spane_spec_CNTS',spec=1,yrange=[-1,16],ylog=0,zrange=[1,500.],zlog=1,/no_interp
  options,'spp_spane_spec_CNTS1',spec=1,yrange=[-1,32],ylog=0,zrange=[1,500.],zlog=1,/no_interp
  options,'spp_spane_spec_CNTS2',spec=1,yrange=[-1,16],ylog=0,zrange=[1,500.],zlog=1,/no_interp
endelse


if 0 then begin
  tplot,'spp_spani_hkp_HEMI_CDI spp_manip_MROTPOS spp_spani_tof_TOF APID spp_spani_rates_VALID_CNTS
  tplot,'spp_spani_ar_full_p0_m?_*_SPEC2'
  tplot,'spp_spani_ar_full_p1_m?_*_SPEC2'
  
  
  store_data,'ALL_C',data='spp_*_C'
  store_data,'ALL_V',data='spp_*_V'
  store_data,'ALL_ERR_CNT',data='spp_*_ERR_CNT'
  store_data,'ALL_ERR',data='spp_*_ERR'
  store_data,'ALL_CMD_CNT',data='spp_*_CMDS_*'
  !y.style=3
  tplot_options,'ynozero',1
  
  tplot,'APID'
  tplot,'spp_*_TEMPS ALL_? *NYS*',/add
  tplot,'ALL_ERR_CNT',/add
  tplot,'ALL_ERR',/add
  tplot,'ALL_CMD_CNT',/add
  tplot,/add,'spp*hkp*ERR_CNT'
  tplot,/add,'spp_*_C'
;  tplot/
  
endif




end

