;
;  $LastChangedBy: spfuser2 $
;  $LastChangedDate: 2018-11-28 15:45:09 -0800 (Wed, 28 Nov 2018) $
;  $LastChangedRevision: 26181 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_dfb_hk/spp_fld_dfb_hk_load_l1.pro $
;

pro spp_fld_dfb_hk_load_l1, file, prefix = prefix

  if not keyword_set(prefix) then prefix = 'spp_fld_dfb_hk_'

  cdf2tplot, file, prefix = prefix


end