# left-shunt-unified-power-quality-conditioner

Study of a **Flipped Unified Power Quality Conditioner (F-UPQC)** — also called left-shunt
UPQC, after Akagi's classification of the shunt/series arrangement — for active distribution
networks: the shunt converter faces the grid and provides ancillary services to the DSO
(reactive power, harmonic mitigation, fault-ride-through behaviour), while the series
converter faces the load and stabilizes its voltage against sags and swells. A shared DC link
with a battery behind an isolated DC-DC converter makes the unit usable for local flexibility
services.

The repository contains the complete Simulink/Simscape bench of the system (`ls_upqc/`) and
the paper that derives topology, model and control (`doc/`).

## Prerequisites

- MATLAB with Simulink, Simscape and Simscape Electrical.
- The companion [library](https://github.com/pwr-control/library) repository on the MATLAB
  path **with subfolders**: the model uses its masked power stages (three-phase inverter
  with ideal switch / IGBT / MOSFET thermal models, full bridges, DAB modulator, DC link,
  lithium-ion battery, transformers, grid emulator with FRT, IEC power meter), the C-Caller
  control code (dq-PLL, current controllers, moving-average filters, double-integrator
  observer) and the setup functions called by `init_model.m` (`init_environment`,
  `timing_setup`, `*_hwdata`, `three_phase_transformer_setup`, `frt_settings`, ...).

## How to use

1. Run `ls_upqc/init_model.m`: it sets the global timing, the 690 V application data, the
   grid emulator, the FRT test case, the series transformer, the controllers, the device set
   and the battery, then opens `ls_upqc.slx`.
2. Simulate. Results are logged to the workspace (`*_sim` arrays) and can be saved as
   `sim_results*.mat` (ignored by git).
3. Post-process with `plot_sim.m` (EPS figures), `plot_spectrum.m` (grid-voltage spectra)
   and the scripts in `video_plots/` (MP4 animations).

## Repository layout

| Folder | Content |
|---|---|
| [`ls_upqc`](ls_upqc) | Simulink/Simscape model of the F-UPQC (shunt active filter, series voltage stabilizer, DC link with DAB and battery), init script, plotting, spectrum and video scripts |
| [`doc`](doc) | *A Flipped Unified Power Quality Conditioner for Active Distribution Networks: Topology, Modelling, and Control Strategy* — IEEE conference-format paper (LaTeX + PDF) |

Each folder has its own README.
