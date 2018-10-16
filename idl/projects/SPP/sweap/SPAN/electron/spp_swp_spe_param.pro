; $LastChangedBy: davin-mac $
; $LastChangedDate: 2018-10-15 09:32:49 -0700 (Mon, 15 Oct 2018) $
; $LastChangedRevision: 25976 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/electron/spp_swp_spe_param.pro $
;


;;------------------------------------------------------
;; SIMULATION OF THE OPTICS
;; 

FUNCTION spp_swp_spe_param_esa


  ;;------------------------------------------------------
  ;; ESA Dimensions 
  ;; Toroidal Section
  r1 = 3.34                              ;; Inner Hemisphere Radius
  ;; Toroidal Section
  r2 = r1*1.06                           ;; Outer Hemisphere Radius
  r3 = r1*1.639                          ;; Inner Hemisphere
  r4 = r3*1.06                           ;; Top Cap Radius
  rd = 3.863                             ;; Deflector Radius
  o1 = [0.000,-2.080]                    ;; Origin of Top Cap/Spherical
  o2 = [0.480, 0,000]                    ;; Origin of Toroidal Section
  o3 = [2.500,-0.575]                    ;; Origin of Lower Deflector
  o4 = [2.500, 7.588]                    ;; Origin of Upper Deflector
  deg     = findgen(9000.)/100.
  d2      =  2.5                         ;; Distance of def. from
  ;; rotation axis
  dr      =  3.863                       ;; Deflector Radius 38.63mm
  dist    =  0.56                        ;; Distance between deflectors
  ;; (58.7-53.1)
  drp     = dr+dist/2.                   ;; Radius of particle path
  ;; with deflection
  top_def = [[dr*cos(!DTOR*deg)],$       ;; x
    [dr*sin(!DTOR*deg)]]        ;; y
  top_def_path = [[drp*cos(!DTOR*deg)],$ ;; x
    [drp*sin(!DTOR*deg)]]  ;; y
  deg = -1.*deg
  bot_def = [[dr*cos(!DTOR*deg)],$       ;; x
    [dr*sin(!DTOR*deg)]]        ;; y
  bot_def_path = [[drp*cos(!DTOR*deg)],$ ;; x
    [drp*sin(!DTOR*deg)]]  ;; y
  deg = -1.*deg

  yaw_vals = fltarr((90-6)*10)
  lin_vals = fltarr((90-6)*10)
  ii=0.
  FOR yaw=  0.,  70.,  5 DO BEGIN

    ;; Crude Approximation of Tangent Point
    pp  =  where(ABS(reverse(deg) - yaw) EQ $
      min(ABS(reverse(deg) - yaw)), cc)
    IF cc EQ 0 THEN stop
    ;; Adjust yaw and linear parameters
    ;; to match tangent line
    theta =  (yaw)*!DTOR
    ;; Top Deflector
    xx =  (top_def[*, 0]+d2)
    yy =  (top_def[*, 1]-dr-dist/2.)
    xx11 =  xx*cos(theta)-yy*sin(theta)
    yy11 =  xx*sin(theta)+yy*cos(theta)
    ;; Top Deflector Path
    xx =  top_def_path[*, 0]+d2
    yy =  top_def_path[*, 1]-dr-dist/2.
    xx22 =  xx*cos(theta)-yy*sin(theta)
    yy22 =  xx*sin(theta)+yy*cos(theta)
    ;; Linear Shift
    lin =  yy22[pp[0]]
    plot,   xx11,  yy11-lin, $
      xrange=[-10, 10], $
      yrange=[-10, 10], $
      ystyle=1, $
      /iso
    oplot,  xx22,  yy22-lin, $
      color=250
    ;; Beam
    beam =  [[findgen(1000)-500], [replicate(0., 1000)]]
    oplot,  beam[*, 0],  beam[*, 1]
    ;; Bottom Deflector
    xx =  bot_def[*, 0]+d2
    yy =  bot_def[*, 1]+dr+dist/2.
    xx1 =  xx*cos(theta)-yy*sin(theta)
    yy1 =  xx*sin(theta)+yy*cos(theta)
    oplot,  xx1,  yy1-lin
    xx =  bot_def_path[*, 0]+d2
    yy =  bot_def_path[*, 1]+dr+dist/2.
    xx1 =  xx*cos(theta)-yy*sin(theta)
    yy1 =  xx*sin(theta)+yy*cos(theta)
    oplot,  xx1,  yy1-lin
    ;; Plot temporary location of tangent
    oplot,  top_def_path[pp, 0]+d2,  $
      top_def_path[pp, 1]-dr-dist/2.,  psym=1
    ;; Information
    xyouts,  -8, -8, $
      'yaw=' + strtrim(string(yaw),2)+'   '+$
      'lin=' + strtrim(string(lin),2)
    wait, 0.025
    yaw_vals[ii] = yaw
    lin_vals[ii] = lin
    ii=ii+1
    IF yaw EQ 65 THEN stop
    IF yaw EQ 70 THEN stop

  ENDFOR

END




