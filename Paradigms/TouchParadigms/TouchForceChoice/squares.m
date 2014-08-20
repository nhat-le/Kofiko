function squares(window)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

%coordinates of where the squares start; size of squares
x = -150; y = 350; w = 0; h = 500; 
numSquares = 7;
screenWidth = 1200;
filename = 'squares2.avi';

%make screen
win_size = [20 20 screenWidth 700];
%window = Screen('OpenWindow', 0, [0 0 0],win_size);
window = hWindow;

rate = Screen('GetFlipInterval', window);
start = Screen('Flip', window);
n = 1;
speed = 3;

% %create video object
% writerObj = VideoWriter(filename);
% open(writerObj);

%array holding positions of all squares on screen
%starts with one square
rect = [x;y;w;h];

%while the mouse hasn't responded...
for k = 1:numSquares
    %move the squares 25 times, 8 pixels each time (25 flips)
    for i = 1 : 25
        Screen('FillRect', window,[], rect);
%         currIm = Screen('GetImage', window, [], 'backBuffer');
%         writeVideo(writerObj, currIm);
          Screen('Flip', window, start + speed*n*rate);
          
        n = n + 1;
        
        for row = 1:4
            if row == 1 || row == 3
                for col = 1: size(rect, 2)
                    rect(row, col) = rect(row, col) + 12;
                end
            end
        end
    end
    
    %if a square has moved off-screen, remove its column from rect
    for j = 1 : size(rect, 2)
        if rect(1, j) == screenWidth
            rect(:, j) = [];
        end
    end
    
    %add a new square 
    newrect = [x; y; w; h];
    rect = [rect newrect];
    if acInputsFromKofiko{1} == 'AbortTrial'
        rect = [];
        break;
end

% close(writerObj);
%Screen('Close');
end

