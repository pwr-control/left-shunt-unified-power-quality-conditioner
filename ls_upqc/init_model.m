%[text] # Left-shunt unified power quality conditioner (ls\_upqc)
%[text] Initialization of ls\_upqc.slx. A 690 V, 50 Hz grid emulator (ideal source with fault generator behind a 1 MVA Dyn11 transformer) feeds a three-phase RL load through the series transformer of the UPQC. The shunt active filter (SAF, block upqc/saf) is connected at the grid side of the series transformer: a 250 kW two-level converter with LC filter that controls the grid current (active current, reactive current steps, fault ride-through support per VDE-AR-N 4110, islanding detection). The voltage stabilizer (VS, block upqc/vs) is a 250 kW two-level converter with LCL filter that injects through the series transformer (three single-phase saturable units, 3 x 125 kVA, 400 V / 690 V) the voltage that keeps the load voltage at its reference (positive sequence 1 pu, negative sequence 0) during dips and swells of the grid.
%[text] SAF and VS share the DC link. Storage (optional, param.sim.storage): a single-phase dual active bridge (DAB, block upqc/dab) between the DC link and a 1200 V lithium-ion battery (block upqc/battery). With the storage the DAB holds the DC link at param.dclink.udc\_ref and the SAF draws the constant active current param.saf.ref.ixi\_ref from the grid (the battery is charged); without the storage the DAB and the battery are commented out and the SAF holds the DC link with its voltage PI (block saf\_ctrl/udc\_ctrl).
%[text] All the data are in one struct param, one group per part of the model: sim, time, glb\_time, grid, frt, dclink, saf, vs, dab, battery, load, meas, ctrl. The model reads param.\* only; the README lists the old names. The functions of ./private are called through the handles of ls\_upqc\_private.m (prv.timing\_param, prv.converter\_hw\_param, ...): the Live Editor runs a live script from a copy outside this folder and does not see ./private. Run the whole script once (Run): a section run on its own needs prv and param in the workspace.
%[text] The old flat init is init\_model\_legacy.m (kept until the merge). It no longer runs with the library: grid\_fault\_generator is now a function, lithium\_ion\_battery\_setup takes the charge capacity, and it switches thermal-model blocks that the model no longer has.
clear;
model = 'ls_upqc';
prv = ls_upqc_private();        % handles to the functions of ./private (the Live Editor does not see ./private)
prv.library_setup();            % pwr-control/library on the path (blocks, C-Caller sources), cloned when missing

% environment (was init_environment of the library)
close all; clc; beep off;
try
    pm_addunit('percent', 0.01, '1');       % custom Simscape unit used by some library blocks
catch ME
    if ~contains(ME.message, 'percent')     % already registered in this session: fine
        rethrow(ME);
    end
