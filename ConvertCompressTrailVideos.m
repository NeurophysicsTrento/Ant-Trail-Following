%% Compress all .mp4 videos in a folder and save them as .mat files
clear all;close all
inpath='X:\xxx\';% enter video folder her
compfac=0.25;%compresses by 1/compfac in each dimension, so 0.25->64
outpath='X:\yyy\'; %enter output folder
dirlist=dir([inpath,'*.MP4']);%select only MP4
for d=1:length(dirlist) % directories
    tstart=tic; %start timertic
    vidobj = VideoReader([inpath dirlist(d).name]);
    nFrames = vidobj.NumberOfFrames;
    %rawFrames = vidobj.NumberOfFrames; %restrict videos to 3 min = 180s
    %nFrames=min(rawFrames,180*framerate); %convert only first 3 min
    framerate=vidobj.FrameRate;
    nbytes = fprintf('file:0/%d frame:0/%d',length(dirlist),nFrames);
    for f=1:nFrames
        fprintf(repmat('\b',1,nbytes))
        nbytes = fprintf('file:%d/%d frame:%d/%d\n',d,length(dirlist),f,nFrames);
        frame=read(vidobj,f);
        g(:,:,f)=0.2989*frame(:,:,1)+0.5870*frame(:,:,2)+0.1140*frame(:,:,3);%convert rgb in gray
    end
    comp=0.25;%compression factor
    gbin = single(imresize3(g,compfac)); % Data binning, last argument compression factor
    save([outpath dirlist(d).name(1:end-4) '.mat'],'gbin','framerate','compfac','-v7.3')
    tend=toc(tstart);
    display(sprintf('\b converted in: %.1f s.\n',tend));
    clearvars -except inpath outpath compfac dirlist tstart
end
