


;+
;  cdf_tools_varinfo
;  This basic object is the entry point for reading and writing cdf files
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2018-12-04 09:52:17 -0800 (Tue, 04 Dec 2018) $
; $LastChangedRevision: 26225 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu:36867/repos/spdsoft/trunk/projects/SPP/COMMON/cdf_tools__define.pro $
;
; Written by Davin Larson October 2018
;-




function cdf_tools_varinfo::variable_attributes, vname,value
  dlevel =3
  fnan = !values.f_nan
  dprint,dlevel=dlevel,'Creating variable attributes for: ',vname
  att = orderedhash()
  if ~isa(vname,/string) then return,att
  ;  Create default value place holders
  EPOCHname = 'Epoch'
  att['CATDESC']    = ''
  att['FIELDNAM']    = vname
  att['LABLAXIS']    = vname
  att['DEPEND_0'] = EPOCHname
  att['DISPLAY_TYPE'] = ''
  att['MONOTON']    = ''
  case strupcase(vname) of
    'EPOCH': begin
      att['CATDESC']    = 'Time at middle of sample'
      att['FIELDNAM']    = 'Time in TT2000 format'
      att['LABLAXIS']    = EPOCHname
      att['UNITS']    = 'ns'
      att['FILLVAL']    = -1
      att['VALIDMIN']    = -315575942816000000
      att['VALIDMAX']    = 946728068183000000
      att['VAR_TYPE']    = 'support_data'
      att['DICT_KEY']    = 'time>Epoch'
      att['SCALETYP']    = 'linear'
      att['MONOTON']    = 'INCREASE'
    end
    'TIME': begin
      att['CATDESC']    = 'Time at middle of sample'
      att['FIELDNAM']    = 'Time in UTC format'
      att['LABLAXIS']    = 'Unix Time'
      att['UNITS']    = 'sec'
      att['FILLVAL']    = fnan
      att['VALIDMIN']    = time_double('2010')
      att['VALIDMAX']    = time_double('2030')
      att['VAR_TYPE']    = 'support_data'
      att['DICT_KEY']    = 'time>UTC'
      att['SCALETYP']    = 'linear'
      att['MONOTON']    = 'INCREASE'
    end
    'COUNTS': begin
      att['CATDESC']    = 'Counts in Energy/angle bin'
      att['FIELDNAM']    = 'Counts'
      att['DEPEND_0']    = EPOCHname
      att['LABLAXIS']    = 'Counts'
      att['UNITS']    = 'Counts'
      att['FILLVAL']    = fnan
      att['VALIDMIN']    = 0
      att['VALIDMAX']    = 1e6
      att['VAR_TYPE']    = 'data'
      att['DICT_KEY']    = ''
      att['SCALETYP']    = 'log'
      att['MONOTON']    = ''
    end
    'EFLUX': begin
      att['CATDESC']    = 'Differential Energy Flux vs Energy/angle bin'
      att['FIELDNAM']    = 'Eflux'
      att['DEPEND_0']    = EPOCHname
      att['DEPEND_1']    = 'ENERGY'
      att['LABLAXIS']    = 'Diff Energy Flux'
      att['UNITS']    = 'eV/cm2-s-ster-eV'
      att['FILLVAL']    = fnan
      att['VALIDMIN']    = 0.001
      att['VALIDMAX']    = 1e12
      att['VAR_TYPE']    = 'data'
      att['DICT_KEY']    = ''
      att['SCALETYP']    = 'log'
      att['MONOTON']    = ''
      att['DISPLAY_TYPE'] = 'spectrogram'
    end
    'ENERGY': begin
      att['CATDESC']    = 'Energy'
      att['FIELDNAM']    = 'Counts in '
      att['DEPEND_0']    = EPOCHname
      ;      att['DEPEND_1']    = 'ENERGY'
      att['LABLAXIS']    = 'Energy'
      att['UNITS']    = 'eV'
      att['FILLVAL']    = fnan
      att['VALIDMIN']    = 1
      att['VALIDMAX']    = 1e5
      att['VAR_TYPE']    = 'support_data'
      att['DICT_KEY']    = ''
      att['SCALETYP']    = 'log'
      att['MONOTON']    = ''
    end
    'THETA': begin
      att['CATDESC']    = 'THETA'
      att['FIELDNAM']    = 'Elevation Angle in instrument coordinates'
      att['DEPEND_0']    = EPOCHname
      ;      att['DEPEND_1']    = 'ENERGY'
      att['LABLAXIS']    = 'Elevation Angle'
      att['UNITS']    = 'Degrees'
      att['FILLVAL']    = fnan
      att['VALIDMIN']    = 1
      att['VALIDMAX']    = 1e5
      att['VAR_TYPE']    = 'support_data'
      att['DICT_KEY']    = ''
      att['SCALETYP']    = 'log'
      att['MONOTON']    = ''
    end
    'PHI': begin
      att['CATDESC']    = 'PHI'
      att['FIELDNAM']    = 'Azimuth Angle in instrument coordinates'
      att['DEPEND_0']    = EPOCHname
      ;      att['DEPEND_1']    = 'ENERGY'
      att['LABLAXIS']    = 'Azimuth Angle'
      att['UNITS']    = 'Degrees'
      att['FILLVAL']    = fnan
      att['VALIDMIN']    = 1
      att['VALIDMAX']    = 1e5
      att['VAR_TYPE']    = 'support_data'
      att['DICT_KEY']    = ''
      att['SCALETYP']    = 'log'
      att['MONOTON']    = ''
    end
    'EFLUX_VS_ENERGY': begin
      att['CATDESC']    = 'Differential Energy Flux vs Energy'
      att['FIELDNAM']    = 'Eflux vs Energy'
      att['DEPEND_0']    = EPOCHname
      att['DEPEND_1']    = 'ENERGY_VALS'
      att['LABLAXIS']    = 'Eflux vs Energy'
      att['UNITS']    = 'eV/cm2-s-ster-eV'
      att['FILLVAL']    = fnan
      att['VALIDMIN']    = 0.001
      att['VALIDMAX']    = 1e12
      att['VAR_TYPE']    = 'data'
      att['DICT_KEY']    = ''
      att['SCALETYP']    = 'log'
      att['MONOTON']    = ''
      att['DISPLAY_TYPE'] = 'spectrogram'
    end
    'EFLUX_VS_THETA': begin
      att['CATDESC']    = 'Differential Energy Flux vs Theta'
      att['FIELDNAM']    = 'Eflux vs Theta'
      att['DEPEND_0']    = EPOCHname
      att['DEPEND_1']    = 'THETA_VALS'
      att['LABLAXIS']    = 'Eflux vs Theta'
      att['UNITS']    = 'eV/cm2-s-ster-eV'
      att['FILLVAL']    = fnan
      att['VALIDMIN']    = 0.001
      att['VALIDMAX']    = 1e12
      att['VAR_TYPE']    = 'data'
      att['DICT_KEY']    = ''
      att['SCALETYP']    = 'log'
      att['MONOTON']    = ''
      att['DISPLAY_TYPE'] = 'spectrogram'
    end
    'EFLUX_VS_PHI': begin
      att['CATDESC']    = 'Differential Energy Flux vs Phi'
      att['FIELDNAM']    = 'Eflux vs Phi'
      att['DEPEND_0']    = EPOCHname
      att['DEPEND_1']    = 'PHI_VALS'
      att['LABLAXIS']    = 'Eflux vs Phi'
      att['UNITS']    = 'eV/cm2-s-ster-eV'
      att['FILLVAL']    = fnan
      att['VALIDMIN']    = 0.001
      att['VALIDMAX']    = 1e12
      att['VAR_TYPE']    = 'data'
      att['DICT_KEY']    = ''
      att['SCALETYP']    = 'log'
      att['MONOTON']    = ''
      att['DISPLAY_TYPE'] = 'spectrogram'
    end
    'ENERGY_VALS': begin
      att['CATDESC']    = 'Energy'
      att['FIELDNAM']    = 'Energy'
      att['DEPEND_0']    = EPOCHname
      ;      att['DEPEND_1']    = 'ENERGY'
      att['LABLAXIS']    = 'Energy'
      att['UNITS']    = 'eV'
      att['FILLVAL']    = fnan
      att['VALIDMIN']    = 1
      att['VALIDMAX']    = 1e5
      att['VAR_TYPE']    = 'support_data'
      att['DICT_KEY']    = ''
      att['SCALETYP']    = 'log'
      att['MONOTON']    = ''
    end
    'THETA_VALS': begin
      att['CATDESC']    = 'THETA'
      att['FIELDNAM']    = 'Elevation Angle in instrument coordinates'
      att['DEPEND_0']    = EPOCHname
      ;      att['DEPEND_1']    = 'ENERGY'
      att['LABLAXIS']    = 'Elevation Angle'
      att['UNITS']    = 'Degrees'
      att['FILLVAL']    = fnan
      att['VALIDMIN']    = 1
      att['VALIDMAX']    = 1e5
      att['VAR_TYPE']    = 'support_data'
      att['DICT_KEY']    = ''
      att['SCALETYP']    = 'log'
      att['MONOTON']    = ''
    end
    'PHI_VALS': begin
      att['CATDESC']    = 'PHI'
      att['FIELDNAM']    = 'Azimuth Angle in instrument coordinates'
      att['DEPEND_0']    = EPOCHname
      ;      att['DEPEND_1']    = 'ENERGY'
      att['LABLAXIS']    = 'Azimuth Angle'
      att['UNITS']    = 'Degrees'
      att['FILLVAL']    = fnan
      att['VALIDMIN']    = 1
      att['VALIDMAX']    = 1e5
      att['VAR_TYPE']    = 'support_data'
      att['DICT_KEY']    = ''
      att['SCALETYP']    = 'log'
      att['MONOTON']    = ''
    end
    else:  begin    ; assumed to be support
      att['CATDESC']    = 'Not known'
      att['FIELDNAM']    = 'Unknown '
      att['DEPEND_0']    = EPOCHname
      att['LABLAXIS']    = vname
      att['UNITS']    = ''
      att['FILLVAL']    = fnan
      att['VALIDMIN']    = -1e30
      att['VALIDMAX']    = 1e30
      att['VAR_TYPE']    = 'ignore_data'
      att['DICT_KEY']    = ''
      att['SCALETYP']    = 'linear'
      att['MONOTON']    = ''
      dprint,dlevel=dlevel, 'variable ' +vname+ ' not recognized'

    end

  endcase

  return, att
