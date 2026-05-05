clear;
close all;
clc;

tratto1 = 2;
tratto2 = 2;
tratto3 = 4;
colore1 = [0.25 0.25 0.25];
colore2 = [0.50 0.50 0.50];
colore3 = [0.75 0.75 0.75];

fontsize_title = 14;
fontsize_legend = 16;
fontsize_axis = 12;

load sim_results_2.mat;
tc_eq = glb_time.tc*glb_time.decimation_tc;
tc = tc_eq;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% figure 1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
t1 = 0.6;
t2 = 2.0;
N1 = floor(t1/tc);
N2 = floor(t2/tc);
N = N2-N1;

ugrid_u = ug_abc_sim(N1:N2,1);
ugrid_v = ug_abc_sim(N1:N2,2);
ugrid_w = ug_abc_sim(N1:N2,3);

uload_u = hwdata.afe.ubez * uload_abc_pu_sim(N1:N2,1);
uload_v = hwdata.afe.ubez * uload_abc_pu_sim(N1:N2,2);
uload_w = hwdata.afe.ubez * uload_abc_pu_sim(N1:N2,3);

time = time_tc_sim(N1:N2);

figure(1);
subplot 211
plot(time,ugrid_u,'-','LineWidth',tratto2,'Color',colore1);
hold on
plot(time,ugrid_v,'-','LineWidth',tratto2,'Color',colore2);
hold on
plot(time,ugrid_w,'-','LineWidth',tratto2,'Color',colore3);
hold off
title('Grid Voltages','Interpreter','latex','FontSize',fontsize_title);
legend('$u_{\mathrm{grid}}^{\mathrm{u}}$','$u_{\mathrm{grid}}^{\mathrm{v}}$',...
    '$u_{\mathrm{grid}}^{\mathrm{w}}$','Location','northeastoutside',...
    'Interpreter','latex','FontSize',fontsize_legend);
% xlabel('Time - [s]','Interpreter','latex','FontSize', fontsize_axis);
ylabel('Voltage - [V]','Interpreter','latex','FontSize', fontsize_axis);
set(gca,'ylim',[-750 750]);
set(gca,'xlim',[t1 t2]);
grid on
chH = get(gca,'Children');
set(gca,'Children',[chH(1); chH(2); chH(3)]);
subplot 212
plot(time,uload_u,'-','LineWidth',tratto2,'Color',colore1);
hold on
plot(time,uload_v,'-','LineWidth',tratto2,'Color',colore2);
hold on
plot(time,uload_w,'-','LineWidth',tratto2,'Color',colore3);
hold off
title('Load Voltages','Interpreter','latex','FontSize',fontsize_title);
legend('$u_{\mathrm{load}}^{\mathrm{u}}$','$u_{\mathrm{load}}^{\mathrm{v}}$',...
    '$u_{\mathrm{load}}^{\mathrm{w}}$','Location','northeastoutside',...
    'Interpreter','latex','FontSize',fontsize_legend);
xlabel('Time - [s]','Interpreter','latex','FontSize', fontsize_axis);
ylabel('Voltage - [V]','Interpreter','latex','FontSize', fontsize_axis);
set(gca,'ylim',[-750 750]);
set(gca,'xlim',[t1 t2]);
grid on
chH = get(gca,'Children');
set(gca,'Children',[chH(1); chH(2); chH(3)]);
grid on
h=gcf;
set(h,'PaperOrientation','landscape');
set(h,'PaperUnits','normalized');
set(h,'PaperPosition', [0 0 1 1]);
print('grid_load_voltages','-depsc');
movefile('grid_load_voltages.eps', 'figures');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% figure 2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

t1 = 0.6;
t2 = 2.0;
N1 = floor(t1/tc);
N2 = floor(t2/tc);
N = N2-N1;

igrid_u = ig_abc_sim(N1:N2,1);
igrid_v = ig_abc_sim(N1:N2,2);
igrid_w = ig_abc_sim(N1:N2,3);

