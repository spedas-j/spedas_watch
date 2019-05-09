;+
;
; $LastChangedBy: ali $
; $LastChangedDate: 2019-05-08 12:55:43 -0700 (Wed, 08 May 2019) $
; $LastChangedRevision: 27208 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/ion/spp_swp_spi_load.pro $
; Created by Davin Larson 2018
;
;-

PRO spp_swp_spi_load, types=types, $
                      varformat=varformat, $
                      trange=trange, $
                      no_load=no_load, $
                      save=save,  $
                      verbose=verbose,$
                      loc=loc,$
                      vars=vars

   ;; Add Archive and Tagerted when available
   IF ~keyword_set(types) THEN BEGIN     
      ;; - Survey - Full
      types = ['sf00', 'sf01']
   ENDIF
      
   dir = 'SP?/L3/YYYY/MM/SP?_TYP/'
   fileprefix = 'psp/data/sci/sweap/'

   IF ~keyword_set(loc) THEN BEGIN 
      ;; Product File Names
      loc = orderedhash()
      loc['sf00'] = dir+'spp_swp_SP?_TYP_L3_8Dx32Ex8A_YYYYMMDD_v??.cdf'
      loc['sf01'] = dir+'spp_swp_SP?_TYP_L3_8Dx32Ex8A_YYYYMMDD_v??.cdf'
      loc['hkp'] = 'SP?/L1/YYYY/MM/SP?_hkp/spp_swp_SP?_hkp_L1_YYYYMMDD_v??.cdf'
      loc['tof'] = 'SP?/L1/YYYY/MM/SP?_tof/spp_swp_SP?_tof_L1_YYYYMMDD_v??.cdf'
      loc['rates'] = 'spi/L1/YYYY/MM/SP?_rates/spp_swp_spi_rates_L1_YYYYMMDD_v??.cdf'      
      ;;http://sprg.ssl.berkeley.edu/data/psp/data/sci/sweap/spi/L1/2019/03/spi_rates/spp_swp_spi_rates_L1_20190307_v00.cdf
   ENDIF

   IF ~keyword_set(vars) THEN BEGIN
      ;; Product TPLOT Parameters
      vars = orderedhash()
      vars['sf00'] = 'EFLUX EMODE *THETA* *PHI* *ENERG*'
      vars['sf01'] = 'EFLUX EMODE *THETA* *PHI* *ENERG*'
      vars['hkp']    = '*TEMP* *_BITS *_FLAG* RAW_EVENTS'
      vars['tof']    = '*'
      vars['rates']  = '*VALID*'
      ;;vars['events'] 
   ENDIF
   
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
              
      ;;               
      if keyword_set(save) then begin
        vardata = !null
        novardata = !null
        loadcdfstr,filenames=files,vardata,novardata
        dummy = spp_data_product_hash('spi_'+type,vardata)
      endif


      ;; Do not load the files
      IF keyword_set(no_load) THEN CONTINUE

      ;; Load TPLOT Formats
      IF keyword_set(varformat) THEN $
;       vfm = varformat ELSE vfm=vars[type]
       vfm = varformat
      ;; Convert to TPLOT
      cdf2tplot, files, prefix=prefix, $
                 varformat=vfm, verbose=verbose

      ;; Housekeeping not working at the moment
      IF type EQ 'hkp' THEN BEGIN
         CONTINUE
      ENDIF

      ;; Set tplot Preferences
  ;    ylim,prefix+'*EFLUX',  1.,10000.,1,/default
  ;    Zlim,prefix+'*EFLUX',100., 2000.,1,/default
      
   endforeach
   ;; format = 'psp/data/sci/sweap/spa/L2/YYYY/MM/spa_sf1/spp_swp_spa_sf1_L2_*_YYYYMMDD_v??.cdf'
   ;; files = spp_file_retrieve(spa_format,/daily_names,/valid_only,/last_version,prefix=ssr_prefix,verbose=2,trange=tr)
   ;; cdf2tplot,spa_files,prefix = prefix,varformat='EFLUX EMODE'

END