end






PRO cdf_tools_varinfo::GetProperty, data=data, name=name, attributes=attributes, numrec=numrec,strct=strct
  COMPILE_OPT IDL2
  IF (ARG_PRESENT(name)) THEN name = self.name
  IF (ARG_PRESENT(numrec)) THEN numrec = self.numrec
  IF (ARG_PRESENT(attributes)) THEN attributes = self.attributes
  IF (ARG_PRESENT(data)) THEN data = self.data
  IF (ARG_PRESENT(strct)) THEN struct_assign,strct,self
END





FUNCTION cdf_tools_varinfo::Init,name,value,all_values=all_values,structure_array=str_arr,set_default_atts=set_default_atts,attr_name=attr_name,_EXTRA=ex
  COMPILE_OPT IDL2
  ;  self.dlevel = 4
  void = self.generic_Object::Init(_extra=ex)   ; Call the superclass Initialization method.
  if keyword_set(str_arr) then begin
    str_element,str_arr,name,dat_values
    all_values = transpose(dat_values)
    str_element,str_arr[0],name,value
  endif
  if isa(name,/string) && keyword_set(set_default_atts) then begin
    self.name  =name
    self.attributes = self.variable_attributes(name,value)
  endif
  self.data = dynamicarray(all_values,name=self.name)
  self.is_zvar = 1
  self.type = size(/type,value)
  self.ndimen = size(/n_dimensions,value)
  self.d = size(/dimen,value)
  ;  if debug(3) and keyword_set(ex) then dprint,ex,phelp=2,dlevel=4
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




