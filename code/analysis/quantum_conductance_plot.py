#! usr/bin/python

import numpy as np
import matplotlib.pyplot as plt
import argparse

# Only the first 10000 lines of the conductance text files contain conductance
# data
DESC="""Take some IGOR-formatted data files with successful quantum conductance
runs saved and convert the data to text."""
NUM_LINES=10000
# each line in the conductance infile has 100 data points in it
ENTRIES_PER_LINE=100

parser = argparse.ArgumentParser(description=DESC)
parser.add_argument('-e', \
	help='Specify the infile path for file containing extension information')
parser.add_argument('-c', \
	help='Specify the infile patt for file containing conductance information')
parser.add_argument('-n', \
	help='Specify how may traces to generate. By default this is 100, i.e. the \
	the number of traces per infile',\
	default=100)
# returns a dictionary whose keys are the letters corresponding to command line\
# flags
args=vars(parser.parse_args())

def makeVoltageArray(voltageInfile):
	with open(voltageInfile) as f:
		voltageArray=[line for line in f]
#		voltageArray=[i for i in voltageArray]
	return voltageArray

def makeConductanceMatrix(conductanceInfile):
	dataArray=np.zeros(NUM_LINES*ENTRIES_PER_LINE)
	with open(conductanceInfile) as f: 
		lines=[line.rstrip('\n').split('\t') for line in f][:NUM_LINES]
		for i in range(NUM_LINES):
			for j in range(ENTRIES_PER_LINE):
				dataArray[i*ENTRIES_PER_LINE+j]=float(lines[i][j])
	conductanceMatrix=np.reshape(dataArray,(NUM_LINES,len(dataArray)/NUM_LINES))
	return conductanceMatrix

def boundConductanceArray(conductanceArray,upperBound):
	conductanceArray=[i for i in conductanceArray if i<upperBound]
	return conductanceArray

def generateTrace(voltageArray,conductanceArray,n):
	fig=plt.figure()
	ax=plt.subplot(111)
	ax.plot(voltageArray, conductanceArray)
	fig.savefig('conductance_trace_'+str(n)+'.png')

conductanceMatrix=makeConductanceMatrix(args['e'])
conductanceArray=conductanceMatrix[:,20]
voltageArray=makeVoltageArray(args['v'])
generateTrace(voltageArray,conductanceArray,1)
