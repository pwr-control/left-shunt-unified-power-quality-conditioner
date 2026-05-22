
%%
clear;
[model, options] = init_environment('ls_upqc');

CTRPIFF_CLIP_RELEASE = 0.001;
s = tf('s');
%[text] ### Global timing
% simulation length
simlength = 2.25;

fpwm = 4e3;
fpwm_afe = fpwm; % for PWM
trgo_afe = 1; % double update
fpwm_inv = fpwm; % for MPC
trgo_inv = 1; % double update
fpwm_dab = 3 * fpwm;
trgo_dab = 1; % double update
fpwm_psfbc = 2.5 * fpwm;
trgo_psfbc = 0; % double update
fpwm_cllc = 5 * fpwm;
trgo_cllc = 0; % double update
% t_measure = 0.648228176318064;
t_measure = simlength;
tc_factor = 200; % tc is ts_afe / tc_factor
tc_decimation = 1;
delay_pwm = 0;
dead_time_afe = 3e-6;
dead_time_inv = 3e-6;
dead_time_dab = 2e-6;
dead_time_psfbc = 3e-6;
dead_time_cllc = 2e-6;

glb_time = timing_setup(fpwm_afe, trgo_afe, fpwm_inv, trgo_inv, fpwm_dab, trgo_dab,  fpwm_psfbc, trgo_psfbc, ...
                fpwm_cllc, trgo_cllc, t_measure, tc_factor, tc_decimation, delay_pwm, dead_time_afe, ...
                dead_time_inv, dead_time_dab, dead_time_psfbc, dead_time_cllc);

% fPWM_AFE = glb_time.fPWM_AFE;
% TRGO_AFE_double_update = glb_time.TRGO_AFE_double_update;
% fPWM_INV = glb_time.fPWM_INV;
% TRGO_INV_double_update = glb_time.TRGO_INV_double_update;
% fPWM_DAB = glb_time.fPWM_DAB;
% TRGO_DAB_double_update = glb_time.TRGO_DAB_double_update;
% fPWM_CLLC = glb_time.fPWM_CLLC;
% TRGO_CLLC_double_update = glb_time.TRGO_CLLC_double_update;
% 
% ts_afe = glb_time.ts_afe;
% ts_inv = glb_time.ts_inv;
% ts_dab = glb_time.ts_dab;
% ts_cllc = glb_time.ts_cllc;
% tc = glb_time.tc;
% 
% Nc = glb_time.Nc;
% Ns_afe = glb_time.Ns_afe;
% Ns_inv = glb_time.Ns_inv;
% Ns_dab = glb_time.Ns_dab;
% Ns_cllc = glb_time.Ns_cllc;


%[text] ## Settings for simulink model initialization and data analysis
%[text] ### Settings Enable devices with thermal model
use_mosfet_thermal_model = 0;
use_thermal_model = 0;

nonlinear_iterations = 3;  % for simscape solver
if (use_mosfet_thermal_model || use_thermal_model)
    nonlinear_iterations = 5; % for simscape solver
end

%[text] ### Enable specific settings for the simulation
load_step_time = 1.25;
transmission_delay = 125e-6*2;
sst_num_of_modules = 2;
%[text] ### Enable one/two modules
number_of_modules = 1;
enable_two_modules = number_of_modules;
%[text] ### Control Mode Settings
use_torque_curve = 1; 
use_speed_control = 1-use_torque_curve; %
use_mtpa = 1; %
use_psm_encoder = 0; % 
use_im_encoder = 1; % 
use_load_estimator = 0; %
use_estimator_from_mb = 0; % mb model based
use_motor_speed_control_mode = 0; 

% advanced dqPLL
use_dq_pll_fht_pll = 1; % 
use_dq_pll_fht_simulink_pll = 0; % 
use_dq_pll_mod1 = 0; % 
use_dq_pll_ccaller_mod1 = 0; % 
use_dq_pll_ccaller_mod2 = 0; % 

% dqPLL
use_dq_pll_mode1 = use_dq_pll_mod1;
use_dq_pll_mode2 = use_dq_pll_ccaller_mod1;
use_dq_pll_mode3 = use_dq_pll_fht_simulink_pll;
use_dq_pll_mode4 = use_dq_pll_fht_pll;

use_dq_pll_mode1_modn = 0; % simulink dqPLL
use_dq_pll_mode2_modn = 0; % ccaller dqPLL
use_dq_pll_mode3_modn = 1; % fht simulink dqPLL
use_dq_pll_mode4_modn = 0; % fht ccaller dqPLL

% single phase inverter
rpi_enable = 0; % use RPI otherwise DQ PI
system_identification_enable = 0;
use_current_controller_from_ccaller_mod1 = 1;
use_phase_shift_filter_from_ccaller_mod1 = 1;
use_sogi_from_ccaller_mod1 = 1;

% four modules in parallel connected to a dc microgrid
ixi_ref_mod1 = -0.85;
ixi_ref_mod2 = -0.85;
ixi_ref_mod3 = -0.85;
ixi_ref_mod4 = -0.85;

% common mode voltage control for hard parallelization
en_parallel_mode = 1;
   u_cm_comp_mod1 = 0;
   u_cm_comp_mod2 = 0;
   u_cm_comp_mod3 = 0;
   u_cm_comp_mod4 = 0;

if en_parallel_mode
   u_cm_comp_mod2 = -1;
   u_cm_comp_mod3 = -1;
   u_cm_comp_mod4 = -1;
end
%[text] ### Settings for CCcaller versus Simulink
use_ekf_bemf_module_1 = 1;
use_ekf_bemf_module_2 = 1;
use_observer_from_simulink_module_1 = 0;
use_observer_from_ccaller_module_1 = 0;
use_observer_from_simulink_module_2 = 0;
use_observer_from_ccaller_module_2 = 0;

% current controllers
use_current_controller_from_simulink_module_1 = 0;
use_current_controller_from_ccaller_module_1 = 1;
use_current_controller_from_simulink_module_2 = 0;
use_current_controller_from_ccaller_module_2 = 0;

% moving average filters
use_moving_average_from_ccaller_mod1 = 1;
use_moving_average_from_ccaller_mod2 = 0;
use_moving_average_from_ccaller_mod3 = 0;
use_moving_average_from_ccaller_mod4 = 0;

use_single_phase_inverter_based_FHT = 0;
use_single_phase_inverter_based_SOGI = 0;
use_single_phase_inverter_based_PHSH = 0;
use_single_phase_inverter_based_SOGI_ccaller = 1;
use_single_phase_inverter_based_PHSH_ccaller = 0;

use_system_identification_based_FHT = 0;
use_system_identification_based_SOGI = 0;
use_system_identification_based_PHSH = 0;
use_system_identification_based_SOGI_ccaller = 0;
use_system_identification_based_PHSH_ccaller = 1;


%[text] ### Single phase inverter control
iph_grid_pu_ref_1 = 1/3;
iph_grid_pu_ref_2 = 1/3.;
iph_grid_pu_ref_3 = 1/3;
time_step_ref_1 = 0.025;
time_step_ref_2 = 0.5;
time_step_ref_3 = 1;
%[text] ### Setting global behavioural (system identification versus normal functioning) and operative frequency
frequency_set = 50; % default
if system_identification_enable
    frequency_set = 300;
end
omega_set = frequency_set*2*pi;
%[text] ### Settings average filters
mavarage_filter_frequency_base_order = 2; % 2 means 100Hz, 1 means 50Hz
dmavg_filter_enable_time = 0.025;
%%
%[text] ### Grid Emulator Settings
grid_nominal_power = 1000e3;
application_voltage = 690;
grid_nominal_current = grid_nominal_power/application_voltage/sqrt(3);

% Transformer Dyn11
delta_star = 1;

if application_voltage == 690
    % trafo data
    us1 = 690; us2 = 690; fgrid = 50;
    eta = 95; ucc = 5;
    p_iron = 1800;
elseif application_voltage == 480
    % trafo data
    us1 = 480; us2 = 480; fgrid = 60;
    eta = 95; ucc = 5;
    p_iron = 1400;
else
    % trafo data
    us1 = 400; us2 = 400; fgrid = 50;
    eta = 95; ucc = 5;
    p_iron = 1000;
end

n2 = 14; n1 = floor(n2*sqrt(3));
core_area = 0.05; core_length = 2.5;
mu0 = 4*pi*1e-7; mur = 10e3;

% two simple calculation:
Lm1 = (n1^2 * mu0 * mur * core_area) / core_length;
% Lm1 = u1_nom/sqrt(3)/i1m/(2*pi*fgrid);
i1m = us1/sqrt(3)/Lm1/(2*pi*fgrid);

% reference for the voltage sequence
up_xi_pu_ref = 1; up_eta_pu_ref = 0; un_xi_pu_ref = 0; un_eta_pu_ref = 0;

% grid impedance
Lgrid_base = us1/sqrt(3)*ucc/100/2/pi/fgrid/grid_nominal_current;
if ~exist('ucc_factor', 'var')
    ucc_factor = 1;
end
eq_grid_inductance = Lgrid_base*ucc_factor; % [H]
eq_grid_resistance = 2e-3; % [Ohm]

grid_emu = grid_three_phase_emulator('Dyn11', delta_star, grid_nominal_power, application_voltage, us1, us2, fgrid, ...
                eq_grid_inductance, eq_grid_resistance, eta, ucc, i1m, p_iron, n1, n2, core_area, core_length, mur, ...
                up_xi_pu_ref, up_eta_pu_ref, un_xi_pu_ref, un_eta_pu_ref);



%%
%[text] ## Global Hardware Settings
single_phase_inverter_pwr_nom = 225e3;
afe_pwr_nom = 250e3;
inv_pwr_nom = 250e3;
dab_pwr_nom = 250e3;
cllc_pwr_nom = 250e3;
psfbc_pwr_nom = 275e3;
fres_dab = glb_time.fPWM_DAB/5;
fres_cllc = glb_time.fPWM_CLLC*1.2;

