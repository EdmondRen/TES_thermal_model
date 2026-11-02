model System_LMO_v1
  Modelica.Thermal.HeatTransfer.Sources.FixedTemperature fixedTemperature(T(displayUnit = "mK") = 0.012) annotation(
    Placement(transformation(origin = {-82, -54}, extent = {{-6, -6}, {6, 6}})));
  Modelica.Thermal.HeatTransfer.Sources.PrescribedHeatFlow HeatSource(T_ref(displayUnit = "K") = 0.1) annotation(
    Placement(transformation(origin = {-74, 22}, extent = {{-4, -4}, {4, 4}})));
  Modelica.Thermal.HeatTransfer.Sources.PrescribedHeatFlow HeatSource1(T_ref(displayUnit = "K") = 0.1) annotation(
    Placement(transformation(origin = {-74, -2}, extent = {{-4, -4}, {4, 4}})));
  libTES.TES2 c1(Rn = TES_Rn, T(start = TES_Tinit), Tc = TES_Tc, a1 = TES_a1, a3 = TES_a3, alpha0 = TES_alpha, beta0 = TES_beta, I0 = TES_I0, m = TES_m) annotation(
    Placement(transformation(origin = {28, 44}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  libTES.ThermlConductanceN g1(K = K1, n = 5) annotation(
    Placement(transformation(origin = {-56, 22}, extent = {{-8, -8}, {8, 8}})));
  libTES.ThermlConductanceN g2(K = K2, n = 2) annotation(
    Placement(transformation(origin = {-32, 22}, extent = {{-8, -8}, {8, 8}})));
  libTES.ThermlConductanceN g3(K = K3, n = 2) annotation(
    Placement(transformation(origin = {-10, 22}, extent = {{-8, -8}, {8, 8}})));
  libTES.ThermlConductanceN g12(K = K12, n = 4) annotation(
    Placement(transformation(origin = {10, -20}, extent = {{-8, -8}, {8, 8}}, rotation = -90)));
  libTES.ThermlConductanceN g13(K = K13, n = 4) annotation(
    Placement(transformation(origin = {10, -46}, extent = {{-8, -8}, {8, 8}}, rotation = -90)));
  libTES.ThermlConductanceN g14(K = K14, n = 4) annotation(
    Placement(transformation(origin = {-66, -34}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  libTES.HeatCapacitorPoly c11(m = m11, a1 = 0, a3 = a3_gold, a5 = 0, T(start = TES_Tinit)) annotation(
    Placement(transformation(origin = {-32, 2}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
  libTES.HeatCapacitorPoly c10(m = m10, a1 = a1_target, a3 = a3_target, a5 = a5_target, T(start = TES_Tinit)) annotation(
    Placement(transformation(origin = {-66, 36}, extent = {{-10, -10}, {10, 10}})));
  libTES.HeatCapacitorPoly c2(m = m2, a1 = a1_gold, a3 = a3_gold, a5 = a5_gold, T(start = TES_Tinit)) annotation(
    Placement(transformation(origin = {-46, 36}, extent = {{-10, -10}, {10, 10}})));
  libTES.HeatCapacitorPoly c3(m = m3, a1 = a1_gold, a3 = a3_gold, a5 = a5_gold, T(start = TES_Tinit)) annotation(
    Placement(transformation(origin = {-20, 36}, extent = {{-10, -10}, {10, 10}})));
  libTES.HeatCapacitorPoly c4(m = m4, a1 = a1_gold, a3 = a3_gold, a5 = a5_gold, T(start = TES_Tinit)) annotation(
    Placement(transformation(origin = {10, 36}, extent = {{-10, -10}, {10, 10}})));
  libTES.HeatCapacitorPoly c6(m = m6, a1 = a1_gold, a3 = a3_gold, a5 = a5_gold, T(start = TES_Tinit)) annotation(
    Placement(transformation(origin = {46, 36}, extent = {{-10, -10}, {10, 10}})));
  libTES.HeatCapacitorPoly c5(m = m5, a1 = a1_silicon, a3 = a3_silicon, a5 = a5_silicon, T(start = TES_Tinit)) annotation(
    Placement(transformation(origin = {39, 3}, extent = {{-7, -7}, {7, 7}})));
  libTES.HeatCapacitorPoly c7(m = m7, a1 = a1_gold, a3 = a3_gold, a5 = a5_gold, T(start = TES_Tinit)) annotation(
    Placement(transformation(origin = {68, 36}, extent = {{-10, -10}, {10, 10}})));
  libTES.HeatCapacitorPoly c9(m = m9, a1 = a1_glue, a3 = a3_glue, a5 = a5_glue, T(start = TES_Tinit)) annotation(
    Placement(transformation(origin = {-2, -34}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
  libTES.HeatCapacitorPoly c8(m = m8, a1 = a1_gold, a3 = a3_gold, a5 = a5_gold, T(start = TES_Tinit)) annotation(
    Placement(transformation(origin = {72, -18}, extent = {{-8, -8}, {8, 8}}, rotation = 90)));
  Modelica.Electrical.Analog.Basic.Resistor RL(R(displayUnit = "mOhm") = Bias_R, useHeatPort = false) annotation(
    Placement(transformation(origin = {-28, 62}, extent = {{-6, -6}, {6, 6}}, rotation = -90)));
  Modelica.Electrical.Analog.Basic.Ground GND annotation(
    Placement(transformation(origin = {-54, 56}, extent = {{-6, -6}, {6, 6}}, rotation = -90)));
  Modelica.Electrical.Analog.Basic.Inductor L(L = Bias_L, i(start = Bias_I*0.3)) annotation(
    Placement(transformation(origin = {12, 68}, extent = {{-6, -6}, {6, 6}})));
  Modelica.Electrical.Analog.Sources.ConstantCurrent TESBias(I = Bias_I) annotation(
    Placement(transformation(origin = {-40, 62}, extent = {{-6, -6}, {6, 6}}, rotation = 90)));
  libTES.ThermlConductanceN g4(K = K4, n = 2) annotation(
    Placement(transformation(origin = {20, 22}, extent = {{-8, -8}, {8, 8}})));
  libTES.ThermlConductanceN g5(K = K5, n = 5) annotation(
    Placement(transformation(origin = {10, 4}, extent = {{-8, -8}, {8, 8}}, rotation = -90)));
  libTES.ThermlConductanceN g6(K = K6, n = 6) annotation(
    Placement(transformation(origin = {28, 4}, extent = {{-8, -8}, {8, 8}}, rotation = -90)));
  libTES.ThermlConductanceN g7(K = K7, n = 2) annotation(
    Placement(transformation(origin = {38, 22}, extent = {{-8, -8}, {8, 8}})));
  libTES.ThermlConductanceN g8(K = K8, n = 2) annotation(
    Placement(transformation(origin = {60, 22}, extent = {{-8, -8}, {8, 8}})));
  libTES.ThermlConductanceN g11(K = K11, n = 5) annotation(
    Placement(transformation(origin = {68, 4}, extent = {{-8, -8}, {8, 8}}, rotation = -90)));
  libTES.ThermlConductanceN g10(K = K10, n = 2) annotation(
    Placement(transformation(origin = {88, -36}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  libTES.ThermlConductanceN g9(K = K9, n = 2) annotation(
    Placement(transformation(origin = {88, 2}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  libTES.ThermlConductanceN g15(K = K15, n = 5) annotation(
    Placement(transformation(origin = {-10, 8}, extent = {{8, -8}, {-8, 8}})));
  libTES.ThermlConductanceN g16(K = K16, n = 4) annotation(
    Placement(transformation(origin = {-10, -4}, extent = {{-8, -8}, {8, 8}})));
  // Parameters
  // IMPORTANT: The parameters below are set to Evaluate=false to avoid them being evaluated during compilation. This is necessary because the model is compiled before the parameters are set in the simulation script.
  //  - Exitation
  parameter Real Edep = 200000 "[eV], energy deposition" annotation(Evaluate = false);
  parameter Real Edep_time = 1.00e-7 "[s], time for energy deposition" annotation(Evaluate = false);
  parameter Real Edep_fractiontarget = 0.2 "Fraction of energy in target" annotation(Evaluate = false);
  parameter Real Edep_falltimetarget = 0.3e-3 "Phonon thermalization time constant in target" annotation(Evaluate = false);
  parameter Real Edep_falltimefilm = 0.3e-3 "Phonon thermalization time constant in film" annotation(Evaluate = false);
  parameter Modelica.Units.SI.Time Edep_starttime = 10e-3 "Start time of energy deposition" annotation(Evaluate = false);
  //  - Electrical, bias
  parameter Modelica.Units.SI.Current Bias_I = 36.1e-6 "Bias current" annotation(Evaluate = false);
  parameter Modelica.Units.SI.Resistance Bias_R = 2.00e-2 "Load resistance (Rsh+Rp)" annotation(Evaluate = false);
  parameter Modelica.Units.SI.Resistance Bias_Rp = 1.50e-2 "Load resistance (Rp)" annotation(Evaluate=false);  
  parameter Modelica.Units.SI.Inductance Bias_L = 3.00e-7 "Bias circuit indutance" annotation(Evaluate = false);
  parameter Modelica.Units.SI.Capacitance Bias_C = 20e-12 "Bias circuit capacitance" annotation(Evaluate = false);
  //  - Electrical, TES
  parameter Modelica.Units.SI.Resistance TES_Rn = 0.175 "TES normal resistance" annotation(Evaluate = false);
  parameter Modelica.Units.SI.Temperature TES_Tc = 0.021 "TES critical temp." annotation(Evaluate = false);
  parameter Modelica.Units.SI.Temperature TES_Tinit = 0.021 "Initial guess of TES temperature" annotation(Evaluate = false);
  parameter Real TES_alpha = 20 "TES alpha" annotation(Evaluate = false);
  parameter Real TES_beta = 1 "TES beta" annotation(Evaluate = false);
  parameter Modelica.Units.SI.Current TES_I0 = 5e-6 "TES Current where beta is evaluated" annotation(Evaluate = false);
  parameter Modelica.Units.SI.Mass TES_m = 6.53e-12 "TES mass" annotation(Evaluate = false);
  parameter Real TES_a1 = 5.00e-2 "TES heat capacity linear term" annotation(Evaluate = false);
  parameter Real TES_a3 = 9.24e-4 "TES heat capacity cubic term" annotation(Evaluate = false);
  //  - Thermal, conductance
  parameter Real K1 = 1.16e-1 "Absorber -> Goldpad" annotation(Evaluate = false);
  parameter Real K2 = 8.80e-6 "Goldpad -> Goldwirebond" annotation(Evaluate = false);
  parameter Real K3 = 8.80e-6 "Goldwirebond -> Goldpad(TES1)" annotation(Evaluate = false);
  parameter Real K4 = 0.1e-7 "Goldpad(TES1) -> TES Electron System" annotation(Evaluate = false);
  parameter Real K5 = 7.99e-5*2000 "Goldpad(TES1) -> Si chip" annotation(Evaluate = false);
  parameter Real K6 = 1.08e-5 "Si chip -> TES, electron-phonon coupling" annotation(Evaluate = false);
  parameter Real K7 = 0.1e-7 "TES -> Goldpad(TES2)" annotation(Evaluate = false);
  parameter Real K8 = 6.8e-8 "Goldpad(TES2) -> Meander" annotation(Evaluate = false);
  parameter Real K9 = 5.64e-5 "Meander -> WireBond2" annotation(Evaluate = false);
  parameter Real K10 = 5.64e-5 "WireBond2 -> bath" annotation(Evaluate = false);
  parameter Real K11 = 1.45e-4 " Meander -> Si chip" annotation(Evaluate = false);
  parameter Real K12 = 2.70e-6*4000 "Si chip -> Glue" annotation(Evaluate = false);
  parameter Real K13 = 2.70e-6*4000 "Glue -> bath" annotation(Evaluate = false);
  parameter Real K14 = 7.84e-8 "Absorber -> bath" annotation(Evaluate = false);
  parameter Real K15 = 7.84e-8 "Gold e-ph in wirebond" annotation(Evaluate = false);
  parameter Real K16 = 7.84e-8 "Gold Kapitza between wirebond -> Si chip" annotation(Evaluate = false);
  parameter Real K17 = 7.84e-8 "Stycast bulk" annotation(Evaluate = false);
  parameter Real K18 = 7.84e-8 "Copper-Stycast boundary" annotation(Evaluate = false);        
  //  - Thermal, heat capacity
  parameter Modelica.Units.SI.Mass m2 = 6.07e-7 "Gold (target gold pad)" annotation(Evaluate = false);
  parameter Modelica.Units.SI.Mass m3 = 3.03e-8 "Gold (WireBond1)" annotation(Evaluate = false);
  parameter Modelica.Units.SI.Mass m4 = 4.17e-10 "Gold (GoldPad2)" annotation(Evaluate = false);
  parameter Modelica.Units.SI.Mass m5 = 8.38e-6 "Silicon chip" annotation(Evaluate = false);
  parameter Modelica.Units.SI.Mass m6 = 3.97e-12 "Gold (GoldPadTES)" annotation(Evaluate = false);
  parameter Modelica.Units.SI.Mass m7 = 7.59e-10 "Gold (Meander)" annotation(Evaluate = false);
  parameter Modelica.Units.SI.Mass m8 = 4.73e-9 "Gold (WireBond2)" annotation(Evaluate = false);
  parameter Modelica.Units.SI.Mass m9 = 2.67e-9 "Glue" annotation(Evaluate = false);
  parameter Modelica.Units.SI.Mass m10 = 2.46e-2 "Absorber mass" annotation(Evaluate = false);
  parameter Modelica.Units.SI.Mass m11 = 2.46e-2 "Gold (target gold pad) + wire bond 1" annotation(Evaluate = false);
  parameter Modelica.Units.SI.Mass m12 = 2.67e-9 "Glue" annotation(Evaluate = false);
  parameter Modelica.Units.SI.Mass m13 = 2.67e-9 "Glue" annotation(Evaluate = false);    
  parameter Real a1_target = 6.95e-7 annotation(Evaluate = false);
  parameter Real a3_target = 2.18e-6 annotation(Evaluate = false);
  parameter Real a5_target = 0 annotation(Evaluate = false);
  parameter Real a1_gold = 8.86e-3 annotation(Evaluate = false);
  parameter Real a3_gold = 5.58e-3 annotation(Evaluate = false);
  parameter Real a5_gold = 0 annotation(Evaluate = false);
  parameter Real a1_silicon = 0 annotation(Evaluate = false);
  parameter Real a3_silicon = 2.70e-4 annotation(Evaluate = false);
  parameter Real a5_silicon = 0 annotation(Evaluate = false);
  parameter Real a1_glue = 6.50e-3 annotation(Evaluate = false);
  parameter Real a3_glue = 1.90e-2 annotation(Evaluate = false);
  parameter Real a5_glue = 0 annotation(Evaluate = false);
  parameter Real a1_stycast1266 = 2.91e-3 annotation(Evaluate = false);
  parameter Real a3_stycast1266 = 1.57e-2 annotation(Evaluate = false);
  parameter Real a5_stycast1266 = 8.98e-3 annotation(Evaluate = false);
  parameter Real a1_copper = 1.11e-2 annotation(Evaluate = false);
  parameter Real a3_copper = 7.32e-4 annotation(Evaluate = false);
  parameter Real a5_copper = 0 annotation(Evaluate = false);


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
  Real C11;
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
  Real T11;
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
  Real G15;
  Real G16;
  libTES.SourceExp edep_target(outMax = Edep*1.6e-19*Edep_fractiontarget/Edep_falltimetarget, fallTimeConst = Edep_falltimetarget, offset = 0, startTime = Edep_starttime) annotation(
    Placement(transformation(origin = {-86, 22}, extent = {{-6, -6}, {6, 6}})));
  libTES.SourceExp edep_film(outMax = Edep*1.6e-19*(1 - Edep_fractiontarget)/Edep_falltimefilm, fallTimeConst = Edep_falltimefilm, offset = 0, startTime = Edep_starttime) annotation(
    Placement(transformation(origin = {-86, -2}, extent = {{-6, -6}, {6, 6}})));
  //  Modelica.Blocks.Sources.Pulse Pulse(amplitude = Edep*1.602e-19/Edep_time*Edep_thermalfraction, nperiod = 1, period = 1, startTime(displayUnit = "ms") = Edep_starttime, width = 100*Edep_time) annotation(
  //    Placement(transformation(origin = {-88, 22}, extent = {{-6, -6}, {6, 6}})));
  Modelica.Electrical.Analog.Basic.Capacitor CL(C = Bias_C) annotation(
    Placement(transformation(origin = {-18, 62}, extent = {{-6, -6}, {6, 6}}, rotation = -90)));
  libTES.ThermlConductanceN g17(K = K17, n = 2.9) annotation(
    Placement(transformation(origin = {28, -54}, extent = {{-8, -8}, {8, 8}}, rotation = 180)));
  libTES.HeatCapacitorPoly c12(T(start = TES_Tinit), a1 = a1_stycast1266, a3 = a3_stycast1266, a5 = a5_stycast1266, m = m12) annotation(
    Placement(transformation(origin = {36, -40}, extent = {{-8, -8}, {8, 8}})));
  libTES.HeatCapacitorPoly c13(T(start = TES_Tinit), a1 = a1_copper, a3 = a3_copper, a5 = 0, m = m13) "Copper" annotation(
    Placement(transformation(origin = {64, -40}, extent = {{-8, -8}, {8, 8}})));
  libTES.ThermlConductanceN g18(K = K18, n = 2.9) annotation(
    Placement(transformation(origin = {52, -54}, extent = {{-8, -8}, {8, 8}}, rotation = 180)));
  Modelica.Electrical.Analog.Basic.Resistor Rp(R= Bias_Rp, useHeatPort = false) annotation(
    Placement(transformation(origin = {-4, 68}, extent = {{-6, -6}, {6, 6}})));
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
  C11 = c11.C;
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
  T11 = c11.T;
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
  G15 = g15.G;
  G16 = g16.G;
  connect(c3.port, g2.port_b) annotation(
    Line(points = {{-20, 26}, {-20, 22}, {-24, 22}}, color = {191, 0, 0}));
  connect(g14.port_a, c10.port) annotation(
    Line(points = {{-66, -24}, {-66, 26}}, color = {191, 0, 0}));
  connect(g1.port_a, c10.port) annotation(
    Line(points = {{-64, 22}, {-66, 22}, {-66, 26}}, color = {191, 0, 0}));
  connect(g1.port_b, c2.port) annotation(
    Line(points = {{-48, 22}, {-46, 22}, {-46, 26}}, color = {191, 0, 0}));
  connect(HeatSource.port, c10.port) annotation(
    Line(points = {{-70, 22}, {-66, 22}, {-66, 26}}, color = {191, 0, 0}));
  connect(c3.port, g3.port_a) annotation(
    Line(points = {{-20, 26}, {-20, 22}, {-18, 22}}, color = {191, 0, 0}));
  connect(g12.port_b, g13.port_a) annotation(
    Line(points = {{10, -28}, {10, -38}}, color = {191, 0, 0}));
  connect(c9.port, g13.port_a) annotation(
    Line(points = {{8, -34}, {10, -34}, {10, -38}}, color = {191, 0, 0}));
  connect(HeatSource1.port, c2.port) annotation(
    Line(points = {{-70, -2}, {-46, -2}, {-46, 26}}, color = {191, 0, 0}));
  connect(GND.p, TESBias.p) annotation(
    Line(points = {{-48, 56}, {-40, 56}}, color = {0, 0, 255}));
  connect(TESBias.p, RL.n) annotation(
    Line(points = {{-40, 56}, {-28, 56}}, color = {0, 0, 255}));
  connect(RL.p, TESBias.n) annotation(
    Line(points = {{-28, 68}, {-40, 68}}, color = {0, 0, 255}));
  connect(L.n, c1.p) annotation(
    Line(points = {{18, 68}, {36, 68}, {36, 54}, {34, 54}}, color = {0, 0, 255}));
  connect(g2.port_a, c2.port) annotation(
    Line(points = {{-40, 22}, {-46, 22}, {-46, 26}}, color = {191, 0, 0}));
  connect(g4.port_a, g3.port_b) annotation(
    Line(points = {{12, 22}, {-2, 22}}, color = {191, 0, 0}));
  connect(g3.port_b, c4.port) annotation(
    Line(points = {{-2, 22}, {10, 22}, {10, 26}}, color = {191, 0, 0}));
  connect(c1.heatPort, g4.port_b) annotation(
    Line(points = {{28, 34}, {28, 22}}, color = {191, 0, 0}));
  connect(g12.port_a, g5.port_b) annotation(
    Line(points = {{10, -12}, {10, -4}}, color = {191, 0, 0}));
  connect(g5.port_b, g6.port_b) annotation(
    Line(points = {{10, -4}, {28, -4}}, color = {191, 0, 0}));
  connect(c5.port, g6.port_b) annotation(
    Line(points = {{39, -4}, {28, -4}}, color = {191, 0, 0}));
  connect(g6.port_a, g4.port_b) annotation(
    Line(points = {{28, 12}, {28, 22}}, color = {191, 0, 0}));
  connect(g4.port_b, g7.port_a) annotation(
    Line(points = {{28, 22}, {30, 22}}, color = {191, 0, 0}));
  connect(c6.port, g7.port_b) annotation(
    Line(points = {{46, 26}, {46, 22}}, color = {191, 0, 0}));
  connect(g8.port_a, g7.port_b) annotation(
    Line(points = {{52, 22}, {46, 22}}, color = {191, 0, 0}));
  connect(c7.port, g8.port_b) annotation(
    Line(points = {{68, 26}, {68, 22}}, color = {191, 0, 0}));
  connect(fixedTemperature.port, g14.port_b) annotation(
    Line(points = {{-76, -54}, {-66, -54}, {-66, -44}}, color = {191, 0, 0}));
  connect(c1.n, RL.n) annotation(
    Line(points = {{22, 54}, {22, 56}, {-28, 56}}, color = {0, 0, 255}));
  connect(g11.port_a, g8.port_b) annotation(
    Line(points = {{68, 12}, {68, 22}}, color = {191, 0, 0}));
  connect(g11.port_b, c5.port) annotation(
    Line(points = {{68, -4}, {39, -4}}, color = {191, 0, 0}));
  connect(g9.port_a, g8.port_b) annotation(
    Line(points = {{88, 12}, {88, 22}, {68, 22}}, color = {191, 0, 0}));
  connect(g10.port_a, g9.port_b) annotation(
    Line(points = {{88, -26}, {88, -8}}, color = {191, 0, 0}));
  connect(c8.port, g10.port_a) annotation(
    Line(points = {{80, -18}, {88, -18}, {88, -26}}, color = {191, 0, 0}));
  connect(edep_target.y, HeatSource.Q_flow) annotation(
    Line(points = {{-79.4, 22}, {-78.4, 22}}, color = {0, 0, 127}));
  connect(edep_film.y, HeatSource1.Q_flow) annotation(
    Line(points = {{-79.4, -2}, {-78.4, -2}}, color = {0, 0, 127}));
  connect(CL.p, RL.p) annotation(
    Line(points = {{-18, 68}, {-28, 68}}, color = {0, 0, 255}));
  connect(CL.n, RL.n) annotation(
    Line(points = {{-18, 56}, {-28, 56}}, color = {0, 0, 255}));
  connect(g3.port_b, g15.port_a) annotation(
    Line(points = {{-2, 22}, {-2, 8}}, color = {191, 0, 0}));
  connect(c11.port, g16.port_a) annotation(
    Line(points = {{-22, 2}, {-18, 2}, {-18, -4}}, color = {191, 0, 0}));
  connect(g16.port_b, g5.port_b) annotation(
    Line(points = {{-2, -4}, {10, -4}}, color = {191, 0, 0}));
  connect(c12.port, g17.port_a) annotation(
    Line(points = {{36, -48}, {36, -54}}, color = {191, 0, 0}));
  connect(g17.port_b, g13.port_b) annotation(
    Line(points = {{20, -54}, {10, -54}}, color = {191, 0, 0}));
  connect(g13.port_b, fixedTemperature.port) annotation(
    Line(points = {{10, -54}, {-76, -54}}, color = {191, 0, 0}));
  connect(g18.port_b, g17.port_a) annotation(
    Line(points = {{44, -54}, {36, -54}}, color = {191, 0, 0}));
  connect(g18.port_a, c13.port) annotation(
    Line(points = {{60, -54}, {64, -54}, {64, -48}}, color = {191, 0, 0}));
  connect(g18.port_a, g10.port_b) annotation(
    Line(points = {{60, -54}, {88, -54}, {88, -46}}, color = {191, 0, 0}));
  connect(g15.port_b, g16.port_a) annotation(
    Line(points = {{-18, 8}, {-18, -4}}, color = {191, 0, 0}));
  connect(g5.port_a, c4.port) annotation(
    Line(points = {{10, 12}, {10, 26}}, color = {191, 0, 0}));
  connect(Rp.n, L.p) annotation(
    Line(points = {{2, 68}, {6, 68}}, color = {0, 0, 255}));
  connect(Rp.p, CL.p) annotation(
    Line(points = {{-10, 68}, {-18, 68}}, color = {0, 0, 255}));
  annotation(
    uses(Modelica(version = "4.1.0")),
    Diagram(graphics = {Line(origin = {68, 22}, points = {{-110, 0}, {20, 0}, {20, -55}}, color = {255, 170, 0}, thickness = 2), Rectangle(origin = {44, 22}, fillColor = {232, 232, 232}, pattern = LinePattern.DashDot, lineThickness = 0.5, extent = {{-44, 30}, {35, -30}}), Text(origin = {-42, 46}, extent = {{-10, 4}, {10, -4}}, textString = "GoldPad(Target)"), Text(origin = {-18, 46}, extent = {{-8, 2}, {8, -2}}, textString = "WireBond1"), Text(origin = {5, 47}, extent = {{-9, 3}, {9, -3}}, textString = "GoldPad(TES1)
+bondpad1"), Text(origin = {51, 47}, extent = {{-9, 3}, {9, -3}}, textString = "GoldPad(TES2)"), Text(origin = {69, 47}, extent = {{-9, 3}, {9, -3}}, textString = "Meander
+bondpad2"), Text(origin = {-17, -33}, extent = {{-9, 3}, {9, -3}}, textString = "Glue"), Text(origin = {57, -17}, extent = {{-9, 3}, {9, -3}}, textString = "WireBond2"), Text(origin = {-65, 46}, extent = {{-7, 2}, {7, -2}}, textString = "Target", textStyle = {TextStyle.Bold}), Text(origin = {28, 57}, extent = {{-8, 3}, {8, -3}}, textString = "TES", textStyle = {TextStyle.Bold}), Text(origin = {33, -29}, extent = {{-9, 3}, {9, -3}}, textString = "Epoxy"), Text(origin = {-30, -8}, extent = {{-8, 2}, {8, -2}}, textString = "m2+m3+m4,
T^3 (phonon) only"), Text(origin = {63, -29}, extent = {{-9, 3}, {9, -3}}, textString = "Copper"), Text(origin = {57, -61}, extent = {{-19, 1}, {19, -1}}, textString = "(K18: copper-epoxy boundary resistance)"), Text(origin = {23, -61}, extent = {{-19, 1}, {19, -1}}, textString = "(K17: epoxy bulk resistance)")}, coordinateSystem(extent = {{-100, -100}, {100, 100}})),
    Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}})),
    version = "",
    experiment(StartTime = 0, StopTime = 0.1, Tolerance = 0.5e-07, Interval = 1e-06),
    __OpenModelica_commandLineOptions = "--matchingAlgorithm=PFPlusExt --indexReductionMethod=dynamicStateSelection -d=initialization,NLSanalyticJacobian -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts -d=aliasConflicts",
    __OpenModelica_simulationFlags(lv = "LOG_STDOUT,LOG_ASSERT,LOG_STATS", s = "dassl", variableFilter = ".*"));
end System_LMO_v1;