iload_u = hwdata.afe.ibez * iload_abc_pu_sim(N1:N2,1);
iload_v = hwdata.afe.ibez * iload_abc_pu_sim(N1:N2,2);
iload_w = hwdata.afe.ibez * iload_abc_pu_sim(N1:N2,3);

time = time_tc_sim(N1:N2);

figure(2);
subplot 211
plot(time,igrid_u,'-','LineWidth',tratto2,'Color',colore1);
hold on
plot(time,igrid_v,'-','LineWidth',tratto2,'Color',colore2);
hold on
plot(time,igrid_w,'-','LineWidth',tratto2,'Color',colore3);
hold off
title('Grid Currents','Interpreter','latex','FontSize',fontsize_title);
legend('$i_{\mathrm{grid}}^{\mathrm{u}}$','$i_{\mathrm{grid}}^{\mathrm{v}}$',...
    '$i_{\mathrm{grid}}^{\mathrm{w}}$','Location','northeastoutside',...
    'Interpreter','latex','FontSize',fontsize_legend);
% xlabel('Time - [s]','Interpreter','latex','FontSize', fontsize_axis);
ylabel('Current - [A]','Interpreter','latex','FontSize', fontsize_axis);
set(gca,'ylim',[-1250 1250]);
set(gca,'xlim',[t1 t2]);
grid on
chH = get(gca,'Children');
set(gca,'Children',[chH(1); chH(2); chH(3)]);
subplot 212
plot(time,iload_u,'-','LineWidth',tratto2,'Color',colore1);
hold on
plot(time,iload_v,'-','LineWidth',tratto2,'Color',colore2);
hold on
plot(time,iload_w,'-','LineWidth',tratto2,'Color',colore3);
hold off
title('Load Currents','Interpreter','latex','FontSize',fontsize_title);
legend('$i_{\mathrm{load}}^{\mathrm{u}}$','$i_{\mathrm{load}}^{\mathrm{v}}$',...
    '$i_{\mathrm{load}}^{\mathrm{w}}$','Location','northeastoutside',...
    'Interpreter','latex','FontSize',fontsize_legend);
xlabel('Time - [s]','Interpreter','latex','FontSize', fontsize_axis);
ylabel('Current - [A]','Interpreter','latex','FontSize', fontsize_axis);
set(gca,'ylim',[-450 450]);
set(gca,'xlim',[t1 t2]);
grid on
chH = get(gca,'Children');
set(gca,'Children',[chH(1); chH(2); chH(3)]);
grid on
h=gcf;
set(h,'PaperOrientation','landscape');
set(h,'PaperUnits','normalized');
set(h,'PaperPosition', [0 0 1 1]);
print('grid_load_currents','-depsc');
movefile('grid_load_currents.eps', 'figures');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% figure 3
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

t1 = 0.6;
t2 = 2.0;
N1 = floor(t1/tc);
N2 = floor(t2/tc);
N = N2-N1;

u_vs_u = hwdata.afe.ubez * ug_abc_pu_vs_sim(N1:N2,1);
u_vs_v = hwdata.afe.ubez * ug_abc_pu_vs_sim(N1:N2,2);
u_vs_w = hwdata.afe.ubez * ug_abc_pu_vs_sim(N1:N2,3);

i_vs_u = hwdata.afe.ibez * ig_abc_pu_vs_sim(N1:N2,1);
i_vs_v = hwdata.afe.ibez * ig_abc_pu_vs_sim(N1:N2,2);
i_vs_w = hwdata.afe.ibez * ig_abc_pu_vs_sim(N1:N2,3);

time = time_tc_sim(N1:N2);

