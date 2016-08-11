# Filename: Examine_data_v1.R
# 
# Author: Luke Miller  Aug 11, 2016
###############################################################################

# Make sure this Calib_data_process.R file is in the current R working directory
source("Calib_data_process.R")


# Filename with calibration data inside (.csv file)
fnameCalib = 'CalibrationFiles_Apr202016.csv'

# Put the name of the data folder here (both calib and real data file live here)
fdir = 'D:/Dropbox/Limpet_force_meter/'

# Load the calibration data file
calib = read.csv(paste0(fdir,fnameCalib))

# Use the function calibCoefficients to produce a set of regression coefficients
# that can be used to convert analogValue into force estimates (Newtons)
# This function is defined in the script Calib_data_process.R
calibCoefs = calibCoefficients(calib)

# To show the plots directly in R, instead of outputting to a png image file,
# comment out the png line and the dev.off() lines below, and just execute
# the plotSeparateAxesCalib() line in the middle. 
png(file='Calib_raw_data.png',height=2100,width=2100,res=300)
plotSeparateAxesCalib(calib) # function defined in Calib_data_process.R
dev.off()

# Show the calibration data for each axis altogether, with the regression line
# fit to the positive and negative direction data.
png(file='Calib_fits.png',height=2100,width=2100,res=300)
plotAxesCalib(calib) # function defined in Calib_data_process.R
dev.off()

#########################
# Load the raw field data file

fname = 'ForceMeterData_Apr26106.csv'
df = read.csv(paste0(fdir,fname))
# Convert milliseconds to seconds
df$Time.sec = df$Time.ms / 1000

#############################################
# Plot the raw field data
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
# Note the jump in the baseline value around 90 seconds into the run. Not sure
# what happened here, but it requires a different zero-offset from that point
# forward.
# Also note that the Z-axis shows no real signal, just random noise around 
# the baseline. It's either too stiff, or there's something else amiss here. The
# calibration data look fine, so it is responsive, even though the field data
# don't show any real forces. It's possible that this is a result of the 
# off-by-one error in the array addressing in the older version of the 
# Limpet_force_calibration.ino program, but I'm not sure. 

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
dfmatrix = as.matrix(df[,c('X.force.N.off','Y.force.N.off','Z.force.N.off')])
for (i in 1:nrow(dfmatrix)){
	# norm() function computes the norm. Needs to work on one row of data at
	# a time
	df$norm.N[i] = norm(dfmatrix[i],"2")	
}

###############################################
# Plot a small section of time using forces
startSec = 0 # define start time for plot
endSec = 30 # define end time for plot
ylims = c(-15,15)

png(file='1st_half_of_trial.png', height = 2100, width = 2100,res = 300)
par(mfrow= c(4,1), mar = c(4,4,2,1)) # make a 4-panel plot
# X-axis
plot(X.force.N.off~Time.sec,data=df[df$Time.sec > startSec & 
						df$Time.sec < endSec,], ylab = 'Force, N',
		type = 'l', ylim = ylims, main = 'X axis', xlab = 'Time, sec', las = 1,
		xaxs = 'i', xaxt = 'n')
axis(side = 1, at = pretty(df$Time.sec[df$Time.sec>startSec & 
								df$Time.sec < endSec], n = 10), 
		labels = pretty(df$Time.sec[df$Time.sec>startSec & 
								df$Time.sec < endSec], n = 10))
abline(v = pretty(df$Time.sec[df$Time.sec>startSec & 
								df$Time.sec < endSec], n = 10), 
		col='grey70',lty = 2)
grid(nx = NA, ny = NULL)
# Y-axis
plot(Y.force.N.off~Time.sec,data=df[df$Time.sec > startSec & 
						df$Time.sec < endSec,], ylab = 'Force, N',
		type = 'l', ylim = ylims, main = 'Y axis', xlab = 'Time, sec', las = 1,
		xaxs = 'i', xaxt = 'n')
axis(side = 1, at = pretty(df$Time.sec[df$Time.sec>startSec & 
								df$Time.sec < endSec], n = 10), 
		labels = pretty(df$Time.sec[df$Time.sec>startSec & 
								df$Time.sec < endSec], n = 10))
abline(v = pretty(df$Time.sec[df$Time.sec>startSec & 
								df$Time.sec < endSec], n = 10), 
		col='grey70',lty = 2)
grid(nx = NA, ny = NULL, col = 'grey70')
# Z-axis
plot(Z.force.N.off~Time.sec,data=df[df$Time.sec > startSec & 
						df$Time.sec < endSec,], ylab = 'Force, N',
		type = 'l', ylim = ylims, main = 'Z axis', xlab = 'Time, sec', las = 1,
		xaxs = 'i', xaxt = 'n')
axis(side = 1, at = pretty(df$Time.sec[df$Time.sec>startSec & 
								df$Time.sec < endSec], n = 10), 
		labels = pretty(df$Time.sec[df$Time.sec>startSec & 
								df$Time.sec < endSec], n = 10))
abline(v = pretty(df$Time.sec[df$Time.sec>startSec & 
								df$Time.sec < endSec], n = 10), 
		col='grey70',lty = 2)
grid(nx = NA, ny = NULL, col = 'grey70')

# Plot the norm'd force
plot(norm.N~Time.sec, data = df[df$Time.sec > startSec & 
						df$Time.sec < endSec,], 
		ylab = 'Force, N', type = 'l', 
		main = 'Euclidean norm (3 axes combined)',
		xlab = 'Time, sec', las = 1,
		xaxs = 'i', xaxt = 'n')
