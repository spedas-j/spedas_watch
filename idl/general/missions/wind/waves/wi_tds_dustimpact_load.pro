;+
;*****************************************************************************************
;
;  PROCEDURE:   wi_tds_dustimpact_load.pro
;  PURPOSE  :   This routine retrieves/downloads CDF files and loads the resulting data
;                 into TPLOT.  The data files contain the dust impact database from the
;                 Wind/WAVES instrument's time domain sampler (TDS), created by
;                 David M. Malaspina and Lynn B. Wilson III as part of a 2014 NASA
;                 ROSES Heliophysics Guest Investigator (H-GI) program for the Open Data-
;                 Development Element (ODDE) grant.
;
;  CALLED BY:   
;               NA
;
;  INCLUDES:
;               NA
;
;  CALLS:
;               time_string.pro
;               time_double.pro
;               root_data_dir.pro
;               wind_init.pro
;               spd_get_valid_trange.pro
;               is_num.pro
;               file_dailynames.pro
;               spd_download.pro
;               file_retrieve.pro
;               timespan.pro
;               cdf2tplot.pro
;               tnames.pro
;               options.pro
;               tplot_options.pro
;               get_data.pro
;               store_data.pro
;
;  REQUIRES:    
;               1)  SPEDAS IDL Libraries
;               2)  TDS dust impact database CDF files at:
;                     http://spdf.gsfc.nasa.gov/pub/data/wind/waves/dust_impact_l3/
;
;  INPUT:
;               NA
;
;  EXAMPLES:    
;               [calling sequence]
;               wi_tds_dustimpact_load [,TRANGE=trange] [,VERBOSE=verbose]       $
;                                      [,/DOWNLOADONLY] [,VARFORMAT=varformat]   $
;                                      [,SOURCE_OPTIONS=source] [,/ADDMASTER]    $
;                                      [,PREFIX=prefix] [,MIDFIX=midfix]         $
;                                      [,MIDPOS=midpos] [,SUFFIX=suffix]         $
;                                      [/LOAD_LABELS] [,FILES=files]             $
;                                      [,TPLOTNAMES=tplotnames]
;
;               ;;  Example:  Get dust impacts between Jan. 1-4, 2000
;               tdate_st       = '2000-01-01'
;               tdate_en       = '2000-01-04'
;               start_of_day   = '00:00:00.000'
;               end___of_day   = '23:59:59.999'
;               tr_t           = [tdate_st[0]+'/'+start_of_day[0],tdate_en[0]+'/'+end___of_day[0]]
;               tran           = time_double(tr_t)
;               wi_tds_dustimpact_load,TRANGE=tran,FILES=files,TPLOTNAMES=tplotnames
;
;  KEYWORDS:    
;               **********************************
;               ***       DIRECT  INPUTS       ***
;               **********************************
;               TRANGE          :  [2]-Element [double] array specifying the Unix time
;                                   range for which to limit the data in DATA
;                                   [Default = handled by file finding routines]
;               VERBOSE         :  Scalar [numeric] defining the level to which the
;                                    routine dprint.pro outputs information
;               DOWNLOADONLY    :  If set, routine will exit after it retrieves the
;                                    desired data files
;                                    [Default = FALSE]
;               VARFORMAT       :  Scalar or [N]-Element [string] array specifying the
;                                    CDF variable names to load into TPLOT
;                                    [Default = '*' (for all variables)]
;               DATATYPE        :  ***  Not Used by this routine  ***
;                                    [kept for compatibility with other SPEDAS routines]
;               SOURCE_OPTIONS  :  Scalar [structure] defining information relevant to
;                                    local and remote file management
;                                    [Default = !wind (initiated by wind_init.pro)]
;               ADDMASTER       :  If set, the routine file_dailynames.pro will add a
;                                    file path with the zeroth date
;                                    [Default = FALSE]
;               PREFIX          :  Scalar [string] defining the characters that will
;                                    pre-pend all TPLOT handles produced by this routine
;                                    [Default = 'Wind_tds_dust_']
;               MIDFIX          :  Scalar [string] defining the characters that will
;                                    be placed at MIDPOS within all TPLOT handles
;                                    produced by this routine
;                                    [Default = '']
;               MIDPOS          :  Scalar [numeric] defining the starting character
;                                    position in which to place the string defined by
;                                    the MIDFIX keyword
;                                    [Default = 0]
;               SUFFIX          :  Scalar [string] defining the characters that will
;                                    append all TPLOT handles produced by this routine
;                                    [Default = '']
;               LOAD_LABELS     :  If set, the labels from labl_ptr_1 in the CDF file
;                                    attributes will be copied into the TPLOT DLIMITS
;                                    structure
;               *****************
;               ***  OUTPUTS  ***
;               *****************
;               FILES           :  [N]-Element [string] array of file names, with full
;                                    directory paths, to the CDF files downloaded and
;                                    loaded (or just loaded) into TPLOT
;               TPLOTNAMES      :  [N]-Element [string] array of TPLOT handles loaded
;
;   CHANGED:  1)  Continued to write routine
;                                                                   [08/24/2016   v1.0.0]
;             2)  Continued to write routine
;                                                                   [08/24/2016   v1.0.0]
;             3)  Continued to write routine
;                                                                   [08/25/2016   v1.0.0]
;             4)  Continued to write routine
;                                                                   [09/02/2016   v1.0.0]
;             5)  Continued to write routine
;                                                                   [09/02/2016   v1.0.0]
;             6)  Continued to write routine
;                                                                   [09/02/2016   v1.0.0]
;             7)  Finished writing routine
;                                                                   [09/02/2016   v1.0.0]
;             8)  Now calls spd_get_valid_trange.pro and cleaned up a little and
;                   moved to SPEDAS directory
;                                                                   [09/08/2016   v1.1.0]
;             9)  Updated SPDF URL:  All NASA URLs are now https
;                                                                   [02/09/2017   v1.1.1]
;
;   NOTES:      
;               1)  If the TRANGE keyword is not set, the routine will prompt the user
;                     for a date and then define the time range as one full day
;
;  REFERENCES:  
;               1)  Bougeret, J.-L., M.L. Kaiser, P.J. Kellogg, R. Manning, K. Goetz,
;                      S.J. Monson, N. Monge, L. Friel, C.A. Meetre, C. Perche,
;                      L. Sitruk, and S. Hoang "WAVES:  The Radio and Plasma
;                      Wave Investigation on the Wind Spacecraft," Space Sci. Rev.
;                      Vol. 71, pp. 231-263, doi:10.1007/BF00751331, (1995).
;               2)  Malaspina, D.M., M. Horanyi, A. Zaslavsky, K. Goetz, L.B. Wilson III,
;                      and K. Kersten "Interplanetary and interstellar dust observed by
;                      the Wind/WAVES electric field instrument," Geophys. Res. Lett.
;                      Vol. 41, pp. 266-272, doi:10.1002/2013GL058786, (2014).
;               3)  Malaspina, D.M., and L.B. Wilson III "A Database of Interplanetary
;                      and Interstellar Dust Detected by the Wind Spacecraft,"
;                      J. Geophys. Res. Vol. 121, submitted July 19, 2016.
;
;   CREATED:  08/23/2016
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  02/09/2017   v1.1.1
;    MODIFIED BY: Lynn B. Wilson III
;
; $LastChangedBy: lbwilsoniii_desk $
; $LastChangedDate: 2017-02-09 11:42:45 -0800 (Thu, 09 Feb 2017) $
; $LastChangedRevision: 22754 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/wind/waves/wi_tds_dustimpact_load.pro $
;
;*****************************************************************************************
;-

