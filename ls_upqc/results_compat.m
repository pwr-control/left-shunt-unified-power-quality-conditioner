%RESULTS_COMPAT  Names of init_model.m for a workspace of simulation results (script, run after load).
%   load sim_results_2.mat; results_compat          (from ls_upqc)
%   load ..\sim_results_2.mat; run(fullfile('..', 'results_compat.m'))     (from ls_upqc/video_plots)
%
%   Results of the legacy init (branch main: glb_time, hwdata, DAB signals *_mod1_sim) get param.glb_time,
%   param.saf.hw, param.vs.hw (the legacy init had one data set, hwdata.afe, for both converters), param.dab.hw,
%   param.grid.fgrid, param.grid.us2 and the DAB signals with the names of this model. Results without the
%   signals of the IEC power meter (P1p_global_sim, Q1p_global_sim, P1n_global_sim, Q1n_global_sim: the block
%   is no longer in ls_upqc.slx, to stay within the 1000 nonvirtual blocks of the MATLAB Home licence) get
%   them from iec_power_meter with the grid voltages and currents (ug_abc_sim, ig_abc_sim).

if ~exist('param', 'var') && exist('glb_time', 'var')
    param.glb_time = glb_time;
    param.saf.hw = hwdata.afe;
    param.vs.hw = hwdata.afe;
    if isfield(hwdata, 'dab')
        param.dab.hw = hwdata.dab;
    end
    param.grid.fgrid = 50;                  % the legacy init: 690 V, 50 Hz
    param.grid.us2 = 690;
    if exist('fgrid', 'var')
        param.grid.fgrid = fgrid;
    end
    if exist('us2', 'var')
        param.grid.us2 = us2;
    end
    if exist('u1_dab_transformer_mod1_sim', 'var')
        u1_dab_transformer_sim = u1_dab_transformer_mod1_sim;
    end
    if exist('u2_dab_transformer_mod1_sim', 'var')
        u2_dab_transformer_sim = u2_dab_transformer_mod1_sim;
    end
    if exist('i1_dab_transformer_mod1_sim', 'var')
        i1_dab_transformer_sim = i1_dab_transformer_mod1_sim;
    end
    if exist('i2_dab_transformer_mod1_sim', 'var')
        i2_dab_transformer_sim = i2_dab_transformer_mod1_sim;
    end
end
if ~exist('time_tc_sim', 'var') && exist('t_tc_sim', 'var')
    time_tc_sim = t_tc_sim;
end
if ~exist('P1p_global_sim', 'var') && exist('ug_abc_sim', 'var') && exist('ig_abc_sim', 'var')
    pm_compat = iec_power_meter(time_tc_sim, ug_abc_sim, ig_abc_sim, param.grid.fgrid);
    P1p_global_sim = pm_compat.P1p;
    Q1p_global_sim = pm_compat.Q1p;
    P1n_global_sim = pm_compat.P1n;
    Q1n_global_sim = pm_compat.Q1n;
    clear pm_compat
end
