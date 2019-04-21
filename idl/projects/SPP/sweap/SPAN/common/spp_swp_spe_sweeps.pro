; $LastChangedBy: davin-mac $
; $LastChangedDate: 2019-04-19 18:29:55 -0700 (Fri, 19 Apr 2019) $
; $LastChangedRevision: 27051 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/common/spp_swp_spe_sweeps.pro $
;


;;----------------------------------------------
;; The gen L2 code calls this for params
function  spp_swp_spe_sweeps, param=param, data_struct=dat  



  etable = param.etable
  cal    = param.cal
  

  targeted =  (dat.apid and 2 ) ne 0      ; targeted apids have the 2 bit set.
  
  if targeted then begin      ; targeted sweap
    tsindex = reform(etable.tsindex,256,256)
    sweep_index = dat.peak_bin
    index = [1,1,1,1] # reform(tsindex[*,sweep_index])
  endif else begin
    sweep_index = -1
    index = reform(etable.fsindex,4,256)  ; full sweep
  endelse

  dprint,dlevel=3,'Generating sweeps for sweep_index:',sweep_index,'  Emode =',etable.emode, '  status_bits= ',dat.status_bits


;  if param.haskey('fullsweeps') then begin
;    if param.fullsweeps.haskey(peak_bin) then begin
;      fswp = param.fullsweeps[peak_bin]
;      if fswp.status_bits eq dati.status_bits
;      return, param.fullsweeps[peak_bin]
;    endif
;  endif else begin
;    param.fullsweep
;  endelse
  
;  if ~isa(spe_param_dict, 'dictionary')  then begin
;    spe_param_dict = dictionary()
;  endif


  ; this portion of code assumes  4 substeps, 8 deflectors and 32 energies  (ptable correponds to full distribution)
  ;  index = reform(etable.index,4,256)   ; full sweep



  substep_time = 0.873/4/256 /4  ; integration time of single substep

  hem_dac  = etable.hem_dac[index]  
  def_dac  = etable.def1_dac[index]  -  etable.def2_dac[index]  ; use this later to collect theta angles.
  spl_dac  = etable.spl_dac[index]
  delt_dac  = substep_time[index * 0]               ; time duration with same dimensions

  ; move from dacs to energy and defl  average over substeps
  
 ; defConvEst = 0.0025
  hemv  = float( hem_dac * cal.hem_scale * 4. / 2.^16  )   ;  approximate voltage,  average over substeps
  defv  = float( def_dac  * cal.defl_scale   )   ; approximate angle (degrees) ; ideally this is not used (direct dac - theta conversion)
  splv  = float( spl_dac  * cal.spoil_scale * 4./2.^16  ) ;  approximate voltage
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
 ; defa_all_old = reform(cal.k_defl # defv[*],new_dimen,/overwrite) * (-1.)   ;  this should be evaluated as a cubic spline in the future, flips for particle velocity direction not look direction
 ; if 1 then begin
    thetas =  func(def_dac,param = cal.defl_cal)  ; add minus sign to account for travel direction instead of look direction.
    defa_all = reform(cal.k_defl # thetas[*], new_dimen, /overwrite)    
 ; endif else begin
 ;   thetas = findgen(n_elements(def_dac))
 ;   for i=0,n_elements(def_dac)-1  do begin
 ;     thetas[i] = cal.deflut_ang[where(cal.deflut_dac eq def_dac[i])]
 ;   endfor
 ;   defa_all = reform(cal.k_defl # thetas, new_dimen, /overwrite)    
 ; endelse
  
  atten_code = ishft(dat.status_bits , -6) and 3   ; 0:undefined,  1:atten_out,   2: atten_in,   3: undefined
  geomfactor_full = cal.geomfactor_full / cal.MECH_ATTNXS[atten_code]
;  if atten_in then begin
;    dprint,dat.status_bits
;    geomfactor_full = geomfactor_full / cal.MECH_ATTNX
;  endif else begin
;    dprint,'atten_out',dat.status_bits
;  endelse

  geomdt_all = reform(cal.dphi # delt[*],new_dimen,/overwrite) * geomfactor_full / 360.
  
  anode_all = reform(anodes # replicate(1,nelem),new_dimen,/overwrite)

;  atten_factor = cal.atten_factor
  geom_all = cal.dphi[anode_all] * geomfactor_full / 360.
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
  fswp.sweep_index = sweep_index
  fswp.anode = anode_all
  fswp.energy = nrg_all
  fswp.phi    = phi_all
  fswp.delt   = delt_all
  fswp.theta = defa_all
  fswp.geom  = geom_all
  fswp.geomdt = geomdt_all
;  fswp.timesort = timesort_all
;  fswp.deflsort = deflsort_all
  fswp.targeted = targeted
  fswp.peak_bin = dat.peak_bin
  return,fswp
end


