from sputil import fetch_library, read_spcsv
from os.path import join, isfile
from glob import glob

import numpy as np
import pandas as pd
import os

TID_LEN = 22
sppath = os.environ['SPPATH']

def read_skipped_file(fname):
    records = []

    with open(fname) as f:
        n = int(f.readline().strip())

        for _ in range(n):
            line = f.readline().strip()

            try:
                tid, ts = tuple(line.split(','))
            except ValueError:
                continue

            if len(tid) == TID_LEN:
                records.append((tid, int(ts)))

    df = pd.DataFrame(data=records, columns=['id', 'timestamp'])
    return df


def read_recently_played():
    return read_spcsv(join(sppath, 'recently_played.csv'))


def read_skipped():
    skipped = pd.DataFrame(columns=['id', 'timestamp'])

    for fname in glob(join(sppath, '*.csv')):
        if 'skipped' in fname:
            skipped = skipped.append(read_skipped_file(fname))

    if isfile('other_tracks.csv'):
        all_tracks = read_all_tracks()
        skipped = skipped.merge(all_tracks, on='id', how='inner')

    return skipped

def read_all_tracks():
    #tracks = fetch_library()
    tracks = read_spcsv(join(sppath, 'library.csv'))
    other_tracks = read_spcsv('other_tracks.csv')
    tracks = tracks.append(other_tracks)
    return tracks.set_index('id')

def save_data(df):
    df['title'] = df['title'].apply(lambda x: "'%s'" % x)
    df['artist'] = df['artist'].apply(lambda x: "'%s'" % x)
    df.to_csv('data.csv', index=False)

def read_data():
    df = pd.read_csv('data.csv')
    df['title'] = df['title'].apply(lambda x: x.strip("'").lstrip("'"))
    df['artist'] = df['artist'].apply(lambda x: x.strip("'").lstrip("'"))
    return df
