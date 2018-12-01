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

;  max = 65536.

  if ~ isa(sensor)  then sensor  = 0
  if ~ isa(emode)  then emode  = 0
  if ~ isa(k)       then k       = 16.7
  if ~ isa(rmax)    then rmax    = 11.0
  if ~ isa(vmax)    then vmax    = 4000
  if ~ isa(nen)     then nen     = 128
  if ~ isa(spfac)   then spfac   = 0.
  if ~ isa(maxspen) then maxspen = 5000.
  if ~ isa(hvgain)  then hvgain  = 1000.
  if ~ isa(spgain)  then spgain  = 20.12
  if ~ isa(fixgain) then fixgain = 13.


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
   
;   if keyword_set(spane) then begin
;    hvgain = 500.
;    sensor = spane
;   endif
;   if n_elements(spfac) eq 0  then spfac = 0.
;   if n_elements(emode) eq 0  then emode = 0
;   

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
   
   if 1 then begin
     timesort = indgen(8*32)
     defsort = indgen(8,2,16)
     for i = 0,15 do defsort[*,1,i] = reverse(defsort[*,1,i])           ; reverse direction of every other deflector sweep
     defsort = reform(defsort,8,32)                                       ; defsort will reorder data so that it is no longer in time order - but deflector values are regular    
   endif else begin
     timesort = indgen(4,8*32)
     defsort = indgen(4*8,2,16)
     for i = 0,15 do defsort[*,1,i] = reverse(defsort[*,1,i])           ; reverse direction of every other deflector sweep
     defsort = reform(defsort,4,8,32)                                       ; defsort will reorder data so that it is no longer in time order - but deflector values are regular
   endelse

   

   if total(/pres,(defv1_dac ne 0) and (defv2_dac ne 0)) then message,'Bad deflector sweep table'


   ;; -------- Structure with values ----------
   table = { emode:emode, $
             sensor:sensor, $
             sweepv_dac:sweepv_dac,$
             defv1_dac:defv1_dac,$
             defv2_dac:defv2_dac,$
             spv_dac:spv_dac,$
             fsindex: reform(fsindex,4,256),$
             tsindex: reform(tsindex,256,256),$
             timesort: timesort,  $
             deflsort:  defsort,   $
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
