function tr = transformer_param(in)
%TRANSFORMER_PARAM  Three-phase transformer data in SI and per unit (local replacement of the library class
%   three_phase_transformer_setup, same formulas and field names, returns a struct).
%
%   tr = transformer_param(in), with the nameplate in the struct in:
%     name                     text; a name that starts with the vector group (Dyn11, Yyn0, ...) sets the clock number
%     delta_star               1: delta primary (Dyn), 0: star primary (Yyn); the secondary is always star
%     pwr_nom                  [VA] rated power
%     u1_nom, u2_nom           [V] rated line-to-line voltages
%     f_nom                    [Hz]
%     eta                      [%] efficiency at rated load (copper losses (1 - eta/100)*pwr_nom, half per winding)
%     ucc                      [%] short-circuit voltage
%     i1m                      [A] no-load LINE current of the primary side
%     p_iron                   [W] iron losses, total of the three limbs
%     n1, n2                   turns of the primary and secondary coil
%     core_area, core_length   [m^2], [m]
%     mur                      relative permeability of the core
%     lm0_pu                   (optional) zero-sequence magnetizing inductance [pu]; default lm0 = lm
%
%   SI fields: the data of ONE COIL (the model of the series transformer is made of three single-phase
%   transformers). A delta primary coil sees the line voltage and carries the line current divided by
%   sqrt(3): its resistance and leakage inductance are 3 times the star-equivalent values and its
%   magnetizing branch (Lm1, Rfe1, psi) is referred to the line voltage. A star coil sees the phase voltage.
%   Per-unit fields (struct pu): parameters of the block configurable_trafo (grid emulator): Sr, V1, V3, fr,
%   r1, l1, r3, l3, lm, lm0, rfe, clock3, on the coil bases of the Simscape components (V^2/Sr for a star
%   coil, 3*V^2/Sr for a delta coil).
%
%   Fields read by ls_upqc.slx. Grid emulator (param.grid.emu.trafo): pu.*, f_nom, pwr_nom, u1_nom, u2_nom.
%   Series transformer of the VS (param.vs.st, block saturable_single_phase_transformer): Ld1, Ld2, Rd1, Rd2,
%   Rfe1, n1, n2, psi, core_area, core_length, mu0, mur.

    tr = struct();
    tr.name = in.name;
    tr.delta_star = in.delta_star;
    tr.pwr_nom = in.pwr_nom;
    tr.u1_nom = in.u1_nom;
    tr.i1_nom = in.pwr_nom/sqrt(3)/in.u1_nom;
    tr.u2_nom = in.u2_nom;
    tr.i2_nom = in.pwr_nom/sqrt(3)/in.u2_nom;
    tr.f_nom = in.f_nom;
    tr.ucc = in.ucc;
    tr.eta = in.eta;
    tr.i1m = in.i1m;
    tr.n12 = in.u1_nom/in.u2_nom;
    tr.n1 = in.n1;
    tr.n2 = in.n2;
    omega = 2*pi*in.f_nom;

    % primary coil: delta (Dy) sees the line voltage and carries the line current / sqrt(3), so its
    % resistance and leakage are k1 = 3 times the star-equivalent values; star (Yy): k1 = 1
    if in.delta_star == 1
        k1 = 3;
        tr.u1_coil = in.u1_nom;
    else
        k1 = 1;
        tr.u1_coil = in.u1_nom/sqrt(3);
    end
    tr.i1m_coil = in.i1m/sqrt(k1);
    [tr.clock, tr.vector_group] = vector_group_of(char(in.name), in.delta_star);

    % leakage from the short-circuit voltage, copper losses (1 - eta)*pwr_nom, half per winding,
    % both as star equivalents on the primary side
    tr.Lsigma = in.u1_nom*in.ucc/100/sqrt(3)/tr.i1_nom/omega;
    Rd_star = 0.5*((1 - in.eta/100)*in.pwr_nom/3/tr.i1_nom^2);
    tr.Ld1 = k1*tr.Lsigma/2;
    tr.Rd1 = k1*Rd_star;

    % secondary coil (star): star-equivalent values referred with the line-to-line ratio
    tr.Ld2 = tr.Lsigma/2/tr.n12^2;
    tr.Rd2 = Rd_star/tr.n12^2;

    % magnetizing branch of the primary coil at its own voltage; iron losses one third per limb
    tr.Lm1 = tr.u1_coil/tr.i1m_coil/omega;
    tr.Lm2 = tr.Lm1/(tr.u1_coil/(in.u2_nom/sqrt(3)))^2;
    tr.p_iron = in.p_iron;
    tr.Rfe1 = tr.u1_coil^2/(in.p_iron/3);
    tr.psi = sqrt(2)*tr.u1_coil/omega;                     % peak flux linkage of the primary coil

    tr.core_area = in.core_area;
    tr.core_length = in.core_length;
    tr.mu0 = 4*pi*1e-7;
    tr.mur = in.mur;

    % per unit: coil bases of the Simscape components (star coil V^2/Sr, delta coil 3*V^2/Sr)
    tr.Zbase1 = in.u1_nom^2/in.pwr_nom;
    tr.Zbase2 = in.u2_nom^2/in.pwr_nom;
    tr.Zcoil1 = k1*tr.Zbase1;
    tr.Zcoil2 = tr.Zbase2;
    tr.Lsigma_pu = omega*tr.Lsigma/tr.Zbase1;              % = ucc/100
    tr.Rd1_pu = tr.Rd1/tr.Zcoil1;                          % = (1 - eta/100)/2
    tr.Ld1_pu = omega*tr.Ld1/tr.Zcoil1;                    % = ucc/200
    tr.Lm1_pu = omega*tr.Lm1/tr.Zcoil1;                    % = i1_nom/i1m
    tr.Rfe1_pu = tr.Rfe1/tr.Zcoil1;                        % = pwr_nom/p_iron
    tr.Rd2_pu = tr.Rd2/tr.Zcoil2;
    tr.Ld2_pu = omega*tr.Ld2/tr.Zcoil2;
    tr.i1m_pu = in.i1m/tr.i1_nom;                          % = 1/Lm1_pu
    if ~isfield(in, 'lm0_pu') || isempty(in.lm0_pu)
        tr.lm0_pu = tr.Lm1_pu;                             % bank of single-phase units
    else
        tr.lm0_pu = in.lm0_pu;                             % three-limb core: a fraction of a pu
    end

    % parameters of the block configurable_trafo (one primary, three-phase secondary)
    tr.pu = struct('Sr', in.pwr_nom, 'V1', in.u1_nom, 'V3', in.u2_nom, 'fr', in.f_nom, ...
        'r1', tr.Rd1_pu, 'l1', tr.Ld1_pu, 'r3', tr.Rd2_pu, 'l3', tr.Ld2_pu, ...
        'lm', tr.Lm1_pu, 'lm0', tr.lm0_pu, 'rfe', tr.Rfe1_pu, 'clock3', tr.clock);

    fprintf('%s (%s): Ld1 = %.3g H, Ld2 = %.3g H, Lm1 = %.3g H, Rd1 = %.3g mOhm, Rd2 = %.3g mOhm, Rfe1 = %.3g Ohm\n', ...
        tr.name, tr.vector_group, tr.Ld1, tr.Ld2, tr.Lm1, tr.Rd1*1e3, tr.Rd2*1e3, tr.Rfe1);
end

function [clock, vector_group] = vector_group_of(name, delta_star)
% clock number of the vector group from a name that starts with it (Dyn11, Dyn1, Yyn0, Yyn6, also Dy11, Yy0);
% an odd clock number goes with a delta primary and a star secondary, an even one with two star windings.
% A name without a vector group gives the default of the connection (Dyn11 / Yyn0).
    if delta_star == 1
        clock = 11;
        prefix = 'Dyn';
    else
        clock = 0;
        prefix = 'Yyn';
    end
    tok = regexp(name, '^[DY][dy]n?(\d{1,2})', 'tokens', 'once');
    if ~isempty(tok)
        c = str2double(tok{1});
        if c >= 0 && c <= 11 && mod(c, 2) == mod(clock, 2)
            clock = c;
        else
            warning('transformer_param:clock', ...
                'clock number %d of ''%s'' does not fit the connection (delta_star = %d): %s%d used', ...
                c, name, delta_star, prefix, clock);
        end
    end
    vector_group = sprintf('%s%d', prefix, clock);
end
