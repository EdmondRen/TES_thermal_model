model System_2block
  Modelica.Thermal.HeatTransfer.Sources.FixedTemperature fixedTemperature(T(displayUnit = "mK") = 0.012) annotation(
    Placement(transformation(origin = {-66, -24}, extent = {{-8, -8}, {8, 8}})));
  Modelica.Thermal.HeatTransfer.Sources.PrescribedHeatFlow HeatSource(T_ref(displayUnit = "K") = 0.1) annotation(
    Placement(transformation(origin = {-66, 26}, extent = {{-6, -6}, {6, 6}})));
  libTES.TES2 c1(I0 = TES_I0, Rn = TES_Rn, T(start = TES_Tinit), Tc = TES_Tc, a1 = TES_a1, a3 = TES_a3, alpha0 = TES_alpha, beta0 = TES_beta, m = TES_m) annotation(
    Placement(transformation(origin = {-4, 52}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  Modelica.Electrical.Analog.Basic.Resistor RL(R(displayUnit = "mOhm") = Bias_R, useHeatPort = false) annotation(
    Placement(transformation(origin = {-70, 70}, extent = {{-6, -6}, {6, 6}}, rotation = -90)));
  Modelica.Electrical.Analog.Basic.Ground GND annotation(
    Placement(transformation(origin = {-82, 54}, extent = {{-6, -6}, {6, 6}})));
  Modelica.Electrical.Analog.Basic.Inductor L(L = Bias_L, i(start = Bias_I*0.3)) annotation(
    Placement(transformation(origin = {-22, 76}, extent = {{-6, -6}, {6, 6}})));
  Modelica.Electrical.Analog.Sources.ConstantCurrent TESBias(I = Bias_I) annotation(
    Placement(transformation(origin = {-82, 70}, extent = {{-6, -6}, {6, 6}}, rotation = 90)));
  libTES.ThermlConductanceN g1(K = K1, n = 5) annotation(
    Placement(transformation(origin = {-4, 14}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  libTES.ThermlConductanceN g2(K = K2, n = 2) annotation(
    Placement(transformation(origin = {12, 26}, extent = {{-10, -10}, {10, 10}})));
  libTES.SourceExp edep_target(fallTimeConst = Edep_falltimetarget, offset = 0, outMax = Edep*1.6e-19*Edep_fractiontarget/Edep_falltimetarget, startTime = Edep_starttime) annotation(
    Placement(transformation(origin = {-84, 26}, extent = {{-6, -6}, {6, 6}})));
  Modelica.Electrical.Analog.Basic.Capacitor CL(C = Bias_C) annotation(
    Placement(transformation(origin = {-60, 70}, extent = {{-6, -6}, {6, 6}}, rotation = -90)));
  Modelica.Electrical.Analog.Basic.Resistor Rp(R = Bias_Rp, useHeatPort = false) annotation(
    Placement(transformation(origin = {-46, 76}, extent = {{-6, -6}, {6, 6}})));
  libTES.HeatCapacitorPoly c2(T(start = TES_Tinit), a1 = a1_gold, a3 = a3_gold, a5 = a5_gold, m = m2) annotation(
    Placement(transformation(origin = {26, 38}, extent = {{-10, -10}, {10, 10}})));
  libTES.ThermlConductanceN g3(K = K3, n = 5) annotation(
    Placement(transformation(origin = {26, 14}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  // Parameters
  // IMPORTANT: The parameters below are set to Evaluate=false to avoid them being evaluated during compilation. This is necessary because the model is compiled before the parameters are set in the simulation script.
  //  - Exitation
  parameter Real Edep = 200 "[eV], energy deposition" annotation(Evaluate=false);
  parameter Real Edep_time = 1.00e-7 "[s], time for energy deposition" annotation(Evaluate=false);
  parameter Real Edep_fractiontarget = 1 "Fraction of energy in target" annotation(Evaluate=false);
  parameter Real Edep_falltimetarget = 0.3e-3 "Phonon thermalization time constant in target" annotation(Evaluate=false);
  parameter Real Edep_falltimefilm = 0.3e-3 "Phonon thermalization time constant in film" annotation(Evaluate=false);
  parameter Modelica.Units.SI.Time Edep_starttime = 1e-3 "Start time of energy deposition" annotation(Evaluate=false);
  //  - Electrical, bias
  parameter Modelica.Units.SI.Current Bias_I = 36.1e-6 "Bias current" annotation(Evaluate=false);
  parameter Modelica.Units.SI.Resistance Bias_R = 2.00e-2 "Load resistance (Rsh)" annotation(Evaluate=false);
  parameter Modelica.Units.SI.Resistance Bias_Rp = 1.50e-2 "Load resistance (Rp)" annotation(Evaluate=false);  
  parameter Modelica.Units.SI.Inductance Bias_L = 3.00e-7 "Bias circuit indutance" annotation(Evaluate=false);
  parameter Modelica.Units.SI.Capacitance Bias_C = 20e-12 "Bias circuit capacitance" annotation(Evaluate=false);
  //  - Electrical, TES
  parameter Modelica.Units.SI.Resistance TES_Rn = 0.175 "TES normal resistance" annotation(Evaluate=false);
  parameter Modelica.Units.SI.Temperature TES_Tc = 0.021 "TES critical temp." annotation(Evaluate=false);
  parameter Modelica.Units.SI.Temperature TES_Tinit = 0.021 "Initial guess of TES temperature" annotation(Evaluate=false);
  parameter Real TES_alpha = 20 "TES alpha" annotation(Evaluate=false);
  parameter Real TES_beta = 1 "TES beta" annotation(Evaluate=false);
  parameter Modelica.Units.SI.Current TES_I0 = 5e-6 "TES Current where beta is evaluated" annotation(Evaluate=false);
  parameter Modelica.Units.SI.Mass TES_m = 6.53e-12 "TES mass" annotation(Evaluate=false);
  parameter Real TES_a1 = 5.00e-2 "TES heat capacity linear term" annotation(Evaluate=false);
  parameter Real TES_a3 = 9.24e-4 "TES heat capacity cubic term" annotation(Evaluate=false);
  //  - Thermal, conductance
  parameter Real K1 = 7.99e-05   "Absorber -> Goldpad" annotation(Evaluate=false);
  parameter Real K2 = 1.2e-7   "Goldpad -> Goldwirebond" annotation(Evaluate=false);
  parameter Real K3 = 7.99e-05   "Goldwirebond -> Goldpad(TES1)" annotation(Evaluate=false);
  //  - Thermal, heat capacity
  parameter Modelica.Units.SI.Mass m2 = 6.07e-14 "Gold (target gold pad)" annotation(Evaluate=false);
  parameter Real a1_target = 6.95e-7 annotation(Evaluate=false);
  parameter Real a3_target = 2.18e-6 annotation(Evaluate=false);
  parameter Real a5_target = 0 annotation(Evaluate=false);
  parameter Real a1_gold = 8.86e-3 annotation(Evaluate=false);
  parameter Real a3_gold = 5.58e-3 annotation(Evaluate=false);
  parameter Real a5_gold = 0 annotation(Evaluate=false);
  parameter Real a1_silicon = 0 annotation(Evaluate=false);
  parameter Real a3_silicon = 2.70e-4 annotation(Evaluate=false);
  parameter Real a5_silicon = 0 annotation(Evaluate=false);
  parameter Real a1_glue = 6.50e-3 annotation(Evaluate=false);
  parameter Real a3_glue = 1.90e-2 annotation(Evaluate=false);
  parameter Real a5_glue = 0 annotation(Evaluate=false);  

equation
  connect(TESBias.p, RL.n) annotation(
    Line(points = {{-82, 64}, {-70, 64}}, color = {0, 0, 255}));
  connect(RL.p, TESBias.n) annotation(
    Line(points = {{-70, 76}, {-82, 76}}, color = {0, 0, 255}));
  connect(L.n, c1.p) annotation(
    Line(points = {{-16, 76}, {2, 76}, {2, 62}}, color = {0, 0, 255}));
  connect(c1.n, RL.n) annotation(
    Line(points = {{-10, 62}, {-10, 64}, {-70, 64}}, color = {0, 0, 255}));
  connect(edep_target.y, HeatSource.Q_flow) annotation(
    Line(points = {{-77.4, 26}, {-71.4, 26}}, color = {0, 0, 127}));
  connect(CL.p, RL.p) annotation(
    Line(points = {{-60, 76}, {-70, 76}}, color = {0, 0, 255}));
  connect(CL.n, RL.n) annotation(
    Line(points = {{-60, 64}, {-70, 64}}, color = {0, 0, 255}));
  connect(Rp.n, L.p) annotation(
    Line(points = {{-40, 76}, {-28, 76}}, color = {0, 0, 255}));
  connect(Rp.p, CL.p) annotation(
    Line(points = {{-52, 76}, {-60, 76}}, color = {0, 0, 255}));
  connect(HeatSource.port, g1.port_a) annotation(
    Line(points = {{-60, 26}, {-4, 26}, {-4, 24}}, color = {191, 0, 0}));
  connect(c1.heatPort, g1.port_a) annotation(
    Line(points = {{-4, 42}, {-4, 24}}, color = {191, 0, 0}));
  connect(g2.port_a, g1.port_a) annotation(
    Line(points = {{2, 26}, {-4, 26}, {-4, 24}}, color = {191, 0, 0}));
  connect(g2.port_b, g3.port_a) annotation(
    Line(points = {{22, 26}, {26, 26}, {26, 24}}, color = {191, 0, 0}));
  connect(c2.port, g3.port_a) annotation(
    Line(points = {{26, 28}, {26, 24}}, color = {191, 0, 0}));
  connect(g1.port_b, fixedTemperature.port) annotation(
    Line(points = {{-4, 4}, {-4, -24}, {-58, -24}}, color = {191, 0, 0}));
  connect(g3.port_b, fixedTemperature.port) annotation(
    Line(points = {{26, 4}, {26, -24}, {-58, -24}}, color = {191, 0, 0}));
  connect(GND.p, TESBias.p) annotation(
    Line(points = {{-82, 60}, {-82, 64}}, color = {0, 0, 255}));
  annotation(
    Diagram(graphics = {Text(origin = {-4, 67}, extent = {{-8, 3}, {8, -3}}, textString = "TES", textStyle = {TextStyle.Bold})}),
  experiment(StartTime = 0, StopTime = 0.01, Tolerance = 1e-08, Interval = 1e-06),
  __OpenModelica_commandLineOptions = "--matchingAlgorithm=PFPlusExt --indexReductionMethod=dynamicStateSelection -d=initialization,NLSanalyticJacobian -d=aliasConflicts ",
  __OpenModelica_simulationFlags(lv = "LOG_STDOUT,LOG_ASSERT,LOG_STATS", s = "dassl", variableFilter = ".*"));
end System_2block;
