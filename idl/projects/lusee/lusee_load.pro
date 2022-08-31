;+
;
; NAME:
;   lusee_load
;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2022-08-30 09:41:59 -0700 (Tue, 30 Aug 2022) $
; $LastChangedRevision: 31059 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/lusee/lusee_load.pro $
;
;-

pro lusee_load, em_test = em_test

  if not keyword_set(em_test) then em_test = '20220811_lusee_scm_test'

  yyyy = test.SubString(0,3)
  mm   = test.SubString(4,5)

  test_dir = yyyy + '/' + mm + '/' + test + '/'

  remote_data_dir = 'http://research.ssl.berkeley.edu/data/spp/' + $
    'sppfldsoc/cdf_em_lusee/' + test_dir

  local_data_dir = root_data_dir() + 'lusee_em/' + test + '/'

  print, yyyy, mm

  l1_type = 'dfb_wf01'

  l1_fmt = '/fields/l1/' + l1_type + $
    '/' + yyyy + '/' + mm + '/lusee_l1_' + $
    l1_type + '_' + yyyy + mm + '*_*_v??.cdf'

  print, l1_fmt

  source = spp_file_source(key='FIELDS')

  l1_files = file_retrieve(l1_fmt, $
    remote_data_dir = remote_data_dir, local_data_dir = local_data_dir, $
    user_pass = getenv('FIELDS_USER_PASS'), /valid_only)

  if l1_files[0] NE '' then $
    spp_fld_load_l1, l1_files, varformat = varformat, $
    add_prefix = tname_prefix, add_suffix = tname_suffix, /lusee

end