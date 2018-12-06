



;+
;  cdf_tools
;  This basic object is the entry point for reading and writing cdf files
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2018-12-05 12:46:20 -0800 (Wed, 05 Dec 2018) $
; $LastChangedRevision: 26252 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/cdf_tools__define.pro $
; 
; Written by Davin Larson October 2018
;-
 
 
 

;
;PRO cdf_tools::Cleanup
;  COMPILE_OPT IDL2
;  ; Call our superclass Cleanup method
;  self->IDL_Object::Cleanup
;END



;PRO cdf_tools::help
;  help,/obj,self
;END



 
 ;+
;NAME: SW_VERSION
;Function: 
;PURPOSE:
; Acts as a timestamp file to trigger the regeneration of SEP data products. Also provides Software Version info for the MAVEN SEP instrument.
;Author: Davin Larson  - January 2014
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2018-12-05 12:46:20 -0800 (Wed, 05 Dec 2018) $
; $LastChangedRevision: 26252 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/cdf_tools__define.pro $
;-


function cdf_tools::sw_version

  tb = scope_traceback(/structure)
  this_file = tb[n_elements(tb)-1].filename
  this_file_date = (file_info(this_file)).mtime
  login_info = get_login_info() 

  sw_hash = orderedhash()
  
  sw_hash['sw_version'] =  'v00'
  sw_hash['sw_time_stamp_file'] = this_file
  sw_hash['sw_time_stamp'] = time_string(this_file_date)
  sw_hash['sw_runtime'] = time_string(systime(1))
  sw_hash['sw_runby'] = login_info.user_name
  sw_hash['sw_machine'] = login_info.machine_name
  sw_hash['svn_changedby '] = '$LastChangedBy: davin-mac $'
  sw_hash['svn_changedate'] = '$LastChangedDate: 2018-12-05 12:46:20 -0800 (Wed, 05 Dec 2018) $'
  sw_hash['svn_revision '] = '$LastChangedRevision: 26252 $'

  return,sw_hash
end
 
;function cdf_tools::default_global_attributes
;  global_att=orderedhash()
; 
;  global_att['Project'] = 'PSP>Parker Solar Probe'
;  global_att['Source_name'] = 'PSP>Parker Solar Probe'
;  global_att['Acknowledgement'] = !NULL
;  global_att['TITLE'] = 'PSP SPAN Electron and Ion Flux'
;  global_att['Discipline'] = 'Heliospheric Physics>Particles'
;  global_att['Descriptor'] = 'INSTname>SWEAP generic Sensor Experiment'
;  global_att['Data_type'] = '>Survey Calibrated Particle Flux'
;  global_att['Data_version'] = 'v00'
;  global_att['TEXT'] = 'Reference Paper or URL'
;  global_att['MODS'] = 'Revision 0'
;  ;global_att['Logical_file_id'] =  self.name+'_test.cdf'  ; 'mvn_sep_l2_s1-cal-svy-full_20180201_v04_r02.cdf'
;  global_att['dirpath'] = './'
;  ;global_att['Logical_source'] = '.cal.spec_svy'
;  ;global_att['Logical_source_description'] = 'DERIVED FROM: PSP SWEAP'  ; SEP (Solar Energetic Particle) Instrument
;  global_att['Sensor'] = ' '   ;'SEP1'
;  global_att['PI_name'] = 'J. Kasper'
;  global_att['PI_affiliation'] = 'U. Michigan'
;  global_att['IPI_name'] = 'D. Larson (davin@ssl.berkeley.edu)
;  global_att['IPI_affiliation'] = 'U.C. Berkeley Space Sciences Laboratory'
;  global_att['InstrumentLead_name'] = '  ' 
;  global_att['InstrumentLead_affiliation'] = 'U.C. Berkeley Space Sciences Laboratory'
;  global_att['Instrument_type'] = 'Electrostatic Analyzer Particle Detector'
;  global_att['Mission_group'] = 'PSP'
;  global_att['Parents'] = '' ; '2018-02-17/22:17:38   202134481 ChecksumExecutableNotAvailable            /disks/data/maven/data/sci/pfp/l0_all/2018/02/mvn_pfp_all_l0_20180201_v002.dat ...
;  global_att = global_att + self.sw_version()
;
;return,global_att
;end


; default variable attributes
;function cdf_tools::cdf_variable_attributes
;  var_att = orderedhash()
;  var_att['FIELDNAM']= ''
;  var_att['MONOTON']= 'INCREASE'
;  var_att['FORMAT']= ''
;  var_att['FORM_PTR']= ''
;  var_att['LABLAXIS']= ''
;  var_att['LABL_PTR_1']= ''
;  var_att['VAR_TYPE']= 'support_data'
;  var_att['FILLVAL']= !values.f_nan
;  var_att['DEPEND_0']= 'Epoch'
;  var_att['DEPEND_1']= ''
;  var_att['DISPLAY_TYPE']= ''
;  var_att['VALIDMIN']= !null
;  var_att['VALIDMAX']= !null
;  var_att['SCALEMIN']= !null
;  var_att['SCALEMAX']= !null
;  var_att['UNITS']= ''
;  var_att['CATDESC']= ''
;  return,var_att
;end






