#! /usr/bin/python

import sys
import numpy as np
import matplotlib.pyplot as plt
import argparse
# for the igor code to run
import re
import struct

# the number of lines in the output file containing data to be used in the 
# histogram is 10000
NUM_LINES = 10000
ENTRIES_PER_LINE = 100

parser = argparse.ArgumentParser()
parser.add_argument('-f', help='specify infile paths. more than one infile can\
	be specified', nargs='+')
parser.add_argument('-l', help='Specify a lower bound for the histogram. By \
	default it is 0.5', type=float, default=0.5)
parser.add_argument('-u', help='specify a lower bound for the histogram. By \
	default it is 3', type=float, default = 3)
parser.add_argument('-n', type=int, default=2, help='Allows the user to specify\
	the number of blah blah blh fix this')
# returns a dictionary whose keys are the letters corresponding to command\
# line flags 
args = vars(parser.parse_args())

def makeDataArray(infile_array):
	dataArray = np.zeros(len(infile_array)*NUM_LINES*ENTRIES_PER_LINE)
	for file in infile_array:
		n=infile_array.index(file)
		with open(file) as f:
			lines = [line.rstrip('\n').split('\t') for line in f]
			for i in range(NUM_LINES):
				for j in range(ENTRIES_PER_LINE):
					dataArray[1000000*n+i*ENTRIES_PER_LINE+j] = lines[i][j]
	return dataArray

def makeHist(dataArray):
	n, bins, patches = plt.hist(dataArray, 1000, color='black', alpha=0.75)
	binMiddle = findBiggestBinsMiddles(n,bins,args['n'], .7)
#	plt.axvline(x=binMiddle, color='red')
	plt.ylabel('Counts')
	plt.xlabel('Conductance (G0)')
	plt.savefig('conductance_histogram_for_conductance_block.png')

# Takes two arrays of m and m+1 element corresponding to the counts, and bin
# bin edges respectively, and an integer specifying how many bins middles to
# return. I.e. for the biggest bin middle n=1. It also ignores bins whose
# conductance value is greater than the lower bound since values close to 0
# tend to have many counts
def findBiggestBinsMiddles(counts, binEdges, n, lowerBound):
	import heapq
	largestElements = heapq.nlargest(n,counts)
	boundedLargestElements=[i for i in largestElements if i>lowerBound]
	countIndeces = [np.where(counts==i) for i in boundedLargestElements]
	print(countIndeces, type(countIndeces))
	binMiddles = [(binEdges[i[0][0]]+binEdges[i[0][0]+1])/float(2) for i in\
		 countIndeces]
	print(binMiddles)
	return binMiddles

def boundData(min, max, dataArray):
	#goodIndeces = np.zeros(len(dataArray))
	#dataOutsideLimits = np.zeros(len(dataArray))
	goodDataArray = [i for i in dataArray if (i<max and i>min)]
	return goodDataArray

def fitGaussian(mode, binsArray, countsArray):
	lowerBound,upperBound = mode-.25,mode+.25
	return lowerBound

def main(infileArray):
#	conductanceBlock = infile[-5]
	min,max = args['l'],args['u']
	dataArray = makeDataArray(infileArray)
	dataArray = boundData(min, max, dataArray)
	makeHist(dataArray)

if __name__ == '__main__':
    main(args['f'])