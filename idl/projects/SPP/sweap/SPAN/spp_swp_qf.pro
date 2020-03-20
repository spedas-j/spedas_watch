;+
; $LastChangedBy: ali $
; $LastChangedDate: 2020-03-19 18:13:09 -0700 (Thu, 19 Mar 2020) $
; $LastChangedRevision: 28443 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/spp_swp_qf.pro $
;-

pro spp_swp_qf,prefix=prefix

  qf_labels = ['Counter Overflow','Snapshot On','Alternate Energy Table','Spoiler Test','Attenuator Engaged']
  options,verbose=0,prefix+'QUALITY_FLAG',tplot_routine='bitplot',numbits=5,yticks=6,psyms=2,labels=qf_labels,colors=[0,1,2,6],yticklen=1,ygridstyle=1,yminor=1

end