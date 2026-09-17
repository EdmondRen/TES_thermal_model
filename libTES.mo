package libTES
  model TES
    // Electrical port
    Modelica.Electrical.Analog.Interfaces.PositivePin p annotation(
      Placement(transformation(origin = {0, 40}, extent = {{-110, -10}, {-90, 10}}), iconTransformation(origin = {0, 60}, extent = {{-110, -10}, {-90, 10}})));
    Modelica.Electrical.Analog.Interfaces.NegativePin n annotation(
      Placement(transformation(origin = {-200, -40}, extent = {{90, -10}, {110, 10}}), iconTransformation(origin = {-200, -60}, extent = {{90, -10}, {110, 10}})));
    // Heat port
    Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a heatPort annotation(
      Placement(transformation(origin = {-20, 100}, extent = {{-10, -110}, {10, -90}}), iconTransformation(origin = {100, 100}, extent = {{-10, -110}, {10, -90}})));
    //                         (electrical)
    //                    p -----[ TES R] ----- n
    //                              |
    //                           Joule heat
    //                              ↓
    //           heatPort --- [ thermal C, T ]
    parameter Modelica.Units.SI.Resistance Rn;
    parameter Modelica.Units.SI.Temperature Tc;
    parameter Real alpha0;
    parameter Modelica.Units.SI.HeatCapacity C "TES heat capacity";
    Modelica.Units.SI.Voltage v;
    Modelica.Units.SI.Current i;
    Modelica.Units.SI.Resistance R;
    Modelica.Units.SI.Power P_Joule;
    Modelica.Units.SI.Temperature T(start = 0.05, fixed = false);
  equation
// Electrical equations
    v = p.v - n.v;
    p.i = i;
    n.i = -i;
// TES Resistance. Joule heating generated internally
    R = Rn/2*(1. + tanh((T - Tc)*alpha0/Tc));
    v = R*i;
    P_Joule = v*i;