hwdata.single_phase_inverter = single_phase_inverter_hwdata(application_voltage, single_phase_inverter_pwr_nom, glb_time.fPWM_INV);
hwdata.afe = three_phase_afe_hwdata(application_voltage, afe_pwr_nom, glb_time.fPWM_AFE); %[output:4a4e8333]
hwdata.inv = three_phase_inverter_hwdata(application_voltage, inv_pwr_nom, glb_time.fPWM_INV); %[output:6b916fd2]
hwdata.dab = single_phase_dab_hwdata(application_voltage, dab_pwr_nom, glb_time.fPWM_DAB, fres_dab); %[output:15811d7e]
hwdata.psfbc = single_phase_psfbc_hwdata(application_voltage, psfbc_pwr_nom, glb_time.fPWM_PSFBC); %[output:201f4793]
hwdata.three_phase_dab = three_phase_dab_hwdata(application_voltage, dab_pwr_nom, glb_time.fPWM_DAB, fres_dab); %[output:4ca4d289]
hwdata.cllc = single_phase_cllc_hwdata(application_voltage, dab_pwr_nom, glb_time.fPWM_CLLC, fres_cllc); %[output:25c725ab]

% modifications
hwdata.afe.CFi = 2 * hwdata.psfbc.Cdc_dc1;
%[text] ### Sensors endscale, and quantization
adc_quantization = 1/2^11;
adc12_quantization = adc_quantization;
adc16_quantization = 1/2^15;

Imax_adc = 1049.835;
CurrentQuantization = Imax_adc/2^11;

Umax_adc = 1500;
VoltageQuantization = Umax_adc/2^11;
%[text] ## AFE Settings and Initialization
%[text] ### Behavioural Settings

time_gain_afe_module_1 = 1.0002;
time_gain_afe_module_2 = 1.0015;
time_gain_afe_module_3 = 0.9988;
time_gain_afe_module_4 = 1.0020;

time_gain_inv_module_1 = 1.0005;
time_gain_inv_module_2 = 1.001;
wnp = 0;
white_noise_power_afe_mod1 = wnp;
white_noise_power_inv_mod1 = wnp;
white_noise_power_afe_mod2 = wnp;
white_noise_power_inv_mod2 = wnp;

trgo_th_generator = 0.025;

afe_pwm_phase_shift_mod1 = 0;
white_noise_power_afe_pwm_phase_shift_mod1 = 0.0;
inv_pwm_phase_shift_mod1 = 0;
white_noise_power_inv_pwm_phase_shift_mod1 = 0.0;

afe_pwm_phase_shift_mod2 = 0;
white_noise_power_afe_pwm_phase_shift_mod2 = 0.0;
inv_pwm_phase_shift_mod2 = 0;
white_noise_power_inv_pwm_phase_shift_mod2 = 0.0;

afe_pwm_phase_shift_mod3 = 0;
white_noise_power_afe_pwm_phase_shift_mod3 = 0.0;
inv_pwm_phase_shift_mod3 = 0;
white_noise_power_inv_pwm_phase_shift_mod3 = 0.0;

afe_pwm_phase_shift_mod4 = 0;
white_noise_power_afe_pwm_phase_shift_mod4 = 0.0;
inv_pwm_phase_shift_mod4 = 0;
white_noise_power_inv_pwm_phase_shift_mod4 = 0.0;
%[text] ### FRT Settings
test_index = 25; % type of fault: index
test_subindex = 4; % type of fault: subindex
% test_subindex = 1; % type of fault: subindex
enable_frt_1 = 0; % faults generated from abc
enable_frt_2 = 1; % faults generated from xi_eta_pos and xi_eta_neg
start_time_LVRT = 0.75;
asymmetric_error_type = 1;
deepPOSxi = 1;
deepPOSeta = -0.4;
deepNEGxi = 0.4;
deepNEGeta = 0.4;
frt_data = frt_settings(test_index, test_subindex, asymmetric_error_type, ...
    enable_frt_1, enable_frt_2, start_time_LVRT, deepPOSxi, deepPOSeta, deepNEGxi, deepNEGeta);
grid_fault_generator;
%[text] ### Reactive Current References Settings
% reactive current references 
enable_i_react_pos_steps = 1;
    time_i_react_pos_ref_1 = 0; % default
    time_i_react_pos_ref_2 = 0; % default
    i_react_pos_ref_1 = 0; % default
    i_react_pos_ref_2 = 0; % default
    i_react_pos_ref_3 = 0; % default

if enable_i_react_pos_steps
    time_i_react_pos_ref_1 = start_time_LVRT + error_length + 0.335;
    time_i_react_pos_ref_2 = time_i_react_pos_ref_1 + 0.5;
    i_react_pos_ref_2 = -ixi_ref_mod1*tan(acos(0.95));  % cos(phi) = 0.9
    i_react_pos_ref_3 = ixi_ref_mod1*tan(acos(0.95)); % cos(phi) = 0.9
end
%[text] #### UPQC Series Transformer
name = 'UPQC Series Transformer';
pwr_nom = 3*125e3;
u1_nom = 400;
u2_nom = 690;
f_nom = 50;
eta = 98;
ucc = 4;
p_iron = 5e3;
n12 = u1_nom/u2_nom;
n2 = 8;
n1 = n12*n2;
core_area = 0.04;
core_length = 0.25;
mur = 35e3;

Lm1 = (n1^2 * mu0 * mur * core_area) / core_length;
i1m = u1_nom/sqrt(3)/Lm1/f_nom/2/pi;

delta_star = 0;

upqc_st = three_phase_transformer_setup(name, delta_star, pwr_nom, u1_nom, u2_nom, f_nom, eta, ucc, ...
    i1m, p_iron, n1, n2, core_area, core_length, mur);
upqc_st.Lm1;
upqc_st.Ld1;
upqc_ctrl.kp_p = 1;
upqc_ctrl.ki_p = 35;
upqc_ctrl.kp_n = 1;
upqc_ctrl.ki_n = 35;
upqc_ctrl.lim = 4;
%[text] #### DClink Lstray model (partial loop inductance)
parasitic_dclink_data; %[output:45652a74]
%%
%[text] ## INVERTER Settings and Initialization
%[text] ### Mode of operation
motor_torque_mode = 1 - use_motor_speed_control_mode; % system uses torque curve for wind application
time_start_motor_control = 0.25;
%[text] ### IM Machine settings
im = im_calculus(); %[output:20fe7200]
%[text] ### PSM Machine settings
psm = psm_calculus(); %[output:585fcea9]
n_sys = psm.number_of_systems;

% load
b = psm.load_friction_m;
% external_load_inertia = 6*psm.Jm_m;
external_load_inertia = 1;
%[text] ### Motor Voltage to Udc Scaling
u_psm_scale = 2/3*hwdata.inv.udc_nom/psm.ubez;
u_im_scale = 2/3*hwdata.inv.udc_nom/im.ubez;

u_psm_scale_ekf = sqrt(3)/2 * 2/3 * hwdata.inv.udc_nom/psm.ubez;
u_im_scale_ekf = (2/3)^2 * hwdata.inv.udc_nom/im.ubez;
%[text] ## **CONTROL Settings and Initialization**
%[text] #### Permanent magnet synchronous motor control with EKF based observer
psm_ctrl = ctrl_pmsm_setup(glb_time.ts_inv, psm.omega_bez, u_psm_scale, psm.Jm_norm);
% psm_ctrl.ekf = ekf_pmsm_setup(psm.Rs_norm, psm.Ls_norm, psm.Jm_norm, glb_time.ts_inv);
psm_ctrl.ekf = ekf_pmsm_setup(psm.Rs_norm, psm.Ls_norm, 1e6, glb_time.ts_inv); %[output:3ab2eff1]
psm_ctrl.kp_i = 0.25;
psm_ctrl.ki_i = 35;
%[text] #### Induction Motor Control
im_ctrl = ctrl_im_setup(glb_time.ts_inv, im.omega_bez, u_im_scale, im.Jm_norm);
im_ctrl.ekf = ekf_im_setup(im.alpha_norm, im.beta_norm, im.gamma_norm, im.sigma_norm, ... %[output:group:64b892aa] %[output:98818507]
        im.mu_norm, im.Lm_norm, im.Jm_norm, glb_time.ts_inv); %[output:group:64b892aa] %[output:98818507]
%[text] #### AFE control (with sequences)
afe_ctrl = ctrl_afe_setup(glb_time.ts_afe, grid_emu.omega_grid_nom);

kp_udc = 0.5;
ki_udc = 18.0;
kp_idc = 0.5;
ki_idc = 18.0;

%% gain for weak grids
afe_ctrl.res_pi.kp_rpi = 0.5;
afe_ctrl.res_pi.ki_rpi = 18;

%% gains for LVRT
afe_ctrl.res_pi.kp_rpi = 0.25;
afe_ctrl.res_pi.ki_rpi = 35;

%[text] #### DCDC Control
dab_ctrl = ctrl_dab_setup(kp_udc, ki_udc, kp_idc, ki_idc);
psfbc_ctrl = ctrl_dab_setup(kp_udc, ki_udc, kp_idc, ki_idc);
cllc_ctrl = ctrl_cllc_setup(kp_udc, ki_udc, kp_idc, ki_idc);

dab_ctrl.kp_udc = 1;
dab_ctrl.ki_udc = 35;
%[text] #### Resonant PI settings
pres_ctrl.kp_rpi = 0.75;
pres_ctrl.ki_rpi = 45;
pres_ctrl.delta_rpi = 0.025;
pres_ctrl.omega_set = omega_set;
pres_ctrl.res_nom = s/(s^2 + 2*pres_ctrl.delta_rpi*pres_ctrl.omega_set*s + (pres_ctrl.omega_set)^2);

