% function experiment(subjid,delaytime)
%
% Delay time should be specified in milliseconds
%
% E.g. experiment('RB',1000)  

function run_block(windowPtr,subjid,delaytime,setsizes,nTrials)

%-%-%-%-%-
%- INIT %-
%-%-%-%-%-
outputfile = ['output/' upper(subjid) '_' datestr(clock,30) '_' num2str(delaytime) '.mat'];

settings.intertrialtime = 500; % time between two trials
settings.bglum = 30;
settings.gablambda = .35;
settings.gabsigma = .2;
settings.gabphase = 0;
settings.gabpeak = 0.8;   % between 0 and 1 (1=maximum contrast)
settings.bgdac = 128;
settings.stimtime = 90;
settings.stimecc = 5;
settings.breakTime = 30;
settings.maxN = max(setsizes);

settings.setsizes = setsizes;
settings.delaytime = delaytime;

% screen info
screen_width = 40;    % in cm (Dell@T115A: ~48cm; Dell@T101C: ~40 cm)
[w h]=Screen('WindowSize', 0);             % screen resolution
screen_resolution = [w h];                 % screen resolution
screen_distance = 60;                      % distance between observer and screen (in cm)
screen_angle = 2*(180/pi)*(atan((screen_width/2) / screen_distance)) ; % total visual angle of screen
screen_ppd = screen_resolution(1) / screen_angle;  % pixels per degree
screen_fixposxy = screen_resolution .* [.5 .5]; % fixation position

%-%-%-%-%-%-%-%-%-%
% Generate trials %
%-%-%-%-%-%-%-%-%-%

N_vec = repmat(settings.setsizes,1,ceil(nTrials/length(settings.setsizes)));
N_vec = N_vec(randperm(length(N_vec)));
N_vec = N_vec(1:nTrials);
for ii=1:nTrials
    data.N(ii) = N_vec(ii);
    data.delay(ii) = settings.delaytime;
    data.stimvec{ii} = rand(1,data.N(ii))*180-90; % draw stimuli randomly in range [-90, 90]
    data.targetidx(ii) = randi(data.N(ii));
    data.targetval(ii) = data.stimvec{ii}(data.targetidx(ii));
    data.startpos(ii) = randi(settings.maxN);
end

% compute stimulus positions
angle=0;
for ii=1:settings.maxN
    [x y] = pol2cart(angle,settings.stimecc*screen_ppd);
    posx(ii) = x+screen_fixposxy(1);
    posy(ii) = y+screen_fixposxy(2);
    angle = angle+2*pi/settings.maxN;
end

% wait briefly before presenting the first trial
Screen('FillRect', windowPtr, 128);
drawfixation(windowPtr,screen_fixposxy(1),screen_fixposxy(2),250,5,1);
Screen('Flip', windowPtr);
Screen('TextSize', windowPtr, 15);
WaitSecs(1.5);

%-%-%-%-%-%-%-%-%-%-%-%-%
%- LOOP THROUGH TRIALS %-
%-%-%-%-%-%-%-%-%-%-%-%-%
nextFlipTime = 0; % just to initialize...

