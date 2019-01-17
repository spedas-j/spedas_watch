;+
; MMS orbit crib sheet
;
;
;
;
; do you have suggestions for this crib sheet?
;   please send them to egrimes@igpp.ucla.edu
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2019-01-16 07:56:17 -0800 (Wed, 16 Jan 2019) $
; $LastChangedRevision: 26469 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_orbit_crib.pro $
;-

; create a simple orbit plot with all 4 spacecraft on 15Dec2015
mms_orbit_plot, probe=[1, 2, 3, 4], trange=['2015-12-15', '2015-12-16']
stop

; you can specify the plane to view using the 'plane' keyword
mms_orbit_plot, plane='yz', probe=[1, 2, 3, 4], trange=['2015-12-15', '2015-12-16'];, yrange=[-20, 20], xrange=[-20, 20]
stop

; you can specify the coordinate system using the 'coord' keyword
mms_orbit_plot, coord='sm', probe=[1, 2, 3, 4], trange=['2015-12-15', '2015-12-16'];, yrange=[-20, 20], xrange=[-20, 20]
stop

end
