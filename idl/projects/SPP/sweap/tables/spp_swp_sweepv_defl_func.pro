;+
;
;
;
; SPP_SWP_SWEEPV_DEFL_FUNC
;
; $LastChangedBy: rlivi2 $
; $LastChangedDate: 2019-09-30 22:44:10 -0700 (Mon, 30 Sep 2019) $
; $LastChangedRevision: 27806 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/tables/spp_swp_sweepv_defl_func.pro $
;
;-

FUNCTION spp_swp_sweepv_defl_func, defl_angle

   ;; SPAN-Ion 5th Degree Polynomial Values
   pi = [ -6.6967358589, 1118.9683837891, 0.5826185942, -0.0928234607, 0.0000374681, 0.0000016514]

   ;; SPAN-Electron 5th Degree Polynomial Values (WRONG)
   pe = [ -6.6967358589, 1118.9683837891, 0.5826185942, -0.0928234607, 0.0000374681, 0.0000016514]

   ;; Switch to defaults
   p = pi
   xparam = defl_angle

   ;; Generate DACS
   defl_dac = p[0]+p[1]*xparam+p[2]*xparam^2+p[3]*xparam^3+p[4]*xparam^4+p[5]*xparam^5

   ;; Return values
   return, defl_dac

END
