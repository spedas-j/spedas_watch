;+
;Procedure:
;  mms_part_getspec_crib
;
;
;Purpose:
;  Basic example on how to use mms_part_getspec to generate particle
;  spectrograms and moments from level 2 MMS HPCA and FPI distributions.
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2018-03-20 11:29:29 -0700 (Tue, 20 Mar 2018) $
;$LastChangedRevision: 24916 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/advanced/mms_part_getspec_crib.pro $
;-

;==========================================================
; FPI - L2
;==========================================================

; clear data
del_data,'*'

; use short time range for data due to high resolution
timespan, '2015-10-16/13:05:40', 30, /sec

; generate products
mms_part_getspec, instrument='fpi', probe='1', species='e', data_rate='brst', level='l2', outputs=['phi', 'theta', 'energy', 'pa', 'gyro']

; plot spectrograms
tplot, 'mms1_des_dist_brst_'+['energy','theta','phi','pa','gyro']

stop

; the following shows how to add the errorflag bars to the spectrograms
; note: the errorflags tplot variable is loaded automatically by mms_part_getspec
tplot, 'mms1_des_errorflags_brst_dist_flagbars_dist', /add
stop

;plot moments
; !!!!!! words of caution <------ by egrimes, 4/7/2016:
; While you can use mms_part_getspec/mms_part_products to generate particle moments for FPI from
; the distributions, these calculations are currently missing several important
; components, including photoelectron removal and S/C potential corrections.
; The official moments released by the team include these, and are the scientific
; products you should use in your analysis
;
;
; The following example shows how to load the FPI moments
; released by the team (des-moms, dis-moms datatypes):
mms_load_fpi, probe='1', data_rate='brst', level='l2', datatype='des-moms'
tplot, 'mms1_des_numberdensity_brst'

; add the errorflags bar to the top of the plot
tplot, /add, 'mms1_des_errorflags_brst_moms_flagbars_full'
stop

;==========================================================
; FPI - L2, ions, with and without bulk velocity subtracted
;==========================================================

mms_part_getspec, /subtract_bulk, suffix='_bulk', trange=['2015-10-16/13:05:40', '2015-10-16/13:06:40'], probe='1', species='i', data_rate='brst', level='l2', outputs=['phi', 'theta', 'energy', 'pa', 'gyro']
mms_part_getspec, trange=['2015-10-16/13:05:40', '2015-10-16/13:06:40'], probe='1', species='i', data_rate='brst', level='l2', outputs=['phi', 'theta', 'energy', 'pa', 'gyro']

; plot the spectrograms
tplot, 'mms1_dis_dist_brst_'+['energy', 'energy_bulk', 'pa', 'pa_bulk']
stop

;==========================================================
; FPI - L2, ions, with bulk velocity and distribution error subtracted
;==========================================================

mms_part_getspec, /subtract_bulk, /subtract_error, suffix='_bulk', trange=['2015-10-16/13:05:40', '2015-10-16/13:06:40'], probe='1', species='i', data_rate='brst', level='l2', outputs=['phi', 'theta', 'energy', 'pa', 'gyro']

; plot the spectrograms
tplot, 'mms1_dis_dist_brst_'+['energy_bulk', 'pa_bulk']
stop

;==========================================================
; FPI - L2, multi-dimensional PAD variable (pitch angle spectrograms at each energy)
;==========================================================

mms_part_getspec, probe='1', species='e', data_rate='brst', level='l2', output='multipad'

; generate the PAD at the full energy range by leaving off the energy keyword
mms_part_getpad, probe=1, species='e', data_rate='brst'

tplot, 'mms1_des_dist_brst_pad_10.6600eV_30622.2eV'
stop

; now generate the PADs at various energy ranges
mms_part_getpad, probe=1, species='e', data_rate='brst', energy=[0, 10]
mms_part_getpad, probe=1, species='e', data_rate='brst', energy=[10, 50]
mms_part_getpad, probe=1, species='e', data_rate='brst', energy=[50, 100]
mms_part_getpad, probe=1, species='e', data_rate='brst', energy=[100, 1000]
mms_part_getpad, probe=1, species='e', data_rate='brst', energy=[1000, 10000]
mms_part_getpad, probe=1, species='e', data_rate='brst', energy=[10000, 20000]
mms_part_getpad, probe=1, species='e', data_rate='brst', energy=[10000, 30000]

tplot, 'mms1_des_dist_brst_pad_'+['0eV_10eV', '10eV_50eV', '50eV_100eV', '100eV_1000eV', '1000eV_10000eV', '10000eV_20000eV', '10000eV_30000eV'], /add
stop

;==========================================================
; HPCA - L2
;==========================================================

;clear data
del_data,'*'

timespan, '2016-10-16/13:09', 2, /min

mms_part_getspec, instrument='hpca', probe='1', species='hplus', data_rate='brst', level='l2', outputs=['phi', 'theta', 'energy', 'pa', 'gyro', 'moments']

;generate products (experimental option)
;  The /no_regrid option uses a regular transformation on the HPCA to avoid the more general spherical interpolation
;    The main benefit of the /no_regrid keyword is to reduce the runtime of mms_part_products
;  mms_part_products, name, trange=trange,/no_regrid, $
;                     mag_name=bname, pos_name=pos_name, $ ;required for field aligned spectra
;                     outputs=['energy','phi','theta','pa','gyro','moments']

;plot spectrograms
tplot, 'mms1_hpca_hplus_phase_space_density_'+['energy','theta','phi','pa','gyro']

stop

;plot moments
tplot, 'mms1_hpca_hplus_phase_space_density_'+['density', 'avgtemp']

stop




end