;pro cdf_tools::create_data_vars, var, vattributes=atts, varstr
;   array = self.data.array    ; this should be an array of structures
;   if isa(array) then begin
;     varnames = tag_names(array)
;     ntags = n_elements(varnames)
;     for i=0,ntags-1 do begin
;       val = array.(i)
;       cdf_var_att_create,self.fileid,varnames[i],val,attributes=atts
;     endfor    
;   endif 
;end


pro cdf_tools::write,pathname,cdftags=cdftags,trange=trange
;  if not keyword_set(self.cdf_pathname) then return
  
  global_attributes = self.g_attributes
  if keyword_set(trange) then begin
    if not keyword_set(trange) then trange=timerange()
    pathname =  spp_file_retrieve(self.cdf_pathname ,trange=trange,/create_dir,/daily_names)
    global_attributes['Logical_file_id'] = str_sub(pathname,'$NAME$',self.name)

    pathname = global_attributes['Logical_file_id']
    
  endif 
  if ~isa(pathname,/string) then  pathname = 'temp.cdf'
  file_mkdir2,file_dirname(pathname)
  self.fileid = cdf_create(pathname,/clobber)
  dprint,'Making CDF file: ',pathname,dlevel=self.dlevel

  global_attributes = self.g_attributes  
  foreach attvalue,global_attributes,name do begin
    dummy = cdf_attcreate(self.fileid,name,/global_scope)
    for gentnum=0,n_elements(attvalue)-1 do begin
      cdf_attput,self.fileid,name,gentnum,attvalue[gentnum]
    endfor
  endforeach
  
  vars = self.vars
  foreach v,vars,k do begin
    self.var_att_create,v
  endforeach
  ;self.create_data_vars,fileid,vattributes=var_atts
   
  cdf_close,self.fileid
  self.fileid = 0
  dprint,'Created:  ',pathname,dlevel=self.dlevel
end



;function cdf_tools::struct    ; not needed, use self.getattr()
;  strct = create_struct(name=typename(self))
;  struct_assign , self, strct
;  return,strct
;END

 
 
 
;PRO cdf_tools::GetProperty,data=data, array=array, npkts=npkts, apid=apid, name=name,  typename=typename, $
;   nsamples=nsamples,nbytes=nbytes,strct=strct,ccsds_last=ccsds_last,tname=tname,dlevel=dlevel,ttags=ttags,last_data=last_data, $
;   window=window
;COMPILE_OPT IDL2
;IF (ARG_PRESENT(nbytes)) THEN nbytes = self.nbytes
;IF (ARG_PRESENT(name)) THEN name = self.name
;IF (ARG_PRESENT(tname)) THEN tname = self.tname
;IF (ARG_PRESENT(ttags)) THEN ttags = self.ttags
;IF (ARG_PRESENT(apid)) THEN apid = self.apid
;IF (ARG_PRESENT(npkts)) THEN npkts = self.npkts
;IF (ARG_PRESENT(ccsds_last)) THEN ccsds_last = self.ccsds_last
;IF (ARG_PRESENT(data)) THEN data = self.data
;if (arg_present(last_data)) then last_data = *(self.last_data_p)
;if (arg_present(window)) then window = self.window_obj
;IF (ARG_PRESENT(array)) THEN array = self.data.array
;IF (ARG_PRESENT(nsamples)) THEN nsamples = self.data.size
;IF (ARG_PRESENT(typename)) THEN typename = typename(*self.data)
;IF (ARG_PRESENT(dlevel)) THEN dlevel = self.dlevel
;if (arg_present(strct) ) then strct = self.struct()
;END
 
  
 
;PRO cdf_tools::SetProperty,apid=apid, _extra=ex
;COMPILE_OPT IDL2
;; If user passed in a property, then set it.
;;if isa(name,/string) then  self.name = name
;;if isa(routine,/string) then self.routine=routine
;if keyword_set(apid) then dprint,'apid can not be changed!'
;if keyword_set(ex) then begin
;  struct_assign,ex,self,/nozero
;endif
;END


function cdf_tools::cdf_var_type,strng
  stypes = 'CDF_'+strsplit(/extr,'XXX BYTE UINT1 INT1 CHAR UCHAR INT2 UINT2 INT4 UINT4 REAL4 FLOAT DOUBLE REAL8 EPOCH EPOCH16 LONG_EPOCH TIME_TT2000')
  vtypes = [0,1,1,1,1,1,2,12,3,13,4,4,5,5,5,9,9,14]
  type = array_union(strng,stypes)
  return,(vtypes[type])[0]
