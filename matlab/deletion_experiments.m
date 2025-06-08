function deletion_experiments(varargin)
    %% deletion_experiments
    % perform deletion experiments to identify important genes or reaction
    % for a set of models in a directory
    %
    % Usage:
    %   characterize_contextual_models('parameterName', parameterValue,
    %   ...)
    %
    % Parameters:
    %   'modelDir' (string, required):
    %       Directory containing the context-specific models.
    %
    %   'level' (string, optional):
    %       'Gene' or 'Reaction'. Gene default
    %
    %   'outputDir' (string, required):
    %       Directory to save the analysis results.

    %% Parse inputs

    p = inputParser();

    addParameter(p, 'modelDir', '', @ischar)
    addParameter(p, 'level', 'Gene', @ischar)
    addParameter(p, 'outputDir', '', @ischar)
    
    parse(p, varargin{:})

    modelDir = p.Results.modelDir;
    level = p.Results.level;
    outputDir = p.Results.outputDir;

    %% Load models
    files = dir(fullfile(modelDir, '*.mat'));
    if isempty(files)
        error('No models found in the specified directory.');
    end

    for i=1:numel(files)

        file = files(i).name;
        filename = strsplit(file, '.mat');
        filename = filename{1};
        model = readCbModel(fullfile(modelDir, file));

        if strcmp(level, 'Gene')
            [grRatio, ~, ~, effect, ~] = singleGeneDeletion(model);
            result = table();
            result.gene = model.genes;
            result.grRatio = grRatio;
            result.effect = effect;
            writetable(result, fullfile(outputDir, strcat(filename,'.csv')))

        elseif strcmp(level,'Reaction')
            [grRatio, ~, ~, effect, ~] = singleRxnDeletion(model);
            result = table();
            result.reaction = model.rxns;
            result.grRatio = grRatio;
            result.effect = effect;
            writetable(result, fullfile(outputDir, strcat(filename,'.csv')))
        else
            error("level must be one of 'Gene' or 'Reaction'")
        end
    end
