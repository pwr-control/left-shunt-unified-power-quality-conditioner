function ls_upqc_migrate(repo_dir, main_slx)
%LS_UPQC_MIGRATE  One-off migration of ls_upqc.slx (branch dev) to the param struct of the new init_model.m.
%
%   ls_upqc_migrate(repo_dir, main_slx)
%     repo_dir  clone of left-shunt-unified-power-quality-conditioner: ls_upqc/ls_upqc.slx is changed and saved
%     main_slx  copy of ls_upqc.slx of the branch main: source of the blocks that dev had removed
%
%   Steps: structural fixes (blocks restored from main, logging buses rebuilt, dead blocks removed), tag
%   renames, parameters re-pointed to param.*, block renames (saf / vs labels), model configuration.
%
%   Already applied: ls_upqc/ls_upqc.slx of this branch is its result (November 2026, MATLAB R2026b). The script
%   stays as the readable record of the changes to the binary model. It runs on the model of the branch dev
%   before the migration (git show <commit of dev>:ls_upqc/ls_upqc.slx), not on the migrated one: its asserts
%   check the old names.

    fprintf('=== ls_upqc_migrate %s\n', datestr(now)); %#ok<TNOW1,DATST>
    here = fullfile(repo_dir, 'ls_upqc');
    cd(here);
    addpath(here);
    prv = ls_upqc_private();
    prv.library_setup();
    try
        pm_addunit('percent', 0.01, '1');
    catch
    end
    M = 'ls_upqc';
    bdclose('all');
    load_system(fullfile(here, 'ls_upqc.slx'));
    tmp = tempname;
    mkdir(tmp);
    copyfile(main_slx, fullfile(tmp, 'ls_upqc_main.slx'));
    MM = 'ls_upqc_main';
    load_system(fullfile(tmp, 'ls_upqc_main.slx'));

    U = [M '/left_shunt_universal_power_quality_compensator'];
    SAF = [U '/shunt_active_filter'];
    SAF_ISR = [SAF '/saf_control/saf_control'];
    SAF_CTRL = [SAF_ISR '/saf_control'];
    VS = [U '/voltage_stabiliser'];
    VS_ISR = [VS '/VS_control/vs_control'];
    VS_CTRL = [VS_ISR '/vs_control'];
    EMU = [M '/grid_emulator'];
    GT = [M '/global timing'];
    MEAS = [M '/ls_upqc_measurement_sim'];
    MU = [MM '/left_shunt_universal_power_quality_compensator'];
    MSAF_CTRL = [MU '/shunt_active_filter/saf_control/saf_control/saf_control'];
    MVS_CTRL = [MU '/voltage_stabiliser/VS_control/vs_control/vs_control'];
    MGRID = [MM '/grid'];

    %% 1. structural fixes
    fprintf('--- 1. structural fixes\n');
    % VS: the sequences of the load voltage (dev read ugd_abc_pu, a tag of the SAF that the VS cannot see)
    set_param([VS_CTRL '/grid_voltage_sequences/From'], 'GotoTag', 'ugd_abc_load_pu');
    % dead pair From8 (ugd_abc_pu) -> Goto5 (v_grid_ff_abc) at the ISR level of SAF and VS
    for sys = {SAF_ISR, VS_ISR}
        assert(strcmp(get_param([sys{1} '/Goto5'], 'GotoTag'), 'v_grid_ff_abc'));
        assert(strcmp(get_param([sys{1} '/From8'], 'GotoTag'), 'ugd_abc_pu'));
        delete_block_and_lines([sys{1} '/From8']);
        delete_block_and_lines([sys{1} '/Goto5']);
    end
    % instantaneous power of SAF and VS (about 80 nonvirtual blocks each): removed in dev to stay within the 1000
    % nonvirtual blocks of the Home licence; its readers (scope 'power-meter mod1', logging bus pwr_meter) go too
    for sys = {SAF_ISR, VS_ISR}
        assert(strcmp(get_param([sys{1} '/From4'], 'GotoTag'), 'pwr_act_grid'));
        assert(strcmp(get_param([sys{1} '/From5'], 'GotoTag'), 'pwr_react_grid'));
        for b = {'From4', 'From5', ['power-meter' newline 'mod1']}
            delete_block_and_lines([sys{1} '/' b{1}]);
        end
    end
    for C = {SAF_CTRL, VS_CTRL}
        D = [C{1} '/data_to_worspace_module_1'];
        delete_block_and_lines([D '/pwr_meter']);
        bus_creator_remove_input([D '/Bus Creator'], 2);
    end
    % DC-link voltage PI of the SAF (commented out in main, removed in dev): copied from main, active, used
    % by the switch of i_xi_ref when there is no storage
    copy_from_main([MSAF_CTRL '/udc_ctrl'], [SAF_CTRL '/udc_ctrl']);
    set_param([SAF_CTRL '/udc_ctrl'], 'Commented', 'off');
    p = get_param([SAF_CTRL '/udc_ctrl'], 'Position');
    add_block('simulink/Signal Routing/From', [SAF_CTRL '/udc_meas'], 'GotoTag', 'udcd_pu_afe', ...
        'Position', [p(1)-160 p(2)+2 p(1)-60 p(2)+18]);
    add_block('simulink/Sources/Constant', [SAF_CTRL '/udc_ref'], 'Value', 'param.saf.ctrl.udc_norm_ref', ...
        'Position', [p(1)-160 p(4)-18 p(1)-60 p(4)-2]);
    add_line(SAF_CTRL, 'udc_meas/1', 'udc_ctrl/1', 'autorouting', 'on');
    add_line(SAF_CTRL, 'udc_ref/1', 'udc_ctrl/2', 'autorouting', 'on');
    % i_xi_ref = storage ? (pwr_lim_enable ? 0 : ixi_ref) : output of udc_ctrl. With the storage the SAF draws
    % ixi_ref and none during the FRT power limitation (the DAB holds the DC link); without the storage the DC-link
    % loop gives the active current also during a fault, because the VS takes from the DC link the power that
    % keeps the load voltage
    X = [SAF_CTRL '/i_xi_ref'];
    pc = get_param([X '/Switch'], 'Position');
    po = get_param([X '/i_xi_ref'], 'Position');
    set_param([X '/i_xi_ref'], 'Position', po + [160 0 160 0]);
    add_block('simulink/Sources/In1', [X '/i_xi_ref_udc_ctrl'], 'Position', [pc(1) pc(4)+60 pc(1)+30 pc(4)+74]);
    add_block('simulink/Sources/Constant', [X '/storage'], 'Value', 'param.sim.storage', ...
        'Position', [pc(1) pc(4)+100 pc(3)+40 pc(4)+120]);
    add_block('simulink/Signal Routing/Switch', [X '/storage_switch'], 'Criteria', 'u2 > Threshold', ...
        'Threshold', '0.5', 'Position', [pc(3)+80 pc(2) pc(3)+110 pc(4)+120]);
    delete_line(X, 'Switch/1', 'i_xi_ref/1');
    add_line(X, 'Switch/1', 'storage_switch/1', 'autorouting', 'on');
    add_line(X, 'storage/1', 'storage_switch/2', 'autorouting', 'on');
    add_line(X, 'i_xi_ref_udc_ctrl/1', 'storage_switch/3', 'autorouting', 'on');
    add_line(X, 'storage_switch/1', 'i_xi_ref/1', 'autorouting', 'on');
    add_line(SAF_CTRL, 'udc_ctrl/1', 'i_xi_ref/1', 'autorouting', 'on');
    % udc_ctrl of main zeroed its output and reset its state on pwr_lim_enable: not without the storage
    UC = [SAF_CTRL '/udc_ctrl'];
    assert(strcmp(get_param([UC '/From'], 'GotoTag'), 'pwr_lim_enable'));
    pf = get_param([UC '/From'], 'Position');
    delete_block_and_lines([UC '/From']);
    add_block('simulink/Sources/Constant', [UC '/no_pwr_lim'], 'Value', '0', 'Position', pf);
    add_line(UC, 'no_pwr_lim/1', 'Switch/2', 'autorouting', 'on');
    % IEC power meter of the grid (about 300 nonvirtual blocks, removed in dev for the same reason): its readers
    % go; P1p, Q1p, P1n, Q1n are computed after the simulation from ug_abc_sim and ig_abc_sim (iec_power_meter.m)
    for b = {'From86', 'From87', 'From88', 'From89'}
        assert(any(strcmp(get_param([MEAS '/' b{1}], 'GotoTag'), {'P1n_global', 'P1p_global', 'Q1p_global', 'Q1n_global'})));
        assert(any(strcmp(get_param([M '/scope/' b{1}], 'GotoTag'), {'P1n_global', 'P1p_global', 'Q1p_global', 'Q1n_global'})));
    end
    for b = {'From86', 'From87', 'From88', 'From89', 'To Workspace7', 'To Workspace8', 'To Workspace9', 'To Workspace10'}
        delete_block_and_lines([MEAS '/' b{1}]);
    end
    for b = {'From86', 'From87', 'From88', 'From89', 'line_power_meter'}
        delete_block_and_lines([M '/scope/' b{1}]);
    end
    % logging buses of SAF and VS: rebuilt with the signals that exist
    for C = {SAF_CTRL, VS_CTRL}
        cc = [C{1} '/current_ctrl'];
        pu = get_param([cc '/current_ctrl_uvw'], 'Position');
        tags = {'u_abg', 'i_abc_ref', 'is_xe'};
        for j = 1:3
            g = [cc '/goto_' tags{j}];
            add_block('simulink/Signal Routing/Goto', g, 'GotoTag', tags{j}, 'TagVisibility', 'scoped', ...
                'Position', [pu(3)+150 pu(4)+30*j pu(3)+250 pu(4)+30*j+16]);
            add_line(cc, sprintf('current_ctrl_uvw/%d', j), ['goto_' tags{j} '/1'], 'autorouting', 'on');
            bbc = system_bbox(C{1});
            add_block('simulink/Signal Routing/Goto Tag Visibility', [C{1} '/visibility_' tags{j}], ...
                'GotoTag', tags{j}, 'Position', [bbc(1) bbc(4)+40*j bbc(1)+120 bbc(4)+40*j+24]);
        end
        D = [C{1} '/data_to_worspace_module_1'];
        rebuild_bus([D '/dq_pll'], ...
            struct('tag', {'phase_grid_pll', 'omega_grid_pll_pu', 'grid_emulator_phase'}, ...
                   'names', {{'phase_grid_pll'}, {'omega_grid_pll_pu'}, {'phase_grid_emulator'}}));
        rebuild_bus([D '/inner_current_tracking'], ...
            struct('tag', {'i_abc_ref', 'isd_abc_pu', 'is_xe', 'u_abg'}, ...
                   'names', {{'isa_ref', 'isb_ref', 'isc_ref'}, {'isa', 'isb', 'isc'}, {'is_xe'}, ...
                             {'u_alpha', 'u_beta', 'u_gamma'}}));
    end
    rebuild_bus([SAF_CTRL '/data_to_worspace_module_1/sequences_data'], ...
        struct('tag', {'i_grid_seq_ref', 'v_grid_pos_xi_avg', 'v_grid_pos_eta_avg', 'v_grid_neg_xi_avg', ...
                       'v_grid_neg_eta_avg', 'i_grid_pos_xi_avg', 'i_grid_pos_eta_avg', 'i_grid_neg_xi_avg', ...
                       'i_grid_neg_eta_avg'}, ...
               'names', {{'i_grid_pos_eta_ref', 'i_grid_neg_xi_ref', 'i_grid_neg_eta_ref'}, {'v_grid_pos_xi_avg'}, ...
                         {'v_grid_pos_eta_avg'}, {'v_grid_neg_xi_avg'}, {'v_grid_neg_eta_avg'}, ...
                         {'i_grid_pos_xi_avg'}, {'i_grid_pos_eta_avg'}, {'i_grid_neg_xi_avg'}, {'i_grid_neg_eta_avg'}}));
    rebuild_bus([VS_CTRL '/data_to_worspace_module_1/sequences_data'], ...
        struct('tag', {'v_grid_pos_xi_avg', 'v_grid_pos_eta_avg', 'v_grid_neg_xi_avg', 'v_grid_neg_eta_avg'}, ...
               'names', {{'v_load_pos_xi_avg'}, {'v_load_pos_eta_avg'}, {'v_load_neg_xi_avg'}, {'v_load_neg_eta_avg'}}));
    % space vector modulators: current_ctrl_uvw (library) gives u_abg as a vector, not as the bus of main
    for C = {SAF_CTRL, VS_CTRL}
        sv = [C{1} '/space_vector'];
        p = get_param([sv '/Bus Selector1'], 'Position');
        delete_block_and_lines([sv '/Bus Selector1']);
        add_block('simulink/Signal Routing/Demux', [sv '/demux_u_abg'], 'Outputs', '3', 'Position', p);
        add_line(sv, 'uab_out/1', 'demux_u_abg/1', 'autorouting', 'on');
        for j = 1:3
            add_line(sv, sprintf('demux_u_abg/%d', j), sprintf('Gain%d/1', j), 'autorouting', 'on');
        end
        set_param([sv '/uab_out'], 'Name', 'u_abg');
    end
    % global timing: the DAB has no time alignment (dangling From local_time_corr_dab_mod1): zero correction
    pf = get_param([GT '/From1'], 'Position');
    delete_block_and_lines([GT '/From1']);
    add_block('simulink/Sources/Constant', [GT '/local_time_corr_dab'], 'Value', '0', 'Position', pf);
    add_line(GT, 'local_time_corr_dab/1', 'Unit Delay1/1', 'autorouting', 'on');
    delete_block_and_lines([GT '/From2']);
    set_param([GT '/pwm_alignments'], 'NumInputPorts', '2');
    set_param([GT '/time_afe3'], 'k', 'param.dab.behav.time_gain');
    % logging of the DAB devices: their Gotos were in the thermal models, which dev no longer has
    for b = {'From15', 'To Workspace21', 'From22', 'To Workspace28'}
        delete_block_and_lines([MEAS '/DAB_quantities/' b{1}]);
    end
    % ideal bridges of dev (library ideal_bridges): their integrated passives are on by default and put 0.5 mH per
    % AC terminal (full bridge) or 1 mH per phase (three-phase bridge) in series and 2 mF on the DC side of each
    % bridge, on top of the LC/LCL filters, the DC links and the DAB tank of the model (main had bare switch models)
    br = find_system(M, 'LookUnderMasks', 'all', 'FollowLinks', 'off', 'IncludeCommented', 'on', ...
        'RegExp', 'on', 'ReferenceBlock', '^ideal_bridges_lib/');
    assert(numel(br) == 4, 'ideal bridges: %d blocks', numel(br));
    for k = 1:numel(br)
        set_param(br{k}, 'cap_dc', 'ideal_bridges.onoff.off', 'ind_ac', 'ideal_bridges.onoff.off');
        fprintf('  %s: cap_dc off, ind_ac off\n', strrep(br{k}, newline, ' '));
    end
    % start from the initial conditions, not from a Simscape steady state: the steady state brings the battery to
    % SOC 0 (764 V) through the off-state leakage of the bridges
    sc = find_system(M, 'LookUnderMasks', 'all', 'FollowLinks', 'off', 'IncludeCommented', 'on', ...
        'ReferenceBlock', sprintf('nesl_utility/Solver\nConfiguration'));
    assert(numel(sc) == 1);
    set_param(sc{1}, 'DoDC', 'off');
    set_param([U '/battery_1/litium_ion_battery'], 'battery_voltage_init_m', 'param.battery.voltage_init_1');
    set_param([U '/dab_mod1/dcdc_with_galvanic_isolation/CFi_dc1'], 'vc', 'param.battery.voltage_init_1', ...
        'vc_specify', 'on', 'vc_priority', 'High');
    fprintf('  Solver Configuration: DoDC off; battery and CFi_dc1 start at param.battery.voltage_init_1\n');

    %% 2. tags
    fprintf('--- 2. tags\n');
    tag_map = {'u_abc_line', 'ug_abc'; 'i_abc_line', 'ig_abc'; 'gamma_grid_emulator', 'phase_grid_emulator'; ...
        'all_voltages_about_dclink_mod1', 'all_voltages_about_dclink_saf'; 'udcd_pu_afe', 'udcd_pu'; ...
        'iz_afe_pu_saf', 'iz_pu_saf'; 'time_dab_module_1', 'time_dab'; 'TRGO_DAB_1', 'TRGO_dab'; ...
        'current_battery_1', 'current_battery'; 'voltage_battery_1', 'voltage_battery'; ...
        'single_phase_transformer_data_mod1', 'dab_transformer_data'; ...
        'CFi_dc1_current_mod1', 'CFi_dc1_current_dab'; 'CFi_dc2_current_mod1', 'CFi_dc2_current_dab'; ...
        'd1m_dab_mod1', 'd1m_dab'; 'd2m_dab_mod1', 'd2m_dab'; 'phase_disp_dab_mod1', 'phase_disp_dab'; ...
        'dab_current_input_mod1', 'dab_current_input'; 'dab_current_output_mod1', 'dab_current_output'; ...
        'dab_voltage_input_mod1', 'dab_voltage_input'; 'dab_voltage_output_mod1', 'dab_voltage_output'; ...
        'i1_dab_transformer_mod1', 'i1_dab_transformer'; 'i2_dab_transformer_mod1', 'i2_dab_transformer'; ...
        'u1_dab_transformer_mod1', 'u1_dab_transformer'; 'u2_dab_transformer_mod1', 'u2_dab_transformer'};
    rename_tags(M, tag_map);
    rename_tags(VS, {'v_grid_pos_xi_avg', 'v_load_pos_xi_avg'; 'v_grid_pos_eta_avg', 'v_load_pos_eta_avg'; ...
        'v_grid_neg_xi_avg', 'v_load_neg_xi_avg'; 'v_grid_neg_eta_avg', 'v_load_neg_eta_avg'});
    remove_orphan_visibility(M);

    %% 3. parameters
    fprintf('--- 3. parameters\n');
    remap_parameters(M);
    for j = 1:3
        set_param([M '/three_phase_rl_load'], sprintf('Ls%d_load_m', j), 'param.load.L', ...
            sprintf('Rs%d_load_m', j), 'param.load.R');
    end
    set_param([U '/dab_mod1/dab_ctrl/references/Vout_dc_nom'], 'FinalValue', 'param.dclink.udc_ref');
    % DAB: the DC-link voltage PI gives the phase shift directly (the current PI i_out_ctrl is commented out, also in
    % main). Its output, in units of max_phase_displacement = pi/2 of the modulator, was limited to +-2: the phase
    % shift reached +-pi, beyond the top of the power curve at pi/2, where the loop gain changes sign, and during a
    % fault the PI wound up to almost zero power. Limit: param.dab.ctrl.phase_lim (1, that is pi/2)
    set_param([U '/dab_mod1/dab_ctrl/ui_ctrl/dab_ctrl/u_out_ctrl/pi_ctrl'], 'lim_up', 'param.dab.ctrl.phase_lim', ...
        'lim_down', '-param.dab.ctrl.phase_lim');
    tw_map = {'u1_dab_transformer_mod1_sim', 'u1_dab_transformer_sim'; ...
        'u2_dab_transformer_mod1_sim', 'u2_dab_transformer_sim'; ...
        'i1_dab_transformer_mod1_sim', 'i1_dab_transformer_sim'; ...
        'i2_dab_transformer_mod1_sim', 'i2_dab_transformer_sim'; ...
        'dab_voltage_input_mod1_sim', 'dab_voltage_input_sim'; 'dab_voltage_output_mod1_sim', 'dab_voltage_output_sim'; ...
        'dab_current_input_mod1_sim', 'dab_current_input_sim'; 'dab_current_output_mod1_sim', 'dab_current_output_sim'; ...
        'CFi_dc1_current_mod1_sim', 'CFi_dc1_current_dab_sim'; 'CFi_dc2_current_mod1_sim', 'CFi_dc2_current_dab_sim'; ...
        'udc_pu_sim_mod1', 'udc_pu_saf_sim'; 'udc_pu_ref_sim_mod1', 'udc_pu_ref_saf_sim'};
    tws = find_system(M, 'LookUnderMasks', 'all', 'FollowLinks', 'off', 'IncludeCommented', 'on', ...
        'BlockType', 'ToWorkspace');
    for k = 1:numel(tws)
        i = find(strcmp(tw_map(:, 1), get_param(tws{k}, 'VariableName')));
        if ~isempty(i)
            set_param(tws{k}, 'VariableName', tw_map{i, 2});
        end
    end
    set_param(M, 'StopTime', 'param.sim.simlength', 'MaxStep', 'param.glb_time.tc', 'FixedStep', 'param.glb_time.tc');
    set_param(M, 'SimCustomHeaderCode', sprintf('#include "sv_pwm_cm.h"\n#include "sv_pwm_cm_simulink.h"'), ...
        'SimUserSources', sprintf('"sv_pwm_cm.c"\n"sv_pwm_cm_simulink.c"'));

    %% 4. labels
    fprintf('--- 4. labels\n');
    q = 'quantizzation and one step delay';
    ren = {
        [SAF_CTRL '/data_to_worspace_module_1'], 'data_to_workspace'
        [SAF_CTRL '/interesting scopes'], 'scopes'
        [SAF_ISR '/phase_compensation_1/alignment_eval_afe1'], 'alignment_eval'
        [SAF_ISR '/phase_compensation_1'], 'time_alignment'
        [SAF_ISR '/ig afe ' q '/ig afe ' q], 'quantization_and_delay'
        [SAF_ISR '/is afe ' q '/is afe ' q], 'quantization_and_delay'
        [SAF_ISR '/ug afe ' q '/ug afe ' q], 'quantization_and_delay'
        [SAF_ISR '/ig afe ' q], 'ig_acquisition'
        [SAF_ISR '/is afe ' q], 'is_acquisition'
        [SAF_ISR '/ug afe ' q], 'ug_acquisition'
        [SAF_ISR '/AFE1_local_time_corr'], 'local_time_corr'
        SAF_CTRL, 'saf_ctrl'
        SAF_ISR, 'saf_isr'
        [VS_CTRL '/data_to_worspace_module_1'], 'data_to_workspace'
        [VS_CTRL '/interesting scopes'], 'scopes'
        [VS_CTRL '/grid_voltage_sequences'], 'load_voltage_sequences'
        [VS_CTRL '/voltage_stabiliser'], 'load_voltage_ctrl'
        [VS_ISR '/phase_compensation_1/alignment_eval_afe1'], 'alignment_eval'
        [VS_ISR '/phase_compensation_1'], 'time_alignment'
        [VS_ISR '/is afe ' q '/is afe ' q], 'quantization_and_delay'
        [VS_ISR '/ug afe ' q '/ug afe ' q], 'quantization_and_delay'
        [VS_ISR '/ug afe ' q '1/ug afe ' q], 'quantization_and_delay'
        [VS_ISR '/is afe ' q], 'is_acquisition'
        [VS_ISR '/ug afe ' q], 'ug_load_acquisition'
        [VS_ISR '/ug afe ' q '1'], 'ug_line_acquisition'
        [VS_ISR '/AFE1_local_time_corr'], 'local_time_corr'
        VS_CTRL, 'vs_ctrl'
        VS_ISR, 'vs_isr'
        [VS '/VS_control'], 'vs_control'
        [VS '/inverter'], 'vs_inverter'
        [VS '/LCL_filter'], 'vs_lcl_filter'
        [U '/battery_1/litium_ion_battery'], 'lithium_ion_battery'
        SAF, 'saf'
        VS, 'vs'
        [U '/dab_mod1'], 'dab'
        [U '/battery_1'], 'battery'
        [U '/series_three_phase_transformer'], 'series_transformer'
        [U '/load_ui_measures'], 'load_measures'
        U, 'upqc'
        [MEAS '/shunt_active_filter_quantities'], 'saf_quantities'
        [MEAS '/voltage_stabiliser_quantities'], 'vs_quantities'
        [MEAS '/DAB_quantities'], 'dab_quantities'
        MEAS, 'measurements'
        [GT '/time_afe1'], 'time_saf'
        [GT '/time_afe2'], 'time_vs'
        [GT '/time_afe3'], 'time_dab'
        GT, 'global_timing'
        [EMU '/three_phase_voltage_source_with_frt_emulator1'], 'voltage_source_with_frt'
        [EMU '/3ph_Dyg_ssc'], 'grid_transformer'
        [M '/three_phase_rl_load'], 'rl_load'
        [M '/scope'], 'scopes'
        };
    for k = 1:size(ren, 1)
        if getSimulinkBlockHandle(ren{k, 1}) == -1
            fprintf('  rename: not found %s\n', strrep(ren{k, 1}, newline, ' '));
            continue
        end
        set_param(ren{k, 1}, 'Name', ren{k, 2});
    end

    %% 5. report and save
    fprintf('--- 5. residual legacy names\n');
    report_legacy(M);
    save_system(M);
    close_system(MM, 0);
    fprintf('=== saved %s\n', get_param(M, 'FileName'));
