%% Source reconstruction analysis
% Run Non Parametric Cluster Permutation Test to asses the presence of a
% response in the frequency of interest at source level.

% M. De Rosa
% SL26 - SISSA+CIMeC Entrainment to regularities, June 2021

clear all; close all; clz

rng(110693)
for looping = 1:5
    %% Set
    which_condition_to_test = looping; % 1= NW in PF; 2 = PW in NW; 3 = HFE in PW; 4 = SUFF in HFE; 5 = W in SUFF
    
    SetPaths;
    cd(sources_dir)
    
    condition_code1         = which_condition_to_test;            % 1 - 5
    condition_code2         = which_condition_to_test +5;            % 0 - 6:10
    freq_of_interest        = 'odd';        % 'odd 'or 'base
    har = 1;%1:2:5;
    
    %% load files
    
    load(['C' num2str(condition_code1) '.mat']);
    eval(['C' num2str(condition_code1) '= BC;']);
    
    load(['C' num2str(condition_code2) '.mat']);
    eval(['C' num2str(condition_code2) '= BC;']);
    
        
    % ROIs and Neighbours
    load ROIs; load worldNeighbours
    
    
    %% Compute empirical oddball frequency based on refresh rate
    
    cfg = [];
    cfg.refresh_rate = 120; % bin width 0.361
    cfg.nominal_base_frequency = 6;
    cfg.directory = behav_dir;
    [true_base_frequency, true_oddball_frequency] = SSEP_compute_exact_frequency(cfg);
    
    fI = true_oddball_frequency*har';
    [~,odd_bin] = min(abs(repmat(Freqs,[length(fI),1]) - repmat(fI,[1,length(Freqs)])),[],2);
    
    %% set up file for fieldtrip
    
    vertices = [];
    for roi = 1:length(ROIs)
        vertices = [vertices ROIs(roi).iVertices];
    end
    
    eval(['temp = C' num2str(condition_code1) ';']);
    temp = temp(vertices,:,odd_bin);
    
    dataset_1.BC =  permute(temp,[2 1 3]); % sort dimensions
    dataset_1.freq = Freqs(odd_bin);
    dataset_1.label = cellstr(string(vertices));
    dataset_1.dimord = 'subj_chan_freq';
    clear temp
    
    eval(['temp = C' num2str(condition_code2) ';']);
    
    temp = temp(vertices,:,odd_bin);
    dataset_2.BC =  permute(temp,[2 1 3]); % sort dimensions
    dataset_2.freq = Freqs(odd_bin);
    dataset_2.label =cellstr(string(vertices));
    dataset_2.dimord = 'subj_chan_freq';
    clear temp
    
    
    %% Non-parametric cluster permutation test (Maris and Oostenvald)
    
    cfg                  = [];
    cfg.method           = 'montecarlo';
    cfg.statistic        = 'depsamplesT';
    cfg.correctm         = 'cluster';
    cfg.clusteralpha     = 0.05;
    cfg.clusterstatistic = 'maxsum';
    cfg.minnbchan        = 2;          % minimum number of neighborhood channels for a selected sample to be included (default=0).
    cfg.neighbours       = worldNeighbours;
    cfg.tail             = 1;
    cfg.clustertail      = 1;
    cfg.alpha            = 0.05;      % alpha level of the permutation test
    cfg.numrandomization = 1000;
    cfg.parameter      =  'BC';
    
    design_matrix = [ones(1,size(dataset_1.BC,1)), 2*ones(1,size(dataset_1.BC,1)); 1:size(dataset_1.BC,1), 1:size(dataset_1.BC,1)];
    cfg.design = design_matrix;
    cfg.ivar = 1;
    cfg.uvar=2;
    
    [stat] = ft_freqstatistics(cfg, dataset_1, dataset_2);
    
    if isfield(stat, 'posclusters')
        output_name = ['clustering_results_' num2str(condition_code1) 'vs' num2str(condition_code2) '.txt'];
        output_name_stats = ['clustering_results_stats_' num2str(condition_code1) 'vs' num2str(condition_code2)];
        fileID = fopen(output_name,'w');
        fprintf(fileID, 'Cluster permutation test conducted with neighbours within 6mm \n');
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
            fprintf( fileID, 'Cluster %.f for condition %.f vs %.f: t(%.f) = %.2f, p = %.3g, Hedge''s g = %.2f [%.2f, %.2f])\n',s);
            
            %save(fullfile(output_name_stats), 'stat')
        end
        fclose(fileID);
        
        
        
        
        for cluster = 1:length(stat.posclusters)
            
            p =  stat.posclusters(cluster).prob;
            clusterlabels = stat.posclusterslabelmat;
            clust = clusterlabels == cluster;
            elec  = find(sum(clust,2));
            branchname = ['clusterlabels_' num2str(cluster)];
            eval(['stat.clusterlabels.' branchname ' = elec'])
            
        end
    end
    save(fullfile(output_name_stats), 'stat')
    
    disp(['Done with condition ' num2str(looping)])
end

%% collect the vertices labels for significant clusters

for condition_code1 = 1:5

condition_code2 = condition_code1 + 5;
output_name_stats = ['clustering_results_stats_' num2str(condition_code1) 'vs' num2str(condition_code2)];
load(['D:\tegolino-derosa\_Experiments\SL26\MEG_Data\Sources\' output_name_stats '.mat'])
for cluster = 1:length(stat.posclusters)

    p =  stat.posclusters(cluster).prob;
    clusterlabels = stat.posclusterslabelmat;
    clust = clusterlabels == cluster;
    elec  = find(sum(clust,2));
    branchname = ['clusterlabels_' num2str(cluster)];
    eval(['stat.clusterlabels.' branchname ' = elec'])

end
 save(fullfile(output_name_stats), 'stat')
end