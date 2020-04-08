;+
;PURPOSE:
; Temporary program to load FAST EFI SFA files created from Level0
; data via SDT.
;CALLING SEQUENCE:
; temp_fa_load_sfa_efi, filename
;INPUT:
; filename = file to input, full path please
;OUTPUT:
; tplot variables:
; SfaAve_V1-V2_Data  - this is the data variable
; Sdt_Cdf_MDim_Sizes_by_Record - data size of the frequency variable
; MinMaxVals_Dim_1_SubDim_1_1 - min and max values of the frequency
;                               bands, units are kHz, and a quality
;                               value for each band. THis variable is
;                               used to create the 'v' tag in the data variable.
; Data_MinMax_Offset_Dim_1_SubDim_1_1 - The variable:
;                                       Data_MinMax_Offset contains,
;                                       for each data array, the
;                                       record offset into the
;                                       corresponding MinMaxVals
;                                       variable for each dimension
;                                       and sub-dimension.  Note that
;                                       the number of records is given
;                                       by the size of the dimension
;                                       from the
;                                       Sdt_Cdf_MDim_Sizes_by_Record
;                                       variable.
; DimensionDescription_Dim_1_SubDim_1_1 - a string denoting the
;                                         frequency variable
;HISTORY:
;$LastChangedBy: jimm $
;$LastChangedDate: 2020-04-07 13:37:22 -0700 (Tue, 07 Apr 2020) $
;$LastChangedRevision: 28519 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/fast/fa_fields/temp_fa_load_sfa_efi.pro $
Pro temp_fa_load_sfa_efi, filename, _extra=_extra

;for plotting purposes
  fa_init
;create tplot variables using cdf2tplot
;extract data type from filename
  bfile = file_basename(filename, '.cdf')
  ttp = strsplit(bfile, '_', /extract)
  nttp = n_elements(ttp)
  datatype = ttp[nttp-1]
  data_var = 'SfaAve_'+datatype+'_Data'
  If(is_string(tnames(data_var))) Then del_data, data_var
  cdf2tplot, files = filename, /all, /smex
  If(~is_string(tnames(data_var))) Then Begin
     dprint, 'No data in file: '+filename
     Return
  Endif
;Here we have data, but need to add
;the frequency to the data variable
  get_data, data_var, data = d
  If(~is_struct(d)) Then Begin
     dprint, 'No data in file: '+filename
     Return
  Endif
;Get frequency values
  get_data, 'MinMaxVals_Dim_1_SubDim_1_1', data = v
  If(~is_struct(v)) Then Begin
     dprint, 'No Frequency data in file: '+filename
     Return
  Endif
  vmid = 0.5*(v.y[*,0]+v.y[*,1])
  store_data,data_var,data = {x:d.x, y:d.y, v:vmid}
;copy the data variables, so that they are not overwritten
;then delete the input variables
  copy_data, data_var, 'fa_'+data_var
  store_data, data_var, /delete
  copy_data, 'Sdt_Cdf_MDim_Sizes_by_Record', $
             'fa_'+datatype+'_Sdt_Cdf_MDim_Sizes_by_Record'
  store_data, 'Sdt_Cdf_MDim_Sizes_by_Record', /delete
  copy_data, 'MinMaxVals_Dim_1_SubDim_1_1', $
             'fa_'+datatype+'_MinMaxVals_Dim_1_SubDim_1_1'
  store_data, 'MinMaxVals_Dim_1_SubDim_1_1', /delete
  copy_data, 'Data_MinMax_Offset_Dim_1_SubDim_1_1', $
             'fa_'+datatype+'_Data_MinMax_Offset_Dim_1_SubDim_1_1'
  store_data, 'Data_MinMax_Offset_Dim_1_SubDim_1_1', /delete
  copy_data, 'DimensionDescription_Dim_1_SubDim_1_1', $
             'fa_'+datatype+'_DimensionDescription_Dim_1_SubDim_1_1'
  store_data, 'DimensionDescription_Dim_1_SubDim_1_1', /delete

;plot options
  options, 'fa_'+data_var, 'spec', 1
  options, 'fa_'+data_var, 'zlog', 1
  Return
End

  



