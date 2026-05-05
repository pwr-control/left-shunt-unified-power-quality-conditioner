

load ..\sim_results_2.mat;

font_size_legend = 14;
font_size_labels = 16;
font_size_title = 14;

tc_eq = glb_time.tc*glb_time.decimation_tc;
tc = tc_eq;

% t1 = 0.6;
% t2 = 2.25;

t1 = 1.0;
t2 = 1.2;

N1 = floor(t1/tc);
N2 = floor(t2/tc);
N = N2-N1;

u_saf_u = hwdata.afe.ubez * ug_abc_pu_saf_sim(N1:N2,1);
u_saf_v = hwdata.afe.ubez * ug_abc_pu_saf_sim(N1:N2,2);
u_saf_w = hwdata.afe.ubez * ug_abc_pu_saf_sim(N1:N2,3);

i_saf_u = hwdata.afe.ibez * ig_abc_pu_saf_sim(N1:N2,1);
i_saf_v = hwdata.afe.ibez * ig_abc_pu_saf_sim(N1:N2,2);
i_saf_w = hwdata.afe.ibez * ig_abc_pu_saf_sim(N1:N2,3);

u_vs_u = hwdata.afe.ubez * ug_abc_pu_vs_sim(N1:N2,1);
u_vs_v = hwdata.afe.ubez * ug_abc_pu_vs_sim(N1:N2,2);
u_vs_w = hwdata.afe.ubez * ug_abc_pu_vs_sim(N1:N2,3);

i_vs_u = hwdata.afe.ibez * ig_abc_pu_vs_sim(N1:N2,1);
i_vs_v = hwdata.afe.ibez * ig_abc_pu_vs_sim(N1:N2,2);
i_vs_w = hwdata.afe.ibez * ig_abc_pu_vs_sim(N1:N2,3);

time = time_tc_sim(N1:N2);

%% Parametri
sim_duration   = t2-t1;
video_duration = 6.0;
fps            = 30;
output_file    = 'video_plot_saf_vs_2.mp4';

%% Colori
col_u  = [0.25  0.72  1.00];
col_v  = [1.00  0.55  0.10];
col_w  = [0.20  0.85  0.45];
col_P1p = [1.00  0.85  0.20];
col_P1n = [1.00  0.45  0.20];
col_Q1p = [0.75  0.30  1.00];
col_Q1n = [0.30  0.85  0.85];

%% Limiti assi (precalcolati)
lim = @(x) deal(min(x)*1.15, max(x)*1.15);
[yi_min, yi_max] = lim([i_saf_u; i_saf_v; i_saf_w]);
[yv_min, yv_max] = lim([u_vs_u; u_vs_v; u_vs_w]);

fix = @(a,b) deal(a-(a==b), b+(a==b));
[yi_min,   yi_max  ] = fix(yi_min,   yi_max  );
[yv_min,   yv_max  ] = fix(yv_min,   yv_max  );

n_frames = round(fps * video_duration);

%% Video writer
vw = VideoWriter(output_file, 'MPEG-4');
vw.FrameRate = fps;
vw.Quality   = 95;
open(vw);

%% ---- Figura SINISTRA: tensioni + correnti ----
W = 900;  H = 720;          % dimensioni di ciascuna finestra
fig_L = figure('Color','k', 'Position',[50,  100, W, H], ...
               'MenuBar','none','ToolBar','none');

ax_v = subplot(2,1,1,'Parent',fig_L);
setup_ax(ax_v);
hsaf_vu = plot(ax_v,NaN,NaN,'Color',col_u,'LineWidth',2);
hsaf_vv = plot(ax_v,NaN,NaN,'Color',col_v,'LineWidth',2);
hsaf_vw = plot(ax_v,NaN,NaN,'Color',col_w,'LineWidth',2);
hc_saf_v  = xline(ax_v,0,'r--','LineWidth',0.8,'Alpha',0.7);
legend(ax_v,{'v_{saf,u}','v_{saf,v}','v_{saf,w}'},'TextColor','w', ...
       'Color','none','EdgeColor',[0.4 0.4 0.4],'Location','northeast','FontSize',font_size_legend);
title(ax_v,'SAF Voltages during Voltage Sag','Color','w','FontSize',font_size_title,'FontWeight','normal');
ylabel(ax_v,'Voltage  [V]','Color','w','FontSize',font_size_labels);
xlim(ax_v,[t1,t2]); ylim(ax_v,[yv_min,yv_max]);
set(ax_v,'XTickLabel',{});
ht_saf_v = make_text(ax_v,'w');

ax_i = subplot(2,1,2,'Parent',fig_L);
setup_ax(ax_i);
hsaf_iu = plot(ax_i,NaN,NaN,'Color',col_u,'LineWidth',2);
hsaf_iv = plot(ax_i,NaN,NaN,'Color',col_v,'LineWidth',2);
hsaf_iw = plot(ax_i,NaN,NaN,'Color',col_w,'LineWidth',2);
hc_saf_i  = xline(ax_i,0,'r--','LineWidth',0.8,'Alpha',0.7);
legend(ax_i,{'i_{saf,u}','i_{saf,v}','i_{saf,w}'},'TextColor','w', ...
       'Color','none','EdgeColor',[0.4 0.4 0.4],'Location','northeast','FontSize',font_size_legend);
