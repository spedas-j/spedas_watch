pro elf_set_overview_options, probe=probe, trange=trange, no_switch=no_switch

   if ~keyword_set(probe) then probe='a' else probe=probe

   if ~keyword_set(no_switch) then begin
     get_data, 'el'+probe+'_pef_nflux', data=pef_nflux, dlimits=pef_nflux_dl, limits=pef_nflux_l
     get_data, 'el'+probe+'_pef_en_spec2plot_omni', data=omni, dlimits=omni_dl, limits=omni_l
     if pef_nflux.v[0] LT omni.v[0] then omni.v[0]=pef_nflux.v[0]
     store_data, 'el'+probe+'_pef_en_spec2plot_omni', data=omni, dlimits=omni_dl, limits=omni_l
     get_data, 'el'+probe+'_pef_en_spec2plot_anti', data=anti, dlimits=anti_dl, limits=anti_l
     if pef_nflux.v[0] LT anti.v[0] then anti.v[0]=pef_nflux.v[0]
     store_data, 'el'+probe+'_pef_en_spec2plot_anti', data=anti, dlimits=anti_dl, limits=anti_l
     get_data, 'el'+probe+'_pef_en_spec2plot_perp', data=perp, dlimits=perp_dl, limits=perp_l
     if pef_nflux.v[0] LT perp.v[0] then perp.v[0]=pef_nflux.v[0]
     store_data, 'el'+probe+'_pef_en_spec2plot_perp', data=perp, dlimits=perp_dl, limits=perp_l
     get_data, 'el'+probe+'_pef_en_spec2plot_para', data=para, dlimits=para_dl, limits=para_l
     if pef_nflux.v[0] LT para.v[0] then para.v[0]=pef_nflux.v[0]
     store_data, 'el'+probe+'_pef_en_spec2plot_para', data=para, dlimits=para_dl, limits=para_l
     get_data, 'el'+probe+'_pef_en_reg_spec2plot_omni', data=omni, dlimits=omni_dl, limits=omni_l
     if size(omni,/type) EQ 8 && pef_nflux.v[0] LT omni.v[0] then begin
      omni.v[0]=pef_nflux.v[0]
      store_data, 'el'+probe+'_pef_en_reg_spec2plot_omni', data=omni, dlimits=omni_dl, limits=omni_l
     endif
     get_data, 'el'+probe+'_pef_en_reg_spec2plot_anti', data=anti, dlimits=anti_dl, limits=anti_l
     if size(omni,/type) EQ 8 && pef_nflux.v[0] LT anti.v[0] then begin
      anti.v[0]=pef_nflux.v[0]
      store_data, 'el'+probe+'_pef_en_reg_spec2plot_anti', data=anti, dlimits=anti_dl, limits=anti_l
     endif
     get_data, 'el'+probe+'_pef_en_reg_spec2plot_perp', data=perp, dlimits=perp_dl, limits=perp_l
     if size(omni,/type) EQ 8 && pef_nflux.v[0] LT perp.v[0] then begin
      perp.v[0]=pef_nflux.v[0]
      store_data, 'el'+probe+'_pef_en_reg_spec2plot_perp', data=perp, dlimits=perp_dl, limits=perp_l
     endif
     get_data, 'el'+probe+'_pef_en_reg_spec2plot_para', data=para, dlimits=para_dl, limits=para_l
      if size(omni,/type) EQ 8 && pef_nflux.v[0] LT para.v[0] then begin
        para.v[0]=pef_nflux.v[0]
        store_data, 'el'+probe+'_pef_en_reg_spec2plot_para', data=para, dlimits=para_dl, limits=para_l
      endif
   endif
   
   options, 'el'+probe+'_pef_en_spec2plot_omni', charsize=.9
   options, 'el'+probe+'_pef_en_spec2plot_omni', 'ztitle','#/(scm!U2!NstrMeV)' 
   options, 'el'+probe+'_pef_en_spec2plot_omni', 'ysubtitle','[keV]'
   options, 'el'+probe+'_pef_en_spec2plot_anti', charsize=.9
   options, 'el'+probe+'_pef_en_spec2plot_anti', 'ztitle','#/(scm!U2!NstrMeV)'
   options, 'el'+probe+'_pef_en_spec2plot_anti', 'ysubtitle','[keV]'
   options, 'el'+probe+'_pef_en_spec2plot_perp', charsize=.9
   options, 'el'+probe+'_pef_en_spec2plot_perp', 'ztitle','#/(scm!U2!NstrMeV)'
   options, 'el'+probe+'_pef_en_spec2plot_perp', 'ysubtitle','[keV]'
   options, 'el'+probe+'_pef_en_spec2plot_para', charsize=.9
   options, 'el'+probe+'_pef_en_spec2plot_para', 'ztitle','#/(scm!U2!NstrMeV)'
   options, 'el'+probe+'_pef_en_spec2plot_para', 'ysubtitle','[keV]'
   options, 'el'+probe+'_pef_en_reg_spec2plot_omni', charsize=.9
   options, 'el'+probe+'_pef_en_reg_spec2plot_omni', 'ztitle','#/(scm!U2!NstrMeV)'
   options, 'el'+probe+'_pef_en_reg_spec2plot_omni', 'ysubtitle','[keV]'
   options, 'el'+probe+'_pef_en_reg_spec2plot_anti', charsize=.9
   options, 'el'+probe+'_pef_en_reg_spec2plot_anti', 'ztitle','#/(scm!U2!NstrMeV)'
   options, 'el'+probe+'_pef_en_reg_spec2plot_anti', 'ysubtitle','[keV]'
   options, 'el'+probe+'_pef_en_reg_spec2plot_perp', charsize=.9
   options, 'el'+probe+'_pef_en_reg_spec2plot_perp', 'ztitle','#/(scm!U2!NstrMeV)'
   options, 'el'+probe+'_pef_en_reg_spec2plot_perp', 'ysubtitle','[keV]'
   options, 'el'+probe+'_pef_en_reg_spec2plot_para', charsize=.9
   options, 'el'+probe+'_pef_en_reg_spec2plot_para', 'ztitle','#/(scm!U2!NstrMeV)'
   options, 'el'+probe+'_pef_en_reg_spec2plot_para', 'ysubtitle','[keV]'
   
   options, 'el'+probe+'_bt89_sm_NED', charsize=.8
   options, 'el'+probe+'_bt89_sm_NED', colors=[251, 155, 252]
   zlim, 'el'+probe+'_pef_en_spec2plot_omni', 1.e1, 2.e6
   zlim, 'el'+probe+'_pef_en_spec2plot_anti', 1.e1, 2.e6
   zlim, 'el'+probe+'_pef_en_spec2plot_perp', 1.e1, 2.e6
   zlim, 'el'+probe+'_pef_en_spec2plot_para', 1.e1, 2.e6
   zlim, 'el'+probe+'_pef_pa_spec2plot_ch0LC', 2.e3, 2.e6
   zlim, 'el'+probe+'_pef_pa_spec2plot_ch1LC',1.e3, 2.e5
   zlim, 'el'+probe+'_pef_pa_spec2plot_ch2LC', 1.e2, 1.e5
   zlim, 'el'+probe+'_pef_pa_spec2plot_ch3LC', 1.e1, 2.e3
   zlim, 'el'+probe+'_pef_en_reg_spec2plot_omni', 1.e1, 2.e6
   zlim, 'el'+probe+'_pef_en_reg_spec2plot_anti', 1.e1, 2.e6
   zlim, 'el'+probe+'_pef_en_reg_spec2plot_perp', 1.e1, 2.e6
   zlim, 'el'+probe+'_pef_en_reg_spec2plot_para', 1.e1, 2.e6
   zlim, 'el'+probe+'_pef_pa_reg_spec2plot_ch0LC', 2.e3, 2.e6
   zlim, 'el'+probe+'_pef_pa_reg_spec2plot_ch1LC',1.e3, 2.e5
   zlim, 'el'+probe+'_pef_pa_reg_spec2plot_ch2LC', 1.e2, 1.e5
   zlim, 'el'+probe+'_pef_pa_reg_spec2plot_ch3LC', 1.e1, 2.e3

   options, 'el'+probe+'_pef_en_spec2plot_omni',zstyle=1
   options, 'el'+probe+'_pef_en_spec2plot_anti',zstyle=1
   options, 'el'+probe+'_pef_en_spec2plot_perp',zstyle=1
   options, 'el'+probe+'_pef_en_spec2plot_para',zstyle=1
   options, 'el'+probe+'_pef_pa_spec2plot_ch1LC',zstyle=1
   options, 'el'+probe+'_pef_pa_spec2plot_ch0LC',zstyle=1
   options, 'el'+probe+'_pef_pa_spec2plot_ch2LC',zstyle=1
   options, 'el'+probe+'_pef_pa_spec2plot_ch3LC',zstyle=1
   options, 'el'+probe+'_pef_en_reg_spec2plot_omni',zstyle=1
   options, 'el'+probe+'_pef_en_reg_spec2plot_anti',zstyle=1
   options, 'el'+probe+'_pef_en_reg_spec2plot_perp',zstyle=1
   options, 'el'+probe+'_pef_en_reg_spec2plot_para',zstyle=1
   options, 'el'+probe+'_pef_pa_reg_spec2plot_ch1LC',zstyle=1
   options, 'el'+probe+'_pef_pa_reg_spec2plot_ch0LC',zstyle=1
   options, 'el'+probe+'_pef_pa_reg_spec2plot_ch2LC',zstyle=1
   options, 'el'+probe+'_pef_pa_reg_spec2plot_ch3LC',zstyle=1

   options, 'el'+probe+'_pef_pa_spec2plot_ch0LC', 'ysubtitle','[deg]'
   options, 'el'+probe+'_pef_pa_spec2plot_ch0LC', 'ztitle','#/(scm!U2!NstrMeV)'  
   options, 'el'+probe+'_pef_pa_spec2plot_ch1LC', 'ysubtitle','[deg]'
   options, 'el'+probe+'_pef_pa_spec2plot_ch1LC', 'ztitle','#/(scm!U2!NstrMeV)'  
   options, 'el'+probe+'_pef_pa_spec2plot_ch2LC', 'ysubtitle','[deg]'
   options, 'el'+probe+'_pef_pa_spec2plot_ch2LC', 'ztitle','#/(scm!U2!NstrMeV)'  
   options, 'el'+probe+'_pef_pa_spec2plot_ch3LC', 'ysubtitle','[deg]'
   options, 'el'+probe+'_pef_pa_spec2plot_ch3LC', 'ztitle','#/(scm!U2!NstrMeV)'  
   options, 'el'+probe+'_pef_pa_reg_spec2plot_ch0LC', 'ysubtitle','[deg]'
   options, 'el'+probe+'_pef_pa_reg_spec2plot_ch0LC', 'ztitle','#/(scm!U2!NstrMeV)'
   options, 'el'+probe+'_pef_pa_reg_spec2plot_ch1LC', 'ysubtitle','[deg]'
   options, 'el'+probe+'_pef_pa_reg_spec2plot_ch1LC', 'ztitle','#/(scm!U2!NstrMeV)'
   options, 'el'+probe+'_pef_pa_reg_spec2plot_ch2LC', 'ysubtitle','[deg]'
   options, 'el'+probe+'_pef_pa_reg_spec2plot_ch2LC', 'ztitle','#/(scm!U2!NstrMeV)'
   options, 'el'+probe+'_pef_pa_reg_spec2plot_ch3LC', 'ysubtitle','[deg]'
   options, 'el'+probe+'_pef_pa_reg_spec2plot_ch3LC', 'ztitle','#/(scm!U2!NstrMeV)'

   options,'el?_p?f_pa*spec2plot_ch*LC*','ztitle','#/(scm!U2!NstrMeV)'
   options,'el?_p?f_pa*spec2plot_ch0LC*','zrange',[2e3,2e6]
   options,'el?_p?f_pa*spec2plot_ch1LC*','zrange',[1e3,2e5]
   options,'el?_p?f_pa*spec2plot_ch2LC*','zrange',[1e2,1e5]
   options,'el?_p?f_pa*spec2plot_ch3LC*','zrange',[1e1,2e3]
   options,'el?_p?f_pa*spec2plot_ch0LC*','zstyle',1
   options,'el?_p?f_pa*spec2plot_ch1LC*','zstyle',1
   options,'el?_p?f_pa*spec2plot_ch2LC*','zstyle',1
   options,'el?_p?f_pa*spec2plot_ch3LC*','zstyle',1
   options,'el?_p?f_en_spec2plot*','zrange',[1e1,2e6]
   options,'el?_p?f_en_spec2plot*','zstyle',1
   options,'el?_p?f_en_reg_spec2plot*','zrange',[1e1,2e6]
   options,'el?_p?f_en_reg_spec2plot*','zstyle',1

   options, 'el'+probe+'_pef_en_spec2plot_omni','extend_edges',1
   options, 'el'+probe+'_pef_en_spec2plot_anti','extend_edges',1
   options, 'el'+probe+'_pef_en_spec2plot_perp','extend_edges',1
   options, 'el'+probe+'_pef_en_spec2plot_para','extend_edges',1

   options, 'el'+probe+'_pef_en_reg_spec2plot_omni','extend_edges',1
   options, 'el'+probe+'_pef_en_reg_spec2plot_anti','extend_edges',1
   options, 'el'+probe+'_pef_en_reg_spec2plot_perp','extend_edges',1
   options, 'el'+probe+'_pef_en_reg_spec2plot_para','extend_edges',1

end