// Thermal energy balance
    heatPort.T = T;
    C*der(T) = P_Joule + heatPort.Q_flow;
    annotation(
      Diagram(graphics = {Rectangle(origin = {-60, 0}, extent = {{-40, 40}, {40, -40}})}),
      Icon(graphics = {Text(origin = {7, 3}, extent = {{-29, 17}, {29, -17}}, textString = "Rn=%Rn
  Tc=%Tc
  alpha0=%alpha0
  C=%C", horizontalAlignment = TextAlignment.Left), Rectangle(extent = {{-100, 100}, {100, -100}}), Line(origin = {-76, 10}, points = {{-24, 50}, {16, 50}, {16, 30}, {24, 30}, {24, -50}, {8, -50}, {8, 30}, {16, 30}, {16, 30}}), Line(origin = {-75, -50}, points = {{15, 10}, {15, -10}, {-15, -10}, {-15, -10}}), Line(origin = {-57.0045, 2.71811}, points = {{-20.9955, -26.7181}, {15.0045, 23.2819}, {9.00454, 27.2819}, {21.0045, 19.2819}, {21.0045, 19.2819}}), Text(origin = {-2, 123}, extent = {{-50, 27}, {50, -27}}, textString = "%name")}));
  end TES;

  model TES2
    // Electrical port
    Modelica.Electrical.Analog.Interfaces.PositivePin p annotation(
      Placement(transformation(origin = {0, 40}, extent = {{-110, -10}, {-90, 10}}), iconTransformation(origin = {0, 60}, extent = {{-110, -10}, {-90, 10}})));
    Modelica.Electrical.Analog.Interfaces.NegativePin n annotation(
      Placement(transformation(origin = {-200, -40}, extent = {{90, -10}, {110, 10}}), iconTransformation(origin = {-200, -60}, extent = {{90, -10}, {110, 10}})));
    // Heat port
    Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a heatPort(T(displayUnit = "mK")) annotation(
      Placement(transformation(origin = {-20, 100}, extent = {{-10, -110}, {10, -90}}), iconTransformation(origin = {100, 100}, extent = {{-10, -110}, {10, -90}})));
    //                         (electrical)
    //                    p -----[ TES R] ----- n
    //                              |
    //                           Joule heat
    //                              ↓
    //           heatPort --- [ thermal C, T ]
    parameter Modelica.Units.SI.Resistance Rn;
    parameter Modelica.Units.SI.Temperature Tc;
    parameter Modelica.Units.SI.Current I0 "Current where beta0 is evaluated";
    parameter Real alpha0;
    parameter Real beta0 = 1;
    // Heat capacity
    parameter Modelica.Units.SI.Mass m(displayUnit = "ug") = 1;
    parameter Real a1 = 0;
    parameter Real a3 = 0;
    Modelica.Units.SI.SpecificHeatCapacity cp;
    Modelica.Units.SI.Voltage v;
    Modelica.Units.SI.Current i;
    Modelica.Units.SI.Resistance R;
    Modelica.Units.SI.Power P_Joule;
    Modelica.Units.SI.Temperature T(start = 0.05, fixed = false, displayUnit = "mK");
    // Variables for results
    Real C;
  equation
// Electrical equations
    v = p.v - n.v;
    p.i = i;
    n.i = -i;
// TES Resistance. Joule heating generated internally
    R = Rn/2*(1. + tanh((T - Tc)*alpha0/Tc) + (i - I0)*beta0/I0);
    v = R*i;
    P_Joule = v*i;
// Heat capacity (temperature dependent)
    cp = a1*T + a3*T^3;
    C = m*cp;
// Thermal energy balance
    heatPort.T = T;
    m*cp*der(T) = P_Joule + heatPort.Q_flow;
    annotation(
      Diagram(graphics = {Rectangle(origin = {-60, 0}, extent = {{-40, 40}, {40, -40}})}),
      Icon(graphics = {Text(origin = {14, 0}, extent = {{-46, 30}, {46, -30}}, textString = "Rn=%Rn
  Tc=%Tc, I0=%I0
  α=%alpha0, β=%beta0
  m=%m
  a1=%a1
  a3=%a3
  ", horizontalAlignment = TextAlignment.Left), Rectangle(extent = {{-100, 100}, {100, -100}}), Line(origin = {-76, 10}, points = {{-24, 50}, {16, 50}, {16, 30}, {24, 30}, {24, -50}, {8, -50}, {8, 30}, {16, 30}, {16, 30}}), Line(origin = {-75, -50}, points = {{15, 10}, {15, -10}, {-15, -10}, {-15, -10}}), Line(origin = {-57.0045, 2.71811}, points = {{-20.9955, -26.7181}, {15.0045, 23.2819}, {9.00454, 27.2819}, {21.0045, 19.2819}, {21.0045, 19.2819}}), Text(origin = {-2, 123}, extent = {{-50, 27}, {50, -27}}, textString = "%name")}));
  end TES2;

  model ThermlConductanceN
    Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a port_a(T(displayUnit = "mK")) annotation(
      Placement(transformation(origin = {0, 40}, extent = {{-110, -10}, {-90, 10}}), iconTransformation(extent = {{-110, -10}, {-90, 10}})));
    Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_b port_b(T(displayUnit = "mK")) annotation(
      Placement(transformation(origin = {200, 40}, extent = {{-110, -10}, {-90, 10}}), iconTransformation(origin = {200, 0}, extent = {{-110, -10}, {-90, 10}})));
    parameter Real K = 1e-8 "Thermal coupling coefficient  such that Q_flow = K*(Ta^n - Tb^n) [W/K^n]";
    parameter Real n = 3 "Thermal transport exponent";
    Modelica.Units.SI.HeatFlowRate Q_flow;
    // Variables for results
    Real G;
  equation
    Q_flow = K*(port_a.T^n - port_b.T^n);
    G = n*K*port_a.T^(n - 1);
    port_a.Q_flow = Q_flow;
    port_b.Q_flow = -Q_flow;
    annotation(
      Icon(graphics = {Rectangle(lineColor = {170, 0, 0}, fillColor = {255, 255, 255}, pattern = LinePattern.None, fillPattern = FillPattern.Forward, extent = {{-68, 20}, {68, -20}}), Line(origin = {-79.5, 0}, points = {{-10.5, 0}, {11.5, 0}, {9.5, 0}}, color = {85, 0, 0}), Line(origin = {78.5, 0}, points = {{-10.5, 0}, {11.5, 0}, {9.5, 0}}, color = {85, 0, 0}), Text(origin = {-2, -46}, extent = {{-36, 18}, {36, -18}}, textString = "K=%K
n=%n"), Text(origin = {0, 39}, textColor = {0, 0, 127}, extent = {{-44, 20}, {44, -20}}, textString = "%name", textStyle = {TextStyle.Bold})}, coordinateSystem(extent = {{-100, -100}, {100, 100}})),
      Diagram(coordinateSystem(extent = {{-100, -100}, {100, 100}})));
  end ThermlConductanceN;

  model HeatCapacitorPoly
    import Modelica.Units.SI;
    parameter SI.Mass m(displayUnit = "ug") = 1;
    parameter Real a0 = 0;
    parameter Real a1 = 0;
    parameter Real a3 = 0;
    parameter Real a5 = 0;
    parameter Real T0 = 0;
    SI.Temperature T(start = 0.05, displayUnit = "mK");
    SI.SpecificHeatCapacity cp;
    Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a port annotation(
      Placement(transformation(origin = {-20, 100}, extent = {{-10, -110}, {10, -90}}), iconTransformation(extent = {{-10, -110}, {10, -90}})));
    // Variables for results
    Real C;
  equation
    port.T = T;
    cp = a0 + a1*T + a3*T^3 + a5*T^5;
    C = m*cp;
    C*der(T) = port.Q_flow;
    annotation(
      Diagram(graphics),
      Icon(graphics = {Polygon(lineColor = {160, 160, 164}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid, points = {{0, 67}, {-20, 63}, {-40, 57}, {-52, 43}, {-58, 35}, {-68, 25}, {-72, 13}, {-76, -1}, {-78, -15}, {-76, -31}, {-76, -43}, {-76, -53}, {-70, -65}, {-64, -73}, {-48, -77}, {-30, -83}, {-18, -83}, {-2, -85}, {8, -89}, {22, -89}, {32, -87}, {42, -81}, {54, -75}, {56, -73}, {66, -61}, {68, -53}, {70, -51}, {72, -35}, {76, -21}, {78, -13}, {78, 3}, {74, 15}, {66, 25}, {54, 33}, {44, 41}, {36, 57}, {26, 65}, {0, 67}}), Polygon(fillColor = {160, 160, 164}, fillPattern = FillPattern.Solid, points = {{-58, 35}, {-68, 25}, {-72, 13}, {-76, -1}, {-78, -15}, {-76, -31}, {-76, -43}, {-76, -53}, {-70, -65}, {-64, -73}, {-48, -77}, {-30, -83}, {-18, -83}, {-2, -85}, {8, -89}, {22, -89}, {32, -87}, {42, -81}, {54, -75}, {42, -77}, {40, -77}, {30, -79}, {20, -81}, {18, -81}, {10, -81}, {2, -77}, {-12, -73}, {-22, -73}, {-30, -71}, {-40, -65}, {-50, -55}, {-56, -43}, {-58, -35}, {-58, -25}, {-60, -13}, {-60, -5}, {-60, 7}, {-58, 17}, {-56, 19}, {-52, 27}, {-48, 35}, {-44, 45}, {-40, 57}, {-58, 35}}), Text(origin = {2, -58}, textColor = {0, 0, 255}, extent = {{-150, 110}, {150, 70}}, textString = "%name", textStyle = {TextStyle.Bold}), Text(origin = {-2, -11}, extent = {{-61, 10}, {63, -33}}, textString = "m=%m
  a1=%a1")}));
  end HeatCapacitorPoly;

  block SourceExp
    parameter Real outMax = 1 "Height of output for infinite riseTime" annotation(
      Dialog(groupImage = "modelica://Modelica/Resources/Images/Blocks/Sources/Exponentials.png"));
    parameter Modelica.Units.SI.Time fallTimeConst(min = Modelica.Constants.small) = riseTimeConst "Fall time constant";
    extends Modelica.Blocks.Interfaces.SignalSource;
  equation
    y = offset + (if (time < startTime) then 0 else outMax*Modelica.Math.exp(-(time - startTime)/fallTimeConst));
    annotation(
      Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-90, -70}, {68, -70}}, color = {192, 192, 192}), Polygon(lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid, points = {{90, -70}, {68, -62}, {68, -78}, {90, -70}}), Line(origin = {-4, 0}, points = {{-62, 56}, {-59.88, 39.5}, {-57.05, 24.7}, {-50.22, 11.8}, {-43.394, -1.55}, {-33.86, -13.7}, {-22.32, -26}, {-14.1, -32.2}, {-5.8, -36.6}, {5.1, -44.5}, {16.8, -49.4}, {29.1, -53.3}, {40.9, -58.5}, {50.8, -62.8}, {60, -65.4}}), Polygon(lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid, points = {{-80, 90}, {-88, 68}, {-72, 68}, {-80, 90}}), Line(points = {{-80, 68}, {-80, -80}}, color = {192, 192, 192}), Text(extent = {{-150, -150}, {150, -110}}, textString = "fallTime=%fallTime")}),
      Documentation(info = "<html>
  <p>
  The Real output y is a rising exponential followed
  by a falling exponential signal:
  </p>
  
  <div>
  <img src=\"modelica://Modelica/Resources/Images/Blocks/Sources/Exponentials.png\"
     alt=\"Exponentials.png\">
  </div>
  </html>"));
  end SourceExp;

  model ThermalConductanceWireEPH
    Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a port_a_e(T(displayUnit = "mK")) annotation(
      Placement(transformation(origin = {0, 30}, extent = {{-110, -10}, {-90, 10}}), iconTransformation(origin = {0, 40}, extent = {{-110, -10}, {-90, 10}})));
    Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_b port_b_e(T(displayUnit = "mK")) annotation(
      Placement(transformation(origin = {200, 30}, extent = {{-110, -10}, {-90, 10}}), iconTransformation(origin = {200, 40}, extent = {{-110, -10}, {-90, 10}})));
    Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a port_a_ph(T(displayUnit = "mK")) annotation(
      Placement(transformation(origin = {0, 4}, extent = {{-110, -10}, {-90, 10}}), iconTransformation(origin = {0, -40}, extent = {{-110, -10}, {-90, 10}})));
    Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_b port_b_ph(T(displayUnit = "mK")) annotation(
      Placement(transformation(origin = {200, 4}, extent = {{-110, -10}, {-90, 10}}), iconTransformation(origin = {200, -40}, extent = {{-110, -10}, {-90, 10}})));
    ThermlConductanceN g_e0(K = K_e0, n = n_e0) annotation(
      Placement(transformation(origin = {-76, 30}, extent = {{-10, -10}, {10, 10}})));
    libTES.ThermlConductanceN g_ph0(K = K_ph0, n = n_ph0) annotation(
      Placement(transformation(origin = {-76, 4}, extent = {{-10, -10}, {10, 10}})));
    libTES.ThermlConductanceN g_eph1(K = K_eph0, n = n_eph0) annotation(
      Placement(transformation(origin = {-62, 16}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
    HeatCapacitorPoly c_e1(m = m_e0, a1 = a1_e0) annotation(
      Placement(transformation(origin = {-56, 44}, extent = {{-10, -10}, {10, 10}})));
    libTES.HeatCapacitorPoly c_ph1(m = m_ph0, a3 = a3_ph0) annotation(
      Placement(transformation(origin = {-56, -10}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
    libTES.ThermlConductanceN g_e1(K = K_e0, n = n_e0) annotation(
      Placement(transformation(origin = {-38, 30}, extent = {{-10, -10}, {10, 10}})));
    libTES.ThermlConductanceN g_ph1(K = K_ph0, n = n_ph0) annotation(
      Placement(transformation(origin = {-38, 4}, extent = {{-10, -10}, {10, 10}})));
    libTES.ThermlConductanceN g_eph2(K = K_eph0, n = n_eph0) annotation(
      Placement(transformation(origin = {-24, 16}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
    libTES.HeatCapacitorPoly c_e2(a1 = a1_e0, m = m_e0) annotation(
      Placement(transformation(origin = {-18, 42}, extent = {{-10, -10}, {10, 10}})));
    libTES.HeatCapacitorPoly c_ph2(a1 = a1_ph0, m = m_ph0) annotation(
      Placement(transformation(origin = {-18, -8}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
    libTES.ThermlConductanceN g_e2(K = K_e0, n = n_e0) annotation(
      Placement(transformation(origin = {2, 30}, extent = {{-10, -10}, {10, 10}})));
    libTES.ThermlConductanceN g_ph2(K = K_ph0, n = n_ph0) annotation(
      Placement(transformation(origin = {2, 4}, extent = {{-10, -10}, {10, 10}})));
    libTES.ThermlConductanceN g_eph3(K = K_eph0, n = n_eph0) annotation(
      Placement(transformation(origin = {16, 16}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
    libTES.HeatCapacitorPoly c_e3(a1 = a1_e0, m = m_e0) annotation(
      Placement(transformation(origin = {22, 42}, extent = {{-10, -10}, {10, 10}})));
    libTES.HeatCapacitorPoly c_ph3(a1 = a1_ph0, m = m_ph0) annotation(
      Placement(transformation(origin = {22, -8}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
    libTES.ThermlConductanceN g_e3(K = K_e0, n = n_e0) annotation(
      Placement(transformation(origin = {38, 30}, extent = {{-10, -10}, {10, 10}})));
    libTES.ThermlConductanceN g_ph3(K = K_ph0, n = n_ph0) annotation(
      Placement(transformation(origin = {38, 4}, extent = {{-10, -10}, {10, 10}})));
    libTES.ThermlConductanceN g_eph4(K = K_eph0, n = n_eph0) annotation(
      Placement(transformation(origin = {52, 16}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
    libTES.HeatCapacitorPoly c_e4(a1 = a1_e0, m = m_e0) annotation(
      Placement(transformation(origin = {58, 42}, extent = {{-10, -10}, {10, 10}})));
    libTES.HeatCapacitorPoly c_ph4(a1 = a1_ph0, m = m_ph0) annotation(
      Placement(transformation(origin = {58, -8}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
    libTES.ThermlConductanceN g_e4(K = K_e0, n = n_e0) annotation(
      Placement(transformation(origin = {78, 30}, extent = {{-10, -10}, {10, 10}})));
    libTES.ThermlConductanceN g_ph4(K = K_ph0, n = n_ph0) annotation(
      Placement(transformation(origin = {78, 4}, extent = {{-10, -10}, {10, 10}})));
  equation
    connect(g_e0.port_b, c_e1.port) annotation(
      Line(points = {{-66, 30}, {-56, 30}, {-56, 34}}, color = {191, 0, 0}));
    connect(g_eph1.port_a, g_e0.port_b) annotation(
      Line(points = {{-62, 26}, {-62, 30}, {-66, 30}}, color = {191, 0, 0}));
    connect(g_eph1.port_a, g_e1.port_a) annotation(
      Line(points = {{-62, 26}, {-62, 30}, {-48, 30}}, color = {191, 0, 0}));
    connect(g_ph0.port_b, g_eph1.port_b) annotation(
      Line(points = {{-66, 4}, {-62, 4}, {-62, 6}}, color = {191, 0, 0}));
    connect(c_ph1.port, g_ph1.port_a) annotation(
      Line(points = {{-56, 0}, {-56, 4}, {-48, 4}}, color = {191, 0, 0}));
    connect(c_ph1.port, g_ph0.port_b) annotation(
      Line(points = {{-56, 0}, {-56, 4}, {-66, 4}}, color = {191, 0, 0}));
    connect(c_e1.port, g_e1.port_a) annotation(
      Line(points = {{-56, 34}, {-56, 30}, {-48, 30}}, color = {191, 0, 0}));
    connect(g_e1.port_b, c_e2.port) annotation(
      Line(points = {{-28, 30}, {-18, 30}, {-18, 32}}, color = {191, 0, 0}));
    connect(g_e2.port_a, g_e1.port_b) annotation(
      Line(points = {{-8, 30}, {-28, 30}}, color = {191, 0, 0}));
    connect(g_eph2.port_a, g_e1.port_b) annotation(
      Line(points = {{-24, 26}, {-24, 30}, {-28, 30}}, color = {191, 0, 0}));
    connect(g_ph1.port_b, g_ph2.port_a) annotation(
      Line(points = {{-28, 4}, {-8, 4}}, color = {191, 0, 0}));
    connect(c_ph2.port, g_ph2.port_a) annotation(
      Line(points = {{-18, 2}, {-18, 4}, {-8, 4}}, color = {191, 0, 0}));
    connect(g_eph2.port_b, g_ph1.port_b) annotation(
      Line(points = {{-24, 6}, {-24, 4}, {-28, 4}}, color = {191, 0, 0}));
    connect(g_e2.port_b, c_e3.port) annotation(
      Line(points = {{12, 30}, {22, 30}, {22, 32}}, color = {191, 0, 0}));
    connect(g_e3.port_a, g_eph3.port_a) annotation(
      Line(points = {{28, 30}, {16, 30}, {16, 26}}, color = {191, 0, 0}));
    connect(g_e2.port_b, g_e3.port_a) annotation(
      Line(points = {{12, 30}, {28, 30}}, color = {191, 0, 0}));
    connect(g_ph2.port_b, c_ph3.port) annotation(
      Line(points = {{12, 4}, {22, 4}, {22, 2}}, color = {191, 0, 0}));
    connect(g_eph3.port_b, g_ph2.port_b) annotation(
      Line(points = {{16, 6}, {16, 4}, {12, 4}}, color = {191, 0, 0}));
    connect(g_ph2.port_b, g_ph3.port_a) annotation(
      Line(points = {{12, 4}, {28, 4}}, color = {191, 0, 0}));
    connect(g_e3.port_b, c_e4.port) annotation(
      Line(points = {{48, 30}, {58, 30}, {58, 32}}, color = {191, 0, 0}));
    connect(g_eph4.port_a, g_e3.port_b) annotation(
      Line(points = {{52, 26}, {52, 30}, {48, 30}}, color = {191, 0, 0}));
    connect(g_e3.port_b, g_e4.port_a) annotation(
      Line(points = {{48, 30}, {68, 30}}, color = {191, 0, 0}));
    connect(g_ph4.port_a, g_ph3.port_b) annotation(
      Line(points = {{68, 4}, {48, 4}}, color = {191, 0, 0}));
    connect(g_eph4.port_b, g_ph3.port_b) annotation(
      Line(points = {{52, 6}, {52, 4}, {48, 4}}, color = {191, 0, 0}));
    connect(c_ph4.port, g_ph4.port_a) annotation(
      Line(points = {{58, 2}, {58, 4}, {68, 4}}, color = {191, 0, 0}));
    connect(port_a_ph, g_ph0.port_a) annotation(
      Line(points = {{-100, 4}, {-86, 4}}, color = {191, 0, 0}));
    connect(g_e0.port_a, port_a_e) annotation(
      Line(points = {{-86, 30}, {-100, 30}}, color = {191, 0, 0}));
    connect(port_b_ph, g_ph4.port_b) annotation(
      Line(points = {{100, 4}, {88, 4}}, color = {191, 0, 0}));
    connect(g_e4.port_b, port_b_e) annotation(
      Line(points = {{88, 30}, {100, 30}}, color = {191, 0, 0}));
    annotation(
      Diagram(coordinateSystem(extent = {{-100, -100}, {100, 100}})),
      Icon(graphics = {Rectangle(origin = {0, 40}, lineColor = {170, 0, 0}, fillColor = {255, 255, 255}, pattern = LinePattern.None, fillPattern = FillPattern.Forward, extent = {{-68, 20}, {68, -20}}), Line(origin = {-79.5, 40}, points = {{-10.5, 0}, {11.5, 0}, {9.5, 0}}, color = {85, 0, 0}), Line(origin = {78.5, 40}, points = {{-10.5, 0}, {11.5, 0}, {9.5, 0}}, color = {85, 0, 0}), Text(origin = {-2, -86}, extent = {{-36, 18}, {36, -18}}, textString = "K=%K
  n=%n"), Text(origin = {0, 79}, textColor = {0, 0, 127}, extent = {{-44, 20}, {44, -20}}, textString = "%name", textStyle = {TextStyle.Bold}), Rectangle(origin = {0, -40}, lineColor = {170, 0, 0}, fillColor = {255, 255, 255}, pattern = LinePattern.None, fillPattern = FillPattern.Forward, extent = {{-68, 20}, {68, -20}}), Line(origin = {-79.5, -40}, points = {{-10.5, 0}, {11.5, 0}, {9.5, 0}}, color = {85, 0, 0}), Line(origin = {78.5, -40}, points = {{-10.5, 0}, {11.5, 0}, {9.5, 0}}, color = {85, 0, 0}), Text(origin = {-79, 52}, extent = {{-15, 10}, {15, -10}}, textString = "e"), Text(origin = {-79, -30}, extent = {{-15, 10}, {15, -10}}, textString = "ph"), Line(origin = {1.02263, 1.43097}, points = {{-61.0226, 16.569}, {-41.0226, -17.431}, {-21.0226, 16.569}, {-1.02263, -17.431}, {18.9774, 16.569}, {38.9774, -17.431}, {58.9774, 16.569}, {60.9774, 14.569}})}, coordinateSystem(extent = {{-100, -100}, {100, 100}})));
  end ThermalConductanceWireEPH;
end libTES;
