;+
;
; Unit tests for mms_part_slice2d
;
; To run:
;     IDL> mgunit, 'mms_part_slice2d_ut'
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2018-09-20 15:35:27 -0700 (Thu, 20 Sep 2018) $
; $LastChangedRevision: 25842 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_part_slice2d_ut__define.pro $
;-

function mms_part_slice2d_ut::test_fpi_i_basic
  mms_part_slice2d, trange=['2015-12-15', '2015-12-15/0:01'], instrument='fpi', species='i', export='test_fpi_i_basic'
  return, 1
end

function mms_part_slice2d_ut::test_fpi_i_units
  mms_part_slice2d, units='eflux', trange=['2015-12-15', '2015-12-15/0:01'], instrument='fpi', species='i', export='test_fpi_i_units'
  return, 1
end

function mms_part_slice2d_ut::test_fpi_i_burst
  mms_part_slice2d, trange=['2015-10-16/13:06', '2015-10-16/13:06:05'], instrument='fpi', species='i', data_rate='brst', export='test_fpi_i_burst'
  return, 1
end

function mms_part_slice2d_ut::test_fpi_i_subtract_bulk
  mms_part_slice2d, trange=['2015-12-15', '2015-12-15/0:01'], instrument='fpi', species='i', /subtract_bulk, export='test_fpi_i_subtract_bulk'
  return, 1
end

function mms_part_slice2d_ut::test_fpi_e_basic
  mms_part_slice2d, trange=['2015-12-15', '2015-12-15/0:01'], instrument='fpi', species='e', export='test_fpi_e_basic'
  return, 1
end

function mms_part_slice2d_ut::test_hpca_hplus_basic
  mms_part_slice2d, trange=['2015-12-15', '2015-12-15/0:01'], instrument='hpca', species='hplus', export='test_hpca_hplus_basic'
  return, 1
end

function mms_part_slice2d_ut::test_hpca_oplus_basic
  mms_part_slice2d, trange=['2015-12-15', '2015-12-15/0:01'], instrument='hpca', species='oplus', export='test_hpca_oplus_basic'
  return, 1
end

function mms_part_slice2d_ut::test_hpca_heplus_basic
  mms_part_slice2d, trange=['2015-12-15', '2015-12-15/0:01'], instrument='hpca', species='heplus', export='test_hpca_heplus_basic'
  return, 1
end

function mms_part_slice2d_ut::test_hpca_heplusplus_basic
  mms_part_slice2d, trange=['2015-12-15', '2015-12-15/0:01'], instrument='hpca', species='heplusplus', export='test_hpca_heplusplus_basic'
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