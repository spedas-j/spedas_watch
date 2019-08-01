;+
;
;  Author: Davin Larson December 2018
;
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2019-02-05 16:17:41 -0800 (Tue, 05 Feb 2019) $
; $LastChangedRevision:  $
; $URL:  $
;
;-

pro spp_fld_load,  trange=trange, type = type, files=files, fileprefix=fileprefix,tname_prefix=tname_prefix, pathformat=pathformat,no_load=no_load,varformat=varformat, $
  level = level, get_support = get_support

  if not keyword_set(level) then level = 2

  if not keyword_set(fileprefix) then begin
    if level EQ 2 then fileprefix = 'psp/data/sci/fields/staging/l2/' else $
      fileprefix = 'psp/data/sci/fields/staging/l1/'
  endif
  if not keyword_set(pathformat) then begin
    if level EQ 2 then pathformat =  'TYPE/YYYY/MM/psp_fld_l2_TYPE_YYYYMMDD_v??.cdf' else $
      pathformat = 'TYPE/YYYY/MM/spp_fld_l1_TYPE_YYYYMMDD_v??.cdf'
  endif


  if not keyword_set(type) then begin
    dprint,'Choices for type are: mag_SC mag_RTN
    dprint,'See the directories at: "http://sprg.ssl.berkeley.edu/data/psp/data/sci/fields/staging/l2/" for other valid entries'
    type = 'mag_RTN'
    dprint,'Default is: ', type
  endif

  if (strmid(type, 0, 11) EQ 'dfb_dc_spec') or (strmid(type, 0, 11) EQ 'dfb_ac_spec') and level EQ 2 then begin
    
    pathformat = 'DIR' + pathformat
    
    pathformat = str_sub(pathformat, 'DIRTYPE', strmid(type, 0, 11))
    
  endif

  pathformat = str_sub(pathformat,'TYPE',type)
  pathformat = fileprefix+pathformat


  ;  example location: http://sprg.ssl.berkeley.edu/data/psp/data/sci/fields/staging/l2/mag_RTN/2019/04/psp_fld_l2_mag_RTN_20190401_v00.cdf
  pathformat = str_sub(pathformat,'ss', 's\s' )    ; replace ss with escape so that ss will not be converted to seconds

  if level EQ 1.5 then pathformat = str_sub(pathformat,'/l1/', '/l1b/' )
  if level EQ 1.5 then pathformat = str_sub(pathformat,'_l1_', '_l1b_' )

  files=spp_file_retrieve(key='FIELDS',pathformat,trange=trange,source=src,/last_version,/daily_names,/valid_only)

  if not keyword_set(no_load) then begin
    if level EQ 1 then begin
      spp_fld_load_l1, files, varformat = varformat
    endif else begin

      if strmatch(type,'rfs_?fr') then begin

        psp_fld_rfs_load_l2, files

      endif else begin

        cdf2tplot,files,varformat=varformat,prefix=tname_prefix,/get_support

      endelse

;      if strmatch(type,'rfs_?fr') then begin
;        dprint,'Modifying limits'
;        zlim,'*psp_fld_l2_rfs_?fr_*_V?V?',1e-16,1e-14,1 , /default
;        ylim,'*psp_fld_l2_rfs_hfr_*_V?V?',1.1e6,22e6,1   , /default
;        ylim,'*psp_fld_l2_rfs_lfr_*_V?V?',1e4,2e6,1   , /default
;      endif

      if strmatch(type,'mag_*') then begin
        options,'psp_fld_l2_'+type,colors='bgr' ,/default
      endif

    endelse

  endif


end