end


;+
; This is a wrapper routine to create CDF variables within an open CDF file.
; usage:
;  CDF_VAR_ATT_CREATE,fileid,'RandomVariable',randomn(seed,3,1000),attributes = atts
;  Attributes are contained in a orderedhash and should have already been created.
;-

pro cdf_tools::var_att_create,var

  dlevel = self.dlevel+1
  fileid = self.fileid
  varname = var.name
  data = var.data
  ZVARIABLE =  1  ; force it to be a zvar
;  ,name=varname,data=data,attributes=attributes,rec_novary=rec_novary,datatype=datatype
  rec_novary = ~var.recvary
  if isa(data,'DYNAMICARRAY') then begin
    data=  data.array 
    if size(/n_dimen,data) eq 2 then data = transpose(data)
    if size(/n_dimen,data) gt 2 then message,'Not ready'
  endif

  dim = var.d
  ndim = var.ndimen
  numrec = var.numrec
  numelem = var.numelem
  if ndim ge 1 then  dim = dim[0:ndim-1] else dim=0

  if keyword_set(var.datatype) then type=-1 else type = size(/type,data)
  case type of
    -1: cdf_type = create_struct(var.datatype,1)
    0: message,'No valid data provided'
    1: cdf_type = {cdf_uint1:1}
    2: cdf_type = {cdf_int2:1}
    3: cdf_type = {cdf_int4:1}
    4: cdf_type = {cdf_float:1}
    5: cdf_type = {cdf_double:1}
    12: cdf_type = {cdf_uint2:1}
    13: cdf_type = {cdf_uint4:1}
    else: begin
      dprint,'Please add data type '+string(type)+' to this case statement for variable: '+varname
      return
    end
  endcase
  opts = struct(cdf_type,ZVARIABLE=ZVARIABLE,rec_novary=rec_novary,numelem=numelem)

  
  dprint,dlevel=dlevel,phelp=2,varname,dim,opts,data
  if ~keyword_set(rec_novary)  then  begin
    if ndim ge 1 then begin
      varid = cdf_varcreate(fileid, varname,dim ne 0, DIMENSION=dim,_extra=opts)
    endif else begin
      varid = cdf_varcreate(fileid, varname,_extra=opts)
    endelse
  endif else begin
    if ndim ge 1 then begin
      varid = cdf_varcreate(fileid, varname,dim gt 1,dimension=dim,_extra=opts)      
    endif else begin
      varid = cdf_varcreate(fileid, varname,_extra=opts)      
    endelse
  endelse

  if keyword_set(data) then cdf_varput,fileid,varname,data else dprint,dlevel=self.dlevel,'Warning! No data written for '+varname


  if isa(var.attributes,'ORDEREDHASH')  then begin
    foreach value,var.attributes,attname do begin
      if not keyword_set(attname) then continue      ; ignore null strings
      if ~cdf_attexists(fileid,attname) then begin
        dummy = cdf_attcreate(fileid,attname,/variable_scope)
        dprint,dlevel=dlevel,'Created new Attribute: ',attname, ' for: ',varname
      endif
      if keyword_set(value) then begin
        cdf_attput,fileid,attname,varname,value  ;,ZVARIABLE=ZVARIABLE        
      endif
    endforeach
  endif else dprint,dlevel=1,'Warning! No attributes for '+varname

end



function cdf_tools::get_var_struct,  names, struct0=struct0,add_time = add_time
if not keyword_set(names) then names = self.varnames()
;if isa(struct0,'STRUCT') then strct0 = !null
if keyword_set(add_time) then str_element,/add,strct0,'TIME',!values.d_nan
numrec = 0
for i=0,n_elements(names)-1 do begin   ;    define first record structure;
  vi = self.vars[names[i]]
;  val = vi.data.array
  if vi.ndimen ge 1 then begin
    dim = vi.d
    dim = dim[where(dim ne 0)]
    val = make_array(type=vi.type,/nozero,  dimension=dim)  
  endif else begin
    val = make_array(type=vi.type,1,/nozero)
    val = val[0]
  endelse
  str_element,/add,strct0, names[i],val
  if numrec ne 0 then begin
    if numrec ne vi.numrec then dprint,'Warning! wrong number of records: ', names[i]
  endif
  numrec = numrec > vi.numrec    ; get largest record size
endfor

strct_n = replicate(strct0,numrec)
for i=0,n_elements(names)-1 do begin
  vi = self.vars[names[i]]
  vals = vi.data.array
  if size(/n_dimen,vals) ge 2 then begin   ; need a correction if ndimen >= 3
    vals = transpose(vals)
  endif
  str_element,/add,strct_n,names[i], vals 
