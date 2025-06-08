% Evaluate how well model captures metabolic tasks


clear
% loadenv("./.env")  %Loading the environment variables
% addpath(getenv("COBRATOOLBOX_PATH"))
% initCobraToolbox(false)
% changeCobraSolver('gurobi');%% Preliminaries
%% Data

taskdata = 'data\metabolic_tasks_richelle_2019.xlsx';
outpath = 'results\model_evaluation\objective_tasks\';

% Getting path to all the models

sprint_model_paths = cellstr(ls("outputs\builtmodels\localgini_sprintcore_avg\*.mat"));
gimme_model_paths = cellstr(ls("outputs\builtmodels\localgini_gimme_avg\*.mat"));
init_model_paths = cellstr(ls("outputs\builtmodels\localgini_init_avg\*.mat"));


for i=1:6
    % Some calculation for getting the column names
    sprint_model_name = strsplit(sprint_model_paths{i}, '.');
    sprint_model_name = ['sprint_' sprint_model_name{1}];

    % gimme_model_name = strsplit(gimme_model_paths{i}, '.');
    % gimme_model_name = ['gimme_' gimme_model_name{1}];

    init_model_name = strsplit(init_model_paths{i}, '.');
    init_model_name = ['init_' init_model_name{1}];

    % Read the models
    sprint_model = readCbModel(['outputs\builtmodels\localgini_sprintcore_avg\' sprint_model_paths{i}]);
    gimme_model = readCbModel(['outputs\builtmodels\localgini_gimme_avg\' gimme_model_paths{i}]);
    init_model = readCbModel(['outputs\builtmodels\localgini_init_avg\' init_model_paths{i}]);

    % [result_gimme, ~,~] = checkMetabolicTasks(gimme_model, taskdata);
    % writecell(result_gimme, [outpath gimme_model_name '.csv'])

    [result_sprint, ~,~] = checkMetabolicTasks(sprint_model, taskdata);
    writecell(result_sprint, [outpath sprint_model_name '.csv'])

    [result_init, ~,~] = checkMetabolicTasks(init_model, taskdata);
    writecell(result_init, [outpath init_model_name '.csv'])
end
