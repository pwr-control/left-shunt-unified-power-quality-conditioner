clc
clear
close all

load ..\sim_results_2.mat;

font_size_legend = 14;
font_size_labels = 16;
font_size_title = 14;

tc_eq = glb_time.tc*glb_time.decimation_tc;
tc = tc_eq;

t1 = 2.22;
t2 = 2.2202;

N1 = floor(t1/tc);
N2 = floor(t2/tc);
N = N2-N1;

u1_dab = u1_dab_transformer_mod1_sim(N1:N2);
u2_dab = u2_dab_transformer_mod1_sim(N1:N2);
i1_dab = i1_dab_transformer_mod1_sim(N1:N2);

uds_device = inverter_1_dab_devices_mod1_sim(N1:N2,2);
ugs_device = inverter_1_dab_devices_mod1_sim(N1:N2,25);
ids_device_Q1 = inverter_1_dab_devices_mod1_sim(N1:N2,3);
ids_device_Q2 = inverter_1_dab_devices_mod1_sim(N1:N2,8);

time = time_tc_sim(N1:N2);

%% Parametri
sim_duration   = t2-t1;
video_duration = 6.0;
fps            = 30;
output_file    = 'video_plot_dab_advanced_1.mp4';

%% Colori
col_u  = [0.25  0.72  1.00];
col_v  = [1.00  0.55  0.10];
col_w  = [0.20  0.85  0.45];
col_P1p = [1.00  0.85  0.20];
col_P1n = [1.00  0.45  0.20];
col_Q1p = [0.75  0.30  1.00];
col_Q1n = [0.30  0.85  0.85];

%% Limiti assi (precalcolati)
lim = @(x) deal(min(x)*1.2, max(x)*1.2);
[yi_min, yi_max] = lim(i1_dab);
[yv_min, yv_max] = lim(u1_dab);

fix = @(a,b) deal(a-(a==b), b+(a==b));
[yi_min,   yi_max  ] = fix(yi_min,   yi_max  );
[yv_min,   yv_max  ] = fix(yv_min,   yv_max  );

n_frames = round(fps * video_duration);

%% Video writer
vw = VideoWriter(output_file, 'MPEG-4');
vw.FrameRate = fps;
vw.Quality   = 95;
open(vw);

%% ---- Figura Sinistra ----
W = 900;  H = 720;          % dimensioni di ciascuna finestra
fig_L = figure('Color','k', 'Position',[50,  100, W, H], ...
               'MenuBar','none','ToolBar','none');

ax_v = subplot(2,1,1,'Parent',fig_L);
setup_ax(ax_v);
hl_u1_dab = plot(ax_v,NaN,NaN,'Color',col_u,'LineWidth',3);
hl_u2_dab = plot(ax_v,NaN,NaN,'Color',col_v,'LineWidth',3);
hlc_v  = xline(ax_v,0,'r--','LineWidth',0.8,'Alpha',0.7);
legend(ax_v,{'u_{dab,ac1}','u_{dab,ac2}'},'TextColor','w', ...
       'Color','none','EdgeColor',[0.4 0.4 0.4],'Location','northeast','FontSize',font_size_legend);
title(ax_v,'DAB AC Voltages - During Battery Charging','Color','w','FontSize',font_size_title,'FontWeight','normal');
ylabel(ax_v,'Voltage  [V]','Color','w','FontSize',font_size_labels);
xlim(ax_v,[t1,t2]); ylim(ax_v,[yv_min,yv_max]);
set(ax_v,'XTickLabel',{});
hlt_v = make_text(ax_v,'w');

ax_i = subplot(2,1,2,'Parent',fig_L);
setup_ax(ax_i);
hl_i1_dab = plot(ax_i,NaN,NaN,'Color',col_u,'LineWidth',3);
hlc_i  = xline(ax_i,0,'r--','LineWidth',0.8,'Alpha',0.7);
legend(ax_i,{'i_{dab,ac}'},'TextColor','w', ...
       'Color','none','EdgeColor',[0.4 0.4 0.4],'Location','northeast','FontSize',font_size_legend);
title(ax_i,'DAB AC Current - During Battery Charging','Color','w','FontSize',font_size_title,'FontWeight','normal');
ylabel(ax_i,'Current  [A]','Color','w','FontSize',font_size_labels);
xlabel(ax_i,'Time  [s]','Color','w','FontSize',font_size_labels);
xlim(ax_i,[t1,t2]); ylim(ax_i,[yi_min,yi_max]);
hlt_i = make_text(ax_i,'w');

%% ---- Figura Destra ----
fig_R = figure('Color','k', 'Position',[50+W+10, 100, W, H], ...
               'MenuBar','none','ToolBar','none');

ax_v1 = subplot(3,1,1,'Parent',fig_R);
setup_ax(ax_v1);
hr_uds_dab = plot(ax_v1,NaN,NaN,'Color',col_u,'LineWidth',3);
hrc_v1  = xline(ax_v1,0,'r--','LineWidth',0.8,'Alpha',0.7);
legend(ax_v1,{'u_{Q1,ds}'},'TextColor','w', ...
    'Color','none','EdgeColor',[0.4 0.4 0.4],'Location','northeast','FontSize',font_size_legend);
