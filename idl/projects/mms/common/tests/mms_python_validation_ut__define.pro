;+
;
; Unit tests for mms_python_validation_ut
;
; To run:
;     IDL> mgunit, 'mms_python_validation_ut'
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2019-08-06 13:24:46 -0700 (Tue, 06 Aug 2019) $
; $LastChangedRevision: 27557 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_python_validation_ut__define.pro $
;-


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
  notused = where(idl_result-py_result ge 1e-6, bad_count)
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