figure(3);
subplot 211
plot(time,u_vs_u,'-','LineWidth',tratto2,'Color',colore1);
hold on
plot(time,u_vs_v,'-','LineWidth',tratto2,'Color',colore2);
hold on
plot(time,u_vs_w,'-','LineWidth',tratto2,'Color',colore3);
hold off
title('VS - Voltages','Interpreter','latex','FontSize',fontsize_title);
legend('$u_{\mathrm{vs}}^{\mathrm{u}}$','$u_{\mathrm{vs}}^{\mathrm{v}}$',...
    '$u_{\mathrm{vs}}^{\mathrm{w}}$','Location','northeastoutside',...
    'Interpreter','latex','FontSize',fontsize_legend);
% xlabel('Time - [s]','Interpreter','latex','FontSize', fontsize_axis);
ylabel('Voltage - [V]','Interpreter','latex','FontSize', fontsize_axis);
set(gca,'ylim',[-850 850]);
set(gca,'xlim',[t1 t2]);
grid on
chH = get(gca,'Children');
set(gca,'Children',[chH(1); chH(2); chH(3)]);
subplot 212
plot(time,i_vs_u,'-','LineWidth',tratto2,'Color',colore1);
hold on
plot(time,i_vs_v,'-','LineWidth',tratto2,'Color',colore2);
hold on
plot(time,i_vs_w,'-','LineWidth',tratto2,'Color',colore3);
hold off
title('VS - Currents','Interpreter','latex','FontSize',fontsize_title);
legend('$i_{\mathrm{vs}}^{\mathrm{u}}$','$i_{\mathrm{vs}}^{\mathrm{v}}$',...
    '$i_{\mathrm{vs}}^{\mathrm{w}}$','Location','northeastoutside',...
    'Interpreter','latex','FontSize',fontsize_legend);
xlabel('Time - [s]','Interpreter','latex','FontSize', fontsize_axis);
ylabel('Current - [A]','Interpreter','latex','FontSize', fontsize_axis);
set(gca,'ylim',[-750 750]);
set(gca,'xlim',[t1 t2]);
grid on
chH = get(gca,'Children');
set(gca,'Children',[chH(1); chH(2); chH(3)]);
grid on
h=gcf;
set(h,'PaperOrientation','landscape');
set(h,'PaperUnits','normalized');
set(h,'PaperPosition', [0 0 1 1]);
print('vs_outputs','-depsc');
movefile('vs_outputs.eps', 'figures');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% figure 4
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

t1 = 0.6;
t2 = 2.0;
N1 = floor(t1/tc);
N2 = floor(t2/tc);
N = N2-N1;

ig_saf_u = hwdata.afe.ibez * ig_abc_pu_saf_sim(N1:N2,1);
ig_saf_v = hwdata.afe.ibez * ig_abc_pu_saf_sim(N1:N2,2);
ig_saf_w = hwdata.afe.ibez * ig_abc_pu_saf_sim(N1:N2,3);
vdc_saf = hwdata.afe.udc_nom * vdc_pu_saf_sim(N1:N2);
udc_battery = voltage_battery_sim(N1:N2);
idc_battery = current_battery_sim(N1:N2);

time = time_tc_sim(N1:N2);

figure(4);
subplot 311
plot(time,ig_saf_u,'-','LineWidth',tratto2,'Color',colore1);
hold on
plot(time,ig_saf_v,'-','LineWidth',tratto2,'Color',colore2);
hold on
plot(time,ig_saf_w,'-','LineWidth',tratto2,'Color',colore3);
hold off
title('SAF - Currents','Interpreter','latex','FontSize',fontsize_title);
legend('$i_{\mathrm{saf}}^{\mathrm{u}}$','$i_{\mathrm{saf}}^{\mathrm{v}}$',...
    '$i_{\mathrm{saf}}^{\mathrm{w}}$','Location','northeastoutside',...
    'Interpreter','latex','FontSize',fontsize_legend);