for trialnr = 1:length(data.N)

    % create stimulus patches
    clear stimtex;
    for ii=1:data.N(trialnr)
        im = generate_gabor(data.stimvec{trialnr}(ii),settings.gablambda*screen_ppd,settings.gabsigma*screen_ppd,settings.gabphase);
        im = ((settings.gabpeak*im*256)+256)/2;
        patchsize(ii,:) = size(im);
        stimtex(ii)=Screen('MakeTexture', windowPtr, im);
    end
    
    % SCREEN 1: FIXATION
    Screen('fillRect',windowPtr,settings.bgdac);
    drawfixation(windowPtr,screen_fixposxy(1),screen_fixposxy(2),250,5,1);
    Screen('flip',windowPtr,nextFlipTime);
    nextFlipTime = GetSecs + .5;
    
    % SCREEN 2: STIMULUS
    Screen('fillRect',windowPtr,settings.bgdac);    
    drawfixation(windowPtr,screen_fixposxy(1),screen_fixposxy(2),250,5,1);
    posidx = data.startpos(trialnr);
    for ii=1:data.N(trialnr)
        srcrect = [0 0 patchsize(ii,:)];        
        destrect = CenterRectOnPoint(srcrect,posx(posidx),posy(posidx));
        Screen('drawtexture',windowPtr,stimtex(ii),srcrect,destrect);
        if ii==data.targetidx(trialnr)
            posx_target = posx(posidx);
            posy_target = posy(posidx);
        end
        posidx = posidx+1;
        if posidx>settings.maxN
            posidx=1;
        end
    end
    Screen('flip',windowPtr,nextFlipTime);
    nextFlipTime = GetSecs + settings.stimtime/1000;
    
    % SCREEN 3: DELAY
    Screen('fillRect',windowPtr,settings.bgdac);
    drawfixation(windowPtr,screen_fixposxy(1),screen_fixposxy(2),250,5,1);
    Screen('flip',windowPtr,nextFlipTime);
    pause((settings.delaytime-10)/1000);
    
    % SCREEN 4: RESPONSE
    
    % Show a circle at the target location
    [mousex_bf mousey_bf buttons_bf] = GetMouse(windowPtr); 
    done_circle = 0;
    while ~done_circle
        Screen('fillRect',windowPtr,settings.bgdac);
        drawfixation(windowPtr,screen_fixposxy(1),screen_fixposxy(2),250,5,1);
        rect_target = CenterRectOnPoint([0 0 size(im)*1.2], posx_target, posy_target);
        Screen('frameOval',windowPtr, 255, rect_target);
        Screen('flip',windowPtr);

        [mousex_aft mousey_aft buttons_aft] = GetMouse(windowPtr);
        if (mousex_aft-mousex_bf)^2+(mousey_aft-mousey_bf)^2 > 10
            done_circle = 1;
        end
        
        % check if ESC is pressed
        [keyIsDown,secs,keyCode] = KbCheck;
        if keyCode(27)
            Screen('closeall');
            error('Program aborted');
        end
        
    end
    
    % response appears with mouse input
    done=0;
    mousex = screen_resolution(1)/2 + rand*screen_resolution(1)/4-screen_resolution(1)/8;        
    data.respstartangle(trialnr) = mod(mousex,screen_resolution(1)/4)/(screen_resolution(1)/4)*180-90;
    while ~done
        SetMouse(round(mousex),round(screen_resolution(2)/2),windowPtr);
        Screen('fillRect',windowPtr,settings.bgdac);
        drawfixation(windowPtr,screen_fixposxy(1),screen_fixposxy(2),250,5,1);
        % draw response gabor
        respangle = mod(mousex,screen_resolution(1)/4)/(screen_resolution(1)/4)*180-90;
        im = generate_gabor(respangle,settings.gablambda*screen_ppd,settings.gabsigma*screen_ppd,settings.gabphase);
        im = ((settings.gabpeak*im*256)+256)/2;
        patchsize = size(im);
        stimtex=Screen('MakeTexture', windowPtr, im);
        srcrect = [0 0 patchsize];        
        destrect = CenterRectOnPoint(srcrect,posx_target,posy_target);
        Screen('drawtexture',windowPtr,stimtex,srcrect,destrect);               
%         Screen('DrawText',windowPtr,['Angle= ' num2str(respangle,2)],0,0,[255 255 255]);
        Screen('flip',windowPtr);
        
        % check for mouse click
        [mousex mousey buttons] = GetMouse(windowPtr);
        done = any(buttons);
        
        % check if ESC is pressed
        [keyIsDown,secs,keyCode] = KbCheck;
        if keyCode(27)
            Screen('closeall');
            error('Program aborted');
        end
        
        
    end
    data.respangle(trialnr) = respangle;    

    % SCREEN 4: INTER TRIAL DISPLAY
    Screen('fillRect',windowPtr,settings.bgdac);
    drawfixation(windowPtr,screen_fixposxy(1),screen_fixposxy(2),250,5,0);
    Screen('flip',windowPtr);
    nextFlipTime = GetSecs + settings.intertrialtime/1000;
    
end
save(outputfile,'settings','data');


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

