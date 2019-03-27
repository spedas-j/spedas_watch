; $LastChangedBy: davin-mac $
; $LastChangedDate: 2019-03-26 17:00:04 -0700 (Tue, 26 Mar 2019) $
; $LastChangedRevision: 26913 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/ion/spp_swp_spi_param2.pro $
;



;; ************************************************************
;; *************************** MAIN ***************************
;; ************************************************************


;usage:
; rswp = spp_swp_span_reduced_sweep(fullsweep=fswp,  ptable=spe.ptable)





function spp_swp_spi_param2,detname=detname,emode=emode,pmode=pmode,reset=reset

  ;;------------------------------------------------------
  ;; COMMON BLOCK
  common spp_swp_spi_param2_com, spi_param_dict  ;, etables, cal, a,b

  if keyword_set(reset) then begin
    if isa(spi_param_dict,'OBJREF') then  obj_destroy,spi_param_dict
    spi_param_dict = !null
  endif
  
  if ~isa(spi_param_dict,'dictionary')  then begin
    spi_param_dict = dictionary()
  endif
  
  retval = dictionary()


  if isa(emode) then begin
    if ~spi_param_dict.haskey('ETABLES') then spi_param_dict.etables =orderedhash()
    etables = spi_param_dict.etables
    if ~etables.haskey(emode)  then begin
      ratios = [1.,.3,.1,.1,.001]
;      spane_params = {  $
;        hvgain : 500., $
;        fixgain : 13. * 2 $
;      }
      dprint,dlevel=2,'Generating Energy table - emode: '+strtrim(fix(emode),2)
      case emode  of
        1:  etables[1] = spp_swp_spanx_sweep_tables([500.,10000.],spfac=ratios[2]   , emode=emode, _extra = spani_params)
        2:  etables[2] = spp_swp_spanx_sweep_tables([500.,2000.],spfac=ratios[2]   , emode=emode, _extra = spani_params)
        3:  etables[3] = spp_swp_spanx_sweep_tables([ 250., 1000.],spfac=ratios[2]   , emode=emode, _extra = spani_params)
        4:  etables[4] = spp_swp_spanx_sweep_tables([ 1000.,4000.],spfac=ratios[2]   , emode=emode, _extra = spani_params)
        5:  etables[5] = spp_swp_spanx_sweep_tables([ 125.,20000.],spfac=ratios[2]   , emode=emode, _extra = spani_params)
;        6:  etables[6] = spp_swp_spanx_sweep_tables([ 4000.,40000.],spfac=ratios[2]   , emode=emode, _extra = spani_params)
        else: begin
          etables[emode] = 'Invalid'
          printdat,'Unknown etable encountered'
        end
      endcase    
    endif    
    retval.etable = etables[emode]
    
  ;  def5coeff = [-1396.73, 539.083, 0.802293, -0.0462400, -0.000163369, 0.00000319759]

  endif
  
  
  
  if isa(detname) then begin
    if ~spi_param_dict.haskey('CALS') then   spi_param_dict.cals  = dictionary()
    cals = spi_param_dict.cals
    if ~cals.haskey(strupcase(detname))  then begin
      dprint,dlevel=2,'Generating cal structure for ',detname
      case strupcase(detname) of
        'SPA' : begin
          dphi =  [1,1,1,1,1,1,1,1,4,4,4,4,4,4,4,4] * 240./40.
          phi  = total(dphi,/cumulative)
          n_anodes  = 16
          eff = replicate(1.,n_anodes)
          cal  = {   $
            name: detname,  $
            n_anodes: n_anodes, $
            phi: phi, $
            dphi: dphi,  $
            eff:  eff,   $
            defl_scale: .0028d,  $  ; conversion from dac to angle  - This is not quite appropriate - works for now
            hem_scale:    500.d  , $
            spoil_scale:  80./2.^16   ,  $  ; Needs correction
            k_anal:  replicate(16.7,n_anodes) ,  $
            k_defl:  replicate(1.,n_anodes) $
          }
          end
        'SPB' : begin
          dphi =  [4,4,4,4,1,1,1,1,1,1,1,1,4,4,4,4] * 240./40.
          phi = total(dphi,/cumulative) - 120 - 12
          n_anodes  = 16
          eff = replicate(1.,n_anodes)
          cal  = {   $
            name: detname,  $
            n_anodes: n_anodes, $
            phi: phi, $
            dphi: dphi,  $
            eff:  eff,   $
            defl_scale: .0028d,  $  ; conversion from dac to angle  - This is not quite appropriate - works for now
            hem_scale:    500.d  , $
            spoil_scale:  80./2.^16   ,  $  ; Needs correction
            k_anal:  replicate(16.7,n_anodes) ,  $
            k_defl:  replicate(1.,n_anodes) $
          }
          end
        'SPI' : begin
          dphi = [11.25,11.25,11.25,11.25,11.25,11.25,11.25,11.25,11.25,11.25, 22.5,22.5,22.5,22.5,22.5,22.5]
          phi = total(dphi,/cumulative) + 10. + dphi/2  ; This number needs fixing!
          n_anodes  = 16
          eff = replicate(1.,n_anodes)
          cal  = {   $
            name: detname,  $
            n_anodes: n_anodes, $
            phi: phi, $
            dphi: dphi,  $
            eff:  eff,   $
            defl_scale: .0028d,  $  ; conversion from dac to angle  - This is not quite appropriate - works for now
            hem_scale:    1000.d  , $
            spoil_scale:  80./2.^16   ,  $  ; Needs correction
            k_anal:  replicate(16.7,n_anodes) ,  $
            k_defl:  replicate(1.,n_anodes) $
          }
          end
      endcase
      cals[strupcase(detname)] = cal
    endif
      
    retval.cal = cals[strupcase(detname)]
  endif
  
  
  if isa(pmode) then begin
    if ~spi_param_dict.haskey('ptables') then spi_param_dict.ptables = orderedhash()
    ptables = spi_param_dict.ptables
    if ~ptables.haskey(pmode) then begin
      dprint, 'Generating new product table ',pmode,dlevel=2
      binmap = spp_swp_spi_flight_product_tables('prod_'+pmode)
      ptable = dictionary()
      ptable.pmode = pmode
      if isa(binmap) then begin
        hist = histogram(binmap,locations=loc,min=0,omin=omin,omax=omax,reverse_ind=ri)
        ptable.binmap = binmap
        ptable.hist = hist
        ptable.reverse_ind = ri
      endif else dprint,dlevel=1,'Unknown pmode: "',pmode,'"'
      ptables[pmode] = ptable
    endif    
    retval.ptable  = ptables[pmode]
  endif
  
  
  if n_elements(retval) eq 0 then retval = spi_param_dict
  
  return,retval
     
END

