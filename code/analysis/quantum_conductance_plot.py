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
parser.add_argument('-e', nargs='+',\
	help='Specify the infile path for file containing extension information')
parser.add_argument('-c', nargs='+',\
	help='Specify the infile patt for file containing conductance information')
parser.add_argument('-n', \
	help='Specify how may traces to generate. By default this is 100, i.e. the \
	the number of traces per infile',\
	default=100)
# returns a dictionary whose keys are the letters corresponding to command line\
# flags
args=vars(parser.parse_args())

def makeExtensionArray(extensionInfile):
	with open(extensionInfile) as f:
		extensionArray=[float(line.rstrip('\n')) for line in f]
	return extensionArray

def makeConductanceMatrix(conductanceInfile):
	dataArray=np.zeros(NUM_LINES*ENTRIES_PER_LINE)
	print(conductanceInfile)
	with open(conductanceInfile) as f: 
		lines=[line.rstrip('\n').split('\t') for line in f][:NUM_LINES]
		for i in range(NUM_LINES):
			for j in range(ENTRIES_PER_LINE):
				dataArray[i*ENTRIES_PER_LINE+j]=float(lines[i][j])
	conductanceMatrix=np.reshape(dataArray,(NUM_LINES,len(dataArray)/NUM_LINES))
	return conductanceMatrix

#def boundConductanceArray(conductanceArray,upperBound):
#	conductanceArray=[i for i in conductanceArray if i<upperBound]
#	return conductanceArray

def findFirstInstance(array, number):
	index=np.nan
	for i in range(len(array)):
		if array[i]<number:
			index=i
			break
		else:
			pass
	return index

# Truncates the input array so that it includes the elements at the start and
# end positions
def truncateArray(array,startIndex,endIndex):
	truncatedArray=array[startIndex-1:endIndex]
	return truncatedArray

def makeArraysForPlot(conductanceArray,extensionArray,upperBound,lowerBound):
	sIndex=findFirstInstance(conductanceArray,upperBound)
	eIndex=findFirstInstance(conductanceArray,lowerBound)
	conductanceArray=truncateArray(conductanceArray,sIndex,eIndex)
	_=truncateArray(extensionArray,sIndex,eIndex)
	# This step reverses the order of the extension array since the extension
	# data represents how extended the piezo is, and thus is inversely related
	# to how far the tip is from the wafer
	extensionArray=_[::-1]
	return conductanceArray,extensionArray

def generateTrace(extensionArray,conductanceArray,n):
	fig=plt.figure()
	ax=plt.subplot(111)
	ax.plot(extensionArray, conductanceArray)
	fig.savefig('conductance_trace_'+str(n)+'.png')

def main(eInfiles,cInfiles):
	for i in range(len(eInfiles)):
		print(cInfiles)
		cMatrix=makeConductanceMatrix(cInfiles[i])
		eArray=makeExtensionArray(eInfiles[i])
		for i in range(len(cMatrix[1,:])):
			c,e=makeArraysForPlot(cMatrix[:,i],eArray,10,0.1)
			generateTrace(e,c,i+1)

main(args['e'],args['c'])
