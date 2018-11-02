;+
;  cdf_tools
;  This basic object is the entry point for reading and writing cdf files
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2018-11-01 15:52:23 -0700 (Thu, 01 Nov 2018) $
; $LastChangedRevision: 26044 $
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
; $LastChangedDate: 2018-11-01 15:52:23 -0700 (Thu, 01 Nov 2018) $
; $LastChangedRevision: 26044 $
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
  sw_hash['svn_changedate'] = '$LastChangedDate: 2018-11-01 15:52:23 -0700 (Thu, 01 Nov 2018) $'
  sw_hash['svn_revision '] = '$LastChangedRevision: 26044 $'

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

  
 ; var_atts = self.cdf_variable_attributes()
;  foreach att,var_atts,name do begin
;    dummy = cdf_attcreate(fileid,name,/variable_scope)  ;  Variable attributes are created - but not filled
;  endforeach
  
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

  dlevel = self.dlevel
  fileid = self.fileid
  varname = var.name
  data = var.data
  ZVARIABLE = var.IS_ZVAR  || 1  ; force it to be a zvar
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

  
  dprint,dlevel=3,phelp=2,varname,dim,opts,data
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
        dprint,dlevel=self.dlevel,'Created new Attribute: ',attname, ' for: ',varname
      endif
      cdf_attput,fileid,attname,varname,value  ;,ZVARIABLE=ZVARIABLE
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




pro cdf_tools::add_variable,vi
  self.vars[vi.name] = vi
end


;  The following function is obsolete and will be changed