PRO wi_tds_dustimpact_load,TRANGE=trange,VERBOSE=verbose,DOWNLOADONLY=downloadonly,       $
                           VARFORMAT=varformat,DATATYPE=datatype,SOURCE_OPTIONS=source,   $
                           ADDMASTER=addmaster,PREFIX=prefix,MIDFIX=midfix,MIDPOS=midpos, $
                           SUFFIX=suffix,LOAD_LABELS=load_labels,                         $
                           FILES=files,TPLOTNAMES=tplotnames

ex_start       = SYSTIME(1)
;;----------------------------------------------------------------------------------------
;;  Constants
;;----------------------------------------------------------------------------------------
ver_str        = !VERSION
vern           = ver_str.RELEASE                             ;;  e.g., '8.5.1'
vernf          = FLOAT(vern[0])                              ;;  e.g., 8.5
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
http_slash     = '/'                                         ;;  separator for URLs
R_Ea__m        = 6.3781366d06                                ;;  Earth's Mean Equatorial Radius [m, 2015 AA values]
R_E            = R_Ea__m[0]*1d-3                             ;;  m --> km
;;  Regular Expressions
str_regex_int  = '^[-+]?[0-9][0-9]*$'                                     ;;  Regular expression for integer-only
;;----------------------------------------------------------------------------------------
;;  Define dummy time variables
;;----------------------------------------------------------------------------------------
tdate_launch   = '1994-11-01'                                ;;  launch date of Wind
tdate0         = '1995-01-01'                                ;;  start of CDF files
t_current      = time_string(ex_start[0],PREC=3)
tdate1         = STRMID(t_current[0],0L,10L)                 ;;  Current date
yr_st_en       = STRMID([tdate0[0],tdate1[0]],0L,4L)
start_of_day   = '00:00:00.000'
end___of_day   = '23:59:59.999'
def_toffset    = 36d1*864d2                                  ;;  Assume data files are at least 1 year behind current date
;;  Define the maximum possible time range
tr_tmax        = [tdate0[0]+'/'+start_of_day[0],tdate1[0]+'/'+end___of_day[0]]
tr_dmax        = time_double(tr_tmax)
;;  Define the DOY values at the start of each month for non-leap and leap years
mdt            = [[0, 31,  59,  90, 120, 151, 181, 212, 243, 273, 304, 334, 365], $
                  [0, 31,  60,  91, 121, 152, 182, 213, 244, 274, 305, 335, 366]]
