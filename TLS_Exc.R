# # Remove variables and restart R-session
rm(list=ls())
# 
# # Install packages
install.packages("lidR")
install.packages('circular')
; install.packages('stats');install.packages('RANN');
require(lidR)
require(tidyverse)
require(circular)
require(stats);
require(RANN)
# set working directory
setwd("F:/krish/Exercise 6")

# Read TLS data
pc<-readLAS("pointcloud.laz")
#names(pc)

# View some statistics
summary(pc)

# Visualize the point cloud
plot(pc, axis=TRUE)

# Color by classification
plot(pc, color='Classification', axis=TRUE)

# Extract points by classification
stem<-pc[pc$Classification==2,] # stem points are assigned a classification 2
crown<-pc[pc$Classification==4,] # crown points are assigned a classification 4

#str(stem)
#summary(stem)
#stemPoint <- stem$Classification
#stem %>% count()
#Percentage <- (stem$X)/(pc$X)


# Visualize stem
plot(stem)

# Take a horizontal slice out of the stem point cloud
slice<-stem[stem$Z<1.35 & stem$Z>1.25,]
summary(slice)
plot(slice)

half_h<- treeheight/2 #define treeheight first, which is in line 63.
slice<-stem[stem$Z<half_h+0.1 & stem$Z>half_h-0.1,] #to get the slice at 50% height of tree.
summary(slice)

# fit a circle into the point cloud slice
circle<-lsfit.circle(slice$X, slice$Y)

# extract circle parameters
circlecoef<-circle$coefficients

#compute stem diameter = 2 * stem radius
diam<-as.numeric(2*circlecoef[1])

# Compute tree height as a difference between min and max return heights
treeheight<-max(pc$Z) - min(pc$Z)
summary(crown)
crownlength  <- max(crown$Z)- min(crown$Z)
crownratio <- crownlength/treeheight #to calculate the crown ratio.

### TAPER CURVE ESTIMATION ###
  slice<-stem[stem$Z<1.2 & stem$Z>1.1,] #to measure the dia at some point.
  # define starting height
  bottom_h <- 0.2         #should be more than 0, usually at stump height.
  # define ending height
  top_h <- max(stem$Z)
  # define measurement interval
  meas_interval <- 0.20        #for computational method it should be as low as possible
  # define height of the slice
  slice_h <- 0.15
  # create list of measurement heights
  hlist <- seq(from = bottom_h, to = top_h, by = meas_interval)
  # create an empty vector for diameters
  diamlist <- c() # for dia that are going to be measure
  
  # Loop through the measurement heights
  for (h in hlist) {
    #h<- 1.2
    # extract upper height threshold for diameter measurement
    top_h <- h + slice_h/2
    
    # extract lower height threshold for diameter measurement
    bottom_h <- h - slice_h/2
    
    # obtain a slice from the stem point cloud
    slice<-stem[stem$Z<top_h & stem$Z>bottom_h,]
    
    #plot(slice) to visualize the results
    
    # fit a circle into the point cloud slice
    circle<-lsfit.circle(slice$X, slice$Y)
    
    # extract circle parameters
    circlecoef<-circle$coefficients
    
    # compute stem diameter = 2 * stem radius
    diam<-as.numeric(2*circlecoef[1])
    
    
    # store the diameter measurement
    diamlist <- append(diamlist,diam)
    
  }
  
  # Plot the observations
  plot(hlist,diamlist,xlab = 'height', ylab = 'diameter')

