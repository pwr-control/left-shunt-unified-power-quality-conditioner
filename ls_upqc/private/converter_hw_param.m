function hw = converter_hw_param(name, application_voltage, pwr_nom, fpwm)
%CONVERTER_HW_PARAM  Hardware data of a three-phase two-level converter with its DC link and LC filter
%   (local replacement of three_phase_afe_hwdata and hw_afe_three_phase_setup of the library, same data sets,
%   formulas and field names, returns a struct).
%
%   hw = converter_hw_param(name, application_voltage, pwr_nom, fpwm)
%     name                 text, e.g. 'saf690V'
%     application_voltage  [V] 690, 480 or 400: selects the data set
%     pwr_nom              [W] rated power
%     fpwm                 [Hz] carrier frequency
%
%   Data sets (the same three of the library):
%     690 V, 50 Hz: udc 1070 V, LFu 500 uH, CFu 200 uF, Rbrake 4 Ohm
%     480 V, 60 Hz: udc  750 V, LFu 330 uH, CFu 360 uF, Rbrake 2.5 Ohm
%     400 V, 50 Hz: udc  660 V, LFu 330 uH, CFu 360 uF, Rbrake 2.5 Ohm
%   all with CFi 7.2 mF, RCFi 1 mOhm, RCFu 50 mOhm, RLFu = 157*0.05*LFu, LFu_cm = LFu. Rated current
%   is_nom = pwr_nom/sqrt(3)/us_nom/0.9. Bases: ubez = us_nom*sqrt(2/3) (peak phase voltage), ibez =
%   is_nom*sqrt(2) (peak current).
%
%   Fields read by ls_upqc.slx (param.saf.hw and param.vs.hw): CFi, udc_nom (DC link), LFu, LFu_cm, RLFu,
%   RLFu_cm, CFu, RCFu (filter), ubez, ibez (measurements).

    hw = struct();
    switch application_voltage
        case 690
            us_nom = 690; f_nom = 50; udc = 1070;
            LFu = 500e-6; CFu = 200e-6; Rbrake = 4;
        case 480
            us_nom = 480; f_nom = 60; udc = 750;
            LFu = 330e-6; CFu = 360e-6; Rbrake = 2.5;
        otherwise
            us_nom = 400; f_nom = 50; udc = 660;
            LFu = 330e-6; CFu = 360e-6; Rbrake = 2.5;
    end

    hw.name = name;
    hw.pwr_nom = pwr_nom;
    hw.us_nom = us_nom;                         % [V] rated line-to-line voltage
    hw.is_nom = pwr_nom/sqrt(3)/us_nom/0.9;     % [A] rated current (10 % margin)
    hw.f_nom = f_nom;                           % [Hz]
    hw.udc_nom = udc;                           % [V] rated DC-link voltage
    hw.fpwm_base = fpwm;                        % [Hz]

    % DC link: whole bank and the two halves of a three-level converter
    hw.CFi = 7.2e-3;                            % [F]
    hw.RCFi = 1e-3;                             % [Ohm]
    hw.CFi1 = 2*hw.CFi;
    hw.RCFi1 = hw.RCFi/2;
    hw.CFi2 = 2*hw.CFi;
    hw.RCFi2 = hw.RCFi/2;

    % LC filter on the AC side
    hw.LFu = LFu;                               % [H] filter inductance
    hw.RLFu = 157*0.05*LFu;                     % [Ohm] its resistance
    hw.LFu_cm = LFu;                            % [H] common-mode (zero-sequence) inductance
    hw.RLFu_cm = 157*0.05*hw.LFu_cm;            % [Ohm]
    hw.CFu = CFu;                               % [F] filter capacitor
    hw.RCFu = 50e-3;                            % [Ohm] its damping resistor
    hw.Rbrake = Rbrake;                         % [Ohm] braking resistor

    % normalization bases
    hw.ubez = hw.us_nom*sqrt(2/3);              % [V] peak phase voltage
    hw.ibez = hw.is_nom*sqrt(2);                % [A] peak current

    fprintf('Converter %s: %.0f kW, %.0f V, udc %.0f V, LFu %.0f uH, CFu %.0f uF, ubez %.1f V, ibez %.1f A\n', ...
        hw.name, hw.pwr_nom/1e3, hw.us_nom, hw.udc_nom, hw.LFu*1e6, hw.CFu*1e6, hw.ubez, hw.ibez);
end
