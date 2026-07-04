# Tree Measurements Using Terrestrial Laser Scanning Point Clouds

## Project Overview

This exercise uses a semantically segmented terrestrial laser scanning (TLS) point cloud to reconstruct the 3D structure of an individual tree and estimate core tree attributes from stem and crown points. The workflow includes stem slicing, circle fitting for diameter estimation, taper-curve construction, outlier removal, spline smoothing, and stem-volume estimation. 

## Objectives

- Reconstruct individual-tree structure from TLS point clouds.
- Estimate DBH, tree height, crown ratio, and stem volume.
- Build a taper curve from stem diameter measurements.
- Compare smoothing parameters and measurement intervals.
- Estimate log-wood percentage from the taper curve. 

## Data

- `pointcloud.laz`
- R script for TLS analysis
- TLS point cloud with semantic classes:
  - stem
  - crown 

## Methodology

### Point-cloud preparation
The point cloud was loaded into `lidR`, inspected, and split into stem and crown subsets based on classification. Basic summary statistics and visualizations were used to check data quality. 

### Tree attribute extraction
A horizontal slice around breast height was used to fit a circle and estimate DBH. Additional slices were taken along the stem to derive diameter measurements at multiple heights and to reconstruct a taper curve. Tree height was computed from the vertical extent of the point cloud, and crown ratio was calculated from crown length relative to total height. 

### Taper-curve smoothing and sensitivity analysis
Diameter measurements were cleaned by comparing each observation with the mean of its nearest neighbours. The taper curve was then smoothed with cubic splines, and the effect of smoothing parameters and measurement intervals was explored to assess stability in DBH and stem-volume estimates. 

### Volume estimation
Stem volume was calculated using the Huber formula by summing cylindrical segments along the taper curve. Log-wood volume was estimated by restricting the calculation to stem sections above a diameter threshold. 

## Main Outputs

- Tree height and crown ratio
- DBH and diameter at multiple stem heights
- Smoothed taper curve
- Stem volume estimate
- Log-wood percentage
- Comparison of taper curves under different smoothing settings 

## Key Results

The diary reports the following task-1 values: **1,865,308 total points**, **23% stem points**, **18.38 m tree height**, **71% crown ratio**, **21.4617 cm DBH**, **14.5 cm diameter at 50% height**, **21.79 cm diameter at stem reconstruction top height**, **320.4958 dm³ stem volume**, and **77.75% log-wood percentage**. The analysis used a 20 cm measurement interval and a smoothing parameter of 0.5 as the main configuration. 

## Skills Demonstrated

- TLS point-cloud processing
- Semantic segmentation of stem and crown points
- Circle fitting for diameter estimation
- Stem slicing and taper-curve reconstruction
- Outlier detection using nearest neighbours
- Spline smoothing and interpolation
- Stem-volume estimation
- Log-wood estimation
- Sensitivity analysis of smoothing and measurement interval 