;function cdf_tools::info,id0,data=ret_data,attributesf=ret_attr,verbose=verbose,convert_int1_to_int2=convert_int1_to_int2
;  tstart = systime(1)
;  if n_elements(id0) eq 0 then id0 = dialog_pickfile(/multi)
;  vb = keyword_set(verbose) ? verbose : 0
;
;  ;for i=0,n_elements(id0)-1 do begin
;
;  if size(/type,id0) eq 7 then begin
;    if file_test(id0) then  id=cdf_open(id0)  $
;    else begin
;      if vb ge 1 then dprint,verbose=verbose,'File not found: "'+id0+'"'
;      return,0
;    endelse
;  endif  else id=id0
;
;  inq = cdf_inquire(id)
;  q = !quiet
;  cdf_control,id,get_filename=fn
;  ; need to add .cdf to the filename, since "cdf_control,id, get_filename="
;  ;    returns the filename without the extension
;  fn = fn + '.cdf'
;
;  nullp = ptr_new()
;  varinfo_format = {name:'',num:0, is_zvar:0, datatype:'',type:0, $
;    ;   depend_0:'', $
;    numattr:-1,  $
;    ;   userflag1:0, $
;    ;   userstr1:'', $
;    ;   index:0,     $
;    numelem:0, recvary:0b, numrec:0l, $
;    ndimen:0, d:lonarr(6) , $
;    dataptr:ptr_new(), attrptr:ptr_new()  }
;
;  nv = inq.nvars+inq.nzvars
;  vinfo = nv gt 0 ? replicate(varinfo_format, nv) : 0
;  i = 0
;  g_atts = cdf_var_atts(id)
;  g_att_names = cdf_var_atts(id,/names_only)   ; If cdf_var_atts were modified slightly these calls could be made in parallel
;  num_recs =0
;  t0=systime(1)
;
;  att=0
;  for zvar = 0,1 do begin   ; regular variables first, then zvariables
;    nvars = zvar ? inq.nzvars : inq.nvars
;    for v = 0,nvars-1 do begin
;      vi = cdf_varinq(id,v,zvar=zvar)
;      vinfo[i].num = v
;      vinfo[i].is_zvar = zvar
;      vinfo[i].name = vi.name
;      vinfo[i].datatype = vi.datatype
;      vinfo[i].type = self.cdf_var_type(vi.datatype)
;      vinfo[i].numelem = vi.numelem
;      recvar = vi.recvar eq 'VARY'
;      vinfo[i].recvary = recvar
;
;      if recvar then begin
;        ;if vb ge 6 then print,ptrace(),v,' '+vi.name
;        !quiet = 1
;        cdf_control,id,var=v,get_var_info=info,zvar = zvar
;        !quiet = q
;        ;if vb ge 7 then print,ptrace(),vi.name
;        nrecs = info.maxrec+1
;      endif else nrecs = -1
;      vinfo[i].numrec = nrecs
;
;      if zvar then begin
;        dimen = [vi.dim]
;        ndimen = total(vi.dimvar)
;      endif else begin
;        dimc = vi.dimvar * inq.dim
;        w = where(dimc ne 0,ndimen)
;        if ndimen ne 0 then dimen = dimc[w] else dimen=0
;      endelse
;      vinfo[i].ndimen = ndimen
;      vinfo[i].d =  dimen
;      ;dprint,dlevel=3,phelp=3,vi,dimen,dimc
;      t2 = systime(1)
;      dprint,dlevel=8,verbose=verbose,v,systime(1)-t2,' '+vi.name
;      if keyword_set(ret_data) then begin
;        message,'Routine not finished use cdf_load_vars'
;        ;       var_type=''
;        ;       str_element,attr,'VAR_TYPE',var_type
;        cdf_varget,id,vi.name,value  ;,rec_count=nrecs                ;,string= var_type eq 'metadata'
;        value=reform(value,/overwrite)                             ;  get rid of trailing 1's
;        vinfo[i].dataptr = ptr_new(value,/no_copy)
;      endif
;
;      if keyword_set(ret_attr) then begin
;        ;       attr = cdf_var_atts(id,vi.name,attribute=att, convert_int1_to_int2=convert_int1_to_int2)   ;   Slow version
;        attr = cdf_var_atts(id, v,zvar=zvar,  attribute=att, convert_int1_to_int2=convert_int1_to_int2)   ; Fast Version
;        vinfo[i].attrptr = ptr_new(attr,/no_copy)
;      endif
;      i = i+1
;      dprint,dlevel=8,verbose=verbose,v,systime(1)-t0,' '+vi.name
;      t0=systime(1)
;    endfor
;  endfor
;
;  res = create_struct('filename',fn,'inq',inq,'g_attributes',g_atts,'g_att_names',g_att_names,'nv',nv,'vars',vinfo)  ;'num_recs',num_recs,'nvars',nv
;  if size(/type,id0) eq 7 then cdf_close,id
;
;  dprint,dlevel=4,verbose=verbose,'Time=',systime(1)-tstart
;  return,res
;end

 
 ;  The following function is obsolete and will be changed
