; $LastChangedBy: davin-mac $
; $LastChangedDate: 2018-12-04 12:32:15 -0800 (Tue, 04 Dec 2018) $
; $LastChangedRevision: 26232 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/COMMON/spp_swp_load.pro $
;
;this is a test routine for now.
;

pro spp_swp_load

ssrfiles = spp_file_retrieve(/ssr)
spp_ssr_file_read,ssrfiles

spp_swp_tplot,'swem2',/setlim

ctime,t
spp_swp_ssrreadreq,t

end
