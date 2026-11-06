function hw = dab_hw_param(application_voltage, pwr_nom, fpwm, fres)
%DAB_HW_PARAM  Hardware data of the single-phase dual active bridge between the battery and the DC link
%   (local replacement of single_phase_dab_hwdata and hw_dab_single_phase_setup of the library, same data
%   sets, formulas and field names, returns a struct).
%
%   hw = dab_hw_param(application_voltage, pwr_nom, fpwm, fres)
%     application_voltage  [V] 690: DAB 1200 V; 480 or 400: DAB 800 V
%     pwr_nom              [W] rated power
%     fpwm                 [Hz] switching frequency of the bridges
%     fres                 [Hz] resonance frequency of the series tank (Cs)
%
%   Data sets: DAB_1200V (udc 1200 V, uac 1000 V, idc 250 A) and DAB_800V (udc 800 V, uac 800 V, idc 350 A),
%   both with Lm 1 mH, n1 = n2 = 6, Rfe 1 kOhm, Rs1 1 mOhm, core length 1 m and mur 75, DC links of 3.6 mF and
%   1 mOhm, DC inductors of 250 uH. Series inductance Ls = udc1^2/(4*pi*fpwm*pwr_nom) (power at a phase shift
%   of 1 rad with margin), split half per winding (Ld1, Ld2 referred to the secondary); Cs = 1/(Ls*(2*pi*fres)^2).
%   The library data set DAB_800V had RCdc1_dc2 = Cdc_dc2/2 (a capacitance instead of RCdc_dc2/2): fixed here.
%
%   Fields read by ls_upqc.slx (param.dab.hw, block dab_mod1): Cdc_dc1, Cdc_dc2, RCdc_dc1, RCdc_dc2, Ldc_dc1,
%   Ldc_dc2, RLdc_dc1, RLdc_dc2, Ld1, Ld2, Lm, Rfe, Rs1, Rs2, core_length, core_mur, n1, n2, idc1_bez,
%   udc2_bez, udc2_nom.

    if application_voltage == 690
        name = 'DAB_1200V';
        udc1 = 1200; udc2 = 1200; uac1 = 1000; uac2 = 1000; idc1 = 250; idc2 = 250;
    else
        name = 'DAB_800V';
        udc1 = 800; udc2 = 800; uac1 = 800; uac2 = 800; idc1 = 350; idc2 = 350;
    end

    hw = struct();
    hw.name = name;
    hw.pwr_nom = pwr_nom;
    hw.udc1_nom = udc1;                         % [V] DC voltage of side 1 (battery)
    hw.udc2_nom = udc2;                         % [V] DC voltage of side 2 (DC link of the SAF and the VS)
    hw.uac1_nom = uac1;
    hw.uac2_nom = uac2;
    hw.idc1_nom = idc1;                         % [A]
    hw.idc2_nom = idc2;
    hw.fpwm_base = fpwm;                        % [Hz]
    hw.fres_base = fres;                        % [Hz]

    % transformer
    hw.n1 = 6;
    hw.n2 = 6;
    n12 = hw.n1/hw.n2;
    hw.Lm = 1e-3;                               % [H] magnetizing inductance (primary)
    hw.Rfe = 1e3;                               % [Ohm] iron losses
    hw.core_length = 1;                         % [m]
    hw.core_mur = 75;

    % series tank
    hw.Ls = udc1^2/fpwm/pwr_nom/4/pi;           % [H] (udc1^2/fpwm/pwr_nom/8 without margin)
    hw.Cs = 1/hw.Ls/(2*pi*fres)^2;              % [F]
    hw.Rs1 = 1e-3;                              % [Ohm] winding resistances
    hw.Rs2 = hw.Rs1/n12^2;
    hw.Ld1 = hw.Ls/2;                           % [H] leakage inductances
    hw.Ld2 = hw.Ld1/n12^2;
    hw.Cs1 = 2*hw.Cs;
    hw.Cs2 = hw.Cs1*n12^2;
    hw.Ls1 = hw.Ld1;
    hw.Ls2 = hw.Ld2;

    % DC links (whole bank and the two halves of a three-level bridge) and DC inductors
    hw.Cdc_dc1 = 3.6e-3;                        % [F]
    hw.Cdc1_dc1 = 2*hw.Cdc_dc1;
    hw.Cdc2_dc1 = 2*hw.Cdc_dc1;
    hw.Cdc_dc2 = 3.6e-3;
    hw.Cdc1_dc2 = 2*hw.Cdc_dc2;
    hw.Cdc2_dc2 = 2*hw.Cdc_dc2;
    hw.RCdc_dc1 = 1e-3;                         % [Ohm]
    hw.RCdc1_dc1 = hw.RCdc_dc1/2;
    hw.RCdc2_dc1 = hw.RCdc_dc1/2;
    hw.RCdc_dc2 = 1e-3;
    hw.RCdc1_dc2 = hw.RCdc_dc2/2;
    hw.RCdc2_dc2 = hw.RCdc_dc2/2;
    hw.Ldc_dc1 = 250e-6;                        % [H]
    hw.RLdc_dc1 = 157*0.05*hw.Ldc_dc1;          % [Ohm]
    hw.Ldc_dc2 = 250e-6;
    hw.RLdc_dc2 = 157*0.05*hw.Ldc_dc2;

    % normalization bases and end scales
    hw.idc1_bez = hw.idc1_nom;
    hw.idc2_bez = hw.idc2_nom;
    hw.udc1_bez = hw.udc1_nom;
    hw.udc2_bez = hw.udc2_nom;
    hw.Idc_FS = max(hw.idc1_bez, hw.idc2_bez);
    hw.Vdc_FS = max(hw.udc1_bez, hw.udc2_bez);

    fprintf('DAB %s: %.0f kW, %.0f/%.0f V, fpwm %.0f Hz, Ls %.1f uH, Cs %.1f uF\n', ...
        hw.name, hw.pwr_nom/1e3, hw.udc1_nom, hw.udc2_nom, hw.fpwm_base, hw.Ls*1e6, hw.Cs*1e6);
end
