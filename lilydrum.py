#!/usr/bin/env python

from os import path
import subprocess

basedir = path.dirname(path.realpath(__file__))
scd_file = path.join(basedir, 'lilydrum.scd')

cachefile = os.path.expanduser('~/.lilydrum-cache')

parser = argparse.ArgumentParser()
parser.add_argument('input_file', type=str, help='.lilydrum-notes file.')
args = parser.parse_args()

# There is no way to pass command-line args to supercollider.js,
# so we have to use this weird roundabout hack by writing to a special
# cache file. Yuck!
f = open(cachefile, 'w')
f.write(os.path.abspath(args.input_file))
f.close()

subprocess.call(['supercollider', scd_file])