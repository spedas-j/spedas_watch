; $LastChangedBy: -mac $
; $LastChangedDate: 20Jun 2018) $
; $LastChangedRevision:  $
; $URL: svn+ssh://thm.pro $
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
