;+
;
; Unit tests for mms_python_validation_ut
;
; To run:
;     IDL> mgunit, 'mms_python_validation_ut'
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2020-11-05 18:21:30 -0800 (Thu, 05 Nov 2020) $
; $LastChangedRevision: 29330 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_python_validation_ut__define.pro $
;-

function mms_python_validation_ut::test_aspoc_default
  mms_load_aspoc, probe=1, trange=['2015-10-16','2015-10-17']
  py_script = ["from pyspedas import mms_load_aspoc", "mms_load_aspoc(probe=1, trange=['2015-10-16','2015-10-17'])"]
  vars = ['mms1_aspoc_ionc_l2']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_fgm_default
  mms_load_fgm, probe=1, trange=['2015-10-16','2015-10-17']
  py_script = ["from pyspedas import mms_load_fgm", "mms_load_fgm(probe=1, trange=['2015-10-16','2015-10-17'])"]
  vars = ['mms1_fgm_b_gse_srvy_l2', 'mms1_fgm_b_gsm_srvy_l2']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_fgm_brst
  mms_load_fgm, data_rate='brst', probe=4, trange=['2015-10-16/13:06', '2015-10-16/13:07']
  py_script = ["from pyspedas import mms_load_fgm", "mms_load_fgm(data_rate='brst', probe=4, trange=['2015-10-16/13:06', '2015-10-16/13:07'])"]
  vars = ['mms4_fgm_b_gse_brst_l2', 'mms4_fgm_b_gsm_brst_l2']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_fgm_curlometer
  mms_load_fgm, data_rate='brst', probe=[1, 2, 3, 4], trange=['2015-10-30/05:15:45', '2015-10-30/05:15:48'], /get_fgm_ephem, /time_clip
  fields = 'mms'+['1', '2', '3', '4']+'_fgm_b_gse_brst_l2'
  positions = 'mms'+['1', '2', '3', '4']+'_fgm_r_gse_brst_l2'

  mms_curl, trange=['2015-10-30/05:15:45', '2015-10-30/05:15:48'], fields=fields, positions=positions
  py_script = ["from pyspedas import mms_load_fgm", $
               "from pyspedas.mms import curlometer", $
               "mms_load_fgm(time_clip=True, data_rate='brst', probe=[1, 2, 3, 4], trange=['2015-10-30/05:15:45', '2015-10-30/05:15:48'])", $
               "positions = ['mms1_fgm_r_gse_brst_l2', 'mms2_fgm_r_gse_brst_l2', 'mms3_fgm_r_gse_brst_l2', 'mms4_fgm_r_gse_brst_l2']", $
               "fields = ['mms1_fgm_b_gse_brst_l2', 'mms2_fgm_b_gse_brst_l2', 'mms3_fgm_b_gse_brst_l2', 'mms4_fgm_b_gse_brst_l2']", $
               "curlometer(fields=fields, positions=positions)"]
  vars = ['baryb', 'curlB', 'divB', 'jtotal', 'jpar', 'jperp', 'alpha', 'alphaparallel']
  return, spd_run_py_validation(py_script, vars, tol=1e-4)
end

