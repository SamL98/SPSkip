from sputil import get_tracks, read_spcsv
from os.path import join
from glob import glob

import pandas as pd
import os

from reading import *

# 1. read the recently played and all skipped files
recently_played = read_recently_played()
skipped = read_skipped()

recently_played['score'] = 1
skipped['score'] = -1

del recently_played['Unnamed: 0']
del recently_played['duration']

recently_played = recently_played[['id', 'title', 'artist', 'timestamp', 'score']]
skipped = skipped[['id', 'title', 'artist', 'timestamp', 'score']]

data = recently_played.append(skipped)
data = data.sort_values(by='timestamp')
data.to_csv('data.csv', index=False)
