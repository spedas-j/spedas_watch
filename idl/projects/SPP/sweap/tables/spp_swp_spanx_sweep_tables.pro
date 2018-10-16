function spp_swp_spanx_sweep_tables,erange, deflrange,  $
    plot = plot,$
    emode=emode, sensor=sensor,  $
    k = k,$
    rmax = rmax,$
    vmax = vmax,$
    nen = nen,$
;    e0 = e0,$
;    emax = emax,$
    spfac = spfac,$
    maxspen = maxspen,$
    hvgain = hvgain,$
    spgain = spgain,$
    fixgain = fixgain

  max = 65536.

  if not keyword_set(sensor)  then sensor  = 0
  if not keyword_set(emode)  then emode  = 0
  if not keyword_set(k)       then k       = 16.7
  if not keyword_set(rmax)    then rmax    = 11.0
  if not keyword_set(vmax)    then vmax    = 4000
  if not keyword_set(nen)     then nen     = 128
;  if not keyword_set(e0)      then e0      = 5.0
;  if not keyword_set(emax)    then emax    = 20000.
  if not keyword_set(spfac)   then spfac   = 0.
  if not keyword_set(maxspen) then maxspen = 5000.
  if not keyword_set(hvgain)  then hvgain  = 1000.
  if not keyword_set(spgain)  then spgain  = 20.12
  if not keyword_set(fixgain) then fixgain = 13.


;   ;; Initiate Table Constants
;   nen=128
;   emin=5.0
;   emax=4000.
;   k=16.7
;   rmax=11.0
;   vmax=4000
;   maxspen=5000.
;   hvgain=1000.
;   spgain=20.12
;   fixgain=13.
;   sensor= 0
   
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

   if total(/pres,(defv1_dac ne 0) and (defv2_dac ne 0)) then message,'Bad deflector sweep table'


   ;; -------- Structure with values ----------
   table = { emode:emode, $
             sensor:sensor, $
             sweepv_dac:sweepv_dac,$
             defv1_dac:defv1_dac,$
             defv2_dac:defv2_dac,$
             spv_dac:spv_dac,$
             fsindex:fsindex,$
             tsindex:tsindex,$
             emin:emin,$
             emax:emax,$
             k:k,$
             rmax:rmax,$
             vmax:vmax,$
             nen:nen,$
             spfac:spfac,$
             maxspen:maxspen,$
             hvgain:hvgain,$
             spgain:spgain,$
             fixgain:fixgain }
   

return,table
END
