; $LastChangedBy: phyllisw2 $
; $LastChangedDate: 2019-03-01 15:45:11 -0800 (Fri, 01 Mar 2019) $
; $LastChangedRevision: 26737 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/electron/spp_swp_spe_param.pro $
;



;; ************************************************************
;; *************************** MAIN ***************************
;; ************************************************************


;usage:
; rswp = spp_swp_span_reduced_sweep(fullsweep=fswp,  ptable=spe.ptable)

function spp_swp_span_reduced_sweep,fullsweep=fswp,ptable=ptable

rswp = dictionary()

average_quants = ['energy','theta','phi','time']
total_quants = ['delt','geom','geomdt']

quantnames = [average_quants,total_quants]
normalize = [average_quants eq average_quants, total_quants eq '']

hist = ptable.hist
ri  = ptable.reverse_ind
substep_dim = 2


for q=0,n_elements(quantnames)-1  do begin
  qname = quantnames[q]
  if ~fswp.haskey(qname) then continue
  quant = fswp[qname]
  norm  = normalize[q] 
  if substep_dim ne 0 then begin
    qmin  = min(quant, dimen = substep_dim)
    qmax  = max(quant, dimen = substep_dim)
    qval = total(quant,substep_dim)
    if norm then  qval /= 4
  endif else begin
    qmin = quant
    qmax = quant
    qval = quant
  endelse
  rqarray = replicate(!values.f_nan,n_elements(hist) )
  for i = 0,n_elements(hist)-1 do begin
    if hist[i] eq 0 then continue
    ind0 = ri[i] 
    ind1 = ri[i+1]-1
    ind =  ri[ ind0 :ind1 ]
    rqval = total( qval[ ind ] ) 
    if norm then   rqval = rqval / hist[i] 
    rqarray[i] =rqval
  endfor
  rswp[qname] = rqarray
endfor

return,rswp
end



