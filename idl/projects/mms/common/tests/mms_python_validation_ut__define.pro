;+
;
; Unit tests for mms_python_validation_ut
;
; To run:
;     IDL> mgunit, 'mms_python_validation_ut'
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2019-08-09 15:48:05 -0700 (Fri, 09 Aug 2019) $
; $LastChangedRevision: 27592 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_python_validation_ut__define.pro $
;-

function mms_python_validation_ut::test_edi_default
  mms_load_edi
  spawn, 'python -m pyspedas.mms.tests.validation.edi', output

  get_data, 'mms1_edi_e_gse_srvy_l2', data=d
  assert, self.compare(d.y[1300, *], self.str_to_arr(output[-1])), 'Problem with EDI'
  assert, self.compare(d.y[1200, *], self.str_to_arr(output[-2])), 'Problem with EDI'
  assert, self.compare(d.y[1100, *], self.str_to_arr(output[-3])), 'Problem with EDI'
  assert, self.compare(d.y[1000, *], self.str_to_arr(output[-4])), 'Problem with EDI'
  assert, self.compare(d.y[900, *], self.str_to_arr(output[-5])), 'Problem with EDI'
  assert, self.compare(d.y[800, *], self.str_to_arr(output[-6])), 'Problem with EDI'
  assert, self.compare(d.y[700, *], self.str_to_arr(output[-7])), 'Problem with EDI'
  assert, self.compare(d.y[600, *], self.str_to_arr(output[-8])), 'Problem with EDI'
  assert, self.compare(d.y[500, *], self.str_to_arr(output[-9])), 'Problem with EDI'
  assert, self.compare(d.y[400, *], self.str_to_arr(output[-10])), 'Problem with EDI'
  assert, self.compare(d.y[300, *], self.str_to_arr(output[-11])), 'Problem with EDI'
  assert, self.compare(d.y[200, *], self.str_to_arr(output[-12])), 'Problem with EDI'
  assert, self.compare(d.y[100, *], self.str_to_arr(output[-13])), 'Problem with EDI'
  assert, self.compare(d.y[0, *], self.str_to_arr(output[-14])), 'Problem with EDI'
  assert, self.compare(d.x[0:9], self.str_to_arr(output[-15])), 'Problem with EDI'

  return, 1
end

function mms_python_validation_ut::test_scm_default
  mms_load_scm
  spawn, 'python -m pyspedas.mms.tests.validation.scm', output

  get_data, 'mms1_scm_acb_gse_scsrvy_srvy_l2', data=d
  assert, self.compare(d.y[2000000, *], self.str_to_arr(output[-1])), 'Problem with SCM'
  assert, self.compare(d.y[1500000, *], self.str_to_arr(output[-2])), 'Problem with SCM'
  assert, self.compare(d.y[1000000, *], self.str_to_arr(output[-3])), 'Problem with SCM'
  assert, self.compare(d.y[900000, *], self.str_to_arr(output[-4])), 'Problem with SCM'
  assert, self.compare(d.y[800000, *], self.str_to_arr(output[-5])), 'Problem with SCM'
  assert, self.compare(d.y[700000, *], self.str_to_arr(output[-6])), 'Problem with SCM'
  assert, self.compare(d.y[600000, *], self.str_to_arr(output[-7])), 'Problem with SCM'
  assert, self.compare(d.y[500000, *], self.str_to_arr(output[-8])), 'Problem with SCM'
  assert, self.compare(d.y[400000, *], self.str_to_arr(output[-9])), 'Problem with SCM'
  assert, self.compare(d.y[300000, *], self.str_to_arr(output[-10])), 'Problem with SCM'
  assert, self.compare(d.y[200000, *], self.str_to_arr(output[-11])), 'Problem with SCM'
  assert, self.compare(d.y[100000, *], self.str_to_arr(output[-12])), 'Problem with SCM'
  assert, self.compare(d.y[50000, *], self.str_to_arr(output[-13])), 'Problem with SCM'
  assert, self.compare(d.y[10000, *], self.str_to_arr(output[-14])), 'Problem with SCM'
  assert, self.compare(d.x[0:9], self.str_to_arr(output[-15])), 'Problem with SCM'

  return, 1
end

