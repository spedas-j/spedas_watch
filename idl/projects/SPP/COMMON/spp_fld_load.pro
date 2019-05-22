; 
;  Author: Davin Larson December 2018
; 
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2019-02-05 16:17:41 -0800 (Tue, 05 Feb 2019) $
; $LastChangedRevision:  $
; $URL:  $

pro spp_fld_load,  trange=trange, type = type, files=files, fileprefix=fileprefix,tname_prefix=tname_prefix, pathformat=pathformat,no_load=no_load,varformat=varformat

  if not keyword_set(fileprefix) then fileprefix = 'psp/data/sci/fields/staging/l2/'
  if not keyword_set(pathformat) then pathformat =  'TYPE/YYYY/MM/psp_fld_l2_TYPE_YYYYMMDD_v??.cdf'
  
  if not keyword_set(type) then begin
    dprint,'Choices for type are: mag_SC mag_RTN
    dprint,'See the directories at: "http://sprg.ssl.berkeley.edu/data/psp/data/sci/fields/staging/l2/" for other valid entries'
    type = 'mag_RTN'
    dprint,'Default is: ', type
  endif

  pathformat = str_sub(pathformat,'TYPE',type)
  pathformat = fileprefix+pathformat
  

  ;  example location: http://sprg.ssl.berkeley.edu/data/psp/data/sci/fields/staging/l2/mag_RTN/2019/04/psp_fld_l2_mag_RTN_20190401_v00.cdf
  pathformat = str_sub(pathformat,'ss', 's\s' )    ; replace ss with escape so that ss will not be converted to seconds

  files=spp_file_retrieve(key='FIELDS',pathformat,trange=trange,source=src,/last_version,/daily_names,/valid_only)
  
  if not keyword_set(no_load) then begin
    cdf2tplot,files    ,varformat=varformat,prefix=tname_prefix

    if strmatch(type,'rfs_?fr') then begin
      dprint,'Modifying limits'
      zlim,'*psp_fld_l2_rfs_?fr_*_V?V?',1e-16,1e-14,1 , /default
      ylim,'*psp_fld_l2_rfs_hfr_*_V?V?',1.1e6,22e6,1   , /default
      ylim,'*psp_fld_l2_rfs_lfr_*_V?V?',1e4,2e6,1   , /default
    endif

    if strmatch(type,'mag_*') then begin
      options,'psp_fld_l2_'+type,colors='bgr' ,/default
    endif
  endif

     
end
