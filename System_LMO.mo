model System_LMO
  Modelica.Thermal.HeatTransfer.Sources.FixedTemperature fixedTemperature(T(displayUnit = "mK") = 0.01) annotation(
    Placement(transformation(origin = {-71, -71}, extent = {{-11, -11}, {11, 11}})));
  Modelica.Thermal.HeatTransfer.Sources.PrescribedHeatFlow HeatSource(T_ref(displayUnit = "K") = 0.1) annotation(
    Placement(transformation(origin = {-56, 76}, extent = {{-6, -6}, {6, 6}})));
  Modelica.Blocks.Sources.Pulse Pulse(amplitude = 3.2e-10, nperiod = 1, period = 1, startTime(displayUnit = "ms") = 0.01, width = 100e-7) annotation(
    Placement(transformation(origin = {-78, 76}, extent = {{-6, -6}, {6, 6}})));
  TES2 tes(Rn = TES_Rn, Tc= TES_Tc, alpha0 = TES_alpha, m = TES_m, a1 = TES_a1, a3 = TES_a3) annotation(
    Placement(transformation(origin = {12, 32}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Electrical.Analog.Basic.Resistor RL(R(displayUnit = "mOhm") = Bias_R) annotation(
    Placement(transformation(origin = {-14, 32}, extent = {{-6, -6}, {6, 6}}, rotation = -90)));
  Modelica.Electrical.Analog.Basic.Ground GND annotation(
    Placement(transformation(origin = {-26, 18}, extent = {{-6, -6}, {6, 6}})));
  Modelica.Electrical.Analog.Basic.Inductor L(L(displayUnit = "nH") = Bias_L) annotation(
    Placement(transformation(origin = {-6, 38}, extent = {{-6, -6}, {6, 6}})));
  Modelica.Electrical.Analog.Sources.ConstantCurrent TESBias(I= Bias_I) annotation(
    Placement(transformation(origin = {-26, 32}, extent = {{-6, -6}, {6, 6}}, rotation = 90)));
  HeatCapacitorPoly Target(m=m1, a1=a1_target, a3=a3_target, a5=a5_target) annotation(
    Placement(transformation(origin = {-38, 86}, extent = {{-10, -10}, {10, 10}})));
  ThermlConductanceN G2(K = K_2_3, n = n_2_3) annotation(
    Placement(transformation(origin = {10, 76}, extent = {{-10, -10}, {10, 10}})));
  HeatCapacitorPoly TargetGoldPad(m=m2, a1=a1_gold, a3=a3_gold, a5=a5_gold) annotation(
    Placement(transformation(origin = {-6, 86}, extent = {{-10, -10}, {10, 10}})));
  HeatCapacitorPoly WireBond1(m=m3, a1=a1_gold, a3=a3_gold, a5=a5_gold) annotation(
    Placement(transformation(origin = {26, 86}, extent = {{-10, -10}, {10, 10}})));
  HeatCapacitorPoly GoldPad2(m=m4, a1=a1_gold, a3=a3_gold, a5=a5_gold) annotation(
    Placement(transformation(origin = {80, 32}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  ThermlConductanceN G4(K = K_4_10, n = n_4_10) annotation(
    Placement(transformation(origin = {42, 32}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
  ThermlConductanceN G6(K = K_5_10, n = n_5_10) annotation(
    Placement(transformation(origin = {42, 8}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
  ThermlConductanceN G5(K = K_4_5, n = n_4_5) annotation(
    Placement(transformation(origin = {58, 18}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  HeatCapacitorPoly Si(m=m5, a1=a1_silicon, a3=a3_silicon, a5=a5_silicon) annotation(
    Placement(transformation(origin = {80, 8}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  HeatCapacitorPoly GoldPadTES(m=m6, a1=a1_gold, a3=a3_gold, a5=a5_gold) annotation(
    Placement(transformation(origin = {-6, 8}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
  ThermlConductanceN G7(K = K_10_6, n = n_10_6) annotation(
    Placement(transformation(origin = {18, 8}, extent = {{-10, -10}, {10, 10}}, rotation = 180)));
  HeatCapacitorPoly Meander(m=m7, a1=a1_gold, a3=a3_gold, a5=a5_gold) annotation(
    Placement(transformation(origin = {-6, -16}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
  ThermlConductanceN G9(K = K_7_5, n = n_7_5) annotation(
    Placement(transformation(origin = {32, -16}, extent = {{-10, -10}, {10, 10}})));
  ThermlConductanceN G11(K = K_5_9, n = n_5_9) annotation(
    Placement(transformation(origin = {58, -30}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  HeatCapacitorPoly Glue(m=m9, a1=a1_glue, a3=a3_glue, a5=a5_glue) annotation(
    Placement(transformation(origin = {78, -42}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  HeatCapacitorPoly WireBond2(m=m8, a1=a1_gold, a3=a3_gold, a5=a5_gold) annotation(
    Placement(transformation(origin = {-6, -42}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
  ThermlConductanceN G10(K = K_7_8, n = n_7_8) annotation(
    Placement(transformation(origin = {8, -30}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  ThermlConductanceN G8(K = K_6_7, n = n_6_7) annotation(
    Placement(transformation(origin = {8, -6}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  ThermlConductanceN G12(K = K_8_0, n = n_8_0) annotation(
    Placement(transformation(origin = {8, -56}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  ThermlConductanceN G16(K = K_1_0, n = n_1_0) annotation(
    Placement(transformation(origin = {-38, -56}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  ThermlConductanceN G1(K = K_1_2, n = n_1_2) annotation(
    Placement(transformation(origin = {-20, 76}, extent = {{-10, -10}, {10, 10}})));
  ThermlConductanceN G3(K = K_3_4, n = n_3_4) annotation(
    Placement(transformation(origin = {40, 76}, extent = {{-10, -10}, {10, 10}})));
  ThermlConductanceN G13(K = K_9_0, n = n_9_0) annotation(
    Placement(transformation(origin = {58, -56}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
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
  parameter Real K_1_2;
  parameter Real n_1_2;
  parameter Real K_2_3;
  parameter Real n_2_3;
  parameter Real K_3_4;
  parameter Real n_3_4;
  parameter Real K_4_10;
  parameter Real n_4_10;
  parameter Real K_4_5;
  parameter Real n_4_5;
  parameter Real K_5_10;
  parameter Real n_5_10;
  parameter Real K_10_6;
  parameter Real n_10_6;
  parameter Real K_6_7;
  parameter Real n_6_7;
  parameter Real K_7_5;
  parameter Real n_7_5;
  parameter Real K_7_8;
  parameter Real n_7_8;
  parameter Real K_8_0;
  parameter Real n_8_0;
  parameter Real K_5_9;
  parameter Real n_5_9;
  parameter Real K_9_0;
  parameter Real n_9_0;
  parameter Real K_1_0;
  parameter Real n_1_0;  
  
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
    Placement(transformation(origin = {-78, 58}, extent = {{-6, -6}, {6, 6}})));  equation
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
  connect(G2.port_a, TargetGoldPad.port) annotation(
    Line(points = {{0, 76}, {-6, 76}}, color = {191, 0, 0}));
  connect(WireBond1.port, G2.port_b) annotation(
    Line(points = {{26, 76}, {20, 76}}, color = {191, 0, 0}));
  connect(G4.port_b, tes.heatPort) annotation(
    Line(points = {{32, 32}, {22, 32}}, color = {191, 0, 0}));
  connect(G4.port_b, G6.port_b) annotation(
    Line(points = {{32, 32}, {32, 8}}, color = {191, 0, 0}));
  connect(G6.port_a, G5.port_b) annotation(
    Line(points = {{52, 8}, {58, 8}}, color = {191, 0, 0}));
  connect(Si.port, G5.port_b) annotation(
    Line(points = {{70, 8}, {58, 8}}, color = {191, 0, 0}));
  connect(GoldPadTES.port, G7.port_b) annotation(
    Line(points = {{4, 8}, {8, 8}}, color = {191, 0, 0}));
  connect(G7.port_a, G6.port_b) annotation(
    Line(points = {{28, 8}, {32, 8}}, color = {191, 0, 0}));
  connect(G9.port_b, G5.port_b) annotation(
    Line(points = {{42, -16}, {58, -16}, {58, 8}}, color = {191, 0, 0}));
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
  connect(G16.port_b, fixedTemperature.port) annotation(
    Line(points = {{-38, -66}, {-38, -71}, {-60, -71}}, color = {191, 0, 0}));
  connect(G16.port_a, Target.port) annotation(
    Line(points = {{-38, -46}, {-38, 76}}, color = {191, 0, 0}));
  connect(G1.port_a, Target.port) annotation(
    Line(points = {{-30, 76}, {-38, 76}}, color = {191, 0, 0}));
  connect(G1.port_b, TargetGoldPad.port) annotation(
    Line(points = {{-10, 76}, {-6, 76}}, color = {191, 0, 0}));
  connect(HeatSource.port, Target.port) annotation(
    Line(points = {{-50, 76}, {-38, 76}}, color = {191, 0, 0}));
  connect(WireBond1.port, G3.port_a) annotation(
    Line(points = {{26, 76}, {30, 76}}, color = {191, 0, 0}));
  connect(G3.port_b, G5.port_a) annotation(
    Line(points = {{50, 76}, {58, 76}, {58, 28}}, color = {191, 0, 0}));
  connect(GoldPad2.port, G5.port_a) annotation(
    Line(points = {{70, 32}, {58, 32}, {58, 28}}, color = {191, 0, 0}));
  connect(G4.port_a, G5.port_a) annotation(
    Line(points = {{52, 32}, {58, 32}, {58, 28}}, color = {191, 0, 0}));
  connect(G11.port_a, G5.port_b) annotation(
    Line(points = {{58, -20}, {58, 8}}, color = {191, 0, 0}));
  connect(G11.port_b, G13.port_a) annotation(
    Line(points = {{58, -40}, {58, -46}}, color = {191, 0, 0}));
  connect(Glue.port, G13.port_a) annotation(
    Line(points = {{68, -42}, {58, -42}, {58, -46}}, color = {191, 0, 0}));
  connect(G13.port_b, fixedTemperature.port) annotation(
    Line(points = {{58, -66}, {58, -71}, {-60, -71}}, color = {191, 0, 0}));
  connect(Pulse1.y, HeatSource1.Q_flow) annotation(
    Line(points = {{-71, 58}, {-62, 58}}, color = {0, 0, 127}));
 connect(HeatSource1.port, TargetGoldPad.port) annotation(
    Line(points = {{-50, 58}, {-6, 58}, {-6, 76}}, color = {191, 0, 0}));
  annotation(
    uses(Modelica(version = "4.1.0")),
    Diagram(graphics = {Text(origin = {-43, 72}, rotation = 180, extent = {{-5, 4}, {5, -4}}, textString = "1", textStyle = {TextStyle.Bold}), Text(origin = {-3, 72}, extent = {{-5, 4}, {5, -4}}, textString = "2", textStyle = {TextStyle.Bold}), Text(origin = {27, 72}, extent = {{-5, 4}, {5, -4}}, textString = "3", textStyle = {TextStyle.Bold}), Text(origin = {63, 38}, extent = {{-5, 4}, {5, -4}}, textString = "4", textStyle = {TextStyle.Bold}), Text(origin = {63, 4}, extent = {{-5, 4}, {5, -4}}, textString = "5", textStyle = {TextStyle.Bold}), Text(origin = {-37, -78}, extent = {{-5, 4}, {5, -4}}, textString = "0", textStyle = {TextStyle.Bold}), Text(origin = {9, 14}, extent = {{-5, 4}, {5, -4}}, textString = "6", textStyle = {TextStyle.Bold}), Text(origin = {15, -20}, extent = {{-5, 4}, {5, -4}}, textString = "7", textStyle = {TextStyle.Bold}), Text(origin = {15, -40}, extent = {{-5, 4}, {5, -4}}, textString = "8", textStyle = {TextStyle.Bold}), Text(origin = {49, -40}, extent = {{-5, 4}, {5, -4}}, textString = "9", textStyle = {TextStyle.Bold}), Text(origin = {27, 40}, extent = {{-5, 4}, {5, -4}}, textString = "10", textStyle = {TextStyle.Bold})}));
end System_LMO;
