;
;  $LastChangedBy: pulupalap $
;  $LastChangedDate: 2019-01-30 21:11:34 -0800 (Wed, 30 Jan 2019) $
;  $LastChangedRevision: 26522 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_dfb_hk/spp_fld_dfb_hk_load_l1.pro $
;

pro spp_fld_dfb_hk_load_l1, file, prefix = prefix

  if not keyword_set(prefix) then prefix = 'spp_fld_dfb_hk_'

  cdf2tplot, /get_support_data, file, prefix = prefix


end