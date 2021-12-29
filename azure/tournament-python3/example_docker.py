import os
overwriteOldSubmissions = os.environ['overwriteOldSubmissions']
public_id = os.environ['public_id']
secret_key = os.environ['secret_key']
model_id = os.environ['model_id']

print("Running with model_id: %s" % model_id)

import time
start = time.time()

import pandas as pd
from lightgbm import LGBMRegressor
import gc
import json

from numerapi import NumerAPI
from halo import Halo
from utils import (
    save_model,
    load_model,
    neutralize,
    get_biggest_change_features,
    validation_metrics,
    ERA_COL,
    DATA_TYPE_COL,
    TARGET_COL,
    EXAMPLE_PREDS_COL
)


napi = NumerAPI(public_id=public_id, secret_key=secret_key,verbosity='info')

spinner = Halo(text='', spinner='dots')

current_round = napi.get_current_round(tournament=8)  # tournament 8 is the primary Numerai Tournament
print("current round is " + str(current_round))

i = 1
while i < 10:
    try:
        if napi.check_new_round():
            print("new round has started within the last 24hours!")
        else:
            print("no new round within the last 24 hours")
            
        latest_dataset_number = int(napi.get_current_round())
        print("Latest numerai dataset number is: ", latest_dataset_number)
        
        i = 20
    except:
        time.sleep(60) # Sleep for 60 seconds
        i += 1

try:
    napi.submission_status(model_id)
    if overwriteOldSubmissions == False:
        print("Looks like there is already a submission, aborting....")
        exit()
    else:
        print("we are going to overwrite the old submission")
except:
    print("No submission for this model yet i guess.....")
    
# Tournament data changes every week so we specify the round in their name.
print('Downloading dataset files...')
napi.download_dataset("numerai_training_data.parquet", "training_data.parquet")
napi.download_dataset("numerai_tournament_data.parquet", f"tournament_data_{current_round}.parquet")
napi.download_dataset("features.json", "features.json")

print('Reading minimal training data')
# read the feature metadata amd get the "small" feature set
with open("features.json", "r") as f:
    feature_metadata = json.load(f)
features = feature_metadata["feature_sets"]["small"]
# read in just those features along with era and target columns
read_columns = features + [ERA_COL, DATA_TYPE_COL, TARGET_COL]

# note: sometimes when trying to read the downloaded data you get an error about invalid magic parquet bytes...
# if so, delete the file and rerun the napi.download_dataset to fix the corrupted file
training_data = pd.read_parquet('training_data.parquet', columns=read_columns)

print('Reading minimal features of tournament data...')
tournament_data = pd.read_parquet(f'tournament_data_{current_round}.parquet',
                                  columns=read_columns)
nans_per_col = tournament_data[tournament_data["data_type"] == "live"].isna().sum()

# getting the per era correlation of each feature vs the target
all_feature_corrs = training_data.groupby(ERA_COL).apply(
    lambda era: era[features].corrwith(era[TARGET_COL])
)

# find the riskiest features by comparing their correlation vs
# the target in each half of training data; we'll use these later
riskiest_features = get_biggest_change_features(all_feature_corrs, 50)

# check for nans and fill nans
if nans_per_col.any():
    total_rows = len(tournament_data[tournament_data["data_type"] == "live"])
    print(f"Number of nans per column this week: {nans_per_col[nans_per_col > 0]}")
    print(f"out of {total_rows} total rows")
    print(f"filling nans with 0.5")
    tournament_data.loc[:, features].fillna(0.5, inplace=True)
else:
    print("No nans in the features this week!")
    
model_name = f"model_target"
print(f"Reading existing model '{model_name}'")
model = load_model(model_name)

print(f"Predicting on tournament data")
# double check the feature that the model expects vs what is available to prevent our
# pipeline from failing if Numerai adds more data and we don't have time to retrain!
model_expected_features = model.booster_.feature_name()
if set(model_expected_features) != set(features):
    print(f"New features are available! Might want to retrain model {model_name}.")
tournament_data.loc[:, f"preds_{model_name}"] = model.predict(
    tournament_data.loc[:, model_expected_features])
print(f"Predicting on tournament data finished")

gc.collect()


print(f"Neutralizing to risky features")

tournament_data[f"preds_{model_name}_neutral_riskiest_50"] = neutralize(
    df=tournament_data,
    columns=[f"preds_{model_name}"],
    neutralizers=riskiest_features,
    proportion=1.0,
    normalize=True,
    era_col=ERA_COL
)
print(f"Neutralizing to risky features finished")

model_to_submit = f"preds_{model_name}_neutral_riskiest_50"

csvFilename = "tournament_predictions_" + str(current_round) + ".csv"

# rename best model to "prediction" and rank from 0 to 1 to meet upload requirements
tournament_data["prediction"] = tournament_data[model_to_submit].rank(pct=True)
tournament_data["prediction"].to_csv(csvFilename)

print(f"Prediction export to csv finished.")

#Upload model
print(f"Prediction uploading.....")
i = 1
while i < 10:    
    try:
        submission_id = napi.upload_predictions(csvFilename, model_id=model_id, version=2)
        time.sleep(60) # Sleep for 60 seconds
        i = 10
    except:
        print(f"Prediction upload exception, retrying....")
        time.sleep(60) # Sleep for 60 seconds
        i += 1
print(f"Prediction upload finished.")
        