end

%% ------------------------------------------------------------------------------------------------------------
function copy_from_main(src, dst)
    p = get_param(src, 'Position');
    add_block(src, dst, 'Position', p);
    fprintf('  copied %s\n', strrep(dst, newline, ' '));
end

function copy_group(src_sys, dst_sys, names, origin)
% copy the blocks names(:,1) of src_sys into dst_sys as names(:,2), shifted to origin, with the lines among them
    pos = zeros(size(names, 1), 4);
    for k = 1:size(names, 1)
        pos(k, :) = get_param([src_sys '/' names{k, 1}], 'Position');
    end
    off = origin - min(pos(:, 1:2), [], 1);
    for k = 1:size(names, 1)
        add_block([src_sys '/' names{k, 1}], [dst_sys '/' names{k, 2}], 'Position', pos(k, :) + [off off]);
    end
    for k = 1:size(names, 1)
        pc = get_param([src_sys '/' names{k, 1}], 'PortConnectivity');
        for j = 1:numel(pc)
            if isempty(pc(j).SrcBlock) || pc(j).SrcBlock == -1
                continue
            end
            src_name = get_param(pc(j).SrcBlock, 'Name');
            i = find(strcmp(names(:, 1), src_name));
            if isempty(i) || ~strcmp(get_param(pc(j).SrcBlock, 'Parent'), src_sys)
                continue
            end
            add_line(dst_sys, sprintf('%s/%d', names{i, 2}, pc(j).SrcPort + 1), ...
                sprintf('%s/%s', names{k, 2}, pc(j).Type), 'autorouting', 'on');
        end
    end
    fprintf('  copied %d blocks into %s\n', size(names, 1), dst_sys);
