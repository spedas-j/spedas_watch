PRO spp_swp_spi_tables, table, modeid=modeid

   ;; Parse MODE ID
   IF ~keyword_set(modeid) THEN BEGIN
      print, 'MODEID not defined. Using default 0x0015'
      modeid = '15'x
   ENDIF 
   energy_id = (ishft(modeid,-4) and 15)
   tmode_id  = (ishft(modeid,-8) and 15)

   ;; Initiate Table Constants
   nen=128
   emin=5.0
   emax=4000.
   k=16.7
   rmax=11.0
   vmax=4000
   spfac=0.
   maxspen=5000.
   hvgain=1000.
   spgain=20.12
   fixgain=13.

   ;; Select Energy Table
   CASE energy_id OF
      ;; Science Tables 0x01
      '01'x: BEGIN
         emin  = 500.
         emax  = 2000.
         spfac = 0.15
      END
      ;; Science Tables 0x02
      '02'x: BEGIN
         emin  = 5.
         emax  = 1500.
         spfac = 0.15
      END
      ;; Science Tables 0x03
      '03'x: BEGIN
         emin  = 1500.
         emax  = 20000.
         spfac = 0.15
      END
      ;; Science Tables 0x04
      '04'x: BEGIN
         emin  = 5.
         emax  = 20000.
         spfac = 0.15
      END
   ENDCASE


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
   table = { sweepv_dac:sweepv_dac,$
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
   

END
