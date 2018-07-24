;+
; NAME:
;   SPP_FLD_L2_CDF_SKT_FILE
;
; PURPOSE:
;   Returns the path to the skeleton (SKT) table file for a given PSP/FIELDS
;   Level 2 data type.  The SKT file contains a list of the CDF attributes
;   and variables to be stored in the L2 data file.
;
; INPUTS:
;   L2_DATA_TYPE: The name of the data type for the L2 CDF file.
;
; RETURNS:
;   SKT_FILE: The path to the requested SKT file.
;
;   If more than one matching SKT file is present in the directory (different
;   versions identified by the file name ending v_NN.cdf with NN as the
;   version number), then the highest version is returned.
;
; EXAMPLE:
;
;     mag_skt = spp_fld_l2_cdf_skt_file('mag')
;
; NOTE:
;     This file should be in the same directory as the L2 SKT files.  If the
;     SKT files are in a directory without any IDL routines ('.pro' files) then
;     the FILE_SEARCH routine will not find them using the !PATH IDL system
;     variable.
;
; CREATED BY:
;   pulupa
;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2018-07-23 14:25:37 -0700 (Mon, 23 Jul 2018) $
; $LastChangedRevision: 25507 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/skt/l2/spp_fld_l2_cdf_skt_file.pro $
;-
function spp_fld_l2_cdf_skt_file, l2_data_type, l2_version = l2_version

  slash = path_sep()
  sep   = path_sep(/search_path)

  dirs = ['.',strsplit(!path,sep,/extract)]

  skt_file_name = 'psp_fld_l2_' + l2_data_type + '_00000000_v??.skt'

  skt_path = file_search(dirs + slash + skt_file_name, count = n_skt_found)

  if n_skt_found GT 0 then begin

    skt_file = skt_path[-1]

    l2_version = strmid(skt_file, 5, 2, /reverse)

  endif else begin
  
    dprint, dlevel = 1, 'Skeleton file not found for data type ', l2_data_type
  
    skt_file = ''  
    
    l2_version = ''
    
  endelse

  return, skt_file

end