function mms_python_validation_ut::test_mec_default
  mms_load_mec
  spawn, 'python -m pyspedas.mms.tests.validation.mec', output

  get_data, 'mms1_mec_r_gse', data=d
  assert, self.compare(d.y[2500, *], self.str_to_arr(output[-1])), 'Problem with MEC'
  assert, self.compare(d.y[2000, *], self.str_to_arr(output[-2])), 'Problem with MEC'
  assert, self.compare(d.y[1500, *], self.str_to_arr(output[-3])), 'Problem with MEC'
  assert, self.compare(d.y[1000, *], self.str_to_arr(output[-4])), 'Problem with MEC'
  assert, self.compare(d.y[900, *], self.str_to_arr(output[-5])), 'Problem with MEC'
  assert, self.compare(d.y[800, *], self.str_to_arr(output[-6])), 'Problem with MEC'
  assert, self.compare(d.y[700, *], self.str_to_arr(output[-7])), 'Problem with MEC'
  assert, self.compare(d.y[600, *], self.str_to_arr(output[-8])), 'Problem with MEC'
  assert, self.compare(d.y[500, *], self.str_to_arr(output[-9])), 'Problem with MEC'
  assert, self.compare(d.y[400, *], self.str_to_arr(output[-10])), 'Problem with MEC'
  assert, self.compare(d.y[300, *], self.str_to_arr(output[-11])), 'Problem with MEC'
  assert, self.compare(d.y[200, *], self.str_to_arr(output[-12])), 'Problem with MEC'
  assert, self.compare(d.y[100, *], self.str_to_arr(output[-13])), 'Problem with MEC'
  assert, self.compare(d.y[0, *], self.str_to_arr(output[-14])), 'Problem with MEC'
  assert, self.compare(d.x[0:9], self.str_to_arr(output[-15])), 'Problem with MEC'

  return, 1
end

function mms_python_validation_ut::test_fpi_default
  mms_load_fpi, probe=1, datatype=['des-moms', 'dis-moms']
  spawn, 'python -m pyspedas.mms.tests.validation.fpi', output

  get_data, 'mms1_des_energyspectr_omni_fast', data=d
  assert, self.compare(d.y[9000, *], self.str_to_arr(output[-1])), 'Problem with FPI'
  assert, self.compare(d.y[8000, *], self.str_to_arr(output[-2])), 'Problem with FPI'
  assert, self.compare(d.y[7000, *], self.str_to_arr(output[-3])), 'Problem with FPI'
  assert, self.compare(d.y[6000, *], self.str_to_arr(output[-4])), 'Problem with FPI'
  assert, self.compare(d.y[5000, *], self.str_to_arr(output[-5])), 'Problem with FPI'
  assert, self.compare(d.y[4000, *], self.str_to_arr(output[-6])), 'Problem with FPI'
  assert, self.compare(d.y[3000, *], self.str_to_arr(output[-7])), 'Problem with FPI'
  assert, self.compare(d.y[3000, *], self.str_to_arr(output[-8])), 'Problem with FPI'
  assert, self.compare(d.y[1000, *], self.str_to_arr(output[-9])), 'Problem with FPI'
  assert, self.compare(d.y[0, *], self.str_to_arr(output[-10])), 'Problem with FPI'
  assert, self.compare(d.x[0:9], self.str_to_arr(output[-12])), 'Problem with FPI'

  return, 1
end

function mms_python_validation_ut::test_feeps_default
  mms_load_feeps
  spawn, 'python -m pyspedas.mms.tests.validation.feeps', output


  return, 1
end

function mms_python_validation_ut::test_dsp_default
  mms_load_dsp
  spawn, 'python -m pyspedas.mms.tests.validation.dsp', output

  return, 1
end