axis(side = 1, at = pretty(df$Time.sec[df$Time.sec>startSec & 
								df$Time.sec < endSec], n = 10), 
		labels = pretty(df$Time.sec[df$Time.sec>startSec & 
								df$Time.sec < endSec], n = 10))
abline(v = pretty(df$Time.sec[df$Time.sec>startSec & 
								df$Time.sec < endSec], n = 10), 
		col='grey70',lty = 2)
grid(nx = NA, ny = NULL, col = 'grey70')
dev.off()
####################################################################
# Produce a different offset for the time after the baseline shifted on all 
# the axes, starting just before second 100
xoffset2 = mean(df$X.force.N[df$Time.sec > 100 & df$Time.sec < 120])
df$X.force.N.off2 = df$X.force.N - xoffset2
yoffset2 = mean(df$Y.force.N[df$Time.sec > 100 & df$Time.sec < 120])
df$Y.force.N.off2 = df$Y.force.N - yoffset2
zoffset2 = mean(df$Z.force.N[df$Time.sec > 100 & df$Time.sec < 120])
df$Z.force.N.off2 = df$Z.force.N - zoffset2
# Calculate 2-norm for force for the 3 axes
# This estimates the Euclidean length of the 3 force vectors, essentially the
# overall force across the 3 axes, removing any positive/negative information
df$norm.N2 = NA
dfmatrix2 = as.matrix(df[,c('X.force.N.off2','Y.force.N.off2','Z.force.N.off2')])
for (i in 1:nrow(dfmatrix2)){
	# norm() function computes the norm. Needs to work on one row of data at
	# a time
	df$norm.N2[i] = norm(dfmatrix2[i],"2")	
}

###############################################
# Plot the later section of time using forces and the later offset value
startSec = 175 # define start time for plot
endSec = 275 # define end time for plot
ylims = c(-5,5)

png(file='2nd_half_of_trial.png', height = 2100, width = 2100,res = 300)
par(mfrow= c(4,1), mar = c(4,4,2,1)) # make a 4-panel plot
# X-axis
plot(X.force.N.off2~Time.sec,data=df[df$Time.sec > startSec & 
						df$Time.sec < endSec,], ylab = 'Force, N',
		type = 'l', ylim = ylims, main = 'X axis', xlab = 'Time, sec', las = 1,
		xaxt = 'n')
axis(side = 1, at = pretty(df$Time.sec[df$Time.sec>startSec & 
								df$Time.sec < endSec], n = 10), 
		labels = pretty(df$Time.sec[df$Time.sec>startSec & 
								df$Time.sec < endSec], n = 10))
abline(v = pretty(df$Time.sec[df$Time.sec>startSec & 
								df$Time.sec < endSec], n = 10), 
		col='grey70',lty = 2)
grid(nx = NA, ny = NULL, col = 'grey70')

# Y-axis
plot(Y.force.N.off2~Time.sec,data=df[df$Time.sec > startSec & 
						df$Time.sec < endSec,], ylab = 'Force, N',
		type = 'l', ylim = ylims, main = 'Y axis', xlab = 'Time, sec', las = 1,
		xaxt = 'n')
axis(side = 1, at = pretty(df$Time.sec[df$Time.sec>startSec & 
								df$Time.sec < endSec], n = 10), 
		labels = pretty(df$Time.sec[df$Time.sec>startSec & 
								df$Time.sec < endSec], n = 10))
abline(v = pretty(df$Time.sec[df$Time.sec>startSec & 
								df$Time.sec < endSec], n = 10), 
		col='grey70',lty = 2)
grid(nx = NA, ny = NULL, col = 'grey70')
# Z-axis
plot(Z.force.N.off2~Time.sec,data=df[df$Time.sec > startSec & 
						df$Time.sec < endSec,], ylab = 'Force, N',
		type = 'l', ylim = ylims, main = 'Z axis', xlab = 'Time, sec', las = 1,
		xaxt = 'n')
axis(side = 1, at = pretty(df$Time.sec[df$Time.sec>startSec & 
								df$Time.sec < endSec], n = 10), 
		labels = pretty(df$Time.sec[df$Time.sec>startSec & 
								df$Time.sec < endSec], n = 10))
abline(v = pretty(df$Time.sec[df$Time.sec>startSec & 
								df$Time.sec < endSec], n = 10), 
		col='grey70',lty = 2)
grid(nx = NA, ny = NULL, col = 'grey70')
# Plot the norm'd force
plot(norm.N2~Time.sec, data = df[df$Time.sec > startSec & 
						df$Time.sec < endSec,], 
		ylab = 'Force, N', type = 'l', 
		main = 'Euclidean norm (3 axes combined)',
		xlab = 'Time, sec', las = 1,
		xaxt = 'n')
axis(side = 1, at = pretty(df$Time.sec[df$Time.sec>startSec & 
								df$Time.sec < endSec], n = 10), 
		labels = pretty(df$Time.sec[df$Time.sec>startSec & 
								df$Time.sec < endSec], n = 10))
abline(v = pretty(df$Time.sec[df$Time.sec>startSec & 
								df$Time.sec < endSec], n = 10), 
		col='grey70',lty = 2)
grid(nx = NA, ny = NULL, col = 'grey70')
dev.off()


