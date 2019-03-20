; $LastChangedBy: phyllisw2 $
; $LastChangedDate: 2019-03-19 17:20:53 -0700 (Tue, 19 Mar 2019) $
; $LastChangedRevision: 26858 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/common/spp_swp_spe_sweeps.pro $
;


;;----------------------------------------------
;; The gen L2 code calls this for params
function  spp_swp_spe_sweeps,etable=etable,ptable=ptable,cal=cal,peakbin=peakbin,param=param

;message,'Old routine',/cont

  if isa(param) then begin
    etable = param.etable
    ptable = param.ptable
    cal    = param.cal
    status = param.stat
  endif

  ; this portion of code assumes  4 substeps, 8 deflectors and 32 energies  (ptable correponds to full distribution)
  ;  index = reform(etable.index,4,256)   ; full sweep

  substep_time = 0.873/4/256 /4  ; integration time of single substep   
  
  if isa(peakbin) then begin      ; targeted sweap
    tsindex = reform(etable.tsindex,256,256)
    index = [1,1,1,1] # reform(tsindex[*,peakbin])    
  endif else index = reform(etable.fsindex,4,256)  ; full sweep

  hemv_dac  = etable.sweepv_dac[index]  
  defv_dac  = etable.defv1_dac[index]  -  etable.defv2_dac[index]  ; use this later to collect theta angles.
  splv_dac  = etable.spv_dac[index]
  delt_dac  = substep_time[index * 0]               ; time duration with same dimensions

  ; move from dacs to energy and defl  average over substeps
  
  defConvEst = 0.0025
  hemv  = float( hemv_dac * cal.hem_scale * 4. / 2.^16  )   ;  approximate voltage,  average over substeps
  defv  = float( defv_dac  * cal.defl_scale   )   ; approximate angle (degrees) ; ideally this is not used (direct dac - theta conversion)
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
  
  ;def_angs = 

  nrg_all = reform(cal.k_anal # hemv[*],new_dimen,/overwrite)     ; energy = k_anal * voltage on inner hemisphere
  defa_all_old = reform(cal.k_defl # defv[*],new_dimen,/overwrite) * (-1.)   ;  this should be evaluated as a cubic spline in the future, flips for particle velocity direction not look direction
  thetas = findgen(n_elements(defv_dac))
  for i=0,n_elements(defv_dac)-1  do begin
    thetas[i] = cal.deflut_ang[where(cal.deflut_dac eq defv_dac[i])]
  endfor
  defa_all = reform(cal.k_defl # thetas, new_dimen, /overwrite)

  geomdt_all = reform(cal.dphi # delt[*],new_dimen,/overwrite)
  
  anode_all = reform(anodes # replicate(1,nelem),new_dimen,/overwrite)

  geom_all = cal.dphi[anode_all] / 360.
  phi_all  = cal.phi[anode_all]
  
  delt_all = reform( replicate(1,n_anodes) # delt[*],new_dimen)
  
  timesort = etable.timesort
  deflsort = etable.deflsort
  
  timesort_all =  replicate(1,n_anodes) # timesort[*]*n_anodes  + indgen(n_anodes) # replicate(1,nelem) 
  timesort_all =  reform( timesort_all , [n_anodes,size(/dimensions,timesort)],  /overwrite)
  deflsort_all =  replicate(1,n_anodes) # deflsort[*]*n_anodes  + indgen(n_anodes) # replicate(1,nelem)                ; data varies with anode
  deflsort_all =  reform( deflsort_all , [n_anodes,size(/dimensions,deflsort)],  /overwrite)

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
  fswp.timesort = timesort_all
  fswp.deflsort = deflsort_all
  return,fswp
end


