%% 1) Load compressed video
clear all;close all
inpath='X:\xxx\'; %folder containing matlab XYT array after video conversion
infile='MVI_2524'% .mat file name containing matlab XYT
outpath='Y:\yyy\'; %labelled video output path
outfile=infile; % labelled video oputput filename
databasefile='video_data'; %data base file name to add numerical analysis parameters
trailcorrection='off'; %switch on/off trail motion correction
load([inpath infile])
nFrames = size(gbin,3); %Frame number to be analysed, change to 1125 to restict to 3 min

%% 2) ROI selection GUI
% cut upper and lower dark edges with a few pixels extra margin
% regions on side doesn't matter
% if less frames have to be analysed: nFrames=500;
set(0,'Units','pixels') 
scnsize = get(0,'ScreenSize');%[1 1 width height]
figure('Position',[scnsize(3)/2-20,scnsize(4)/2-200,scnsize(3)/2,scnsize(4)/2])%[left bottom width height]
colormap gray
imagesc(gbin(:,:,1))
title(['Click to upper left and lower right corner points of the ROI, then press enter'])
% choose ROI, sort edge coordinates
[xsub,ysub]=ginput;
xsubt=round(xsub(end-1:end)');
ysubt=round(ysub(end-1:end)');
if xsubt(2)<xsubt(1)
    xsubt=fliplr(xsubt);
end
if ysubt(2)<ysubt(1)
    ysubt=fliplr(ysubt);
end
gbin([1:ysubt(1) ysubt(2):end],:,:)=[]; %cuts upper part
gbin(:,[1:xsubt(1) xsubt(2):end],:)=[]; %cuts left part
imagesc(gbin(:,:,1)) %plot ROI

%% 3) Trail line selection via GUI
% if the fit shows errors, position points further away from tube and edge
set(0,'Units','pixels') 
scnsize = get(0,'ScreenSize');%[1 1 width height]
figure('Position',[scnsize(3)/2-20,scnsize(4)/2-200,scnsize(3)/2+20,scnsize(4)/2+200])%[left bottom width height]
% define trail on first image
imagesc(gbin(:,:,1)), colormap gray
title(['Click on left and on right end of the trail, then press enter!'])
[xin,yin]=ginput; %waiting for input
xint=round(xin(end-1:end)'); %select only last 2 clicks
yint=round(yin(end-1:end)');
hold on
line(xint,yint) %plot selected trail line
hold off

%% 4) Find ant position in the first frame via intensity thresholding
% ant position in time
[minant,maxpos]=min(gbin,[],[1 2],'linear'); %intensity and linear position of the ant
[anty,antx,time]=ind2sub(size(gbin,[1 2]),maxpos); %x,y position ant
% rough estimate of trail intensities
[miny1,liny1]=min(gbin(:,xint(1),:)); %start point
[miny2,liny2]=min(gbin(:,xint(2),:)); %end point
antthresh=min(minant)+60; %upper intensity limit for ant
tposthresh=5; %trial position jump limit
miny1thresh=mean(miny1)-20; %trial intensity jump limit
miny2thresh=mean(miny2)-20; %trial intensity jump limit

%% 5) Find and correct trail intensity and position frame by frame
len=xint(2)-xint(1);%line length    
for t=1:nFrames
    %redefine endpoints from minimum along y axis at x of initial endpoints
    [miny1(t),y1(t)]=min(gbin(:,xint(1),t)); %start point
    [miny2(t),y2(t)]=min(gbin(:,xint(2),t)); %end point
    y1raw(t)=y1(t);y2raw(t)=y2(t); %copy raw data points for monitoring
    miny1raw(t)=miny1(t);miny2raw(t)=miny2(t);
    %correct line endpoints when position changes too fast
    %set ant position back to previous frame
    if t==1 || strcmp(trailcorrection,'off'); %no correction or first frame, set to initial values
        y1(t)=yin(end-1);
        miny1(t)=gbin(yint(1),xint(1),1);
        y2(t)=yin(end);
        miny2(t)=gbin(yint(2),xint(2),1);
    elseif miny1(t)<miny1thresh && abs(y1(t)-y1(t-1))> tposthresh; %y1 move above threshhold
        y1(t)=y1(t-1);%set to previous frame values
        miny1(t)=miny1(t-1);
    elseif miny2(t)<miny2thresh && abs(y2(t)-y2(t-1))> tposthresh; %y2 move above threshhold 
        y2(t)=y2(t-1);%set to previous frame values
        miny2(t)=miny2(t-1);
    end
    % define line with corrected parameters
    liney(1:len)=y1(t)+(1:len).*(y2(t)-y1(t))/len; %y parametrization
    linex(1:len)=xint(1)+(1:len); %xy parametrization
    [minevd,xpix] = min(abs(antx(t) - linex)); %x on trail closest to ant
    traily(t) = liney(xpix); %y on trail for x of ant
    % check if ant is in image
    if minant(t) > antthresh, % no ant, intensity above threshold
        if t==1 % first trial no correction
            antx(t)=linex(1);anty(t)=liney(1); %set to upper left point
            traily(t)=liney(1); %set to manual set line
        else % correct to last position inside
            antx(t)=antx(t-1); %x to last frame
            anty(t)=anty(t-1); %y to upper edge         
        end
    end
end

%% 6) Plot Intensities and Positions of ant and trail line over time
% ant and trail position should not jump drastically
% if yes change thresholds in 6
figure('Name','Test plots')
% Various Intensity signals to test via continuity if ants and trail lines
% are captured
subplot(211)
hold on
plot(squeeze(minant),'r') %plot ant signal intensity (threshold below)
line([1,nFrames],[antthresh,antthresh],'Color','red','LineStyle','--')
plot(squeeze(miny1raw),'y') %plot original trail start point intensity (threshold below)
plot(squeeze(miny1),'g') %plot corrected trail start point intensity
line([1,nFrames],[miny1thresh,miny1thresh],'Color','green','LineStyle','--')
plot(squeeze(miny2raw),'c') %plot original trail end point intensity (threshold below)
plot(squeeze(miny2),'b') %plot corrected trail end point intensity
line([1,nFrames],[miny2thresh,miny2thresh],'Color','blue','LineStyle','--')
hold off
legend('ant','antth','miny1','miny1thresh','miny1corr','miny2','miny2thresh','miny2corr')
ylim([0 250]);ylabel('Intensity')
title('Check ant and trail line intensities')
% Plot ant and trail line position
subplot(212)
hold on,plot(squeeze(anty)),plot(squeeze(traily)),hold off
legend('anty','traily')
ylabel('Y position')
title('Ant and trail positions')

