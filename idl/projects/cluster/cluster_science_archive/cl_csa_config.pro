;+
;NAME:    cl_csa_config
;
;PURPOSE:
;  This procedure serves as the Cluster configuration file.  It sets global (system)
;  variables and initializes devices
;
;  This procedure will define the location of data files and the data server.
;  This procedure is intended to be called from within the "CL_INIT" procedure.
;
;  This should be the only Cluster file that requires modification for use in different
;  locations.
;
;  There is no need to modify this file if:
;     - Your computer is an SSL UNIX machine that mounts "/disks/data/"   (i.e. ALL Linux and Solaris machines at SSL)
;     - You use a portable computer that will be caching files on a local hard drive.
;
;
;  Settings  in this file will be overridden by settings in the environment.
;  (see setup_themis or setup_themis_bash for examples of setting environment
;  variables on UNIX-like systems.  The environment can also be set on Windows
;  systems.)
;
;KEYWORDS
;   NO_COLOR_SETUP   Do not do color setup if taken care for already
;   COLORTABLE       Overwrite the default colortable initialization
;     
;HISTORY:
; 2019-12-23, egrimes, created based on mms_init
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2021-07-08 16:21:36 -0700 (Thu, 08 Jul 2021) $
; $LastChangedRevision: 30111 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/cluster/cluster_science_archive/cl_csa_config.pro $
;
;-
PRO cl_csa_config, no_color_setup=no_color_setup, colortable=colortable

  ;--------------------
  ; LOCAL_DATA_DIR
  ;--------------------
  !cluster_csa.local_data_dir = spd_default_local_data_dir() + 'cluster_csa/'
  
  ;--------------------
  ; REMOTE_DATA_DIR
  ;--------------------
  ;Pick your favorite Cluster data server:  (Comment out the others)
  ;
  ; Ignored for now....this is built cl_load_csa sets the URL internally
  !cluster_csa.remote_data_dir = 'https://spdf.gsfc.nasa.gov/pub/data/cluster/'

  ;--------------------
  ; Local Config File
  ;--------------------
  cfg = cl_csa_config_read(); read config file

  if (size(cfg,/type) eq 8)then begin; if config file exists, update !cluster_csa from the file
    !cluster_csa.LOCAL_DATA_DIR = cfg.local_data_dir
    if tag_exist(cfg, 'mirror_data_dir') then  !cluster_csa.MIRROR_DATA_DIR = cfg.mirror_data_dir
  endif else begin; if cfg not found,
    dir = cl_csa_config_filedir(); create config directory
    !cluster_csa.LOCAL_DATA_DIR = spd_default_local_data_dir() + 'cluster_csa/'
    pref = {LOCAL_DATA_DIR: !cluster_csa.LOCAL_DATA_DIR}
    cl_csa_config_write, pref
  endelse

  ; Settings of environment variables can override mms_config
  if getenv('CLUSTER_CSA_REMOTE_DATA_DIR') ne '' then $
    !cluster_csa.remote_data_dir = getenv('CLUSTER_CSA_REMOTE_DATA_DIR')
  !cluster_csa.remote_data_dir = spd_addslash(!cluster_csa.remote_data_dir)
  
  if getenv('ROOT_DATA_DIR') ne '' then $
    !cluster_csa.LOCAL_DATA_DIR = spd_addslash(getenv('ROOT_DATA_DIR'))+'cluster_csa/'

  if getenv('SPEDAS_DATA_DIR') ne '' then $
    !cluster_csa.LOCAL_DATA_DIR = spd_addslash(getenv('SPEDAS_DATA_DIR'))+'cluster_csa/'
   
  if getenv('CLUSTER_CSA_DATA_DIR') ne '' then $
    !cluster_csa.local_data_dir = getenv('CLUSTER__CSA_DATA_DIR')
  !cluster_csa.local_data_dir = spd_addslash(!cluster_csa.local_data_dir)
  
  if getenv('MIRROR_DATA_DIR') ne '' then begin
    !cluster_csa.mirror_data_dir = getenv('MIRROR_DATA_DIR')
    !cluster_csa.mirror_data_dir = spd_addslash(!cluster_csa.mirror_data_dir)
  endif

  ;------------------------
  ; Global Sytem Variables
  ;------------------------
  ; Please note: These settings will affect all IDL routines, NOT JUST MMS routines!

  ;========= COLOR SETUP
  ;
  ; Do not do color setup if taken care for already
  if not keyword_set(no_color_setup) then begin
    spd_graphics_config,colortable=colortable
  endif ; no_color_setup
  
  ;===========  DEBUGGING OPTIONS
  
  ; The following calls set persistent flags in dprint that change subsequent output
  ;dprint,setdebug=3       ; set default debug level to value of 3
  ;dprint,/print_dlevel    ; uncomment to display dlevel/verbose at each dprint statement
  ;dprint,/print_dtime     ; uncomment to display time interval between dprint statements.
  dprint,print_trace=1    ; uncomment to display current procedure and line number on each line. (recommended)
  ;dprint,print_trace=3    ; uncomment to display entire program stack on each line.

  ;  !quiet=1            ; if !quiet ==1 then  error messages are suppressed

  ;============= USEFUL TPLOT OPTIONS
  ;
  ; Most standard plotting keywords can be included in the global tplot_options routine
  ; or individually in each tplot variable using the procedure: "options"
  ; for example:
  ; tplot_options,'title','Themis Event #1'
  ; tplot_options,'charsize',1.2   ; set default character size.

  ; Some other useful options:
  tplot_options,window=0            ; Forces tplot to use only window 0 for all time plots
  tplot_options,'wshow',1           ; Raises tplot window when tplot is called
  ;If(!mms.verbose Eq 0) Then tplot_options, 'verbose', 0 $ ;turn off default to verbose if !mms.verbose is zero, jmm, 30-sep-2009
  ;Else tplot_options,'verbose',1         ; Displays some extra messages in tplot (e.g. When variables get created/altered)
  ;tplot_options,'psym_lim',100      ; Displays symbols if less than 100 point in panel
  tplot_options,'ygap',.5           ; Set gap distance between tplot panels.
  tplot_options,'lazy_ytitle',1     ; breaks "_" into carriage returns on ytitles
  tplot_options,'no_interp',1       ; prevents interpolation in spectrograms (recommended)

END
