function remove_loops_processed_data(modelDir, samplingDir, outputDir)
    
    

    modelDir = py.pathlib.Path(modelDir);
    samplingDir = py.pathlib.Path(samplingDir);
    outputDir = py.pathlib.Path(outputDir);

    models = cell(py.list(modelDir.glob('*.mat')));
    sample_files = cell(py.list(samplingDir.glob('*.parquet')));

    if length(sample_files) ~= length(models)
        error('Length mismatch between number of models and sampling files')
    end

    for i=1:length(sample_files)
        
        sample_file = sample_files{i};
        model_file = char(py.str(models{i}));

        savename = sample_file.stem;
        py.print(savename)
        df = py.polars.read_parquet(sample_file);
        model = readCbModel(model_file);

        model_reactions = model.rxns;
        df = df.select(cellstr(model_reactions'));
        fluxes = double(df.to_numpy().T);
        
        loopless_fluxes = removeLoopsFull(fluxes, model);

        save_df = py.polars.DataFrame(py.numpy.array(loopless_fluxes', dtype=py.numpy.float32), ...
             schema=py.list(df.columns));
        
        write_path = py.pathlib.Path(outputDir, savename + py.str('.parquet'));
        save_df.write_parquet(write_path)
    end
