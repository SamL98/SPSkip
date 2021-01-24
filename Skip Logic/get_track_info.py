from reading import read_skipped
from sputil import fetch_library, get_tracks

import pandas as pd
import os

skipped = read_skipped()
library = fetch_library()

tids_to_fetch = []

for _, row in skipped.iterrows():
    lib_rows = library.loc[lambda t: t.id == row.id]

    if len(lib_rows) == 0:
        tids_to_fetch.append(row.id)

nt = 50
tracks = []

for i in range(len(tids_to_fetch)//nt):
    tids = tids_to_fetch[i*nt:(i+1)*nt]
    track_batch = get_tracks(tids)

    if track_batch is not None:
        tracks.extend(track_batch)

pd.DataFrame(tracks).to_csv('other_tracks.csv', index=False)
