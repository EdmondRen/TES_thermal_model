model System_LMO
  Modelica.Thermal.HeatTransfer.Sources.FixedTemperature fixedTemperature(T(displayUnit = "mK") = 0.012) annotation(
    Placement(transformation(origin = {-76, -52}, extent = {{-8, -8}, {8, 8}})));
  Modelica.Thermal.HeatTransfer.Sources.PrescribedHeatFlow HeatSource(T_ref(displayUnit = "K") = 0.1) annotation(
    Placement(transformation(origin = {-72, 22}, extent = {{-6, -6}, {6, 6}})));
  Modelica.Thermal.HeatTransfer.Sources.PrescribedHeatFlow HeatSource1(T_ref(displayUnit = "K") = 0.1) annotation(
    Placement(transformation(origin = {-72, -2}, extent = {{-6, -6}, {6, 6}})));
  libTES.TES2 c10(Rn = TES_Rn, T(start = TES_Tinit), Tc = TES_Tc, a1 = TES_a1, a3 = TES_a3, alpha0 = TES_alpha, m = TES_m) annotation(
    Placement(transformation(origin = {46, 44}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  libTES.ThermlConductanceN g1(K = K1, n = 5) annotation(
    Placement(transformation(origin = {-44, 22}, extent = {{-10, -10}, {10, 10}})));
  libTES.ThermlConductanceN g2(K = K2, n = 2) annotation(
    Placement(transformation(origin = {-18, 22}, extent = {{-10, -10}, {10, 10}})));
  libTES.ThermlConductanceN g3(K = K3, n = 2) annotation(
    Placement(transformation(origin = {6, 22}, extent = {{-10, -10}, {10, 10}})));
  libTES.ThermlConductanceN g12(K = K12, n = 4) annotation(
    Placement(transformation(origin = {26, -18}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  libTES.ThermlConductanceN g13(K = K13, n = 4) annotation(
    Placement(transformation(origin = {26, -42}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  libTES.ThermlConductanceN g14(K = K14, n = 4) annotation(
    Placement(transformation(origin = {-58, -34}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  libTES.HeatCapacitorPoly c1(m = m1, a1 = a1_target, a3 = a3_target, a5 = a5_target, T(start = TES_Tinit)) annotation(
    Placement(transformation(origin = {-58, 36}, extent = {{-10, -10}, {10, 10}})));
  libTES.HeatCapacitorPoly c2(m = m2, a1 = a1_gold, a3 = a3_gold, a5 = a5_gold, T(start = TES_Tinit)) annotation(
    Placement(transformation(origin = {-32, 36}, extent = {{-10, -10}, {10, 10}})));
  libTES.HeatCapacitorPoly c3(m = m3, a1 = a1_gold, a3 = a3_gold, a5 = a5_gold, T(start = TES_Tinit)) annotation(
    Placement(transformation(origin = {-8, 36}, extent = {{-10, -10}, {10, 10}})));
  libTES.HeatCapacitorPoly c4(m = m4, a1 = a1_gold, a3 = a3_gold, a5 = a5_gold, T(start = TES_Tinit)) annotation(
    Placement(transformation(origin = {26, 36}, extent = {{-10, -10}, {10, 10}})));
  libTES.HeatCapacitorPoly c6(m = m6, a1 = a1_gold, a3 = a3_gold, a5 = a5_gold, T(start = TES_Tinit)) annotation(
    Placement(transformation(origin = {70, 36}, extent = {{-10, -10}, {10, 10}})));
  libTES.HeatCapacitorPoly c5(m = m5, a1 = a1_silicon, a3 = a3_silicon, a5 = a5_silicon, T(start = TES_Tinit)) annotation(
    Placement(transformation(origin = {68, 6}, extent = {{-10, -10}, {10, 10}})));
  libTES.HeatCapacitorPoly c7(m = m7, a1 = a1_gold, a3 = a3_gold, a5 = a5_gold, T(start = TES_Tinit)) annotation(
    Placement(transformation(origin = {94, 36}, extent = {{-10, -10}, {10, 10}})));
  libTES.HeatCapacitorPoly c9(m = m9, a1 = a1_glue, a3 = a3_glue, a5 = a5_glue, T(start = TES_Tinit)) annotation(
    Placement(transformation(origin = {6, -32}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
  libTES.HeatCapacitorPoly c8(m = m8, a1 = a1_gold, a3 = a3_gold, a5 = a5_gold, T(start = TES_Tinit)) annotation(
    Placement(transformation(origin = {90, -30}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
  Modelica.Electrical.Analog.Basic.Resistor RL(R(displayUnit = "mOhm") = Bias_R, useHeatPort = false) annotation(
    Placement(transformation(origin = {-6, 62}, extent = {{-6, -6}, {6, 6}}, rotation = -90)));
  Modelica.Electrical.Analog.Basic.Ground GND annotation(
    Placement(transformation(origin = {-32, 56}, extent = {{-6, -6}, {6, 6}}, rotation = -90)));
  Modelica.Electrical.Analog.Basic.Inductor L(L = Bias_L, i(start = Bias_I*0.3)) annotation(
    Placement(transformation(origin = {2, 68}, extent = {{-6, -6}, {6, 6}})));
  Modelica.Electrical.Analog.Sources.ConstantCurrent TESBias(I = Bias_I) annotation(
    Placement(transformation(origin = {-18, 62}, extent = {{-6, -6}, {6, 6}}, rotation = 90)));
  libTES.ThermlConductanceN g4(K = K4, n = 2) annotation(
    Placement(transformation(origin = {36, 22}, extent = {{-10, -10}, {10, 10}})));
  libTES.ThermlConductanceN g5(K = K5, n = 5) annotation(
    Placement(transformation(origin = {26, 6}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  libTES.ThermlConductanceN g6(K = K6, n = 6) annotation(
    Placement(transformation(origin = {46, 6}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  libTES.ThermlConductanceN g7(K = K7, n = 2) annotation(
    Placement(transformation(origin = {60, 22}, extent = {{-10, -10}, {10, 10}})));
  libTES.ThermlConductanceN g8(K = K8, n = 2) annotation(
    Placement(transformation(origin = {84, 22}, extent = {{-10, -10}, {10, 10}})));
  libTES.ThermlConductanceN g11(K = K11, n = 5) annotation(
    Placement(transformation(origin = {94, 6}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  libTES.ThermlConductanceN g10(K = K10, n = 2) annotation(
    Placement(transformation(origin = {108, -42}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  libTES.ThermlConductanceN g9(K = K9, n = 2) annotation(
    Placement(transformation(origin = {108, -16}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  // Parameters
  // IMPORTANT: The parameters below are set to Evaluate=false to avoid them being evaluated during compilation. This is necessary because the model is compiled before the parameters are set in the simulation script.
  //  - Exitation
  parameter Real Edep = 200000 "[eV], energy deposition" annotation(Evaluate=false);
  parameter Real Edep_time = 1.00e-7 "[s], time for energy deposition" annotation(Evaluate=false);
  parameter Real Edep_fractiontarget = 0.2 "Fraction of energy in target" annotation(Evaluate=false);
  parameter Real Edep_falltimetarget = 0.3e-3 "Phonon thermalization time constant in target" annotation(Evaluate=false);
  parameter Real Edep_falltimefilm = 0.3e-3 "Phonon thermalization time constant in film" annotation(Evaluate=false);
  parameter Modelica.Units.SI.Time Edep_starttime = 10e-3 "Start time of energy deposition" annotation(Evaluate=false);
  //  - Electrical, bias
  parameter Modelica.Units.SI.Current Bias_I = 36.1e-6 "Bias current" annotation(Evaluate=false);
  parameter Modelica.Units.SI.Resistance Bias_R = 2.00e-2 "Load resistance (Rsh+Rp)" annotation(Evaluate=false);
  parameter Modelica.Units.SI.Inductance Bias_L = 3.00e-7 "Bias circuit indutance" annotation(Evaluate=false);
  //  - Electrical, TES
  parameter Modelica.Units.SI.Resistance TES_Rn = 0.175 "TES normal resistance" annotation(Evaluate=false);
  parameter Modelica.Units.SI.Temperature TES_Tc = 0.021 "TES critical temp." annotation(Evaluate=false);
  parameter Modelica.Units.SI.Temperature TES_Tinit = 0.021 "Initial guess of TES temperature" annotation(Evaluate=false);
  parameter Real TES_alpha = 20 "TES alpha" annotation(Evaluate=false);
  parameter Modelica.Units.SI.Mass TES_m = 6.53e-12 "TES mass" annotation(Evaluate=false);
  parameter Real TES_a1 = 5.00e-2 "TES heat capacity linear term" annotation(Evaluate=false);
  parameter Real TES_a3 = 9.24e-4 "TES heat capacity cubic term" annotation(Evaluate=false);
  //  - Thermal, conductance
  parameter Real K1 = 1.16e-1   "Absorber -> Goldpad" annotation(Evaluate=false);
  parameter Real K2 = 8.80e-6   "Goldpad -> Goldwirebond" annotation(Evaluate=false);
  parameter Real K3 = 8.80e-6   "Goldwirebond -> Goldpad(TES1)" annotation(Evaluate=false);
  parameter Real K4 = 0.1e-7    "Goldpad(TES1) -> TES Electron System" annotation(Evaluate=false);
  parameter Real K5 = 7.99e-5*2000 "Goldpad(TES1) -> Si chip" annotation(Evaluate=false);
  parameter Real K6 = 1.08e-5 "Si chip -> TES, electron-phonon coupling" annotation(Evaluate=false);
  parameter Real K7 = 0.1e-7    "TES -> Goldpad(TES2)" annotation(Evaluate=false);
  parameter Real K8 = 6.8e-8 "Goldpad(TES2) -> Meander" annotation(Evaluate=false);
  parameter Real K9 = 5.64e-5   "Meander -> WireBond2" annotation(Evaluate=false);
  parameter Real K10 = 5.64e-5  "WireBond2 -> bath" annotation(Evaluate=false);
  parameter Real K11 = 1.45e-4 " Meander -> Si chip" annotation(Evaluate=false);
  parameter Real K12 = 2.70e-6*4000 "Si chip -> Glue" annotation(Evaluate=false);
  parameter Real K13 = 2.70e-6*4000 "Glue -> bath" annotation(Evaluate=false);
  parameter Real K14 = 7.84e-8 "Absorber -> bath" annotation(Evaluate=false);
  //  - Thermal, heat capacity
  parameter Modelica.Units.SI.Mass m1 = 2.46e-2 "Absorber mass" annotation(Evaluate=false);
  parameter Modelica.Units.SI.Mass m2 = 6.07e-7 "Gold (target gold pad)" annotation(Evaluate=false);
  parameter Modelica.Units.SI.Mass m3 = 3.03e-8 "Gold (WireBond1)" annotation(Evaluate=false);
  parameter Modelica.Units.SI.Mass m4 = 4.17e-10 "Gold (GoldPad2)" annotation(Evaluate=false);
  parameter Modelica.Units.SI.Mass m5 = 8.38e-6 "Silicon chip" annotation(Evaluate=false);
  parameter Modelica.Units.SI.Mass m6 = 3.97e-12 "Gold (GoldPadTES)" annotation(Evaluate=false);
  parameter Modelica.Units.SI.Mass m7 = 7.59e-10 "Gold (Meander)" annotation(Evaluate=false);
  parameter Modelica.Units.SI.Mass m8 = 4.73e-9 "Gold (WireBond2)" annotation(Evaluate=false);
  parameter Modelica.Units.SI.Mass m9 = 2.67e-9 "Glue" annotation(Evaluate=false);
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
  // Results
  Real C1;
  Real C2;
  Real C3;
  Real C4;
  Real C5;
  Real C6;
  Real C7;
  Real C8;
  Real C9;
  Real C10;
  Real T1;
  Real T2;
  Real T3;
  Real T4;
  Real T5;
  Real T6;
  Real T7;
  Real T8;
  Real T9;
  Real T10;
  Real G1;
  Real G2;
  Real G3;
  Real G4;
  Real G5;
  Real G6;
  Real G7;
  Real G8;
  Real G9;
  Real G10;
  Real G11;
  Real G12;
  Real G13;
  Real G14;

  libTES.SourceExp edep_target(outMax = Edep*1.6e-19*Edep_fractiontarget/Edep_falltimetarget, fallTimeConst = Edep_falltimetarget, offset = 0, startTime = Edep_starttime)  annotation(
    Placement(transformation(origin = {-90, 22}, extent = {{-6, -6}, {6, 6}})));
  libTES.SourceExp edep_film(outMax = Edep*1.6e-19*(1-Edep_fractiontarget)/Edep_falltimefilm, fallTimeConst = Edep_falltimefilm, offset = 0, startTime = Edep_starttime) annotation(
    Placement(transformation(origin = {-90, -2}, extent = {{-6, -6}, {6, 6}})));
//  Modelica.Blocks.Sources.Pulse Pulse(amplitude = Edep*1.602e-19/Edep_time*Edep_thermalfraction, nperiod = 1, period = 1, startTime(displayUnit = "ms") = Edep_starttime, width = 100*Edep_time) annotation(
//    Placement(transformation(origin = {-88, 22}, extent = {{-6, -6}, {6, 6}})));
equation
  C1 = c1.C;
  C2 = c2.C;
  C3 = c3.C;
  C4 = c4.C;
  C5 = c5.C;
  C6 = c6.C;
  C7 = c7.C;
  C8 = c8.C;
  C9 = c9.C;
  C10 = c10.C;
  T1 = c1.T;
  T2 = c2.T;
  T3 = c3.T;
  T4 = c4.T;
  T5 = c5.T;
  T6 = c6.T;
  T7 = c7.T;
  T8 = c8.T;
  T9 = c9.T;
  T10 = c10.T;
  G1 = g1.G;
  G2 = g2.G;
  G3 = g3.G;
  G4 = g4.G;
  G5 = g5.G;
  G6 = g6.G;
  G7 = g7.G;
  G8 = g8.G;
  G9 = g9.G;
  G10 = g10.G;
  G11 = g11.G;
  G12 = g12.G;
  G13 = g13.G;
  G14 = g14.G;
  connect(c3.port, g2.port_b) annotation(
    Line(points = {{-8, 26}, {-8, 22}}, color = {191, 0, 0}));
  connect(g14.port_a, c1.port) annotation(
    Line(points = {{-58, -24}, {-58, 26}}, color = {191, 0, 0}));
  connect(g1.port_a, c1.port) annotation(
    Line(points = {{-54, 22}, {-58, 22}, {-58, 26}}, color = {191, 0, 0}));
  connect(g1.port_b, c2.port) annotation(
    Line(points = {{-34, 22}, {-32, 22}, {-32, 26}}, color = {191, 0, 0}));
  connect(HeatSource.port, c1.port) annotation(
    Line(points = {{-66, 22}, {-58, 22}, {-58, 26}}, color = {191, 0, 0}));
  connect(c3.port, g3.port_a) annotation(
    Line(points = {{-8, 26}, {-8, 22}, {-4, 22}}, color = {191, 0, 0}));
  connect(g12.port_b, g13.port_a) annotation(
    Line(points = {{26, -28}, {26, -32}}, color = {191, 0, 0}));
  connect(c9.port, g13.port_a) annotation(
    Line(points = {{16, -32}, {26, -32}}, color = {191, 0, 0}));
  connect(HeatSource1.port, c2.port) annotation(
    Line(points = {{-66, -2}, {-32, -2}, {-32, 26}}, color = {191, 0, 0}));
  connect(GND.p, TESBias.p) annotation(
    Line(points = {{-26, 56}, {-18, 56}}, color = {0, 0, 255}));
  connect(TESBias.p, RL.n) annotation(
    Line(points = {{-18, 56}, {-6, 56}}, color = {0, 0, 255}));
  connect(L.p, RL.p) annotation(
    Line(points = {{-4, 68}, {-6, 68}}, color = {0, 0, 255}));
  connect(RL.p, TESBias.n) annotation(
    Line(points = {{-6, 68}, {-18, 68}}, color = {0, 0, 255}));
  connect(L.n, c10.p) annotation(
    Line(points = {{8, 68}, {52, 68}, {52, 54}}, color = {0, 0, 255}));
  connect(g2.port_a, c2.port) annotation(
    Line(points = {{-28, 22}, {-32, 22}, {-32, 26}}, color = {191, 0, 0}));
  connect(g4.port_a, g3.port_b) annotation(
    Line(points = {{26, 22}, {16, 22}}, color = {191, 0, 0}));
  connect(g3.port_b, c4.port) annotation(
    Line(points = {{16, 22}, {26, 22}, {26, 26}}, color = {191, 0, 0}));
  connect(c10.heatPort, g4.port_b) annotation(
    Line(points = {{46, 34}, {46, 22}}, color = {191, 0, 0}));
  connect(g12.port_a, g5.port_b) annotation(
    Line(points = {{26, -8}, {26, -4}}, color = {191, 0, 0}));
  connect(g5.port_b, g6.port_b) annotation(
    Line(points = {{26, -4}, {46, -4}}, color = {191, 0, 0}));
  connect(c5.port, g6.port_b) annotation(
    Line(points = {{68, -4}, {46, -4}}, color = {191, 0, 0}));
  connect(g5.port_a, g4.port_a) annotation(
    Line(points = {{26, 16}, {26, 22}}, color = {191, 0, 0}));
  connect(g6.port_a, g4.port_b) annotation(
    Line(points = {{46, 16}, {46, 22}}, color = {191, 0, 0}));
  connect(g4.port_b, g7.port_a) annotation(
    Line(points = {{46, 22}, {50, 22}}, color = {191, 0, 0}));
  connect(c6.port, g7.port_b) annotation(
    Line(points = {{70, 26}, {70, 22}}, color = {191, 0, 0}));
  connect(g8.port_a, g7.port_b) annotation(
    Line(points = {{74, 22}, {70, 22}}, color = {191, 0, 0}));
  connect(c7.port, g8.port_b) annotation(
    Line(points = {{94, 26}, {94, 22}}, color = {191, 0, 0}));
  connect(g13.port_b, g14.port_b) annotation(
    Line(points = {{26, -52}, {-58, -52}, {-58, -44}}, color = {191, 0, 0}));
  connect(fixedTemperature.port, g14.port_b) annotation(
    Line(points = {{-68, -52}, {-58, -52}, {-58, -44}}, color = {191, 0, 0}));
  connect(c10.n, RL.n) annotation(
    Line(points = {{40, 54}, {40, 56}, {-6, 56}}, color = {0, 0, 255}));
  connect(g11.port_a, g8.port_b) annotation(
    Line(points = {{94, 16}, {94, 22}}, color = {191, 0, 0}));
  connect(g11.port_b, c5.port) annotation(
    Line(points = {{94, -4}, {68, -4}}, color = {191, 0, 0}));
  connect(g9.port_a, g8.port_b) annotation(
    Line(points = {{108, -6}, {108, 22}, {94, 22}}, color = {191, 0, 0}));
  connect(g10.port_a, g9.port_b) annotation(
    Line(points = {{108, -32}, {108, -26}}, color = {191, 0, 0}));
  connect(c8.port, g10.port_a) annotation(
    Line(points = {{100, -30}, {108, -30}, {108, -32}}, color = {191, 0, 0}));
  connect(g10.port_b, g13.port_b) annotation(
    Line(points = {{108, -52}, {26, -52}}, color = {191, 0, 0}));
  connect(edep_target.y, HeatSource.Q_flow) annotation(
    Line(points = {{-84, 22}, {-78, 22}}, color = {0, 0, 127}));
  connect(edep_film.y, HeatSource1.Q_flow) annotation(
    Line(points = {{-84, -2}, {-78, -2}}, color = {0, 0, 127}));
  annotation(
    uses(Modelica(version = "4.1.0")),
    Diagram(graphics = {Text(origin = {-59, -54}, extent = {{-5, 4}, {5, -4}}, textString = "0", textStyle = {TextStyle.Bold}), Line(origin = {71, 22}, points = {{-100, 0}, {37, 0}, {37, -75}}, color = {255, 170, 0}, thickness = 2), Rectangle(origin = {58, 24}, fillColor = {232, 232, 232}, pattern = LinePattern.DashDot, lineThickness = 0.5, extent = {{-44, 30}, {44, -30}}), Text(origin = {-30, 46}, extent = {{-10, 4}, {10, -4}}, textString = "GoldPad(Target)"), Text(origin = {-6, 46}, extent = {{-8, 2}, {8, -2}}, textString = "WireBond1"), Text(origin = {25, 47}, extent = {{-9, 3}, {9, -3}}, textString = "GoldPad(TES1)
+bondpad1"), Text(origin = {71, 47}, extent = {{-9, 3}, {9, -3}}, textString = "GoldPad(TES2)"), Text(origin = {95, 47}, extent = {{-9, 3}, {9, -3}}, textString = "Meander
+bondpad2"), Text(origin = {7, -21}, extent = {{-9, 3}, {9, -3}}, textString = "Glue"), Text(origin = {91, -19}, extent = {{-9, 3}, {9, -3}}, textString = "WireBond2"), Text(origin = {-57, 46}, extent = {{-7, 2}, {7, -2}}, textString = "Target", textStyle = {TextStyle.Bold}), Text(origin = {46, 59}, extent = {{-8, 3}, {8, -3}}, textString = "TES", textStyle = {TextStyle.Bold}), Text(origin = {-8, 16}, extent = {{-8, 2}, {8, -2}}, textString = "K2=K3"), Text(origin = {112, -30}, rotation = -90, extent = {{-8, 2}, {8, -2}}, textString = "K9=K10")}, coordinateSystem(extent = {{-100, -100}, {120, 100}})),
    Icon(coordinateSystem(extent = {{-100, -100}, {120, 100}})),
    version = "",
    experiment(StartTime = 0, StopTime = 0.1, Tolerance = 0.5e-07, Interval = 1e-06),
    __OpenModelica_commandLineOptions = "--matchingAlgorithm=PFPlusExt --indexReductionMethod=dynamicStateSelection -d=initialization,NLSanalyticJacobian -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts",
    __OpenModelica_simulationFlags(lv = "LOG_STDOUT,LOG_ASSERT,LOG_STATS", s = "dassl", variableFilter = ".*"));
end System_LMO;