pres_ctrl.Ares_nom = [0 1; -omega_set^2 -2*pres_ctrl.delta_rpi*pres_ctrl.omega_set];
pres_ctrl.Aresd_nom = eye(2) + pres_ctrl.Ares_nom*glb_time.ts_inv;
pres_ctrl.a11d = 1;
pres_ctrl.a12d = glb_time.ts_inv;
pres_ctrl.a21d = -pres_ctrl.omega_set^2*glb_time.ts_inv;
apres_ctrl.a22d = 1 -2*pres_ctrl.delta_rpi*pres_ctrl.omega_set*glb_time.ts_inv;

pres_ctrl.Bres = [0; 1];
pres_ctrl.Cres = [0 1];
pres_ctrl.Bresd = pres_ctrl.Bres*glb_time.ts_inv;
pres_ctrl.Cresd = pres_ctrl.Cres;
%[text] #### Sogi
sogi_delta = 1;
kepsilon = 2;
sogi = sogi_filter(omega_set, sogi_delta, kepsilon, glb_time.ts_afe); %[output:47757a60]
%[text] #### Current control parameters DQ PI
dqvector_pi.kp_inv = 0.5;
dqvector_pi.ki_inv = 45;
dqvector_pi.pi_ctrl = dqvector_pi.kp_inv + dqvector_pi.ki_inv/s;
dqvector_pi.pid_ctrl = c2d(dqvector_pi.pi_ctrl, glb_time.ts_inv);
dqvector_pi.plant = 1/(s*grid_emu.trafo.Ld1 + 1);
dqvector_pi.plantd = c2d(dqvector_pi.plant, glb_time.ts_inv);

G = sogi.fltd.alpha * dqvector_pi.pid_ctrl * dqvector_pi.plantd;
figure; margin(G, options);  %[output:429dc069]
grid on %[output:429dc069]
%[text] #### Single phase inverter - with resonant PI and virtual DQ
single_phase_inverter_ctrl = ctrl_single_phase_inverter_setup(glb_time.ts_inv, pres_ctrl.omega_set, ...
    dqvector_pi.kp_inv, dqvector_pi.ki_inv, pres_ctrl.kp_rpi, pres_ctrl.ki_rpi, pres_ctrl.delta_rpi);
%[text] #### 
%[text] ### Local time alignment to master time
kp_align = 0.25;
ki_align = 18;
lim_up_align = 0.05;
lim_down_align = -0.05;
%[text] ### Simulation parameters: speed reference, load torque for energy production application
run('n_sys_generic_1M5W_torque_curve');
torque_overload_factor = 1;
%[text] ### Simulation parameters: speed reference, load torque for driver application
% rpm_sim = 3000;
rpm_sim = 17.8;
% rpm_sim = 15.2;
omega_m_sim = psm.omega_m_bez;
omega_sim = omega_m_sim*psm.number_poles/2;
tau_load_sim = psm.tau_bez/5; %N*m
b_square = 0;
%[text] ### Settings Global Filters
filters = setup_global_filters(glb_time.ts_afe, glb_time.ts_inv, glb_time.ts_dab, glb_time.tc);
%[text] ## Power semiconductors modelization, IGBT, MOSFET,  and snubber data
%[text] ### Diode rectifier
% ABB 5SDF 0131Z0401
diode.rectifier.Vf = 0.977;
diode.rectifier.Rdon = 22e-6;
diode.rectifier.Cj = 0;             % F
diode.rectifier.Irm = -75;          % A
diode.rectifier.didt = -30;         % A/us
diode.rectifier.trr = 5;            % us
diode.rectifier.Qrr = 325e-6;       % C
diode.rectifier.Ifm = 2000;         % A
diode.rectifier.Vr = -50;           % V
diode.rectifier.Err = 15e-3;        % J
diode.rectifier.Rth_JC = 0.004;     % W/K
diode.rectifier.Rth_CH = 0.003;     % W/K
%[text] ### HeatSink settings
% Aluminum plate liquid cooled with a size fit for primepack2
% heat exchange made by an aluminum plate with a liquid flow > 28 l/min
% "A" as "ambient" here means water: so HA means delta temperature between water and
% heatsink surface
% moreover the delta temperature between water in and water out is maximum
% 5K assuming a overall power losses of 2kW 

weight = 0.150;                         % kg
no_weight = 0.150/10;                   % kg - when /10 is applied thermal inertia is not accounted 
cp_al = 900;                            % specific heat_capacity J/K/kg - aluminum
heat_capacity_hs = cp_al * weight;      % J/K
thermal_conductivity_al = 160;          % W/(m K) - aluminum
Rth_switch_HA = 15/1000;                % K/W 
Rth_mosfet_HA = Rth_switch_HA;          % K/W
Rth_diode_HA = Rth_switch_HA;           % K/W
Tambient = 40;                          % degC - water temperature
DThs_init = 0;                          % degC

heatsink = liquid_cooled_plate_2kw_setup(weight, no_weight, cp_al, heat_capacity_hs, thermal_conductivity_al, ...
    Rth_switch_HA, Rth_mosfet_HA, Rth_diode_HA, Tambient, DThs_init);
%[text] ### DEVICES settings (IGBT)
% infineon_FF650R17IE4D_B2;
% infineon_FF650R17IE4;
% infineon_FF1200R17IP5;
% danfoss_DP650B1700T104001;
% infineon_FF1200XTR17T2P5;
% infineon_FF1800R23IE7;
% infineon_FF900R12IE4;
% mitsubishi_CM1200DW_24T;
used_device = 'mitsubishi_CM1200DW_24T';

igbt.inv = device_igbt_setup(used_device, glb_time.fPWM_INV, hwdata.inv.udc_nom);
igbt.afe = device_igbt_setup(used_device, glb_time.fPWM_AFE, hwdata.afe.udc_nom);
igbt.dab = device_igbt_setup(used_device, glb_time.fPWM_DAB, hwdata.dab.udc1_nom);
igbt.psfbc = device_igbt_setup(used_device, glb_time.fPWM_PSFBC, hwdata.psfbc.udc1_nom);
igbt.cllc = device_igbt_setup(used_device, glb_time.fPWM_CLLC, hwdata.cllc.udc1_nom);

%[text] ### DEVICES settings (MOSFET)

% wolfspeed_CAB760M12HM3
% infineon_FF1000UXTR23T2M1;
% danfoss_SKM1700MB20R4S2I4
used_device = 'danfoss_SKM1700MB20R4S2I4';

mosfet.inv = device_mosfet_setup(used_device, glb_time.fPWM_INV, hwdata.inv.udc_nom);
mosfet.afe = device_mosfet_setup(used_device, glb_time.fPWM_AFE, hwdata.afe.udc_nom);
mosfet.dab = device_mosfet_setup(used_device, glb_time.fPWM_DAB, hwdata.dab.udc1_nom);
mosfet.psfbc = device_mosfet_setup(used_device, glb_time.fPWM_PSFBC, hwdata.psfbc.udc1_nom);
mosfet.cllc = device_mosfet_setup(used_device, glb_time.fPWM_CLLC, hwdata.cllc.udc1_nom);
%[text] ### DEVICES settings (Ideal switch)
used_device = 'silicon_high_power_ideal_switch';
ideal_switch = device_ideal_switch_setting(used_device, glb_time.fPWM_AFE, hwdata.afe.udc_nom);
ideal_switch.afe = device_ideal_switch_setting(used_device, glb_time.fPWM_AFE, hwdata.afe.udc_nom);
ideal_switch.inv = device_ideal_switch_setting(used_device, glb_time.fPWM_INV, hwdata.inv.udc_nom);
ideal_switch.dab = device_ideal_switch_setting(used_device, glb_time.fPWM_DAB, hwdata.dab.udc1_nom);
ideal_switch.psfbc = device_ideal_switch_setting(used_device, glb_time.fPWM_PSFBC, hwdata.psfbc.udc1_nom);
ideal_switch.cllc = device_ideal_switch_setting(used_device, glb_time.fPWM_CLLC, hwdata.cllc.udc1_nom);
%[text] ### Setting Global Faults
time_aux_power_supply_fault = 1e3;
%[text] ### Lithium Ion Battery
% nominal_battery_voltage_1 = hwdata.cllc.udc1_bez;
nominal_battery_voltage_1 = hwdata.dab.udc1_bez;
% nominal_battery_voltage_1 = hwdata.afe.udc_nom;
% nominal_battery_voltage_2 = hwdata.cllc.udc2_bez;
nominal_battery_voltage_2 = hwdata.dab.udc2_bez;
% nominal_battery_voltage_2 = hwdata.afe.udc_nom;
nominal_battery_power = 250e3;
initial_battery_soc = 0.85;
lithium_ion_battery_1 = lithium_ion_battery_setup(nominal_battery_voltage_1, nominal_battery_power, initial_battery_soc, glb_time.ts_dab); %[output:0011e885]
lithium_ion_battery_2 = lithium_ion_battery_setup(nominal_battery_voltage_2, nominal_battery_power, initial_battery_soc, glb_time.ts_dab); %[output:83a3d105]
lithium_ion_battery_1.R0 = lithium_ion_battery_1.R0/2;
lithium_ion_battery_1.R1 = lithium_ion_battery_1.R1/2;
lithium_ion_battery_2.R0 = lithium_ion_battery_2.R0/2;
lithium_ion_battery_2.R1 = lithium_ion_battery_2.R1/2;
lithium_ion_battery_1.C1 = lithium_ion_battery_1.C1/50;
lithium_ion_battery_2.C1 = lithium_ion_battery_2.C1/50;

