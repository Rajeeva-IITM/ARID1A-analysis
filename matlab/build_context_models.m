function build_context_models(varargin)
    %% build_context_models
    % Function to build context-specific genome-scale models using expression data.
    %
    % Usage:
    %   build_context_models('parameterName', parameterValue, ...)
    %
    % Parameters:
    %   'modelPath' (string, optional):
    %       Path to the genome-scale model file. Default: './data/models/Recon3DModel_301.mat'.
    %
    %   'expressionMatrix' (string, optional):
    %       Path to the expression matrix file. Default: './data/Clus_vs_disp/counts_clus_reconclean.tsv'.
    %
    %   'method' (string, optional):
    %       Context-specific model-building method (e.g., 'FASTCORE').
    %       Default: 'FASTCORE'. Note: Applies SprintCore actually
    %
    %   'lowerThreshold' (numeric, optional):
    %       Lower threshold for expression data. Default: 25.
    %
    %   'upperThreshold' (numeric, optional):
    %       Upper threshold for expression data. Default: 75.
    %
    %   'thresholdType' (numeric, optional):
    %       Type of threshold (e.g., 1 for gene-level). Default: 1.
    %
    %   'coreReaction' (numeric array or string, optional):
    %       Core reactions to include. Can be:
    %       - A numeric array of reaction indices (e.g., [1, 5, 10]).
    %       - The string 'growth' to include the default biomass maintenance reaction.
    %       - Empty ([]) for no core reaction. Default: [].
    %
    %   'outputFilename' (string, optional):
    %       Base name for output files. Default: './outputs/clus_vs_disp/clus'.
    %
    %   'tolerance' (numeric, optional):
    %       Solver tolerance. Default: 1e-8.

    %% Preliminaries
    clearvars -except varargin
    loadenv("./.env")  % Loading the environment variables
    addpath(getenv("COBRATOOLBOX_PATH"))
    % changeCobraSolver('gurobi')

    %% Parse command-line arguments
    p = inputParser;

    addParameter(p, 'modelPath', './data/models/Recon3DModel_301.mat', @ischar);
    addParameter(p, 'expressionMatrix', './data/Clus_vs_disp/counts_clus_reconclean.tsv', @ischar);
    addParameter(p, 'method', 'FASTCORE', @ischar);
    addParameter(p, 'lowerThreshold', 25, @isnumeric);
    addParameter(p, 'upperThreshold', 75, @isnumeric);
    addParameter(p, 'thresholdType', 1, @isnumeric); % 1 for gene-level
    addParameter(p, 'coreReaction', [], @(x) isnumeric(x) || ischar(x) || isempty(x)); % Allow numeric, string, or empty
    addParameter(p, 'outputFilename', './outputs/clus_vs_disp/clus', @ischar);
    addParameter(p, 'tolerance', 1e-8, @isnumeric);

    parse(p, varargin{:});

    modelPath = p.Results.modelPath;
    expressionMatrix = p.Results.expressionMatrix;
    method = p.Results.method;
    lowerThreshold = p.Results.lowerThreshold;
    upperThreshold = p.Results.upperThreshold;
    thresholdType = p.Results.thresholdType;
    coreReaction = p.Results.coreReaction;
    outputFilename = p.Results.outputFilename;
    tolerance = p.Results.tolerance;

    %% Getting data
    model = readCbModel(modelPath);  % Load the consistent Recon3D model

    ge_matrix = readtable(expressionMatrix, 'FileType', 'delimitedtext', 'Delimiter', '\t');

    ge_data.value = table2array(ge_matrix(:, 2:end));
    ge_data.context = ge_matrix.Properties.VariableNames(2:end);
    ge_data.genes = string(ge_matrix.GeneID);

    %% Setting params
    contexts = ge_data.context;

    % Handle coreReaction parameter
    if ischar(coreReaction) && strcmpi(coreReaction, 'growth')
        coreReaction = find(model.c); % Default: Biomass maintenance as core
    elseif isempty(coreReaction)
        coreReaction = []; % No core reaction
    end

    changeCobraSolverParams('LP', 'feasTol', 1e-9);
    cons_mod_rxn_id = 1:numel(model.rxns);

    %% Building models
    [Models, RxnImp] = buildContextmodels(ge_data, model, method, contexts, ...
        upperThreshold, lowerThreshold, thresholdType, coreReaction, ...
        outputFilename, cons_mod_rxn_id, tolerance);
end