function emu = grid_emulator_param(g)
%GRID_EMULATOR_PARAM  Data of the three-phase grid emulator (local replacement of the library class
%   grid_three_phase_emulator, same formulas and field names, returns a struct).
%
%   emu = grid_emulator_param(g), with the inputs in the struct g (param.grid of init_model.m):
%     name                         text; a name that starts with the vector group (Dyn11, ...) sets the clock number
%     delta_star                   1: Dyn transformer, 0: Yyn
%     pwr_nom                      [W] rated power of the transformer
%     application_voltage          [V] 690, 480 or 400: selects the normalization bases and udc_nom
%     us1, us2                     [V] rated line-to-line voltages of the transformer
%     fgrid                        [Hz]
%     eta, ucc, i1m, p_iron, n1, n2, core_area, core_length, mur, lm0_pu: transformer data (see transformer_param)
%     up_xi_pu_ref, up_eta_pu_ref  [pu] positive-sequence voltage references of the emulator
%     un_xi_pu_ref, un_eta_pu_ref  [pu] negative-sequence voltage references
%     f_sof                        [Hz] cut-off frequency of the second-order filters of the FRT profiles
%
%   Fields read by ls_upqc.slx (block grid_emulator/three_phase_voltage_source_with_frt_emulator1 and the
%   transformer 3ph_Dyg_ssc/configurable_trafo): fgrid_nom, us_secondary_nom, Vemu_ref_norm, up_xi_pu_ref,
%   up_eta_pu_ref, un_xi_pu_ref, un_eta_pu_ref, sof.A, sof.B, sof.C (filters of the FRT profiles: the
%   library model read them from setup_global_filters, param.ctrl.filters.afe.SOF_50Hz.ss_c), trafo.pu.*,
%   trafo.pwr_nom, trafo.u1_nom, trafo.u2_nom, trafo.f_nom. The grid impedance of the library class
%   (eq_grid_inductance, eq_grid_resistance) and the gains of the closed-loop emulator (kp_vgrid, ki_vgrid,
%   k_ff) are not used by the model: the emulator is an ideal source behind the transformer.

    emu = struct();
    emu.name = g.name;
    emu.delta_star = g.delta_star;
    emu.pwr_nom = g.pwr_nom;
    emu.application_voltage = g.application_voltage;
    emu.us_primary_nom = g.us1;
    emu.is_primary_nom = g.pwr_nom/sqrt(3)/g.us1;
    emu.us_secondary_nom = g.us2;
    emu.is_secondary_nom = g.pwr_nom/sqrt(3)/g.us2;
    emu.n1 = g.n1;
    emu.n2 = g.n2;
    emu.fgrid_nom = g.fgrid;
    emu.omega_grid_nom = 2*pi*g.fgrid;

    if ~isfield(g, 'lm0_pu')
        g.lm0_pu = [];
    end
    emu.trafo = transformer_param(struct('name', g.name, 'delta_star', g.delta_star, 'pwr_nom', g.pwr_nom, ...
        'u1_nom', g.us1, 'u2_nom', g.us2, 'f_nom', g.fgrid, 'eta', g.eta, 'ucc', g.ucc, 'i1m', g.i1m, ...
        'p_iron', g.p_iron, 'n1', g.n1, 'n2', g.n2, 'core_area', g.core_area, 'core_length', g.core_length, ...
        'mur', g.mur, 'lm0_pu', g.lm0_pu));

    % normalization bases of the two sides of the transformer: peak phase voltage, peak line current
    emu.u1bez = emu.us_primary_nom*sqrt(2/3);
    emu.i1bez = emu.is_primary_nom*sqrt(2);
    emu.u2bez = emu.us_secondary_nom*sqrt(2/3);
    emu.i2bez = emu.is_secondary_nom*sqrt(2);

    emu.up_xi_pu_ref = g.up_xi_pu_ref;
    emu.up_eta_pu_ref = g.up_eta_pu_ref;
    emu.un_xi_pu_ref = g.un_xi_pu_ref;
    emu.un_eta_pu_ref = g.un_eta_pu_ref;

    % voltage reference of the emulator and normalization of the grid quantities (secondary side)
    emu.ugrid_factor = 1;
    switch g.application_voltage
        case 690
            emu.igrid_bez = 270*sqrt(2);
            emu.udc_nom = 1070;
        case 480
            emu.igrid_bez = 360*sqrt(2);
            emu.udc_nom = 750;
        otherwise
            emu.igrid_bez = 360*sqrt(2);
            emu.udc_nom = 680;
    end
    emu.ugrid_bez = g.application_voltage*sqrt(2/3);
    emu.Vemu_ref = g.application_voltage/sqrt(3)*emu.ugrid_factor;      % [V] rms phase voltage
    emu.Vemu_ref_norm = emu.Vemu_ref*sqrt(2)/emu.ugrid_bez;              % [pu]

    % second-order low pass 1/(tau*s + 1)^2 of the FRT profiles (sequence references, amplitudes, phase
    % shift), continuous state space. The states of the emulator start from zero, so any realization gives
    % the same output: this one is the controllable canonical form (sof_setup of the library used ss(tf))
    tau = 1/(2*pi*g.f_sof);
    emu.sof.fcut = g.f_sof;
    emu.sof.time_constant = tau;
    emu.sof.A = [0 1; -1/tau^2 -2/tau];
    emu.sof.B = [0; 1/tau^2];
    emu.sof.C = [1 0];
    emu.sof.D = 0;

    fprintf('Grid emulator %s: %.0f kVA, %.0f/%.0f V, %.0f Hz, Vemu_ref_norm = %.4f pu, FRT filters %.0f Hz\n', ...
        emu.name, emu.pwr_nom/1e3, emu.us_primary_nom, emu.us_secondary_nom, emu.fgrid_nom, emu.Vemu_ref_norm, ...
        emu.sof.fcut);
end
