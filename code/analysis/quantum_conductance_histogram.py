#! /usr/bin/python

import sys
import numpy as np
import matplotlib.pyplot as plt
# for the igor code to run
import re
import struct

# the number of lines in the output file containing data to be used in the 
# histogram is 10000
NUM_LINES = 10000
ENTRIES_PER_LINE = 100
MAX=3
MIN=0.5
try:
	MAX = float(sys.argv[2])
except:
	IndexError
try:
	MIN = float(sys.argv[3])
except:
	IndexError


def makeDataArray(infile):
	dataArray = np.zeros(NUM_LINES*ENTRIES_PER_LINE)
	with open(infile) as f:
		lines = [line.rstrip('\n').split('\t') for line in f]
		for i in range(NUM_LINES):
			for j in range(ENTRIES_PER_LINE):
				dataArray[i*ENTRIES_PER_LINE+j] = lines[i][j]
	return dataArray

def makeHist(dataArray, label):
	n, bins, patches = plt.hist(dataArray, 100, color='green', alpha=0.75)
	binMiddle = findBiggestBinMiddle(n,bins)
	plt.axvline(x=binMiddle, color='red')
	plt.ylabel('Counts')
	plt.savefig('conductance_histogram_for_conductance_block_'+str(label)+\
		'.png')

def findBiggestBinMiddle(counts, bins):
	i = np.argmax(counts)
	binMiddle = (bins[i]+bins[i+1])/float(2)
	print(binMiddle)
	return binMiddle

def boundData(min, max, dataArray):
	#goodIndeces = np.zeros(len(dataArray))
	#dataOutsideLimits = np.zeros(len(dataArray))
	goodDataArray = [i for i in dataArray if (i<max and i>min)]
	return goodDataArray

def main(infile):
	conductanceBlock = infile[-5]
	dataArray = makeDataArray(infile)
	dataArray = boundData(MIN, MAX, dataArray)
	makeHist(dataArray, conductanceBlock)

main(sys.argv[1])
