%% Artifact Rejection
% Visualize files through both databrowser and rejectvisual to assess data
% on single trial level. 
% Remove potentially compromised trials from MEG first, and EOG and ECG
% files accordignly.
% Save files ready for ICA

% M. De Rosa
% SL26 - SISSA+CIMeC Entrainment to regularities, Jan 2021


clear all; close all; clc;
SetPaths 

for i = 1:length(fif_folders)
    dirname                 = strcat(preproc_dir,fif_folders(i).name);
    cd(dirname)
    sbj = dir(strcat(fif_folders(i).name,'.mat'));
    load(sbj.name)
    EOG = dir(strcat(fif_folders(i).name,'_EOG.mat'));
    load(EOG.name)
    ECG = dir(strcat(fif_folders(i).name,'_ECG.mat'));
    load(ECG.name)    
    
    disp(sbj.name)
    %% Data Browser
    cfg_art                  = [];
    cfg_art.trl              = 'all';
    cfg_art.ylim             = [-1.5e-11 1.5e-11];
    cfg_art.channel          = 'MEG'; % 'MEG' or 'meggrad' or 'megmag'
    cfg_art.gradscale        = 0.04;
    cfg_art.layout           = 'neuromag306mag.lay';
    cfg_art.viewmode         = 'butterfly';
    cfg_art.showlabel        = 'yes';
    cfg_art                  = ft_databrowser(cfg_art, data_tot);
    
    %% Reject Visual 
    cfg                     = [];
    cfg.showlabel           = 'yes';
    cfg.trials              = 'all';
    cfg.method              = 'summary';
    cfg.gradscale           = 0.04; %factor to bring Grad and Mag data onto same scale
    cfg.latency             = [0 26.7];      
    cfg.layout              = 'neuromag306mag.lay';
    cfg.continuous          = 'no';
    data_tot_arrej          = ft_rejectvisual(cfg,data_tot);
    
    outputname_MEG = strcat(fif_folders(i).name,'_arrej');
    save(outputname_MEG,'data_tot_arrej','-v7.3')
    
    % Adapt EOG and ECG files accordingly
    cfg = [];
    cfg.trials = ismember(data_tot_arrej.trialinfo(:,1),data_tot_EOG.trialinfo(:,1));
    data_tot_arrej_EOG = ft_selectdata(cfg,data_tot_EOG);    
    
    
    outputname_EOG = strcat(fif_folders(i).name,'_arrej_EOG');
    save(outputname_EOG,'data_tot_arrej_EOG','-v7.3')
    
    cfg = [];
    cfg.trials = ismember(data_tot_arrej.trialinfo(:,1),data_tot_ECG.trialinfo(:,1));
    data_tot_arrej_ECG = ft_selectdata(cfg,data_tot_ECG);
    outputname_ECG = strcat(fif_folders(i).name,'_arrej_ECG');
    save(outputname_ECG,'data_tot_arrej_ECG','-v7.3')
    
    clear data_tot_arrej data_tot_arrej_EOG data_tot_arrej_ECG data_tot
    
end

clear all
