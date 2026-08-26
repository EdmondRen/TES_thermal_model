model ThermlConductanceN

  Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a port_a
    annotation(Placement(transformation(origin = {0, 40}, extent = {{-110, -10}, {-90, 10}}), iconTransformation(extent = {{-110, -10}, {-90, 10}})));

  Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_b port_b
    annotation(Placement(transformation(origin = {200, 40}, extent = {{-110, -10}, {-90, 10}}), iconTransformation(origin = {200, 0}, extent = {{-110, -10}, {-90, 10}})));
  
  parameter Real K = 1e-8
    "Thermal coupling coefficient [W/K^n]";

  parameter Real n = 3
    "Thermal transport exponent";

  Modelica.Units.SI.HeatFlowRate Q_flow;
  
  
equation


  Q_flow = K * (port_a.T^n - port_b.T^n);

  port_a.Q_flow = Q_flow;
  port_b.Q_flow = -Q_flow;


annotation(
    Icon(graphics = {Rectangle(lineColor = {170, 0, 0}, fillColor = {255, 255, 255}, pattern = LinePattern.None, fillPattern = FillPattern.Forward, extent = {{-68, 20}, {68, -20}}), Line(origin = {-79.5, 0}, points = {{-10.5, 0}, {11.5, 0}, {9.5, 0}}, color = {85, 0, 0}), Line(origin = {78.5, 0}, points = {{-10.5, 0}, {11.5, 0}, {9.5, 0}}, color = {85, 0, 0}), Text(origin = {-2, -46}, extent = {{-36, 18}, {36, -18}}, textString = "K=%K
n=%n"), Text(origin = {0, 42}, textColor = {0, 0, 127}, extent = {{-44, 24}, {44, -24}}, textString = "%name")}),
  Diagram(graphics));
end ThermlConductanceN;
