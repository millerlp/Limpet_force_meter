# Filename: Calib_data_process.R
# Functions to import calibration data and estimate regression coefficients
# Also plotting tools
# Author: Luke Miller  Aug 11, 2016
###############################################################################

# Filename with calibration data inside (.csv file)
fname = 'CalibrationFiles_Apr202016.csv'
# Put the name of the data folder here, and the D:/ or ~/ will be added next
fdir = 'Dropbox/Limpet_force_meter/'

################################################################################
# Function loadCalibFile
# This function imports a calibration data file (.csv) with 4 columns of data
# that should be titled 'axis', 'direction', 'mass.grams', 'analogValue'.
# The input should be the file name and directory of the file
# The output will be a dataframe holding the data. 
loadCalibFile = function(fname = 'CalibrationFiles_Apr202016.csv' ,
		fdir = 'Dropbox/Limpet_force_meter/'){
	# Determine which computer we're working on so we can put the appropriate
	# file path prefix on the Dropbox file directory
	platform = .Platform$OS.type
	if (platform == 'unix'){
		prefixDrive = '~/'
	} else if (platform == 'windows'){
		prefixDrive = 'D:/'
	}
	
	fdir = paste0(prefixDrive,fdir)
	
	# Import the calibration data file
	calib = read.csv(paste0(fdir,fname))	
}
################################################################################


################################################################################
# Function plotSeparateAxesCalib
# A function to plot the individual positive and negative calibration data for
# each of the axes (X, Y, Z). This includes the zero values for a particular 
# axis in each plot of the positive or negative direction. Note that the Z 
# axis only has one direction (positive = downwards)
# Input a data frame produced by the function loadCalibFile() above

plotSeparateAxesCalib = function(calib = calib){
# Pull apart the separate axes calibration data, and include the zero values
	xpos = calib[calib$axis == 'X' & (calib$direction == 'zero' | 
						calib$direction == 'positive'),]
	xpos = droplevels(xpos)
	
	xneg = calib[calib$axis == 'X' & (calib$direction == 'zero' | 
						calib$direction == 'negative'),]
	xneg = droplevels(xneg)
	
	ypos = calib[calib$axis == 'Y' & (calib$direction == 'zero' | 
						calib$direction == 'positive'),]
	ypos = droplevels(ypos)
	
	yneg = calib[calib$axis == 'Y' & (calib$direction == 'zero' | 
						calib$direction == 'negative'),]
	yneg = droplevels(yneg)
	
	zneg = calib[calib$axis == 'Z' & (calib$direction == 'zero' | 
						calib$direction == 'negative'),]
	zneg = droplevels(zneg)

# Plot the raw data for each axis
	par(mfrow = c(3,2))
	#############################
# Positive X-axis
	plot(x = xpos$analogValue, y = xpos$mass.grams, type='p', 
			xlab = 'Analog count',
			ylab = 'Mass, g',
			main = 'X axis positive')
	mod = lm(mass.grams~analogValue, data = xpos)
	modSum = summary(mod)
	abline(mod)
	r2 = modSum$adj.r.squared
	mylabel = bquote(italic(R)^2 == .(format(r2, digits = 3)))
	legend('topleft', legend = mylabel, bty = 'n')
	###########################
# Negative X-axis
	plot(x = xneg$analogValue, y = xneg$mass.grams, type='p', 
			xlab = 'Analog count',
			ylab = 'Mass, g',
			main = 'X axis negative')
	mod = lm(mass.grams~analogValue, data = xneg)
	modSum = summary(mod)
	abline(mod)
	r2 = modSum$adj.r.squared
	mylabel = bquote(italic(R)^2 == .(format(r2, digits = 3)))
	legend('topright', legend = mylabel, bty = 'n')
	#######################
# Positive Y axis
	plot(x = ypos$analogValue, y = ypos$mass.grams, type='p', 
			xlab = 'Analog count',
			ylab = 'Mass, g',
			main = 'Y axis positive')
	mod = lm(mass.grams~analogValue, data = ypos)
	modSum = summary(mod)
	abline(mod)
	r2 = modSum$adj.r.squared
	mylabel = bquote(italic(R)^2 == .(format(r2, digits = 3)))
	legend('topleft', legend = mylabel, bty = 'n')
	###########################
# Negative Y-axis
	plot(x = yneg$analogValue, y = yneg$mass.grams, type='p', 
			xlab = 'Analog count',
			ylab = 'Mass, g',
			main = 'Y axis negative')
	mod = lm(mass.grams~analogValue, data = yneg)
	modSum = summary(mod)
	abline(mod)
	r2 =  modSum$adj.r.squared
	mylabel = bquote(italic(R)^2 == .(format(r2, digits = 3)))
	legend('topright', legend = mylabel, bty = 'n')
	#######################
# Z-axis
	plot(x = zneg$analogValue, y = zneg$mass.grams, type='p', 
			xlab = 'Analog count',
			ylab = 'Mass, g',
			main = 'Z axis negative')
	mod = lm(mass.grams~analogValue, data = zneg)
	modSum = summary(mod)
	abline(mod)
	r2 =  modSum$adj.r.squared
	mylabel = bquote(italic(R)^2 == .(format(r2, digits = 3)))
	legend('topright', legend = mylabel, bty = 'n')	
}  # end of plotSeparateAxesCalib

