%% Run ICA
% First, run ICA on both Megmags and Meggrads (separately). Obtain
% components.
% Second, correlate components with ECG & EOG files, procede to inspect and
% reject clearly identifiable components.

% M. De Rosa
% SL26 - SISSA+CIMeC Entrainment to regularities, Jan 2021

%% 1. ICA, megmags and meggrads
clear all; close all; clc;
SetPaths
for i = 1:length(fif_folders)
    sbj_name = fif_folders(i);
    dirname  = strcat(preproc_dir,sbj_name.name);
    cd(dirname);
    
    % load data file
    sbj = dir('*_arrej.mat');
    load(sbj.name)
    
    % Separate megmag and meggrad
    cfg = [];
    cfg.channel = 'megmag';
    data_mag    = ft_selectdata(cfg,data_tot_arrej);
    cfg.channel = 'meggrad';
    data_grad   = ft_selectdata(cfg,data_tot_arrej);
    clear data_tot_arrej
    
    % Megmag
    cfg        = [];
    cfg.method = 'runica';
    comp_mag = ft_componentanalysis(cfg, data_mag);
    save comp_mag comp_mag
    clear data_mag comp_mag
    
    % Meggrad
    cfg        = [];
    cfg.method = 'runica';
    comp_grad = ft_componentanalysis(cfg, data_grad);
    save comp_grad comp_grad
    clear data_grad comp_grad
end


%% 2. Cleaning of components
clear all; close all;

SetPaths
cd(main_path)
load('grad.mat') % load coordinates to correct channel order 

for i = 1:length(fif_folders)
    %% Load material
    sbj_name = fif_folders(i);
    dirname  = strcat(preproc_dir,sbj_name.name);
    cd(dirname);
    
    sbj = dir('*_arrej.mat');
    load(sbj.name)
    cfg = [];
    cfg.channel = 'megmag';
    data_mag    = ft_selectdata(cfg,data_tot_arrej);
    cfg.channel = 'meggrad';
    data_grad   = ft_selectdata(cfg,data_tot_arrej);
    
    % Load ECG and EOG files
    ECG = dir('*_arrej_ECG.mat');
    load(ECG.name)
    EOG = dir('*_arrej_EOG.mat');
    load(EOG.name)
    
    % Load components resulting from part 1
    load comp_mag
    load comp_grad
    
    %% Megmags
    % plot the components for visual inspection
    figure
    cfg = [];
    cfg.component = 1:30; % check the first 30
    cfg.layout    = 'neuromag306mag.lay';
    cfg.comment   = 'no';
    ft_topoplotIC(cfg, comp_mag)
    
    cfg = [];
    cfg.layout = 'neuromag306mag.lay';
    cfg.viewmode = 'component';
    ft_databrowser(cfg, comp_mag)
    
    % correlate components with EOG&ECG
    [correlations_mag] = SSEP_corr_phys_comp(data_tot_arrej_EOG,data_tot_arrej_ECG, comp_mag);
    save correlations_mag
    
    path_to_use = 'Which components di you want to reject?[1,2,..] ';
    decision_mag = input(path_to_use);
    
    cfg = [];
    cfg.component = decision_mag; % to be removed component(s)
    data_mag_ICA  = ft_rejectcomponent(cfg, comp_mag, data_mag);
    
    close all
    
    %% Meggrads
    % plot the components for visual inspection
    figure
    cfg = [];
    cfg.component = 1:30;
    cfg.layout    = 'neuromag306planar.lay';
    cfg.comment   = 'no';
    ft_topoplotIC(cfg, comp_grad)
    
    cfg = [];
    cfg.layout = 'neuromag306planar.lay';
    cfg.viewmode = 'component';
    ft_databrowser(cfg, comp_grad)
    
    % correlate components with EOG&ECG
    [correlations_grad] = SSEP_corr_phys_comp(data_tot_arrej_EOG,data_tot_arrej_ECG, comp_grad);
    save correlations_grad
     
    path_to_use = 'Which components di you want to reject?[1,2]';
    decision_grad = input(path_to_use);
    
    cfg = [];
    cfg.component = decision_grad; % to be removed component(s)
    data_grad_ICA  = ft_rejectcomponent(cfg, comp_grad, data_grad);
    
    close all
    
    %% recompose the data after ICA
    cfg = [];
    data_tot_arrej_ICA = ft_appenddata(cfg,data_grad_ICA,data_mag_ICA);
    % reorder channels after appending (which does not preserve correct
    % configuration)
    
    data_tot_arrej_ICA = SSEP_reorderICAchan(data_tot_arrej_ICA,grad);

    clear data_grad_ICA data_mag_ICA    
    outputname = strcat(sbj_name.name,'_arrej_ICA.mat');
    save(outputname,'data_tot_arrej_ICA','-v7.3')
    
    %% Plot before and after ICA and ask for feedback:
    cfg_art_preICA                  = [];
    cfg_art_preICA.trl              = 'all';
    cfg_art_preICA.ylim             = [-1.5e-11 1.5e-11];
    cfg_art_preICA.channel          = 'MEG';
    cfg_art_preICA.gradscale        = 0.04;
    cfg_art_preICA.layout           = 'neuromag306mag.lay';
    cfg_art_preICA.viewmode         = 'butterfly';
    cfg_art_preICA.showlabel        = 'yes';
    ft_databrowser(cfg_art_preICA, data_tot_arrej);
    
    
    cfg_art_postICA                  = [];
    cfg_art_postICA.trl              = 'all';
    cfg_art_postICA.ylim             = [-1.5e-11 1.5e-11];
    cfg_art_postICA.channel          = 'MEG';
    cfg_art_postICA.gradscale        = 0.04;
    cfg_art_postICA.layout           = 'neuromag306mag.lay';
    cfg_art_postICA.viewmode         = 'butterfly';
    cfg_art_postICA.showlabel        = 'yes';
    ft_databrowser(cfg_art_postICA, data_tot_arrej_ICA);
    
    % take a note
    feedback = 'Data quality after ICA? [GOOD,MEDIUM,BAD]';
    ICA_decision = input(feedback);
    
    my_opinion.ICA_effectiveness  = ICA_decision;
    my_opinion.rejected_comp_mag  = decision_mag;
    my_opinion.rejected_comp_grad = decision_grad;
    
    save my_opinion my_opinion
    clear data_tot_arrej data_tot_arrej_ICA data_mag data_grad comp_mag comp_grad decision_mag decision_grad ICA_decision
    
    
end