; $LastChangedBy: davin-mac $
; $LastChangedDate: 2019-03-27 11:40:06 -0700 (Wed, 27 Mar 2019) $
; $LastChangedRevision: 26918 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/ion/DEPRECATED/spp_swp_spanx_sweeps.pro $
;

function  spp_swp_spanx_sweeps,etable=etable,cal=cal,param=param,peakbin=peakbin

  if isa(param) then begin
    etable = param.etable
  ;  ptable = param.ptable
    cal    = param.cal
  endif

  ; this portion of code assumes  4 substeps, 8 deflectors and 32 energies  (ptable correponds to full distribution)
  ;  index = reform(etable.index,4,256)   ; full sweep

  substep_time = 0.873/4/256 /4  ; integration time of single substep   
  
  if isa(peakbin) then begin      ; targeted sweap
    tsindex = reform(etable.tsindex,256,256)
    index = [1,1,1,1] # reform(tsindex[*,peakbin])    
  endif else index = reform(etable.fsindex,4,256)  ; full sweep

  hem_dac = etable.hem_dac[index]
  def_dac = etable.def1_dac[index] - etable.def2_dac[index]
  spl_dac = etable.spl_dac[index]
  delt_dac = substep_time[index * 0]               ; time duration with same dimensions

  ; move from dacs to energy and defl  average over substeps
  
  defConvEst = 0.0025
  hemv  = float( hem_dac * cal.hem_scale * 4. / 2.^16  )   ;  approximate voltage,  average over substeps
  defv  = float( def_dac  * cal.defl_scale   )   ; approximate angle (degrees)
  splv  = float( spl_dac  * cal.spoil_scale * 4./2.^16  ) ;  approximate voltage
  delt = delt_dac
  rtime = findgen(4,256) * substep_time 
  
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
  
  
  ; ***************  Add in the anode dimension here  **********************
  new_dimen = [dimensions,n_anodes]   ; Ion data is generated differently from the electron data,   output is transposed  ( time , anode)  

  nrg_all = reform(hemv[*] # cal.k_anal ,new_dimen,/overwrite)     ; energy = k_anal * voltage on inner hemisphere
  defa_all = reform(defv[*] # cal.k_defl,new_dimen,/overwrite)    ;  this should be evaluated as a cubic spline in the future

  geomdt_all = reform(delt[*] # (cal.dphi *cal.geomfactor_full/360),new_dimen,/overwrite)
  
  anode_all = reform(replicate(1,nelem) # anodes ,new_dimen,/overwrite)

  geom_all = cal.dphi[anode_all] * cal.geomfactor_full / 360.
  phi_all  = cal.phi[anode_all]
  
  rtime_all = reform(rtime[*] # replicate(1,n_anodes),new_dimen)
  delt_all = reform(  delt[*] # replicate(1,n_anodes),new_dimen)
  
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
  fswp.rtime  = rtime_all
  fswp.theta = defa_all
  fswp.geom  = geom_all
  fswp.geomdt = geomdt_all
;  fswp.timesort = timesort_all
;  fswp.deflsort = deflsort_all
  return,fswp
end

