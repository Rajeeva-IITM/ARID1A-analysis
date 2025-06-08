% Code for creating binary reaction matrices from the built models

%% Preliminaries
clear
loadenv("./.env")  %Loading the environment variables
addpath(getenv("COBRATOOLBOX_PATH"))

%% Data

recon3d = readCbModel(strcat('./data/', '/models/Recon3DModel_301.mat'));  % Consistent Recon3D model

all_reactions = recon3d.rxns;

% Getting path to all the models

sprint_model_paths = cellstr(ls("outputs\builtmodels\no_objective\localgini_sprintcore\*.mat"));
% gimme_model_paths = cellstr(ls("outputs\builtmodels\localgini_gimme_avg\*.mat"));
init_model_paths = cellstr(ls("outputs\builtmodels\no_objective\localgini_init\*.mat"));

result_table = table(all_reactions, 'VariableNames', {'Reactions'});

for i=1:length(sprint_model_paths)
    
    % Some calculation for getting the column names
    sprint_model_name = strsplit(sprint_model_paths{i}, '.');
    sprint_model_name = ['sprint_' sprint_model_name{1}];

    % gimme_model_name = strsplit(gimme_model_paths{i}, '.');
    % gimme_model_name = ['gimme_' gimme_model_name{1}];

    init_model_name = strsplit(init_model_paths{i}, '.');
    init_model_name = ['init_' init_model_name{1}];
    
    % Get the reactions in the context specific models and then see which
    % reactions are present and which aren't

    

    result_table.(sprint_model_name) = sprint_rxns;
    % result_table.(gimme_model_name) = gimme_rxns;
    result_table.(init_model_name) = init_rxns;

end

writetable(result_table, "outputs\builtmodels\no_objective\reaction_presence_absence matrix.csv")