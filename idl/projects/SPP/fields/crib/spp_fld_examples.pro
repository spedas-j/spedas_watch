pro spp_fld_examples

  ; First, show the directory where you have SPEDAS installed.  If this yields
  ; an error or no result, then you need a recent 'bleeding edge' version
  ; of SPEDAS, see:
  ; http://spedas.org/wiki/index.php?title=Main_Page#Downloads_and_Installation

  libs, 'spp_fld_load_l1'

  ; Confirm that you have installed a recent version of the CDF patch.
  ; Versions including and above 3.6.3.1 should work.  If you don't have a
  ; recent version, install one from:
  ; https://cdf.gsfc.nasa.gov/html/cdf_patch_for_idl.html
  
  help, 'CDF', /dlm
  
  ; You can download files manually and load them, but it's easier to use
  ; the SPEDAS file_retrieve routine.  To do that, you'll need to set up 
  ; environment variables containing the directory you want to store the data,
  ; and your user name and password.
  
  if getenv('PSP_STAGING_DIR') EQ '' then $
    setenv, 'PSP_STAGING_DIR=your_test_directory' ; <- replace this 

  if getenv('USER') EQ '' then $
    setenv, 'USER=your_username' ; <- replace this 

  if getenv('PSP_STAGING_PW') EQ '' then $
    setenv, 'PSP_STAGING_PW=your_password' ; <- replace this 

  ; Set a timespan for a day in perihelion.  Loading multiple days should work
  ; but can be slow.

  timespan, '2018-11-02'
  
  ; This command should download a MAGo survey file

  spp_fld_make_or_retrieve_cdf, 'mago_survey', file = mago_file

  ; This command should load the file into tplot variables

  spp_fld_load_l1, mago_file

  ; Plot the B field data
  ; Caveats: no detailed gain and no offsets have been applied
  
  tplot, 'spp_fld_mago_survey'
  
  ; Plot the differential E12 field DFB waveform data
  
  ; (you can use /load on this command to call spp_fld_load_l1 automatically)
  spp_fld_make_or_retrieve_cdf, 'dfb_wf_01', /load ; E12

  tplot, 'spp_fld_dfb_wf_01_wav_data_v'

  ; the rest of the DFB waveforms
  
  spp_fld_make_or_retrieve_cdf, 'dfb_wf_02', /load ; E34
  spp_fld_make_or_retrieve_cdf, 'dfb_wf_03', /load ; SCM Bx
  spp_fld_make_or_retrieve_cdf, 'dfb_wf_04', /load ; SCM By
  spp_fld_make_or_retrieve_cdf, 'dfb_wf_05', /load ; SCM Bz
  spp_fld_make_or_retrieve_cdf, 'dfb_wf_06', /load ; V1
  spp_fld_make_or_retrieve_cdf, 'dfb_wf_07', /load ; V2
  spp_fld_make_or_retrieve_cdf, 'dfb_wf_08', /load ; V3

  ; RFS LFR and HFR data
  
  spp_fld_make_or_retrieve_cdf, 'rfs_hfr_auto', /load ; HFR
  spp_fld_make_or_retrieve_cdf, 'rfs_lfr_auto', /load ; LFR

  tplot, 'spp_fld_rfs_?fr_auto_averages_ch?_converted_V?V?'

  ; ephemeris
  
  spp_fld_make_or_retrieve_cdf, 'ephem_eclipj2000', /load
  spp_fld_make_or_retrieve_cdf, 'ephem_spp_hertn', /load

  tplot, 'spp_fld_ephem_' + [$
    'spp_hertn_radial_distance_rs', $
    'spp_hertn_radial_velocity', $
    'eclipj2000_position', $
    'eclipj2000_velocity']

  stop

end