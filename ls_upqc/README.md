# ls_upqc — left-shunt unified power quality conditioner

Simulink/Simscape bench of a left-shunt (flipped) UPQC on a 690 V, 50 Hz grid. The shunt active filter
(SAF) faces the grid and controls the grid current; the voltage stabilizer (VS) injects a voltage through a
series transformer and keeps the load voltage at its reference during dips and swells; an optional dual
active bridge (DAB) connects a lithium-ion battery to the DC link that SAF and VS share.

```
 grid emulator ──── grid transformer ────┬──── series transformer ──── load measures ──── RL load
 690 V, FRT tests     1 MVA, Dyn11       │     3 x 125 kVA, 400/690 V                    R 1 Ohm, L 1 mH
                                         │               │
                                        SAF              VS
                                  250 kW, LC filter    250 kW, LCL filter
                                         │               │
                                         └── DC link ────┘
                                             1200 V
                                               │
                                  DAB 250 kW, 12 kHz ──── battery 1200 V, 50 Ah      (param.sim.storage = 1)
```

## Requirements

- MATLAB with Simulink, Simscape and Simscape Electrical. Tested with R2026b and the MATLAB Home licence:
  the model has 988 nonvirtual blocks with the storage and 669 without, within the limit of 1000 of that
  licence (`non_virtual_blocks_counting.m` counts them). It needs neither the accelerator nor Stateflow.
- The [library](https://github.com/pwr-control/library) repository, branch `dev`: masked blocks (afe_uvw_ctrl,
  pi_ctrl, ideal bridges, DC links, transformers, battery, DAB modulator, grid emulator) and the C sources of
  the C Caller modulators. `init_model.m` puts it on the path (`private/library_setup.m`): the library already
  on the path, else the folder named by the environment variable `PWR_CONTROL_LIBRARY`, else the folder
  `library` next to this repository (the two repositories cloned side by side), cloned with git when it is
  missing. The init itself calls no function of the library.

## How to use

1. Open `init_model.m`, choose the case and run the whole script (Run):
   - `param.sim.storage`: 1 with the DAB and the battery (the DAB holds the DC link, the SAF draws a constant
     active current from the grid and the battery is charged), 0 without them (the SAF holds the DC link);
   - the fault ride-through test (`param.frt.*`, catalogue in `private/frt_param.m`), the load
     (`param.load.R`, `param.load.L`), the references of SAF and VS (`param.saf.ref`, `param.vs.ref`).

   The script computes the struct `param`, opens the model, comments the storage in or out, and checks that
   every `param.*` read by an active block exists and that every active From block has its Goto.
2. Run the simulation: 2.25 s (`param.sim.simlength`), variable-step ode23tb with the maximum step
   `param.glb_time.tc` = 0.625 µs. On a desktop PC (Intel i9-11900F, R2026b) it takes about 16 min with the
   storage and 13 min without. The To Workspace blocks write the `*_sim` arrays into the base workspace
   (logging step `param.glb_time.tc*param.glb_time.decimation_tc`, set by `param.time.tc_decimation`). With
   the default decimation 1 every signal has 3.6 million samples; `param.time.tc_decimation = 40` (25 µs) is
   enough for the figures and makes the results 40 times smaller.
3. Save the workspace (`save sim_results_2`) and run `plot_sim` (eps figures in `./figures`),
   `video_plot_sim` or the scripts of `video_plots/` (MP4). These scripts also read the results of the legacy
   init of the branch main: `results_compat.m` gives them the names of this init, and computes the sequence
   powers `P1p_global_sim`, `Q1p_global_sim`, `P1n_global_sim`, `Q1n_global_sim` with `iec_power_meter.m`
   when the results do not contain them.

## Default case of init_model.m

The storage is on (`param.sim.storage = 1`): the SAF draws 0.85 pu of active current from the grid (236 kW)
and the DAB holds the DC link at 1200 V, charging the battery at about 200 kW; the load (433 kW, 136 kvar) is
fed through the series transformer and the VS keeps its voltage. At 0.75 s the grid emulator applies the FRT
test 25.4 (two-phase dip of 75 %, k = 2): for 0.915 s the positive sequence of the grid voltage falls to
0.40 pu and a negative sequence of 0.57 pu appears. During the power limitation of the FRT the SAF draws no
active current and the DAB supplies from the battery the power that the VS takes to hold the load voltage. At
2.0 s the reference of the reactive current of the SAF steps to 0.28 pu (the SAF supplies about 74 kvar).