title(ax_v1,'DAB Q1 - Uds Voltage - During Battery Charging','Color','w','FontSize',font_size_title,'FontWeight','normal');
ylabel(ax_v1,'Voltage  [V]','Color','w','FontSize',font_size_labels);
xlim(ax_v1,[t1,t2]); ylim(ax_v1,[-100,1500]);
set(ax_v1,'XTickLabel',{});
hrt_v1 = make_text(ax_v1,'w');

ax_v2 = subplot(3,1,2,'Parent',fig_R);
setup_ax(ax_v2);
hr_ugs_dab = plot(ax_v2,NaN,NaN,'Color',col_u,'LineWidth',3);
hrc_v2  = xline(ax_v2,0,'r--','LineWidth',0.8,'Alpha',0.7);
legend(ax_v2,{'u_{Q1,gs}'},'TextColor','w', ...
    'Color','none','EdgeColor',[0.4 0.4 0.4],'Location','northeast','FontSize',font_size_legend);
title(ax_v2,'DAB Q1 - Ugs Voltage - During Battery Charging','Color','w','FontSize',font_size_title,'FontWeight','normal');
ylabel(ax_v2,'Voltage  [V]','Color','w','FontSize',font_size_labels);
xlim(ax_v2,[t1,t2]); ylim(ax_v2,[-10, 25]);
set(ax_v2,'XTickLabel',{});
hrt_v2 = make_text(ax_v2,'w');

ax_i = subplot(3,1,3,'Parent',fig_R);
setup_ax(ax_i);
hr_ids_dab_Q1 = plot(ax_i,NaN,NaN,'Color',col_u,'LineWidth',3);
hr_ids_dab_Q2 = plot(ax_i,NaN,NaN,'Color',col_v,'LineWidth',3);
hrc_i  = xline(ax_i,0,'r--','LineWidth',0.8,'Alpha',0.7);
legend(ax_i,{'i_{Q1,ds}','i_{Q2,ds}'},'TextColor','w', ...
    'Color','none','EdgeColor',[0.4 0.4 0.4],'Location','northeast','FontSize',font_size_legend);
title(ax_i,'DAB Q1, Q2 - Ids Current - During Battery Charging','Color','w','FontSize',font_size_title,'FontWeight','normal');
ylabel(ax_i,'Current  [A]','Color','w','FontSize',font_size_labels);
xlabel(ax_i,'Time  [s]','Color','w','FontSize',font_size_labels);
xlim(ax_i,[t1,t2]); ylim(ax_i,[yi_min,yi_max]);
hrt_i = make_text(ax_i,'w');

%% ---- Render ----
fprintf('Rendering %d frames...  ', n_frames);
t_prog = tic;

for k = 1:n_frames
    t_now = (k/n_frames) * sim_duration;
    idx   = min(round(t_now/tc)+1, N);
    t_str = sprintf('t = %.4f s', time(idx));

    % --- aggiorna figura sinistra ---
    set(hl_u1_dab,'XData',time(1:idx),'YData',u1_dab(1:idx));
    set(hl_u2_dab,'XData',time(1:idx),'YData',u2_dab(1:idx));
    set(hlc_v, 'Value',time(idx)); set(hlt_v,'String',t_str);

    set(hl_i1_dab,'XData',time(1:idx),'YData',i1_dab(1:idx));
    set(hlc_i, 'Value',time(idx)); set(hlt_i,'String',t_str);

    % --- aggiorna figura destra ---
    set(hr_uds_dab,'XData',time(1:idx),'YData',uds_device(1:idx));
    set(hr_ugs_dab,'XData',time(1:idx),'YData',ugs_device(1:idx));
    set(hrc_v1, 'Value',time(idx)); set(hrt_v1,'String',t_str);
    set(hrc_v2, 'Value',time(idx)); set(hrt_v2,'String',t_str);

    set(hr_ids_dab_Q1,'XData',time(1:idx),'YData',ids_device_Q1(1:idx));
    set(hr_ids_dab_Q2,'XData',time(1:idx),'YData',ids_device_Q2(1:idx));
    set(hrc_i, 'Value',time(idx)); set(hrt_i,'String',t_str);

    % --- cattura e affianca i due frame ---
    fr_L = getframe(fig_L);
    fr_R = getframe(fig_R);

    % Ridimensiona alla stessa altezza se necessario
    hL = size(fr_L.cdata,1);
    hR = size(fr_R.cdata,1);
    if hL ~= hR
        fr_R.cdata = imresize(fr_R.cdata, [hL, size(fr_R.cdata,2)]);
    end

    combined = [fr_L.cdata, fr_R.cdata];   % affianca orizzontalmente
    writeVideo(vw, combined);

    if mod(k, round(n_frames/20)) == 0
        fprintf('%.0f%%  ', 100*k/n_frames);
    end
end

fprintf('\nDone in %.1f s\n', toc(t_prog));
close(vw);
close(fig_L); close(fig_R);
fprintf('Video salvato: %s\n', output_file);

%% ---- Funzioni locali ----
function setup_ax(ax)
    set(ax, 'Color','k','XColor','w','YColor','w', ...
            'GridColor','w','GridAlpha',0.15, ...
            'XGrid','on','YGrid','on','FontSize',12);
    hold(ax,'on');
end

function h = make_text(ax, col)
    h = text(ax, 0.02, 0.93, '', ...
             'Units','normalized','Color',col, ...
             'FontSize',12,'FontName','Consolas', ...
             'VerticalAlignment','top');
end