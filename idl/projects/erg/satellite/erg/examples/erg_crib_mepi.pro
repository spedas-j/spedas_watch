;+
; erg_crib_mepe.pro 
;
; :Description:
; A crib sheet containing basic examples to demonstrate the loading
; and plotting of Medium-energy Particle Experiments - ion mass
; analyzer (MEP-i) data obtained by
; the ERG (Arase) satellite.  
;
;:Author:
; Tomo Hori, ERG Science Center ( E-mail: tomo.hori _at_ nagoya-u.jp )
;
; Written by: T. Hori
;   $LastChangedBy: c0004hori $
;   $LastChangedDate: 2018-09-02 18:35:51 +0900 (Sun, 02 Sep 2018) $
;   $LastChangedRevision: 582 $
;   $URL: https://ergsc-local.isee.nagoya-u.ac.jp/svn/ergsc/trunk/erg/satellite/erg/examples/erg_crib_mepi.pro $
;-

;; Initialize
erg_init

;; Set a time range
timespan, '2017-03-27'

;; Load the omni-flux data and display the loaded tplot variables
erg_load_mepi_nml, datatype='omniflux'
tplot_names

stop

;; Plot omni-flux data of all ion species available, as spectrograms 
tplot, [ 'erg_mepi_l2_omniflux_F*DO' ]

stop

;; Load the 3-D flux data
erg_load_mepi_nml, datatype='3dflux'
tplot_names

stop

;; Plot
tplot, [ 'erg_mepi_l2_3dflux_F*DU' ]

stop

;; Clean up all data variables
store_data, delete='erg_mepi_l2_3dflux_*'

;; Load only the 3-D proton flux data and split them into data of each anode
erg_load_mepi_nml, datatype='3dflux', varformat='FPDU', /split_anode
tplot_names

stop

;; Plot data for anode#03 and #07, for example
tplot, 'erg_mepi_l2_3dflux_FPDU_anode' + ['03', '07']



end