% xlabel('Time - [s]','Interpreter','latex','FontSize', fontsize_axis);
ylabel('Current - [A]','Interpreter','latex','FontSize', fontsize_axis);
set(gca,'ylim',[-1250 1250]);
set(gca,'xlim',[t1 t2]);
grid on
chH = get(gca,'Children');
set(gca,'Children',[chH(1); chH(2); chH(3)]);
subplot 312
plot(time,vdc_saf,'-','LineWidth',tratto2,'Color',colore1);
title('Udc SAF','Interpreter','latex','FontSize',fontsize_title);
legend('$u_{\mathrm{dc}}$','Location','northeastoutside',...
    'Interpreter','latex','FontSize',fontsize_legend);
xlabel('Time - [s]','Interpreter','latex','FontSize', fontsize_axis);
ylabel('Voltage - [V]','Interpreter','latex','FontSize', fontsize_axis);
set(gca,'ylim',[500 1650]);
set(gca,'xlim',[t1 t2]);
grid on
% chH = get(gca,'Children');
% set(gca,'Children',[chH(1); chH(2); chH(3)]);
grid on
subplot 313
plot(time,idc_battery,'-','LineWidth',tratto2,'Color',colore1);
title('Battery - Current','Interpreter','latex','FontSize',fontsize_title);
legend('$i_{\mathrm{dc}}$','Location','northeastoutside',...
    'Interpreter','latex','FontSize',fontsize_legend);
xlabel('Time - [s]','Interpreter','latex','FontSize', fontsize_axis);
ylabel('Current - [A]','Interpreter','latex','FontSize', fontsize_axis);
set(gca,'ylim',[-500 500]);
set(gca,'xlim',[t1 t2]);
grid on
% chH = get(gca,'Children');
% set(gca,'Children',[chH(1); chH(2); chH(3)]);
grid on
h=gcf;
set(h,'PaperOrientation','landscape');
set(h,'PaperUnits','normalized');
set(h,'PaperPosition', [0 0 1 1]);
print('saf_outputs','-depsc');
movefile('saf_outputs.eps', 'figures');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% figure 5
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

t1 = 2.22;
t2 = 2.2202;
N1 = floor(t1/tc);
N2 = floor(t2/tc);
N = N2-N1;

u1_dab = u1_dab_transformer_mod1_sim(N1:N2);
u2_dab = u2_dab_transformer_mod1_sim(N1:N2);
i1_dab = i1_dab_transformer_mod1_sim(N1:N2);

time = time_tc_sim(N1:N2);

figure(5);
subplot 211
plot(time,u1_dab,'-','LineWidth',tratto2,'Color',colore1);
hold on
plot(time,u2_dab,'-','LineWidth',tratto2,'Color',colore2);
hold off
title('DAB - AC Voltages','Interpreter','latex','FontSize',fontsize_title);
legend('$u_{\mathrm{dab}}^{\mathrm{ac1}}$','$u_{\mathrm{dab}}^{\mathrm{ac2}}$',...
    'Location','northeastoutside', 'Interpreter','latex','FontSize',fontsize_legend);
% xlabel('Time - [s]','Interpreter','latex','FontSize', fontsize_axis);
ylabel('Voltage - [V]','Interpreter','latex','FontSize', fontsize_axis);
set(gca,'ylim',[-1500 1500]);
set(gca,'xlim',[t1 t2]);
grid on
chH = get(gca,'Children');
set(gca,'Children',[chH(1); chH(2);]);
subplot 212
plot(time,i1_dab,'-','LineWidth',tratto2,'Color',colore1);
title('DAB AC Current','Interpreter','latex','FontSize',fontsize_title);
legend('$i_{\mathrm{dab}}^{\mathrm{ac1}}$','Location','northeastoutside',...
    'Interpreter','latex','FontSize',fontsize_legend);
