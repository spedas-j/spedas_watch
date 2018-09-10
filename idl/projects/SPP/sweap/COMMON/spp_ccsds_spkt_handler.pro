; $LastChangedBy: phyllisw2 $
; $LastChangedDate: 2018-09-09 14:47:02 -0700 (Sun, 09 Sep 2018) $
; $LastChangedRevision: 25756 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/COMMON/spp_ccsds_spkt_handler.pro $

pro spp_ccsds_spkt_handler,dbuffer, source_dict = source_dict , wrap_ccsds=wrap_ccsds

  
    ccsds = spp_swp_ccsds_decom(dbuffer,wrap_ccsds=wrap_ccsds,dlevel=2)
    if ~keyword_set(ccsds) then begin
      if debug(2) then begin
        dprint,dlevel=2,'Invalid CCSDS'
      endif
      return
    endif
    
;    if  debug(5) then begin
;      ccsds_data = spp_swp_ccsds_data(ccsds)  
;      n = ccsds.pkt_size
;      if n gt 12 then ind = indgen(n-12)+12 else ind = !null      
;;      dprint,dlevel=4,format='(i3,i6," APID: ", Z03,"  SeqGrp:",i1, " Seqn: ",i5,"  Size: ",i5,"   ",8(" ",Z02))',npackets,offset,ccsds.apid,ccsds.seq_group,ccsds.seqn,ccsds.pkt_size,ccsds_data[ind]
;      dprint,dlevel=4,format='(i3,i6," APID: ", Z03,"  SeqGrp:",i1, " Seqn: ",i5,"  Size: ",i5,"   ")',npackets,offset,ccsds.apid,ccsds.seq_group,ccsds.seqn,ccsds.pkt_size   ;,ccsds_data[ind]
;    endif
        

    apdat = spp_apdat(ccsds.apid)

    if keyword_set( *apdat.ccsds_last) then begin
      ccsds_last = *apdat.ccsds_last
      dseq = (( ccsds.seqn - ccsds_last.seqn ) and '3fff'xu)
      ccsds.seqn_delta = dseq
      ccsds.time_delta = (ccsds.met - ccsds_last.met)
      ccsds.gap = (dseq gt ccsds_last.seqn_delta)
    endif   

    if debug(5) && ccsds.seqn_delta gt 1 then begin
      dprint,dlevel=5,format='("Lost ",i5," ",a," (0x", Z03,") packets ",i5," ",a)',  ccsds.seqn_delta-1,apdat.name,apdat.apid,ccsds.seqn,time_string(ccsds.time,prec=3)
    endif

    apdat.handler, ccsds , source_dict=source_dict    ;.source_info, header
    dummy = spp_rt(ccsds.time)     ; This line helps keep track of the current real time

    ;;  Save statistics - get APID_ALL and APID_GAP
    apdat.increment_counters, ccsds
    stats = spp_apdat(0)
    stats.handler, ccsds, source_dict = source_dict

end
