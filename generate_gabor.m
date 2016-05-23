% function im = generate_gabor(ort, lambda, sigma, phase)
%
% Creates a gabor patch, with min=-1, mean=0, max=1. The size of the
% returned image equals 5*[sigma sigma].
%
% INPUT
%   ort        : orientation
%   lambda     : wavelength (pixels)
%   sigma      : std of gaussian filter (pixels)
%   phase      : phase 
%
% OUTPUT
%   im         : gabor patch
%
% Written by RvdB, Sept 2008

function im = generate_gabor(ort, lambda, sigma, phase)

% set image size (cut off after center +/- 3*sigma)
imsize = round(5*[sigma sigma]);

% generate cosine pattern
X = ones(imsize(1),1)*[-(imsize(2)-1)/2:1:(imsize(2)-1)/2];
Y =[-(imsize(1)-1)/2:1:(imsize(1)-1)/2]' * ones(1,imsize(2));

cospattern = cos(2.*pi.*1/lambda.* (cos(deg2rad(ort)).*X ...
    + sin(deg2rad(ort)).*Y)  ...
    - phase*ones(imsize) );

% convolve with gaussian
filt = fspecial('gaussian', imsize, sigma); 
filt = filt/max(max(filt));
im = cospattern .* filt;

function r = deg2rad(d)

r = (d/360)*(2*pi);
