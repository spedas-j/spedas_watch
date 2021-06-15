pro ta15b_crib

; Set time range

timespan,'2007-03-23',1,/day

; Load OMNI data

omni_load_data,varformat='*BY_GSM *BZ_GSM *flow_speed *proton_density *Pressure',/res5min

; Perform smoothing on 30-minute interval preceding each sample time

tsmooth_in_time,'OMNI_HRO_5min_BY_GSM',1800.0,/smooth_nans,/backward,newname='BY_smooth'
tsmooth_in_time,'OMNI_HRO_5min_BZ_GSM',1800.0,/smooth_nans,/backward,newname='BZ_smooth'
tsmooth_in_time,'OMNI_HRO_5min_flow_speed',1800.0,/smooth_nans,/backward,newname='flow_speed_smooth'
tsmooth_in_time,'OMNI_HRO_5min_Pressure',1800.0,/smooth_nans,/backward,newname='pdyn_smooth'
tsmooth_in_time,'OMNI_HRO_5min_proton_density',1800.0,/smooth_nans,/backward,newname='proton_density_smooth'
tomni2bindex,imf_by='BY_smooth',imf_bz='BZ_smooth',sw_speed='flow_speed_smooth',sw_prot_dens='proton_density_smooth',out_name='b_index'

tplot,'OMNI_HRO_5min_BY_GSM BY_smooth OMNI_HRO_5min_BZ_GSM BZ_smooth OMNI_HRO_5min_flow_speed flow_speed_smooth pdyn_smooth proton_density_smooth  b_index'

thm_load_state,probe='a',datatype='pos',coord='GSM'

tta15b,'tha_state_pos',pdyn='pdyn_smooth',yimf='BY_smooth',zimf='BZ_smooth',xind='b_index'
end