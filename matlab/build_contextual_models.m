%% Preliminaries
% Firstly, will create a model with the geneIDs instead of genes

clear
loadenv("./.env")  %Loading the environment variables
addpath(getenv("COBRATOOLBOX_PATH"))
% initCobraToolbox(false)
changeCobraSolver('gurobi')
% data_dir = getenv("DATA_PATH");

%% Getting data
model = readCbModel(strcat('./data/', '/models/Recon3DModel_301.mat'));  % Consistent Recon3D model

ge_matrix = readtable(".\data\salmon_results\combined_quant.tsv", 'FileType', 'delimitedtext', 'Delimiter', '\t');

ge_data.value = table2array(ge_matrix(:, 2:end));
ge_data.context = ge_matrix.Properties.VariableNames(2:end);
ge_data.genes = string(ge_matrix.GeneID);

%% Setting params

MeM = 'FASTCORE';
contexts = ge_data.context;
lt = 25;
ut = 75;
ThS = 1; % implying at gene level
core_reaction = [find(model.c)]; %Biomass maintenance as core
% core_reaction = [];  % For no core reaction
tol = 1e-8;
filename = '.\outputs\arid1a\';
changeCobraSolverParams('LP','feasTol',1e-9);
cons_mod_rxn_id = 1:numel(model.rxns);

%% building models

[Models, RxnImp] = buildContextmodels(ge_data,model,MeM,contexts,ut,lt,ThS,core_reaction,filename,cons_mod_rxn_id,tol);