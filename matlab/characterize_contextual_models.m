function characterize_contextual_models(varargin)
    %% characterize_contextual_models
    % Function to analyze context-specific genome-scale models in a directory.
    %
    % Usage:
    %   characterize_contextual_models('parameterName', parameterValue, ...)
    %
    % Parameters:
    %   'modelDir' (string, required):
    %       Directory containing the context-specific models.
    %
    %   'fullModelPath' (string, required):
    %       Path to the full genome-scale model file.
    %
    %   'outputDir' (string, required):
    %       Directory to save the analysis results.

    %% Parse inputs
    p = inputParser;

    addParameter(p, 'modelDir', '', @ischar);
    addParameter(p, 'fullModelPath', './data/models/Recon3DModel_301.mat', @ischar);
    addParameter(p, 'outputDir', '', @ischar);

    parse(p, varargin{:});

    modelDir = p.Results.modelDir;
    fullModelPath = p.Results.fullModelPath;
    outputDir = p.Results.outputDir;

    % Validate required inputs
    if isempty(modelDir) || isempty(fullModelPath) || isempty(outputDir)
        error('The parameters "modelDir", "fullModelPath", and "outputDir" are required.');
    end

    %% Preliminaries
    clearvars -except modelDir fullModelPath outputDir
    loadenv("./.env")  % Loading the environment variables
    addpath(getenv("COBRATOOLBOX_PATH"))

    % initCobraToolbox(false);
    % changeCobraSolver('gurobi');

    % Defining a few functions
    jaccard = @(x, y) numel(intersect(x, y)) / numel(union(x, y));

    %% Load models
    files = dir(fullfile(modelDir, '*.mat'));
    if isempty(files)
        error('No models found in the specified directory.');
    end

    full_model = readCbModel(fullModelPath);
    all_reactions = full_model.rxns;

    reactions = struct();
    growths = struct();

    for i = 1:numel(files)
        filename = files(i).name;
        model_path = strcat(modelDir, filename);
        filename = strsplit(files(i).name, '.');
        filename = filename{1};
        model = readCbModel(model_path);
        reactions.(filename) = model.rxns;
        growths.(filename) = optimizeCbModel(model).f;
    end

    %% Comparing reactions
    fields = fieldnames(reactions);
    full_model_comparison = struct();
    pairwise_comparison = struct();
    
    presence_absence = struct();
    for i=1:numel(fields)
        presence_absence.(fields{i}) = contains(all_reactions, reactions.(fields{i}));
    end
    writetable(struct2table(presence_absence), fullfile(outputDir, 'reaction_presence_absence.csv'))

    for i = 1:numel(fields)
        full_model_comparison.(fields{i}) = jaccard(full_model.rxns, reactions.(fields{i}));
    end

    for i = 1:numel(fields)
        for j = i:numel(fields)
            fieldname = strcat(fields{i}, '_', fields{j});
            pairwise_comparison.(fieldname) = jaccard(reactions.(fields{i}), reactions.(fields{j}));
        end
    end

    %% What systems are enriched?
    unique_reactions_struct = struct();

    for i = 1:numel(fields)
        for j = 1:numel(fields)
            fieldname = strcat(fields{i}, '_minus_', fields{j});
            unique_reactions = setdiff(reactions.(fields{i}), reactions.(fields{j}));
            unique_reactions_struct.(fieldname) = numel(unique_reactions);

            if numel(unique_reactions) == 0
                continue
            end

            unique_reactions_indices = find(ismember(full_model.rxns, unique_reactions));
            fea = FEA(full_model, unique_reactions_indices, 'subSystems');
            table = cell2table(fea);

            savename = fullfile(outputDir, 'fea_results', strcat(fieldname, '.csv'));
            if ~exist(fullfile(outputDir, 'fea_results'), 'dir')
                mkdir(fullfile(outputDir, 'fea_results'));
            end
            writetable(table, savename);
        end
    end

    %% Save growths
    writetable(struct2table(growths), fullfile(outputDir, 'growths.csv'));
end