xlabel('Time - [s]','Interpreter','latex','FontSize', fontsize_axis);
ylabel('Current - [A]','Interpreter','latex','FontSize', fontsize_axis);
set(gca,'ylim',[-500 500]);
set(gca,'xlim',[t1 t2]);
grid on
% chH = get(gca,'Children');
% set(gca,'Children',[chH(1); chH(2); chH(3)]);
grid on
h=gcf;
set(h,'PaperOrientation','landscape');
set(h,'PaperUnits','normalized');
set(h,'PaperPosition', [0 0 1 1]);
print('dab_inner_quantities','-depsc');
movefile('dab_inner_quantities.eps', 'figures');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% figure 6
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

t1 = 2.22;
t2 = 2.2202;
N1 = floor(t1/tc);
N2 = floor(t2/tc);
N = N2-N1;

uds_device = inverter_1_dab_devices_mod1_sim(N1:N2,2);
ugs_device = inverter_1_dab_devices_mod1_sim(N1:N2,25);
ids_device_Q1 = inverter_1_dab_devices_mod1_sim(N1:N2,3);
ids_device_Q2 = inverter_1_dab_devices_mod1_sim(N1:N2,8);
ploss_device = inverter_1_dab_devices_mod1_sim(N1:N2,1);

time = time_tc_sim(N1:N2);

figure(6);
subplot 311
plot(time,uds_device,'-','LineWidth',tratto2,'Color',colore1);
title('DAB -  Q1-Uds Device Voltage','Interpreter','latex','FontSize',fontsize_title);
legend('$u_{\mathrm{ds}}^{\mathrm{Q1}}$', 'Location','northeastoutside', ...
    'Interpreter','latex','FontSize',fontsize_legend);
% xlabel('Time - [s]','Interpreter','latex','FontSize', fontsize_axis);
ylabel('Voltage -[V]','Interpreter','latex','FontSize', fontsize_axis);
set(gca,'ylim',[-50 1500]);
set(gca,'xlim',[t1 t2]);
grid on
subplot 312
plot(time,ugs_device,'-','LineWidth',tratto2,'Color',colore1);
title('DAB - Q1-Ugs Device Voltage','Interpreter','latex','FontSize',fontsize_title);
legend('$u_{\mathrm{gs}}^{\mathrm{Q1}}$', 'Location','northeastoutside', ...
    'Interpreter','latex','FontSize',fontsize_legend);
% xlabel('Time - [s]','Interpreter','latex','FontSize', fontsize_axis);
ylabel('Voltage - [V]','Interpreter','latex','FontSize', fontsize_axis);
set(gca,'ylim',[-10 25]);
set(gca,'xlim',[t1 t2]);
grid on
% chH = get(gca,'Children');
% set(gca,'Children',[chH(1); chH(2);]);
subplot 313
plot(time,ids_device_Q1,'-','LineWidth',tratto2,'Color',colore1);
hold on
plot(time,ids_device_Q2,'-','LineWidth',tratto2,'Color',colore2);
hold off
title('DAB - Q1-Ids Device Current','Interpreter','latex','FontSize',fontsize_title);
legend('$i_{\mathrm{ds}}^{\mathrm{Q1}}$','$i_{\mathrm{ds}}^{\mathrm{Q2}}$','Location','northeastoutside',...
    'Interpreter','latex','FontSize',fontsize_legend);
xlabel('Time - [s]','Interpreter','latex','FontSize', fontsize_axis);
ylabel('Current - [A]','Interpreter','latex','FontSize', fontsize_axis);
set(gca,'ylim',[-500 500]);
set(gca,'xlim',[t1 t2]);
grid on
% chH = get(gca,'Children');
% set(gca,'Children',[chH(1); chH(2); chH(3)]);
grid on
h=gcf;
set(h,'PaperOrientation','landscape');
set(h,'PaperUnits','normalized');
set(h,'PaperPosition', [0 0 1 1]);
print('dab_devices_quantities','-depsc');
movefile('dab_devices_quantities.eps', 'figures');


