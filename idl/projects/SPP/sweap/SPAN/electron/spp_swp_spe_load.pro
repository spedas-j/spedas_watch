; $LastChangedBy: davin-mac $
; $LastChangedDate: 2019-08-16 09:12:39 -0700 (Fri, 16 Aug 2019) $
; $LastChangedRevision: 27607 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/electron/spp_swp_spe_load.pro $
; Created by Davin Larson 2018
; Major updates by Phyllis Whittlesey 2019


pro spp_swp_spe_load,spxs=spxs,types=types,varformat=varformat,trange=trange,no_load=no_load,verbose=verbose, all = all, hkp = hkp,save=save,level=level

  if ~keyword_set(spxs) then spxs = ['spa','spb']
  if ~keyword_set(types) then types = ['sf1', 'sf0']  ;,'st1','st0']   ; add archive when available
  if keyword_set(all) then types = ['sf1', 'sf0', 'af1', 'af0', 'hkp']

  fileprefix = 'psp/data/sci/sweap/'
  
  loc = orderedhash()
  loc['sf1'] = 'SP?/L2/YYYY/MM/SP?_TYP/psp_swp_SP?_TYP_L2_32E_YYYYMMDD_v??.cdf'
  loc['st1'] = 'SP?/L2/YYYY/MM/SP?_TYP/psp_swp_SP?_TYP_L2_32E_YYYYMMDD_v??.cdf'
  loc['sf0'] = 'SP?/L2/YYYY/MM/SP?_TYP/psp_swp_SP?_TYP_L2_16Ax8Dx32E_YYYYMMDD_v??.cdf'
  loc['st0'] = 'SP?/L2/YYYY/MM/SP?_TYP/psp_swp_SP?_TYP_L2_16Ax8Dx32E_YYYYMMDD_v??.cdf'
  loc['af1'] = 'SP?/L2/YYYY/MM/SP?_TYP/psp_swp_SP?_TYP_L2_32E_YYYYMMDD_v??.cdf'
  loc['af0'] = 'SP?/L2/YYYY/MM/SP?_TYP/psp_swp_SP?_TYP_L2_16Ax8Dx32E_YYYYMMDD_v??.cdf'
  loc['hkp'] = 'SP?/L1/YYYY/MM/SP?_hkp/psp_swp_SP?_hkp_L1_YYYYMMDD_v??.cdf'

  
  ;test='http://sprg.ssl.berkeley.edu/data/psp/data/sci/sweap/spa/L1/2018/09/spa_hkp/spp_swp_spa_hkp_L1_20180924_v00.cdf
  ;test                                  ='psp/data/sci/sweap/spa/L1/2018/10/spa_hkp/spp_swp_spa_hkp_20181004_v??.cdf
  vars = orderedhash()
  vars['sf1'] = 'EFLUX EMODE'
  vars['sf0'] = 'EFLUX EMODE *THETA* *PHI* *ENERGY*'
  vars['st0'] = 'EFLUX EMODE *THETA* *PHI* *ENERGY*'
  vars['af1'] = 'EFLUX EMODE'
  vars['af0'] = 'EFLUX EMODE *THETA* *PHI* *ENERGY*'
  if keyword_set(all) then begin
    vars['sf1'] = '*'
    vars['sf0'] = '*'
  endif
  vars['hkp'] = '*TEMP* *_BITS *_FLAG* *CMD*'
  if keyword_set(all) then vars['hkp'] = vars['hkp'] + ' *CNT*' + ' *PEAK*' + ' *CMD*'
  
  if keyword_set(level) && level eq 'L1' then begin
    loc['sf1'] = 'SP?/L1/YYYY/MM/SP?_TYP/psp_swp_SP?_TYP_L1_YYYYMMDD_v??.cdf'
    loc['st1'] = 'SP?/L1/YYYY/MM/SP?_TYP/psp_swp_SP?_TYP_L1_YYYYMMDD_v??.cdf'
    loc['sf0'] = 'SP?/L1/YYYY/MM/SP?_TYP/psp_swp_SP?_TYP_L1_YYYYMMDD_v??.cdf'
    loc['st0'] = 'SP?/L1/YYYY/MM/SP?_TYP/psp_swp_SP?_TYP_L1_YYYYMMDD_v??.cdf'
    loc['af1'] = 'SP?/L1/YYYY/MM/SP?_TYP/psp_swp_SP?_TYP_L1_YYYYMMDD_v??.cdf'
    loc['af0'] = 'SP?/L1/YYYY/MM/SP?_TYP/psp_swp_SP?_TYP_L1_YYYYMMDD_v??.cdf'
  endif

  
  tr = timerange(trange)
  foreach spx, spxs do begin
    foreach type,types do begin
      fileformat = str_sub(loc[type],'SP?', spx)              ; instrument string substitution
      fileformat = str_sub(fileformat,'TYP',type)                 ; packet type substitution
      dprint,fileformat,/phelp                                   
      files = spp_file_retrieve(fileformat,trange=tr,/daily_names,/valid_only,prefix=fileprefix,verbose=verbose)
      if keyword_set(save) then begin
        vardata = !null
        novardata = !null
        loadcdfstr,filenames=files,vardata,novardata
        dummy = spp_data_product_hash(spx+'_'+type,vardata)
      endif
      if keyword_set(no_load) then continue
      prefix = 'psp_swp_'+spx+'_'+type+'_'
      if keyword_set(varformat) then vfm = varformat else vfm=vars[type]
      cdf2tplot,files,prefix=prefix,varformat=vfm,verbose=verbose
      if type eq 'sf0' or type eq 'af0' then begin ;; will need to change this in the future if sf0 isn't 3d spectra.
        ;; make a line here to get data from tplot
        ;; Hard code bins for now, retain option to keep flexible later
        nrg_bins = 32
        def_bins = 8
        anode_bins = 16
        prod_str = '_SFN_'
        prod_type = str_sub(prod_str,'SFN',type)   
        ; order of the below should be anode, deflector, energy bin
        get_data, 'psp_swp_' + spx + prod_type + 'EFLUX' , data = span_eflux
        get_data, 'psp_swp_' + spx + prod_type + 'ENERGY', data = span_energy
        get_data, 'psp_swp_' + spx + prod_type + 'PHI', data = span_phi
        get_data, 'psp_swp_' + spx + prod_type + 'THETA', data = span_theta
        ;;----------------------------------------------------------
        ;; Make an Nrg Sypec
        nTimePoints = size(span_eflux.v)
        xpandEflux_nrg = reform(span_eflux.y, nTimePoints[1],  anode_bins, def_bins, nrg_bins)
        xpandEbins = reform(span_eflux.v, nTimePoints[1], (def_bins * anode_bins), nrg_bins)
        flatEbins = reform(xpandEbins[*,0,*])
        totalEflux_nrg = total(total(xpandEflux_nrg, 2) , 2)
        sum_nrg_spec = {x: span_eflux.x, $
                        y: totalEflux_nrg, $
                        v: flatEbins }
        store_data, 'psp_swp_' + spx + prod_type + 'ENERGY_SPEC_ql', data = sum_nrg_spec
        ;;----------------------------------------------------------
        ;; Make an Anode Apec
        xpandEflux_anode = reform(span_eflux.y, nTimePoints[1], anode_bins, def_bins, nrg_bins)
        xpandPhi = reform(span_phi.y, nTimePoints[1], anode_bins, (def_Bins*nrg_bins))
        flatAnodeBins = xpandphi[*,*,0]
        totalEflux_anode = total(total(xpandEflux_anode, 3),3)
        sum_anode_spec = {x: span_eflux.x, $
                          y: totalEflux_anode, $
                          v: flatAnodeBins }
        store_data, 'psp_swp_' + spx + prod_type + 'ANODE_SPEC_ql', data = sum_anode_spec
        ;;----------------------------------------------------------
        ;; Gen Def Spec
        xpandEflux_def = reform(span_eflux.y, nTimePoints[1], anode_bins, def_bins, nrg_bins)
        xpandTheta = reform(span_theta.y, nTimePoints[1], anode_bins, def_bins, nrg_bins)
        flatDefBins = reform(xpandTheta[*,0,*,0])
        totalEflux_def = total(total(xpandEflux_def, 2),3)
        sum_def_spec = {x: span_eflux.x, $
                          y: totalEflux_def, $
                          v: flatDefBins }
        store_data, 'psp_swp_' + spx + prod_type + 'DEF_SPEC_ql', data = sum_def_spec
        
        ;; some lines here to put these back in tplot - done for NRG spec
        ;; be done?
      endif
      if type eq 'hkp' then begin
        cdf2tplot,files,prefix=prefix,varformat=vfm,verbose=verbose
        continue
      endif
      ylim,prefix+'EFLUX',1.,10000.,1,/default
      ylim,'*ENERGY*_ql',1,1,1,/default
      ylim,'*ANODE*_ql',0,0,0,/default
      ylim,'*DEF*_ql',0,0,0,/default
      Zlim,prefix+'*EFLUX',100.,2000.,1,/default
      Zlim,'*_ql',1,1,1,/default
      ylim, '*spb*ANODE*ql*', 50,310,0, /default
      ylim, '*spa*ANODE*ql*', 180,420,0, /default
      options, '*_ql', spec = 1
      tplot_options, 'no_interp', 1
      
    endforeach
  endforeach

   
   
   
   
;   format = 'psp/data/sci/sweap/spa/L2/YYYY/MM/spa_sf1/spp_swp_spa_sf1_L2_*_YYYYMMDD_v??.cdf'
;   files = spp_file_retrieve(spa_format,/daily_names,/valid_only,/last_version,prefix=ssr_prefix,verbose=2,trange=tr)
;   cdf2tplot,spa_files,prefix = prefix,varformat='EFLUX EMODE'

end