end

function bb = system_bbox(sys)
% bounding box [left top right bottom] of the blocks of a system
    b = find_system(sys, 'SearchDepth', 1, 'Type', 'block');
    b = b(~strcmp(b, sys));
    bb = [inf inf -inf -inf];
    for k = 1:numel(b)
        p = get_param(b{k}, 'Position');
        bb = [min(bb(1), p(1)) min(bb(2), p(2)) max(bb(3), p(3)) max(bb(4), p(4))];
    end
end

function delete_block_and_lines(b)
    lh = get_param(b, 'LineHandles');
    h = [lh.Inport(:); lh.Outport(:)];
    h = h(h > 0);
    for k = 1:numel(h)
        try
            delete_line(h(k));
        catch
        end
    end
    delete_block(b);
end

function rebuild_bus(sys, entries)
% remove every block of sys but the outport, then: one From per entry (a Demux when the entry has more than one
% element name), a Bus Creator with the element names as signal names, connected to the outport
    blocks = find_system(sys, 'SearchDepth', 1, 'Type', 'block');
    blocks = blocks(~strcmp(blocks, sys));
    outp = '';
    for k = 1:numel(blocks)
        if strcmp(get_param(blocks{k}, 'BlockType'), 'Outport')
            outp = get_param(blocks{k}, 'Name');
        else
            delete_block_and_lines(blocks{k});
        end
    end
    lines = find_system(sys, 'SearchDepth', 1, 'FindAll', 'on', 'Type', 'line');
    if ~isempty(lines)
        delete_line(lines);
    end
    n = sum(cellfun(@numel, {entries.names}));
    add_block('simulink/Signal Routing/Bus Creator', [sys '/bus_creator'], 'Inputs', num2str(n), ...
        'Position', [400 20 410 20+30*n]);
    set_param([sys '/' outp], 'Position', [480 20+15*n-7 510 20+15*n+7]);
    k = 0;
    y = 20;
    for e = 1:numel(entries)
        f = ['from_' entries(e).tag];
        add_block('simulink/Signal Routing/From', [sys '/' f], 'GotoTag', entries(e).tag, ...
            'Position', [40 y 180 y+20]);
        nn = numel(entries(e).names);
        if nn == 1
            k = k + 1;
            h = add_line(sys, [f '/1'], sprintf('bus_creator/%d', k));
            set_param(h, 'Name', entries(e).names{1});
        else
            d = ['demux_' entries(e).tag];
            add_block('simulink/Signal Routing/Demux', [sys '/' d], 'Outputs', num2str(nn), ...
                'Position', [250 y 255 y+30*nn-10]);
            add_line(sys, [f '/1'], [d '/1']);
            for j = 1:nn
                k = k + 1;
                h = add_line(sys, sprintf('%s/%d', d, j), sprintf('bus_creator/%d', k));
                set_param(h, 'Name', entries(e).names{j});
            end
        end
        y = y + 30*nn;
    end
    add_line(sys, 'bus_creator/1', [outp '/1']);
    fprintf('  bus %s: %d elements\n', strrep(sys, newline, ' '), n);