; function cdf_tools::cdf_load_vars,files,varnames=vars,varformat=vars_fmt,info=info,verbose=verbose,all=all, $
;  record=record,convert_int1_to_int2=convert_int1_to_int2, $
;  spdf_dependencies=spdf_dependencies, $
;  var_type=var_type, $
;  no_attributes=no_attributes,$
;  number_records=number_records
;
;  vb = keyword_set(verbose) ? verbose : 0
;  vars=''
;  info = 0
;  dprint,dlevel=4,verbose=verbose,'$Id: cdf_tools__define.pro 26044 2018-11-01 22:52:23Z davin-mac $'
;
;    on_ioerror, ferr
;  for fi=0,n_elements(files)-1 do begin
;    if file_test(files[fi]) eq 0 then begin
;      dprint,dlevel=1,verbose=verbose,'File not found: "'+files[fi]+'"'
;      continue
;    endif
;    id=cdf_open(files[fi])
;    if not keyword_set(info) then begin
;      info = cdf_info(id,verbose=verbose) ;, convert_int1_to_int2=convert_int1_to_int2)
;    endif
;    ; if there are no variables loaded
;    if info.nv eq 0 or ~is_struct(info.vars) then begin
;      dprint,verbose=verbose,'No valid variables in the CDF file!'
;      return,info
;    endif
;
;    if n_elements(spdf_dependencies) eq 0 then spdf_dependencies =1
;
;    if not keyword_set(vars) then begin
;      if keyword_set(all) then vars_fmt = '*'
;      if keyword_set(vars_fmt) then vars = [vars, strfilter(info.vars.name,vars_fmt,delimiter=' ')]
;      if keyword_set(var_type) then begin
;        vtypes = strarr(info.nv)
;        for v=0,info.nv-1 do begin
;          vtypes[v] = cdf_var_atts(id,info.vars[v].num,zvar=info.vars[v].is_zvar,'VAR_TYPE',default='')
;        endfor
;        w = strfilter(vtypes,var_type,delimiter=' ',count=count,/index)
;        if count ge 1 then vars= [vars, info.vars[w].name] else dprint,dlevel=1,verbose=verbose,'No VAR_TYPE matching: ',VAR_TYPE
;      endif
;      vars = vars[uniq(vars,sort(vars))]
;      if n_elements(vars) le 1 then begin
;        dprint,verbose=verbose,'No valid variables selected to load!'
;        return,info
;      endif else vars=vars[1:*]
;      vars2=vars
;
;      ;        if vb ge 4 then printdat,/pgmtrace,vars,width=200
;
;      if keyword_set(spdf_dependencies) then begin  ; Get all the variable names that are dependents
;        depnames = ''
;        for i=0,n_elements(vars)-1 do begin
;          vnum = where(vars[i] eq info.vars.name,nvnum)
;          if nvnum eq 0 then message,'This should never happen, report error to D. Larson: davin@ssl.berkeley.edu'
;          vi = info.vars[vnum]
;          depnames = [depnames, cdf_var_atts(id,vi.num,zvar=vi.is_zvar,'DEPEND_TIME',default='')]   ;bpif vars[i] eq 'tha_fgl'
;          depnames = [depnames, cdf_var_atts(id,vi.num,zvar=vi.is_zvar,'DEPEND_0',default='')]
;          depnames = [depnames, cdf_var_atts(id,vi.num,zvar=vi.is_zvar,'LABL_PTR_1',default='')]
;          ndim = vi.ndimen
;          for j=1,ndim do begin
;            depnames = [depnames, cdf_var_atts(id,vi.num,zvar=vi.is_zvar,'DEPEND_'+strtrim(j,2),default='')]
;          endfor
;        endfor
;        if keyword_set(depnames) then depnames=depnames[[where(depnames)]]
;        depnames = depnames[uniq(depnames,sort(depnames))]
;        vars2 = [vars2,depnames]
;        vars2 = vars2[uniq(vars2,sort(vars2))]
;        vars2 = vars2[where(vars2)]
;        ;            if vb ge 4 then printdat,/pgmtrace,depnames,width=200
;      endif
;    endif
;
;    dprint,dlevel=2,verbose=verbose,'Loading file: "'+files[fi]+'"'
;    for j=0,n_elements(vars2)-1 do begin
;      w = (where( strcmp(info.vars.name, vars2[j]) , nw))[0]
;      if nw ne 0 && cdf_varnum(id,info.vars[w].name) ne -1 then begin ; cdf_varnum call avoids crash for cdfs with non-existent dependent variables
;        vi = info.vars[w]
;        dprint,verbose=verbose,dlevel=7,vi.name
;
;        ;            if vb ge 9 then  wait,.2
;        ;            if   vi.recvary or 1  then begin ;disabling logic that does nothing, pcruce@igpp.ucla.edu
;
;        q=!quiet & !quiet=1 & cdf_control,id,variable=vi.name,get_var_info=vinfo & !quiet=q
;
;        ;adding logic to select the number of records that are loaded.  Helps for testing with large CDFs, can be used with the record= keyword
;        if n_elements(number_records) ne 0 then begin
;          numrec=number_records<(vinfo.maxrec+1)
;        endif else begin
;          if n_elements(record) ne 0 then begin
;            numrec=1<(vinfo.maxrec+1)
;          endif else begin
;            numrec = vinfo.maxrec+1
;          endelse
;        endelse
;        ;                dprint,verbose=vb,dlevel=7,vi.name
;        ;                if vb ge 9 then  wait,.2
;        ;            endif else numrec = 0
;
;        if numrec gt 0 then begin
;          q = !quiet
;          !quiet = keyword_set(convert_int1_to_int2)
;          if n_elements(record) ne 0  then begin
;            value = 0 ;THIS line TO AVOID A CDF BUG IN CDF VERSION 3.1
;            cdf_varget,id,vi.name,value ,/string ,rec_start=record,rec_count=numrec
;          endif else begin
;
;            if vi.is_zvar then begin
;              value = 0 ;THIS Line TO AVOID A CDF BUG IN CDF VERSION 3.1
;              cdf_varget,id,vi.name,value ,/string ,rec_count=numrec
;              ;CDF_varget,id,CDF_var,x,REC_COUNT=nrecs,zvariable = zvar,rec_start=rec_start
;            endif else begin
;
;              if 1 then begin     ; this cluge works but is not efficient!
;                vinq = cdf_varinq(id,vi.num,zvar=vi.is_zvar)
;                dimc = vinq.dimvar * info.inq.dim
;                dimw = where(dimc eq 0,c)
;                if c ne 0 then dimc[dimw] = 1  ;bpif vi.name eq 'ion_vel'
;              endif
;              value = 0   ;THIS Line TO AVOID A CDF BUG IN CDF VERSION 3.1
;              CDF_varget,id,vi.num,zvar=0,value,/string,COUNT=dimc,REC_COUNT=numrec  ;,rec_start=rec_start
;              value = reform(value,/overwrite)
;              dprint,phelp=2,dlevel=5,vi,dimc,value
;            endelse
;          endelse
;          !quiet = q
;          if vi.recvary then begin
;            if (vi.ndimen ge 1 and n_elements(record) eq 0) then begin
;              if numrec eq 1 then begin
;                dprint,dlevel=3,'Warning: Single record! ',vi.name,vi.ndimen,vi.d
;                value = reform(/overwrite,value, [1,size(/dimensions,value)] )  ; Special case for variables with a single record
;              endif else begin
;                transshift = shift(indgen(vi.ndimen+1),1)
;                value=transpose(value,transshift)
;              endelse
;            endif else value = reform(value,/overwrite)
;            if not keyword_set(vi.dataptr) then  vi.dataptr = ptr_new(value,/no_copy)  $
;            else  *vi.dataptr = [*vi.dataptr,temporary(value)]
;          endif else begin
;            if not keyword_set(vi.dataptr) then vi.dataptr = ptr_new(value,/no_copy)
;          endelse
;        endif
;        if not keyword_set(vi.attrptr) then begin
;          var_atts = cdf_var_atts(id,vi.name,convert_int1_to_int2=convert_int1_to_int2)
;          if not keyword_set(var_atts) then vi.attrptr = ptr_new(/allocate_heap) $
;          else vi.attrptr = ptr_new(var_atts)
;        end
;        info.vars[w] = vi
;      endif else  dprint,dlevel=1,verbose=verbose,'variable "'+vars2[j]+'" not found!'
;    endfor
;    cdf_close,id
;  endfor
;
;  if keyword_set(info) and keyword_set(convert_int1_to_int2) then begin
;    w = where(info.vars.datatype eq 'CDF_INT1',nw)
;    for i=0,nw-1 do begin
;      v = info.vars[w[i]]
;      if ptr_valid(v.dataptr) then begin
;        dprint,dlevel=5,verbose=verbose,'Warning: Converting from INT1 to INT2 (',v.name ,')'
;        val = *v.dataptr
;        *v.dataptr = fix(val) - (val ge 128) * 256
;      endif
;    endfor
;  endif
;
;  return,info
;
;  ferr:
;  dprint,dlevel=0,"CDF FILE ERROR in: ",files[fi]
;  msg = !error_state.msg ;copy to keep system var from being mutated when MESSAGE is called
;  message, msg
;  return,0
;
;end


