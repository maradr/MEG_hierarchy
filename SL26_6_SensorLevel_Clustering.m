%% Clustering
% Run Non Parametric Cluster Permutation Test to asses the presence of a
% response in the frequency of interest at sensor level.

% M. De Rosa
% SL26 - SISSA+CIMeC Entrainment to regularities, Jan 2021

clear all; close all; clc;
SetPaths;
%
%% Upload files and sensor coordinates
%
files = dir([freq_dir 'grand_average_condition*.mat']);
for i = 1:length(files)
    load(files(i).name);
end
%
load grad % general coordinates
load grad_cmb % coordinates for combined gradiometers

%% Set parameters

condition_code1         = 1;            % 1 - 10
condition_code2         = 6;            % 0 - 10
freq_of_interest        = 'odd';        % 'odd 'or 'base
sensor_type             = 'meggrad';    % 'meggrad' or 'megmag'
har = 1;

%% Compute empirical frequency based on refresh rates

cfg = [];
cfg.refresh_rate = 120;
cfg.nominal_base_frequency = 6;
cfg.directory = behav_dir;
[true_base_frequency, true_oddball_frequency] = SSEP_compute_exact_frequency(cfg);


eval(['dataset_1 = grand_average_condition' num2str(condition_code1) ';']);

if condition_code2 ~= 0
    eval(['dataset_2 = grand_average_condition' num2str(condition_code2) ';'])
else
    eval(['dataset_2 = grand_average_condition' num2str(condition_code1) ';']);
    dataset_2.BC = zeros(size(dataset_1.BC));
end


%% Subset data according to the parameters (frequency, sensors)

cfg = [];
if strcmpi(freq_of_interest, 'odd')
    cfg.frequency = true_oddball_frequency*har;
elseif strcmpi(freq_of_interest,'base')
    cfg.frequency=true_base_frequency;
end
cfg.channel = sensor_type;

dataset_1 = ft_selectdata(cfg, dataset_1);
dataset_2 = ft_selectdata(cfg, dataset_2);

%% Combine gradiometers (depending on sensor type)

if strcmpi(sensor_type, 'meggrad')
    dataset_1 = SL26_combineplanarAVG(dataset_1);
    dataset_2 = SL26_combineplanarAVG(dataset_2);
end

%% Select neighbours

cfg               = [];
cfg.method        = 'distance';
cfg.neighbourdist = 6;
cfg.grad          = grad_cmb;
if strcmpi(sensor_type, 'megmag'); cfg.grad = grad; end

neighbours = ft_prepare_neighbours(cfg, dataset_1);


%% Cluster permutation

cfg                  = [];
cfg.method           = 'montecarlo';
cfg.statistic        = 'depsamplesT';
cfg.correctm         = 'cluster';
cfg.clusteralpha     = 0.05;
cfg.clusterstatistic = 'maxsum';
cfg.minnbchan        = 2;          % minimum number of neighborhood channels for a selected sample to be included (default=0).
cfg.neighbours       = neighbours;
cfg.tail             = 1;
cfg.clustertail      = 1;
cfg.alpha            = 0.05;      % alpha level of the permutation test
cfg.numrandomization = 5000;
%if strcmpi(sensor_type, 'megmag');  cfg.channel = 'meggrad'; cfg.grad = grad; end
cfg.parameter      =  'BC';
design_matrix = [ones(1,size(dataset_1.BC,1)), 2*ones(1,size(dataset_1.BC,1)); 1:size(dataset_1.BC,1), 1:size(dataset_1.BC,1)];
cfg.design = design_matrix;
cfg.ivar = 1;
cfg.uvar=2;


[stat] = ft_freqstatistics(cfg, dataset_1, dataset_2);



%% Assess results
if isfield(stat, 'posclusters')
    for cluster = 1:length(stat.posclusters) % Cluster to check
        
        P             = stat.posclusters(cluster).prob;
        clusterlabels = stat.posclusterslabelmat;
        clust         = clusterlabels == cluster;
        elec          = find(sum(clust,2));
        
        C1            = squeeze(dataset_1.BC(:,elec))';
        C2            = squeeze(dataset_2.BC(:,elec))';
        % % Requires the Measures of Effect Size Toolbox (Hentschke, 2011)
        if condition_code2 ~= 0
            effect_size = mes(C1,C2,'hedgesg');
        else
            effect_size = mes(C1,0,'hedgesg');
        end
        stat.posclusters(cluster).effect_size = effect_size;
        
        df             = size(dataset_1.BC,1) - 1;
        tstat          = stat.posclusters(cluster).clusterstat;
        p              = stat.posclusters(cluster).prob;
        es             = mean(stat.posclusters(cluster).effect_size.hedgesg);
        ci             = mean(stat.posclusters(cluster).effect_size.hedgesgCi,2)';
        
        s = [cluster, condition_code1, condition_code2, df, tstat, p, es, ci];
        
        
        fprintf('Cluster %.f for condition %.f vs %.f: t(%.f) = %.2f, p = %.3g, Hedge''s g = %.2f [%.2f, %.2f])\n',s);
        
    end
    
    cfg                    = [];
    cfg.alpha              = 0.05;
    cfg.parameter          = 'stat';
    cfg.layout             = 'neuromag306cmb.lay';
    if strcmpi(sensor_type, 'megmag') cfg.layout  = 'neuromag306mag.lay'; end
    cfg.subplotsize        = [1 1];%layout of subplots ([h w], default [3 5])
    cfg.saveaspng          = ['Condition ' num2str(condition_code1) 'vs' num2str(condition_code2) '_' sensor_type];
    ft_clusterplot(cfg, stat);
end










