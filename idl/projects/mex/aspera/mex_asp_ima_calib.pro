;+
;
;PROCEDURE:       MEX_ASP_IMA_CALIB
;
;PURPOSE:         
;                 Reads MEX/ASPERA-3 (IMA) calibration table.
;
;INPUTS:          
;
;KEYWORDS:
;
;CREATED BY:      Takuya Hara on 2018-01-31.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2018-04-04 16:17:13 -0700 (Wed, 04 Apr 2018) $
; $LastChangedRevision: 24998 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mex/aspera/mex_asp_ima_calib.pro $
;
;-
PRO mex_asp_ima_calib, calib, verbose=verbose
  ldir = root_data_dir() + 'mex/aspera/ima/calib/'
  file_mkdir2, ldir
     
  pdir = 'MEX-M-ASPERA3-2-EDR-IMA-V1.0/'
  rpath = 'ftp://psa.esac.esa.int/pub/mirror/MARS-EXPRESS/ASPERA-3/' + pdir + 'CALIB/'
  rfile = 'IMA_MASS.TAB'
  append_array, file, FILE_SEARCH(ldir, rfile, count=nfile)
  IF nfile EQ 0 THEN file[-1] = spd_download(remote_path=rpath, remote_file=rfile, local_path=ldir, ftp_connection_mode=0) 

  dprint, dlevel=2, verbose=verbose, 'Reading ' + file + '.'
  OPENR, unit, file, /get_lun
  data = STRARR(FILE_LINES(file))
  READF, unit, data
  FREE_LUN, unit

  data = STRSPLIT(data, /extract)
  data = data.toarray()

  mnoise = REFORM(DOUBLE(data[*, 3]))
  mratio = REFORM(DOUBLE(data[*, 4]))

  ; These values are coming from "ftp://psa.esac.esa.int/pub/mirror/MARS-EXPRESS/ASPERA-3/MEX-M-ASPERA3-2-EDR-IMA-V1.0/CALIB/IMA_AZIMUTH.TAB".
  aeff = 1.                     ; Efficiency of Azimuth Sector 
  gf   = 0.0001                 ; Very rough (!) Geometric Factor 

  calib = {mnoise: mnoise, mratio: mratio, aeff: aeff, gf: gf}
  RETURN
END
