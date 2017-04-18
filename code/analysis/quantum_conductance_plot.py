#! usr/bin/python

import numpy as np
import matplotlib.pyplot as plt
import argparse
import os

# Only the first 10000 lines of the conductance text files contain conductance
# data
DESC="""Take some IGOR-formatted data files with successful quantum conductance
runs saved and convert the data to text."""
NUM_LINES=10000
# each line in the conductance infile has 100 data points in it
ENTRIES_PER_LINE=100

parser = argparse.ArgumentParser(description=DESC)
parser.add_argument('-e', nargs='+',required=True,\
	help='[required] Specify the infile path for file containing extension \
	information')
parser.add_argument('-c', nargs='+',required=True,\
	help='[required] Specify the infile patt for file containing conductance \
	information')
parser.add_argument('-n', \
	help='Specify how may traces to generate. By default this is 100, i.e. the \
	the number of traces per infile',\
	default=100)
parser.add_argument('-d', required=True,\
	help='[required] Specify the date the data was taken on in the form \
	mm-dd-yyyy. This is used to generate the directory in which plots will be \
	saved')
# returns a dictionary whose keys are the letters corresponding to command line\
# flags
args=vars(parser.parse_args())

# FUNCTIONS FOR FORMATTING INPUT FILES
# takes text of the form PullOutExtension_<number>.txt as output by the Python
# package for converting Igor binary files to text files 
def makeExtensionArray(extensionInfile):
	with open(extensionInfile) as f:
		extensionArray=[float(line.rstrip('\n')) for line in f]
	return extensionArray
# takes text of the form PullOutConductanceBlock_<number>.txt as output by the \
# Python package for converting Igor binary files to text files
def makeConductanceMatrix(conductanceInfile):
	dataArray=np.zeros(NUM_LINES*ENTRIES_PER_LINE)
	with open(conductanceInfile) as f: 
		lines=[line.rstrip('\n').split('\t') for line in f][:NUM_LINES]
		for i in range(NUM_LINES):
			for j in range(ENTRIES_PER_LINE):
				dataArray[i*ENTRIES_PER_LINE+j]=float(lines[i][j])
	conductanceMatrix=np.reshape(dataArray,(NUM_LINES,len(dataArray)/NUM_LINES))
	return conductanceMatrix

# FUNCTIONS FOR FORMATTING DATA TO MAKE SENSIBLE PLOTS
# return the index of the first element of an input array whose value is less \
# than in input number
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

# truncates input conductanceArray and extensionArray so that, when plotted,
# they are scaled reasonably. Also reverses the extensionArray so that
# increasing value corresponds to increasing distance between tip and wafer
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

# MAKES PLOT OF DISTANCE FROM TIP VERSUS CONDUCTANCE
def generateTrace(extensionArray,conductanceArray,n,path,date):
	fig=plt.figure()
	ax=plt.subplot(111)
	ax.plot(extensionArray, conductanceArray)
	fig.savefig(path+'conductance_trace_'+date+'_'+str(n)+'.png')
	plt.close()

def makePath(date, number):
	path='./data/qc_data_'+date+'/plots/traces/'+str(number)+'/'
	if not os.path.exists(path):
		os.makedirs(path)
	return path

def main(eInfiles,cInfiles,date):
	for i in range(len(eInfiles)):
		cBlockNumber=cInfiles[i][-5]
		path=makePath(date,cBlockNumber)
		cMatrix=makeConductanceMatrix(cInfiles[i])
		eArray=makeExtensionArray(eInfiles[i])
		for j in range(len(cMatrix[1,:])):
			c,e=makeArraysForPlot(cMatrix[:,j],eArray,10,0.1)
			generateTrace(e,c,j+1,path,date)

main(args['e'],args['c'],args['d'])
