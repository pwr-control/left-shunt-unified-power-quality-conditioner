%PLOT_SPECTRUM  Spectrum of the grid phase voltage (phase a, the 10 grid periods before the first third of the
%   logging window: before the fault of the default test) of a simulation of ls_upqc.slx. Run it after the
%   simulation, or it loads sim_results_2.mat (save sim_results_2 after the simulation).
if ~exist('ug_abc_sim', 'var')
    load sim_results_2.mat;
end
results_compat;                         % names of init_model.m also for the results of the branch main
close all
clc

tratto1 = 2.2;
tratto2 = 2.2;
tratto3 = 1;
colore1 = [0.5 0.5 0.5];
colore2 = [0.8 0.8 0.8];

tc = param.glb_time.tc*param.glb_time.decimation_tc;
f_grid = param.grid.fgrid;
Nperiod = 10;
N2 = floor(numel(time_tc_sim)/3);
N1 = N2 - floor(Nperiod/f_grid/tc);
sig_fft=ug_abc_sim(N1:N2,1);
time = time_tc_sim(N1:N2);

ugrid_base = param.grid.us2*sqrt(2/3);  % [V] peak phase voltage

% figure; 
% plot(time,sig_fft,'-k','LineWidth',tratto1);
% title('Grid phase voltage used for FFT analysis','Interpreter','latex');
% ylabel('$u/V$','Interpreter','latex');
% xlabel('$t/s$','Interpreter','latex');
% set(gca,'xlim',[time(1) time(end)]);
% % set(gca,'ylim',[20 85]);
% grid on
% print('ugrid_fft_analysis','-depsc');

Nfft=length(sig_fft)+1;
u1=Nfft*tc;
f_sig=fft(sig_fft,Nfft);
Xrange=[f_sig(1)/Nfft f_sig(2:Nfft/2)'/(Nfft/2)];
freq=(0:1/u1:Nfft/2/u1-1/u1)';

n1 = 2; n2 = 11; n3 = 11; n4 = 17;
f1 = f_grid*0.9*n1; f2 = f_grid*1.1*n2;
f3 = f_grid*0.9*n3; f4 = f_grid*1.1*n4;

figure; 
subplot 211
plot(time,sig_fft,'-k','LineWidth',tratto1);
title(['Grid phase voltage used for FFT analysis during ' ...
    'normal operation'],'Interpreter','latex');
ylabel('$u/V$','Interpreter','latex');
xlabel('$t/s$','Interpreter','latex');
set(gca,'xlim',[time(1) time(end)]);
set(gca,'ylim',[-650 650]);
grid on
subplot 212
plot(freq,abs(Xrange)./ugrid_base*100,'-k','LineWidth',tratto1);
xlim([f1 f2]);
set(gca,'ylim',[0 4]);
grid;
xlabel('$Hz$','Interpreter','latex');
ylabel('$\%$','Interpreter','latex');
title(['Grid Phase Voltage Spectrum $2\le h \le 11$ during ' ...
    'normal operation'],'Interpreter','latex');
print('ugrid_spectrum_no_islanding','-depsc');

return

figure; 
subplot 211
plot(freq,abs(Xrange)./ugrid_base*100,'-k','LineWidth',tratto1);
xlim([f1 f2]);
set(gca,'ylim',[0 4]);
grid;
xlabel('$Hz$','Interpreter','latex');
ylabel('$\%$','Interpreter','latex');
title('Grid Phase Voltage Spectrum $2\le h \le 11$','Interpreter','latex');
subplot 212
plot(freq,abs(Xrange)./ugrid_base*100,'-k','LineWidth',tratto1);
xlim([f3 f4]);
set(gca,'ylim',[0 2]);
grid;
xlabel('$Hz$','Interpreter','latex');
ylabel('$\%$','Interpreter','latex');
title('Grid Phase Voltage Spectrum $11\le h \le 17$','Interpreter','latex');
print('ugrid_spectrum_no_islanding','-depsc');

return
n1 = 17; n2 = 23; n3 = 23; n4 = 35;
f1 = f_grid*0.9*n1; f2 = f_grid*1.1*n2;
f3 = f_grid*0.9*n3; f4 = f_grid*1.1*n4;
figure; 
subplot 211
plot(freq,abs(Xrange)./ugrid_base*100,'-k','LineWidth',tratto1);
xlim([f1 f2]);
set(gca,'ylim',[0 1.5]);
grid;
xlabel('$Hz$','Interpreter','latex');
ylabel('$\%$','Interpreter','latex');
title('Grid Phase Voltage Spectrum $17\le h \le 23$','Interpreter','latex');
subplot 212
plot(freq,abs(Xrange)./ugrid_base*100,'-k','LineWidth',tratto1);
xlim([f3 f4]);
set(gca,'ylim',[0 0.6]);
grid;
xlabel('$Hz$','Interpreter','latex');
ylabel('$\%$','Interpreter','latex');
title('Grid Phase Voltage Spectrum $23\le h \le 35$','Interpreter','latex');
print('ugrid_spectrum_s-ii','-depsc');

n1 = 35; n2 = 50; n3 = 50; n4 = 75;
f1 = f_grid*0.9*n1; f2 = f_grid*1.1*n2;
f3 = f_grid*0.9*n3; f4 = f_grid*1.1*n4;
figure; 
subplot 211
plot(freq,abs(Xrange)./ugrid_base*100,'-k','LineWidth',tratto1);
xlim([f1 f2]);
set(gca,'ylim',[0 0.3]);
grid;
xlabel('$Hz$','Interpreter','latex');
ylabel('$\%$','Interpreter','latex');
title('Grid Phase Voltage Spectrum $35\le h \le 50$','Interpreter','latex');
subplot 212
plot(freq,abs(Xrange)./ugrid_base*100,'-k','LineWidth',tratto1);
xlim([f3 f4]);
set(gca,'ylim',[0 1]);
grid;
xlabel('$Hz$','Interpreter','latex');
ylabel('$\%$','Interpreter','latex');
title('Grid Phase Voltage Spectrum $h \ge 50$','Interpreter','latex');
print('ugrid_spectrum_s-iii','-depsc');

u_spectrum = abs(Xrange);
Na = floor(f_grid*u1)+2;
Nb = length(u_spectrum)-1;
u_harmonics = u_spectrum(Na:Nb);
THDu = sqrt(sum(u_harmonics.^2))/ugrid_base*100