%% 7) Quantitative analysis
dist=abs(squeeze(anty)-squeeze(traily)');%Distance over time
totdist=sum(dist);%Total Distance over all frames
meandist=mean(dist);%Mean Distance per frame
stddist=std(dist);%Std
%step sizes between frames
stepsizes=squeeze(sqrt((antx(2:end)-antx(1:end-1)).^2+(anty(2:end)-anty(1:end-1)).^2));
velocity=stepsizes*framerate; %vector pixels/s
meanvelocity=mean(velocity); %pixels/s
stdvelocity=std(velocity); %pixels/s
totalpath=sum(stepsizes);
% time for which distance from the trail is <=2 pixels
timeontrail=sum(dist<=2)/framerate/4; %s factor 4 because videos have been previously compressed
timeofftrail=sum(dist>2)/framerate/4; %s
pathontrail=sum((dist<=2).*[0;stepsizes]); %pixels
pathofftrail=sum((dist>2).*[0;stepsizes]); %pixels 
% output on screen
head=sprintf('%15s %9s %7s %7s %7s %11s %12s %11s %12s\r\n',...
            'filename','meandist','stddist','meanvel','stdvel','pathontrail','pathofftrail','timeontrail','timeofftrail');
out=sprintf('%15s %9.2f %7.2f %7.2f %7.2f %11.2f %12.2f %11.2f %12.2f\r\n',...
            outfile,meandist,stddist,meanvelocity,stdvelocity,pathontrail,pathofftrail,timeontrail,timeofftrail);   
disp([head,out])
% direction distribution
dirs=squeeze(atan2(anty(2:end)-anty(1:end-1),antx(2:end)-antx(1:end-1)));
runs=~squeeze(and(anty(2:end)==anty(1:end-1),antx(2:end)==antx(1:end-1))); %0 for no motion
nandirs=dirs./runs;  %corrected for no motion, becomes NaN
%% 8) Plot and trace, distance over time, and direction distribution
t=nFrames;
figure
colormap(gray)
subplot(3,3,[1:6])
hold on
imagesc(gbin(:,:,t)) %last frame image
scatter(squeeze(antx),squeeze(anty),'.r') %ant positions over time
scatter(linex,liney,'.k') %trail line
scatter(squeeze(antx),traily,'.g') % green points not on a line are misfits
% corrected line by changing thresholds or line endpoints
line(xint,[y1(t),y2(t)])
hold off
axis tight
text(10,10,['Distance: ',num2str(round(meandist)),'+/-',...
    num2str(round(stddist)),' pix ',...
    ', Velocity: ',num2str(round(meanvelocity)),' pix/s']...
    ,'FontSize',10,'Color','black');
title(outfile)
subplot(3,3,[7 8])
plot(squeeze(dist))
axis tight
title('Distance')
xlabel('time')
subplot(3,3,9)
polarhistogram(nandirs,16)
title('Direction distribution')
%% 9) Write quantitative results into database file
prompt = ['Add to output database: ',databasefile,' (y/n)?'];
add = input(prompt,'s');
if add == 'y'
    if ~isfile([outpath databasefile,'.txt']) %file exists
        fileID = fopen([outpath databasefile,'.txt'],'a+');
        fprintf(fileID,head);
    else
        fileID = fopen([outpath databasefile,'.txt'],'a+');
    end
    fprintf(fileID,out);    
    fclose(fileID);
    type([outpath databasefile,'.txt'])
end

%% 10) Make labelled movie
prompt = ['Create a labelled video file: ',[outfile '_labelled.avi'],' (y/n)?'];
add = input(prompt,'s');
if add == 'y'
    figure('Name','Video')
    colormap(gray)
    video = VideoWriter([outpath outfile '_labelled.avi']);
    video.FrameRate = framerate;
    open(video)
    for t=1:nFrames
        set (gca,'FontSize',8);
        set(gca,'XTick',[], 'YTick', [])
        hold on
        imagesc(gbin(:,:,t))
        title(outfile)
        text(10,10,['Frame: ',num2str(t),'/',num2str(nFrames),' Ant x: ',num2str(antx(t)),' y: ',...
            num2str(anty(t)),' Distance: ',num2str(dist(t))],'FontSize',10,'Color','black');
        scatter(squeeze(antx(1:t)),squeeze(anty(1:t)),'.r')%ant
        line(xint,[y1(t) y2(t)])%trail
        axis tight
        hold off
        writeVideo(video,getframe(gcf));
    end
    close(video);
end