end

function bus_creator_remove_input(bc, k)
% remove input k of a Bus Creator: the other inputs keep their sources and signal names, in the same order
    sys = get_param(bc, 'Parent');
    pc = get_param(bc, 'PortConnectivity');
    lh = get_param(bc, 'LineHandles');
    n = numel(lh.Inport);
    src = cell(1, n);
    nm = cell(1, n);
    for j = 1:n
        if lh.Inport(j) > 0
            src{j} = sprintf('%s/%d', strrep(get_param(pc(j).SrcBlock, 'Name'), '/', '//'), pc(j).SrcPort + 1);
            nm{j} = get_param(lh.Inport(j), 'Name');
            delete_line(lh.Inport(j));
        end
    end
    keep = setdiff(1:n, k);
    set_param(bc, 'Inputs', num2str(numel(keep)));
    bname = strrep(get_param(bc, 'Name'), '/', '//');
    for j = 1:numel(keep)
        s = src{keep(j)};
        if isempty(s)
            continue
        end
        h = add_line(sys, s, sprintf('%s/%d', bname, j), 'autorouting', 'on');
        if ~isempty(nm{keep(j)})
            set_param(h, 'Name', nm{keep(j)});
        end
    end
    fprintf('  %s: input %d removed, %d inputs\n', strrep(bc, newline, ' '), k, numel(keep));
