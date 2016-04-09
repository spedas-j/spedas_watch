;+
; MMS FEEPS quicklook plots crib sheet
;
; do you have suggestions for this crib sheet?
;   please send them to egrimes@igpp.ucla.edu
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-04-06 14:56:25 -0700 (Wed, 06 Apr 2016) $
; $LastChangedRevision: 20736 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/quicklook/mms_load_feeps_crib_qlplots.pro $
;-

probe = '1'
date = '2016-2-15'
timespan, date, 1
width = 950
height = 1000
; options:
; 1) intensity
; 2) count_rate
; 3) counts
;;; note, supposed to be count_rate for production; but I'm currently testing with intensity
type = 'count_rate'
data_rate = 'srvy'

; options for send_plots_to:
;   ps: postscript files
;   png: png files
;   win: creates/opens all of the tplot windows

send_plots_to = 'win'
plot_directory = ''

postscript = send_plots_to eq 'ps' ? 1 : 0

; handle any errors that occur in this script gracefully
catch, errstats
if errstats ne 0 then begin
  error = 1
  dprint, dlevel=1, 'Error: ', !ERROR_STATE.MSG
  catch, /cancel
endif

mms_load_feeps, probe=probe, data_rate=data_rate, datatype='electron', suffix='_electrons', data_units = type, varformat='*spinsectnum* *top* *bottom* *pitch_angle*'
mms_load_feeps, probe=probe, data_rate=data_rate, datatype='ion', suffix='_ions', data_units = type, varformat='*spinsectnum* *top* *bottom* *pitch_angle*'

mms_feeps_pad, probe = probe, datatype = 'electron', suffix='_electrons', energy=[70, 71], data_units = type
mms_feeps_pad, probe = probe, datatype = 'electron', suffix='_electrons', energy=[200, 201], data_units = type
mms_feeps_pad, probe = probe, datatype = 'ion', suffix='_ions', energy=[76, 77], data_units = type
mms_feeps_pad, probe = probe, datatype = 'ion', suffix='_ions', energy=[205, 206], data_units = type

; we use the B-field data at the top of the plot, and the position data in GSM coordinates
; loaded from the QL DFG files
mms_load_fgm, instrument='dfg', probes=probe, level='ql', /no_attitude_data

; time clip the data to -150nT to 150nT
b_variable = '_dfg_srvy_dmpa'
prefix = 'mms'+probe
suffix_kludge = ['0', '1', '2']
split_vec, prefix+b_variable
tclip, prefix+b_variable+'_?', -150, 150, /overwrite
tclip, prefix+b_variable+'_btot', -150, 150, /overwrite
store_data, prefix+b_variable+'_clipped', data=prefix+[b_variable+'_'+suffix_kludge, b_variable+'_btot']
options, prefix+b_variable+'_clipped', labflag=-1
options, prefix+b_variable+'_clipped', labels=['Bx DMPA', 'By DMPA', 'Bz DMPA', 'Bmag']
options, prefix+b_variable+'_clipped', colors=[2, 4, 6, 0]
options, prefix+b_variable+'_clipped', ytitle=prefix+'!CFGM QL'

; ephemeris data - set the label to show along the bottom of the tplot
eph_gsm = 'mms'+probe+'_ql_pos_gsm'

; convert km to re
calc,'"'+eph_gsm+'_re" = "'+eph_gsm+'"/6378.'

; split the position into its components
split_vec, eph_gsm+'_re'

options, eph_gsm+'_re_0',ytitle='X-GSM (Re)'
options, eph_gsm+'_re_1',ytitle='Y-GSM (Re)'
options, eph_gsm+'_re_2',ytitle='Z-GSM (Re)'
options, eph_gsm+'_re_3',ytitle='R (Re)'
position_vars = eph_gsm+'_re_'+['3', '2', '1', '0']

if ~postscript then window, xsize=width, ysize=height

tplot_options, 'xmargin', [15, 15]

; data availability bar
spd_mms_load_bss, datatype=['fast', 'burst'], /include_labels

tplot, [['mms_bss_burst', 'mms_bss_fast'], $
        'mms'+probe+['_epd_feeps_electron_'+type+'_omni_spin_electrons', $
                    '_epd_feeps_*keV_pad*electrons*spin', $
                    '_epd_feeps_ion_'+type+'_omni_spin_ions', $
                    '_epd_feeps_*keV_pad*ions*spin', $
                    '_dfg_srvy_dmpa_clipped' $
                    ]], var_label=position_vars

if send_plots_to eq 'png' then begin
  thm_gen_multipngplot, 'mms'+probe+'_', date, directory = plot_directory, /mkdir
endif
if postscript then tprint, plot_directory + 'mms'+probe+'_feeps_qlplots"
end