%[text] ### Load
trafo_load_name = 'Load Single Phase Transformer';
trafo_load_pwr_nom = 225e3;
trafo_load_u1_nom = 400;
trafo_load_n1 = 50;
trafo_load_n2 = 1;
trafo_load_u2_nom = trafo_load_u1_nom/trafo_load_n1*trafo_load_n2;
% trafo_load_f_nom = 50;
trafo_load_f_nom = frequency_set;
trafo_load_eta = 98;
trafo_load_ucc = 5;
trafo_load_i1m = 10;
trafo_load_p_iron = 2e3;
output_transformer = single_phase_transformer_setup(trafo_load_name, trafo_load_pwr_nom, trafo_load_u1_nom, ...
    trafo_load_u2_nom, trafo_load_n1, trafo_load_n2, trafo_load_f_nom, trafo_load_eta, trafo_load_ucc, ...
    trafo_load_i1m, trafo_load_p_iron);

uload = 2;
rload = uload / output_transformer.i2_nom;
lload = 250e-6 / output_transformer.n12^2;

% rload = 0.86/m12_load_trafo^2;
% lload = 3e-3/m12_load_trafo^2;
%[text] ### C-Caller Settings
open_system(model);
Simulink.importExternalCTypes(model,'Names',{'mavgflt_output_t'});
Simulink.importExternalCTypes(model,'Names',{'dsmavgflt_output_t'});
Simulink.importExternalCTypes(model,'Names',{'mavgflts_output_t'});
Simulink.importExternalCTypes(model,'Names',{'bemf_obsv_output_t'});
Simulink.importExternalCTypes(model,'Names',{'bemf_obsv_load_est_output_t'});
Simulink.importExternalCTypes(model,'Names',{'dqvector_pi_output_t'});
Simulink.importExternalCTypes(model,'Names',{'sv_pwm_output_t'});
Simulink.importExternalCTypes(model,'Names',{'sv_pwm_cm_output_t'});
Simulink.importExternalCTypes(model,'Names',{'global_state_machine_output_t'});
Simulink.importExternalCTypes(model,'Names',{'first_harmonic_tracker_output_t'});
Simulink.importExternalCTypes(model,'Names',{'dqpll_thyr_output_t'});
Simulink.importExternalCTypes(model,'Names',{'dqpll_grid_output_t'});
Simulink.importExternalCTypes(model,'Names',{'rpi_output_t'});
Simulink.importExternalCTypes(model,'Names',{'phase_shift_flt_output_t'});
Simulink.importExternalCTypes(model,'Names',{'sogi_flt_output_t'});
Simulink.importExternalCTypes(model,'Names',{'linear_double_integrator_observer_output_t'});

%[text] ### **Remove Scopes Opening Automatically**
open_scopes = find_system(model, 'BlockType', 'Scope');
for i = 1:length(open_scopes)
    set_param(open_scopes{i}, 'Open', 'off');
end

%[text] ### Enable/Disable Subsystems
if use_mosfet_thermal_model
        set_param('ls_upqc/left_shunt_universal_power_quality_compensator/dab_mod1/dcdc_with_galvanic_isolation/full_bridge_1/full_bridge_ideal_switch_based', 'Commented', 'on');
        set_param('ls_upqc/left_shunt_universal_power_quality_compensator/dab_mod1/dcdc_with_galvanic_isolation/full_bridge_1/full_bridge_mosfet_based_with_thermal_model', 'Commented', 'off');
        set_param('ls_upqc/left_shunt_universal_power_quality_compensator/dab_mod1/dcdc_with_galvanic_isolation/full_bridge_2/full_bridge_ideal_switch_based', 'Commented', 'on');
        set_param('ls_upqc/left_shunt_universal_power_quality_compensator/dab_mod1/dcdc_with_galvanic_isolation/full_bridge_2/full_bridge_mosfet_based_with_thermal_model', 'Commented', 'off');
        
        set_param('ls_upqc/left_shunt_universal_power_quality_compensator/shunt_active_filter/saf_inverter/three_phase_inverter_ideal_switch_based_model', 'Commented', 'on');
        set_param('ls_upqc/left_shunt_universal_power_quality_compensator/shunt_active_filter/saf_inverter/three_phase_inverter_igbt_based_with_thermal_model', 'Commented', 'on');
        set_param('ls_upqc/left_shunt_universal_power_quality_compensator/shunt_active_filter/saf_inverter/three_phase_inverter_mosfet_based_with_thermal_model', 'Commented', 'off');
        
        set_param('ls_upqc/left_shunt_universal_power_quality_compensator/voltage_stabiliser/inverter/three_phase_inverter_ideal_switch_based_model', 'Commented', 'on');
        set_param('ls_upqc/left_shunt_universal_power_quality_compensator/voltage_stabiliser/inverter/three_phase_inverter_igbt_based_with_thermal_model', 'Commented', 'on');
        set_param('ls_upqc/left_shunt_universal_power_quality_compensator/voltage_stabiliser/inverter/three_phase_inverter_mosfet_based_with_thermal_model', 'Commented', 'off');
else
    if use_thermal_model
        set_param('ls_upqc/left_shunt_universal_power_quality_compensator/dab_mod1/dcdc_with_galvanic_isolation/full_bridge_1/full_bridge_ideal_switch_based', 'Commented', 'on');
        set_param('ls_upqc/left_shunt_universal_power_quality_compensator/dab_mod1/dcdc_with_galvanic_isolation/full_bridge_1/full_bridge_mosfet_based_with_thermal_model', 'Commented', 'off');
        set_param('ls_upqc/left_shunt_universal_power_quality_compensator/dab_mod1/dcdc_with_galvanic_isolation/full_bridge_2/full_bridge_ideal_switch_based', 'Commented', 'on');
        set_param('ls_upqc/left_shunt_universal_power_quality_compensator/dab_mod1/dcdc_with_galvanic_isolation/full_bridge_2/full_bridge_mosfet_based_with_thermal_model', 'Commented', 'off');
        
        set_param('ls_upqc/left_shunt_universal_power_quality_compensator/shunt_active_filter/saf_inverter/three_phase_inverter_ideal_switch_based_model', 'Commented', 'on');
        set_param('ls_upqc/left_shunt_universal_power_quality_compensator/shunt_active_filter/saf_inverter/three_phase_inverter_igbt_based_with_thermal_model', 'Commented', 'off');
        set_param('ls_upqc/left_shunt_universal_power_quality_compensator/shunt_active_filter/saf_inverter/three_phase_inverter_mosfet_based_with_thermal_model', 'Commented', 'on');
        
        set_param('ls_upqc/left_shunt_universal_power_quality_compensator/voltage_stabiliser/inverter/three_phase_inverter_ideal_switch_based_model', 'Commented', 'on');
        set_param('ls_upqc/left_shunt_universal_power_quality_compensator/voltage_stabiliser/inverter/three_phase_inverter_igbt_based_with_thermal_model', 'Commented', 'off');
        set_param('ls_upqc/left_shunt_universal_power_quality_compensator/voltage_stabiliser/inverter/three_phase_inverter_mosfet_based_with_thermal_model', 'Commented', 'on');
    else
        set_param('ls_upqc/left_shunt_universal_power_quality_compensator/dab_mod1/dcdc_with_galvanic_isolation/full_bridge_1/full_bridge_ideal_switch_based', 'Commented', 'off');
        set_param('ls_upqc/left_shunt_universal_power_quality_compensator/dab_mod1/dcdc_with_galvanic_isolation/full_bridge_1/full_bridge_mosfet_based_with_thermal_model', 'Commented', 'on');
        set_param('ls_upqc/left_shunt_universal_power_quality_compensator/dab_mod1/dcdc_with_galvanic_isolation/full_bridge_2/full_bridge_ideal_switch_based', 'Commented', 'off');
        set_param('ls_upqc/left_shunt_universal_power_quality_compensator/dab_mod1/dcdc_with_galvanic_isolation/full_bridge_2/full_bridge_mosfet_based_with_thermal_model', 'Commented', 'on');
        
        set_param('ls_upqc/left_shunt_universal_power_quality_compensator/shunt_active_filter/saf_inverter/three_phase_inverter_ideal_switch_based_model', 'Commented', 'off');
        set_param('ls_upqc/left_shunt_universal_power_quality_compensator/shunt_active_filter/saf_inverter/three_phase_inverter_igbt_based_with_thermal_model', 'Commented', 'on');
        set_param('ls_upqc/left_shunt_universal_power_quality_compensator/shunt_active_filter/saf_inverter/three_phase_inverter_mosfet_based_with_thermal_model', 'Commented', 'on');
        
        set_param('ls_upqc/left_shunt_universal_power_quality_compensator/voltage_stabiliser/inverter/three_phase_inverter_ideal_switch_based_model', 'Commented', 'off');
        set_param('ls_upqc/left_shunt_universal_power_quality_compensator/voltage_stabiliser/inverter/three_phase_inverter_igbt_based_with_thermal_model', 'Commented', 'on');
        set_param('ls_upqc/left_shunt_universal_power_quality_compensator/voltage_stabiliser/inverter/three_phase_inverter_mosfet_based_with_thermal_model', 'Commented', 'on');
    end
end