end
param = struct();
fprintf('%s init: functions of ./private, called as prv.<name>: %s\n', model, strjoin(fieldnames(prv)', ', '));
%%
%[text] ## Simulation
param.sim.simlength = 2.25;                 % [s] model StopTime
param.sim.storage = 1;                      % 1: DAB and battery on (the DAB holds the DC link),
                                            % 0: DAB and battery commented out (the SAF holds the DC link)
param.sim.nonlinear_iterations = 3;         % Simscape Solver Configuration (block grid_emulator/Solver Configuration)
param.sim.check_model = true;               % last section: param.* references and From blocks without a Goto
%%
%[text] ## Timing
%[text] Three clock domains, one per converter. SAF and VS: carrier at 4 kHz with double update, so the control step is ts = 125 us; DAB: 12 kHz with double update, ts\_dab = 41.7 us. Each control runs in a subsystem triggered by the TRGO of its own PWM generator. The step tc = ts\_saf/200 = 0.625 us is the logging base, the MaxStep of the solver, the step of the Simscape local solver and of the PWM generators. The local clocks of the converters (block global\_timing) run slightly off the master clock (param.saf.behav.time\_gain, param.vs.behav.time\_gain) to study controllers that are not synchronized; the time\_alignment block of each control corrects its clock.
param.time.t_measure = param.sim.simlength; % [s] logging window: the whole simulation
param.time.tc_factor = 200;                 % ts_saf/tc
param.time.tc_decimation = 1;
param.saf.pwm = struct('fpwm', 4e3, 'trgo', 1, 'dead_time', 3e-6);     % [Hz], 1: double update, [s]
param.vs.pwm = struct('fpwm', 4e3, 'trgo', 1, 'dead_time', 3e-6);
param.dab.pwm = struct('fpwm', 12e3, 'trgo', 1, 'dead_time', 2e-6);
param.glb_time = prv.timing_param(param.time, param.saf.pwm, param.vs.pwm, param.dab.pwm);
%%
%[text] ## Grid emulator
%[text] Ideal three-phase source with fault generator (library block three\_phase\_voltage\_source\_with\_frt\_emulator, block grid\_emulator/voltage\_source\_with\_frt) behind a 1 MVA Dyn11 transformer 690 V / 690 V (library block configurable\_trafo, block grid\_emulator/grid\_transformer). Transformer data as in the legacy init; the magnetizing inductance of the delta coil comes from the core geometry (Lm1 = n1^2 mu0 mur A/l) and gives the line no-load current i1m = sqrt(3) us1/(omega Lm1) (the legacy init used us1/sqrt(3)/(omega Lm1), the formula of a star coil: three times less magnetizing current). Zero-sequence magnetizing inductance 0.5 pu (three-limb core), as in afe\_uvw\_three\_phase (modelization-and-control).
param.grid.name = 'Dyn11 grid transformer';
param.grid.delta_star = 1;                  % 1: Dyn, 0: Yyn
param.grid.pwr_nom = 1000e3;                % [VA]
param.grid.application_voltage = 690;       % [V] voltage class: 690, 480 or 400
switch param.grid.application_voltage
    case 690
        g = struct('us1', 690, 'us2', 690, 'fgrid', 50, 'p_iron', 1800);
    case 480
        g = struct('us1', 480, 'us2', 480, 'fgrid', 60, 'p_iron', 1400);
    otherwise
        g = struct('us1', 400, 'us2', 400, 'fgrid', 50, 'p_iron', 1000);
end
param.grid.us1 = g.us1;                     % [V] primary, line to line
param.grid.us2 = g.us2;                     % [V] secondary (PCC), line to line
param.grid.fgrid = g.fgrid;                 % [Hz]
param.grid.eta = 95;                        % [%]
param.grid.ucc = 5;                         % [%]
param.grid.p_iron = g.p_iron;               % [W]
param.grid.n2 = 14;                         % turns of the secondary coil
param.grid.n1 = floor(param.grid.n2*sqrt(3));
param.grid.core_area = 0.05;                % [m^2]
param.grid.core_length = 2.5;               % [m]
param.grid.mur = 10e3;
mu0 = 4*pi*1e-7;
Lm1 = param.grid.n1^2*mu0*param.grid.mur*param.grid.core_area/param.grid.core_length;   % [H] coil
param.grid.i1m = sqrt(3)*param.grid.us1/Lm1/(2*pi*param.grid.fgrid);  % [A] line no-load current (delta)
param.grid.lm0_pu = 0.5;                    % [pu] zero-sequence magnetizing inductance
param.grid.up_xi_pu_ref = 1;                % [pu] voltage of the emulator: positive sequence ...
param.grid.up_eta_pu_ref = 0;
param.grid.un_xi_pu_ref = 0;                % ... and negative sequence
param.grid.un_eta_pu_ref = 0;
param.grid.f_sof = 50;                      % [Hz] second-order filters of the fault profiles
param.grid.emu = prv.grid_emulator_param(param.grid);
clear g mu0 Lm1
%%
%[text] ## Fault ride-through test
%[text] Test of the catalogue of private/frt\_param (VDE-AR-N 4110 style). 25.4: two-phase fault with a dip of 0.75 for 0.915 s at 0.75 s. enable\_frt\_2: the fault acts on the sequence references of the emulator (positive sequence dips deepPOSxi/deepPOSeta, negative sequence steps deepNEGxi/deepNEGeta); enable\_frt\_1: on the phase amplitudes. The FRT function of the SAF is enabled after settle\_time (0.175 s).
param.frt.test_index = 25;                  % type of fault: index
param.frt.test_subindex = 4;                % type of fault: subindex
param.frt.asymmetric_error_type = 1;        % two-phase faults: 0 variant C, 1 variant D
param.frt.enable_frt_1 = 0;                 % faults generated from abc
param.frt.enable_frt_2 = 1;                 % faults generated from xi_eta_pos and xi_eta_neg
param.frt.start_time_LVRT = 0.75;           % [s]
param.frt.deepPOSxi = 1;
param.frt.deepPOSeta = -0.4;
param.frt.deepNEGxi = 0.4;
param.frt.deepNEGeta = 0.4;
param.frt.data = prv.frt_param(param.frt);
%%
%[text] ## DC link
%[text] Voltage of the shared DC link: 1200 V, the rated DC voltage of the DAB data set (DAB\_1200V). With the storage the DAB holds it (block dab/dab\_ctrl/references); without the storage the SAF does (reference param.saf.ctrl.udc\_norm\_ref in pu of the DC voltage base of the SAF, 1070 V). The DC link is charged at the start through the diodes of the SAF bridge (about the peak line voltage, 976 V).
param.dclink.udc_ref = 1200;                % [V]
%%
%[text] ## Shunt active filter (SAF)
%[text] ### Hardware
%[text] 250 kW data set of the library for the 690 V class (afe690V: udc\_nom 1070 V, LFu 500 uH, CFu 200 uF, DC link 7.2 mF). Bases of the measurements: ubez = 690 sqrt(2/3) = 563 V, ibez = sqrt(2) 250e3/(sqrt(3) 690 0.9) = 329 A.
param.saf.application_voltage = 690;        % [V]
param.saf.pwr_nom = 250e3;                  % [W]
param.saf.hw = prv.converter_hw_param('saf690V', param.saf.application_voltage, param.saf.pwr_nom, ...
    param.glb_time.fPWM_SAF);
%[text] ### Control
%[text] FHT-PLL, double-integrator observers and limits of the library class ctrl\_afe\_setup (private/converter\_ctrl\_param), with the legacy changes: resonant PI of the current control kp 0.25, ki 35 (gains for LVRT), DC-link voltage PI kp 2. The parameters of the afe\_uvw\_ctrl blocks (grid\_voltage\_sequences, grid\_current\_sequences\_q\_ctrl, frt\_vde4110, current\_ctrl\_uvw, islanding\_detector) are in param.saf.uvw: sequence averages over half a grid period from 25 ms.
param.saf.ctrl = prv.converter_ctrl_param(param.glb_time.ts_saf, param.grid.emu.omega_grid_nom);
param.saf.ctrl.kp_udc_ctrl = 2;             % [pu/pu] DC-link voltage PI (used without the storage)
param.saf.ctrl.udc_norm_ref = param.dclink.udc_ref/param.saf.hw.udc_nom;    % [pu]
param.saf.ctrl.res_pi.kp_rpi = 0.25;        % resonant PI of the current control (gains for LVRT)
param.saf.ctrl.res_pi.ki_rpi = 35;
param.saf.uvw = prv.uvw_param(param.saf.ctrl, param.grid.fgrid, 2, 0.025, param.frt.data.k_frt_ref);
%[text] ### References
%[text] With the storage the SAF draws the constant active current ixi\_ref (pu of ibez, negative: from the grid to the DC link). Reactive current steps of the positive sequence after the fault, of the amplitude that gives cos(phi) 0.95 with ixi\_ref: to i\_react\_pos\_ref\_2 at time\_i\_react\_pos\_ref\_1 (in the default case the SAF then supplies about 74 kvar to the grid), to the opposite value 0.5 s later.
param.saf.ref.ixi_ref = -0.85;              % [pu] active current with the storage
param.saf.ref.u_cm_comp = 0;                % common mode compensation of the modulator (block space_vector)
param.saf.ref.enable_i_react_pos_steps = 1;
param.saf.ref.time_i_react_pos_ref_1 = 0;   % [s]
param.saf.ref.time_i_react_pos_ref_2 = 0;   % [s]
param.saf.ref.i_react_pos_ref_1 = 0;        % [pu]
param.saf.ref.i_react_pos_ref_2 = 0;
param.saf.ref.i_react_pos_ref_3 = 0;
if param.saf.ref.enable_i_react_pos_steps
    param.saf.ref.time_i_react_pos_ref_1 = param.frt.start_time_LVRT + param.frt.data.error_length + 0.335;
    param.saf.ref.time_i_react_pos_ref_2 = param.saf.ref.time_i_react_pos_ref_1 + 0.5;
    param.saf.ref.i_react_pos_ref_2 = -param.saf.ref.ixi_ref*tan(acos(0.95));
    param.saf.ref.i_react_pos_ref_3 = param.saf.ref.ixi_ref*tan(acos(0.95));
end
%[text] ### Behaviour
param.saf.behav.time_gain = 1.0002;         % local clock = time_gain * master clock (block global_timing/time_saf)
param.saf.behav.pwm_phase_shift = 0;        % phase shift of the carrier (block saf_inverter/sv_pwm)
%%
%[text] ## Voltage stabilizer (VS)
%[text] ### Hardware
%[text] Same 250 kW, 690 V data set as the SAF; LCL filter (block vs\_lcl\_filter).
param.vs.application_voltage = 690;         % [V]
param.vs.pwr_nom = 250e3;                   % [W]
param.vs.hw = prv.converter_hw_param('vs690V', param.vs.application_voltage, param.vs.pwr_nom, ...
    param.glb_time.fPWM_VS);
%[text] ### Series transformer
%[text] Three single-phase saturable transformers (library block saturable\_single\_phase\_transformer, block upqc/series\_transformer): 3 x 125 kVA, 400 V (VS side, floating star of the LCL filter) / 690 V (line side, winding in series with the line), ucc 4 %, efficiency 98 %, iron losses 5 kW. The magnetizing inductance comes from the core geometry; i1m with the formula of a star coil (u1/sqrt(3)/(omega Lm1)).
st.name = 'UPQC series transformer';
st.delta_star = 0;                          % star primary
st.pwr_nom = 3*125e3;                       % [VA]
st.u1_nom = 400;                            % [V] VS side
st.u2_nom = 690;                            % [V] line side
st.f_nom = 50;                              % [Hz]
st.eta = 98;                                % [%]
st.ucc = 4;                                 % [%]
st.p_iron = 5e3;                            % [W]
st.n2 = 8;
st.n1 = st.u1_nom/st.u2_nom*st.n2;
st.core_area = 0.04;                        % [m^2]
st.core_length = 0.25;                      % [m]
st.mur = 35e3;
Lm1 = st.n1^2*4*pi*1e-7*st.mur*st.core_area/st.core_length;   % [H]
st.i1m = st.u1_nom/sqrt(3)/Lm1/st.f_nom/2/pi;                 % [A]
param.vs.st = prv.transformer_param(st);
clear st Lm1
%[text] ### Control
%[text] Same control data as the SAF (the legacy init shared one object). The load voltage sequences (block vs\_ctrl/load\_voltage\_sequences) feed four PIs (block vs\_ctrl/load\_voltage\_ctrl: positive and negative sequence, xi and eta) whose outputs are the stack current references of the resonant current control.
param.vs.ctrl = prv.converter_ctrl_param(param.glb_time.ts_vs, param.grid.emu.omega_grid_nom);
param.vs.ctrl.kp_udc_ctrl = 2;
param.vs.ctrl.udc_norm_ref = param.dclink.udc_ref/param.vs.hw.udc_nom;
param.vs.ctrl.res_pi.kp_rpi = 0.25;
param.vs.ctrl.res_pi.ki_rpi = 35;
param.vs.ctrl.kp_p = 1;                     % PIs of the load voltage: positive sequence
param.vs.ctrl.ki_p = 35;                    % [1/s]
param.vs.ctrl.kp_n = 1;                     % negative sequence
param.vs.ctrl.ki_n = 35;                    % [1/s]
param.vs.ctrl.lim = 4;                      % [pu] limit of the stack current references
param.vs.uvw = prv.uvw_param(param.vs.ctrl, param.grid.fgrid, 2, 0.025, param.frt.data.k_frt_ref);
%[text] ### References and behaviour
param.vs.ref.up_xi_pu_ref = 1;              % [pu] load voltage: positive sequence ...
param.vs.ref.up_eta_pu_ref = 0;
param.vs.ref.un_xi_pu_ref = 0;              % ... and negative sequence
param.vs.ref.un_eta_pu_ref = 0;
param.vs.ref.u_cm_comp = -1;                % common mode compensation of the modulator (legacy en_parallel_mode)
param.vs.behav.time_gain = 1.0015;          % block global_timing/time_vs
param.vs.behav.pwm_phase_shift = 0;
%%
%[text] ## Storage: dual active bridge and battery
%[text] Computed in every case (the blocks are commented out without the storage, see Model setup).
%[text] ### Dual active bridge
%[text] Single-phase DAB of the 1200 V class (library data set DAB\_1200V: 1200 V on both sides, transformer 1:1, Lm 1 mH, DC links 3.6 mF), 250 kW at 12 kHz. The series inductance is the leakage inductance of the transformer, Ld1 + Ld2 = Ls (38.2 uH); the data set also computes a series capacitor Cs for a resonance at fPWM\_DAB/5 (param.dab.fres), which the model does not have. Side 2 is the DC link of SAF and VS, side 1 the battery. The DC-link voltage PI (block dab\_ctrl/u\_out\_ctrl, on the voltage in pu of udc2\_nom) gives the phase shift between the two bridges directly, in units of the max\_phase\_displacement of the modulator (pi/2): its output limit param.dab.ctrl.phase\_lim = 1 keeps the phase shift within pi/2, the top of the power curve (beyond it the power falls while the phase shift grows, and the loop gain changes sign). The current PI (block i\_out\_ctrl) is commented out, as in main: kp\_idc and ki\_idc are not used. Near zero phase shift one unit of the PI output is worth about 790 kW at 1200 V on both sides, and the DC link (18 mF) integrates the difference of the powers: the voltage loop crosses over at about 31 rad/s times kp\_udc. The gains of main (kp 1, ki 35) were too slow for the default FRT test, in which the DAB goes from charging the battery at 200 kW to supplying the VS within a few milliseconds (the DC link fell to 650 V); kp 6 and ki 240 (crossover about 190 rad/s, zero at 40 rad/s) hold it within 2 %.
param.dab.application_voltage = 690;        % [V] selects DAB_1200V
param.dab.pwr_nom = 250e3;                  % [W]
param.dab.fres = param.glb_time.fPWM_DAB/5; % [Hz]
param.dab.hw = prv.dab_hw_param(param.dab.application_voltage, param.dab.pwr_nom, param.glb_time.fPWM_DAB, ...
    param.dab.fres);
param.dab.ctrl.kp_udc = 6;                  % DC-link voltage PI (main: 1)
param.dab.ctrl.ki_udc = 240;                % [1/s] (main: 35)
param.dab.ctrl.phase_lim = 1;               % output limit of the voltage PI [pi/2]
param.dab.ctrl.kp_idc = 0.5;                % current PI (block commented out)
param.dab.ctrl.ki_idc = 18;                 % [1/s]
param.dab.behav.time_gain = 1;              % block global_timing/time_dab
%[text] ### Battery
%[text] Lithium-ion pack on side 1 of the DAB (block battery/lithium\_ion\_battery): 1200 V nominal (udc1\_bez of the DAB), 250 kW, initial state of charge 0.85. Charge capacity 50 Ah, the value of the library function that the legacy init called (lithium\_ion\_battery\_setup, before it took the capacity as an input). As in the legacy init, R0 and R1 are halved and C1 is divided by 50. The model starts from these initial conditions (Solver Configuration: no start from steady state, which would bring the battery to SOC 0 through the off-state leakage of the bridges): the internal capacitor of the battery block (battery\_voltage\_init\_m) and the DC capacitor of DAB side 1 (dab/dcdc\_with\_galvanic\_isolation/CFi\_dc1) start at the open-circuit voltage of the pack at the initial state of charge, param.battery.voltage\_init\_1 (formula of lithium\_ion\_cell.ssc, about 1248 V at SOC 0.85).
param.battery.nominal_battery_voltage_1 = param.dab.hw.udc1_bez;    % [V]
param.battery.nominal_battery_power = 250e3;                        % [W]
param.battery.initial_battery_soc = 0.85;
param.battery.charge_capacity_1 = 50;                               % [Ah]
param.battery.plot_ocv = false;
b = param.battery;
param.battery.pack_1 = prv.battery_param(b.nominal_battery_voltage_1, b.nominal_battery_power, b.charge_capacity_1, ...
    b.initial_battery_soc, param.glb_time.ts_dab, b.plot_ocv);
param.battery.pack_1.R0 = param.battery.pack_1.R0/2;                % legacy changes
param.battery.pack_1.R1 = param.battery.pack_1.R1/2;
param.battery.pack_1.C1 = param.battery.pack_1.C1/50;
p = param.battery.pack_1;
z = param.battery.initial_battery_soc;
param.battery.voltage_init_1 = p.number_of_cells*(p.E_1*exp(-z*p.alpha) + p.E0 + p.E1*z + p.E2*z^2 + ...
    p.E3*z^3 + p.Elog*log(abs(1 - z + 1e-2)));                     % [V] open-circuit voltage at soc_init
clear b p z
%%
%[text] ## Load
%[text] Three-phase RL load (library block three\_phase\_rl\_load, block rl\_load), the same values on the three phases.
param.load.R = 1;                           % [Ohm]
param.load.L = 1e-3;                        % [H]
%%
%[text] ## Measurements and common control data
param.meas.adc_quantization = 1/2^11;       % [pu] quantizer of the acquisitions (pu signals, 12 bit)
param.meas.adc12_quantization = param.meas.adc_quantization;
%[text] Local time alignment to the master time (time\_alignment/alignment\_eval of the SAF and of the VS, outputs local\_time\_corr\_saf and local\_time\_corr\_vs into global\_timing).
param.ctrl.kp_align = 0.25;
param.ctrl.ki_align = 18;                   % [1/s]
param.ctrl.lim_up_align = 0.05;
param.ctrl.lim_down_align = -0.05;
%[text] ### Design figures (informative)
d.udc_ref = param.dclink.udc_ref;                                   % [V]
d.m_saf = param.grid.us2*sqrt(2)/d.udc_ref;                         % peak line voltage / udc (SVPWM limit 1)
d.p_load = 3*(param.grid.us2/sqrt(3))^2*param.load.R/ ...
    (param.load.R^2 + (param.grid.emu.omega_grid_nom*param.load.L)^2);   % [W] load at rated voltage
d.q_load = d.p_load*param.grid.emu.omega_grid_nom*param.load.L/param.load.R;  % [var]
d.p_saf_storage = -3/2*param.saf.hw.ubez*param.saf.hw.ibez*param.saf.ref.ixi_ref;  % [W] drawn by the SAF with the storage
fprintf('DC link %.0f V: peak line voltage / udc = %.2f | load %.0f kW, %.0f kvar at rated voltage | SAF with the storage: %.0f kW from the grid\n', ...
    d.udc_ref, d.m_saf, d.p_load/1e3, d.q_load/1e3, d.p_saf_storage/1e3);
param.design = d;
clear d
%%
%[text] ## Model setup
if usejava('desktop')
    open_system(model);
else
    load_system(model);
end
Simulink.importExternalCTypes(model, 'Names', {'sv_pwm_cm_output_t'});     % output bus of the C-Caller modulators
%[text] Scopes closed at start.
open_scopes = find_system(model, 'BlockType', 'Scope');
for k = 1:numel(open_scopes)
    set_param(open_scopes{k}, 'Open', 'off');
end
clear open_scopes k
%[text] Storage: DAB, battery and their logging are commented in or out. Without the storage the switch of saf\_ctrl/i\_xi\_ref takes the output of the DC-link voltage PI instead of ixi\_ref.
storage_blocks = {[model '/upqc/dab'], [model '/upqc/battery'], [model '/measurements/dab_quantities']};
for k = 1:numel(storage_blocks)
    if param.sim.storage
        set_param(storage_blocks{k}, 'Commented', 'off');
    else
        set_param(storage_blocks{k}, 'Commented', 'on');
    end
end
onoff = {'off', 'on'};
fprintf('%s init: storage (DAB + battery) %s\n', model, onoff{(param.sim.storage == 1) + 1});
clear storage_blocks k onoff
%%
%[text] ## Check of the model
%[text] Every param.\* read by an active block must exist, and every From block of the active part of the model must have a Goto.
if param.sim.check_model
    [missing_refs, model_refs] = prv.check_model_param_refs(model, param);
    if isempty(missing_refs)
        fprintf('%s init: all %d param.* references of the model blocks resolve\n', model, numel(model_refs));
    else
        warning('%s init: %d param.* references of the model blocks do not exist in param:', model, numel(missing_refs));
        disp(missing_refs);
    end
    lost = prv.check_from_goto(model);
    if isempty(lost)
        fprintf('%s init: every active From block has its Goto\n', model);
    else
        warning('%s init: %d tags read by active From blocks have no active Goto:\n  %s', model, numel(lost), ...
            strjoin(lost, '\n  '));
    end
    clear missing_refs model_refs lost
end

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"onright","rightPanelPercent":33.8}
%---