## Detect and remove outlier observations by comparing diameters to the mean of three closest observation
  # combine the measurements as a list
  diamlist <- cbind(hlist,diamlist)

  # find nearest neighbours for each measurement
  nn <- nn2(diamlist,k=4)
  # create an empty vector for diameter differences
  diamdevlist <- c()
  # loop through each observation
  for (i in 1:nrow(diamlist)) {
    # get one diameter measurement at a time
    measurement <- diamlist[i,2]
    # extract its neighbour diameter measurements
    n_ids <- nn$nn.idx[i,2:4]
    neighbors <- diamlist[n_ids,2]
    # compute difference
    diamdev <- measurement - mean(neighbors)
    # store the diameter difference into a vector
    diamdevlist <- append(diamdevlist,diamdev)
  }
  
  # Consider outliers as diameters deviating enough from the mean of its neighbours
  diamlist_olr <- diamlist[abs(diamdevlist) < 0.03,]
  
  # Plot the cleaned data
  plot(diamlist_olr[,1],diamlist_olr[,2],xlab = 'height', ylab = 'diameter')

## Obtain a taper curve
# Add an observation from the treetop where diameter is 0
diamlist_olr <- rbind(diamlist_olr,c(treeheight,0))
#again plot it.

# Generate height interval vector
bottom_h<- 0.2
hlist_int <- seq(from = bottom_h, to = treeheight, by = 0.1)


# Apply cubic spline smoothing and interpolate across the height intervals
  smoothpar <- 0.5 # smoothing parameter (0,1]
  pp <- predict(smooth.spline(diamlist_olr[,1],diamlist_olr[,2],spar = smoothpar),hlist_int)
  diam_int <- pp$y
  
  # Visualize
  plot(diamlist_olr[,1],diamlist_olr[,2],xlab = 'height [m]',ylab = 'diameter [m]')
  lines(hlist_int,diam_int,col = 'red')
  
      # Compare different smoothing parameter values
      smoothpar1 <- 0.8
      smoothpar2 <- 0.2
      
      pp1 <- predict(smooth.spline(diamlist_olr[,1],diamlist_olr[,2],spar = smoothpar1),hlist_int)
      diam_int1 <- pp1$y
      pp2 <- predict(smooth.spline(diamlist_olr[,1],diamlist_olr[,2],spar = smoothpar2),hlist_int)
      diam_int2 <- pp2$y
      
      plot(diamlist_olr[,1],diamlist_olr[,2],xlab = 'height [m]',ylab = 'diameter [m]')
      lines(hlist_int,diam_int1,col = 'red')
      lines(hlist_int,diam_int2,col = 'blue')
      legend(1,0.1,legend = c('p = 0.5','p = 0.2'),col=c("red", "blue"),lty = 1)

# Bind the height intervals and interpolated and smoothed diameters as a taper curve
tapercurve <- cbind(hlist_int,diam_int)

# Obtain a diameter at particular height
dbh <- tapercurve[tapercurve[,1] == 1.3,2] #13.4 for recontruction height diameter

## Stem volume estimation using Huber formula
  # Loop through the taper curve
  stemvolume <- 0
  for (i in 2:nrow(tapercurve)) {
    # diameter at the bottom of the cylinder
    d_lower <- tapercurve[i-1,2]
    # diameter at the top of the cylinder
    d_upper <- tapercurve[i,2]
    # height of the cylinder
    h_int <- 0.1          #tapercurve[i,1] - tapercurve[i-1,1]
    # volume of the cylinder: pi * r^2 * h
    vol <- pi * (mean(d_upper,d_lower)/2)^2 * 0.1
    # Sum the volume of cylinders so far
    stemvolume <- stemvolume + vol;
  }
  # Extract stem volume in litres/dm3
  stemvolume*1000

## Log wood volume estimation
  # set diameter threshold
  diamthreshold <- 0.15
  # loop through the taper curve
  stemvolume_log <- 0
  for (i in 2:nrow(tapercurve[tapercurve[,2] > diamthreshold,])) {
    d_lower <- tapercurve[i-1,2]
    d_upper <- tapercurve[i,2]
    h_int <- tapercurve[i,1] - tapercurve[i-1,1]
    vol <- pi * (mean(d_upper,d_lower)/2)^2 * h_int
    stemvolume_log <- stemvolume_log + vol;
  }
  # Extract stem volume in litres/dm3
  stemvolume_log*1000
  
  stemvolume_log/stemvolume