;;  Define the # of days in each month for non-leap and leap years
nd_permon      = INTARR(13,2)
x              = LINDGEN(12)  & y = x + 1L
nd_permon[y,*] = mdt[y,*] - mdt[x,*]     ;;  # of days in each month
;;----------------------------------------------------------------------------------------
;;  Define other dummy variables
;;----------------------------------------------------------------------------------------
;;  Define dummy angle bin arrays
nang           = 13L                                         ;;  30 deg angle bins
dang           = 36d1/(nang[0] - 1L)
dumb_angs      = DINDGEN(nang[0])*dang[0]
hist_parms     = [dang[0],0d0,36d1]
;;  Define local base data directory
local_base     = root_data_dir()           ;;  e.g., '/Users/lbwilson/data/'
;;  Define CDF file name formats
fname_format   = 'wi_l3-dustimpact_waves_YYYYMMDD_v???.cdf'
;;  Define SPDF base data directory
spdf_base_dir  = 'https://spdf.gsfc.nasa.gov/pub/data/'
;spdf_base_dir  = 'http://spdf.gsfc.nasa.gov/pub/data/'
;;  Define SPDF path format to data [*** this is current ***]
pathformat     = 'wind'+http_slash[0]+'waves'+http_slash[0]+$
                 'dust_impact_l3'+http_slash[0]+'YYYY'+http_slash[0]+fname_format[0]
;;----------------------------------------------------------------------------------------
;;  Define dummy prompt messages
;;----------------------------------------------------------------------------------------
t_latest       = time_string(tr_dmax[1] - def_toffset[0],PREC=3)  ;;  Assume data lags behind by ~1 year
IF (STRMID(t_latest[0],0L,4L) EQ '2015') THEN yr_last = '2016' ELSE yr_last = STRMID(t_latest[0],0L,4L)
yr_se          = [STRMID(tdate0[0],0L,4L),yr_last[0]]
;;  Define dummy prompt messages
prompt_yy      = "Please enter a year between "+yr_se[0]+" and "+yr_se[1]+" [numeric]:  "
prompt_mm      = "Please enter a month between 1 and 12 [numeric]:  "
prompt_dd      = "Please enter a day between 1 and 31 [numeric]:  "     ;;  this will change below
;;----------------------------------------------------------------------------------------
;;  Stuff for TPLOT
;;----------------------------------------------------------------------------------------
sc             = 'Wind'
scpref         = sc[0]+'_'
def_tppref     = scpref[0]+'tds_dust_'
all_types      = ['A','B','C','D','M']
val_sm_labs    = ['vals','smth']
loc_labs       = ['Clear','Magnetosph','Moon','Both']
typ_labs       = 'Type '+all_types
pos_neg_s      = ['+','-']
pos_neg_w      = ['pos','neg']
vec_str        = ['x','y','z']
ef_names       = 'E'+vec_str
channels       = 'Ch'+['1','2']
;;  LABFLAG settings:  defines lable positions
;;    2  :  locations at vertical location of last component data point shown
;;    1  :  equally spaced with zeroth component at bottom
;;    0  :  no labels shown
;;   -1  :  equally spaced with zeroth component at top
def_labflag    = -1
def__ystyle    = 1
def_pansize    = 2.0
def__xminor    = 5
def_xtcklen    = 0.04
def_ytcklen    = 0.01
;;  TPLOT names containing numeric data
good_suffx     = ['TDS_Event_'+['Number','Duration'],'Wind_Spin_'+['Rate','Period'],   $
                  'FLAG_'+['Location','XAnt_Cut'],                                     $
                  'Ch01___'+['Peak_amplitude','cc_'+['value','threshold']],            $
                  'MinCh1_threshold','Ch1ImpAnt_E_S_Angle',                            $
                  'Ch02___'+['Peak_amplitude','cc_'+['value','threshold']],            $
                  'MinCh2_threshold','Ch2ImpAnt_E_S_Angle',                            $
                  'Pos_A'+['x_SCS_Angle',['x','y']+'_E_S_Angle','x_E_S_Delta_Angle'],  $
                  'ImpAnt_E_S_Delta_Angle','n_TDS_per_day']
