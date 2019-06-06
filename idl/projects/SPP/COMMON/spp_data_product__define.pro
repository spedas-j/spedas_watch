;+
;  spp_data_product
;  This basic object is the entry point for defining and obtaining all data for all data products
; $LastChangedBy: -mac $
; $LastChangedDate: 2019-01-29 16:17:12 -0800 (Tue, 29 Jan 2019) $
; $LastChangedRevision:  $
; $URL: svn+ssh://thmsvn@pro $
;-
;COMPILE_OPT IDL2


FUNCTION spp_data_product::Init,_EXTRA=ex,data=data
  COMPILE_OPT IDL2
  ; Call our superclass Initialization method.
  void = self->generic_object::Init()
;  printdat,ex
;  self.data = dynamicarray(name=self.name)
  self.dict = dictionary()
  if keyword_set(data) then self.data_ptr = ptr_new(data)
  if  keyword_set(ex) then dprint,ex,phelp=2,dlevel=self.dlevel
  IF (ISA(ex)) THEN self->SetProperty, _EXTRA=ex
  RETURN, 1
END


pro spp_data_product::savedat,data
  if ~ptr_valid(self.data_ptr) then self.data_ptr = ptr_new(data) else *self.data_ptr = data
end

pro spp_data_product::make_tplot_var,tagnames
  if ptr_valid(self.data_ptr) then begin
    if ~keyword_set(tagnames) then begin
      print, 'Here are you options:'
      print,(tag_names(*self.data_ptr))
      return
    endif
    store_data,self.name+'_',data= *self.data_ptr,tagnames=strupcase(tagnames)
  endif
end


function spp_data_product::getdat,trange=trange,index=index,nsamples=nsamples,valname=valname
  if ~ptr_valid(self.data_ptr) then begin
    dprint,'No data loaded for: ',self.name
    return,!null
  endif

  ns = n_elements(*self.data_ptr)
  
  if isa(trange) then begin
    index = interp(lindgen(ns),(*self.data_ptr).time,trange)    
    index_range = minmax(round(index))
    index = [index_range[0]: index_range[1]]
    printdat,index
  endif

  if isa(index,/integer) then begin
    dats = (*self.data_ptr)[index]
    wbad = where(index lt 0,/null,nbad)
    if nbad gt 0 then begin
      fill = fill_nan(dats[wbad])
      dats[wbad] = fill
    endif
    if keyword_set(valname) then begin
      retval =!null
      str_element,dats,valname,retval
      return, retval
    endif
    return,dats
  endif

  if keyword_set(valname) then begin
    retval = !null
    str_element,(*self.data_ptr),valname,retval
    return, retval
  endif


  return, *self.data_ptr
end



PRO spp_data_product::GetProperty,  ptr=ptr, name=name , data=data,dict=dict
  ; This method can be called either as a static or instance.
  COMPILE_OPT IDL2
;  dprint,'hello',dlevel=3
  IF (ARG_PRESENT(ptr)) THEN ptr = self.data_ptr
;  IF (ARG_PRESENT(data_ptr)) THEN data_ptr = self.data_ptr
  if arg_present(dict) then dict = self.dict
  IF (ARG_PRESENT(data)) THEN begin
    if ptr_valid(self.data_ptr) then data = *self.data_ptr else begin
      data = !null
      dprint,dlevel=self.dlevel,'Warning: Invalid pointer for: '+self.name
    endelse
  ENDIF
  IF (ARG_PRESENT(name)) THEN name = self.name
END





PRO spp_data_product__define
  void = {spp_data_product, $
    inherits generic_object, $    ; superclas
    name: '',  $
;    tname: '',  $
;    ttags: '',  $
    dict: obj_new() , $
;    data_obj: obj_new(), $
    data_ptr: ptr_new(), $
;    cdf_pathname:'', $
;    cdf_tagnames:'', $
    user_ptr: ptr_new() $
  }
END



