;+
;
;  Author: Davin Larson December 2018
;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2019-08-26 22:19:43 -0700 (Mon, 26 Aug 2019) $
; $LastChangedRevision: 27663 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/spp_fld_load.pro $
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

        if tnames('psp_fld_l2_mag_RTN') NE '' then begin
          options,'psp_fld_l2_mag_RTN',colors='bgr' ,/default
          options,'psp_fld_l2_mag_RTN',labels=['R','T','N'] ,/default
        endif

        if tnames('psp_fld_l2_mag_SC') NE '' then begin
          options,'psp_fld_l2_mag_SC',colors='bgr' ,/default
          options,'psp_fld_l2_mag_SC',labels=['X','Y','Z'] ,/default
        endif

      endif

    endelse

  endif


end
