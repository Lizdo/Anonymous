#! /usr/bin/python
### Convert Audio for iPhone Project
import os.path
import subprocess
import shutil

def main():
	dir = '/Users/Liz/Dropbox/Projects/BoardGame/Sound'
	files = os.listdir(dir)
	os.chdir(dir)
	for file in files:
		if file.endswith('m4a'):
			newfile = file.replace('m4a','caf')
			print(newfile)
			commandlist = ['/usr/bin/afconvert', '-f', 'caff', '-d', 'LEI16',file,newfile]
			subprocess.call(commandlist)
			os.remove(file)
	
if __name__ == '__main__':
	main()