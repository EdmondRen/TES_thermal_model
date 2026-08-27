model System_LMO
  Modelica.Thermal.HeatTransfer.Sources.FixedTemperature fixedTemperature(T(displayUnit = "mK") = 0.01) annotation(
    Placement(transformation(origin = {-71, -71}, extent = {{-11, -11}, {11, 11}})));
  Modelica.Thermal.HeatTransfer.Sources.PrescribedHeatFlow HeatSource(T_ref(displayUnit = "K") = 0.1) annotation(
    Placement(transformation(origin = {-56, 76}, extent = {{-6, -6}, {6, 6}})));
  Modelica.Blocks.Sources.Pulse Pulse(amplitude = 3.2e-10, nperiod = 1, period = 1, startTime(displayUnit = "ms") = 0.01, width = 100e-7) annotation(
    Placement(transformation(origin = {-78, 76}, extent = {{-6, -6}, {6, 6}})));
  libTES.TES2 tes(Rn = TES_Rn, Tc = TES_Tc, alpha0 = TES_alpha, m = TES_m, a1 = TES_a1, a3 = TES_a3) annotation(
    Placement(transformation(origin = {12, 32}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Resistor RL(R(displayUnit = "mOhm") = Bias_R) annotation(
    Placement(transformation(origin = {-14, 32}, extent = {{-6, -6}, {6, 6}}, rotation = -90)));
  Modelica.Electrical.Analog.Basic.Ground GND annotation(
    Placement(transformation(origin = {-26, 18}, extent = {{-6, -6}, {6, 6}})));
  Modelica.Electrical.Analog.Basic.Inductor L(L(displayUnit = "nH") = Bias_L) annotation(
    Placement(transformation(origin = {-6, 38}, extent = {{-6, -6}, {6, 6}})));
  Modelica.Electrical.Analog.Sources.ConstantCurrent TESBias(I = Bias_I) annotation(
    Placement(transformation(origin = {-26, 32}, extent = {{-6, -6}, {6, 6}}, rotation = 90)));
  libTES.ThermlConductanceN G1(K = K1, n = 5) annotation(
    Placement(transformation(origin = {-20, 76}, extent = {{-10, -10}, {10, 10}})));
  libTES.ThermlConductanceN G2(K = K2, n = 2) annotation(
    Placement(transformation(origin = {10, 76}, extent = {{-10, -10}, {10, 10}})));
  libTES.ThermlConductanceN G3(K = K3, n = 2) annotation(
    Placement(transformation(origin = {40, 76}, extent = {{-10, -10}, {10, 10}})));
  libTES.ThermlConductanceN G4(K = K4, n = 2) annotation(
    Placement(transformation(origin = {42, 46}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
  libTES.ThermlConductanceN G5(K = K5, n = 5) annotation(
    Placement(transformation(origin = {58, 28}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  libTES.ThermlConductanceN G6(K = K6, n = 5) annotation(
    Placement(transformation(origin = {42, 8}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
  libTES.ThermlConductanceN G7(K = K7, n = 2) annotation(
    Placement(transformation(origin = {18, 8}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
  libTES.ThermlConductanceN G8(K = K8, n = 2) annotation(
    Placement(transformation(origin = {8, -6}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  libTES.ThermlConductanceN G9(K = K9, n = 4) annotation(
    Placement(transformation(origin = {32, -16}, extent = {{-10, -10}, {10, 10}})));
  libTES.ThermlConductanceN G10(K = K10, n = 2) annotation(
    Placement(transformation(origin = {8, -30}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  libTES.ThermlConductanceN G11(K = K11, n = 4) annotation(
    Placement(transformation(origin = {58, -30}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  libTES.ThermlConductanceN G12(K = K12, n = 2) annotation(
    Placement(transformation(origin = {8, -56}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  libTES.ThermlConductanceN G13(K = K13, n = 4) annotation(
    Placement(transformation(origin = {58, -56}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  libTES.ThermlConductanceN G14(K = K14, n = 4) annotation(
    Placement(transformation(origin = {-38, -56}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  libTES.HeatCapacitorPoly Target(m = m1, a1 = a1_target, a3 = a3_target, a5 = a5_target) annotation(
    Placement(transformation(origin = {-38, 86}, extent = {{-10, -10}, {10, 10}})));
  libTES.HeatCapacitorPoly GoldPadTarget(m = m2, a1 = a1_gold, a3 = a3_gold, a5 = a5_gold) annotation(
    Placement(transformation(origin = {-6, 86}, extent = {{-10, -10}, {10, 10}})));
  libTES.HeatCapacitorPoly WireBond1(m = m3, a1 = a1_gold, a3 = a3_gold, a5 = a5_gold) annotation(
    Placement(transformation(origin = {26, 86}, extent = {{-10, -10}, {10, 10}})));
  libTES.HeatCapacitorPoly GoldPadTES1(m = m4, a1 = a1_gold, a3 = a3_gold, a5 = a5_gold) annotation(
    Placement(transformation(origin = {80, 46}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  libTES.HeatCapacitorPoly GoldPadTES2(m = m6, a1 = a1_gold, a3 = a3_gold, a5 = a5_gold) annotation(
    Placement(transformation(origin = {-6, 8}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
  libTES.HeatCapacitorPoly Si(m = m5, a1 = a1_silicon, a3 = a3_silicon, a5 = a5_silicon) annotation(
    Placement(transformation(origin = {80, 8}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  libTES.HeatCapacitorPoly Meander(m = m7, a1 = a1_gold, a3 = a3_gold, a5 = a5_gold) annotation(
    Placement(transformation(origin = {-6, -16}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
  libTES.HeatCapacitorPoly Glue(m = m9, a1 = a1_glue, a3 = a3_glue, a5 = a5_glue) annotation(
    Placement(transformation(origin = {78, -42}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  libTES.HeatCapacitorPoly WireBond2(m = m8, a1 = a1_gold, a3 = a3_gold, a5 = a5_gold) annotation(
    Placement(transformation(origin = {-6, -42}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
  // Parameters
  //  - Electrical, bias
  parameter Modelica.Units.SI.Current Bias_I "Bias current";
  parameter Modelica.Units.SI.Resistance Bias_R "Load resistance (Rsh+Rp)";
  parameter Modelica.Units.SI.Inductance Bias_L "Bias circuit indutance";
  //  - Electrical, TES
  parameter Modelica.Units.SI.Resistance TES_Rn "TES normal resistance";
  parameter Modelica.Units.SI.Temperature TES_Tc "TES critical temp.";
  parameter Real TES_alpha "TES alpha";
  parameter Modelica.Units.SI.Mass TES_m "TES mass";
  parameter Real TES_a1 "TES heat capacity linear term";
  parameter Real TES_a3 "TES heat capacity cubic term";
  //  - Thermal, conductance
  parameter Real K1 "Absorber -> Goldpad";
  parameter Real K2 "Goldpad -> Goldwirebond";
  parameter Real K3 "Goldwirebond -> Goldpad2";
  parameter Real K4 "Goldpad2 -> TES Electron System";
  parameter Real K5 "Goldpad2 -> Si chip";
  parameter Real K6 "Si chip -> TES, electron-phonon coupling";
  parameter Real K7 "TES -> GoldpadTES";
  parameter Real K8 "GoldpadTES -> Meander";
  parameter Real K9 "Meander -> Si chip";
  parameter Real K10 "Meander -> WireBond2";
  parameter Real K11 "WireBond2 -> bath";
  parameter Real K12 "Si chip -> Glue";
  parameter Real K13 "Glue -> bath";
  parameter Real K14 "Absorber -> bath";
  //  - Thermal, heat capacity
  parameter Modelica.Units.SI.Mass m1 "Absorber mass";
  parameter Modelica.Units.SI.Mass m2 "Gold (target gold pad)";
  parameter Modelica.Units.SI.Mass m3 "Gold (WireBond1)";
  parameter Modelica.Units.SI.Mass m4 "Gold (GoldPad2)";
  parameter Modelica.Units.SI.Mass m5 "Silicon chip";
  parameter Modelica.Units.SI.Mass m6 "Gold (GoldPadTES)";
  parameter Modelica.Units.SI.Mass m7 "Gold (Meander)";
  parameter Modelica.Units.SI.Mass m8 "Gold (WireBond2)";
  parameter Modelica.Units.SI.Mass m9 "Glue";
  parameter Real a1_target;
  parameter Real a3_target;
  parameter Real a5_target;
  parameter Real a1_gold;
  parameter Real a3_gold;
  parameter Real a5_gold;
  parameter Real a1_silicon;
  parameter Real a3_silicon;
  parameter Real a5_silicon;
  parameter Real a1_glue;
  parameter Real a3_glue;
  parameter Real a5_glue;
  Modelica.Thermal.HeatTransfer.Sources.PrescribedHeatFlow HeatSource1(T_ref(displayUnit = "K") = 0.1) annotation(
    Placement(transformation(origin = {-56, 58}, extent = {{-6, -6}, {6, 6}})));
  Modelica.Blocks.Sources.Pulse Pulse1(amplitude = 3.2e-10, nperiod = 1, period = 1, startTime(displayUnit = "ms") = 0.01, width = 100e-7) annotation(
    Placement(transformation(origin = {-78, 58}, extent = {{-6, -6}, {6, 6}})));
equation
  connect(Pulse.y, HeatSource.Q_flow) annotation(
    Line(points = {{-71, 76}, {-62, 76}}, color = {0, 0, 127}));
  connect(GND.p, TESBias.p) annotation(
    Line(points = {{-26, 24}, {-26, 26}}, color = {0, 0, 255}));
  connect(TESBias.p, RL.n) annotation(
    Line(points = {{-26, 26}, {-14, 26}}, color = {0, 0, 255}));
  connect(L.p, RL.p) annotation(
    Line(points = {{-12, 38}, {-14, 38}}, color = {0, 0, 255}));
  connect(RL.p, TESBias.n) annotation(
    Line(points = {{-14, 38}, {-26, 38}}, color = {0, 0, 255}));
  connect(L.n, tes.p) annotation(
    Line(points = {{0, 38}, {2, 38}}, color = {0, 0, 255}));
  connect(tes.n, RL.n) annotation(
    Line(points = {{2, 26}, {-14, 26}}, color = {0, 0, 255}));
  connect(G2.port_a, GoldPadTarget.port) annotation(
    Line(points = {{0, 76}, {-6, 76}}, color = {191, 0, 0}));
  connect(WireBond1.port, G2.port_b) annotation(
    Line(points = {{26, 76}, {20, 76}}, color = {191, 0, 0}));
  connect(G4.port_b, G6.port_b) annotation(
    Line(points = {{32, 46}, {32, 8}}, color = {191, 0, 0}));
  connect(GoldPadTES2.port, G7.port_b) annotation(
    Line(points = {{4, 8}, {8, 8}}, color = {191, 0, 0}));
  connect(G7.port_a, G6.port_b) annotation(
    Line(points = {{28, 8}, {32, 8}}, color = {191, 0, 0}));
  connect(G9.port_b, G5.port_b) annotation(
    Line(points = {{42, -16}, {58, -16}, {58, 18}}, color = {191, 0, 0}));
  connect(Meander.port, G8.port_b) annotation(
    Line(points = {{4, -16}, {8, -16}}, color = {191, 0, 0}));
  connect(G10.port_a, G8.port_b) annotation(
    Line(points = {{8, -20}, {8, -16}}, color = {191, 0, 0}));
  connect(G9.port_a, G8.port_b) annotation(
    Line(points = {{22, -16}, {8, -16}}, color = {191, 0, 0}));
  connect(G8.port_a, G7.port_b) annotation(
    Line(points = {{8, 4}, {8, 8}}, color = {191, 0, 0}));
  connect(WireBond2.port, G10.port_b) annotation(
    Line(points = {{4, -42}, {8, -42}, {8, -40}}, color = {191, 0, 0}));
  connect(G12.port_a, G10.port_b) annotation(
    Line(points = {{8, -46}, {8, -40}}, color = {191, 0, 0}));
  connect(G12.port_b, fixedTemperature.port) annotation(
    Line(points = {{8, -66}, {8, -71}, {-60, -71}}, color = {191, 0, 0}));
  connect(G14.port_b, fixedTemperature.port) annotation(
    Line(points = {{-38, -66}, {-38, -71}, {-60, -71}}, color = {191, 0, 0}));
  connect(G14.port_a, Target.port) annotation(
    Line(points = {{-38, -46}, {-38, 76}}, color = {191, 0, 0}));
  connect(G1.port_a, Target.port) annotation(
    Line(points = {{-30, 76}, {-38, 76}}, color = {191, 0, 0}));
  connect(G1.port_b, GoldPadTarget.port) annotation(
    Line(points = {{-10, 76}, {-6, 76}}, color = {191, 0, 0}));
  connect(HeatSource.port, Target.port) annotation(
    Line(points = {{-50, 76}, {-38, 76}}, color = {191, 0, 0}));
  connect(WireBond1.port, G3.port_a) annotation(
    Line(points = {{26, 76}, {30, 76}}, color = {191, 0, 0}));
  connect(G3.port_b, G5.port_a) annotation(
    Line(points = {{50, 76}, {58, 76}, {58, 38}}, color = {191, 0, 0}));
  connect(GoldPadTES1.port, G5.port_a) annotation(
    Line(points = {{70, 46}, {58, 46}, {58, 38}}, color = {191, 0, 0}));
  connect(G4.port_a, G5.port_a) annotation(
    Line(points = {{52, 46}, {58, 46}, {58, 38}}, color = {191, 0, 0}));
  connect(G11.port_a, G5.port_b) annotation(
    Line(points = {{58, -20}, {58, 18}}, color = {191, 0, 0}));
  connect(G11.port_b, G13.port_a) annotation(
    Line(points = {{58, -40}, {58, -46}}, color = {191, 0, 0}));
  connect(Glue.port, G13.port_a) annotation(
    Line(points = {{68, -42}, {58, -42}, {58, -46}}, color = {191, 0, 0}));
  connect(G13.port_b, fixedTemperature.port) annotation(
    Line(points = {{58, -66}, {58, -71}, {-60, -71}}, color = {191, 0, 0}));
  connect(Pulse1.y, HeatSource1.Q_flow) annotation(
    Line(points = {{-71, 58}, {-62, 58}}, color = {0, 0, 127}));
  connect(HeatSource1.port, GoldPadTarget.port) annotation(
    Line(points = {{-50, 58}, {-6, 58}, {-6, 76}}, color = {191, 0, 0}));
  connect(G6.port_a, G5.port_b) annotation(
    Line(points = {{52, 8}, {58, 8}, {58, 18}}, color = {191, 0, 0}));
  connect(Si.port, G5.port_b) annotation(
    Line(points = {{70, 8}, {58, 8}, {58, 18}}, color = {191, 0, 0}));
  connect(tes.heatPort, G4.port_b) annotation(
    Line(points = {{22, 32}, {32, 32}, {32, 46}}, color = {191, 0, 0}));
  annotation(
    uses(Modelica(version = "4.1.0")),
    Diagram(graphics = {Text(origin = {-41, 74}, rotation = 180, extent = {{-3, 2}, {3, -2}}, textString = "1", textStyle = {TextStyle.Bold}), Text(origin = {-4, 74}, extent = {{-4, 2}, {4, -2}}, textString = "2", textStyle = {TextStyle.Bold}), Text(origin = {26, 74}, extent = {{-4, 2}, {4, -2}}, textString = "3", textStyle = {TextStyle.Bold}), Text(origin = {61, 35}, extent = {{-3, 3}, {3, -3}}, textString = "4", textStyle = {TextStyle.Bold}), Text(origin = {62, 5}, extent = {{-4, 3}, {4, -3}}, textString = "5", textStyle = {TextStyle.Bold}), Text(origin = {-39, -76}, extent = {{-5, 4}, {5, -4}}, textString = "0", textStyle = {TextStyle.Bold}), Text(origin = {13, -18}, extent = {{-3, 2}, {3, -2}}, textString = "7", textStyle = {TextStyle.Bold}), Text(origin = {14, -42}, extent = {{-4, 2}, {4, -2}}, textString = "8", textStyle = {TextStyle.Bold}), Text(origin = {51, -42}, extent = {{-3, 2}, {3, -2}}, textString = "9", textStyle = {TextStyle.Bold}), Text(origin = {29, 34}, extent = {{-3, 2}, {3, -2}}, textString = "10", textStyle = {TextStyle.Bold}), Line(origin = {21, 76}, points = {{-27, 0}, {37, 0}, {37, -30}, {12, -30}}, color = {255, 170, 0}, thickness = 2), Line(origin = {8, -18}, rotation = -90, points = {{-26, 22}, {-26, 0}, {37, 0}, {53, 0}}, color = {255, 170, 0}, thickness = 2)}));
end System_LMO;
