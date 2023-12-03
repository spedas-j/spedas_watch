;$LastChangedBy: davin-mac $
;$LastChangedDate: 2023-12-02 00:05:21 -0800 (Sat, 02 Dec 2023) $
;$LastChangedRevision: 32261 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/swx/swx_ccsds_data.pro $

function swx_ccsds_data,ccsds
  if typename(ccsds) eq 'SWX_CCSDS_FORMAT' then data = *ccsds.pdata  else data=ccsds.data
  return,data
end