endfor
  
if keyword_set(add_time) then begin
  time = time_ephemeris(strct_n.epoch / 1d9 ,/et2ut)
  strct_n.time = time
endif

return,strct_n
end


pro cdf_tools::filter_variables, index
;  vnames = self.vars.keys()
  foreach var,self.vars,vname do begin
    if var.recvary then begin
      array = var.data.array
      case var.ndimen of  
        0:  var.data.array = array[index] 
        1:  var.data.array = array[index,*]
        2:  var.data.array = array[index,*,*]
        3:  var.data.array = array[index,*,*,*]
      endcase
    endif
  endforeach
end




pro cdf_tools::add_variable,vi
  if isa(vi,'OBJREF') then begin
    self.vars[vi.name] = vi.getattr()
    return
  endif
  self.vars[vi.name] = vi
end


function cdf_tools::datavary_struct,varnames=varnames
  strct0 = !null
  maxrec = 0
  foreach v,self.vars,k do begin
    maxrec = maxrec > v.numrec
    if 1 then begin
      printdat,v
      dat0 = make_array(type = v.type,dimension=v.d[0:v.ndimen-1 > 0] > 1 )
      if v.ndimen eq 0 then dat0 = dat0[0]
      printdat,dat0
    endif else begin
      dat=v.data.array
      printdat,v
      case v.ndimen of
        0: dat0= dat[0]
        1: dat0= reform(dat[0,*])
        2: dat0= reform(dat[0,*,*])
        3: dat0= reform(dat[0,*,*,*])
      endcase      
    endelse
    strct0 = create_struct(strct0,k,dat0)
  endforeach
  strct = replicate(strct0,maxrec)
  foreach v,self.vars,k do begin
    dat=v.data.array
    strct.(k) = transpose(dat)
  endforeach


  printdat,strct
  
  
  return,strct
end


function cdf_tools::varnames,data=data
  vnames = self.vars.keys()
  l=list()
  depend = list()
  if keyword_set(data) then begin
    foreach v,self.vars,k do begin      
      if v.attributes.haskey('VAR_TYPE') && v.attributes['VAR_TYPE'] eq 'data' then begin
        l.add ,k  ; v.attributes['VAR_TYPE'].name
        if v.attributes.haskey('DEPEND_0') then depend.add, v.attributes['DEPEND_0']
        if v.attributes.haskey('DEPEND_1') then depend.add, v.attributes['DEPEND_1']
        if v.attributes.haskey('DEPEND_2') then depend.add, v.attributes['DEPEND_2']
      endif
    endforeach
    depend = depend.sort()
    depend = depend[ uniq( depend.toarray() ) ]
    l = l + depend
    return, l.toarray()
    
  endif
  return,vnames.toarray()

end





pro cdf_tools::read,filename
   info = cdf_info2(filename,/data,/attri)
   self.filename = info.filename
   *self.inq_ptr = info.inq
   self.g_attributes = info.g_attributes
;   self.nv  = info.nv
   self.vars = info.vars
end



 
 
PRO cdf_tools::GetProperty, filename=filename, vars=vars, G_attributes=G_attributes, nvars=nvars
COMPILE_OPT IDL2
IF (ARG_PRESENT(filename)) THEN filename = self.filename
IF (ARG_PRESENT(nvars)) THEN nv = n_elements(self.vars)
IF (ARG_PRESENT(G_attributes)) THEN G_attributes = self.G_attributes
IF (ARG_PRESENT(vars)) THEN vars = self.vars
END
 
 


FUNCTION cdf_tools::Init,filename,_EXTRA=ex
  COMPILE_OPT IDL2
  ; Call our superclass Initialization method.
; void = self.generic_Object::Init()
  self.inq_ptr = ptr_new(!null)
  self.g_attributes = orderedhash()
  self.vars = orderedhash()
  if keyword_set(name) then begin
    self.name  =name
    ;  insttype = strsplit(self.name
    ;  self.cdf_pathname = prefix + 'sweap/spx/
  endif
  ; self.data = dynamicarray(name=name)
  self.dlevel = 3
  if debug(3) and keyword_set(ex) then dprint,ex,phelp=2,dlevel=self.dlevel
  IF (ISA(ex)) THEN self->SetProperty, _EXTRA=ex
  if isa(filename,/string) then self.read,filename
  RETURN, 1
END








PRO cdf_tools__define
void = {cdf_tools, $
  inherits generic_object, $    ; superclass
  filename: '',  $
  fileid:  0uL,  $
  inq_ptr:  ptr_new() ,  $          ; pointer to inquire structure 
  G_attributes: obj_new(),  $     ; ordered hash
;  nv:  0     , $
  vars:  obj_new(),   $           ; ordered hash with variables
  dummy:0 }

END



