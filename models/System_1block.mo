model System_1block
  Modelica.Thermal.HeatTransfer.Sources.FixedTemperature fixedTemperature(T(displayUnit = "mK") = 0.01) annotation(
    Placement(transformation(origin = {-19, -47}, extent = {{-11, -11}, {11, 11}})));
  Modelica.Thermal.HeatTransfer.Sources.PrescribedHeatFlow HeatSource(T_ref(displayUnit = "K") = 0.1)  annotation(
    Placement(transformation(origin = {-22, 48}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Blocks.Sources.Pulse Pulse(amplitude = 3.2e-10, width = 100e-7, period = 1, nperiod = 1, startTime(displayUnit = "ms") = 0.01) annotation(
    Placement(transformation(origin = {-50, 48}, extent = {{-10, -10}, {10, 10}})));
  libTES.TES2 tes(Rn = TES_Rn, Tc = TES_Tc, alpha0 = TES_alpha, m = TES_m, a1 = TES_a1, a3 = TES_a3) annotation(
    Placement(transformation(origin = {-18, 0}, extent = {{-10, -10}, {10, 10}})));
  libTES.ThermlConductanceN G1(K = 1.5e-6, n = 5)  annotation(
    Placement(transformation(origin = {12, -22}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  Modelica.Electrical.Analog.Basic.Resistor RL(R (displayUnit = "mOhm")= 0.02) annotation(
    Placement(transformation(origin = {-50, 0}, extent = {{-6, -6}, {6, 6}}, rotation = -90)));
  Modelica.Electrical.Analog.Basic.Ground GND annotation(
    Placement(transformation(origin = {-62, -22}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Inductor L(L(displayUnit = "nH") = 3.01e-7) annotation(
    Placement(transformation(origin = {-38, 6}, extent = {{-6, -6}, {6, 6}})));
  Modelica.Electrical.Analog.Sources.ConstantCurrent TESBias(I(displayUnit = "uA") = 1.1e-5) annotation(
    Placement(transformation(origin = {-62, 0}, extent = {{-6, -6}, {6, 6}}, rotation = 90)));
  //  - Electrical, TES
  parameter Modelica.Units.SI.Resistance TES_Rn = 0.175 "TES normal resistance";
  parameter Modelica.Units.SI.Temperature TES_Tc = 0.048 "TES critical temp.";
  parameter Real TES_alpha = 10 "TES alpha";
  parameter Modelica.Units.SI.Mass TES_m = 6.53e-13 "TES mass";
  parameter Real TES_a1 = 5.00e-2 "TES heat capacity linear term";
  parameter Real TES_a3 = 9.24e-4 "TES heat capacity cubic term";

equation
  connect(Pulse.y, HeatSource.Q_flow) annotation(
    Line(points = {{-39, 48}, {-33, 48}}, color = {0, 0, 127}));
  connect(fixedTemperature.port, G1.port_b) annotation(
    Line(points = {{-8, -47}, {12, -47}, {12, -33}}, color = {191, 0, 0}));
  connect(G1.port_a, HeatSource.port) annotation(
    Line(points = {{12, -12}, {12, 48}, {-12, 48}}, color = {191, 0, 0}));
  connect(tes.heatPort, G1.port_a) annotation(
    Line(points = {{-8, 0}, {12, 0}, {12, -12}}, color = {191, 0, 0}));
  connect(GND.p, TESBias.p) annotation(
    Line(points = {{-62, -12}, {-62, -6}}, color = {0, 0, 255}));
  connect(TESBias.p, RL.n) annotation(
    Line(points = {{-62, -6}, {-50, -6}}, color = {0, 0, 255}));
  connect(L.p, RL.p) annotation(
    Line(points = {{-44, 6}, {-50, 6}}, color = {0, 0, 255}));
  connect(RL.p, TESBias.n) annotation(
    Line(points = {{-50, 6}, {-62, 6}}, color = {0, 0, 255}));
  connect(L.n, tes.p) annotation(
    Line(points = {{-32, 6}, {-28, 6}}, color = {0, 0, 255}));
  connect(tes.n, RL.n) annotation(
    Line(points = {{-28, -6}, {-50, -6}}, color = {0, 0, 255}));
  annotation(
    uses(Modelica(version = "4.1.0")),
    Diagram,
    __OpenModelica_simulationFlags(lv = "LOG_STDOUT,LOG_ASSERT,LOG_STATS", s = "dassl", variableFilter = ".*"),
  __OpenModelica_commandLineOptions = "--matchingAlgorithm=PFPlusExt --indexReductionMethod=dynamicStateSelection -d=initialization,NLSanalyticJacobian",
  experiment(StartTime = 0, StopTime = 0.04, Tolerance = 1e-06, Interval = 2e-07));
end System_1block;
