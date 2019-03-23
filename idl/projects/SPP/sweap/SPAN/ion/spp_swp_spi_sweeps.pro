;+
;
; SPP_SWP_SPI_SWEEPS
;
; PUPORSE:
;
; EXAMPLE:
;
; $LastChangedBy: rlivi2 $
; $LastChangedDate: 2019-03-22 10:29:40 -0700 (Fri, 22 Mar 2019) $
; $LastChangedRevision: 26879 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/ion/spp_swp_spi_sweeps.pro $
;
;-

FUNCTION  spp_swp_spi_sweeps, etable=etable,$
                              ptable=ptable,$
                              cal=cal,$
                              peakbin=peakbin,$
                              param=param

   IF isa(param) THEN BEGIN
      etable = param.etable
      ptable = param.ptable
      cal    = param.cal
   ENDIF

   ;; This portion of code assumes:
   ;;   -  4 substeps
   ;;   -  8 deflectors
   ;;   - 32 energies
   ;; (ptable correponds to full distribution)
   ;;index = reform(etable.index,4,256)   ; full sweep
   substep_time = 0.873/4/256 /4 ; integration time of single substep   
  
   ;; Targeted Sweep
   IF isa(peakbin) THEN BEGIN   
      tsindex = reform(etable.tsindex,256,256)
      index = [1,1,1,1] # reform(tsindex[*,peakbin])    
   endif else index = reform(etable.fsindex,4,256) ;; Full Sweep

   ;; DACS
   hemv_dac  = etable.sweepv_dac[index]  
   defv_dac  = etable.defv1_dac[index]  -  etable.defv2_dac[index]  
   splv_dac  = etable.spv_dac[index]
   
   ;; Time duration with same dimensions
   delt_dac  = substep_time[index * 0] 
   
   ;; DACS to Energy and defl averaged over substeps
   
   defConvEst = 0.0025
   ;; Approximate voltage averaged over substeps
   hemv = float(hemv_dac*cal.hem_scale*4./2.^16)
   ;; Approximate angle (degrees)
   defv = float(defv_dac*cal.defl_scale) 
   ;; Approximate voltage
   splv = float(splv_dac*cal.spoil_scale*4./2.^16)


   delt = delt_dac
  
   IF 0 THEN BEGIN
    hemv = average(hemv ,1 ) ;; Average over substeps
    defv = average(defv ,1 ) ;; Average of theta
    splv = average(splv ,1 ) ;; Average over substeps
    delt = total(delt,1)     ;; Integration time    
  endif

   ;; Increase dimension for anodes
   n_anodes = cal.n_anodes
   anodes = indgen(n_anodes)
   dimensions = size(/dimen,hemv)
   nelem = n_elements(hemv)
   new_dimen = [n_anodes,dimensions]

   ;; energy = k_anal * voltage on inner hemisphere
   nrg_all = reform(cal.k_anal # hemv[*],new_dimen,/overwrite)     

   ;; This should be evaluated as a cubic spline in the future
   defa_all = reform(cal.k_defl # defv[*],new_dimen,/overwrite)    
   geomdt_all = reform(cal.dphi # delt[*],new_dimen,/overwrite)
   anode_all = reform(anodes # replicate(1,nelem),new_dimen,/overwrite)
   geom_all = cal.dphi[anode_all]
   phi_all  = cal.phi[anode_all]
   delt_all = reform( replicate(1,n_anodes) # delt[*],new_dimen)
   timesort = etable.timesort
   deflsort = etable.deflsort
   timesort_all = replicate(1,n_anodes) # timesort[*]*n_anodes + $
                  indgen(n_anodes) # replicate(1,nelem) 
   timesort_all = reform( timesort_all, $
                          [n_anodes,size(/dimensions,timesort)],$
                          /overwrite)

   ;; Data varies with anode
   deflsort_all = replicate(1,n_anodes) # deflsort[*]*n_anodes + $
                  indgen(n_anodes) # replicate(1,nelem) 
   deflsort_all = reform(deflsort_all,$
                         [n_anodes,size(/dimensions,deflsort)],$
                         /overwrite)


   ;; Full Sweep Dictionary
   fswp = dictionary()          

   ;;fswp.cal = cal
   fswp.anode    = anode_all
   fswp.energy   = nrg_all
   fswp.phi      = phi_all
   fswp.delt     = delt_all
   fswp.theta    = defa_all
   fswp.geom     = geom_all
   fswp.geomdt   = geomdt_all
   fswp.timesort = timesort_all
   fswp.deflsort = deflsort_all
   return,fswp

END 


;;timesort= indgen(16,8,32)
;;defsort = indgen(8,2,16)
;; Reverse direction of every other deflector sweep
;;if not keyword_set(timesort_flag) then $
;; for i = 0,15 do $
;;  defsort[*,1,i] = reverse(defsort[*,1,i]) 
;; defsort will reorder data so that it is no longer in time order
;; But deflector values are regular
;;defsort = reform(defsort,8,32)                                       
;; Data varies with anode
;;datsort = reform( replicate(1,16) # defsort[*]*16 , 16,8,32 ) + $
;;          reform( indgen(16) # replicate(1,8*32) , 16,8,32 )