end

function rename_tags(root, map)
% rename the tags of Goto, From and Goto Tag Visibility blocks under root
    types = {'Goto', 'From', 'GotoTagVisibility'};
    for t = 1:numel(types)
        b = find_system(root, 'LookUnderMasks', 'all', 'FollowLinks', 'off', 'IncludeCommented', 'on', ...
            'BlockType', types{t});
        for k = 1:numel(b)
            i = find(strcmp(map(:, 1), get_param(b{k}, 'GotoTag')));
            if ~isempty(i)
                set_param(b{k}, 'GotoTag', map{i, 2});
            end
        end
    end
end

function remove_orphan_visibility(M)
% a Goto Tag Visibility block without a scoped Goto of its tag in its subsystem is deleted
    v = find_system(M, 'LookUnderMasks', 'all', 'FollowLinks', 'off', 'IncludeCommented', 'on', ...
        'BlockType', 'GotoTagVisibility');
    n = 0;
    for k = 1:numel(v)
        tag = get_param(v{k}, 'GotoTag');
        g = find_system(get_param(v{k}, 'Parent'), 'LookUnderMasks', 'all', 'FollowLinks', 'on', ...
            'IncludeCommented', 'on', 'BlockType', 'Goto', 'GotoTag', tag, 'TagVisibility', 'scoped');
        if isempty(g)
            delete_block(v{k});
            n = n + 1;
        end
    end
    fprintf('  %d Goto Tag Visibility blocks without a scoped Goto deleted\n', n);
