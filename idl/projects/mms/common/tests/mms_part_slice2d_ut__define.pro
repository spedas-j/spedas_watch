;+
;
; Unit tests for mms_part_slice2d
;
; To run:
;     IDL> mgunit, 'mms_part_slice2d_ut'
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2018-06-28 12:33:20 -0700 (Thu, 28 Jun 2018) $
; $LastChangedRevision: 25415 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_part_slice2d_ut__define.pro $
;-

function mms_part_slice2d_ut::test_fpi_i_basic
  mms_part_slice2d, trange=['2015-12-15', '2015-12-15/0:01'], instrument='fpi', species='i'
  return, 1
end

function mms_part_slice2d_ut::test_fpi_i_subtract_bulk
  mms_part_slice2d, trange=['2015-12-15', '2015-12-15/0:01'], instrument='fpi', species='i', /subtract_bulk
  return, 1
end

function mms_part_slice2d_ut::test_fpi_e_basic
  mms_part_slice2d, trange=['2015-12-15', '2015-12-15/0:01'], instrument='fpi', species='e'
  return, 1
end

function mms_part_slice2d_ut::test_hpca_hplus_basic
  mms_part_slice2d, trange=['2015-12-15', '2015-12-15/0:01'], instrument='hpca', species='hplus'
  return, 1
end

function mms_part_slice2d_ut::test_hpca_oplus_basic
  mms_part_slice2d, trange=['2015-12-15', '2015-12-15/0:01'], instrument='hpca', species='oplus'
  return, 1
end

function mms_part_slice2d_ut::test_hpca_heplus_basic
  mms_part_slice2d, trange=['2015-12-15', '2015-12-15/0:01'], instrument='hpca', species='heplus'
  return, 1
end

function mms_part_slice2d_ut::test_hpca_heplusplus_basic
  mms_part_slice2d, trange=['2015-12-15', '2015-12-15/0:01'], instrument='hpca', species='heplusplus'
  return, 1
end

pro mms_part_slice2d_ut::setup
  del_data, '*'
  timespan, '2015-12-15', 1, /min
end

function mms_part_slice2d_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self->addTestingRoutine, ['spd_slice2d', 'mms_part_slice2d']
  return, 1
end

pro mms_part_slice2d_ut__define
  define = { mms_part_slice2d_ut, inherits MGutTestCase }
end