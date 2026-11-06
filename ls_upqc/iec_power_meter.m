function pm = iec_power_meter(t, u_abc, i_abc, fgrid)
%IEC_POWER_METER  Fundamental positive- and negative-sequence powers of a three-phase port, from logged
%   waveforms (post-processing).
%
%   pm = iec_power_meter(t, u_abc, i_abc, fgrid)
%     t      [s]  time, uniform step, N x 1
%     u_abc  [V]  phase-to-neutral voltages, N x 3
%     i_abc  [A]  phase currents, N x 3 (positive into the load)
%     fgrid  [Hz] grid frequency: the window of the Fourier analysis is one period
%
%   pm.P1p, pm.Q1p, pm.P1n, pm.Q1n  [W, var] fundamental active and reactive power of the positive and of the
%                                    negative sequence, N x 1 (NaN during the first period)
%   pm.U1p, pm.U1n, pm.I1p, pm.I1n  [V, A] rms of the sequence components
%   pm.u1p, pm.u1n, pm.i1p, pm.i1n  complex rms phasors in the frame that rotates at 2*pi*fgrid
%
%   The fundamental phasor of each phase comes from a sliding one-period DFT, the sequences from the
%   symmetrical components, and P + jQ = 3 U I* for each sequence (IEC 61000-4-30, IEEE 1459). These are the
%   quantities of the IEC power meter block of the branch main (P1p_global ... Q1n_global): the block is no
%   longer in ls_upqc.slx, to stay within the 1000 nonvirtual blocks of the MATLAB Home licence, and
%   plot_sim.m and video_plot_sim.m call this function when the results do not contain P1p_global_sim.
%
%   Example (results of ls_upqc.slx in the workspace):
%     pm = iec_power_meter(time_tc_sim, ug_abc_sim, ig_abc_sim, param.grid.fgrid);

    t = t(:);
    if size(u_abc, 1) ~= numel(t)
        u_abc = u_abc.';
    end
    if size(i_abc, 1) ~= numel(t)
        i_abc = i_abc.';
    end
    dt = (t(end) - t(1))/(numel(t) - 1);
    n = round(1/(fgrid*dt));                        % samples in one period
    e = exp(-1j*2*pi*fgrid*t);
    a = exp(1j*2*pi/3);
    T = [1 a a^2; 1 a^2 a].'/3;                     % columns: positive, negative sequence
    u_seq = sliding_dft(double(u_abc), e, n)*T;
    i_seq = sliding_dft(double(i_abc), e, n)*T;
    s1p = 3*u_seq(:, 1).*conj(i_seq(:, 1));
    s1n = 3*u_seq(:, 2).*conj(i_seq(:, 2));
    pm.P1p = real(s1p);
    pm.Q1p = imag(s1p);
    pm.P1n = real(s1n);
    pm.Q1n = imag(s1n);
    pm.u1p = u_seq(:, 1);
    pm.u1n = u_seq(:, 2);
    pm.i1p = i_seq(:, 1);
    pm.i1n = i_seq(:, 2);
    pm.U1p = abs(pm.u1p);
    pm.U1n = abs(pm.u1n);
    pm.I1p = abs(pm.i1p);
    pm.I1n = abs(pm.i1n);
end

function X = sliding_dft(x, e, n)
% rms phasor of the fundamental of each column of x over the last n samples
    c = cumsum(x.*e, 1);
    X = nan(size(x));
    X(n:end, :) = (c(n:end, :) - [zeros(1, size(x, 2)); c(1:end-n, :)])*(sqrt(2)/n);
end
