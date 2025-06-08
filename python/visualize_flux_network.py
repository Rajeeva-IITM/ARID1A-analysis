import polars as pl 
# import numpy as np
# import cobra as cb
import sammi 
from argparse import ArgumentParser
# from pathlib import Path
from cobra.io.mat import load_matlab_model


def visualize_flux_network(
    model_path,
    reaction_df_path,
    fc_cutoff,
    html_name,
    subsystem_data_path = "./data/recon_reaction_names.csv"
):
    
    model = load_matlab_model(model_path)
    reaction_df = pl.read_csv(reaction_df_path, infer_schema_length=False)
    subsystem_df = pl.read_csv(subsystem_data_path)
    
    # reaction df must have columns: Reaction, fc, pval, *condition1, *condition2, subsystem
    condition1 = reaction_df.columns[3]
    condition2 = reaction_df.columns[4]

    
    reaction_df = reaction_df.with_columns(
        pl.col('fc').cast(pl.Float32),
        pl.col(condition1).cast(pl.Float32, strict=False),
        pl.col(condition2).cast(pl.Float32, strict=False)
        
    )
    
    
    if fc_cutoff == 'more':
        reaction_df = reaction_df.filter((pl.col('fc')>0) | (pl.col(condition1).is_null()))
        relevant_condition = condition2
    elif fc_cutoff == 'less':
        reaction_df = reaction_df.filter((pl.col('fc')<0) | (pl.col(condition2).is_null()))
        relevant_condition = condition1
    elif fc_cutoff == 'none':
        relevant_condition = 'fc'
    else:
        raise Exception("fc_cutoff must be 'more' or 'less' or 'none")
    
    reaction_df = reaction_df.join(subsystem_df, 'Reaction')
    
    plot_df = (
        reaction_df
        .group_by('subSystem')
        .agg(pl.col('Reaction'), pl.col(relevant_condition))
        .with_columns(subsystem_size = pl.col('Reaction').list.len())
        .sort('subsystem_size',descending=True)
    )
    
    plot_data = []
    for row in plot_df.iter_rows():
        plot_data.append(
            sammi.parser(row[0],row[1], row[2])
        )
    
    sammi.plot(model, plot_data, opts=sammi.options(html_name))
    
    return plot_df

if __name__ == "__main__":
    
    parser = ArgumentParser()
    parser.add_argument("--model_path", type=str, required=True)
    parser.add_argument("--reaction_df_path", type=str, required=True)
    parser.add_argument("--fc_cutoff", type=str, required=True)
    parser.add_argument("--html_name", type=str, required=True)
    parser.add_argument("--subsystem_data_path", type=str, default="./data/recon_reaction_names.csv")
    
    args = parser.parse_args()
    
    df = visualize_flux_network(
        model_path=args.model_path,
        reaction_df_path=args.reaction_df_path,
        fc_cutoff=args.fc_cutoff,
        html_name=args.html_name,
        subsystem_data_path=args.subsystem_data_path
    )
    print(df)