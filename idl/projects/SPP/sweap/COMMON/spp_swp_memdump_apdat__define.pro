;$LastChangedBy: ali $
;$LastChangedDate: 2021-06-14 10:41:21 -0700 (Mon, 14 Jun 2021) $
;$LastChangedRevision: 30043 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/COMMON/spp_swp_memdump_apdat__define.pro $

function spp_swp_memdump_apdat::decom,ccsds,source_dict=source_dict

  ccsds_data = spp_swp_ccsds_data(ccsds)
  offset = self.ccsds_offset

  strct = {  $
    time:         ccsds.time, $
    MET:          ccsds.met,  $
    apid:         ccsds.apid, $
    seqn:         ccsds.seqn,  $
    seqn_delta:   ccsds.seqn_delta,  $
    seqn_group:   ccsds.seqn_group,  $
    pkt_size:     ccsds.pkt_size,  $
    source_apid:  ccsds.source_apid,  $
    source_hash:  ccsds.source_hash,  $
    compr_ratio:  ccsds.compr_ratio,  $
    bsize: ccsds.pkt_size-offset-4, $
    addr: 0ul, $
    memp: ptr_new(),  $
    gap: ccsds.gap  $
  }

  mem = !null
  addr = spp_swp_data_select(ccsds_data,offset*8,32)  ;  address in memory
  strct.addr = addr
  if ccsds.pkt_size gt offset+4 then   mem = ccsds_data[offset+4:*] else dprint,dlevel=1,'Mem dump with 0 size. Address:',strct.addr
  memsize = n_elements(mem)
  strct.memp = ptr_new(mem)
  if debug(self.dlevel+3) then begin
    dprint,strct.addr, n_elements(mem),format='(Z08, i)'
    hexprint,mem
  endif

  if addr + memsize le self.ram_size then begin
    dprint,dlevel=self.dlevel+2, format='("Addr: ", Z06,"     size:",i)',addr,memsize
    (*self.diff)[addr: addr+memsize-1]  = mem - (*self.ram)[addr: addr+memsize-1]
    (*self.ram)[addr: addr+memsize-1]  = mem

    (*self.cntr)[addr: addr+memsize-1] += 1b
  endif else begin
    dprint, 'Not enough memory in object.', addr,memsize
  endelse

  self.display, addr / '100000'x

  return,strct
end


pro spp_swp_memdump_apdat::display,section,discntr=discntr,ram=ram,cntr=cntr,buffer=b,win_obj=win_obj

  if keyword_set(win_obj) then self.window_obj = win_obj
  ram=*self.ram
  cntr=*self.cntr

  if obj_valid(self.window_obj)  then begin
    win = self.window_obj
    if typename(win.uvalue) ne 'DICTIONARY'   then    win.uvalue = dictionary()
    if win.uvalue.haskey('ADDR_TEXT') eq 0 then  win.uvalue.ADDR_TEXT =  text(current = win,.01,.01,"XXXXXX")
    if win.uvalue.haskey('MEM_IMAGE') eq 0 then  win.uvalue.MEM_IMAGE =   image(current=win,dist(256,256),rgb_table=33)

    meg = 2UL ^20
    if not isa(section) then  section=0
    str = *self.last_data_p                                   ;

    if isa(str) then begin
      win.uvalue.addr_text.string = string(format='(Z06)',str.addr)

      if  not isa(discntr) then discntr = 2
      case discntr of
        0: b = *self.cntr
        1: b = *self.ram
        2: b = *self.diff
      endcase
      start = round(section * meg)
      b = b[start: start+meg-1]
      b = reform(b,1024,1024)
      win.uvalue.MEM_IMAGE.setdata, b

    endif
  endif
end


pro spp_swp_memdump_apdat::nomem
  *self.ram=!null
  *self.cntr=!null
  *self.diff=!null
end


function spp_swp_memdump_apdat::init,apid,name,_extra=ex
  valid = self->spp_gen_apdat::Init(apid,name,_EXTRA=ex)
  ;  printdat,apid
  switch apid of
    '342'x : begin
      self.ccsds_offset = 10
      self.ram_size = 8* 2UL^20
      break
    end
    '36d'x :
    '37d'x :
    '3b8'x : begin
      self.ccsds_offset = 12
      self.ram_size= 2* 2UL^20
      break
    end
  endswitch
  self.ram  = ptr_new(bytarr(self.ram_size))
  self.cntr = ptr_new(bytarr(self.ram_size))
  self.diff = ptr_new(bytarr(self.ram_size))
  return,valid
end


PRO spp_swp_memdump_apdat__define

  void = {spp_swp_memdump_apdat, $
    inherits spp_gen_apdat, $    ; superclass
    ccsds_offset: 0u , $
    ram_size : 0UL, $
    ram: ptr_new(), $
    diff: ptr_new(), $
    cntr: ptr_new() $
  }
END
