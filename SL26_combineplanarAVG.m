function data_cmb = SL26_combineplanarAVG(data)

data_cmb       = data;
data_cmb.BC   = [];
data_cmb.var   = [];
data_cmb.dof   = [];
data_cmb.label = [];
data_cmb.cfg   = [];

% find pairs of sensors

pairs = [];

for k = 1:length(data.label)
    
    i = 1;
    
    while i <= length(data.label)
        
        pairs(i,k) = strcmp(data.label{k}(1:end-1),data.label{i}(1:end-1));
        
        i = i + 1;
        
    end
    
    
end

for subject = 1:size(data.BC,1)
    k = 1;
    for i = 1:2:length(pairs)
        data_cmb.BC(subject,k,:)   = mean(data.BC(subject,find(pairs(:,i)),:));
        
        % Update labels in a ft-compatible format (1 before 3, joined by '+')
        labels = data.label(find(pairs(:,i)));
        label_root = labels{1}(1:end-1);
        data_cmb.label{k}  = strcat(label_root, '2+', label_root(4:end), '3');
        
        k = k + 1;
    end
    
    
end


end

