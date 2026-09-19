# ls_upqc — F-UPQC simulation bench

## System

- **Grid side** — three-phase grid emulator (690 V, 50 Hz) with fault-ride-through
  generator (`frt_settings`, `grid_fault_generator`: symmetric/asymmetric dips defined by
  `test_index`, `test_subindex`, positive/negative sequence depths, start at 0.75 s).
- **Shunt active filter (SAF)** — three-phase two-level converter on the grid side with LCL
  filter, `fPWM = 4 kHz` with double update, 3 µs deadtime; positive- and negative-sequence
  ξ–η current control, DC-link voltage loop, reactive-current references per VDE 4110
  (`FRT-VDE4110`, `FRT-Detection`, `LVRT_detector`), first-harmonic trackers (FHT) per phase
  and FHT-based dq-PLL, moving-average and sequence calculators, IEC power meter.
- **Series voltage stabilizer (VS)** — two full bridges injecting through the UPQC series
  transformer (`three_phase_transformer_setup`: 3 × 125 kVA, 400 V / 690 V, 50 Hz,
  `ucc = 4 %`), positive/negative sequence voltage controllers (`upqc_ctrl.kp_p/ki_p`,
  `kp_n/ki_n`, limit 4).
- **DC link and storage** — single-phase DAB (`fPWM_DAB = 12 kHz`, 2 µs deadtime, resonance
  at `fPWM_DAB/5`) between the shared DC link and a lithium-ion battery model
  (`lithium_ion_battery_setup`, 250 kW, initial SOC 0.85, `R0`/`R1`/`C1` adjusted);
  DC-link with stray-inductance model (`parasitic_dclink_data`).
- **Load** — single-phase load transformer (225 kVA, 400 V, 50:1) with RL load, plus the
  three-phase RL load of the library.
- Devices: `mitsubishi_CM1200DW_24T` IGBT, `danfoss_SKM1700MB20R4S2I4` SiC MOSFET or ideal
  switch; thermal models off by default (`use_thermal_model`, `use_mosfet_thermal_model`).
- Each converter has its own local time base aligned to the master time (`time_gain_*`,
  `trgo_th_generator`, PWM phase shifts, optional white noise) to study the effect of
  non-synchronized controllers.

## Files

- `init_model.m` — live-script style initialization (2.25 s run, load step at 1.25 s); the
  `%[text]` headings list every parameter group.
- `ls_upqc.slx` — the model.
- `plot_sim.m` — grid and load voltages/currents, VS voltages and currents, SAF currents,
  SAF DC-link voltage and battery current, DAB AC voltages/current, DAB Q1 device
  voltages/current; EPS output.
- `plot_spectrum.m` — grid phase-voltage spectra (harmonic ranges 2–11, 11–17, 17–23,
  23–35) with and without islanding.
- `video_plot_sim.m` — two-window animation of three-phase voltages/currents and of the
  sequence powers `P1p, P1n, Q1p, Q1n` (loads `sim_results_icc20inom_3.mat`).
- `video_plots/` — MP4 generators (`VideoWriter`, dark theme):
  `video_plot_grid_load_quantities_1/2.m` (line and load quantities during a voltage sag,
  with and without battery charging), `video_plot_saf_vs_quantities_1/2.m` (SAF and VS
  voltages/currents), `video_plot_dclink_grid_powers.m` (SAF and battery DC voltages,
  battery current, grid powers), `video_plot_dab_essential_1/2.m` and
  `video_plot_dab_advanced_1/2.m` (DAB AC quantities and Q1 `Uds`/`Ugs` during battery
  charging and during a sag). These are the sources of the *Fun with UPQC* video.
