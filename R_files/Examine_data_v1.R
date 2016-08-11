# Filename: Examine_data_v1.R
# 
# Author: Luke Miller  Aug 11, 2016
###############################################################################

# Make sure this Calib_data_process.R file is in the current R working directory
source("Calib_data_process.R")

# Put the name of the data folder here, and the D:/ or ~/ will be added next
fdir = 'Dropbox/Limpet_force_meter/'
# Determine which computer we're working on so we can put the appropriate
# file path prefix on the Dropbox file directory
platform = .Platform$OS.type
if (platform == 'unix'){
	prefixDrive = '~/'
} else if (platform == 'windows'){
	prefixDrive = 'D:/'
}
# Stick the prefix on the drive path
fdir = paste0(prefixDrive,fdir)