function mms_python_validation_ut::test_edp_default
  mms_load_edp, probe=1
  spawn, 'python -m pyspedas.mms.tests.validation.edp', output
  
  get_data, 'mms1_edp_dce_gse_fast_l2', data=d
  assert, self.compare(d.y[1300000, *], self.str_to_arr(output[-1])), 'Problem with EDP'
  assert, self.compare(d.y[1200000, *], self.str_to_arr(output[-2])), 'Problem with EDP'
  assert, self.compare(d.y[1100000, *], self.str_to_arr(output[-3])), 'Problem with EDP'
  assert, self.compare(d.y[1000000, *], self.str_to_arr(output[-4])), 'Problem with EDP'
  assert, self.compare(d.y[900000, *], self.str_to_arr(output[-5])), 'Problem with EDP'
  assert, self.compare(d.y[800000, *], self.str_to_arr(output[-6])), 'Problem with EDP'
  assert, self.compare(d.y[700000, *], self.str_to_arr(output[-7])), 'Problem with EDP'
  assert, self.compare(d.y[600000, *], self.str_to_arr(output[-8])), 'Problem with EDP'
  assert, self.compare(d.y[500000, *], self.str_to_arr(output[-9])), 'Problem with EDP'
  assert, self.compare(d.y[400000, *], self.str_to_arr(output[-10])), 'Problem with EDP'
  assert, self.compare(d.y[300000, *], self.str_to_arr(output[-11])), 'Problem with EDP'
  assert, self.compare(d.y[200000, *], self.str_to_arr(output[-12])), 'Problem with EDP'
  assert, self.compare(d.y[100000, *], self.str_to_arr(output[-13])), 'Problem with EDP'
  assert, self.compare(d.y[50000, *], self.str_to_arr(output[-14])), 'Problem with EDP'
  assert, self.compare(d.y[10000, *], self.str_to_arr(output[-15])), 'Problem with EDP'
  assert, self.compare(d.x[0:9], self.str_to_arr(output[-16])), 'Problem with EDP'

  return, 1
end

function mms_python_validation_ut::test_aspoc_default
  mms_load_aspoc
  spawn, 'python -m pyspedas.mms.tests.validation.aspoc', output

  get_data, 'mms1_aspoc_ionc_l2', data=d
  assert, d.y[60000, *] eq output[-1], 'Problem with ASPOC'
  assert, d.y[59000, *] eq output[-2], 'Problem with ASPOC'
  assert, d.y[58000, *] eq output[-3], 'Problem with ASPOC'
  assert, d.y[57000, *] eq output[-4], 'Problem with ASPOC'
  assert, d.y[56000, *] eq output[-5], 'Problem with ASPOC'
  assert, d.y[55000, *] eq output[-6], 'Problem with ASPOC'
  assert, d.y[54000, *] eq output[-7], 'Problem with ASPOC'
  assert, d.y[53000, *] eq output[-8], 'Problem with ASPOC'
  assert, d.y[52000, *] eq output[-9], 'Problem with ASPOC'
  assert, d.y[51000, *] eq output[-10], 'Problem with ASPOC'
  assert, d.y[50000, *] eq output[-11], 'Problem with ASPOC'
  assert, self.compare(d.x[0:9], self.str_to_arr(output[-12])), 'Problem with ASPOC'
  
  return, 1
end

function mms_python_validation_ut::test_hpca_default
  mms_load_hpca, datatype='ion', trange=['2016-10-16', '2016-10-17']
  mms_hpca_calc_anodes, fov=[0, 360]
  mms_hpca_spin_sum, probe='1'
  spawn, 'python -m pyspedas.mms.tests.validation.hpca', output
  
  get_data, 'mms1_hpca_hplus_flux_elev_0-360_spin', data=d
  assert, self.compare(d.y[7000, *], self.str_to_arr(output[-1])), 'Problem with HPCA'
  assert, self.compare(d.y[6000, *], self.str_to_arr(output[-2])), 'Problem with HPCA'
  assert, self.compare(d.y[5000, *], self.str_to_arr(output[-3])), 'Problem with HPCA'
  assert, self.compare(d.y[4000, *], self.str_to_arr(output[-4])), 'Problem with HPCA'
  assert, self.compare(d.y[3000, *], self.str_to_arr(output[-5])), 'Problem with HPCA'
  assert, self.compare(d.y[2000, *], self.str_to_arr(output[-6])), 'Problem with HPCA'
  assert, self.compare(d.y[1000, *], self.str_to_arr(output[-7])), 'Problem with HPCA'
  assert, self.compare(d.y[0, *], self.str_to_arr(output[-8])), 'Problem with HPCA'
  assert, self.compare(d.x[0:9], self.str_to_arr(output[-9])), 'Problem with HPCA'
  
  return, 1
end