function mms_python_validation_ut::test_edi_default
; problem with the data on 10/16/15
  mms_load_edi, trange=['2016-10-16','2016-10-17']
  py_script = ["from pyspedas import mms_load_edi", "mms_load_edi(trange=['2016-10-16','2016-10-17'])"]
  vars = ['mms1_edi_e_gse_srvy_l2', 'mms1_edi_e_gsm_srvy_l2', 'mms1_edi_vdrift_gse_srvy_l2', 'mms1_edi_vdrift_gsm_srvy_l2']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_scm_default
  mms_load_scm, trange=['2015-10-15','2015-10-16']
  py_script = ["from pyspedas import mms_load_scm", "mms_load_scm(trange=['2015-10-15','2015-10-16'])"]
  vars = ['mms1_scm_acb_gse_scsrvy_srvy_l2']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_scm_brst
  mms_load_scm, data_rate='brst', probe=1, trange=['2015-10-16/13:06', '2015-10-16/13:07']
  py_script = ["from pyspedas import mms_load_scm", "mms_load_scm(trange=['2015-10-16/13:06', '2015-10-16/13:07'], data_rate='brst', probe=1)"]
  vars = ['mms1_scm_acb_gse_scb_brst_l2', 'mms1_scm_acb_gse_schb_brst_l2']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_scm_dpwrspc_brst
  mms_load_scm, data_rate='brst', probe=1, trange=['2015-10-16/13:06', '2015-10-16/13:07']
  tdpwrspc, 'mms1_scm_acb_gse_scb_brst_l2', nboxpoints=8192, nshiftpoints=8192, bin=1
  py_script = ["from pyspedas import mms_load_scm", $
    "from pyspedas.analysis.tdpwrspc import tdpwrspc", $
    "mms_load_scm(trange=['2015-10-16/13:06', '2015-10-16/13:07'], data_rate='brst', probe=1)", $
    "tdpwrspc('mms1_scm_acb_gse_scb_brst_l2', nboxpoints=8192, nshiftpoints=8192, binsize=1)"]
  vars = ['mms1_scm_acb_gse_scb_brst_l2_x_dpwrspc', 'mms1_scm_acb_gse_scb_brst_l2_y_dpwrspc', 'mms1_scm_acb_gse_scb_brst_l2_z_dpwrspc']
  return, spd_run_py_validation(py_script, vars, tol=1e-4)
end

function mms_python_validation_ut::test_edp_default
  mms_load_edp, probe=1, trange=['2015-10-16','2015-10-17']
  py_script = ["from pyspedas import mms_load_edp", "mms_load_edp(probe=1, trange=['2015-10-16','2015-10-17'])"]
  vars = ['mms1_edp_dce_gse_fast_l2']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_edp_brst
  mms_load_edp, data_rate='brst', probe=1, trange=['2015-10-16/13:06', '2015-10-16/13:07']
  py_script = ["from pyspedas import mms_load_edp", "mms_load_edp(data_rate='brst', probe=1, trange=['2015-10-16/13:06', '2015-10-16/13:07'])"]
  vars = ['mms1_edp_dce_gse_brst_l2']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_dsp_psd
  mms_load_dsp, data_rate='fast', trange=['2015-10-16', '2015-10-17'], datatype=['epsd', 'bpsd'], level='l2'
  py_script = ["from pyspedas import mms_load_dsp", "mms_load_dsp(trange=['2015-10-16', '2015-10-17'], data_rate='fast', datatype=['epsd', 'bpsd'], level='l2')"]
  vars = ['mms1_dsp_epsd_omni', 'mms1_dsp_bpsd_omni_fast_l2']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_mec_default
  mms_load_mec, trange=['2015-10-16','2015-10-17']
  py_script = ["from pyspedas import mms_load_mec", "mms_load_mec(trange=['2015-10-16','2015-10-17'])"]
  vars = ['mms1_mec_r_gsm', 'mms1_mec_r_gse', 'mms1_mec_r_sm', 'mms1_mec_v_gsm', 'mms1_mec_v_gse', 'mms1_mec_v_sm']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_feeps_srvy_electron
  mms_load_feeps, trange=['2015-10-16','2015-10-17']
  py_script = ["from pyspedas import mms_load_feeps", "mms_load_feeps(trange=['2015-10-16','2015-10-17'])"]
  vars = ['mms1_epd_feeps_srvy_l2_electron_intensity_omni', 'mms1_epd_feeps_srvy_l2_electron_intensity_omni_spin']
  return, spd_run_py_validation(py_script, vars, tol=1e-4)
end

