function c = converter_ctrl_param(ts, omega_base)
%CONVERTER_CTRL_PARAM  Control data of a grid-connected three-phase converter: PLL, observers, first harmonic
%   tracker, DC-link voltage PI, current limits (local replacement of the library class ctrl_afe_setup, same
%   numbers and field names, returns a struct).
%
%   c = converter_ctrl_param(ts, omega_base)
%     ts          [s] control period
%     omega_base  [rad/s] nominal grid pulsation
%
%   The observer gains come from the closed-form pole placement of the 2x2 discrete systems (the class used
%   acker of the Control System Toolbox: same values, no toolbox needed):
%     di_obs    double integrator observer of the PLL, poles exp([-1 -4]*omega_base*ts)
%     vr_obs    voltage-rate observer of the FRT, poles exp([-0.1 -0.4]*omega_base*ts)
%     fht_grid  first harmonic tracker of the grid voltage (resonator at omega_base, damping delta_fht),
%               poles [-1 -4]*omega_base (L_fht, continuous) and their images exp(p*ts) (Ld_fht, discrete)
%
%   Fields read by ls_upqc.slx (param.saf.ctrl and param.vs.ctrl, FHT-PLL of the two controls): di_obs.Ldso,
%   di_obs.Adso, di_obs.Cso, fht_grid.Ld_fht, fht_grid.Ad_fht, fht_grid.Cfht, fht_grid.omega_fht, pll_i1_fht,
%   pll_p_fht, omega_base; DC-link voltage PI of the SAF: udc_norm_ref, kp_udc_ctrl, ki_udc_ctrl,
%   ixi_pos_ref_lim; windows of the moving averages of the power measurement (instantaneus_power of the SAF
%   and of the VS): rms.n1 (one grid period), rms.n10 (ten grid periods). The other numbers feed the
%   parameters of the afe_uvw_ctrl blocks (uvw_param).
%   Left out from the class: fht_load (copy of fht_grid), the DDSRF PLL gains, the dq PI gains of the
%   stack and grid currents (kp_is_xi ... ki_ig_eta) and the matrices of res_pi: ls_upqc.slx does not use
%   them.

    c = struct();
    c.ts = ts;
    c.omega_base = omega_base;
    c.omega_diobs = omega_base;

    % double integrator observer (PLL)
    c.di_obs = double_integrator_observer(ts, [-1 -4]*c.omega_diobs);
    c.di_obs.komega = c.di_obs.Ldso(2)/ts;
    c.di_obs.ktheta = c.di_obs.Ldso(1)/ts;

    % voltage-rate observer (FRT detection)
    c.vr_obs = double_integrator_observer(ts, [-0.1 -0.4]*c.omega_diobs);
    c.vr_obs.kv = c.vr_obs.Ldso(2)/ts;
    c.vr_obs.kx = c.vr_obs.Ldso(1)/ts;

    % first harmonic tracker of the grid voltage
    c.fht_grid = first_harmonic_tracker(ts, omega_base, 0.05, [-1 -4]*omega_base);

    % resonant PI of the grid current (current_ctrl_uvw)
    c.res_pi.kp_rpi = 0.2;
    c.res_pi.ki_rpi = 45;
    c.res_pi.delta_res = 0.015;

    % PLL gains
    c.pll_i1 = 80;
    c.pll_p = 1;
    c.pll_p_frt = 0.2;
    c.pll_i1_fht = c.pll_i1;
    c.pll_p_fht = c.pll_p;

    % DC-link voltage PI [pu]
    c.udc_norm_ref = 1;
    c.kp_udc_ctrl = 0.85;
    c.ki_udc_ctrl = 35;

    % PIs of the grid current sequences (reactive power control)
    c.kp_rc_grid = 0.25;
    c.ki_rc_grid = 35;
    c.kp_rc_pos_grid = c.kp_rc_grid;
    c.ki_rc_pos_grid = c.ki_rc_grid;
    c.kp_rc_neg_grid = c.kp_rc_grid;
    c.ki_rc_neg_grid = c.ki_rc_grid;

    % zero-sequence current PI
    c.kp_is_z = 0.5;
    c.ki_is_z = 18;

    % limits [pu]
    c.umax_ff = 1.1;
    c.ixi_pos_ref_lim = 1.65;
    c.ieta_pos_ref_lim = 1.0;
    c.ieta_neg_ref_lim = 0.5;
    c.i_grid_pos_eta_lim = 1;
    c.i_grid_neg_xi_lim = 0.5;
    c.i_grid_neg_eta_lim = 0.5;
    c.i_grid_pos_eta_red_lim = 0.1;
    c.i_grid_neg_eta_red_lim = 0.1;
    c.i_grid_neg_xi_red_lim = 0.1;

    % moving-average windows [samples]: one and ten grid periods
    c.rms.n1 = 2*pi*1/omega_base/ts;
    c.rms.n10 = 2*pi*10/omega_base/ts;
end

function o = double_integrator_observer(ts, poles)
% x+ = Adso*x + Ldso*(y - Cso*x) with Adso = [1 ts; 0 1] (forward Euler), Cso = [1 0], poles of
% Adso - Ldso*Cso at z = exp(poles*ts): z^2 - (2 - l1)*z + (1 - l1 + ts*l2)
    o.Aso = [0 1; 0 0];
    o.Adso = eye(2) + o.Aso*ts;
    o.Cso = [1 0];
    z = exp(poles*ts);
    l1 = 2 - (z(1) + z(2));
    l2 = (z(1)*z(2) - 1 + l1)/ts;
    o.Ldso = [l1; l2];
end

function o = first_harmonic_tracker(ts, omega, delta, poles)
% resonator x' = Afht*x, Afht = [0 1; -w^2 -delta*w], y = Cfht*x. Continuous observer gain L_fht: poles of
% Afht - L*Cfht at the poles (s^2 + (l1 + delta*w)*s + l1*delta*w + w^2 + l2). Discrete (forward Euler,
% Ad_fht = I + Afht*ts) gain Ld_fht: poles of Ad_fht - L*Cfht at z = exp(poles*ts)
% (z^2 - (a + b)*z + a*b + w^2*ts^2 + ts*l2, a = 1 - l1, b = 1 - delta*w*ts).
    o.omega_fht = omega;
    o.delta_fht = delta;
    o.Afht = [0 1; -omega^2 -delta*omega];
    o.Cfht = [1 0];
    o.Ad_fht = eye(2) + o.Afht*ts;

    l1 = -(poles(1) + poles(2)) - delta*omega;
    l2 = poles(1)*poles(2) - omega^2 - l1*delta*omega;
    o.L_fht = [l1; l2];

    z = exp(poles*ts);
    b = 1 - delta*omega*ts;
    l1 = 2 - delta*omega*ts - (z(1) + z(2));
    a = 1 - l1;
    l2 = (z(1)*z(2) - a*b)/ts - omega^2*ts;
    o.Ld_fht = [l1; l2];
end
