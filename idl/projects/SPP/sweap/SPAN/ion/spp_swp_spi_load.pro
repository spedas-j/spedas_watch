;+
;
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2019-04-19 16:24:07 -0700 (Fri, 19 Apr 2019) $
; $LastChangedRevision: 27047 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/ion/spp_swp_spi_load.pro $
; Created by Davin Larson 2018
;
;-

PRO spp_swp_spi_load, types=types, $
                      varformat=varformat, $
                      trange=trange, $
                      no_load=no_load, $
                      verbose=verbose

   ;; Add Archive and Tagerted when available
   IF ~keyword_set(types) THEN BEGIN 
    
      ;; - Survey - Full
      types = ['sf00', 'sf01', 'sf02', 'sf03',$
               'sf10', 'sf11', 'sf12', 'sf13',$
               'sf20', 'sf21', 'sf22', 'sf23']
      
      ;; - Survey - Targeted
      ;;types = ['st00', 'st01', 'st02', 'st03',$
      ;;         'st10', 'st11', 'st12', 'st13',$
      ;;         'st20', 'st21', 'st22', 'st23']
      
      ;; - Archive - Full
      ;;types = ['af00', 'af01', 'af02', 'af03',$
      ;;         'af10', 'af11', 'af12', 'af13',$
      ;;         'af20', 'af21', 'af22', 'af23']
      
      ;; - Archive - Targeted
      ;;types = ['at00', 'at01', 'at02', 'at03',$
      ;;         'at10', 'at11', 'at12', 'at13',$
      ;;         'at20', 'at21', 'at22', 'at23']

   ENDIF
      

   dir = 'SP?/L2/YYYY/MM/SP?_TYP/'
   fileprefix = 'psp/data/sci/sweap/'

   ;; Product File Names
   loc = orderedhash()
   loc['sf00'] = dir+'spp_swp_SP?_TYP_L2_8Dx32Ex8A_YYYYMMDD_v??.cdf'
   loc['sf01'] = dir+'spp_swp_SP?_TYP_L2_8Dx32Ex8A_YYYYMMDD_v??.cdf'
   loc['sf02'] = dir+'spp_swp_SP?_TYP_L2_8Dx32Ex8A_YYYYMMDD_v??.cdf'
   loc['sf03'] = dir+'spp_swp_SP?_TYP_L2_8Dx32Ex8A_YYYYMMDD_v??.cdf'
   loc['sf10'] = dir+'spp_swp_SP?_TYP_L2_8Dx32E_YYYYMMDD_v??.cdf'
   loc['sf11'] = dir+'spp_swp_SP?_TYP_L2_8Dx32E_YYYYMMDD_v??.cdf'
   loc['sf12'] = dir+'spp_swp_SP?_TYP_L2_8Dx32E_YYYYMMDD_v??.cdf'
   loc['sf13'] = dir+'spp_swp_SP?_TYP_L2_8Dx32E_YYYYMMDD_v??.cdf'
   loc['sf20'] = dir+'spp_swp_SP?_TYP_L2_32Ex16M_YYYYMMDD_v??.cdf'
   loc['sf21'] = dir+'spp_swp_SP?_TYP_L2_32Ex16M_YYYYMMDD_v??.cdf'
   loc['sf22'] = dir+'spp_swp_SP?_TYP_L2_32Ex16M_YYYYMMDD_v??.cdf'
   loc['sf23'] = dir+'spp_swp_SP?_TYP_L2_32Ex16M_YYYYMMDD_v??.cdf'

   loc['hkp'] = 'SP?/L1/YYYY/MM/SP?_hkp/spp_swp_SP?_hkp_L1_YYYYMMDD_v??.cdf'
   loc['tof'] = 'SP?/L1/YYYY/MM/SP?_tof/spp_swp_SP?_tof_L1_YYYYMMDD_v??.cdf'
   loc['rates'] = 'spi/L1/YYYY/MM/SP?_rates/spp_swp_spi_rates_L1_YYYYMMDD_v??.cdf'
   
   ;http://sprg.ssl.berkeley.edu/data/psp/data/sci/sweap/spi/L1/2019/03/spi_rates/spp_swp_spi_rates_L1_20190307_v00.cdf

   ;; Product TPLOT Parameters
   vars = orderedhash()
   vars['sf00'] = 'EFLUX EMODE *THETA* *PHI* *ENERG*'
   vars['sf01'] = 'EFLUX EMODE *THETA* *PHI* *ENERG*'
   vars['sf02'] = 'EFLUX EMODE *THETA* *PHI* *ENERG*'
   vars['sf03'] = 'EFLUX EMODE *THETA* *PHI* *ENERG*'
   vars['sf10'] = 'EFLUX EMODE *PHI* *ENERG*'
   vars['sf11'] = 'EFLUX EMODE *PHI* *ENERG*'
   vars['sf12'] = 'EFLUX EMODE *PHI* *ENERG*'
   vars['sf13'] = 'EFLUX EMODE *PHI* *ENERG*'
   vars['sf20'] = 'EFLUX EMODE *ENERG* *MASS*'
   vars['sf21'] = 'EFLUX EMODE *ENERG* *MASS*'
   vars['sf22'] = 'EFLUX EMODE *ENERG* *MASS*'
   vars['sf23'] = 'EFLUX EMODE *ENERG* *MASS*'

   vars['hkp']    = '*TEMP* *_BITS *_FLAG* RAW_EVENTS'
   vars['tof']    = '_*TOF'
   vars['rates']  = '*VALID*'
   ;;vars['events'] 
   
   tr = timerange(trange)
   foreach type,types DO BEGIN

      ;; Instrument string substitution
      fileformat = str_sub(loc[type],'SP?', 'spi')
      fileformat = str_sub(fileformat,'TYP',type)
      prefix = 'psp_swp_spi_'+type+'_'

      ;; Debugging
      dprint,fileformat,/phelp

      ;; Find file locations
      files = spp_file_retrieve($
              fileformat,trange=tr,/daily_names,$
              /valid_only,prefix=fileprefix,$
              verbose=verbose)

      ;; Do not load the files
      IF keyword_set(no_load) THEN CONTINUE

      ;; Load TPLOT Formats
      IF keyword_set(varformat) THEN $
       vfm = varformat ELSE vfm=vars[type]

      ;; Convert to TPLOT
      cdf2tplot, files, prefix=prefix, $
                 varformat=vfm, verbose=verbose

      ;; Housekeeping not working at the moment
      IF type EQ 'hkp' THEN BEGIN
         CONTINUE
      ENDIF

      ;; Set tplot Preferences
      ylim,prefix+'*EFLUX',  1.,10000.,1,/default
      Zlim,prefix+'*EFLUX',100., 2000.,1,/default
      
   endforeach
   ;; format = 'psp/data/sci/sweap/spa/L2/YYYY/MM/spa_sf1/spp_swp_spa_sf1_L2_*_YYYYMMDD_v??.cdf'
   ;; files = spp_file_retrieve(spa_format,/daily_names,/valid_only,/last_version,prefix=ssr_prefix,verbose=2,trange=tr)
   ;; cdf2tplot,spa_files,prefix = prefix,varformat='EFLUX EMODE'

END
