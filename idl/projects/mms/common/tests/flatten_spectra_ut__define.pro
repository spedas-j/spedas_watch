;+
;
; Unit tests for flatten_spectra
;
; To run:
;     IDL> mgunit, 'flatten_spectra_ut'
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2019-01-22 12:00:19 -0800 (Tue, 22 Jan 2019) $
; $LastChangedRevision: 26490 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/flatten_spectra_ut__define.pro $
;-

function flatten_spectra_ut::test_to_kev_flux_samples
  tplot, ['mms3_hpca_hplus_flux_elev_0-360_spin', 'mms3_epd_eis_extof_proton_flux_omni_spin', 'mms3_epd_eis_phxtof_proton_flux_omni_spin', 'mms3_dis_energyspectr_omni_fast']
  flatten_spectra, /xlog, /ylog, /to_kev, /to_flux, time='2017-09-10/08:57:00', /png, filename='flatten_spectra_ut_to_kev_flux_samples', samples=20
  return, 1
end

function flatten_spectra_ut::test_to_kev_flux
  tplot, ['mms3_hpca_hplus_flux_elev_0-360_spin', 'mms3_epd_eis_extof_proton_flux_omni_spin', 'mms3_epd_eis_phxtof_proton_flux_omni_spin', 'mms3_dis_energyspectr_omni_fast']
  flatten_spectra, /xlog, /ylog, /to_kev, /to_flux, time='2017-09-10/08:57:00', /png, filename='flatten_spectra_ut_to_kev_flux'
  return, 1
end

function flatten_spectra_ut::test_to_kev
  tplot, ['mms3_hpca_hplus_flux_elev_0-360_spin', 'mms3_epd_eis_extof_proton_flux_omni_spin', 'mms3_epd_eis_phxtof_proton_flux_omni_spin', 'mms3_dis_energyspectr_omni_fast']
  flatten_spectra, /xlog, /ylog, /to_kev, time='2017-09-10/08:57:00', /png, filename='flatten_spectra_ut_to_kev'
  return, 1
end

function flatten_spectra_ut::test_to_flux
  tplot, ['mms3_hpca_hplus_flux_elev_0-360_spin', 'mms3_epd_eis_extof_proton_flux_omni_spin', 'mms3_epd_eis_phxtof_proton_flux_omni_spin', 'mms3_dis_energyspectr_omni_fast']
  flatten_spectra, /xlog, /ylog, /to_flux, time='2017-09-10/08:57:00', /png, filename='flatten_spectra_ut_to_flux'
  return, 1
end

function flatten_spectra_ut::test_no_conversion
  tplot, ['mms3_hpca_hplus_flux_elev_0-360_spin', 'mms3_epd_eis_extof_proton_flux_omni_spin', 'mms3_epd_eis_phxtof_proton_flux_omni_spin', 'mms3_dis_energyspectr_omni_fast']
  flatten_spectra, /xlog, /ylog, time='2017-09-10/08:57:00', /png, filename='flatten_spectra_ut_no_conversion'
  return, 1
end

function flatten_spectra_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self->addTestingRoutine, ['flatten_spectra', 'flatten_spectra_multi']
  trange=['2017-09-10/09:30:20', '2017-09-10/09:34:20']
  probe=3

  mms_load_fpi, trange=trange, datatype='dis-moms', probe=probe
  mms_load_eis, trange=trange, probe=probe, datatype=['extof', 'phxtof']
  mms_load_hpca, trange=trange, probe=probe, datatype='ion'
  mms_hpca_calc_anodes, fov=[0, 360]
  mms_hpca_spin_sum, /avg, probe=probe
  return, 1
end

pro flatten_spectra_ut__define
    define = { flatten_spectra_ut, inherits MGutTestCase }
end