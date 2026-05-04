

% load ..\sim_results_1.mat;

font_size_legend = 14;
font_size_labels = 16;
font_size_title = 14;

tc_eq = glb_time.tc*glb_time.decimation_tc;
tc = tc_eq;

t1 = 0.6;
t2 = 2.25;

% t1 = 1.0;
% t2 = 1.2;

N1 = floor(t1/tc);
N2 = floor(t2/tc);
N = N2-N1;

ugrid_u = ug_abc_sim(N1:N2,1);
ugrid_v = ug_abc_sim(N1:N2,2);
ugrid_w = ug_abc_sim(N1:N2,3);

uload_u = hwdata.afe.ubez * uload_abc_pu_sim(N1:N2,1);
uload_v = hwdata.afe.ubez * uload_abc_pu_sim(N1:N2,2);
uload_w = hwdata.afe.ubez * uload_abc_pu_sim(N1:N2,3);

igrid_u = ig_abc_sim(N1:N2,1);
igrid_v = ig_abc_sim(N1:N2,2);
igrid_w = ig_abc_sim(N1:N2,3);

iload_u = hwdata.afe.ibez * iload_abc_pu_sim(N1:N2,1);
iload_v = hwdata.afe.ibez * iload_abc_pu_sim(N1:N2,2);
iload_w = hwdata.afe.ibez * iload_abc_pu_sim(N1:N2,3);

time = time_tc_sim(N1:N2);

%% Parametri
sim_duration   = t2-t1;
video_duration = 6.0;
fps            = 30;
output_file    = 'video_plot_grid_load_1.mp4';

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
[yi_min, yi_max] = lim([igrid_u; igrid_v; igrid_w]);
[yv_min, yv_max] = lim([uload_u; uload_v; uload_w]);

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
hgrid_vu = plot(ax_v,NaN,NaN,'Color',col_u,'LineWidth',1.5);
hgrid_vv = plot(ax_v,NaN,NaN,'Color',col_v,'LineWidth',1.5);
hgrid_vw = plot(ax_v,NaN,NaN,'Color',col_w,'LineWidth',1.5);
hc_grid_v  = xline(ax_v,0,'r--','LineWidth',0.8,'Alpha',0.7);
legend(ax_v,{'v_{grid,u}','v_{grig,v}','v_{grid,w}'},'TextColor','w', ...
       'Color','none','EdgeColor',[0.4 0.4 0.4],'Location','northeast','FontSize',font_size_legend);
title(ax_v,'Grid Voltages','Color','w','FontSize',font_size_title,'FontWeight','normal');
ylabel(ax_v,'Voltage  [V]','Color','w','FontSize',font_size_labels);
xlim(ax_v,[t1,t2]); ylim(ax_v,[yv_min,yv_max]);
set(ax_v,'XTickLabel',{});
ht_grid_v = make_text(ax_v,'w');

ax_i = subplot(2,1,2,'Parent',fig_L);
setup_ax(ax_i);
hgrid_iu = plot(ax_i,NaN,NaN,'Color',col_u,'LineWidth',1.5);
hgrid_iv = plot(ax_i,NaN,NaN,'Color',col_v,'LineWidth',1.5);
hgrid_iw = plot(ax_i,NaN,NaN,'Color',col_w,'LineWidth',1.5);
hc_grid_i  = xline(ax_i,0,'r--','LineWidth',0.8,'Alpha',0.7);
legend(ax_i,{'i_{grid,u}','i_{grid,v}','i_{grid,w}'},'TextColor','w', ...
       'Color','none','EdgeColor',[0.4 0.4 0.4],'Location','northeast','FontSize',font_size_legend);
title(ax_i,'Grid Currents','Color','w','FontSize',font_size_title,'FontWeight','normal');
ylabel(ax_i,'Current  [A]','Color','w','FontSize',font_size_labels);
xlabel(ax_i,'Time  [s]','Color','w','FontSize',font_size_labels);
xlim(ax_i,[t1,t2]); ylim(ax_i,[yi_min,yi_max]);
ht_grid_i = make_text(ax_i,'w');

%% ---- Figura DESTRA: P1p P1n Q1p Q1n (2x2) ----
fig_R = figure('Color','k', 'Position',[50+W+10, 100, W, H], ...
               'MenuBar','none','ToolBar','none');

