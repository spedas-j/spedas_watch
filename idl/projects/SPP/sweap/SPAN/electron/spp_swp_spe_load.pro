; $LastChangedBy: ali $
; $LastChangedDate: 2019-11-04 19:41:19 -0800 (Mon, 04 Nov 2019) $
; $LastChangedRevision: 27976 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/electron/spp_swp_spe_load.pro $
; Created by Davin Larson 2018
; Major updates by Phyllis Whittlesey 2019


pro spp_swp_spe_load,spxs=spxs,types=types,varformat=varformat,trange=trange,no_load=no_load,verbose=verbose,$
  alltypes=alltypes,allvars=allvars,hkp=hkp,save=save,level=level,fileprefix=fileprefix

  if ~keyword_set(level) then level='L2'
  level=strupcase(level)
  if ~keyword_set(spxs) then spxs = ['spa','spb']
  if ~keyword_set(types) then types = ['sf1', 'sf0']  ;,'st1','st0']   ; add archive when available
  if keyword_set(alltypes) then types = 'all'
  if types[0] eq 'all' then begin
    types=['hkp','fhkp']
    foreach type0,['s','a'] do foreach type1,['f','t'] do foreach type2,['0','1'] do types=[types,type0+type1+type2]
  endif

  dir='SP?/'+level+'/SP?_TYP/YYYY/MM/'
  fileformat=dir+'psp_swp_SP?_TYP_'+level+'*_YYYYMMDD_v??.cdf'
  if not keyword_set(fileprefix) then fileprefix='psp/data/sci/sweap/'

  vars = orderedhash()
  vars['hkp'] = '*TEMP* *_BITS *_FLAG* *CMD* *PEAK* *CNT*'
  if keyword_set(allvars) then varformat='*'

  tr = timerange(trange)
  foreach spx, spxs do begin
    foreach type,types do begin
      filespx = str_sub(fileformat,'SP?', spx)              ; instrument string substitution
      filetype = str_sub(filespx,'TYP',type)                 ; packet type substitution
      dprint,filetype,/phelp
      files = spp_file_retrieve(filetype,trange=tr,/last_version,/daily_names,/valid_only,prefix=fileprefix,verbose=verbose)
      if keyword_set(save) then begin
        vardata = !null
        novardata = !null
        loadcdfstr,filenames=files,vardata,novardata
        dummy = spp_data_product_hash(spx+'_'+type,vardata)
      endif
      if keyword_set(no_load) then continue
      prefix = 'psp_swp_'+spx+'_'+type+'_'+level+'_'
      if keyword_set(varformat) then vfm = varformat else if vars.haskey(type) then vfm=vars[type] else vfm=[]
      cdf2tplot,files,prefix=prefix,varformat=vfm,verbose=verbose

      if 0 and (type eq 'sf0' or type eq 'af0') then begin ;; will need to change this in the future if sf0 isn't 3d spectra.
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
        ylim,prefix+'EFLUX',1.,10000.,1,/default
        ylim,'*ENERGY*_ql',1,1,1,/default
        ylim,'*ANODE*_ql',0,0,0,/default
        ylim,'*DEF*_ql',0,0,0,/default
        Zlim,prefix+'*EFLUX',100.,2000.,1,/default
        Zlim,'*_ql',1,1,1,/default
        ylim, '*spb*ANODE*ql*', 50,310,0, /default
        ylim, '*spa*ANODE*ql*', 180,420,0, /default
        options, '*_ql', spec = 1
        ;        tplot_options, 'no_interp', 1
      endif

    endforeach
  endforeach

end
