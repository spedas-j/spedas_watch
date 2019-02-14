
;$LastChangedBy: davin-mac $
;$LastChangedDate: 2019-02-13 17:49:40 -0800 (Wed, 13 Feb 2019) $
;$LastChangedRevision: 26627 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/sppeva/source/data/sppeva_get_fld.pro $



PRO sppeva_get_fld, apid_name,trange=trange
  compile_opt idl2


  if undefined(apid_name) then apid_name = 'f1_100bps'

  ;remote_site = 'http://sprg.ssl.berkeley.edu/data/spp/data/sci/fields/l1/'
  
  if strmid(apid_name, 0, 3) EQ 'dfb' then begin
    final_underscore = strpos(apid_name, '_', /reverse_search)
    apid_name = strmid(apid_name, 0, final_underscore) + $
      strmid(apid_name, final_underscore + 1)
  endif
  if apid_name EQ 'dcb_ssr_telemetry' then apid_name = 'dcb_s\sr_telemetry'
  if apid_name EQ 'rfs_hfr_cross' then apid_name = 'rfs_hfr_cros\s'

  trange = timerange(trange)

 ; remote_site = 'http://sprg.ssl.berkeley.edu/data/'

  prefix = 'spp/data/sci/fields/staging/l1/'  
  source = spp_file_source(source_key='FIELDS')
  source.local_data_dir += prefix
  pathname = prefix + apid_name +'/YYYY/MM/spp_fld_l1_' + apid_name + '_YYYYMMDD_v00.cdf'
  files = file_retrieve(pathname,/daily,valid_only=1,  trange = trange, _extra=source)
  
  ;------------
  ; LOAD
  ;------------
  
  files = spp_file_retrieve(prefix + apid_name +'/YYYY/MM/spp_fld_l1_' + apid_name + '_YYYYMMDD_v00.cdf', source=source,/daily_names,/valid_only,  trange = trange)
  
 ; http://sprg.ssl.berkeley.edu/data/spp/data/sci/fields/staging/l1/mago_survey/2018/11/

;  valid_files = where(file_test(files) eq 1,valid_count)
  
  if keyword_set(files) then begin
     spp_fld_load_l1, files
 ;   spp_fld_load_l1, files[valid_files]
  end
  
  ;------------
  ; OPTIONS
  ;------------
  
  tp = 'spp_fld_f1_100bps_DFB_SCM_PEAK_converted'
  if spd_data_exists(tp, trange[0], trange[1]) then begin
    options, tp, zlog=1 
  endif
  tp = 'spp_fld_f1_100bps_DFB_V34AC_PEAK_converted'
  if spd_data_exists(tp, trange[0], trange[1]) then begin
    options, tp, zlog=1
  endif 

END