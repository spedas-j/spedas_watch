pro elf_set_overview_options, probe=probe, trange=trange

   if ~keyword_set(probe) then probe='a' else probe=probe
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
   
   options, 'el'+probe+'_bt89_sm_NED', charsize=.8
   options, 'el'+probe+'_bt89_sm_NED', colors=[251, 155, 252]
   zlim, 'el'+probe+'_pef_en_spec2plot_omni', 1.e1, 2.e6
   zlim, 'el'+probe+'_pef_en_spec2plot_anti', 1.e1, 2.e6
   zlim, 'el'+probe+'_pef_en_spec2plot_perp', 1.e1, 2.e6
   zlim, 'el'+probe+'_pef_en_spec2plot_para', 1.e1, 2.e6
   zlim, 'el'+probe+'_pef_pa_reg_spec2plot_ch0LC', 2.e3, 2.e6
   zlim, 'el'+probe+'_pef_pa_reg_spec2plot_ch1LC',1.e3, 1.e6
   zlim, 'el'+probe+'_pef_pa_spec2plot_ch2LC', 1.e2, 1.e5
   zlim, 'el'+probe+'_pef_pa_spec2plot_ch3LC', 1.e1, 2.e3

   options, 'el'+probe+'_pef_pa_reg_spec2plot_ch1LC',zstyle=1
   options, 'el'+probe+'_pef_pa_reg_spec2plot_ch0LC',zstyle=1
   options, 'el'+probe+'_pef_pa_spec2plot_ch2LC',zstyle=1
   options, 'el'+probe+'_pef_pa_spec2plot_ch3LC',zstyle=1
   options, 'el'+probe+'_pef_en_spec2plot_omni',zstyle=1
   options, 'el'+probe+'_pef_en_spec2plot_anti',zstyle=1
   options, 'el'+probe+'_pef_en_spec2plot_perp',zstyle=1
   options, 'el'+probe+'_pef_en_spec2plot_para',zstyle=1

   options, 'el'+probe+'_pef_pa_reg_spec2plot_ch0LC', 'ysubtitle','[deg]'
   options, 'el'+probe+'_pef_pa_reg_spec2plot_ch0LC', 'ztitle','#/(scm!U2!NstrMeV)'  
   options, 'el'+probe+'_pef_pa_reg_spec2plot_ch1LC', 'ysubtitle','[deg]'
   options, 'el'+probe+'_pef_pa_reg_spec2plot_ch1LC', 'ztitle','#/(scm!U2!NstrMeV)'  
   options, 'el'+probe+'_pef_pa_spec2plot_ch2LC', 'ysubtitle','[deg]'
   options, 'el'+probe+'_pef_pa_spec2plot_ch2LC', 'ztitle','#/(scm!U2!NstrMeV)'  
   options, 'el'+probe+'_pef_pa_spec2plot_ch3LC', 'ysubtitle','[deg]'
   options, 'el'+probe+'_pef_pa_spec2plot_ch3LC', 'ztitle','#/(scm!U2!NstrMeV)'  

   options,'el?_p?f_pa*spec2plot_ch*LC*','ztitle','#/(scm!U2!NstrMeV)'
   options,'el?_p?f_pa*spec2plot_ch0LC*','zrange',[2e3,2e6]
   options,'el?_p?f_pa*spec2plot_ch1LC*','zrange',[1e3,1e6]
   options,'el?_p?f_pa*spec2plot_ch2LC*','zrange',[1e2,1e5]
   options,'el?_p?f_pa*spec2plot_ch3LC*','zrange',[1e1,2e3]
   options,'el?_p?f_en_spec2plot*','zrange',[1e1,2e6]
   options,'el?_p?f_pa*spec2plot_ch0LC*','zstyle',1
   options,'el?_p?f_pa*spec2plot_ch1LC*','zstyle',1
   options,'el?_p?f_pa*spec2plot_ch2LC*','zstyle',1
   options,'el?_p?f_pa*spec2plot_ch3LC*','zstyle',1
   options,'el?_p?f_en_spec2plot*','zstyle',1

end
