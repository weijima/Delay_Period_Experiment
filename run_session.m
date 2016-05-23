function run_session

%------- EXPERIMENT SETTINGS -------
delaytimes        = [1000 2000 3000 6000];  
setsizes          = [1 2 4 6];
nTrialsPerBlock   = 60;
nBlocksPerSession = 4;                 % this should be a multiple of length(delaytimes)
breakTime         = 30;                % length of break between blocks (in seconds)
%-----------------------------------

if mod(nBlocksPerSession,length(delaytimes))~=0
    error('nBlocksPerSession should be a multiple of the number of tested delay times');
end

clc;
subjid=[];
while isempty(subjid)
    subjid = input('Subject initials: ','s');
end

s = RandStream.create('mt19937ar','seed',sum(100*clock));
RandStream.setGlobalStream(s);

% open screen
HideCursor;
windowPtr = Screen('OpenWindow',0,128,[],32,2);
[w h] = Screen('WindowSize', 0);           % screen resolution
screen_resolution = [w h];                 % screen resolution
screen_fixposxy = screen_resolution .* [.5 .5]; % fixation position

% show start screen
xpos = 100;
ypos = 100;
dy = 37;
Screen('fillRect',windowPtr,128);
Screen('TextSize',windowPtr,25);
Screen('DrawText',windowPtr,['This experiment consists of ' num2str(nBlocksPerSession) ' blocks of ' num2str(nTrialsPerBlock) ' trials.'],xpos,ypos,[255 255 255]); ypos = ypos+2*dy;
Screen('DrawText',windowPtr,'On each trial, a set of stimuli will be shown.',xpos,ypos,[255 255 255]); ypos = ypos+dy;
Screen('DrawText',windowPtr,'After a brief delay, you will be asked to',xpos,ypos,[255 255 255]); ypos = ypos+dy;
Screen('DrawText',windowPtr,'estimate the orienation of one of them. ',xpos,ypos,[255 255 255]); ypos = ypos+2*dy;
Screen('DrawText',windowPtr,'The stimulus orientations are completely random.',xpos,ypos,[255 255 255]); ypos = ypos+2*dy;
Screen('DrawText',windowPtr,'Good luck!',xpos,ypos,[255 255 255]); ypos = ypos+4*dy;
Screen('DrawText',windowPtr,'Press any key to start',xpos,ypos,[60 200 60]);
Screen('flip',windowPtr);
waitForKey;

% run blocks
delay_times_randomized = repmat(delaytimes,1,nBlocksPerSession/length(delaytimes));
delay_times_randomized = delay_times_randomized(randperm(length(delay_times_randomized)));
for ii=1:nBlocksPerSession
    run_block(windowPtr,subjid,delay_times_randomized(ii),setsizes,nTrialsPerBlock);
    
    % BREAK
    Screen('TextSize',windowPtr,25);
    if ii<nBlocksPerSession
        breakStart=GetSecs;
        while (GetSecs-breakStart)<breakTime
            Screen('fillRect',windowPtr,128);
            Screen('DrawText',windowPtr,['You have finished ' num2str(ii) ' out of ' num2str(nBlocksPerSession) ' blocks.'],75,400,[255 255 255]);
            Screen('DrawText',windowPtr,['Please take a short break now.'],75,440,[255 255 255]);
            totalBreak = GetSecs-breakStart;
            Screen('DrawText',windowPtr,['You can continue in ' num2str(ceil(breakTime-totalBreak)) ' seconds.'],75,520,[255 255 255]);
            Screen('flip',windowPtr);
        end
        Screen('fillRect',windowPtr,128);
        Screen('DrawText',windowPtr,['You have finished ' num2str(ii) ' out of ' num2str(nBlocksPerSession) ' blocks.'],75,400,[255 255 255]);
        Screen('DrawText',windowPtr,['Please take a short break now.'],75,440,[255 255 255]);
        Screen('DrawText',windowPtr,['Press any key to continue.'],75,520,[255 255 255]);
        Screen('flip',windowPtr);
    else
        Screen('fillRect',windowPtr,128);
        Screen('DrawText',windowPtr,['You have finished this session.'],75,400,[255 255 255]);
        Screen('DrawText',windowPtr,['Thank you for your participation!'],75,460,[255 255 255]);
        Screen('flip',windowPtr);
    end
    waitForKey;
end

% finalize
ShowCursor;
Screen('closeall');

%-%-%-%-%-%-%-%-%-%-%-%-%- HELPER FUNCTIONS %-%-%-%-%-%-%-%-%-%-%-%-%-%-%-

function keyCode = waitForKey
keyCode = ones(1,256);
while sum(keyCode(1:254))>0
    [keyIsDown,secs,keyCode] = KbCheck;
end
while sum(keyCode(1:254))==0
    [keyIsDown,secs,keyCode] = KbCheck;
end
keyCode = min(find(keyCode==1));

function drawfixation(windowPtr,x,y,color,size,vert)
Screen('DrawLine',windowPtr,color,x-size,y,x+size,y,2);
if (vert)
    Screen('DrawLine',windowPtr,color,x,y-size,x,y+size,2);
end

