function data = frt_param(f)
%FRT_PARAM  Grid fault (FRT test) data of the grid emulator (local replacement of frt_settings,
%   grid_fault_generator and asymmetric_error of the library, same formulas and field names).
%
%   data = frt_param(f), with the inputs in the struct f (param.frt of init_model.m):
%     test_index, test_subindex   test of the catalogue below (VDE-AR-N 4110 / FGW TR3 style), e.g. 25 and 4
%     asymmetric_error_type       two-phase faults: 0 variant C, 1 variant D (see asymmetric_error)
%     enable_frt_1                1: the fault acts on the phase amplitudes and phase shift (abc)
%     enable_frt_2                1: the fault acts on the sequence references (xi-eta positive and negative)
%     start_time_LVRT             [s] start of the fault
%     deepPOSxi, deepPOSeta       [pu] dips of the positive-sequence references (enable_frt_2)
%     deepNEGxi, deepNEGeta       [pu] steps of the negative-sequence references (enable_frt_2)
%
%   Fields read by ls_upqc.slx: enable_frt_1, enable_frt_2, start_time_LVRT, end_time_LVRT, t_ramp,
%   deepPOSxi, deepPOSeta, deepNEGxi, deepNEGeta, Amplitude_U, Amplitude_V, Amplitude_W, Phase_shift (grid
%   emulator), settle_time (enable of the FRT of the SAF), k_frt_ref (param.saf.uvw.frt). The test also gives
%   error_length (fault duration), P_load_norm, Q_load_norm and k_lvrt, as the library function. The fields
%   of frt_settings that only the drive models use (time_start_motor_control, start_load,
%   time_aux_power_supply_fault, time_phase_fault, start_time_grid_switch_open) are left out.
%   Test 25.3 is not defined (empty case in the library: undefined variables): it stops with an error.

    data = struct();
    data.enable_frt_1 = f.enable_frt_1;
    data.enable_frt_2 = f.enable_frt_2;
    if data.enable_frt_1 && data.enable_frt_2
        error('frt_param:enable', 'enable_frt_1 and enable_frt_2 cannot be both 1');
    end
    data.deepPOSxi = f.deepPOSxi;
    data.deepPOSeta = f.deepPOSeta;
    data.deepNEGxi = f.deepNEGxi;
    data.deepNEGeta = f.deepNEGeta;
    data.test_index = f.test_index;
    data.test_subindex = f.test_subindex;
    data.asymmetric_error_type = f.asymmetric_error_type;   % 0: variant C, 1: variant D
    data.start_time_LVRT = f.start_time_LVRT;
    data.settle_time = 0.175;                               % [s] FRT of the SAF enabled after this time
    data.k_frt_ref = 2;                                     % [pu/pu] reactive current per voltage change

    % test catalogue: index, subindex, kind ('sym' three-phase, 'asym' two-phase), remaining voltage (sym) or
    % dip (asym, a negative dip is a rise), fault duration [s], P_load_norm, Q_load_norm, k_lvrt
    tests = {
          0, 0, 'none', 1,     0,      1,   0.1,   2    % no fault
         25, 1, 'sym',  0.25,  0.760,  1,   0,     2    % 75% dip, three-phase, full load
         25, 2, 'sym',  0.25,  0.760,  0.5, 0,     2    % 75% dip, three-phase, partial load
         25, 4, 'asym', 0.75,  0.915,  1,   0,     2    % 75% dip, two-phase, full load
         25, 5, 'asym', 0.75,  0.250,  0.5, 0,     2    % 75% dip, two-phase, partial load
         50, 1, 'sym',  0.5,   1.982,  1,   0,     2    % 50% dip, three-phase, full load
         50, 2, 'sym',  0.5,   1.982,  0.5, 0,     2    % 50% dip, three-phase, partial load
         50, 3, 'asym', 0.5,   2.305,  1,   0,     2    % 50% dip, two-phase, full load
         50, 4, 'asym', 0.5,   2.305,  0.5, 0,     2    % 50% dip, two-phase, partial load
         50, 5, 'sym',  0.5,   1.982,  1,   0,     2    % 50% dip, three-phase, full load, reduced dyn. support
         50, 6, 'asym', 0.5,   2.305,  1,   0,     2    % 50% dip, two-phase, full load, reduced dyn. support
         75, 1, 'sym',  0.75,  2.796,  1,   0,     2    % 25% dip, three-phase, full load
         75, 2, 'sym',  0.75,  2.796,  0.5, 0,     2    % 25% dip, three-phase, partial load
         75, 3, 'sym',  0.75,  2.796,  0.5, 0.33,  2    % 25% dip, three-phase, partial load, max. under-excited
         75, 4, 'sym',  0.75,  2.796,  0.5, -0.33, 2    % 25% dip, three-phase, partial load, max. over-excited
         75, 5, 'sym',  0.75,  2.796,  0.5, 0,     4    % 25% dip, three-phase, partial load, k = 4
         75, 6, 'asym', 0.25,  3.000,  1,   0,     2    % 25% dip, two-phase, full load
         75, 7, 'asym', 0.25,  3.000,  0.5, 0,     2    % 25% dip, two-phase, partial load
         75, 8, 'asym', 0.25,  3.000,  0.5, 0,     4    % 25% dip, two-phase, partial load, k = 4
         80, 1, 'sym',  0.8,   3.000,  1,   0.1,   2    % 20% dip, three-phase, full load, reduced dyn. support
         80, 2, 'asym', 0.20,  3.000,  1,   0,     2    % 20% dip, two-phase, full load, reduced dyn. support
         85, 1, 'sym',  0.88,  60.000, 1,   0,     2    % 12% dip, three-phase, full load
        110, 1, 'asym', -0.15, 5.000,  1,   0,     2    % rise, two-phase, full load
        110, 2, 'asym', -0.15, 5.000,  0.5, 0,     2    % rise, two-phase, partial load
        110, 3, 'sym',  1.16,  60.000, 0.5, 0,     2    % rise, three-phase, partial load
        115, 1, 'sym',  1.16,  5.000,  1,   0,     2    % 15% rise, three-phase, full load
        115, 2, 'sym',  1.16,  5.000,  0.5, 0,     2    % 15% rise, three-phase, partial load
    };
    if f.test_index == 0
        row = 1;                                            % no fault, whatever the subindex
    else
        row = find(cell2mat(tests(:, 1)) == f.test_index & cell2mat(tests(:, 2)) == f.test_subindex, 1);
    end
    if isempty(row)
        error('frt_param:test', 'test %d.%d is not defined', f.test_index, f.test_subindex);
    end
    [kind, v, error_length, P_load_norm, Q_load_norm, k_lvrt] = tests{row, 3:8};

    switch kind
        case {'none', 'sym'}
            Amplitude_U = v;
            Amplitude_V = v;
            Amplitude_W = v;
            Phase_shift = 0;
        case 'asym'
            [Voltage_LVRT, delta_phi] = asymmetric_error(v, f.asymmetric_error_type);
            if f.asymmetric_error_type == 0
                Amplitude_U = 1;
            else
                Amplitude_U = 1 - v;
            end
            Amplitude_V = Voltage_LVRT;
            Amplitude_W = Voltage_LVRT;
            Phase_shift = delta_phi;
    end

    data.end_time_LVRT = f.start_time_LVRT + error_length;
    data.error_length = error_length;
    data.Amplitude_U = Amplitude_U;
    data.Amplitude_V = Amplitude_V;
    data.Amplitude_W = Amplitude_W;
    data.Phase_shift = Phase_shift;
    data.P_load_norm = P_load_norm;
    data.Q_load_norm = Q_load_norm;
    data.t_ramp = 20e-3;                                    % [s] ramp of the phase voltages
    data.k_lvrt = k_lvrt;

    fprintf('FRT: test %d.%d (%s), fault %.3f s to %.3f s, enable_frt_1 = %d, enable_frt_2 = %d\n', ...
        data.test_index, data.test_subindex, kind, data.start_time_LVRT, data.end_time_LVRT, ...
        data.enable_frt_1, data.enable_frt_2);
end

function [rho, delta_phi] = asymmetric_error(voltage_dip, error_type)
% Two-phase fault: remaining line voltage U_23 = sqrt(3)*(1 - dip). Variant C (error_type 0): the phases V and
% W move towards each other; variant D (error_type 1): their common component shrinks. rho is the amplitude of
% the phases V and W, delta_phi their phase shift.
    if error_type == 0
        im = sqrt(3)/2*(1 - voltage_dip);
        re = -1/2;
    else
        im = sqrt(3)/2;
        re = -1/2*(1 - voltage_dip);
    end
    [theta, rho] = cart2pol(re, im);
    delta_phi = theta - 2/3*pi;
end
