function data = SSEP_reorderICAchan(data,grad)


if sum(strcmp(data.label,grad.label)) == length(data.label)
    
    disp('Nothing to correct, sensors in the right order')
    
elseif sum(strcmp(data.label,grad.label)) ~= length(data.label)
    
    label_idx = zeros(length(data.label),1);
    
    % find correct index
    for n_label = 1:length(data.label)
        
        label_idx(n_label) = find(strcmp(grad.label{n_label},data.label));
        
    end
    
    % adjust label order
    data.label = data.label(label_idx);
    
    %adjust channel order in trial
    
    if isfield(data,'trial') % single trials
        
        for n_trials = 1:length(data.trial)
            
            data.trial{n_trials} = data.trial{n_trials}(label_idx,:);
            
        end
        
    elseif isfield(data,'avg') % average already calculated
        
        data.avg = data.avg(label,:);
        
    end
    
    disp('Corrected channel order')
    
end
end