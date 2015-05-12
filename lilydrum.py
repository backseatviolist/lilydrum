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
parser.add_argument('-k', '--kits', type=str, default=os.path.join(basedir, 'kits'),
	help='Kits directory. '
	'If this directory contains a lilysing.json file, it is taken as a single dir of samples. '
	'Otherwise the directory is searched for other directories containing lilysing.json.')
args = parser.parse_args()

base_file = args.input_file.rpartition('.')[0]

# Compile LilyPond files
if args.input_file.endswith('.ly'):
	callAndPrint(['lilypond', args.input_file])
	args.input_file = base_file + '.lilydrum-notes'

input_file = os.path.abspath(args.input_file)
base_file = os.path.abspath(base_file)
kits_dir = os.path.abspath(args.kits)
wav_file = base_file + '.wav'

if not os.path.isfile(input_file):
	raise ValueError('File %s does not exist' % input_file)

if not os.path.isdir(kits_dir):
	raise ValueError('%s is not a directory' % kits_dir)

# There is no way to pass command-line args to supercollider.js,
# so we have to use this weird roundabout hack by writing to a special
# cache file. Yuck!
f = open(cachefile, 'w')
json.dump({
	'notesFile': input_file,
	'outFile': wav_file,
	'kitsDir': kits_dir
}, f)
f.close()

subprocess.call(['supercollider', scd_file])