;;  TPLOT names containing strings
bad_suffx      = ['ImpactAntenna','MorphologicalType']
;;  Define min/max spin period [s] and rate [degrees/s]
mnmx_spperi    = [1d0,5d0]                     ;;  min/max spin period [s]
mnmx_sprate    = 36d1/REVERSE(mnmx_spperi)     ;;  min/max spin rate [deg/s]
;;  Define TPLOT YTITLEs
evn_yttl       = 'TDS Event #'
dur_yttl       = 'TDS Duration'+'!C'+'[sec]'
wsr_yttl       = sc[0]+' Spin Rate'+'!C'+'[degrees/sec]'
wsp_yttl       = sc[0]+' Spin Period'+'!C'+'[sec]'
wlf_yttl       = sc[0]+' Location'+'!C'+'Flag'
wac_yttl       = sc[0]+' Ant. Cut'+'!C'+'Flag'
xpk_yttl       = ef_names[0]+' Peak Amp.'+'!C'+'[mV]'
xcv_yttl       = ef_names[0]+' CC Val.'+'!C'+'[unitless]'
xct_yttl       = ef_names[0]+' CC Thresh.'+'!C'+'[unitless]'
xmt_yttl       = ef_names[0]+' Min. Thresh.'+'!C'+'[mV]'
xia_yttl       = ef_names[0]+' Imp. Ant.'+'!C'+'Angle [E-S line vs '+ef_names[0]+', CW, degrees]'
ypk_yttl       = ef_names[1]+' Peak Amp.'+'!C'+'[mV]'
ycv_yttl       = ef_names[1]+' CC Val.'+'!C'+'[unitless]'
yct_yttl       = ef_names[1]+' CC Thresh.'+'!C'+'[unitless]'
ymt_yttl       = ef_names[1]+' Min. Thresh.'+'!C'+'[mV]'
yia_yttl       = ef_names[1]+' Imp. Ant.'+'!C'+'Angle [E-S line vs '+ef_names[1]+', CW, degrees]'
axs_yttl       = '+Ax Angle'+'!C'+'[SC-Sun line vs +Ax, CW, degrees]'
axe_yttl       = '+Ax Angle'+'!C'+'[E-S line vs +Ax, CW, degrees]'
aye_yttl       = '+Ay Angle'+'!C'+'[E-S line vs +Ay, CW, degrees]'
axd_yttl       = 'd(+Ax Angle)'+'!C'+'[Uncert., degrees]'
iad_yttl       = 'd(Imp. Ant.)'+'!C'+'[Uncert., degrees]'
ntd_yttl       = '# TDS'+'!C'+'Per Day'
all_yttls      = [evn_yttl[0],dur_yttl[0],wsr_yttl[0],wsp_yttl[0],wlf_yttl[0],wac_yttl[0],$
                  xpk_yttl[0],xcv_yttl[0],xct_yttl[0],xia_yttl[0],xmt_yttl[0],            $
                  ypk_yttl[0],ycv_yttl[0],yct_yttl[0],yia_yttl[0],ymt_yttl[0],            $
                  axs_yttl[0],axe_yttl[0],aye_yttl[0],axd_yttl[0],iad_yttl[0],            $
                  ntd_yttl[0]]
