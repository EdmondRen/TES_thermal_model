model System_1block_linearG
  Modelica.Thermal.HeatTransfer.Sources.FixedTemperature fixedTemperature(T(displayUnit = "mK") = 0.01) annotation(
    Placement(transformation(origin = {-39, -23}, extent = {{-11, -11}, {11, 11}})));
  Modelica.Electrical.Analog.Basic.Resistor RL(R = 0.02) annotation(
    Placement(transformation(origin = {-72, 24}, extent = {{-6, -6}, {6, 6}}, rotation = -90)));
  Modelica.Thermal.HeatTransfer.Sources.PrescribedHeatFlow HeatSource(T_ref(displayUnit = "K") = 0.1)  annotation(
    Placement(transformation(origin = {-42, 72}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Blocks.Sources.Pulse Pulse(amplitude = 3.2e-10, width = 100e-7, period = 1, nperiod = 1, startTime(displayUnit = "ms") = 0.01) annotation(
    Placement(transformation(origin = {-70, 72}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Ground GND annotation(
    Placement(transformation(origin = {-84, 2}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Inductor L(L(displayUnit = "nH") = 2.01e-7) annotation(
    Placement(transformation(origin = {-60, 30}, extent = {{-6, -6}, {6, 6}})));
  libTES.TES tes(Tc(displayUnit = "K") = 0.048, alpha0 = 10, C = 2e-14, Rn = 0.3, T(displayUnit = "K")) annotation(
    Placement(transformation(origin = {-38, 24}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Thermal.HeatTransfer.Components.ThermalConductor thermalConductor(G = 5.4e-11)  annotation(
    Placement(transformation(origin = {-8, 0}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  Modelica.Electrical.Analog.Sources.ConstantCurrent TESBias(I(displayUnit = "uA") = 2e-5)  annotation(
    Placement(transformation(origin = {-84, 24}, extent = {{6, -6}, {-6, 6}}, rotation = -90)));
equation
  connect(Pulse.y, HeatSource.Q_flow) annotation(
    Line(points = {{-59, 72}, {-53, 72}}, color = {0, 0, 127}));
  connect(L.n, tes.p) annotation(
    Line(points = {{-54, 30}, {-48, 30}}, color = {0, 0, 255}));
  connect(fixedTemperature.port, thermalConductor.port_b) annotation(
    Line(points = {{-28, -23}, {-8, -23}, {-8, -11}}, color = {191, 0, 0}));
  connect(thermalConductor.port_a, tes.heatPort) annotation(
    Line(points = {{-8, 10}, {-8, 24}, {-28, 24}}, color = {191, 0, 0}));
  connect(HeatSource.port, thermalConductor.port_a) annotation(
    Line(points = {{-32, 72}, {-8, 72}, {-8, 10}}, color = {191, 0, 0}));
  connect(GND.p, TESBias.p) annotation(
    Line(points = {{-84, 12}, {-84, 18}}, color = {0, 0, 255}));
  connect(TESBias.p, RL.n) annotation(
    Line(points = {{-84, 18}, {-72, 18}}, color = {0, 0, 255}));
  connect(tes.n, RL.n) annotation(
    Line(points = {{-48, 18}, {-72, 18}}, color = {0, 0, 255}));
  connect(L.p, RL.p) annotation(
    Line(points = {{-66, 30}, {-72, 30}}, color = {0, 0, 255}));
  connect(RL.p, TESBias.n) annotation(
    Line(points = {{-72, 30}, {-84, 30}}, color = {0, 0, 255}));
  annotation(
    uses(Modelica(version = "4.1.0")),
    Diagram,
    __OpenModelica_simulationFlags(lv = "LOG_STDOUT,LOG_ASSERT,LOG_STATS", s = "dassl", variableFilter = ".*"),
    __OpenModelica_commandLineOptions = "--matchingAlgorithm=PFPlusExt --indexReductionMethod=dynamicStateSelection -d=initialization,NLSanalyticJacobian -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts",
    experiment(StartTime = 0, StopTime = 0.03, Interval = 1e-07, Tolerance = 1e-06));  
end System_1block_linearG;
