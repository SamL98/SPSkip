from flask import Flask, request, send_from_directory, jsonify
from werkzeug.utils import secure_filename
from os.path import join as pjoin
import os
import psycopg2 as pg
import psycopg2.extras as ex

app = Flask(__name__)

def get_db_url():
	db_url = None
	if 'SPSKIP_DB_URL' in os.environ:
		db_url = os.environ['SPSKIP_DB_URL']
	elif 'DATABASE_URL' in os.environ:
		db_url = os.environ['DATABASE_URL']
	return db_url

@app.route('/upload', methods=['POST'])
def upload():
	if not 'file' in request.files:
		print('No uploaded file')
		return '', 400

	f = request.files['file']
	if not f.filename.endswith('.csv'):
		print('Tried to upload non-csv: %s' % f.filename)
		return '', 400

	db_url = get_db_url()
	if db_url is None:
		print('Couldnt get database url')
		return 'No database url in environment', 500

	contents = str(f.read())[2:-1]
	lines = contents.split('\\n')
	nskips = int(lines[0])

	conn = pg.connect(db_url)
	cur = conn.cursor()

	for i in range(nskips):
		line = lines[i+1]
		parts = line.split(',')
		tid, ts = parts[0], int(parts[1])
		cur.execute('INSERT INTO Skips (tid, ts) VALUES (%s, %s) ON CONFLICT (tid, ts) DO NOTHING', (tid, ts))

	conn.commit()

	cur.close()
	conn.close()

	return 'All good', 200

@app.route('/download', methods=['GET'])
def download():
	db_url = get_db_url()
	if db_url is None:
		print('Couldnt get database url')
		return 'No database url in environment', 500

	after = 0
	if 'after' in request.args:
		after = int(request.args.get('after'))

	conn = pg.connect(db_url)
	cur = conn.cursor(cursor_factory=ex.RealDictCursor)

	cur.execute('SELECT tid, ts FROM Skips WHERE ts>%s', (after,))
	res = cur.fetchall()

	cur.close()
	conn.close()

	return jsonify(res), 200

if __name__ == '__main__':
	app.run()
