;+
;  spp_data_product
;  This basic object is the entry point for defining and obtaining all data for all data products
; $LastChangedBy: -mac $
; $LastChangedDate: 2019-01-29 16:17:12 -0800 (Tue, 29 Jan 2019) $
; $LastChangedRevision:  $
; $URL: svn+ssh://thmsvn@pro $
;-
;COMPILE_OPT IDL2


FUNCTION spp_data_product::Init,_EXTRA=ex
  COMPILE_OPT IDL2
  ; Call our superclass Initialization method.
  void = self->generic_object::Init()
  printdat,ex
;  self.data = dynamicarray(name=self.name)
  if  keyword_set(ex) then dprint,ex,phelp=2,dlevel=self.dlevel
  IF (ISA(ex)) THEN self->SetProperty, _EXTRA=ex
  RETURN, 1
END


pro spp_data_product::savedat,data
  if ~ptr_valid(self.data_ptr) then self.data_ptr = ptr_new(data) else *self.data_ptr = data
end


function spp_data_product::getdat,trange=trange
  if ~ptr_valid(self.data_ptr) then begin
    dprint,'No data loaded for: ',self.name
    return,!null
  endif
  
  if isa(trange) then begin
    index = interp(lindgen(n_elements((*self.data_ptr))),(*self.data_ptr).time,trange)
    printdat,index
    index = minmax(round(index))
    dats = (*self.data_ptr)[index[0]:index[1]]
    return,dats
  endif
  return, *self.data_ptr
end



PRO spp_data_product::GetProperty,  ptr=ptr, name=name 
  ; This method can be called either as a static or instance.
  COMPILE_OPT IDL2
  dprint,'hello',dlevel=3
  IF (ARG_PRESENT(ptr)) THEN ptr = self.data_ptr
  IF (ARG_PRESENT(name)) THEN name = self.name
END





PRO spp_data_product__define
  void = {spp_data_product, $
    inherits generic_object, $    ; superclas
    name: '',  $
    tname: '',  $
    ttags: '',  $
    data_obj: obj_new(), $
    data_ptr: ptr_new(), $
    cdf_pathname:'', $
    cdf_tagnames:'', $
    user_ptr: ptr_new() $
  }
END



