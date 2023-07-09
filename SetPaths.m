%% Set the different Paths
cd('D:\tegolino-derosa\_Experiments\SL26\MEG_Data')
% Set the paths for the different folders
main_path =  pwd; 


fif_dir     = '\\cns-dataforge.cns.sissa.it\dcrepaldi\StatLearn\SL26_MEG_CIMeC\RAWDATA\fif_file\'; %%folder for raw data
preproc_dir = '\\cns-dataforge.cns.sissa.it\dcrepaldi\StatLearn\SL26_MEG_CIMeC\RAWDATA\preproc_file\'; %%folder for preprocessed data
avg_dir     = strcat(main_path,filesep,'avg',filesep); %%folder with averaged data (for the different conditions)
freq_dir =  strcat(main_path,filesep,'freqs',filesep); %%folder with data in frequency domain
behav_dir = strcat(main_path,filesep,'behavioral',filesep); %%folder with behavioral outputs
sources_dir = 'D:\tegolino-derosa\_Experiments\SL26\MEG_Data\Sources';

addpath(main_path);
addpath(fif_dir);
addpath(preproc_dir);
addpath(avg_dir);
addpath(freq_dir);
addpath(behav_dir);
addpath(sources_dir);
fif_folders = dir(strcat(fif_dir,'2*'));