%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"onright","rightPanelPercent":5.5}
%---
%[output:4a4e8333]
%   data: {"dataType":"text","outputData":{"text":"Device AFE_THREE_PHASE: afe690V\nNominal Voltage: 690 V | Nominal Current: 2.324276e+02 A\nCurrent Normalization Data: 328.70 A\nVoltage Normalization Data: 563.38 V\n---------------------------\n","truncated":false}}
%---
%[output:6b916fd2]
%   data: {"dataType":"text","outputData":{"text":"Device INVERTER: inv690V_250kW\nNominal Voltage: 550 V | Nominal Current: 370 A\nCurrent Normalization Data: 523.26 A\nVoltage Normalization Data: 449.07 V\n---------------------------\n","truncated":false}}
%---
%[output:15811d7e]
%   data: {"dataType":"text","outputData":{"text":"Single Phase DAB: DAB_1200V\nNominal Power: 250000 [W]\nNormalization Voltage DC1: 1200 [V] | Normalization Current DC1: 250 [A]\nNormalization Voltage DC2: 1200 [V] | Normalization Current DC2: 250 [A]\nInternal Tank Ls: 3.819719e-05 [H] | Internal Tank Cs: 1.151294e-04 [F]\n---------------------------\n","truncated":false}}
%---
%[output:201f4793]
%   data: {"dataType":"text","outputData":{"text":"Single Phase PSFBC: PSFBC_1200V\nNominal Power: 275000 [W]\nNormalization Voltage DC1: 1200 [V] | Normalization Current DC1: 250 [A]\nNormalization Voltage DC2: 1200 [V] | Normalization Current DC2: 250 [A]\nInternal Tank Ls1: 1.212121e-05 [H] | Internal Tank Ls2: 1.212121e-05 [H]\n---------------------------\n","truncated":false}}
%---
%[output:4ca4d289]
%   data: {"dataType":"text","outputData":{"text":"Single Phase DAB: Three_phase_DAB_1200V\nNominal Power: 250000 [W]\nNormalization Voltage DC1: 1200 [V] | Normalization Current DC1: 750 [A]\nNormalization Voltage DC2: 1200 [V] | Normalization Current DC2: 750 [A]\nInternal Tank Ls: 1.200000e-04 [H] | Internal Tank Cs: 750 [F]\n---------------------------\n","truncated":false}}
%---
%[output:25c725ab]
%   data: {"dataType":"text","outputData":{"text":"Single Phase CLLC: CLLC_1200V\nNominal Power: 250000 [W]\nNormalization Voltage DC1: 1200 [V] | Normalization Current DC1: 250 [A]\nNormalization Voltage DC2: 1200 [V] | Normalization Current DC2: 250 [A]\nInternal Tank Ls: 1.548074e-05 [H] | Internal Tank Cs: 2.840705e-06 [F]\n---------------------------\n","truncated":false}}
%---
%[output:45652a74]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEcAAAArCAYAAAAqhpU+AAAHOklEQVR4AeyaZYhUbRTH\/3ftxhb1gy2I3e3aiojdYqFYiInYuio2BmIHYmB9EAMDFTtRVBRbcQ2wxW7nnd\/hvcM6zrvf5t7FdxbO3rnPjed5\/nPO\/9TEBXz6e\/fuXWDUqFGBq1evBrp06RJ49uxZ4P79+4GePXsGXr169duqGB8+fPgf47\/dFIWTOPn0lyVLFjVo0ECDBw\/W7du3FQRK7du3V7NmzdSmTRsVKVIkJN26dVPFihWVPXt2T1frGzjssnnz5tqzZ48WLFig7t272+cOHTpo165dunfvnoIaY3Lq1Cm1bNlSv3794jHPxFdwjhw5osmTJytfvnxauHChmjZtqtmzZ2v8+PF68OCBnj9\/bnLz5k3TrKC5eQYME\/kGztu3b7V161Yzq8TERDVs2FBTp07V3r17FeQhLV261AADtA0bNqhRo0bKkSMHa\/ZM4jybKWyir1+\/KnPmzMqbN6\/Onz+vatWqGQCVKlUybZo5c6ZmzJgRkk6dOil16tRhb4nuqW\/gZMuWTd++fdPQoUN15swZZc2aVf3799f79++1bNkyI+u6devKlc6dO+vFixfRRSPs7b6Bky5dOk2fPl1BN645c+aoUKFCxjnz5s3T9u3bdfz48d9ky5Ytyp07d9jyo3vqGzhsK0OGDCpXrpxy5sypL1++qE6dOgbUjRs3tHjxYo0bNy4kEHUwNuIxz8Q3cH78+GGag4uGbNu2bSvcOKSbkJCgz58\/q1atWiGpWrWq0qRJ4xkwTOQbOG\/evNHr16914MABjRw50nhm06ZN+vDhg\/Lnz69BgwapRYsWIalfv77QNBbtlfgGTtIN4oWC6YMKFCigjx8\/iugZ00p6jx+ffQMnV65cFvzhsgsXLqzVq1dbpPzw4UNdunRJeCdM6X\/prRzH0ZgxYzR27FiLcQYOHGhxD0Gfmz4Q\/7he6+\/2VhHsglzp1q1b2r9\/v3FNiRIldPnyZSPqpJ6Kz5D0iRMn9P379whvis6Qb2aFNyIjnz9\/vkgsXQEc3PrLly9Vo0YNYVqPHj0y77V7924DLjpQ\/PlW38AhEiZ9gGuSpgmYF+DMnTvXMvHWrVtr0aJFFk1zDQ\/35zaiM+IbOHgkXHOklABwSC3cLf\/8+dPMjtjIHfPi6Dk4RLlEu9OmTbNcqVWrVpZTwSvIqlWrVKpUKfNWEDZjvXv3VuXKlQXnECR6AQxzeA5OpkyZ1KdPHw0bNsz449ChQwIozhGukYCuX7\/ekk+iZHKvjh07mplNmDCBdXsinoOTKlUqUa6YNGmSlUUhZMdxlCdPHhOSS8qmK1as0NGjR42s16xZo169ehkgXqYQnoODl0JT8ERoB6UKCNnlE9IHYp2iRYtaelG8eHGhbf369fv7s3K8FJtt166dlSn69u1rNRy4CNX49OmTpQ9cB8DSpUtryJAhQot4lnu8Es81h1Lovn37rHZDakCn4fr163I1Bw+GtyLXwtQSgyVUTJGcC63zChjm8RwcJqXNQjZOarBjxw7TIMYRYh8AoxpYsmRJrV27VvHx8cZHXnoq1uILOHfu3FHZsmWtL1W9enWdPXtWHOlVAQgaAgEHG3miEA\/v9OjRw2rIdCxq1qxp5dMRI0ZoypQp1qHo2rWrHdkUHpA+WLDPp40bN9q9tWvXtgI+nMZ1ElveSe0aPsNkSU3wjIxRy\/YcnPTp04vUgE0gBIM7d+60+g1agymRqeO6CRAxqcePH4tzElE817Zt23Ts2DErcbBZ3hNJTp48KUofhw8fthgJrmMu7uXdOALuSZs2rS5cuGA5HqkK\/AaAnoPDwlauXGnNOpp2V65cUZkyZRi2YlbGjBnVuHFja+A9ffpUAMNGqDnzmW4FdR\/HcaxbAaD2cIR\/586d0+bNm4U24v2WLFli5RBurVChggoWLGjVReYnCj99+rS1iOA9uqu+gMPiwoVNBvvkYgOAgkngrZYvX65r165ZPwu3z7j7LCkGpuCe\/3sMHSDx0aNHh74ItAgzDN0Q9oF38SW4wykGHBYUFxcn+GXixImWQsAj8BF8QQLKt4naP3nyRIAEoRNQUkkkOMTLMX7x4kVeZxk92gCfwGN0V0lB7GKEf1WqVDFzBSS0NEWB464Xs6GuDPfQFSX2wSyKFSsmAKMYX69ePQESGgdonFOgb9Kkie7evWvkTeGeDXOMj4+3jimf3XnCj9SsHcexLggc5zk49KUiLXDAgAHCa+DJiIUAB+\/FjwzgJUobNAJx8xAzWkNCiqY4jmP5Ghxz8OBBkbzOmjXL+IQAknEEE0PDmJ91uOAwN2MAzReCtqJxnoPjLij8COnSpmHDECVlUTZQvnx5c+dchzTDn4vmeYoBh01CuPDOunXrBDnzex1X0IDwQhdeJiHY4+LZaEiKAYdsHG3BXCIJ17gnGiD81ztTDDj\/tUA\/x2PgJIN+DJwYOMkgkMylmObEwEkGgWQuxTQnBk4yCCRz6R8AAAD\/\/yZ2M\/sAAAAGSURBVAMAggh+d4D89IEAAAAASUVORK5CYII=","height":43,"width":71}}
%---
%[output:20fe7200]
%   data: {"dataType":"text","outputData":{"text":"Induction Machine: ABB M3BP 355MLB 6 261kW\nIM Normalization Voltage Factor: 375.6 V | IM Normalization Current Factor: 581.2 A\nRotor Resistance: 0.00274 Ohm\nMagnetization Inductance: 0.00376 H\n---------------------------\n","truncated":false}}
%---
%[output:585fcea9]
%   data: {"dataType":"text","outputData":{"text":"Permanent Magnet Synchronous Machine: WindGen\nPSM Normalization Voltage Factor: 365.8 V | PSM Normalization Current Factor: 486.0 A\nPer-System Direct Axis Inductance: 0.00624 H\nPer-System Quadrature Axis Inductance: 0.00756 H\n---------------------------\n","truncated":false}}
%---
%[output:3ab2eff1]
%   data: {"dataType":"text","outputData":{"text":"PSM EKF Fully controllable\nPSM EKF is stable.\n","truncated":false}}
%---
%[output:98818507]
%   data: {"dataType":"text","outputData":{"text":"IM EKF Fully controllable\nIM EKF is stable.\n","truncated":false}}
%---
%[output:47757a60]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEcAAAArCAYAAAAqhpU+AAAMeUlEQVR4AeTadYxdxRcH8PMuVnxxC9ACwYoHJ0CLhCYk0OAWWEpwEoJLkBQNLn\/gEEqQoMHdLTjFAiTIogGCFJfa731mO8vs\/b23VCClZZPvu3NHzp35zjlnZs5stcIKK4x\/8sknx\/9X\/w477LDxAwYMaIlq7bXXjltuuSXGjBkT\/8W\/s88+Oz744IOWqNZcc8145ZVX4quvvmrLzahRo2JUH+jq6oquGkaOHBkjJyCXkdH2I\/\/Cgmr55ZePH374Ib755pu23bvggguiL4wYMSLquOOOOyIjl5ExfPjwOOaYYxIOOeSQOOOMM+Lqq69ORLbtwFQqqKbGd\/v16xfQ0dERv\/32W7z22muJpMGDB8eGG24Y6623XqyxxhoJK664Yiy11FL\/CD788MM+hz9R5HQ1TYYUA5Fuh3feeSfqYEqACFrav39\/onohl6277rqxzDLLhDpzzz13wEILLRRLLrlkrLPOOrHvvvvGCSecELfddls8++yzLf1EO\/\/RKn\/TTTft1Y\/6SyJnxhlnjBlmmKFelt6\/+OKL5E8ef\/zxeO6551K6HTkarLbaarHFFlvEHnvsEeedd17Ccsstl8ySOTErZvbWW2+FxaCjo0OzBNrUv3\/\/QCKipHO5ftx\/\/\/3JfJnjzjvvHDTNsy\/TvOSSS5LWbbzxxn361dSB4ufwww+PykybnYUXXrgo+jPZKl8eDBkyJI466qiExx57LG644YaU7uzsDITMMcccscsuu8SZZ575p8AJqZdeeikOPPDAmH\/++WObbbYJnVd\/QnEyO+Qgu05UruNZJw1hgLTjjjsuXn75ZdXijz\/+iI8\/\/jilmROklxY\/FqcXX3wxqnvuuSfN4DzzzNOiWnfW999\/H3vttVeCgZ522mkBO+ywQyIBET5WQksOmbZJn3zyyfHII48kXHzxxTH77LPLjosuuih+\/\/33ZDpIWn\/99WPVVVdNZfkna1RJFJOgYblO\/Ym0Z555Jt57770km4wjjjgitt9++zRZ+lZORtme2X7yySfdmnPNNdfE0ksvndSP86OKZWU+g6aw9x133DF0jHYYYHMDFe3w6quvJjFmfuutt+6px+xojcKffvopZplllp4yk8QcRxQrIHMy8+obJI0aO3ZsaPvRRx9FBn\/V0dGR3pGjjr4r\/\/TTT8P7119\/HawFOfPNN1+oR24Gmc1NcXqtGo1GSpQ\/tIPN5bzm7jn22Wef\/JqemN18883jjTfeCBqTMoufMq+sk\/MRxEnefvvtkWfwgQceiD333DPILkTFl19+GXfddVfSgJxPJs3I754008onvfrqq8cpp5ySzNr7nHPOmZy9SfYONr7luzz94w+lk0Oed9554+mnn07en2orYHNs7+GHH45Go5vAI488MtV5\/fXXgzb8+OOPcfrpp8cvv\/yiyf9hSNMnyfz555+D5tBKWlfXTHXM2KWXXhrqLr744sn5I88MG5jyBx98MLbbbrswKW+\/\/bZmwV\/yLxYAy3\/KbP7QGIPXtvkangcccEDyi1dddVUyLe5CWQmEG5f6iZxvv\/027rvvvlQnb6efeOKJWHDBBZPNKtDhTJyZHjZsmOzA8rhx41K6\/BkwYEBsttlmgdAyX5pmIglZ77\/\/fjIpvmlkc0et\/Pjjj0\/fll555ZVj\/\/33l+z5lsn59ddf04DPOeecRJYKfB+ypL\/77rvk3wzWO6KWWGIJyfS9tdZaK5llypjwYwKySQ0cODASOcpOPfXUHp9TmhSHppyq0xYDgmxmWNZZ6tgKzIe6MwsOlawS5Fx33XXxwgsvpOxZZ501+YZSlllUmL9lMr2bpJlnnjmZ2+677x477bRTZAKUAxI9taWxzNhEkC+\/hDyTLW+jjTaKatlll5XuBd7a0sqsehX08UJTSqia36UHNmeCXEQxF6uXfHjqqaeCaUtXVRWLLrpomt3cPmuDcsjk2J9lMtSlZTRcHU\/v0hlMlk\/i2\/TFZDG\/XE7LkOiddle0xApx9913p\/2GAqApNEIaOOVW5qOMGdCmEoObRwEdlrfJJpuEFUY6m5M2ZGqvszZy0gaw1VZb9WixNnvvvbei8H17l1tvvTW9W4XsnLNM38hlfObRRx\/da5+TGk34YUK2DJkcimCfNqE4PSpqPdtsswWvzd9kB5hKmz\/ZqTYajbjiiiuSQzbz2f+YIWoqr0RX88ix7bbbNiVEcuhlW\/X4okaj29HbSFp9mG00\/2hDlqk\/c801VzM3wh5IvTvvvDP5G1rmHGYSyURGo9EtU\/6bb76ZNqUa075m7CYOPvjgtOGUZ9lHqDQZFEJa38hLPuezzz4LoQuzZFWhWjoKnGomApHqALUkyErBcUvX4SPIk1+21Z7ayveN3XbbLS3njhf8i07KVy\/3R75yfoa5WLG0R+Iqq6ySNC3LlN8OCBk0aFCceOKJiahcz15K2nc22GADyajYbUoVP8i4\/vrrU4dl06jLLrtMsgeEmNX99tuvJ6+eQJpVD0n1Mu9klt8x6IceeigyoeqAd\/nKvYM+1eV613flkwImxQy1sUpxB9KV3TEVKuHDCkvQoLIOx1Z2tqxbTyOwbJvTZNbrZkJzHU8Ey6\/XrculgZ9\/\/nmvarlOOxkqk63ct8rJqqivCtMSbEyZHFhQct+ZGHi3FDNB6clF8jmT23hqtTOh4Pt8H5KAX5PHDCfHvLQtMU2SQyOoPzNoBSbCVMqBTk66EofJ+412AmzrM+qn2HZtpof8SujAobOvwYi8ZVi6bfBAGpQJkgMS+5I1LZVN0b0VLQKE5PgLohAnUO5w56TMH\/wb0ddEWfUm6t7KtY1drLAA2DWDs4mddauP2D\/xDYLkOUAu6tfKR5R5+exV5v1TaRPWqu\/yLr\/88kj3VjZBzjoyS4wePTpUEmFDAjLsLkUD3QSI2DmP8Fue3pEH6peyaJjzEzNkfmXZ1EzTbiQ5nxlH9r9Wu0qUDQmtOnjTTTel2wMHNLthyOaTL+jEUwxaKMB5yvZcbFdgyXbe9j\/vOH0DSWQwPfHck046KZzKhQs8hTOl20Gdelktr5c8dXN5+ZTWn1133TXFshxgS\/9rg1vRGKfdqP0JC4izCKLXinq9Ot26z0KyXTM4ZT\/66KPpbom2nXvuuSkCR6PKxuK5Zkts+thjj0313RaI0InrILUOvuyv8nKdvp7K9MVBVJAMD66Kyv8bqMRs+YdGo\/s0qwGI0DmQ2uIbrIHRAhDrAQN3qqUt2tQhHGDPQctuvPHGFLZABlnalvVplMMf7eTUmR\/t8gR5NJRJZqhvMQDtoZQ5MelGo3vcJsPh2\/8NuMIxWZUbhH7N61mFpTDEIE0QykeRYEDA7wCiDFT8JZ9yvSNOiKCUl4ka3rwrJ2tYM8zKT5EBZd0y7duAAGQwyQxkIQ0QCAgFaWbrKcyqrlgQYs8\/\/\/y49tpr091Y+S3uwP8N0FwRxIpWiJe4Hikr6pDVxqWbfLbbDtlPiNtyaFYnp1uhS2FSZkBGBm2y7We2yOcQBb0PPfTQdPuALBA60OHch9x+Yp76z2w9XcUgVqQPsbTzyiuvTMH5VrIohTuuSoy4TkyrBgbYDuy3XpbznIGQxLZpVGmC\/BXC3W8JYFmyTRTtHDp0aDhUugC8+eabgzkCbQMro+0F0NaMvMUgA+qrZjk2QffyvUwL1Vb+i0Fwq+6UxWuoFhUrG01uGilMEUmAqFIWswMOnWaZYb6KGXqCvOeffz5AXe7A4JFANthiMHHkASKRCtIgH1qNjdbk\/xuo2KcZRETZWabhmlYnyvxWabNfzy\/z6mlEkW8Q9hO2CvxQXUZ+1wfoaoZe+R5AIDARQBwgEZAK0rYbymw3EEsOIDZ\/w5P58ZU5P90+UK983aoSWN4WWWSRyPc4\/EI72EDVy8q8Vumcx7fwNQZiAALk\/CANAmbPb5hA\/ZpUIFVbZNhuIJZc4NP4SDLV8W8tlnMXDvLahiwWWGCBECDnuMRuzc6WW26Z\/isi+wc+YlIhkM0P0Zh6W98xUbYXyFpsscXi3XffTf+NcdZZZ6W4L21jlpD9DIKBqWYwNXEdt7HuyGmrAZdw0yHwL2jv2ybCjWqj0b28tyWHkM7OzrBMivUOHTo07H0uvPDCWGmllRT\/7eicyO8ZKDBFQAQMagbOM5BlAytYjyBkIhak7YbdcvQ1topTczh0bVEf7UwzzRTujASfEXPvvfemO\/J6vUl5tz0QqGoVp\/67v9fuW4i1PTjooIOir7H95T8vTcrAp7e6Vd0JTW8DnJLxVHUnNCXCpre2\/wMAAP\/\/qbeCtQAAAAZJREFUAwBl+TnvPr5WUwAAAABJRU5ErkJggg==","height":43,"width":71}}
%---
%[output:429dc069]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEcAAAArCAYAAAAqhpU+AAAHYUlEQVR4AeyaZ2gVWRTH\/y+2ta9dVBZjBQti7xoLBhULdsXYsBd0VezYsWNBVOy9f7Gj2HtBMeIHuzG2YMfe8\/b9DvseiTzfh9XMhE1CTmbm3pk79\/7n3HPO\/5yEeV3+2bdvn7dOnTreihUreqOiorwVKlTwbt682drCw8O9fqlevbp3\/fr13vj4+F+a8aYLcd4cfx\/5qczYHxMYP0wu\/zRu3Fh79uzRvHnz1LlzZztv27atdu3apTt37uju3bsmp0+fVrNmzRQfH\/9LM+5YOb9qFf0z6Bh\/5fxDIyMLB\/pcB+fo0aOaMGGC8ufPr\/nz5ysyMlIzZ87U2LFjde\/ePT19+tTk+vXrGj58uF68eBGY\/H892TWgvEZGhgsw\/MJ19LjqiYYMS3Tl8MXr16+1detWDRgwQLGxsWrQoIEmT54s31bT1atXtXjxYgMM0HxbSg0bNlTOnDl\/yyxH+jQEMPzC9Y8Dh\/3Y4OT158+flSVLFuXLl08XLlxQ1apVDQCf\/TFtmj59uqZNmxaQ9u3bK23atI5N0VVwsmfPri9fvmjw4ME6e\/assmXLpj59+ujt27dasmSJ6tevL5+xDkiHDh307NmzlAFOhgwZNHXqVHXs2FGzZs1S4cKFhc2ZM2eOtm\/frhMnTiSSLVu2KE+ePCkDHFaZMWNGlStXTrly5dKnT59Uu3ZtA+ratWtauHChxowZExAM9Zs3b3jMEXF1W3379s00BxeNsW3VqpVw4xjdSZMm6ePHj6pZs2ZAqlSponTp0jkCDC9xFZxXr17p5cuXOnDggIYNG2Z2ZuPGjXr37p0KFCig\/v37q2nTpgGpV6+e0DQm7oS4Ck7CBeKFnjx5ooIFC+r9+\/fKmjWr2FoJ73H63FVwcufObcEfLttHE7RixQqLlO\/fv6\/Lly8L78RW8nssrlOMt\/J4PBo1apRGjx5tMU6\/fv0s7iHo89MH4h+\/10px3gqudOPGDe3fv99sTYkSJRQdHW2GOqGn4hwjffLkSX39+tWRHebctgqyHLwR1GHu3LmCWPoFcHDrz58\/l4+Ni6314MED8167d+824IIM99ubXAWHSBj6gK1JSBPYXoAze\/ZsY+ItW7bUggULLJqmDw\/325EIMqCr4OCRcM3BjCzgQC38c\/7+\/bttO2Ijf1tSH10BhyiXaHfKlCnGlVq0aGGcCruCLF++XKVKlTJvhcGmrXv37qpUqZKwOQSJSQ0M47sCTubMmdWjRw8NGTLE7MehQ4cEUFwj9EFA161bZ+STKBnu1a5dO9tm48aNY+5JLq6AkyZNGpGuGD9+vNq0aSMMssfjUd68eU0glzdv3tTSpUt17NgxM9YrV65Ut27dDBCnKIQr4OCl0BQ8EdpBqgKD7Lcn0AdinaJFixq9KF68uNC2Xr16\/f9ZOV6KxbZu3drSFD179rQcDrYI1fjw4YPRB\/oBsEyZMho0aJDQIp7lHifEFc1hYWFhiV8NIH7NwYPhreBabLVYXwqVrQjnQut43glJPEMH3kiSvEmTJhYRk9iCNxHDJHw1Lh6tIRtYsmRJrVq1ShEREWaPnPJUzMdxcHgpXIrkVlxcnB4+fChfnUrnzp1TtWrVVKRIEdWtW1elS5cWGUGud+7cqePHj4sqBeydMZwQV8Ahd8xi\/TUpjiNGjDDtyJQpk9GE5s2bC55VrFgxlS1b1nI6pFN37NihGjVqWF556NChmjhxopVuOnXqZEdAIzRAQ33VOW3YsMHurVWrllU2MPb0w\/C7dOlihBdDjy2DsxEykOgnye8KOL179zYNQStIkVKGYVEkvwoVKmTGOEeOHFq7dq3OnDkjPBeaBBjklrdt22aaRO6HxfJsMDl16pTlhA4fPmzBI04ALeReonI8JPekT59eFy9etK0Oh8PwA6Ar4CxbtsyqmGjMlStXTDOYMDZo7969GjhwoG7dumWJd74ifArm\/vjxY8v\/AIrH47EyDtyMZ4PJ+fPnbctitwgLFi1aZHki7i1fvrz4EMRMaCb0hA9B7QyHwMdxBRwm9zPBKxEEEhWjUUeOHLHgD5XftGmTkU\/\/s3Av2v3X\/x4DB7wb25WPgJBZZBsGbvjhhLGoiPibkx04TCw8PFzEPETJTDgmJsbiIOzRo0ePhGBPSIIRaWOk0QDcP+2XLl1iGEt1oA3YE0IADDrczDqD\/KlcubJtV96Jo0h24KDexDzUzqlwYpjxavyzwerVqxUVFSWqFHg0QGJbsQW4pnLRqFEj3b592yqjVDRYMMeIiAgrJXMeBBdrIpnv8XisPASPcxwc3HOwCfbt21fENpRpYOAs6uDBg1bUo06O1pD8Aix\/6pT70BSPx2NEFhvDM7D6GTNmWBmHyJp2hC2GhvF+5mGI+P7wbtoAmnw2YQUa5zg4vrmE\/IVnET2vWbNGXbt2NWIKOUVYqFOJLiaZrMDBEJNEx5YEE\/q4h4kjeJlJvuIf50khyQqcpFjgr4yZCk4I9FLBSQUnBAIhulI1JxWcEAiE6ErVnFRwQiAQoitVc0KA8w8AAAD\/\/0gVVG8AAAAGSURBVAMAeqdpdxSJVAIAAAAASUVORK5CYII=","height":43,"width":71}}
%---
%[output:0011e885]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEcAAAArCAYAAAAqhpU+AAAIpklEQVR4AeyaeWzNWRTHT6sYW9UIapu0WokGVUvRaIggrWAEEYrgL6QjjTSCjIkQEqntL43tL8aWSDSKUFtTSu0dWyxRrdq3pkGodaafE\/fl19f3+\/W18TOVvCandznLPfd7z72\/u7zgfwN\/tggES+DPFoEAOLbQiATACYDjgIADKxA5AXAcEHBgeSLn7du3MmXKFCXyGzdulF69esm1a9cc1GvHmj9\/vgwZMkSeP3+udrFPO7Wz4r807dAe7TppwUcOeaucB5zmzZvLzp07lchbhX7W\/KpVq6Rjx46ydOnSOnUhuEuXLnLs2DEhWkzkHDx4UDD85s0bGTt2rPKt1pE3etQTXSYKjB34kK8RefHihcydO1ewTzuMnLGBDoQ96rBPdFEHjR49ukpEM9q0AQ\/CN3Sov3DhggwePFjMYNMOMoaQxfbevXvlwYMHMmLECI1oI+eJHAwaorEFCxZIixYtZN++fTJ8+HDD0jQ2NlY6d+4sd+\/e1fLp06c17dOnj8yaNUsePXokZ8+eVYIxceJEnUrkoTZt2sj69evVPu0wsitXrpTu3bvL1atXtU3ksAtAGzZsEOTghYaGwlICAGwTHfCQoX06TZkOR0dHqywgHD16VG3fu3dPxo8fL8uXL9eUPP2B\/+zZMwGszZs3122f07RpUw3XkydPaqdJ6Rhe3LhxQ1JSUqRt27ZK8fHxOio4C98XMbJmSm\/fvl2jlahCFoBIBw0apBFAJFCGsAkA1GEDGQb08OHDApFv164dojqQ2DQzYc2aNZKXl6c+qsC3fwQC4BEAPiPnm5xtgiM4BBA4SKRQfv36tU4Vq6IZORNlVp41b0KZaWat99Yz9qwy6DBV6DgAWHkmP2PGDI1UykQX8rRJ2UpEKlN64MCBdYscjDFKpIxQeXm5UGaUGC3qDZnO+eqUkcEhQprwZtSYysaOt56xZ3RJmQLoGSIqqLdSz5495cqVKzpt6Tg8pg9TkLyhrVu3ahYf6hQ5aEdGRuoaQQNMKcoQ+V27dul0Y01gUWQ+x1auU+j5IkANCwvzsJhKJgIAhzx1LPZMYSNI6GObAaKOjhIRpMnJyRrFrCHwiBLW0nfv3ukXmfWJAaBt+IZoz+RtwSESECJUaYy8lczUoo4pRRliFFkgGR0I\/p49e6rNbQMkUwJinQJoOldYWKhTACCwQUeQAQymLjYh1jVsMwDoMV2QZd1AFuBMpFGPDvaQxd7atWuFiAJI1i6+VjExMcJA0e9gQhFjdMwsiuRRIgwNH8PeNGfOHIFPanjoYod6KM+y6BHupmyVox4byEObNm3SKYAd5Kw8PuWmLVIAwiZ6ELKmHsABmIjzlkOWfiNLSpn+El3Gnm3koFQfiKhlpJkW+EMkMLLe0wGeN7GG8bFgq+DN86dc78Exo0p00SFSRpZIoOxEFSGh8ndWjqT9uUJKyyp8kpO+q+DgUEZOifyeWShxKwo89Gt6rvwIsrZpl\/+fwSmW\/KLyKqPm5NCP5jGAdm26GjmJ0WHy26+\/eCgxKkz8pZT4cHGLFiZFCpSZEmOHi9a7Cg4tZKf2ln\/+SlDK\/qO3+Es47hYtTIqoBCdCwWfw8NMXuQ6OU+O+HKpPda6DU586W1tfXAGn8pVMtm3bJv3795fExEThvPLlyxe\/fXv8+LFMmjRJ9SdPniwPHz6spmv2P+yBILMPqiboUMGuOD09Xdgk+hJzBZzLly8LB8mcnBw5dOiQnDhxQtji+3LAu+7z58+yevVqBef8+fMydepUycjIkA8fPlQRvX\/\/vnBUYWcLsf+pIuBQeP\/+vd4nzZw5U54+fWor6Qo4ADFgwABp1aqVnpG407l48aKtE1ZGWVmZPHnyRDgDUd+3b1\/h5vDVq1cUPfTy5Utp2bKlp1zbDAdkLsqaNGliq+oKOGzxO3Xq5Gk0KipKSkpKPGWnDKfoRo0aSbNmzVQstPLmj9OzFRymLeAsWbJED4508vr16yovIjWmADJ06FC9ZgkJCbGVdwUcWmvcuDFJnQjdBg0a2Op+\/PhRQdmyZYve+aalpcmyZcs0wmyV6sBwBZyIiAgpKiryuEOeqwBPhUOmdevWeg9jriZIKyoqJDw83KMFeNOnTxcTnXFxcXqF6rR+eJRrkXEFnISEBOFOhksqiDwd8McvDpR0+tKlSypOygmc9UsrKv\/xlWEqAXplUW7duiUAiB7l70WugMMrBPciI0eOlKSkJGF+U+eP06wBfF537NghLOrcKlKmnjqIS6zU1FThXpiFmyuJxYsX6wfAnzb8lXEFnKCgICHs8\/Pz5cyZMzJt2jQJCgry1yfp0KGD7N69W86dO6dXmpRR5rMOkQdw7PMExDtbjx49qK4VcaHHxRoXar4UXQHHV0M\/Y10AHIdRC4ATAMcBAQeWY+RwmOOA56DvN4sjwIQJEzw\/QalJkcPg7NmzdZNXk6xbfEdwvmejbNDY2fLOxF7me9r2ZYsjRm1uAnzZCP706ZP+3KRbt27StWtX\/exyZcCvEnhk46GM6GEkFy1aJMjxYMaDPw54Gy0uLhY2aJyn2IPk5ubq6yc\/OeFtHR4voVY9q05y5UslB1fDP378uPTr10\/b5dcWnNrtfMZHoo1TPA+NtJeVlSX4C3EWoz\/IQTX1J5i9BG\/VBQUF+o4cXrlNz87OFh7HePfhWmDYsGGybt069ZfTNe\/I7EPYZ2jlt380yIZs3LhxcufOHcnMzFTgeUvnJye8KLInsUYOO2ic5LHu9u3bwuaOl0hswSstLdUrj\/3798uBAwcEIO18xg10mMJHjhwRQOReCX\/ZbxG52EXOn\/4Ec51AJ9ieY8zXNQAnYI4AbMDYMPGUywjjJA0ZunnzpuDAqFGjhIMju2LOVKdOnTIi1VLuYr5+\/SpjxowRdsEAOG\/ePGnYsKFweubVkpN5+\/bt9SzFMcHJZ3S4KCNlwHnWxl\/8xhYpJ3x\/+vMfAAAA\/\/9w5njrAAAABklEQVQDAFQwMKNG\/9KqAAAAAElFTkSuQmCC","height":43,"width":71}}
%---
%[output:83a3d105]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEcAAAArCAYAAAAqhpU+AAAIpklEQVR4AeyaeWzNWRTHT6sYW9UIapu0WokGVUvRaIggrWAEEYrgL6QjjTSCjIkQEqntL43tL8aWSDSKUFtTSu0dWyxRrdq3pkGodaafE\/fl19f3+\/W18TOVvCandznLPfd7z72\/u7zgfwN\/tggES+DPFoEAOLbQiATACYDjgIADKxA5AXAcEHBgeSLn7du3MmXKFCXyGzdulF69esm1a9cc1GvHmj9\/vgwZMkSeP3+udrFPO7Wz4r807dAe7TppwUcOeaucB5zmzZvLzp07lchbhX7W\/KpVq6Rjx46ydOnSOnUhuEuXLnLs2DEhWkzkHDx4UDD85s0bGTt2rPKt1pE3etQTXSYKjB34kK8RefHihcydO1ewTzuMnLGBDoQ96rBPdFEHjR49ukpEM9q0AQ\/CN3Sov3DhggwePFjMYNMOMoaQxfbevXvlwYMHMmLECI1oI+eJHAwaorEFCxZIixYtZN++fTJ8+HDD0jQ2NlY6d+4sd+\/e1fLp06c17dOnj8yaNUsePXokZ8+eVYIxceJEnUrkoTZt2sj69evVPu0wsitXrpTu3bvL1atXtU3ksAtAGzZsEOTghYaGwlICAGwTHfCQoX06TZkOR0dHqywgHD16VG3fu3dPxo8fL8uXL9eUPP2B\/+zZMwGszZs3122f07RpUw3XkydPaqdJ6Rhe3LhxQ1JSUqRt27ZK8fHxOio4C98XMbJmSm\/fvl2jlahCFoBIBw0apBFAJFCGsAkA1GEDGQb08OHDApFv164dojqQ2DQzYc2aNZKXl6c+qsC3fwQC4BEAPiPnm5xtgiM4BBA4SKRQfv36tU4Vq6IZORNlVp41b0KZaWat99Yz9qwy6DBV6DgAWHkmP2PGDI1UykQX8rRJ2UpEKlN64MCBdYscjDFKpIxQeXm5UGaUGC3qDZnO+eqUkcEhQprwZtSYysaOt56xZ3RJmQLoGSIqqLdSz5495cqVKzpt6Tg8pg9TkLyhrVu3ahYf6hQ5aEdGRuoaQQNMKcoQ+V27dul0Y01gUWQ+x1auU+j5IkANCwvzsJhKJgIAhzx1LPZMYSNI6GObAaKOjhIRpMnJyRrFrCHwiBLW0nfv3ukXmfWJAaBt+IZoz+RtwSESECJUaYy8lczUoo4pRRliFFkgGR0I\/p49e6rNbQMkUwJinQJoOldYWKhTACCwQUeQAQymLjYh1jVsMwDoMV2QZd1AFuBMpFGPDvaQxd7atWuFiAJI1i6+VjExMcJA0e9gQhFjdMwsiuRRIgwNH8PeNGfOHIFPanjoYod6KM+y6BHupmyVox4byEObNm3SKYAd5Kw8PuWmLVIAwiZ6ELKmHsABmIjzlkOWfiNLSpn+El3Gnm3koFQfiKhlpJkW+EMkMLLe0wGeN7GG8bFgq+DN86dc78Exo0p00SFSRpZIoOxEFSGh8ndWjqT9uUJKyyp8kpO+q+DgUEZOifyeWShxKwo89Gt6rvwIsrZpl\/+fwSmW\/KLyKqPm5NCP5jGAdm26GjmJ0WHy26+\/eCgxKkz8pZT4cHGLFiZFCpSZEmOHi9a7Cg4tZKf2ln\/+SlDK\/qO3+Es47hYtTIqoBCdCwWfw8NMXuQ6OU+O+HKpPda6DU586W1tfXAGn8pVMtm3bJv3795fExEThvPLlyxe\/fXv8+LFMmjRJ9SdPniwPHz6spmv2P+yBILMPqiboUMGuOD09Xdgk+hJzBZzLly8LB8mcnBw5dOiQnDhxQtji+3LAu+7z58+yevVqBef8+fMydepUycjIkA8fPlQRvX\/\/vnBUYWcLsf+pIuBQeP\/+vd4nzZw5U54+fWor6Qo4ADFgwABp1aqVnpG407l48aKtE1ZGWVmZPHnyRDgDUd+3b1\/h5vDVq1cUPfTy5Utp2bKlp1zbDAdkLsqaNGliq+oKOGzxO3Xq5Gk0KipKSkpKPGWnDKfoRo0aSbNmzVQstPLmj9OzFRymLeAsWbJED4508vr16yovIjWmADJ06FC9ZgkJCbGVdwUcWmvcuDFJnQjdBg0a2Op+\/PhRQdmyZYve+aalpcmyZcs0wmyV6sBwBZyIiAgpKiryuEOeqwBPhUOmdevWeg9jriZIKyoqJDw83KMFeNOnTxcTnXFxcXqF6rR+eJRrkXEFnISEBOFOhksqiDwd8McvDpR0+tKlSypOygmc9UsrKv\/xlWEqAXplUW7duiUAiB7l70WugMMrBPciI0eOlKSkJGF+U+eP06wBfF537NghLOrcKlKmnjqIS6zU1FThXpiFmyuJxYsX6wfAnzb8lXEFnKCgICHs8\/Pz5cyZMzJt2jQJCgry1yfp0KGD7N69W86dO6dXmpRR5rMOkQdw7PMExDtbjx49qK4VcaHHxRoXar4UXQHHV0M\/Y10AHIdRC4ATAMcBAQeWY+RwmOOA56DvN4sjwIQJEzw\/QalJkcPg7NmzdZNXk6xbfEdwvmejbNDY2fLOxF7me9r2ZYsjRm1uAnzZCP706ZP+3KRbt27StWtX\/exyZcCvEnhk46GM6GEkFy1aJMjxYMaDPw54Gy0uLhY2aJyn2IPk5ubq6yc\/OeFtHR4voVY9q05y5UslB1fDP378uPTr10\/b5dcWnNrtfMZHoo1TPA+NtJeVlSX4C3EWoz\/IQTX1J5i9BG\/VBQUF+o4cXrlNz87OFh7HePfhWmDYsGGybt069ZfTNe\/I7EPYZ2jlt380yIZs3LhxcufOHcnMzFTgeUvnJye8KLInsUYOO2ic5LHu9u3bwuaOl0hswSstLdUrj\/3798uBAwcEIO18xg10mMJHjhwRQOReCX\/ZbxG52EXOn\/4Ec51AJ9ieY8zXNQAnYI4AbMDYMPGUywjjJA0ZunnzpuDAqFGjhIMju2LOVKdOnTIi1VLuYr5+\/SpjxowRdsEAOG\/ePGnYsKFweubVkpN5+\/bt9SzFMcHJZ3S4KCNlwHnWxl\/8xhYpJ3x\/+vMfAAAA\/\/9w5njrAAAABklEQVQDAFQwMKNG\/9KqAAAAAElFTkSuQmCC","height":43,"width":71}}
%---