end

function remap_parameters(M)
% re-point the legacy workspace names of the block parameters to param.*
    skip = {'GotoTag', 'VariableName', 'OutputSignals', 'Name', 'FunctionName', 'Commented'};
    b = find_system(M, 'LookUnderMasks', 'all', 'FollowLinks', 'off', 'IncludeCommented', 'on', 'Type', 'block');
    n = 0;
    for k = 1:numel(b)
        try
            dp = get_param(b{k}, 'DialogParameters');
        catch
            continue
        end
        if isempty(dp) || ~isstruct(dp)
            continue
        end
        names = setdiff(fieldnames(dp), skip);
        for j = 1:numel(names)
            try
                v = get_param(b{k}, names{j});
            catch
                continue
            end
            if ~ischar(v) || isempty(v)
                continue
            end
            nv = remap_expr(v, b{k});
            if ~strcmp(nv, v)
                try
                    set_param(b{k}, names{j}, nv);
                    n = n + 1;
                catch ME
                    fprintf('  set failed %s : %s = %s (%s)\n', strrep(b{k}, newline, ' '), names{j}, nv, ME.message);
                end
            end
        end
    end
    fprintf('  %d parameters re-pointed\n', n);
end

function nv = remap_expr(v, blk)
    pre = '(?<![\w.])';
    if contains(blk, '/shunt_active_filter') || contains(blk, '/scope/') || contains(blk, '/grid_emulator/')
        c = 'saf';
    elseif contains(blk, '/voltage_stabiliser') || contains(blk, '/load_ui_measures') || ...
            contains(blk, '/series_three_phase_transformer')
        c = 'vs';
    else
        c = 'saf';
    end
    C = upper(c);
    r = {
        [pre '(param\.)?glb_time\.ts_afe\>'], ['param.glb_time.ts_' c]
        [pre '(param\.)?glb_time\.Ns_afe\>'], ['param.glb_time.Ns_' c]
        [pre '(param\.)?glb_time\.fPWM_AFE\>'], ['param.glb_time.fPWM_' C]
        [pre '(param\.)?glb_time\.dead_time_AFE\>'], ['param.glb_time.dead_time_' C]
        [pre 'glb_time\.'], 'param.glb_time.'
        [pre 'hwdata\.afe\.'], ['param.' c '.hw.']
        [pre 'hwdata\.dab\.'], 'param.dab.hw.'
        [pre '(param\.afe|afe_ctrl)\.ctrl\.'], ['param.' c '.ctrl.']
        [pre 'afe_ctrl\.'], ['param.' c '.ctrl.']
        [pre 'param\.afe\.uvw\>'], ['param.' c '.uvw']
        [pre 'param\.afe\.ref\.'], 'param.saf.ref.'
        [pre 'param\.grid\.emu\.omega_grid_nom\>'], ['param.' c '.ctrl.omega_base']
        [pre 'grid_emu\.ugrid_bez\>'], ['param.' c '.hw.ubez']
        [pre 'grid_emu\.igrid_bez\>'], ['param.' c '.hw.ibez']
        [pre 'grid_emu\.(u[pn]_(xi|eta)_pu_ref)\>'], 'param.vs.ref.$1'
        [pre 'grid_emu\.'], 'param.grid.emu.'
        [pre 'upqc_st\.'], 'param.vs.st.'
        [pre 'upqc_ctrl\.'], 'param.vs.ctrl.'
        [pre 'dab_ctrl\.'], 'param.dab.ctrl.'
        [pre 'lithium_ion_battery_1\.'], 'param.battery.pack_1.'
        [pre '(kp_align|ki_align|lim_up_align|lim_down_align)\>'], 'param.ctrl.$1'
        [pre '(adc_quantization|adc12_quantization)\>'], 'param.meas.$1'
        [pre 'ixi_ref_mod1\>'], 'param.saf.ref.ixi_ref'
        [pre 'u_cm_comp_mod1\>'], 'param.saf.ref.u_cm_comp'
        [pre 'u_cm_comp_mod2\>'], 'param.vs.ref.u_cm_comp'
        [pre 'afe_pwm_phase_shift_mod1\>'], 'param.saf.behav.pwm_phase_shift'
        [pre 'afe_pwm_phase_shift_mod2\>'], 'param.vs.behav.pwm_phase_shift'
        [pre 'time_gain_afe_module_1\>'], 'param.saf.behav.time_gain'
        [pre 'time_gain_afe_module_2\>'], 'param.vs.behav.time_gain'
        [pre 'param\.ctrl\.filters\.afe\.SOF_50Hz\.ss_c\.([ABCD])\>'], 'param.grid.emu.sof.$1'
        };
    nv = v;
    for k = 1:size(r, 1)
        nv = regexprep(nv, r{k, 1}, r{k, 2});
    end
    % the grid emulator itself reads the grid data (only the power meter copied from main uses ts_afe)
    if contains(blk, '/grid_emulator/')
        nv = regexprep(nv, [pre 'param\.saf\.ctrl\.omega_base\>'], 'param.grid.emu.omega_grid_nom');
    end