ax_v = subplot(2,1,1,'Parent',fig_R);
setup_ax(ax_v);
hload_vu = plot(ax_v,NaN,NaN,'Color',col_u,'LineWidth',1.5);
hload_vv = plot(ax_v,NaN,NaN,'Color',col_v,'LineWidth',1.5);
hload_vw = plot(ax_v,NaN,NaN,'Color',col_w,'LineWidth',1.5);
hc_load_v  = xline(ax_v,0,'r--','LineWidth',0.8,'Alpha',0.7);
legend(ax_v,{'v_{load,u}','v_{load,v}','v_{load,w}'},'TextColor','w', ...
       'Color','none','EdgeColor',[0.4 0.4 0.4],'Location','northeast','FontSize',font_size_legend);
title(ax_v,'Load Voltages','Color','w','FontSize',font_size_title,'FontWeight','normal');
ylabel(ax_v,'Voltage  [V]','Color','w','FontSize',font_size_labels);
xlim(ax_v,[t1,t2]); ylim(ax_v,[yv_min,yv_max]);
set(ax_v,'XTickLabel',{});
ht_load_v = make_text(ax_v,'w');

ax_i = subplot(2,1,2,'Parent',fig_R);
setup_ax(ax_i);
hload_iu = plot(ax_i,NaN,NaN,'Color',col_u,'LineWidth',1.5);
hload_iv = plot(ax_i,NaN,NaN,'Color',col_v,'LineWidth',1.5);
hload_iw = plot(ax_i,NaN,NaN,'Color',col_w,'LineWidth',1.5);
hc_load_i  = xline(ax_i,0,'r--','LineWidth',0.8,'Alpha',0.7);
legend(ax_i,{'i_{load,u}','i_{load,v}','i_{load,w}'},'TextColor','w', ...
       'Color','none','EdgeColor',[0.4 0.4 0.4],'Location','northeast','FontSize',font_size_legend);
title(ax_i,'Load Currents','Color','w','FontSize',font_size_title,'FontWeight','normal');
ylabel(ax_i,'Current  [A]','Color','w','FontSize',font_size_labels);
xlabel(ax_i,'Time  [s]','Color','w','FontSize',font_size_labels);
xlim(ax_i,[t1,t2]); ylim(ax_i,[yi_min,yi_max]);
ht_load_i = make_text(ax_i,'w');

%% ---- Render ----
fprintf('Rendering %d frames...  ', n_frames);
t_prog = tic;

for k = 1:n_frames
    t_now = (k/n_frames) * sim_duration;
    idx   = min(round(t_now/tc)+1, N);
    t_str = sprintf('t = %.4f s', time(idx));

    % --- aggiorna figura sinistra ---
    set(hgrid_vu,'XData',time(1:idx),'YData',ugrid_u(1:idx));
    set(hgrid_vv,'XData',time(1:idx),'YData',ugrid_v(1:idx));
    set(hgrid_vw,'XData',time(1:idx),'YData',ugrid_w(1:idx));
    set(hc_grid_v, 'Value',time(idx)); set(ht_grid_v,'String',t_str);

    set(hgrid_iu,'XData',time(1:idx),'YData',igrid_u(1:idx));
    set(hgrid_iv,'XData',time(1:idx),'YData',igrid_v(1:idx));
    set(hgrid_iw,'XData',time(1:idx),'YData',igrid_w(1:idx));
    set(hc_grid_i, 'Value',time(idx)); set(ht_grid_i,'String',t_str);

    % --- aggiorna figura destra ---
    set(hload_vu,'XData',time(1:idx),'YData',uload_u(1:idx));
    set(hload_vv,'XData',time(1:idx),'YData',uload_v(1:idx));
    set(hload_vw,'XData',time(1:idx),'YData',uload_w(1:idx));
    set(hc_load_v, 'Value',time(idx)); set(ht_load_v,'String',t_str);

    set(hload_iu,'XData',time(1:idx),'YData',iload_u(1:idx));
    set(hload_iv,'XData',time(1:idx),'YData',iload_v(1:idx));
    set(hload_iw,'XData',time(1:idx),'YData',iload_w(1:idx));
    set(hc_load_i, 'Value',time(idx)); set(ht_load_i,'String',t_str);

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