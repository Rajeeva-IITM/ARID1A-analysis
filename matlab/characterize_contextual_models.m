%% Testing built models

clear
loadenv("./.env")  %Loading the environment variables
addpath(getenv("COBRATOOLBOX_PATH"))
% initCobraToolbox(false)

% Defining a few functions
jaccard = @(x, y) numel(intersect(x,y))/numel(union(x,y));

out_dir = 'outputs/sampling_analysis/localgini_sprintcore_avg/';
model_dir = 'outputs/builtmodels/localgini_sprintcore_avg';
files = ls(model_dir);
files = files(3:end,:);

full_model = readCbModel('./data/models/Recon3DModel_301.mat');

for i=1:6
    filename = strsplit(files(i,:), '.');
    filename = filename{1};
    model = readCbModel(strcat(model_dir, '/', files(i,:)));
    reactions.(filename) = model.rxns;
    growths.(filename) = optimizeCbModel(model).f;
end

%% Comparing reactions

fields =fieldnames(reactions);
for i=1:numel(fields)
    full_model_comparison.(fields{i}) = jaccard(full_model.rxns, reactions.(fields{i}));
end

for i=1:numel(fields)
    for j=i:numel(fields)
        fieldname = strcat(fields{i}, '_',fields{j});
        pairwise_comparison.(fieldname) = jaccard(reactions.(fields{i}), reactions.(fields{j}));
    end
end

%% What systems are enriched?

% GES WT - ARID1A


for i=1:numel(fields)
    for j=1:numel(fields)
        fieldname = strcat(fields{i}, '_minus_',fields{j});
        unique_reactions = setdiff(reactions.(fields{i}), reactions.(fields{j}));
        unique_reactions_struct.(fieldname) = numel(unique_reactions);
        if numel(unique_reactions)==0
            continue
        end
        unique_reactions_indices = find(contains(full_model.rxns, unique_reactions));
        fea = FEA(full_model, unique_reactions_indices, 'subSystems');
        table = cell2table(fea);

        savename = strcat(out_dir, '/fea_results/', fieldname, '.csv');
        writetable(table, savename)
    end
end


writetable(struct2table(growths), strcat(out_dir, 'growths.csv'))