function mms_python_validation_ut::test_feeps_srvy_ion
  mms_load_feeps, datatype='ion', trange=['2015-10-16','2015-10-17']
  py_script = ["from pyspedas import mms_load_feeps", "mms_load_feeps(trange=['2015-10-16','2015-10-17'], datatype='ion')"]
  vars = ['mms1_epd_feeps_srvy_l2_ion_intensity_omni', 'mms1_epd_feeps_srvy_l2_ion_intensity_omni_spin']
  return, spd_run_py_validation(py_script, vars, tol=1e-4)
end

function mms_python_validation_ut::test_feeps_brst_ion
  mms_load_feeps, data_rate='brst', datatype='ion', trange=['2015-10-16/13:06', '2015-10-16/13:07']
  py_script = ["from pyspedas import mms_load_feeps", "mms_load_feeps(trange=['2015-10-16/13:06', '2015-10-16/13:07'], datatype='ion', data_rate='brst')"]
  vars = ['mms1_epd_feeps_brst_l2_ion_intensity_omni']
  return, spd_run_py_validation(py_script, vars, tol=1e-4)
end

function mms_python_validation_ut::test_feeps_brst_electron
  mms_load_feeps, data_rate='brst', trange=['2015-10-16/13:06', '2015-10-16/13:07']
  py_script = ["from pyspedas import mms_load_feeps", "mms_load_feeps(trange=['2015-10-16/13:06', '2015-10-16/13:07'], data_rate='brst')"]
  vars = ['mms1_epd_feeps_brst_l2_electron_intensity_omni']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_eis_default
  mms_load_eis, datatype=['extof', 'phxtof'], probe=4, trange=['2019-10-16','2019-10-17']
  py_script = ["from pyspedas import mms_load_eis", "mms_load_eis(datatype=['extof', 'phxtof'], probe=4, trange=['2019-10-16','2019-10-17'])"]
  vars = ['mms4_epd_eis_extof_proton_flux_omni', 'mms4_epd_eis_phxtof_proton_flux_omni', 'mms4_epd_eis_extof_proton_flux_omni_spin', 'mms4_epd_eis_phxtof_proton_flux_omni_spin']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_eis_brst
  mms_load_eis, datatype=['extof', 'phxtof'], probe=1, data_rate='brst', trange=['2015-10-16/13:06', '2015-10-16/13:07']
  py_script = ["from pyspedas import mms_load_eis", "mms_load_eis(datatype=['extof', 'phxtof'], probe=1, data_rate='brst', trange=['2015-10-16/13:06', '2015-10-16/13:07'])"]
  vars = ['mms1_epd_eis_brst_phxtof_proton_flux_omni', 'mms1_epd_eis_brst_phxtof_oxygen_flux_omni', 'mms1_epd_eis_brst_extof_proton_flux_omni', 'mms1_epd_eis_brst_extof_alpha_flux_omni', 'mms1_epd_eis_brst_extof_oxygen_flux_omni']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_fpi_default
  mms_load_fpi, datatype=['des-moms', 'dis-moms'], probe=1, trange=['2015-10-16','2015-10-17']
  py_script = ["from pyspedas import mms_load_fpi", "mms_load_fpi(datatype=['des-moms', 'dis-moms'], probe=1, trange=['2015-10-16','2015-10-17'])"]
  vars = ['mms1_des_energyspectr_omni_fast', 'mms1_dis_energyspectr_omni_fast', 'mms1_dis_bulkv_gse_fast', 'mms1_des_bulkv_gse_fast', 'mms1_des_numberdensity_fast', 'mms1_dis_temppara_fast', 'mms1_dis_tempperp_fast']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_fpi_brst
  mms_load_fpi, data_rate='brst', datatype=['des-moms', 'dis-moms'], probe=1, trange=['2015-10-16/13:06', '2015-10-16/13:07']
  py_script = ["from pyspedas import mms_load_fpi", "mms_load_fpi(data_rate='brst', datatype=['des-moms', 'dis-moms'], probe=1, trange=['2015-10-16/13:06', '2015-10-16/13:07'])"]
  vars = ['mms1_des_energyspectr_omni_brst', 'mms1_des_numberdensity_brst', 'mms1_des_bulkv_gse_brst', 'mms1_dis_energyspectr_omni_brst', 'mms1_dis_bulkv_gse_brst', 'mms1_dis_numberdensity_brst']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_hpca_ion
  mms_load_hpca, datatype='ion', probe=1, trange=['2016-10-16','2016-10-16/03:00']
  mms_hpca_calc_anodes, fov=[0, 360]
  mms_hpca_spin_sum, probe='1'
  py_script = ["from pyspedas import mms_load_hpca", "from pyspedas.mms.hpca.mms_hpca_calc_anodes import mms_hpca_calc_anodes", "from pyspedas.mms.hpca.mms_hpca_spin_sum import mms_hpca_spin_sum", "mms_load_hpca(datatype='ion', probe=1, trange=['2016-10-16','2016-10-16/03:00'])", "mms_hpca_calc_anodes(fov=[0, 360], probe='1')", "mms_hpca_spin_sum(probe='1')"]
  vars = ['mms1_hpca_hplus_flux_elev_0-360_spin', 'mms1_hpca_heplus_flux_elev_0-360_spin', 'mms1_hpca_heplusplus_flux_elev_0-360_spin', 'mms1_hpca_oplus_flux_elev_0-360_spin']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_hpca_brst_ion
  mms_load_hpca, data_rate='brst', datatype='ion', probe=1, trange=['2015-10-16/13:05', '2015-10-16/13:10']
  mms_hpca_calc_anodes, fov=[0, 360]
  mms_hpca_spin_sum, probe='1'
  py_script = ["from pyspedas import mms_load_hpca", "from pyspedas.mms.hpca.mms_hpca_calc_anodes import mms_hpca_calc_anodes", "from pyspedas.mms.hpca.mms_hpca_spin_sum import mms_hpca_spin_sum", "mms_load_hpca(data_rate='brst', datatype='ion', probe=1, trange=['2015-10-16/13:05', '2015-10-16/13:10'])", "mms_hpca_calc_anodes(fov=[0, 360], probe='1')", "mms_hpca_spin_sum(probe='1')"]
  vars = ['mms1_hpca_hplus_flux_elev_0-360_spin', 'mms1_hpca_heplus_flux_elev_0-360_spin', 'mms1_hpca_heplusplus_flux_elev_0-360_spin', 'mms1_hpca_oplus_flux_elev_0-360_spin']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_hpca_moments
  mms_load_hpca, datatype='moments', probe=1, trange=['2016-10-16','2016-10-16/03:00']
  py_script = ["from pyspedas import mms_load_hpca", "mms_load_hpca(datatype='moments', probe=1, trange=['2016-10-16','2016-10-16/03:00'])"]
  vars = ['mms1_hpca_hplus_number_density', 'mms1_hpca_hplus_ion_bulk_velocity', 'mms1_hpca_hplus_scalar_temperature', 'mms1_hpca_oplus_number_density', 'mms1_hpca_oplus_ion_bulk_velocity', 'mms1_hpca_oplus_scalar_temperature']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_hpca_brst_moments
  mms_load_hpca, data_rate='brst', datatype='moments', probe=1, trange=['2015-10-16/13:05', '2015-10-16/13:10']
  py_script = ["from pyspedas import mms_load_hpca", "mms_load_hpca(data_rate='brst', datatype='moments', probe=1, trange=['2015-10-16/13:05', '2015-10-16/13:10'])"]
  vars = ['mms1_hpca_hplus_number_density', 'mms1_hpca_hplus_ion_bulk_velocity', 'mms1_hpca_hplus_scalar_temperature', 'mms1_hpca_oplus_number_density', 'mms1_hpca_oplus_ion_bulk_velocity', 'mms1_hpca_oplus_scalar_temperature']
  return, spd_run_py_validation(py_script, vars)
end

pro mms_python_validation_ut::setup
  del_data, '*'
end

pro mms_python_validation_ut__define
  define = { mms_python_validation_ut, inherits MGutTestCase }
end