;Ali: March 2020
;+
; $LastChangedBy: ali $
; $LastChangedDate: 2020-08-10 12:22:31 -0700 (Mon, 10 Aug 2020) $
; $LastChangedRevision: 29013 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/spp_swp_qf.pro $
;-

pro spp_swp_qf,prefix=prefix

  if ~keyword_set(prefix) then prefix=''
  qf_labels = ['Counter Overflow','Snapshot On','Alt. Energy Table','Spoiler Test','Attenuator Engaged']
  options,verbose=0,prefix+'QUALITY_FLAG',tplot_routine='bitplot',numbits=5,yticks=6,psyms=2,labels=qf_labels,colors=[0,1,2,6],yticklen=1,ygridstyle=1,yminor=1

end
