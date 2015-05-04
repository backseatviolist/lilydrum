#!/usr/bin/env python

import sys
import os
import argparse
import subprocess
import json

def callAndPrint(cmd):
	print(' '.join(cmd))
	subprocess.call(cmd)

basedir = os.path.dirname(os.path.realpath(__file__))
scd_file = os.path.join(basedir, 'lilydrum.scd')

cachefile = os.path.expanduser('~/.lilydrum-cache')

parser = argparse.ArgumentParser()
parser.add_argument('input_file', type=str, help='.lilydrum-notes file. '
	                'You can also specify an .ly file and lilypond will be invoked first.')
args = parser.parse_args()

base_file = args.input_file.rpartition('.')[0]

# Compile LilyPond files
if args.input_file.endswith('.ly'):
	callAndPrint(['lilypond', args.input_file])
	args.input_file = base_file + '.lilydrum-notes'

input_file = os.path.abspath(args.input_file)
base_file = os.path.abspath(base_file)
wav_file = base_file + '.wav'

if not os.path.isfile(input_file):
	raise ValueError('File does not exist')

# There is no way to pass command-line args to supercollider.js,
# so we have to use this weird roundabout hack by writing to a special
# cache file. Yuck!
json.dumps({
	'notesFile': input_file,
	'outFile': wav_file
})

subprocess.call(['supercollider', scd_file])