function spp_swp_spanx_tables,erange,spfac=spfac, emode=emode, spane=spane

   ;; Initiate Table Constants
   nen=128
   emin=5.0
   emax=4000.
   k=16.7
   rmax=11.0
   vmax=4000
   maxspen=5000.
   hvgain=1000.
   spgain=20.12
   fixgain=13.
   sensor= 0
   
   if keyword_set(spane) then begin
    hvgain = 500.
    sensor = spane
   endif
   if n_elements(spfac) eq 0  then spfac = 0.
   if n_elements(emode) eq 0  then emode = 0
   
   emin = erange[0]
   emax = erange[1]



   ;; --------------- DACS --------------------
   spp_swp_sweepv_dacv, $
    sweepv_dac,defv1_dac,defv2_dac,spv_dac,$
    k=k, rmax=rmax,vmax=vmax,nen=nen,e0=emin,$
    emax=emax,spfac=spfac,maxspen=maxspen,$
    hvgain=hvgain,spgain=spgain,fixgain=fixgain

   ;; ------------ Full Index -----------------
   spp_swp_sweepv_new_fslut,$ 
    sweepv,defv1,defv2,spv,fsindex,$
    nen = nen/4,plot = plot,spfac = spfac


   ;; ---------- Targeted Index ---------------
   FOR i=0, 255 DO BEGIN
      spp_swp_sweepv_new_tslut, $
       sweepv,defv1,defv2,spv,fsindex_tmp,tsindex,$
       nen=nen,edpeak=edpeak,spfac=spfac
      IF i EQ 0 THEN index = tsindex $
      ELSE index = [index,tsindex]      
   ENDFOR
   tsindex = index

   ;; -------- Structure with values ----------
   table = { sensor:sensor, $
             emode:emode, $
             sweepv_dac:sweepv_dac,$
             defv1_dac:defv1_dac,$
             defv2_dac:defv2_dac,$
             spv_dac:spv_dac,$
             fsindex:fsindex,$
             tsindex:tsindex,$
             k:k,$
             rmax:rmax,$
             vmax:vmax,$
             nen:nen,$
             emin:emin,$
             emax:emax,$
             spfac:spfac,$
             maxspen:maxspen,$
             hvgain:hvgain,$
             spgain:spgain,$
             fixgain:fixgain }
   

return,table
END