#############################################################################
# Produce a list of calibration coefficients for the three axes. 
# The output will be a list with entries X, Y, Z, each containing a field
# 'intercept','slope', and 'R2' (R-squared)
# The regression coefficients intercept and slope will convert an input 
# analogValue into an estimate of Force (Newtons), with a positive or negative
# value depending on the direction of the force application. 

calibCoefficients = function(calib = calib){
	#########################################
	xax = calib[calib$axis == 'X',]
# Convert mass into force (Newtons) by multiplying by gravity acceleration
	xax$Force.N = (xax$mass.grams/1000) * 9.8066
# Make negative-direction values into negative forces
	xax$Force.N[xax$direction == 'negative'] = -1 * 
			xax$Force.N[xax$direction=='negative']
	#########################################
# Y-axis all data, converted to force in Newtons
	yax = calib[calib$axis == 'Y',]
# Convert mass into force (Newtons) by multiplying by gravity acceleration
	yax$Force.N = (yax$mass.grams/1000) * 9.8066
# Make negative-direction values into negative forces
	yax$Force.N[yax$direction == 'negative'] = -1 * 
			yax$Force.N[yax$direction=='negative']	
	############################################
# Z-axis all data, converted to force in Newtons
	zax = calib[calib$axis == 'Z',]
# Convert mass into force (Newtons) by multiplying by gravity acceleration
	zax$Force.N = (zax$mass.grams/1000) * 9.8066
# Make negative-direction values into negative forces
	zax$Force.N[zax$direction == 'negative'] = -1 * 
			zax$Force.N[zax$direction=='negative']
	################################################
	# Fit regressions for each axis
	modX = lm(Force.N~analogValue, data = xax)
	modXSum = summary(modX)
	# Extract intercept, slope, R^2 of regression
	myinterceptX = coef(modXSum)[1,1]
	myslopeX = coef(modXSum)[2,1]
	r2X =  modXSum$adj.r.squared
	################
	modY = lm(Force.N~analogValue, data = yax)
	modXYSum = summary(modY)
	# Extract intercept, slope, R^2 of regression
	myinterceptY = coef(modYSum)[1,1]
	myslopeY = coef(modYSum)[2,1]
	r2Y =  modYSum$adj.r.squared
	################
	modZ = lm(Force.N~analogValue, data = zax)
	modXZSum = summary(modZ)
	# Extract intercept, slope, R^2 of regression
	myinterceptZ = coef(modZSum)[1,1]
	myslopeZ = coef(modZSum)[2,1]
	r2Z =  modZSum$adj.r.squared
	###############################################
	# Combine data into an output list
	output = list(X = data.frame(intercept = myinterceptX, slope = myslopeX, 
					R2 = r2X),
			Y = data.frame(intercept = myinterceptY, slope = myslopeY,R2 = r2Y),
			Z= data.frame(intercept = myinterceptZ, slope = myslopeZ,R2 = r2Z))
}
################################################################################


################################################################################
# Function plotAxesCalib
# This function will produce three plots (one per axis X, Y, Z) to show the 
# calibration data and regression fit to those data. The regression will use
# analogValue as the x-axis, and force in newtons (converted from mass in grams)
# for the y-axis. 
# Input should be a data frame of calibration data, with a column 'axis', 
# 'direction', 'mass.grams', and 'analogValue', as produced by the 
# loadCalibFile() function above. 