title(ax_i,'SAF Currents during Voltage Sag','Color','w','FontSize',font_size_title,'FontWeight','normal');
ylabel(ax_i,'Current  [A]','Color','w','FontSize',font_size_labels);
xlabel(ax_i,'Time  [s]','Color','w','FontSize',font_size_labels);
xlim(ax_i,[t1,t2]); ylim(ax_i,[yi_min,yi_max]);
ht_saf_i = make_text(ax_i,'w');

%% ---- Figura DESTRA: P1p P1n Q1p Q1n (2x2) ----
fig_R = figure('Color','k', 'Position',[50+W+10, 100, W, H], ...
               'MenuBar','none','ToolBar','none');

ax_v = subplot(2,1,1,'Parent',fig_R);
setup_ax(ax_v);
hvs_vu = plot(ax_v,NaN,NaN,'Color',col_u,'LineWidth',2);
hvs_vv = plot(ax_v,NaN,NaN,'Color',col_v,'LineWidth',2);
hvs_vw = plot(ax_v,NaN,NaN,'Color',col_w,'LineWidth',2);
hc_vs_v  = xline(ax_v,0,'r--','LineWidth',0.8,'Alpha',0.7);
legend(ax_v,{'v_{vs,u}','v_{vs,v}','v_{vs,w}'},'TextColor','w', ...
       'Color','none','EdgeColor',[0.4 0.4 0.4],'Location','northeast','FontSize',font_size_legend);
title(ax_v,'VS Voltages during Voltage Sag','Color','w','FontSize',font_size_title,'FontWeight','normal');
ylabel(ax_v,'Voltage  [V]','Color','w','FontSize',font_size_labels);
xlim(ax_v,[t1,t2]); ylim(ax_v,[yv_min,yv_max]);
set(ax_v,'XTickLabel',{});
ht_vs_v = make_text(ax_v,'w');

ax_i = subplot(2,1,2,'Parent',fig_R);
setup_ax(ax_i);
hvs_iu = plot(ax_i,NaN,NaN,'Color',col_u,'LineWidth',2);
hvs_iv = plot(ax_i,NaN,NaN,'Color',col_v,'LineWidth',2);
hvs_iw = plot(ax_i,NaN,NaN,'Color',col_w,'LineWidth',2);
hc_vs_i  = xline(ax_i,0,'r--','LineWidth',0.8,'Alpha',0.7);
legend(ax_i,{'i_{vs,u}','i_{vs,v}','i_{vs,w}'},'TextColor','w', ...
       'Color','none','EdgeColor',[0.4 0.4 0.4],'Location','northeast','FontSize',font_size_legend);
title(ax_i,'VS Currents during Voltage Sag','Color','w','FontSize',font_size_title,'FontWeight','normal');
ylabel(ax_i,'Current  [A]','Color','w','FontSize',font_size_labels);
xlabel(ax_i,'Time  [s]','Color','w','FontSize',font_size_labels);
xlim(ax_i,[t1,t2]); ylim(ax_i,[yi_min,yi_max]);
ht_vs_i = make_text(ax_i,'w');

%% ---- Render ----
fprintf('Rendering %d frames...  ', n_frames);
t_prog = tic;

for k = 1:n_frames
    t_now = (k/n_frames) * sim_duration;
    idx   = min(round(t_now/tc)+1, N);
    t_str = sprintf('t = %.4f s', time(idx));

    % --- aggiorna figura sinistra ---
    set(hsaf_vu,'XData',time(1:idx),'YData',u_saf_u(1:idx));
    set(hsaf_vv,'XData',time(1:idx),'YData',u_saf_v(1:idx));
    set(hsaf_vw,'XData',time(1:idx),'YData',u_saf_w(1:idx));
    set(hc_saf_v, 'Value',time(idx)); set(ht_saf_v,'String',t_str);

    set(hsaf_iu,'XData',time(1:idx),'YData',i_saf_u(1:idx));
    set(hsaf_iv,'XData',time(1:idx),'YData',i_saf_v(1:idx));
    set(hsaf_iw,'XData',time(1:idx),'YData',i_saf_w(1:idx));
    set(hc_saf_i, 'Value',time(idx)); set(ht_saf_i,'String',t_str);

    % --- aggiorna figura destra ---
    set(hvs_vu,'XData',time(1:idx),'YData',u_vs_u(1:idx));
    set(hvs_vv,'XData',time(1:idx),'YData',u_vs_v(1:idx));
    set(hvs_vw,'XData',time(1:idx),'YData',u_vs_w(1:idx));
    set(hc_vs_v, 'Value',time(idx)); set(ht_vs_v,'String',t_str);

    set(hvs_iu,'XData',time(1:idx),'YData',i_vs_u(1:idx));
    set(hvs_iv,'XData',time(1:idx),'YData',i_vs_v(1:idx));
    set(hvs_iw,'XData',time(1:idx),'YData',i_vs_w(1:idx));
    set(hc_vs_i, 'Value',time(idx)); set(ht_vs_i,'String',t_str);

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