PRO cdf_tools_varinfo::GetProperty, data=data, name=name, attributes=attributes, numrec=numrec,strct=strct
  COMPILE_OPT IDL2
  IF (ARG_PRESENT(name)) THEN name = self.name
  IF (ARG_PRESENT(numrec)) THEN numrec = self.numrec
  IF (ARG_PRESENT(attributes)) THEN attributes = self.attributes
  IF (ARG_PRESENT(data)) THEN data = self.data
  IF (ARG_PRESENT(strct)) THEN struct_assign,strct,self
END





FUNCTION cdf_tools_varinfo::Init,name,value,_EXTRA=ex,epoch=epoch
  COMPILE_OPT IDL2
  void = self.generic_Object::Init(_extra=ex)   ; Call the superclass Initialization method.
  if isa(name,/string) then begin
    self.name  =name
  endif
  self.data = dynamicarray(name=self.name)
  self.attributes = orderedhash()
  self.is_zvar = 1
  self.type = size(/type,value)
  self.ndimen = size(/n_dimensions,value)
  self.d = size(/dimen,value)
  if debug(3) and keyword_set(ex) then dprint,ex,phelp=2,dlevel=2
  if keyword_set(epoch) then begin
    self.name = 'Epoch'
    self.recvary = 1
    self.datatype = 'CDF_TIME_TT2000'
    self.attributes['CATDESC']    = 'Time in TT2000 format'
    self.attributes['FIELDNAM']    = 'Epoch'
    self.attributes['FILLVAL']    = -1
    self.attributes['LABLAXIS']    = 'Epoch'
    self.attributes['UNITS']    = 'ns'
    self.attributes['VALIDMIN']    = -315575942816000000
    self.attributes['VALIDMAX']    = 946728068183000000
    self.attributes['VAR_TYPE']    = 'support_data'
    self.attributes['SCALETYP']    = 'linear'
    self.attributes['VAR_NOTES']    = 'This time corresponds to the middle measurement of the spectrum. This is usually NOT regular cadence.'
    self.attributes['MONOTON']    = 'INCREASE'
    self.attributes['TIME_BASE']    = 'J2000'
    self.attributes['TIME_SCALE']    = 'Terrestrial Time'
    if isa(epoch,'DYNAMICARRAY')  then self.data = epoch.data
    if isa(epoch, 'LONG64')       then self.data.array = epoch
  endif
  IF (ISA(ex)) THEN self->SetProperty, _EXTRA=ex    
  RETURN, 1
end
 
 
PRO cdf_tools_varinfo__define
  void = {cdf_tools_varinfo, $
    inherits generic_Object, $    ; superclass
    name:'', $
    num:0, $
    is_zvar:0,  $
    datatype:'',  $
    type:0, $
    numattr:-1,  $
    numelem:0, $
    recvary:0b, $
    numrec:0l, $
    ndimen:0, $
    d:lonarr(6) , $
    data:obj_new(), $
    attributes:obj_new()   $
    }
end


;PRO cdf_tools_fileinfo__define
;
;  void = {cdf_fileinfo, $
;    inherits generic_Object, $    ; superclass
;    filename:'', $
;    inq: obj_new(), $
;    g_attributes:obj_new(), $
;    nvars:0L, $
;    vars: obj_new() $
;    }
;end


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
   self.nv  = info.nv
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
  self.dlevel = 2
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



