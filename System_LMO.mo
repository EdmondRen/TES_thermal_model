model System_LMO
  Modelica.Thermal.HeatTransfer.Sources.FixedTemperature fixedTemperature(T(displayUnit = "mK") = 0.012) annotation(
    Placement(transformation(origin = {-76, -52}, extent = {{-8, -8}, {8, 8}})));
  Modelica.Thermal.HeatTransfer.Sources.PrescribedHeatFlow HeatSource(T_ref(displayUnit = "K") = 0.1) annotation(
    Placement(transformation(origin = {-72, 22}, extent = {{-6, -6}, {6, 6}})));
  Modelica.Thermal.HeatTransfer.Sources.PrescribedHeatFlow HeatSource1(T_ref(displayUnit = "K") = 0.1) annotation(
    Placement(transformation(origin = {-72, -2}, extent = {{-6, -6}, {6, 6}})));
  libTES.TES2 tes(Rn = TES_Rn, T(start = TES_Tinit), Tc = TES_Tc, a1 = TES_a1, a3 = TES_a3, alpha0 = TES_alpha, m = TES_m) annotation(
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
  libTES.HeatCapacitorPoly target(m = m1, a1 = a1_target, a3 = a3_target, a5 = a5_target, T(start = TES_Tinit)) annotation(
    Placement(transformation(origin = {-58, 36}, extent = {{-10, -10}, {10, 10}})));
  libTES.HeatCapacitorPoly goldPadTarget(m = m2, a1 = a1_gold, a3 = a3_gold, a5 = a5_gold, T(start = TES_Tinit)) annotation(
    Placement(transformation(origin = {-32, 36}, extent = {{-10, -10}, {10, 10}})));
  libTES.HeatCapacitorPoly wireBond1(m = m3, a1 = a1_gold, a3 = a3_gold, a5 = a5_gold, T(start = TES_Tinit)) annotation(
    Placement(transformation(origin = {-8, 36}, extent = {{-10, -10}, {10, 10}})));
  libTES.HeatCapacitorPoly goldPadTES1(m = m4, a1 = a1_gold, a3 = a3_gold, a5 = a5_gold, T(start = TES_Tinit)) annotation(
    Placement(transformation(origin = {26, 36}, extent = {{-10, -10}, {10, 10}})));
  libTES.HeatCapacitorPoly goldPadTES2(m = m6, a1 = a1_gold, a3 = a3_gold, a5 = a5_gold, T(start = TES_Tinit)) annotation(
    Placement(transformation(origin = {70, 36}, extent = {{-10, -10}, {10, 10}})));
  libTES.HeatCapacitorPoly silicon(m = m5, a1 = a1_silicon, a3 = a3_silicon, a5 = a5_silicon, T(start = TES_Tinit)) annotation(
    Placement(transformation(origin = {68, 6}, extent = {{-10, -10}, {10, 10}})));
  libTES.HeatCapacitorPoly meander(m = m7, a1 = a1_gold, a3 = a3_gold, a5 = a5_gold, T(start = TES_Tinit)) annotation(
    Placement(transformation(origin = {94, 36}, extent = {{-10, -10}, {10, 10}})));
  libTES.HeatCapacitorPoly glue(m = m9, a1 = a1_glue, a3 = a3_glue, a5 = a5_glue, T(start = TES_Tinit)) annotation(
    Placement(transformation(origin = {6, -32}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
  libTES.HeatCapacitorPoly wireBond2(m = m8, a1 = a1_gold, a3 = a3_gold, a5 = a5_gold, T(start = TES_Tinit)) annotation(
    Placement(transformation(origin = {92, -30}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
  Modelica.Electrical.Analog.Basic.Resistor RL(R(displayUnit = "mOhm") = Bias_R) annotation(
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
  //  - Exitation
  parameter Real Edep = 200000 "[eV], energy deposition";
  parameter Real Edep_time = 1.00e-7 "[s], time for energy deposition";
  parameter Real Edep_fractiontarget = 0.2 "Fraction of energy in target";
  parameter Real Edep_falltimetarget = 0.3e-3 "Phonon thermalization time constant in target";
  parameter Real Edep_falltimefilm = 0.3e-3 "Phonon thermalization time constant in film";
  parameter Modelica.Units.SI.Time Edep_starttime = 10e-3 "Start time of energy deposition";
  //  - Electrical, bias
  parameter Modelica.Units.SI.Current Bias_I = 36.1e-6 "Bias current";
  parameter Modelica.Units.SI.Resistance Bias_R = 2.00e-2 "Load resistance (Rsh+Rp)";
  parameter Modelica.Units.SI.Inductance Bias_L = 3.00e-7 "Bias circuit indutance";
  //  - Electrical, TES
  parameter Modelica.Units.SI.Resistance TES_Rn = 0.175 "TES normal resistance";
  parameter Modelica.Units.SI.Temperature TES_Tc = 0.021 "TES critical temp.";
  parameter Modelica.Units.SI.Temperature TES_Tinit = 0.021 "Initial guess of TES temperature";
  parameter Real TES_alpha = 20 "TES alpha";
  parameter Modelica.Units.SI.Mass TES_m = 6.53e-12 "TES mass";
  parameter Real TES_a1 = 5.00e-2 "TES heat capacity linear term";
  parameter Real TES_a3 = 9.24e-4 "TES heat capacity cubic term";
  //  - Thermal, conductance
  parameter Real K1 = 1.16e-1   "Absorber -> Goldpad";
  parameter Real K2 = 8.80e-6   "Goldpad -> Goldwirebond";
  parameter Real K3 = 8.80e-6   "Goldwirebond -> Goldpad(TES1)";
  parameter Real K4 = 0.1e-7    "Goldpad(TES1) -> TES Electron System";
  parameter Real K5 = 7.99e-5*2000 "Goldpad(TES1) -> Si chip"; //
  parameter Real K6 = 1.08e-5*5 "Si chip -> TES, electron-phonon coupling";
  parameter Real K7 = 0.1e-7    "TES -> Goldpad(TES2)";
  parameter Real K8 = 6.8e-8*0.1 "Goldpad(TES2) -> Meander";
  parameter Real K9 = 5.64e-5   "Meander -> WireBond2";
  parameter Real K10 = 5.64e-5  "WireBond2 -> bath";
  parameter Real K11 = 1.45e-4*10 " Meander -> Si chip";
  parameter Real K12 = 2.70e-6*4000 "Si chip -> Glue";
  parameter Real K13 = 2.70e-6*4000 "Glue -> bath";
  parameter Real K14 = 7.84e-8 "Absorber -> bath";
  //  - Thermal, heat capacity
  parameter Modelica.Units.SI.Mass m1 = 2.46e-2 "Absorber mass";
  parameter Modelica.Units.SI.Mass m2 = 6.07e-7 "Gold (target gold pad)";
  parameter Modelica.Units.SI.Mass m3 = 3.03e-8 "Gold (WireBond1)";
  parameter Modelica.Units.SI.Mass m4 = 4.17e-10 "Gold (GoldPad2)";
  parameter Modelica.Units.SI.Mass m5 = 8.38e-6 "Silicon chip";
  parameter Modelica.Units.SI.Mass m6 = 3.97e-12 "Gold (GoldPadTES)";
  parameter Modelica.Units.SI.Mass m7 = 7.59e-10 "Gold (Meander)";
  parameter Modelica.Units.SI.Mass m8 = 4.73e-9 "Gold (WireBond2)";
  parameter Modelica.Units.SI.Mass m9 = 2.67e-9 "Glue";
  parameter Real a1_target = 6.95e-7;
  parameter Real a3_target = 2.18e-6;
  parameter Real a5_target = 0;
  parameter Real a1_gold = 8.86e-3;
  parameter Real a3_gold = 5.58e-3;
  parameter Real a5_gold = 0;
  parameter Real a1_silicon = 0;
  parameter Real a3_silicon = 2.70e-4;
  parameter Real a5_silicon = 0;
  parameter Real a1_glue = 6.50e-3;
  parameter Real a3_glue = 1.90e-2;
  parameter Real a5_glue = 0;
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
  C1 = target.C;
  C2 = goldPadTarget.C;
  C3 = wireBond1.C;
  C4 = goldPadTES1.C;
  C5 = silicon.C;
  C6 = goldPadTES2.C;
  C7 = meander.C;
  C8 = wireBond2.C;
  C9 = glue.C;
  C10 = tes.C;
  T1 = target.T;
  T2 = goldPadTarget.T;
  T3 = wireBond1.T;
  T4 = goldPadTES1.T;
  T5 = silicon.T;
  T6 = goldPadTES2.T;
  T7 = meander.T;
  T8 = wireBond2.T;
  T9 = glue.T;
  T10 = tes.T;
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
  connect(wireBond1.port, g2.port_b) annotation(
    Line(points = {{-8, 26}, {-8, 22}}, color = {191, 0, 0}));
  connect(g14.port_a, target.port) annotation(
    Line(points = {{-58, -24}, {-58, 26}}, color = {191, 0, 0}));
  connect(g1.port_a, target.port) annotation(
    Line(points = {{-54, 22}, {-58, 22}, {-58, 26}}, color = {191, 0, 0}));
  connect(g1.port_b, goldPadTarget.port) annotation(
    Line(points = {{-34, 22}, {-32, 22}, {-32, 26}}, color = {191, 0, 0}));
  connect(HeatSource.port, target.port) annotation(
    Line(points = {{-66, 22}, {-58, 22}, {-58, 26}}, color = {191, 0, 0}));
  connect(wireBond1.port, g3.port_a) annotation(
    Line(points = {{-8, 26}, {-8, 22}, {-4, 22}}, color = {191, 0, 0}));
  connect(g12.port_b, g13.port_a) annotation(
    Line(points = {{26, -28}, {26, -32}}, color = {191, 0, 0}));
  connect(glue.port, g13.port_a) annotation(
    Line(points = {{16, -32}, {26, -32}}, color = {191, 0, 0}));
  connect(HeatSource1.port, goldPadTarget.port) annotation(
    Line(points = {{-66, -2}, {-32, -2}, {-32, 26}}, color = {191, 0, 0}));
  connect(GND.p, TESBias.p) annotation(
    Line(points = {{-26, 56}, {-18, 56}}, color = {0, 0, 255}));
  connect(TESBias.p, RL.n) annotation(
    Line(points = {{-18, 56}, {-6, 56}}, color = {0, 0, 255}));
  connect(L.p, RL.p) annotation(
    Line(points = {{-4, 68}, {-6, 68}}, color = {0, 0, 255}));
  connect(RL.p, TESBias.n) annotation(
    Line(points = {{-6, 68}, {-18, 68}}, color = {0, 0, 255}));
  connect(L.n, tes.p) annotation(
    Line(points = {{8, 68}, {52, 68}, {52, 54}}, color = {0, 0, 255}));
  connect(g2.port_a, goldPadTarget.port) annotation(
    Line(points = {{-28, 22}, {-32, 22}, {-32, 26}}, color = {191, 0, 0}));
  connect(g4.port_a, g3.port_b) annotation(
    Line(points = {{26, 22}, {16, 22}}, color = {191, 0, 0}));
  connect(g3.port_b, goldPadTES1.port) annotation(
    Line(points = {{16, 22}, {26, 22}, {26, 26}}, color = {191, 0, 0}));
  connect(tes.heatPort, g4.port_b) annotation(
    Line(points = {{46, 34}, {46, 22}}, color = {191, 0, 0}));
  connect(g12.port_a, g5.port_b) annotation(
    Line(points = {{26, -8}, {26, -4}}, color = {191, 0, 0}));
  connect(g5.port_b, g6.port_b) annotation(
    Line(points = {{26, -4}, {46, -4}}, color = {191, 0, 0}));
  connect(silicon.port, g6.port_b) annotation(
    Line(points = {{68, -4}, {46, -4}}, color = {191, 0, 0}));
  connect(g5.port_a, g4.port_a) annotation(
    Line(points = {{26, 16}, {26, 22}}, color = {191, 0, 0}));
  connect(g6.port_a, g4.port_b) annotation(
    Line(points = {{46, 16}, {46, 22}}, color = {191, 0, 0}));
  connect(g4.port_b, g7.port_a) annotation(
    Line(points = {{46, 22}, {50, 22}}, color = {191, 0, 0}));
  connect(goldPadTES2.port, g7.port_b) annotation(
    Line(points = {{70, 26}, {70, 22}}, color = {191, 0, 0}));
  connect(g8.port_a, g7.port_b) annotation(
    Line(points = {{74, 22}, {70, 22}}, color = {191, 0, 0}));
  connect(meander.port, g8.port_b) annotation(
    Line(points = {{94, 26}, {94, 22}}, color = {191, 0, 0}));
  connect(g13.port_b, g14.port_b) annotation(
    Line(points = {{26, -52}, {-58, -52}, {-58, -44}}, color = {191, 0, 0}));
  connect(fixedTemperature.port, g14.port_b) annotation(
    Line(points = {{-68, -52}, {-58, -52}, {-58, -44}}, color = {191, 0, 0}));
  connect(tes.n, RL.n) annotation(
    Line(points = {{40, 54}, {40, 56}, {-6, 56}}, color = {0, 0, 255}));
  connect(g11.port_a, g8.port_b) annotation(
    Line(points = {{94, 16}, {94, 22}}, color = {191, 0, 0}));
  connect(g11.port_b, silicon.port) annotation(
    Line(points = {{94, -4}, {68, -4}}, color = {191, 0, 0}));
  connect(g9.port_a, g8.port_b) annotation(
    Line(points = {{108, -6}, {108, 22}, {94, 22}}, color = {191, 0, 0}));
  connect(g10.port_a, g9.port_b) annotation(
    Line(points = {{108, -32}, {108, -26}}, color = {191, 0, 0}));
  connect(wireBond2.port, g10.port_a) annotation(
    Line(points = {{102, -30}, {108, -30}, {108, -32}}, color = {191, 0, 0}));
  connect(g10.port_b, g13.port_b) annotation(
    Line(points = {{108, -52}, {26, -52}}, color = {191, 0, 0}));
  connect(edep_target.y, HeatSource.Q_flow) annotation(
    Line(points = {{-84, 22}, {-78, 22}}, color = {0, 0, 127}));
  connect(edep_film.y, HeatSource1.Q_flow) annotation(
    Line(points = {{-84, -2}, {-78, -2}}, color = {0, 0, 127}));
  annotation(
    uses(Modelica(version = "4.1.0")),
    Diagram(graphics = {Text(origin = {-60, 19}, rotation = 180, extent = {{-3, 2}, {3, -2}}, textString = "1", textStyle = {TextStyle.Bold}), Text(origin = {-30, 19}, extent = {{-4, 2}, {4, -2}}, textString = "2", textStyle = {TextStyle.Bold}), Text(origin = {-8, 19}, extent = {{-4, 2}, {4, -2}}, textString = "3", textStyle = {TextStyle.Bold}), Text(origin = {19, 17}, extent = {{-3, 3}, {3, -3}}, textString = "4", textStyle = {TextStyle.Bold}), Text(origin = {68, -9}, extent = {{-4, 3}, {4, -3}}, textString = "5", textStyle = {TextStyle.Bold}), Text(origin = {-59, -54}, extent = {{-5, 4}, {5, -4}}, textString = "0", textStyle = {TextStyle.Bold}), Text(origin = {99, 26}, extent = {{-3, 2}, {3, -2}}, textString = "7", textStyle = {TextStyle.Bold}), Text(origin = {112, -26}, extent = {{-4, 2}, {4, -2}}, textString = "8", textStyle = {TextStyle.Bold}), Text(origin = {21, -30}, extent = {{-3, 2}, {3, -2}}, textString = "9", textStyle = {TextStyle.Bold}), Line(origin = {71, 22}, points = {{-100, 0}, {37, 0}, {37, -75}}, color = {255, 170, 0}, thickness = 2), Text(origin = {72, 17}, extent = {{-4, 3}, {4, -3}}, textString = "6", textStyle = {TextStyle.Bold}), Text(origin = {51, 17}, extent = {{-5, 3}, {5, -3}}, textString = "10", textStyle = {TextStyle.Bold}), Rectangle(origin = {58, 24}, fillColor = {232, 232, 232}, pattern = LinePattern.DashDot, lineThickness = 0.5, extent = {{-44, 30}, {44, -30}})}, coordinateSystem(extent = {{-100, -100}, {120, 100}})),
    Icon(coordinateSystem(extent = {{-100, -100}, {120, 100}})),
    version = "",
    experiment(StartTime = 0, StopTime = 0.1, Tolerance = 0.5e-07, Interval = 1e-06),
    __OpenModelica_commandLineOptions = "--matchingAlgorithm=PFPlusExt --indexReductionMethod=dynamicStateSelection -d=initialization,NLSanalyticJacobian -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts",
    __OpenModelica_simulationFlags(lv = "LOG_STDOUT,LOG_ASSERT,LOG_STATS", s = "dassl", variableFilter = ".*"));
end System_LMO;