plotAxesCalib = function(calib = calib){
	######################################################
	# Combine all data for a single axis into one set, convert to force units,
	# estimate regression fit. 
	######################################################
	# X-axis all data, converted to force in Newtons
	par(mfrow=c(3,1))
	xax = calib[calib$axis == 'X',]
	# Convert mass into force (Newtons) by multiplying by gravity acceleration
	xax$Force.N = (xax$mass.grams/1000) * 9.8066
	# Make negative-direction values into negative forces
	xax$Force.N[xax$direction == 'negative'] = -1 * 
			xax$Force.N[xax$direction=='negative']
	
	plot(x = xax$analogValue, y = xax$Force.N,las = 1,
			xlab = 'Analog Count',
			ylab = 'Force, N',
			main = 'X axis')
	# Fit regression
	modX = lm(Force.N~analogValue, data = xax)
	modXSum = summary(modX)
	abline(modX)
	myinterceptX = coef(modXSum)[1,1]
	myslopeX = coef(modXSum)[2,1]
	r2 =  modXSum$adj.r.squared
	
	# Start by making an expression vector to hold the 2 lines of output:
	rp = vector('expression',2)
	
	# Write the first line, which will give R-squared and 
	# pull the value from the data frame wt.fits
	# The double == prints an equal sign when used inside expression()
	rp[1] = substitute(expression(italic(R)^2 == MYVALUE),
			list(MYVALUE = format(r2,digits = 4)))[2]
	
	# Write the 2nd line, which will pull 2 values from data frame wt.fits:
	rp[2] = substitute(expression(italic(Y) == MYVALUE2 + MYVALUE3*x),
			list(MYVALUE2 = format(myinterceptX, digits = 3),
					MYVALUE3 = format(myslopeX,digits = 3)))[2]
	# Finally, simply plot with legend() function:
	legend('topleft', legend = rp, bty = 'n')
	
	############################################
	# Y-axis all data, converted to force in Newtons
	yax = calib[calib$axis == 'Y',]
	# Convert mass into force (Newtons) by multiplying by gravity acceleration
	yax$Force.N = (yax$mass.grams/1000) * 9.8066
	# Make negative-direction values into negative forces
	yax$Force.N[yax$direction == 'negative'] = -1 * 
			yax$Force.N[yax$direction=='negative']
	
	plot(x = yax$analogValue, y = yax$Force.N,las = 1,
			xlab = 'Analog Count',
			ylab = 'Force, N',
			main = 'Y axis')
	# Fit regression
	modY = lm(Force.N~analogValue, data = yax)
	modYSum = summary(modY)
	abline(modY)
	myinterceptY = coef(modYSum)[1,1]
	myslopeY = coef(modYSum)[2,1]
	r2 =  modYSum$adj.r.squared
	
	# Start by making an expression vector to hold the 2 lines of output:
	rp = vector('expression',2)
	
	# Write the first line, which will give R-squared and 
	# pull the value from the data frame wt.fits
	# The double == prints an equal sign when used inside expression()
	rp[1] = substitute(expression(italic(R)^2 == MYVALUE),
			list(MYVALUE = format(r2,digits = 4)))[2]
	
	# Write the 2nd line, which will pull 2 values from data frame wt.fits:
	rp[2] = substitute(expression(italic(Y) == MYVALUE2 + MYVALUE3*x),
			list(MYVALUE2 = format(myinterceptY, digits = 3),
					MYVALUE3 = format(myslopeY,digits = 3)))[2]
	# Finally, simply plot with legend() function:
	legend('topleft', legend = rp, bty = 'n')
	
	############################################
	# Z-axis all data, converted to force in Newtons
	zax = calib[calib$axis == 'Z',]
	# Convert mass into force (Newtons) by multiplying by gravity acceleration
	zax$Force.N = (zax$mass.grams/1000) * 9.8066
	# Make negative-direction values into negative forces
	zax$Force.N[zax$direction == 'negative'] = -1 * 
			zax$Force.N[zax$direction=='negative']
	
	plot(x = zax$analogValue, y = zax$Force.N, las = 1,
			xlab = 'Analog Count',
			ylab = 'Force, N',
			main = 'Z axis')
	# Fit regression
	modZ = lm(Force.N~analogValue, data = zax)
	modZSum = summary(modZ)
	abline(modZ)
	myinterceptZ = coef(modZSum)[1,1]
	myslopeZ = coef(modZSum)[2,1]
	r2 =  modZSum$adj.r.squared
	
	# Start by making an expression vector to hold the 2 lines of output:
	rp = vector('expression',2)
	
	# Write the first line, which will give R-squared and 
	# pull the value from the data frame wt.fits
	# The double == prints an equal sign when used inside expression()
	rp[1] = substitute(expression(italic(R)^2 == MYVALUE),
			list(MYVALUE = format(r2,digits = 4)))[2]
	
	# Write the 2nd line, which will pull 2 values from data frame wt.fits:
	rp[2] = substitute(expression(italic(Y) == MYVALUE2 + MYVALUE3*x),
			list(MYVALUE2 = format(myinterceptZ, digits = 3),
					MYVALUE3 = format(myslopeZ,digits = 3)))[2]
	# Finally, simply plot with legend() function:
	legend('topright', legend = rp, bty = 'n')	
}
###############################################################################




