; $LastChangedBy: mdmcmanus $
; $LastChangedDate: 2019-03-21 13:09:47 -0700 (Thu, 21 Mar 2019) $
; $LastChangedRevision: 26873 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/ion/DEPRECATED/spp_swp_spanx_sweeps.pro $
;

function  spp_swp_spanx_sweeps,etable=etable,ptable=ptable,cal=cal,peakbin=peakbin,param=param

  if isa(param) then begin
    etable = param.etable
    ptable = param.ptable
    cal    = param.cal
  endif

  ; this portion of code assumes  4 substeps, 8 deflectors and 32 energies  (ptable correponds to full distribution)
  ;  index = reform(etable.index,4,256)   ; full sweep

  substep_time = 0.873/4/256 /4  ; integration time of single substep   
  
  if isa(peakbin) then begin      ; targeted sweap
    tsindex = reform(etable.tsindex,256,256)
    index = [1,1,1,1] # reform(tsindex[*,peakbin])    
  endif else index = reform(etable.fsindex,4,256)  ; full sweep

  hemv_dac = etable.hem_dac[index]
  defv_dac = etable.def1_dac[index] - etable.def2_dac[index]
  splv_dac = etable.spl_dac[index]
  delt_dac = substep_time[index * 0]               ; time duration with same dimensions

  ; move from dacs to energy and defl  average over substeps
  
  defConvEst = 0.0025
  hemv  = float( hemv_dac * cal.hem_scale * 4. / 2.^16  )   ;  approximate voltage,  average over substeps
  defv  = float( defv_dac  * cal.defl_scale   )   ; approximate angle (degrees)
  splv  = float( splv_dac  * cal.spoil_scale * 4./2.^16  ) ;  approximate voltage
  delt = delt_dac
  
  if 0 then begin
    hemv  = average(hemv ,1 )   ;    average over substeps
    defv  = average(defv ,1 )   ; average of theta
    splv  = average(splv ,1 ) ;  average over substeps
    delt = total(delt,1)  ; integration time    
  endif

; Increase dimension for anodes

  n_anodes = cal.n_anodes
  anodes = indgen(n_anodes)

  dimensions = size(/dimen,hemv)
  nelem = n_elements(hemv)
  new_dimen = [n_anodes,dimensions]

  nrg_all = reform(cal.k_anal # hemv[*],new_dimen,/overwrite)     ; energy = k_anal * voltage on inner hemisphere
  defa_all = reform(cal.k_defl # defv[*],new_dimen,/overwrite)    ;  this should be evaluated as a cubic spline in the future

  geomdt_all = reform(cal.dphi # delt[*],new_dimen,/overwrite)
  
  anode_all = reform(anodes # replicate(1,nelem),new_dimen,/overwrite)

  geom_all = cal.dphi[anode_all]
  phi_all  = cal.phi[anode_all]
  
  delt_all = reform( replicate(1,n_anodes) # delt[*],new_dimen)
  
;  timesort = etable.timesort
;  deflsort = etable.deflsort
  
;  timesort_all =  replicate(1,n_anodes) # timesort[*]*n_anodes  + indgen(n_anodes) # replicate(1,nelem) 
;  timesort_all =  reform( timesort_all , [n_anodes,size(/dimensions,timesort)],  /overwrite)
;  deflsort_all =  replicate(1,n_anodes) # deflsort[*]*n_anodes  + indgen(n_anodes) # replicate(1,nelem)                ; data varies with anode
;  deflsort_all =  reform( deflsort_all , [n_anodes,size(/dimensions,deflsort)],  /overwrite)

;  timesort= indgen(16,8,32)
;
;  defsort = indgen(8,2,16)
;  if not keyword_set(timesort_flag) then for i = 0,15 do defsort[*,1,i] = reverse(defsort[*,1,i])           ; reverse direction of every other deflector sweep
;  defsort = reform(defsort,8,32)                                       ; defsort will reorder data so that it is no longer in time order - but deflector values are regular
;  datsort = reform( replicate(1,16) # defsort[*]*16 , 16,8,32 ) + reform( indgen(16) # replicate(1,8*32) , 16,8,32 )                ; data varies with anode


  fswp = dictionary()          ; full sweep dictionary
;  fswp.cal = cal
  fswp.anode = anode_all
  fswp.energy = nrg_all
  fswp.phi    = phi_all
  fswp.delt   = delt_all
  fswp.theta = defa_all
  fswp.geom  = geom_all
  fswp.geomdt = geomdt_all
;  fswp.timesort = timesort_all
;  fswp.deflsort = deflsort_all
  return,fswp
end


