function [correlations] = SSEP_corr_phys_comp(data_phys1_EOG, data_phys2_ECG,ICA_comp)
n_trials = length(ICA_comp.trial);
n_comp   = size(ICA_comp.trial{1},1);

if size(data_phys1_EOG.trial,2) ~= n_trials ||size(data_phys2_ECG.trial,2) ~= n_trials
    disp('Trial number does not match!')
    return
end
cfg = [];
cfg.channel  = 'EOG061';
EOG61 = ft_selectdata(cfg, data_phys1_EOG);
cfg = [];
cfg.channel  = 'EOG062';
EOG62 = ft_selectdata(cfg, data_phys1_EOG);


for c = 1:n_comp
    for z = 1:n_trials
        corr_coeff_61 = corrcoef(EOG61.trial{z}(ismember(EOG61.time{1},ICA_comp.time{1})),ICA_comp.trial{z}(c,:));
        corr_trial_61(c,z) = corr_coeff_61(1,2);
        
        corr_coeff_62 = corrcoef(EOG62.trial{z}(ismember(EOG62.time{1},ICA_comp.time{1})),ICA_comp.trial{z}(c,:));
        corr_trial_62(c,z) = corr_coeff_62(1,2);
        
        corr_coeff_63 = corrcoef(data_phys2_ECG.trial{z}(ismember(data_phys2_ECG.time{1},ICA_comp.time{1})),ICA_comp.trial{z}(c,:));
        corr_trial_63(c,z) = corr_coeff_63(1,2);
    end
end
    
    mean_corr1 = mean(abs(corr_trial_61),2);
    [val61,idx61] = sort(mean_corr1,'descend');
    mean_corr2 = mean(abs(corr_trial_62),2);
    [val62,idx62] = sort(mean_corr2,'descend');
    mean_corr3 = mean(abs(corr_trial_63),2);
    [val63,idx63] = sort(mean_corr3,'descend');
   
    correlations.EOG61 = [idx61, val61];
    correlations.EOG62 = [idx62, val62];
    correlations.EOG63 = [idx63, val63];
    
    temp = struct2table(correlations);
    
    disp("Correlation values for the first 10 components: ")
    disp(head(temp, 10))
    
end