;;  Initialize external/remote directory locations
;;    -->  Initialize Wind structure
wind_init
;;----------------------------------------------------------------------------------------
;;  Check keywords
;;----------------------------------------------------------------------------------------
;;  Check TRANGE
tra_struc      = spd_get_valid_trange(TRANGE=trange,PRECISION=3,MIN_TDATE=tdate0[0])
tran           = tra_struc.UNIX_TRANGE            ;;  Unix time range
tdates         = tra_struc.DATE_TRANGE            ;;  Date range [e.g., 'YYYY-MM-DD']
tra_t          = tra_struc.STRING_TRANGE          ;;  String time range [e.g., 'YYYY-MM-DD/hh:mm:ss.xxx']
;;  Check DOWNLOADONLY
test           = (N_ELEMENTS(downloadonly) GT 0) AND KEYWORD_SET(downloadonly)
IF (test[0]) THEN no_load_tplot = 1b ELSE no_load_tplot = 0b
;;  Check VARFORMAT
test           = (N_ELEMENTS(varformat) EQ 0) OR (SIZE(varformat,/TYPE) NE 7)
IF (test[0]) THEN varformat = '*' ELSE varformat = varformat[0]
;;  Check DATATYPE
test           = (N_ELEMENTS(datatype) GT 0)
IF (test[0]) THEN dumb = TEMPORARY(datatype)      ;;  Undefine variable in case user defined it
;;  Check SOURCE_OPTIONS
test           = (N_ELEMENTS(source) EQ 0) OR (SIZE(source,/TYPE) NE 8)
IF (test[0]) THEN BEGIN
  ;;  Make sure SOURCE structure is defined
  source         = !wind
  source.REMOTE_DATA_DIR = spdf_base_dir[0]
ENDIF
;;  Check PREFIX
test           = (N_ELEMENTS(prefix) EQ 0) OR (SIZE(prefix,/TYPE) NE 7)
IF (test[0]) THEN prefix = def_tppref[0] ELSE prefix = prefix[0]
;;  Check SUFFIX
test           = (N_ELEMENTS(suffix) EQ 0) OR (SIZE(suffix,/TYPE) NE 7)
IF (test[0]) THEN suffix = '' ELSE suffix = suffix[0]
;;  Check LOAD_LABELS
test           = (N_ELEMENTS(load_labels) GT 0) AND KEYWORD_SET(load_labels)
IF (test[0]) THEN load_cdf_labs = 1b ELSE load_cdf_labs = 0b
;;----------------------------------------------------------------------------------------
;;  Find files and download
;;----------------------------------------------------------------------------------------
;;  Define relative file paths/HTMLs
;;    base path/url contained within REMOTE_DATA_DIR tag of SOURCE structure
relpathnames   = file_dailynames(FILE_FORMAT=pathformat,TRANGE=tran,ADDMASTER=addmaster)
;;  Get files
test_v64       = (vernf[0] GE 6.4)       ;;  Check IDL version number
IF (test_v64[0]) THEN BEGIN
  ;;  User has ≥ v6.4
  ;;    --> Use IDLnetURL object to retrieve data files
  files          = spd_download(REMOTE_FILE=relpathnames,_EXTRA=source,/LAST_VERSION)
ENDIF ELSE BEGIN
  ;;  User has < v6.4
  ;;    --> Use SOCKET.PRO to retrieve data files
  files          = file_retrieve(relpathnames,_EXTRA=source,/LAST_VERSION)
ENDELSE
;;  Check if user wants only to get the data files
IF (no_load_tplot[0]) THEN RETURN
;;----------------------------------------------------------------------------------------
;;  Open window
;;----------------------------------------------------------------------------------------
;;  Set TPLOT time span
timespan,tran[0],(tran[1] - tran[0]),/SECONDS
;;----------------------------------------------------------------------------------------
;;  Load all CDF data into TPLOT
;;----------------------------------------------------------------------------------------
;prefix         = scpref[0]
n_cdf          = N_ELEMENTS(files)
cdf2tplot,files,PREFIX=prefix,MIDFIX=midfix,MIDPOS=midpos,SUFFIX=suffix,           $
                NEWNAME=newname,VARFORMAT=varformat,VARNAMES=varnames2,ALL=all,    $
                VERBOSE=verbose,/GET_SUPPORT_DATA,/CONVERT_INT1_TO_INT2,           $
                RECORD=record,TPLOTNAMES=tplotnames,LOAD_LABELS=load_cdf_labs[0]
