;+
; das2dlm_crib_basic.pro
;
; Description:
;   A crib sheet that shows basic commands to work with das2dlm library
;   Note, that it requres the dlm library (das2dlm) been installed in IDL
;
; Warning:
;   At the moment of the last change, Gallileo dataset on http://planet.physics.uiowa.edu/das/das2Server/source/Galileo/ was not available!
;   This could be resolved in the future 
;
; CREATED BY:
;   Alexander Drozdov (adrozdov@ucla.edu)
;
; $LastChangedBy: adrozdov $
; $Date: 2020-06-01 17:27:59 -0700 (Mon, 01 Jun 2020) $
; $Revision: 28753 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/das2dlm/examples/das2dlm_crib_basic.pro $
;-

; Specify the URL and the with time_start and time_end

time_start = '2001-01-01' ; Can be specifyed as 2001-001 
time_end = '2001-01-02' ; Can be specifyed as 2001-002
s = 'http://planet.physics.uiowa.edu/das/das2Server?server=dataset' + $
   '&dataset=Galileo/PWS/Survey_Electric&start_time=' + time_start + '&end_time=' + time_end
print, s

; Request and print data query
query = das2c_readhttp(s)
help, query

; Inspect Datasets (0), ds = das2c_datasets(query) can be used instead
ds = das2c_datasets(query, 0)
help, ds

; Inspecting Physical Dimensions (i.e. Variable Groups)
pdims = das2c_pdims(ds)
help, pdims

; Listing Variables
pd_freq = das2c_pdims(ds, 'frequency')
var_freq = das2c_vars(pd_freq)
help, var_freq

; Getting properties
props_freq = das2c_props(var_freq)
help, props_freq

; Geting Data Arrays
var_freq = das2c_vars(pd_freq, 'center')
arr = das2c_data(var_freq, {I:0, J:'*'}) ; Memory efficient frequency slice obtaining

; Cleaning up
res = das2c_free(query)

end