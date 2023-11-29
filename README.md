# Ant-Trail-Following
Matlab software that analyses videos of an ant trail following experiment

ConvertCompressTrailVideos.m
% Converts all .mp4 videos in a folder into Matlab XYT arrays, compresses them by a given factor to reduce size, and saves them into .mat files

TrailFollowingVideoAnalysis.m
% 1) Load a Matlab XYT array produced by ConvertCompressTrailVideos.m
% 2) Select an ROI covering the experimental area in a GUI
% 3) Select the Trail line in that GUI
% 4) Find ant position in the first frame via intensity thresholding
% 5) Find and correct trail intensity and position frame-by-frame
% 6) Plot intensities and positions of ant and trail line over time
% 7) Quantitative analysis of distance walked and distance walked on trail line
% 8) Plot and the ant trace, distance over time, and direction distribution
% 9) Write quantitative results into database file
% 10) Make a movie labelling the ant trace