;;  Define TPLOT names containing numeric and string data
tpn_dat_tpns   = tnames('*_'+good_suffx)
tpn_str_tpns   = tnames('*_'+bad_suffx)
;;  Define TPLOTNAMES output
tplotnames     = tpn_dat_tpns
;;----------------------------------------------------------------------------------------
;;  Alter default TPLOT options for loaded variables
;;----------------------------------------------------------------------------------------
;;  Change options for good outputs
options,tpn_dat_tpns,'YTITLE'
options,tpn_dat_tpns,'YSUBTITLE'
options,tpn_dat_tpns,'YSUBTITLE',/DEF
options,tpn_dat_tpns,'PSYM'
options,tpn_dat_tpns,PSYM=2,COLORS=50,/DEF
options,tnames('*_Wind_Spin_Rate'+suffix[0]),  'MAX_VALUE'
options,tnames('*_Wind_Spin_Rate'+suffix[0]),  'MIN_VALUE'
options,tnames('*_Wind_Spin_Period'+suffix[0]),'MAX_VALUE'
options,tnames('*_Wind_Spin_Period'+suffix[0]),'MIN_VALUE'
options,tnames('*_Wind_Spin_Period'+suffix[0]),MIN_VALUE=mnmx_spperi[0],MAX_VALUE=mnmx_spperi[1],/DEF
options,tnames('*_Wind_Spin_Rate'+suffix[0]),  MIN_VALUE=mnmx_sprate[0],MAX_VALUE=mnmx_sprate[1],/DEF
;;  Set TPLOT YTITLEs
n_tpn          = N_ELEMENTS(all_yttls)
FOR j=0L, n_tpn[0] - 1L DO options,tpn_dat_tpns[j],YTITLE=all_yttls[j],/DEF
;;  Define TPLOT defaults
tplot_options,  'YMARGIN',[4,4]
tplot_options,  'XMARGIN',[20,20]
tplot_options,  'LABFLAG',def_labflag[0]
nnw            = tnames()
options,nnw,YSTYLE=def__ystyle[0],PANEL_SIZE=def_pansize[0],XMINOR=def__xminor[0],$
            XTICKLEN=def_xtcklen[0],YTICKLEN=def_ytcklen[0],LABFLAG=def_labflag[0],/DEF
;;  Remove any remnant options
nna            = [tpn_dat_tpns,tpn_str_tpns]
options,nna,       'YLOG'
options,nna,'X_NO_INTERP'
options,nna,'X_NO_INTERP'
options,nna,  'NO_INTERP'
;;----------------------------------------------------------------------------------------
;;  Need to fix dependencies of *_n_TDS_per_day
;;----------------------------------------------------------------------------------------
good           = WHERE(files NE '',gd)
IF (gd[0] GT 0) THEN BEGIN
  gfiles   = files[good]
  gbases   = FILE_BASENAME(gfiles)
  ;;  Get dates from file names
  fdates   = STREGEX(gbases,'([0-9]){8}',/EXTRACT)
  ;;  Define times associated with these dates
  g_tdates = STRMID(fdates,0L,4L)+'-'+STRMID(fdates,4L,2L)+'-'+STRMID(fdates,6L,2L)
  g_ymdbs  = g_tdates+'/'+start_of_day[0]
  g_unix   = time_double(g_ymdbs)
  g_tpn    = tnames('*n_TDS_per_day'+suffix[0])
  IF (g_tpn[0] NE '') THEN BEGIN
    ;;  Get TPLOT variable
    get_data,g_tpn[0],DATA=temp,DLIMIT=dlim,LIMIT=lim
    test     = (SIZE(temp,/TYPE) EQ 8)
    IF (test[0]) THEN BEGIN
      ;;  Redefine time tags
      temp.X   = g_unix
      store_data,g_tpn[0],DATA=temp,DLIMIT=dlim,LIMIT=lim
    ENDIF
  ENDIF
ENDIF
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN
END