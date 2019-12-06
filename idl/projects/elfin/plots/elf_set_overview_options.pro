pro elf_set_overview_options, probe=probe

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
   options, 'el'+probe+'_pef_en_spec2plot_omni',zstyle=1
   options, 'el'+probe+'_pef_en_spec2plot_anti',zstyle=1
   options, 'el'+probe+'_pef_en_spec2plot_perp',zstyle=1
   options, 'el'+probe+'_pef_en_spec2plot_para',zstyle=1
   
   options, 'el'+probe+'_bt89_sm_NED', charsize=.9
   zlim, 'el'+probe+'_pef_en_spec2plot_omni', 10., 5.e6
   zlim, 'el'+probe+'_pef_en_spec2plot_anti', 10., 5.e6
   zlim, 'el'+probe+'_pef_en_spec2plot_perp', 10., 5.e6
   zlim, 'el'+probe+'_pef_en_spec2plot_para', 10., 5.e6
   zlim, 'el'+probe+'_pef_pa_reg_spec2plot_ch0LC',100.,5.e6
   zlim, 'el'+probe+'_pef_pa_reg_spec2plot_ch1LC',100.,1.e6
   zlim, 'el'+probe+'_pef_pa_spec2plot_ch2LC',500.,5.e5
   zlim, 'el'+probe+'_pef_pa_spec2plot_ch3LC',10.,5000.

   options, 'el'+probe+'_pef_pa_reg_spec2plot_ch0LC',zstyle=1
   options, 'el'+probe+'_pef_pa_reg_spec2plot_ch0LC', 'ysubtitle','[deg]'
   options, 'el'+probe+'_pef_pa_reg_spec2plot_ch0LC', 'ztitle','#/(scm!U2!NstrMeV)'  
   options, 'el'+probe+'_pef_pa_reg_spec2plot_ch1LC',zstyle=1
   options, 'el'+probe+'_pef_pa_reg_spec2plot_ch1LC', 'ysubtitle','[deg]'
   options, 'el'+probe+'_pef_pa_reg_spec2plot_ch1LC', 'ztitle','#/(scm!U2!NstrMeV)'  
   options, 'el'+probe+'_pef_pa_spec2plot_ch2LC',zstyle=1
   options, 'el'+probe+'_pef_pa_spec2plot_ch2LC', 'ysubtitle','[deg]'
   options, 'el'+probe+'_pef_pa_spec2plot_ch2LC', 'ztitle','#/(scm!U2!NstrMeV)'  
   options, 'el'+probe+'_pef_pa_spec2plot_ch3LC',zstyle=1
   options, 'el'+probe+'_pef_pa_spec2plot_ch3LC', 'ysubtitle','[deg]'
   options, 'el'+probe+'_pef_pa_spec2plot_ch3LC', 'ztitle','#/(scm!U2!NstrMeV)'  

end