function mms_python_validation_ut::test_fgm_default
  mms_load_fgm
  spawn, 'python -m pyspedas.mms.tests.validation.fgm', output
  
  get_data, 'mms1_fgm_b_gse_srvy_l2', data=d
  assert, self.compare(d.y[900000, *], self.str_to_arr(output[-1])), 'Problem with FGM'
  assert, self.compare(d.y[800000, *], self.str_to_arr(output[-2])), 'Problem with FGM'
  assert, self.compare(d.y[700000, *], self.str_to_arr(output[-3])), 'Problem with FGM'
  assert, self.compare(d.y[600000, *], self.str_to_arr(output[-4])), 'Problem with FGM'
  assert, self.compare(d.y[500000, *], self.str_to_arr(output[-5])), 'Problem with FGM'
  assert, self.compare(d.y[400000, *], self.str_to_arr(output[-6])), 'Problem with FGM'
  assert, self.compare(d.y[300000, *], self.str_to_arr(output[-7])), 'Problem with FGM'
  assert, self.compare(d.y[200000, *], self.str_to_arr(output[-8])), 'Problem with FGM'
  assert, self.compare(d.y[100000, *], self.str_to_arr(output[-9])), 'Problem with FGM'
  assert, self.compare(d.y[50000, *], self.str_to_arr(output[-10])), 'Problem with FGM'
  assert, self.compare(d.y[10000, *], self.str_to_arr(output[-11])), 'Problem with FGM'
  assert, self.compare(d.x[0:9], self.str_to_arr(output[-12])), 'Problem with FGM'
  return, 1
end

function mms_python_validation_ut::test_eis_default
  mms_load_eis, datatype=['extof', 'phxtof']
  spawn, 'python -m pyspedas.mms.tests.validation.eis', output
  
  get_data, 'mms1_epd_eis_extof_proton_flux_omni', data=d
  assert, self.compare(d.y[20000, *], self.str_to_arr(output[-1])), 'Problem with EIS (ExTOF)'
  assert, self.compare(d.y[15000, *], self.str_to_arr(output[-2])), 'Problem with EIS (ExTOF)'
  assert, self.compare(d.y[10000, *], self.str_to_arr(output[-3])), 'Problem with EIS (ExTOF)'
  assert, self.compare(d.y[5000, *], self.str_to_arr(output[-4])), 'Problem with EIS (ExTOF)'
  assert, self.compare(d.v, self.str_to_arr(output[-5])), 'Problem with EIS (ExTOF)'
  assert, self.compare(d.x[0:9], self.str_to_arr(output[-6])), 'Problem with EIS (ExTOF)'
  
  get_data, 'mms1_epd_eis_phxtof_proton_flux_omni', data=d
  assert, self.compare(d.y[20000, *], self.str_to_arr(output[-7])), 'Problem with EIS (PHxTOF)'
  assert, self.compare(d.y[15000, *], self.str_to_arr(output[-8])), 'Problem with EIS (PHxTOF)'
  assert, self.compare(d.y[10000, *], self.str_to_arr(output[-9])), 'Problem with EIS (PHxTOF)'
  assert, self.compare(d.y[5000, *], self.str_to_arr(output[-10])), 'Problem with EIS (PHxTOF)'
  assert, self.compare(d.v, self.str_to_arr(output[-11])), 'Problem with EIS (PHxTOF)'
  assert, self.compare(d.x[0:9], self.str_to_arr(output[-12])), 'Problem with EIS (PHxTOF)'
  
  return, 1
end

function mms_python_validation_ut::compare, idl_result, py_result
  notused = where(abs(idl_result-py_result) ge 1e-6, bad_count)
  return, bad_count eq 0 ? 1 : 0
end

; converts an array stored in a string to an actual array
function mms_python_validation_ut::str_to_arr, str
  return, strsplit(strmid(str[-1], 1, strlen(str[-1])-2), ', ', /extract)
end

pro mms_python_validation_ut::setup
  del_data, '*'
  timespan, '2015-10-16', 1, /day

  ; the pyspedas package is installed in my ~/pyspedas folder
  cd, 'pyspedas'
end

pro mms_python_validation_ut::teardown
  cd, ''
end
pro mms_python_validation_ut__define
  define = { mms_python_validation_ut, inherits MGutTestCase }
end