;+
;  cmblk_keysight
;  This object works with the common block files to decommutate data from Keysight power supplies
; $LastChangedBy:  $
; $LastChangedDate:  $
; $LastChangedRevision:  $
; $URL:  $
;-

COMPILE_OPT IDL2


pro cmblk_keysight::handle,payload,source_dict = source_dict

  dprint,dlevel=4,verbose=self.verbose,n_elements(payload),' Bytes for Handler: "',self.name,'"'
  self.nbytes += n_elements(payload)
  self.npkts  += 1


  dprint,verbose=self.verbose,dlevel=4,n_elements(payload)
  if self.run_proc then begin
    cmbhdr =  source_dict.cmbhdr

    fnan = !values.f_nan
    dnan = !values.d_nan
    format={ $
      time:dnan, $
      dtime:fnan, $
      V: replicate(fnan,6), $
      I: replicate(fnan,6), $
      gap:0 $
      }
    
    str = string(payload)
    time1 = cmbhdr.time
    psnum = fix(cmbhdr.source)
    ss = strsplit(/extract,str,' ')
    if n_elements(ss) eq 14 then begin
      time2 = time_double(ss[0]+' '+ss[1])
      vals = float(ss[2:*])
      format.time = time1
      format.dtime = time2-time1
      format.V =vals[[ 0,2,4,6,8,10] ]
      format.I =vals[[ 1,3,5,7,9,11] ]      
    endif
    tname = 'KEYSIGHT'+strtrim(psnum,2)
    store_data,/append,tname+'_',data=format,tagnames='DTIME V I',gap=format.gap

    if debug(3,self.verbose,msg=self.name + ' handler') then begin
      ;print,strtrim(psnum) + '  '+string(str)
      ;printdat,vals
      print,vals
    endif


  endif



end



PRO cmblk_keysight__define
  void = {cmblk_keysight, $
    inherits socket_reader, $    ; superclass
    ddata: obj_new(),  $
    powersupply_num:0    $           ; not actually used
  }
END


