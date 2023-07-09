%% Average
% Average trials per participant per condition.
% Save individual files (sbj x cond) as well as condition files.

% M. De Rosa
% SL26 - SISSA+CIMeC Entrainment to regularities, Jan 2021

clear all; close all; clc; 

SetPaths

load grad
% list triggers indicating the beginning of each condition
initial_trigger = [11, 21, 31, 41, 51, 61, 71, 81, 91, 101];



for i = 1:length(fif_folders)  %within each participant
    dir_name = strcat(preproc_dir,fif_folders(i).name);
    cd(dir_name)
    preproc_data_file = dir('*_ICA.mat');
    load(preproc_data_file.name);
    data_tot_arrej_ICA = SSEP_reorderICAchan(data_tot_arrej_ICA,grad);
    data_tot_arrej_ICA.grad = grad;
    
    cfg                    = [];
    cfg.latency            = [0 26.7]; % trial length
    
    for g =1:length(initial_trigger) %for all conditions
        
        current_trigger                 = initial_trigger(g);
        cfg.trials                      = find(data_tot_arrej_ICA.trialinfo(:,1) == current_trigger); % find only relevant indices
        output                          = ft_timelockanalysis(cfg,data_tot_arrej_ICA); % ERF for each condition.
        %save individual participant
        name                            = ['cond_' num2str(g) '_' num2str(fif_folders(i).name)];
        eval([name ' =  output;'])
        cd(freq_dir);
        save(name)
        % insert participant results into the condition structure
        eval(['cond' num2str(g) '{i}   = output'])
        clear output
    end
end

%save conditions
cd(avg_dir)
for g=1:length(initial_trigger)
    
    cond_name = ['avg\cond' num2str(g)];
    save(cond_name)
end

