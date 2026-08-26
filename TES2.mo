model TES2
  // Electrical port
  Modelica.Electrical.Analog.Interfaces.PositivePin p
    annotation(Placement(transformation(origin = {0, 40}, extent = {{-110, -10}, {-90, 10}}), iconTransformation(origin = {0, 60}, extent = {{-110, -10}, {-90, 10}})));
  Modelica.Electrical.Analog.Interfaces.NegativePin n
    annotation(Placement(transformation(origin = {-200, -40}, extent = {{90, -10}, {110, 10}}), iconTransformation(origin = {-200, -60}, extent = {{90, -10}, {110, 10}})));
  
  // Heat port
  Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a heatPort
    annotation(Placement(transformation(origin = {-20, 100}, extent = {{-10, -110}, {10, -90}}), iconTransformation(origin = {100, 100}, extent = {{-10, -110}, {10, -90}})));

  
  //                         (electrical)
  //                    p -----[ TES R] ----- n
  //                              |
  //                           Joule heat
  //                              ↓
  //           heatPort --- [ thermal C, T ]


  parameter Modelica.Units.SI.Resistance Rn;
  parameter Modelica.Units.SI.Temperature Tc;
  parameter Real alpha0;

  // Heat capacity
  parameter Modelica.Units.SI.Mass m(displayUnit="ug") = 1;
  parameter Real a1 = 0;
  parameter Real a3 = 0;
  Modelica.Units.SI.SpecificHeatCapacity cp;

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
  R = Rn/2 *(1. + tanh((T - Tc) * alpha0/Tc));
  v = R * i;  
  P_Joule = v * i;

  // Heat capacity (temperature dependent)
  cp = a1*T + a3*Tr^3;
  
  // Thermal energy balance
  heatPort.T = T;
  m * cp * der(T) = P_Joule + heatPort.Q_flow;



annotation(
    Diagram(graphics = {Rectangle(origin = {-60, 0}, extent = {{-40, 40}, {40, -40}})}),
  Icon(graphics = {Text(origin = {14, 0}, extent = {{-46, 30}, {46, -30}}, textString = "Rn=%Rn
Tc=%Tc
alpha0=%alpha0
m=%m
a1=%a1
a3=%a3
", horizontalAlignment = TextAlignment.Left), Rectangle(extent = {{-100, 100}, {100, -100}}), Line(origin = {-76, 10}, points = {{-24, 50}, {16, 50}, {16, 30}, {24, 30}, {24, -50}, {8, -50}, {8, 30}, {16, 30}, {16, 30}}), Line(origin = {-75, -50}, points = {{15, 10}, {15, -10}, {-15, -10}, {-15, -10}}), Line(origin = {-57.0045, 2.71811}, points = {{-20.9955, -26.7181}, {15.0045, 23.2819}, {9.00454, 27.2819}, {21.0045, 19.2819}, {21.0045, 19.2819}}), Text(origin = {-2, 123}, extent = {{-50, 27}, {50, -27}}, textString = "%name")}));
end TES2;