PRO spp_swp_spe_param_esa, esa

  ;;------------------------------------------------------
  ;; ESA Dimensions
  r1 = 3.34                      ;; Inner Hemisphere Radius
  r2 = r1*1.06                   ;; Outer Hemisphere Radius
  r3 = r1*1.639                  ;; Inner Hemisphere Spherical Radius
  r4 = r3*1.06                   ;; Top Cap Radius
  rd = 3.863                     ;; Deflector Radius
  o1 = [0.000,-2.080]            ;; Origin of Top Cap/Spherical Section
  o2 = [0.480, 0,000]            ;; Origin of Toroidal Section
  o3 = [2.500,-0.575]            ;; Origin of Lower Deflector
  o4 = [2.500, 7.588]            ;; Origin of Upper Deflector

  deg     = findgen(9000.)/100.
  d2      =  2.5                 ;; Distance of def. from rotation axis
  dr      =  3.863               ;; Deflector Radius 38.63mm
  dist    =  0.56                ;; Distance between deflectors (58.7-53.1)
  drp     = dr+dist/2.           ;; Radius of particle path with deflection

  top_def = [[dr*cos(!DTOR*deg)],$       ;x
    [dr*sin(!DTOR*deg)]]        ;y
  top_def_path = [[drp*cos(!DTOR*deg)],$ ;x
    [drp*sin(!DTOR*deg)]]  ;y
  deg = -1.*deg
  bot_def = [[dr*cos(!DTOR*deg)],$       ;x
    [dr*sin(!DTOR*deg)]]        ;y
  bot_def_path = [[drp*cos(!DTOR*deg)],$ ;x
    [drp*sin(!DTOR*deg)]]  ;y
  deg = -1.*deg

  esa = {r1:r1,r2:r2,r3:r3,r4:r4,$
    o1:o1,o2:o2,o3:o3,o4:o4}

END

;;------------------------------------------------------
;; PARAMS IN A DICTIONARY
;;

PRO spp_swp_spe_param_dict, vals, dict

  ;; Define Dictionary
  spe_dict = dictionary()

  ;; Find all tags
  tags = tag_names(vals)

  ;; Fill all tags into dictionary
  FOR i=0, n_elements(tags)-1 DO BEGIN
    print, "spe_dict['"+tags[i]+"'] = vals."+tags[i]
    tmp = execute("spe_dict['"+tags[i]+"'] = vals."+tags[i])
  ENDFOR

END


;; ************************************************************
;; *************************** MAIN ***************************
;; ************************************************************

function spp_swp_spe_param,reset=reset

  ;;------------------------------------------------------
  ;; COMMON BLOCK
  common spp_swp_spe_param_com, spe_param_dict

  if keyword_set(reset) then begin
    obj_destroy,spe_param_dict
    spe_param_dict = !null
  endif
  
  if isa(spe_param_dict,'dictionary') eq 0 then begin
    etables = orderedhash()
    spe_param_dict = dictionary()

    spane=1
    ratios = [1.,.3,.1,.1,.001]
    
;    etables[1] = spp_swp_spanx_sweep_tables([20.,20000.],spfac=ratios[0]   , emode=1, spane=spane)
;    etables[2] = spp_swp_spanx_sweep_tables([10.,10000.],spfac=ratios[0]   , emode=2, spane=spane)
;    etables[3] = spp_swp_spanx_sweep_tables([ 5., 5000.],spfac=ratios[0]   , emode=3, spane=spane)
;    etables[4] = spp_swp_spanx_sweep_tables([ 5.,  500.],spfac=ratios[0]   , emode=4, spane=spane)

;    etables[5] = spp_swp_spanx_sweep_tables([20.,20000.],spfac=ratios[1]   , emode=5, spane=spane)
;    etables[6] = spp_swp_spanx_sweep_tables([10.,10000.],spfac=ratios[1]   , emode=6, spane=spane)
;    etables[7] = spp_swp_spanx_sweep_tables([ 5., 5000.],spfac=ratios[1]   , emode=7, spane=spane)
;    etables[8] = spp_swp_spanx_sweep_tables([ 5.,  500.],spfac=ratios[1]   , emode=8, spane=spane)
;
;    etables[9] = spp_swp_spanx_sweep_tables([20.,20000.],spfac=ratios[2]   , emode=9, spane=spane)
;    etables[10] = spp_swp_spanx_sweep_tables([10.,10000.],spfac=ratios[2]   , emode=10, spane=spane)
;    etables[11] = spp_swp_spanx_sweep_tables([ 5., 5000.],spfac=ratios[2]   , emode=11, spane=spane)
;    etables[12] = spp_swp_spanx_sweep_tables([ 5.,  500.],spfac=ratios[2]   , emode=12, spane=spane)
;
;    etables[13] = spp_swp_spanx_sweep_tables([20.,20000.],spfac=ratios[3]   , emode=13, spane=spane)
;    etables[14] = spp_swp_spanx_sweep_tables([10.,10000.],spfac=ratios[3]   , emode=14, spane=spane)
;    etables[15] = spp_swp_spanx_sweep_tables([ 5., 5000.],spfac=ratios[3]   , emode=15, spane=spane)
;    etables[16] = spp_swp_spanx_sweep_tables([ 5.,  500.],spfac=ratios[3]   , emode=16, spane=spane)
;
;    etables[17] = spp_swp_spanx_sweep_tables([20.,20000.],spfac=ratios[4]   , emode=17, spane=spane)
;    etables[18] = spp_swp_spanx_sweep_tables([10.,10000.],spfac=ratios[4]   , emode=18, spane=spane)
;    etables[19] = spp_swp_spanx_sweep_tables([ 5., 5000.],spfac=ratios[4]   , emode=19, spane=spane)
;    etables[20] = spp_swp_spanx_sweep_tables([ 5.,  500.],spfac=ratios[4]   , emode=20, spane=spane)

    etables[21] = spp_swp_spanx_sweep_tables([ 2., 2000.],spfac=ratios[3]   , emode=21, spane=spane)

    spe_param_dict.etables = etables
    
  endif
  
  return,spe_param_dict
     
END

