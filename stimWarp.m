function [stimBitNew, tFormStruct] = stimWarp(imPathOld,imPathNew,stimBitmapPath)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The purpose of this script is to warp a previous recording's FOV and stim
% points to a new recording in order to match up stim point locations
% across days

% Inputs:
% - imPathOld       = path to previous FOV tiff (mapping source)
% - imPathNew       = path to new FOV tiff (mapping destination)
% - stimBitmapPath  = path to stim points - tiff OR .mat containing pages
%                     of data matrices

% Outputs:
% - stimBitmap      = stim bitmap data matrix (same size as input bitmap)

% Dimitar Kostadinov 2024-05-10
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Default params
warpDeg = 12;


%% Deal with data loading - if paths provided, use them OR load manually
% Load source image
if ~isempty(imPathOld)
    imOld0 = double(TiffReader_dk(imPathOld));    
else
    imPathOld = uigetfile({'*.mat;*.tif;*.png;*.jpeg',...
    'Image Files (*.mat,*.tif,*.png,*.jpeg)';
   '*.*',  'All Files (*.*)'}, ...
   'Select mapping source image');
    if isempty(imPathOld); fprintf('No source image file loaded, returning.'); return; end
    imOld0 = double(imread(imPathOld));    
end

% Deal with stacks or multi-color images
if size(imOld0,3) > 1; imOld0 = mean(imOld0,3); end  

% Normalize source image
mu = median(imOld0(:));
sd1 = mean(abs(imOld0(imOld0<mu) - mu));
sd2 = mean(abs(imOld0(imOld0>mu) - mu));
imLims = mu + 5*[-sd1 sd2];
imOld = imOld0-imLims(1);
imOld(imOld(:) > diff(imLims)) = diff(imLims);
imOld = imOld./max(imOld(:));
imOld = uint8(imOld*255);

% Load destination image
if ~isempty(imPathNew)
    imNew0 = double(TiffReader_dk(imPathNew));
else
    imPathNew = uigetfile({'*.mat;*.tif;*.png;*.jpeg',...
    'Image Files (*.mat,*.tif,*.png,*.jpeg)';
   '*.*',  'All Files (*.*)'}, ...
   'Select mapping destination image');
    if isempty(imPathNew); fprintf('No destination image file loaded, returning.'); return; end
    imNew0 = double(imread(imPathNew));    
end

% Deal with stacks or multi-color images
if size(imNew0,3) > 1; imNew0 = mean(imNew0,3); end  

% Normalize source image
mu = median(imNew0(:));
sd1 = mean(abs(imNew0(imNew0<mu) - mu));
sd2 = mean(abs(imNew0(imNew0>mu) - mu));
imLims = mu + 5*[-sd1 sd2];
imNew = imNew0-imLims(1);
imNew(imNew(:) > diff(imLims)) = diff(imLims);
imNew = imNew./max(imNew(:));
imNew = uint8(imNew*255);

% Load in source bitmap images:
if ~isempty(stimBitmapPath)
    if strcmp(stimBitmapPath(end-3:end),'.mat')
        stimBit0 = load(stimBitmapPath);
        stimNames = fieldnames(stimBit0);
        stimBit = double(stimBit0.(stimNames{1}));        
    elseif strcmp(stimBitmapPath(end-3:end),'.tif')
        stimBit = double(TiffReader_dk(stimBitmapPath));            
    else
        fprintf('Wrong file type, returning.\n'); 
        return
    end
else
    stimBitmapPath = uigetfile({'*.mat;*.tif;*.png;*.jpeg',...
    'Image Files (*.mat,*.tif,*.png,*.jpeg)';
   '*.*',  'All Files (*.*)'}, ...
   'Select target location source image(s)');

    if isempty(stimBitmapPath); fprintf('No source stim point image loaded, returning.'); return; end
    
    if strcmp(stimBitmapPath(end-3:end),'.mat')
        stimBit0 = load(stimBitmapPath);
        stimNames = fieldnames(stimBit0);
        stimBit = double(stimBit0.(stimNames{1}));
    elseif strcmp(stimBitmapPath(end-3:end),'.tif')
        stimBit = double(TiffReader_dk(stimBitmapPath));            
    else
        fprintf('Wrong file type, returning.\n'); 
        return
    end    
end

clear imLims imNew0 imOld0 mu sd1 sd2

%% Make warping transformation
% Use cpselect to select warp points
movingPoints = [];
while size(movingPoints,1) < 6
    [movingPoints, fixedPoints] = cpselect(imOld, imNew, 'wait',true);
    if size(movingPoints,1) < 6
        fprintf('Too few points selected, choose at least 6 points.\n');
    end
end
if size(movingPoints,1) < warpDeg
    warpDeg = size(movingPoints,1);
end

% Generate transform
tForm = fitgeotrans(movingPoints, fixedPoints, 'lwm', warpDeg); % DK changed to projective from affine transform

tFormStruct = v2struct(tForm,imOld,imNew,movingPoints,fixedPoints);

clear movingPoints fixedPoints warpDeg

%% Do warping
% Loop through our bitmap images and warp them
stimBitNew = zeros(size(stimBit));
for iStim = 1:size(stimBit,3)
    stimTemp = imwarp(stimBit(:,:,iStim),tForm,'OutputView',imref2d(size(imOld)));
    stimBitNew(:,:,iStim) = imregionalmax(stimTemp);
end

tFormStruct.stimBitOld = stimBit;
tFormStruct.stimBitNew = stimBitNew;
figure; 
subplot(1,2,1); imagesc(stimBit); axis square;
subplot(1,2,2); imagesc(stimBitNew); axis square;
colormap gray

end