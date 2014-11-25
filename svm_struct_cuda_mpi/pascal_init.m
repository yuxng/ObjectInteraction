% initialize the PASCAL development kit 

% use VOC2006 or VOC2007 data

% VOC2006 = false; % set true to use VOC2006 data

tmp = pwd;
cd('../../FunctionRecognition/VOCdevkit');
addpath([cd '/VOCcode']);
VOCinit;
cd(tmp);