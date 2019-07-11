;
;  $LastChangedBy: pulupalap $
;  $LastChangedDate: 2019-07-10 10:58:32 -0700 (Wed, 10 Jul 2019) $
;  $LastChangedRevision: 27428 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_dfb_hk/spp_fld_dfb_hk_load_l1.pro $
;

pro spp_fld_dfb_hk_load_l1, file, prefix = prefix, varformat = varformat

  if not keyword_set(prefix) then prefix = 'spp_fld_dfb_hk_'

  cdf2tplot, /get_support_data, file, prefix = prefix, varformat = varformat


end