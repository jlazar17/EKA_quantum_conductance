#! /usr/bin/python

import os
import argparse

parser=argparse.ArgumentParser()
parser.add_argument('-f', nargs='+',required=True,\
	help='[required] input files')
parser.add_argument('-d', required=True,\
    help='[required] Specify the date the data was taken on in the form \
     mm-dd-yyyy. This is used to generate the directory in which plots will be \
    saved')
args = vars(parser.parse_args())

def checkPathExists(path):
	if not os.path.exists(path):
		os.makedirs(path)

def makePath(date):
	path='./data/qc_data_'+date+'/text_files/'
	checkPathExists(path)
	return path

def findFileName(binaryFile):
	_=binaryFile[37:-3]
	fileName=_+'txt'
	return fileName

def makeTextFile(binaryFile,path):
	fileName=findFileName(binaryFile)
	print(fileName)
	filePath=path+fileName
	print(filePath)
	os.system('igorbinarywave.py -f '+binaryFile+' -o '+filePath)

def main(binaryFileArray,date):
	path=makePath(date)
	for i in binaryFileArray:
		makeTextFile(i,path)

main(args['f'],args['d'])
