import numpy as np
import pandas as pd

from reading import *

data = pd.read_csv('data.csv')
num_play = (data['score'] == 1).sum()
num_skip = len(data) - num_play
denoms = [num_skip, num_play]

tids = data['id'].values
uniq_tids = np.unique(tids).tolist()

n = len(uniq_tids)
mat = np.zeros((n, n), dtype=np.float32)

i = j = 0

while i < len(tids) - 1:
    r1, r2 = data.iloc[i], data.iloc[j]
    id1, id2 = r1['id'], r2['id']
    ix1, ix2 = uniq_tids.index(id1), uniq_tids.index(id2)

    score = r2['score']
    mat[ix1, ix2] += score / denoms[(score + 1) // 2]

    if score == 1:
        i = j

    j = min(j+1, len(tids) - 1)

