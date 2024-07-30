%% Testing built models

clear
loadenv("./.env")  %Loading the environment variables
addpath(getenv("COBRATOOLBOX_PATH"))
% initCobraToolbox(false)

model_dir = 'outputs/builtmodels/localgini_init';
files = ls(model_dir);
files = files(3:end,:);

for i=1:12
    filename = strsplit(files(i,:), '.');
    filename = filename{1};
    model = readCbModel(strcat(model_dir, '/', files(i,:)));
    reactions.(filename) = model.rxns;
    growths.(filename) = optimizeCbModel(model).f;
end