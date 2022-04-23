;+
; NAME:
;    SPINMODEL_PYTHON_TEST.PRO
;
; PURPOSE:
;   Load several spin models and export them as CDFs for comparison with Python results
;
; CATEGORY:
;   TDAS 
;
; CALLING SEQUENCE:
;   spinmodel_python_test
;
;  INPUTS:
;    none
;
;  OUTPUTS:
;
;  KEYWORDS:
;    None.
;
;  PROCEDURE:
;    
;
;  EXAMPLE:
;     spinmodel_python_test
;
;Written by: Jim Lewis (jwl@ssl.berkeley.edu)
;Change Date: 2007-10-08
;-

pro spinmodel_python_test

trange=['2008-03-23','2008-04-23']
thm_load_state,probe='a',trange=trange,/get_supp,/keep_spin
smp0=spinmodel_get_ptr('a',use_ecl=0)
smp1=spinmodel_get_ptr('a',use_ecl=1)
smp2=spinmodel_get_ptr('a',use_ecl=2)
smp0->make_cdf,cdf_filename='tha_30day_corr0.cdf',prefix='tha_30day_corr0_'
smp1->make_cdf,cdf_filename='tha_30day_corr1.cdf',prefix='tha_30day_corr1_'
smp2->make_cdf,cdf_filename='tha_30day_corr2.cdf',prefix='tha_30day_corr2_'

end