end

function report_legacy(M)
% block parameters that still contain a legacy workspace name
    pat = ['(?<![\w.])(glb_time|hwdata|grid_emu|afe_ctrl|upqc_st|upqc_ctrl|dab_ctrl|lithium_ion_battery_\d|' ...
        'param\.afe|\w+_mod[1-4]|time_gain_\w+|adc\d*_quantization|kp_align|ki_align|lim_\w+_align)\>'];
    skip = {'GotoTag', 'VariableName', 'OutputSignals', 'Name', 'FunctionName', 'Commented'};
    b = find_system(M, 'LookUnderMasks', 'all', 'FollowLinks', 'off', 'IncludeCommented', 'on', 'Type', 'block');
    n = 0;
    for k = 1:numel(b)
        try
            dp = get_param(b{k}, 'DialogParameters');
        catch
            continue
        end
        if isempty(dp) || ~isstruct(dp)
            continue
        end
        names = setdiff(fieldnames(dp), skip);
        for j = 1:numel(names)
            try
                v = get_param(b{k}, names{j});
            catch
                continue
            end
            if ischar(v) && ~isempty(regexp(v, pat, 'once'))
                fprintf('  legacy: %s : %s = %s\n', strrep(b{k}, newline, ' '), names{j}, v);
                n = n + 1;
            end
        end
    end
    fprintf('  %d parameters with legacy names\n', n);
end
