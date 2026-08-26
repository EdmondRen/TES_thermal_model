model HeatCapacitorPoly
  import Modelica.Units.SI;

  parameter SI.Mass m(displayUnit="ug") = 1;
  parameter Real a0 = 0;
  parameter Real a1 = 0;
  parameter Real a3 = 0;
  parameter Real a5 = 0;
  parameter Real T0 = 0;
  parameter Real Tr; // Relative temperature for Taylor expansion
  parameter SI.Temperature T_start = 0;

  SI.Temperature T(start=T_start);
  SI.SpecificHeatCapacity cp;

  Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a port
      annotation(Placement(transformation(origin = {-20, 100}, extent = {{-10, -110}, {10, -90}}), iconTransformation(extent = {{-10, -110}, {10, -90}})));

equation
  port.T = T;
  
  Tr = T - T0;
  cp = a0 + a1*Tr + a3*Tr^3 + a5*Tr^5;

  m*cp*der(T) = port.Q_flow;

annotation(
    Diagram(graphics),
    Icon(graphics = {Polygon(lineColor = {160, 160, 164}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid, points = {{0, 67}, {-20, 63}, {-40, 57}, {-52, 43}, {-58, 35}, {-68, 25}, {-72, 13}, {-76, -1}, {-78, -15}, {-76, -31}, {-76, -43}, {-76, -53}, {-70, -65}, {-64, -73}, {-48, -77}, {-30, -83}, {-18, -83}, {-2, -85}, {8, -89}, {22, -89}, {32, -87}, {42, -81}, {54, -75}, {56, -73}, {66, -61}, {68, -53}, {70, -51}, {72, -35}, {76, -21}, {78, -13}, {78, 3}, {74, 15}, {66, 25}, {54, 33}, {44, 41}, {36, 57}, {26, 65}, {0, 67}}), Polygon(fillColor = {160, 160, 164}, fillPattern = FillPattern.Solid, points = {{-58, 35}, {-68, 25}, {-72, 13}, {-76, -1}, {-78, -15}, {-76, -31}, {-76, -43}, {-76, -53}, {-70, -65}, {-64, -73}, {-48, -77}, {-30, -83}, {-18, -83}, {-2, -85}, {8, -89}, {22, -89}, {32, -87}, {42, -81}, {54, -75}, {42, -77}, {40, -77}, {30, -79}, {20, -81}, {18, -81}, {10, -81}, {2, -77}, {-12, -73}, {-22, -73}, {-30, -71}, {-40, -65}, {-50, -55}, {-56, -43}, {-58, -35}, {-58, -25}, {-60, -13}, {-60, -5}, {-60, 7}, {-58, 17}, {-56, 19}, {-52, 27}, {-48, 35}, {-44, 45}, {-40, 57}, {-58, 35}}), Text(textColor = {0, 0, 255}, extent = {{-150, 110}, {150, 70}}, textString = "%name"), Text(origin = {0, 9},extent = {{-61, 10}, {63, -33}}, textString = "m=%m
a1=%a1")}));
end HeatCapacitorPoly;
