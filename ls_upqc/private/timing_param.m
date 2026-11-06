function glb_time = timing_param(t, saf_pwm, vs_pwm, dab_pwm)
%TIMING_PARAM  Timing data of ls_upqc (local replacement of timing_setup of the library).
%
%   glb_time = timing_param(t, saf_pwm, vs_pwm, dab_pwm)
%     t                         param.time:
%       t.t_measure             [s] logging window (the To Workspace blocks keep the last t_measure seconds)
%       t.tc_factor             ts_saf/tc: tc is the logging base, the MaxStep of the solver, the step of the
%                               Simscape local solver and of the PWM generators
%       t.tc_decimation         decimation of the logging at tc
%     saf_pwm, vs_pwm, dab_pwm  param.saf.pwm, param.vs.pwm, param.dab.pwm:
%       .fpwm                   [Hz] carrier frequency of the converter
%       .trgo                   1: double update (two control steps per carrier period), 0: single update
%       .dead_time              [s] dead time of the modulator
%
%   Three clock domains, one per converter: shunt active filter (SAF), voltage stabilizer (VS) and dual active
%   bridge (DAB, used only with the storage). Each control runs in a subsystem triggered by the TRGO of its
%   own PWM generator, so ts_saf, ts_vs and ts_dab are the control periods.
%
%   Fields read by ls_upqc.slx: fPWM_SAF, dead_time_SAF, ts_saf, fPWM_VS, dead_time_VS, ts_vs, tc, Nc,
%   decimation_tc, Ns_saf, Ns_vs and, with the storage, fPWM_DAB, TRGO_DAB_double_update, dead_time_DAB,
%   ts_dab, Ns_dab. The legacy init had the seven domains of the shared template (afe, inv, single_phase_inv,
%   dab, psfbc, isop_rail, cllc): SAF and VS were both on the AFE domain (fPWM_AFE, ts_afe), and
%   tc = ts_afe/tc_factor is now tc = ts_saf/tc_factor, the same value.

    glb_time = struct();
    [glb_time.fPWM_SAF, glb_time.tPWM_SAF, glb_time.TRGO_SAF_double_update, glb_time.ts_saf, ...
        glb_time.dead_time_SAF] = domain(saf_pwm);
    [glb_time.fPWM_VS, glb_time.tPWM_VS, glb_time.TRGO_VS_double_update, glb_time.ts_vs, ...
        glb_time.dead_time_VS] = domain(vs_pwm);
    [glb_time.fPWM_DAB, glb_time.tPWM_DAB, glb_time.TRGO_DAB_double_update, glb_time.ts_dab, ...
        glb_time.dead_time_DAB] = domain(dab_pwm);

    % logging base, MaxStep of the solver, step of the Simscape local solver and of the PWM generators
    glb_time.tc = glb_time.ts_saf/t.tc_factor;
    glb_time.decimation_tc = t.tc_decimation;
    glb_time.t_measure = t.t_measure;
    glb_time.Nc = ceil(t.t_measure/glb_time.tc/t.tc_decimation);
    glb_time.Ns_saf = ceil(t.t_measure/glb_time.ts_saf);
    glb_time.Ns_vs = ceil(t.t_measure/glb_time.ts_vs);
    glb_time.Ns_dab = ceil(t.t_measure/glb_time.ts_dab);

    % the carrier of each PWM generator counts steps of tc: a control period that is not a multiple of tc
    % gives a carrier frequency slightly different from fpwm
    for d = {'saf', 'vs', 'dab'}
        ratio = glb_time.(['ts_' d{1}])/glb_time.tc;
        if abs(ratio - round(ratio)) > 1e-6
            fprintf('Timing: ts_%s/tc = %.3f is not an integer\n', d{1}, ratio);
        end
    end

    fprintf(['Timing: SAF %.0f Hz (ts %.1f us), VS %.0f Hz (ts %.1f us), DAB %.0f Hz (ts %.2f us), ' ...
        'tc = %.4f us, logging window %.3f s (Nc = %d)\n'], ...
        glb_time.fPWM_SAF, glb_time.ts_saf*1e6, glb_time.fPWM_VS, glb_time.ts_vs*1e6, ...
        glb_time.fPWM_DAB, glb_time.ts_dab*1e6, glb_time.tc*1e6, glb_time.t_measure, glb_time.Nc);
end

function [fpwm, tpwm, trgo, ts, dead_time] = domain(pwm)
    fpwm = pwm.fpwm;
    tpwm = 1/pwm.fpwm;
    trgo = pwm.trgo;
    if pwm.trgo
        ts = tpwm/2;
    else
        ts = tpwm;
    end
    dead_time = pwm.dead_time;
end