Results with the logging step of 25 us, averages over the second half of the fault (1.2 s to 1.6 s):

| | with the storage | without the storage |
|---|---|---|
| load voltage: positive sequence, negative sequence, THD | 1.00 pu, 2.8 V, 1.3 % | 1.00 pu, 3.7 V, 4.5 % |
| DC link: mean (lowest to highest) | 1200 V (1176 V to 1228 V) | 686 V (580 V to 799 V) |
| grid active power; battery power | 176 kW; 276 kW (discharge) | 430 kW |
| after the fault (cleared at 1.665 s) | DC link up to 1323 V, within 1 % of 1200 V from 1.74 s | DC link between 0.23 kV and 1.89 kV, not settled at 2.25 s |

Without the storage the SAF cannot bring from the faulted grid the power that the VS needs (at 0.40 pu and
1.65 pu of active current it draws at most 183 kW, the VS needs about 260 kW): the DC link falls below the
peak line voltage and the SAF loses the control of its current. The design note in
[repositories-documentation](https://github.com/pwr-control/repositories-documentation)
(`repos_doc/unified_power_quality_conditioner`) has the figures and the analysis.

## Parameters

All the data are in one struct `param`; the model reads `param.*` only.

| Group | Content |
|---|---|
| `sim` | stop time, storage on/off, nonlinear iterations of the Simscape solver, model checks |
| `time`, `glb_time` | three clock domains: SAF and VS at 4 kHz with double update (control step 125 µs), DAB at 12 kHz (41.7 µs); logging and solver step `tc` = 0.625 µs |
| `grid` | grid emulator and 1 MVA Dyn11 transformer (`grid.emu`) |
| `frt` | fault ride-through test (`frt.data`) |
| `dclink` | DC-link voltage reference, 1200 V |
| `saf`, `vs` | per converter: `hw` (250 kW, 690 V data set), `ctrl`, `uvw` (afe_uvw_ctrl blocks), `ref`, `behav` (clock gain, carrier phase shift), `pwm`; `vs.st` is the series transformer |
| `dab`, `battery` | DAB (`hw`, `ctrl`, `behav`, `pwm`) and battery pack (`pack_1`, initial voltage `voltage_init_1`) |
| `load` | RL load |
| `meas`, `ctrl` | ADC quantization; PI of the time alignment of the local clocks |
| `design` | informative figures printed by the init |

The functions of `private/` compute the groups (`timing_param`, `grid_emulator_param`, `frt_param`,
`converter_hw_param`, `converter_ctrl_param`, `uvw_param`, `transformer_param`, `dab_hw_param`,
`battery_param`); `init_model.m` calls them through the handles of `ls_upqc_private.m`, because the Live
Editor runs a live script from a copy outside this folder and does not see `private/`.

## Model

| Block | Content |
|---|---|
| `grid_emulator` | `voltage_source_with_frt` (ideal source with the fault generator), `grid_transformer` (1 MVA Dyn11), grid measurements, Simscape Solver Configuration |
| `upqc/saf` | `saf_inverter` (DC link, SVPWM, ideal three-phase bridge), `saf_output_filter`, `saf_control/saf_isr` (acquisitions, time alignment) and `saf_isr/saf_ctrl` (PLL, sequences, FRT of VDE-AR-N 4110, resonant current control, DC-link voltage PI `udc_ctrl`, modulator) |
| `upqc/vs` | `vs_inverter`, `vs_lcl_filter`, `vs_control/vs_isr` and `vs_isr/vs_ctrl` (`load_voltage_sequences`, `load_voltage_ctrl`: PIs of the positive and negative sequence of the load voltage, resonant current control, modulator) |
| `upqc/series_transformer` | three single-phase saturable transformers |
| `upqc/load_measures` | load voltages and currents |
| `upqc/dab`, `upqc/battery` | DAB (`dab_ctrl`, `dcdc_with_galvanic_isolation`) and lithium-ion battery; commented out without the storage |
| `global_timing` | master clock and local clocks `time_saf`, `time_vs`, `time_dab` |
| `measurements` | To Workspace blocks: `saf_quantities`, `vs_quantities`, `dab_quantities`, `load_quantities` |
| `rl_load`, `scopes` | three-phase RL load; scopes of the top level |

Logged signals (base workspace):

| Variables | Content |
|---|---|
| `time_tc_sim` | time [s] |
| `ug_abc_sim`, `ig_abc_sim` | grid voltages [V] and currents [A] at the point of connection |
| `uload_abc_pu_sim`, `iload_abc_pu_sim` | load voltages and currents [pu of the VS bases] |
| `udc_saf_sim`, `vdc_pu_saf_sim`, `ic_dclink_saf_sim`, `ug_abc_pu_saf_sim`, `ig_abc_pu_saf_sim`, `is_abc_pu_saf_sim` | SAF: DC link, grid voltages and currents, stack currents |
| `udc_pu_saf_sim`, `udc_pu_ref_saf_sim` | SAF DC-link voltage loop: measure and reference [pu of 1070 V] |
| `vdc_pu_vs_sim`, `ug_abc_pu_vs_sim`, `ig_abc_pu_vs_sim`, `is_abc_pu_vs_sim` | VS: DC link, voltages and currents |
| `voltage_battery_sim`, `current_battery_sim`, `u1/u2/i1/i2_dab_transformer_sim`, `dab_voltage/current_input/output_sim`, `CFi_dc1/2_current_dab_sim` | battery and DAB (storage only) |
| `saf_ctrl_data_output`, `vs_ctrl_data_output` | control buses of SAF and VS (PLL, current tracking, sequences) |

## Changes of November 2026

The model of the branch main worked with the full licence. The branch dev had removed blocks to stay within
the Home licence, but its init no longer ran with the library and the model had broken links. The init was
rewritten (one `param` struct, functions in `private/`, the legacy init kept as `init_model_legacy.m`) and
the model was migrated with these changes:

- **DAB that transferred no power.** The ideal bridges of the library (`ideal_bridges_lib`) have integrated
  passives that are on by default: 0.5 mH in series with each AC terminal of a full bridge, 1 mH per phase of a
  three-phase bridge and 2 mF on the DC side of each bridge, on top of the filters, DC links and transformer
  of the model. They are off in the four bridges (`cap_dc`, `ind_ac`).
- **Phase shift of the DAB beyond the top of the power curve.** The DC-link voltage PI of the DAB
  (`dab_ctrl/u_out_ctrl`) gives the phase shift between the bridges directly (the current PI `i_out_ctrl` is
  commented out, also in main), in units of the `max_phase_displacement` of the modulator (pi/2), but its
  output was limited to +-2: the phase shift could reach +-pi, past the maximum of the power at pi/2, where
  the loop gain changes sign. During the dip of the default test the PI wound up to its limit and the power of
  the DAB fell almost to zero, with the DC link at half its voltage. The limit is now
  `param.dab.ctrl.phase_lim` = 1.
- **Start-up.** The Simscape Solver Configuration no longer starts from a steady state, which brought the
  battery to SOC 0 (764 V) through the off-state leakage of the bridges. The battery and the DC capacitor of
  DAB side 1 start at the open-circuit voltage of the pack at the initial state of charge
  (`param.battery.voltage_init_1`, about 1248 V at SOC 0.85); the DC link starts discharged and is charged
  through the diodes of the SAF bridge.
- **Without the storage** the DC-link voltage PI of the SAF (`saf_ctrl/udc_ctrl`, commented out in main and
  removed in dev) is back and gives the active current reference; with the storage the switch
  `saf_ctrl/i_xi_ref/storage_switch` takes `param.saf.ref.ixi_ref` (zero during the power limitation of the
  FRT). The DC-link PI stays active during the power limitation (the block of main zeroed and reset it):
  without the storage the SAF is the only source of the power that the VS takes during a dip.
- **VS load voltage.** The load voltage sequences of the VS read `ugd_abc_pu`, a tag of the SAF that the VS
  cannot see; they read `ugd_abc_load_pu`.
- **Blocks removed for the Home licence** (in dev) and their readers: the IEC power meter of the grid (about
  300 nonvirtual blocks: P1p, Q1p, P1n, Q1n are computed after the simulation by `iec_power_meter.m`), the
  instantaneous power of SAF and VS (about 80 each), the thermal models of the devices (and the logging of the
  DAB devices). The logging buses of SAF and VS were rebuilt with the signals that exist, the modulators take
  `u_abg` as a vector, the clock of the DAB has no time alignment (zero correction).
- **Names.** Block labels with `saf`, `vs`, `dab`; tags, To Workspace variables and block parameters on the
  names of the new init (tables below). The model configuration reads `param.sim.simlength` and
  `param.glb_time.tc`.

Blocks:

| dev / main | now |
|---|---|
| `left_shunt_universal_power_quality_compensator` | `upqc` |
| `.../shunt_active_filter`, `.../voltage_stabiliser` | `upqc/saf`, `upqc/vs` |
| `saf/saf_control/saf_control`, `.../saf_control/saf_control/saf_control` | `saf/saf_control/saf_isr`, `saf_isr/saf_ctrl` |
| `vs/VS_control`, `VS_control/vs_control`, `.../vs_control/vs_control` | `vs/vs_control`, `vs_control/vs_isr`, `vs_isr/vs_ctrl` |
| `vs/inverter`, `vs/LCL_filter` | `vs/vs_inverter`, `vs/vs_lcl_filter` |
| `vs_ctrl/grid_voltage_sequences`, `vs_ctrl/voltage_stabiliser` | `vs_ctrl/load_voltage_sequences`, `vs_ctrl/load_voltage_ctrl` |
| `phase_compensation_1`, `alignment_eval_afe1`, `AFE1_local_time_corr` | `time_alignment`, `alignment_eval`, `local_time_corr` |
| `ig/is/ug afe quantizzation and one step delay` | `ig_acquisition`, `is_acquisition`, `ug_acquisition` (VS: `ug_load_acquisition`, `ug_line_acquisition`), each with `quantization_and_delay` |
| `data_to_worspace_module_1`, `interesting scopes` | `data_to_workspace`, `scopes` |
| `dab_mod1`, `battery_1`, `battery_1/litium_ion_battery` | `dab`, `battery`, `battery/lithium_ion_battery` |
| `series_three_phase_transformer`, `load_ui_measures` | `series_transformer`, `load_measures` |
| `ls_upqc_measurement_sim` and its `shunt_active_filter_quantities`, `voltage_stabiliser_quantities`, `DAB_quantities` | `measurements` with `saf_quantities`, `vs_quantities`, `dab_quantities` |
| `global timing` with `time_afe1/2/3` | `global_timing` with `time_saf`, `time_vs`, `time_dab` |
| `grid_emulator/three_phase_voltage_source_with_frt_emulator1`, `grid_emulator/3ph_Dyg_ssc` | `grid_emulator/voltage_source_with_frt`, `grid_emulator/grid_transformer` |
| `three_phase_rl_load`, `scope` | `rl_load`, `scopes` |

Tags and logged variables:

| dev / main | now |
|---|---|
| `u_abc_line`, `i_abc_line`, `gamma_grid_emulator` | `ug_abc`, `ig_abc`, `phase_grid_emulator` |
| `all_voltages_about_dclink_mod1`, `udcd_pu_afe`, `iz_afe_pu_saf` | `all_voltages_about_dclink_saf`, `udcd_pu`, `iz_pu_saf` |
| `v_grid_pos/neg_xi/eta_avg` (VS) | `v_load_pos/neg_xi/eta_avg` |
| `time_dab_module_1`, `TRGO_DAB_1`, `single_phase_transformer_data_mod1` | `time_dab`, `TRGO_dab`, `dab_transformer_data` |
| `current_battery_1`, `voltage_battery_1` | `current_battery`, `voltage_battery` |
| DAB tags `*_mod1` (`d1m_dab_mod1`, `phase_disp_dab_mod1`, `dab_voltage_output_mod1`, `CFi_dc1_current_mod1`, ...) | without `_mod1` (`CFi_dc1/2_current_dab`) |
| `*_mod1_sim`, `CFi_dc1/2_current_mod1_sim` | `*_sim`, `CFi_dc1/2_current_dab_sim` |
| `udc_pu_sim_mod1`, `udc_pu_ref_sim_mod1` | `udc_pu_saf_sim`, `udc_pu_ref_saf_sim` |

Workspace names of the legacy init:

| legacy init | `param` |
|---|---|
| `glb_time`, `simlength` | `param.glb_time`, `param.sim.simlength` |
| `hwdata.afe` (one data set for both converters), `hwdata.dab` | `param.saf.hw`, `param.vs.hw`, `param.dab.hw` |
| `afe_ctrl` | `param.saf.ctrl`, `param.vs.ctrl` |
| `grid_emu` | `param.grid.emu` (bases `ugrid_bez`, `igrid_bez`: `param.saf.hw.ubez`, `ibez`) |
| `upqc_st`, `upqc_ctrl` | `param.vs.st`, `param.vs.ctrl` |
| `dab_ctrl`, `lithium_ion_battery_1` | `param.dab.ctrl`, `param.battery.pack_1` |
| `ixi_ref_mod1`, `u_cm_comp_mod1/2` | `param.saf.ref.ixi_ref`, `param.saf.ref.u_cm_comp`, `param.vs.ref.u_cm_comp` |
| `afe_pwm_phase_shift_mod1/2`, `time_gain_afe_module_1/2` | `param.saf/vs.behav.pwm_phase_shift`, `param.saf/vs.behav.time_gain` |
| `kp_align`, `ki_align`, `lim_up/down_align`, `adc_quantization` | `param.ctrl.*`, `param.meas.adc_quantization` |

## Notes and open points

- **Ratings of the VS and of the series transformer.** With the default load the VS carries 654 A rms, 2.8
  times the rated current of its 250 kW data set, and the 690 V windings of the series transformer 380 A
  against their 181 A. The ideal switches do not mind; a smaller load or a series transformer rated for the
  load current would make the currents realistic.
- **Deep dip without the storage.** Test 25.4 is beyond what the SAF can do alone (see above): use a milder
  test (75.x), a smaller load or a higher current limit of the SAF.
- **DAB.** The current PI is commented out (as in main), so the battery current is neither controlled nor
  limited; the transformer has no series capacitor (the data set computes one, `param.dab.hw.Cs`), so nothing
  blocks a DC component of its current.
- **No protection** of the DC link (undervoltage) and of the bridge currents: without the storage the SAF
  current reaches 4.4 kA peak after the fault.
- **Start-up without precharge:** the DC link is charged through the diodes of the SAF, 2.2 kA peak in the
  first period.
- **Battery:** 50 Ah (the value of the legacy init), charged at about 3 C in normal operation; RC branch with
  a time constant of 0.72 ms (R0, R1 halved and C1 divided by 50 as in the legacy init).
- **DAB step:** `ts_dab/tc` = 66.7 is not an integer.
- **FRT block of the library:** `frt_vde4110` releases the power limitation when the negative sequence is below
  0.7 pu, probably a slip for 0.1 pu minus the hysteresis; no effect with test 25.4.
- **Scripts:** `video_plot_sim.m` and two scripts of `video_plots/` read results files and time windows of
  longer simulations of the legacy init: set them for the results at hand.
- **Migration script:** `migration/ls_upqc_migrate.m` runs on the model of dev before the migration; a
  change to a newer dev model must be made on the migrated model by hand (or the script adapted).

## Files

| File | Content |
|---|---|
| `init_model.m` | initialization (live script in plain-text format) |
| `ls_upqc.slx` | the model |
| `ls_upqc_private.m`, `private/` | handles to the local functions of the init and the functions |
| `plot_sim.m` | figures of a simulation (eps, `./figures`) |
| `video_plot_sim.m`, `video_plots/` | MP4 animations (dark theme): grid and load quantities, SAF and VS, DC link and grid powers, DAB |
| `iec_power_meter.m` | fundamental positive- and negative-sequence powers from logged waveforms (sliding one-period DFT, IEC 61000-4-30) |
| `results_compat.m` | names of this init for the results of the legacy init |
| `non_virtual_blocks_counting.m` | count of the nonvirtual blocks (Home licence) |
| `init_model_legacy.m` | the legacy init, for reference: it no longer runs with the library |
| `plot_spectrum.m` | spectrum of the grid phase voltage over the 10 periods before the fault (harmonics 2 to 17, eps) |
| `migration/ls_upqc_migrate.m` | the changes of November 2026 to `ls_upqc.slx`, as the script that made them (already applied) |
