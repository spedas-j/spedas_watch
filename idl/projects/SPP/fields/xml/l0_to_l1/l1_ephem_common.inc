  <cdf_var
      name = "position"
      type = "double"
      nelem = "3">
    <cdf_att
        FIELDNAM = "position"
        FORMAT = "F15.3"
        LABLAXIS = "position"
        DATA_TYPE = "CDF_DOUBLE"
        VAR_TYPE = "data"
        FILLVAL = "-1.0E31"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-2e8"
        VALIDMAX = "2e8"
        SCALEMIN = "-2e8"
        SCALEMAX = "2e8"
        UNITS = "km"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name = "velocity"
      type = "double"
      nelem = "3">
    <cdf_att
        FIELDNAM = "velocity"
        FORMAT = "F15.3"
        LABLAXIS = "velocity"
        DATA_TYPE = "CDF_DOUBLE"
        VAR_TYPE = "data"
        FILLVAL = "-1.0E31"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-2e8"
        VALIDMAX = "2e8"
        SCALEMIN = "-2e8"
        SCALEMAX = "2e8"
        UNITS = "km/s"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name = "sc_x_vector"
      type = "double"
      nelem = "3">
    <cdf_att
        FIELDNAM = "sc_x_vector"
        FORMAT = "F15.3"
        LABLAXIS = "sc_x_vector"
        DATA_TYPE = "CDF_DOUBLE"
        VAR_TYPE = "data"
        FILLVAL = "-1.0E31"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-1"
        VALIDMAX = "1"
        SCALEMIN = "-1"
        SCALEMAX = "1"
        UNITS = "None"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name = "sc_y_vector"
      type = "double"
      nelem = "3">
    <cdf_att
        FIELDNAM = "sc_y_vector"
        FORMAT = "F15.3"
        LABLAXIS = "sc_y_vector"
        DATA_TYPE = "CDF_DOUBLE"
        VAR_TYPE = "data"
        FILLVAL = "-1.0E31"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-1"
        VALIDMAX = "1"
        SCALEMIN = "-1"
        SCALEMAX = "1"
        UNITS = "None"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name = "sc_z_vector"
      type = "double"
      nelem = "3">
    <cdf_att
        FIELDNAM = "sc_z_vector"
        FORMAT = "F15.3"
        LABLAXIS = "z_vector"
        DATA_TYPE = "CDF_DOUBLE"
        VAR_TYPE = "data"
        FILLVAL = "-1.0E31"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-1"
        VALIDMAX = "1"
        SCALEMIN = "-1"
        SCALEMAX = "1"
        UNITS = "None"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name = "c_matrix"
      type = "double"
      nelem = "3"
      nelem2 = "3">
    <cdf_att
        FIELDNAM = "c_matrix"
        FORMAT = "F15.3"
        LABLAXIS = "c_matrix"
        DATA_TYPE = "CDF_DOUBLE"
        VAR_TYPE = "data"
        FILLVAL = "-1.0E31"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-1"
        VALIDMAX = "1"
        SCALEMIN = "-1"
        SCALEMAX = "1"
        UNITS = "None"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>