;  counts = counts(phi,theta,energy)
;  rate = counts / delt
;  eflux = counts / (geom # delt)
;  flux  = counts / (geom # delt) / energy
;  df    = counts / (geom # delt) / energy^2 * (m^2 /2)



; Usage:
; spe = spp_swp_spe_param(detname = 'SPA',emode = 21,pmode='ENERGY_32')
; fswp = spp_swp_span_sweeps(param = spe)


function spp_swp_spe_deflector_func, defangle   ; this is a temporary location for this function - It should be put in a calibration file
;this converts angles to deflector dacs.
;solve for all possible combinations of deflector DAC and just make a lookup table.
   common spp_swp_spe_deflector_com, par
   
   if ~keyword_set(par) then begin
      par = polycurve2(order=5)
      par.a[0] = -1396.73d
      par.a[1] = 539.083d
      par.a[2] = 0.802293d
      par.a[3] = -0.04624d
      par.a[4] = -0.000163369d
      par.a[5] = 0.00000319759d
   endif
   return, func(defangle,p = par)

end

;;----------------------------------------------------------------------
;; Calculate all possible Angle values for each Deflector DAC difference
;; Return these in a structure
function spp_swp_spe_deflut_cal
  par = polycurve2(order= 5)
  anglerange = findgen(141,start = -70, increment = 1)
  anglerangedefs = spp_swp_spe_deflector_func(anglerange)
  fit, anglerange, anglerangedefs, param = par, verbose = 0
  diffdefs = findgen('ffff'x * 2 + 1) - 'ffff'x
  guess = diffdefs * 0 + 0.5
  angles = solve(diffdefs, xguess = guess, param = par)
  deflookup = {defdac:  diffdefs, $
                theta:  angles}
  return, deflookup
end

;;----------------------------------------------
;; The gen L2 code calls this for params
function  spp_swp_span_sweeps,etable=etable,ptable=ptable,cal=cal,peakbin=peakbin,param=param

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






function spp_swp_spe_param,detname=detname,emode=emode,pmode=pmode,reset=reset

  ;;------------------------------------------------------
  ;; COMMON BLOCK
  common spp_swp_spe_param_com, spe_param_dict  ;, etables, cal, a,b

  if keyword_set(reset) then begin
    if isa(spe_param_dict,'OBJREF') then  obj_destroy,spe_param_dict
    spe_param_dict = !null
  endif
  
  if ~isa(spe_param_dict,'dictionary')  then begin
    spe_param_dict = dictionary()
  endif
  
  retval = dictionary()


  if isa(emode) then begin
    if ~spe_param_dict.haskey('ETABLES') then spe_param_dict.etables =orderedhash()
    etables = spe_param_dict.etables
    if ~etables.haskey(emode)  then begin
      ratios = [1.,.3,.1,.1,.001]
      spane_params = {  $
        hvgain : 500., $
        fixgain : 13. * 2 $
      }
      dprint,dlevel=2,'Generating Energy table - emode: '+strtrim(fix(emode),2)
      case emode  of
        1:  etables[1] = spp_swp_spanx_sweep_tables([20.,20000.],spfac=ratios[0]   , emode=emode, _extra = spane_params)
        2:  etables[2] = spp_swp_spanx_sweep_tables([10.,10000.],spfac=ratios[0]   , emode=emode, _extra = spane_params)
        3:  etables[3] = spp_swp_spanx_sweep_tables([ 5., 5000.],spfac=ratios[0]   , emode=emode, _extra = spane_params)
        4:  etables[4] = spp_swp_spanx_sweep_tables([ 5.,  500.],spfac=ratios[0]   , emode=emode, _extra = spane_params)
        5:  etables[5] = spp_swp_spanx_sweep_tables([20.,20000.],spfac=ratios[1]   , emode=emode, _extra = spane_params)
        6:  etables[6] = spp_swp_spanx_sweep_tables([10.,10000.],spfac=ratios[1]   , emode=emode, _extra = spane_params)
        7:  etables[7] = spp_swp_spanx_sweep_tables([ 5., 5000.],spfac=ratios[1]   , emode=emode, _extra = spane_params)
        8:  etables[8] = spp_swp_spanx_sweep_tables([ 5.,  500.],spfac=ratios[1]   , emode=emode, _extra = spane_params)
        9:  etables[9] = spp_swp_spanx_sweep_tables([20.,20000.],spfac=ratios[2]   , emode=9, _extra = spane_params)
        10: etables[10] = spp_swp_spanx_sweep_tables([10.,10000.],spfac=ratios[2]   , emode=10, _extra = spane_params)
        11: etables[11] = spp_swp_spanx_sweep_tables([ 5., 5000.],spfac=ratios[2]   , emode=11, _extra = spane_params)
        12: etables[12] = spp_swp_spanx_sweep_tables([ 5.,  500.],spfac=ratios[2]   , emode=12, _extra = spane_params)
        13: etables[13] = spp_swp_spanx_sweep_tables([20.,20000.],spfac=ratios[3]   , emode=13, _extra = spane_params)
        14: etables[14] = spp_swp_spanx_sweep_tables([10.,10000.],spfac=ratios[3]   , emode=14, _extra = spane_params)
        15: etables[15] = spp_swp_spanx_sweep_tables([ 5., 5000.],spfac=ratios[3]   , emode=15, _extra = spane_params)
        16: etables[16] = spp_swp_spanx_sweep_tables([ 5.,  500.],spfac=ratios[3]   , emode=16, _extra = spane_params)
        17: etables[17] = spp_swp_spanx_sweep_tables([2.,2000.],spfac=ratios[4]   , emode=17, _extra = spane_params)
        18: etables[18] = spp_swp_spanx_sweep_tables([10.,10000.],spfac=ratios[4]   , emode=18, _extra = spane_params)
        19: etables[19] = spp_swp_spanx_sweep_tables([ 5., 5000.],spfac=ratios[4]   , emode=19, _extra = spane_params)
        20: etables[20] = spp_swp_spanx_sweep_tables([ 5.,  500.],spfac=ratios[4]   , emode=20, _extra = spane_params)
        21: etables[21] = spp_swp_spanx_sweep_tables([ 2., 2000.],spfac=ratios[3]   , emode=21, _extra = spane_params)
        else: begin
          etables[emode] = 'Invalid'
          printdat,'Unknown etable encountered'
        end
      endcase    
    endif    
    retval.etable = etables[emode]
    
    def5coeff = [-1396.73, 539.083, 0.802293, -0.0462400, -0.000163369, 0.00000319759]

  endif
  
  
  
  if isa(detname) then begin
    if ~spe_param_dict.haskey('CALS') then   spe_param_dict.cals  = dictionary()
    deflut = spp_swp_spe_deflut_cal()
    cals = spe_param_dict.cals
    if ~cals.haskey(strupcase(detname))  then begin
      dprint,dlevel=2,'Generating cal structure for ',detname
      case strupcase(detname) of
        'SPA' : begin
          dphi =  [1,1,1,1,1,1,1,1,4,4,4,4,4,4,4,4] * 240./40. ;width
          phi = [9.,15.,21.,27.,33.,39.,45.,51.,66.,90.,114.,138.,162.,186.,210.,234.]; hard code for now, center of pixel
          lookdir = fltarr(n_elements(phi))
          for i = 0, n_elements(phi)-1 do begin
            lookdir[i] = float(phi[i] + 180.)
            ;if lookdir[i] ge 360 then lookdir[i] = lookdir[i] - 360
          endfor
          phi = lookdir
          ;phi  = total(dphi,/cumulative) -3 ; +180
          end
        'SPB' : begin
          dphi =  [4,4,4,4,1,1,1,1,1,1,1,1,4,4,4,4] * 240./40. ;width
          phi = [-108.,-84.,-60.,-36.,-21.,-15.,-9.,-3.,3.,9.,15.,21.,36.,60.,84.,108.]; hard code for now, center of pixel
          lookdir = fltarr(n_elements(phi))
          for i = 0, n_elements(phi)-1 do begin
            lookdir[i] = float(phi[i] + 180.)
            ;if lookdir[i] ge 360 then lookdir[i] = lookdir[i] - 360
          endfor
          phi = lookdir
          ;phi = total(dphi,/cumulative) - 120 -12; +180
          end
      endcase
      n_anodes  = 16
      eff = replicate(1.,n_anodes)
      cal  = {   $
        name: detname,  $
        n_anodes: n_anodes, $
        phi: phi, $
        dphi: dphi,  $
        eff:  eff,   $
        defl_scale: .0028d,  $  ; conversion from dac to angle  - This is not quite appropriate - works for now
        deflut_dac: deflut.defdac, $
        deflut_ang: deflut.theta * (-1.), $
        hem_scale:    500.d  , $
        spoil_scale:  80./2.^16   ,  $  ; Needs correction
        k_anal:  replicate(16.7,n_anodes) ,  $
        k_defl:  replicate(1.,n_anodes) $
      }
      cals[strupcase(detname)] = cal
    endif
      
    retval.cal = cals[strupcase(detname)]
  endif
  
  
  if isa(pmode) then begin
    if ~spe_param_dict.haskey('ptables') then spe_param_dict.ptables = orderedhash()
    ptables = spe_param_dict.ptables
    if ~ptables.haskey(pmode) then begin
      dprint, 'Generating new product table ',pmode,dlevel=1
      case pmode of
        '16Ax8Dx32E'  : binmap = indgen(16,8,32)   ; 4096 samples; full resolution
        '32E'  : binmap = reform( replicate(1,16*8) # indgen(32) , 16,8,32 )    ; 32 sample energy spectra
        '16A'   : binmap = reform( indgen(16) # replicate(1,8*32) , 16,8,32)      ; 16 sample anode spectra
        else:   binmap = !null
      endcase
      ptable = dictionary()
      ptable.pmode = pmode
      if isa(binmap) then begin
        hist = histogram(binmap,locations=loc,omin=omin,omax=omax,reverse_ind=ri)
        ptable.binmap = binmap
        ptable.hist = hist
        ptable.reverse_ind = ri
      endif else dprint,dlevel=1,'Unknown pmode: "',pmode,'"'
      ptables[pmode] = ptable
    endif    
    retval.ptable  = ptables[pmode]
  endif
  
  
  if n_elements(retval) eq 0 then retval = spe_param_dict
  
  return,retval
     
END

