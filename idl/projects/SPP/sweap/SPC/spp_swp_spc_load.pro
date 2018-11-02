; $LastChangedBy: davin-mac $
; $LastChangedDate: 2018-11-01 15:52:23 -0700 (Thu, 01 Nov 2018) $
; $LastChangedRevision: 26044 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPC/spp_swp_spc_load.pro $

pro spp_swp_spc_load,files, L2=L2, trange=trange, type = type

   l2=1
   if not keyword_set(type) then type = 'l2'
;   if keyword_set(L2) then begin
      pathname = 'psp/data/sci/sweap/spc/L2/YYYY/MM/spp_swp_spc_'+type+'_YYYYMMDD_v??.cdf'
;   endif
   
   if not keyword_set(files) then files = spp_file_retrieve(pathname,trange=trange,/last_version,/daily_names)
   cdf2tplot,files,prefix = 'spp_spc_'+type+'_'

end
