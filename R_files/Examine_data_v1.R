# Filename: Examine_data_v1.R
# 
# Author: Luke Miller  Aug 11, 2016
###############################################################################

# Make sure this Calib_data_process.R file is in the current R working directory
source("Calib_data_process.R")


# Filename with calibration data inside (.csv file)
fnameCalib = 'CalibrationFiles_Apr202016.csv'

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

calib = read.csv(paste0(fdir,fnameCalib))

calibCoefs = calibCoefficients(calib)

#########################
# Load the raw field data file

fname = 'ForceMeterData_Apr26106.csv'
df = read.csv(paste0(fdir,fname))
# Convert milliseconds to seconds
df$Time.sec = df$Time.ms / 1000

#############################################
# Plot the raw data
par(mfrow = c(3,1))
plot(JOY_X_signal~Time.sec, data = df, type = 'l', las = 1,
		xlab = 'Time, s', 
		ylab = 'X-axis raw counts')
plot(JOY_Y_signal~Time.sec, data = df, type = 'l', las = 1,
		xlab = 'Time, s', 
		ylab = 'Y-axis raw counts')
plot(BEAM_Z_signal~Time.sec, data = df, type = 'l', las = 1,
		xlab = 'Time, s', 
		ylab = 'Z-axis raw counts')
# Note the jump in the 'zero' value around 90 seconds into the run. Not sure
# what happened here, but it probably throws the calibration off after that 
# point.
# Also note that the Z-axis shows no real signal, just random noise around 
# the baseline. It's either too stiff, or there's something else amiss here. The
# calibration data look fine, so it is responsive. 

##############################################
# Convert raw count data to forces
df$X.force.N = (df$JOY_X_signal * calibCoefs$X$slope) + calibCoefs$X$intercept
df$Y.force.N = (df$JOY_Y_signal * calibCoefs$Y$slope) + calibCoefs$Y$intercept
df$Z.force.N = (df$BEAM_Z_signal * calibCoefs$Z$slope) + calibCoefs$Z$intercept

##################
# Calculate an offset from 'zero' for each axis using the first few samples
# where there is presumably no force being exerted
xoffset = mean(df$X.force.N[1:100])
df$X.force.N.off = df$X.force.N - xoffset
yoffset = mean(df$Y.force.N[1:100])
df$Y.force.N.off = df$Y.force.N - yoffset
zoffset = mean(df$Z.force.N[1:100])
df$Z.force.N.off = df$Z.force.N - zoffset
# Calculate 2-norm for force for the 3 axes
# This estimates the Euclidean length of the 3 force vectors, essentially the
# overall force across the 3 axes, removing any positive/negative information
df$norm.N = NA
dfmatrix = as.matrix(df[,9:11])
for (i in 1:nrow(dfmatrix)){
	# norm() function computes the norm. Needs to work on one row of data at
	# a time
	df$norm.N[i] = norm(dfmatrix[i],"2")	
}

###############################################
# Plot a small section of time using forces
startSec = 1
endSec = 30
ylims = c(-15,15)
par(mfrow= c(4,1))
plot(X.force.N.off~Time.sec,data=df[df$Time.sec > startSec & 
						df$Time.sec < endSec,], ylab = 'Force, N',
		type = 'l', ylim = ylims, main = 'X axis', xlab = 'Time, sec', las = 1)
abline(h = 0, lty = 2)
plot(Y.force.N.off~Time.sec,data=df[df$Time.sec > startSec & 
						df$Time.sec < endSec,], ylab = 'Force, N',
		type = 'l', ylim = ylims, main = 'Y axis', xlab = 'Time, sec', las = 1)
abline(h = 0, lty = 2)
plot(Z.force.N.off~Time.sec,data=df[df$Time.sec > startSec & 
						df$Time.sec < endSec,], ylab = 'Force, N',
		type = 'l', ylim = ylims, main = 'Z axis', xlab = 'Time, sec', las = 1)
abline(h = 0, lty = 2)
##################
# Plot the norm'd force
plot(norm.N~Time.sec, data = df[df$Time.sec > startSec & 
						df$Time.sec < endSec,], 
		ylab = 'Force, N', type = 'l', main = 'Euclidean norm (3 axes combined)',
		xlab = 'Time, sec', las = 1)
abline(h = 0, lty = 2)



