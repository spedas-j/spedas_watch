;+
;PROCEDURE:   parabola_vertex
;PURPOSE:
;  Calculates the vertex of the parabola defined by three points.
;  The parabola is assumed to be of the form:
;
;    y = A*(x - xv)^2. + yv
;
;  where A is a constant and [xv, yv] are the coordinates of the 
;  vertex.  Works best when the input x values surround the vertex,
;  but works in other cases as well.
;
;  Uses the second-order Lagrange interpolation formula.
;
;USAGE:
;  parabola_vertex, x, y, xv, hv
;
;INPUTS:
;     x : independent variable (3 values)
;     y : dependent variable (3 values)
;
;OUTPUTS:
;     xv : location of the parabola vertex in x
;     yv : value of the dependent variable at the vertex
;
;KEYWORDS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2020-10-13 15:51:23 -0700 (Tue, 13 Oct 2020) $
; $LastChangedRevision: 29249 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/maven_orbit_tplot/parabola_vertex.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro parabola_vertex, xi, yi, xv, yv

  x = double(xi)
  y = double(yi)
  a = dblarr(3)

  xoff = x[1]
  yoff = y[1]
  x -= xoff
  y -= yoff

  a[0] = y[0]/((x[0]-x[1])*(x[0]-x[2]))
  a[1] = y[1]/((x[1]-x[0])*(x[1]-x[2]))
  a[2] = y[2]/((x[2]-x[0])*(x[2]-x[1]))

  xv = (a[0]*(x[1]+x[2]) + a[1]*(x[0]+x[2]) + a[2]*(x[0]+x[1]))/(2.*total(a))
  yv = a[0]*(xv-x[1])*(xv-x[2]) + a[1]*(xv-x[0])*(xv-x[2]) + a[2]*(xv-x[0])*(xv-x[1])

  xv += xoff
  yv += yoff
  
  return

end
