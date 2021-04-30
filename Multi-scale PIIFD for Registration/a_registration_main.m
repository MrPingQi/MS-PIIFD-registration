clear; close all; clc;
if isempty(gcp('nocreate')) %���֮ǰû�п���parpool������
    parpool(maxNumCompThreads);  %��Ϊ����ʹ�ú���
end
%% Make fileholder for save images
if (exist('save_image','dir')==0) % ����ļ��в�����
    mkdir('save_image');
end

%% Define the constants
G_resize = 3;   % ��˹�������Ľ�������Ԫ��Ĭ��:2
G_sigma = 1.6;  % ��˹��������ģ����Ԫ��Ĭ��:1.6
numLayers = 6;  % ��˹������ÿ�������Ĭ��:4
sigma = 20;     % Harris �ֲ���Ȩ��˹�˱�׼������
thresh = 50;    % Harris �ǵ���Ӧ�б���ֵ
radius = 5;     % Harris �ֲ��Ǽ���ֵ���ƴ��뾶
N = 1000;       % ����������������ֵ
trans_form = 'similarity';  % �任ģ�ͣ�'similarity','affine','perspecive'

%% Read images
[image_1, image_2] = Readimage;
% figure; subplot(121),imshow(I1_o,[]); subplot(122),imshow(I2_o,[]);
% image_1=imresize(image_1,1/3,'bilinear');

%% Image preproscessing
resample1 = 1; resample2 = 1;
[I1_o,I1] = Preproscessing(image_1,resample1);  % I1:�ο�ͼ��
[I2_o,I2] = Preproscessing(image_2,resample2);  % I2:����׼ͼ��
% figure; subplot(121),imshow(I1,[]); subplot(122),imshow(I2,[]);

%% Save the reference image and the image to be registered
% str=['.\save_image\','Reference image.jpg'];
% imwrite(I1,str,'jpg');
% str=['.\save_image\','Image to be registered.jpg'];
% imwrite(I2,str,'jpg');

%% The number of groups in Gauss Pyramid
% numOctaves_1 = max(floor(log2(min(size(I1,1),size(I1,2)))-5),1);  % 2^(7+1)=256��ͼ����С��256
% numOctaves_2 = max(floor(log2(min(size(I2,1),size(I2,2)))-5),1);  % 2^(7+1)=256��ͼ����С��256
numOctaves_1 = 3;
numOctaves_2 = 3;
sig = Get_Gaussian_Scale(G_sigma,numLayers);
ratio = sqrt(size(I1,1)*size(I1,2)/(size(I2,1)*size(I2,2)));
% ratio = 1;

fprintf('\n��ʼͼ����׼�������ĵȴ�\n\n'); tic

%% Harris Corner Detection
% s = 4; o = 6;
% [II1,~,~,~,~,~,~] = phasecong3(I1,s,o,3,'mult',1.6,'sigmaOnf',0.75,'g', 3, 'k',1);
% a=max(II1(:)); b=min(II1(:)); II1=(II1-b)/(a-b);
% [II2,~,~,~,~,~,~] = phasecong3(I2,s,o,3,'mult',1.6,'sigmaOnf',0.75,'g', 3, 'k',1);
% a=max(II2(:)); b=min(II2(:)); II2=(II2-b)/(a-b);
p1 = Detect_Harris_Conner(I1,sigma,thresh,floor(radius*ratio),N,numOctaves_1,G_resize,1);
    str = ['����ɲο�ͼ���������⣬��ʱ',num2str(toc),'s\n']; fprintf(str); tic
p2 = Detect_Harris_Conner(I2,sigma,thresh,radius,N,numOctaves_2,G_resize,1);
    str = ['����ɴ���׼ͼ���������⣬��ʱ',num2str(toc),'s\n\n']; fprintf(str); tic

%% PC-Harris Feature Detection
% scale = 4; orientation = 6;
% p1 = Detect_PC_Harris(I1,scale,orientation,N,numOctaves_1,1);
%     str = ['����ɲο�ͼ���������⣬��ʱ',num2str(toc),'s\n']; fprintf(str); tic
% p2 = Detect_PC_Harris(I2,scale,orientation,N,numOctaves_1,1);
%     str = ['����ɴ���׼ͼ���������⣬��ʱ',num2str(toc),'s\n\n']; fprintf(str); tic

%% PC-FAST Feature Detection
% scale = 4; orientation = 6;
% p1 = Detect_PC_FAST(I1,scale,orientation,N,1);
%     str = ['����ɲο�ͼ���������⣬��ʱ',num2str(toc),'s\n']; fprintf(str); tic
% p2 = Detect_PC_FAST(I2,scale,orientation,N,1);
%     str = ['����ɴ���׼ͼ���������⣬��ʱ',num2str(toc),'s\n\n']; fprintf(str); tic

%% Create PIIFD Descriptor
descriptors_1 = Get_Multiscale_PIIFD(I1,p1,numOctaves_1,numLayers,G_resize,sig);
    str = ['����ɲο�ͼ����������������ʱ',num2str(toc),'s\n']; fprintf(str); tic
descriptors_2 = Get_Multiscale_PIIFD(I2,p2,numOctaves_2,numLayers,G_resize,sig);
    str = ['����ɴ���׼ͼ����������������ʱ',num2str(toc),'s\n\n']; fprintf(str); tic

%% Matching and Transforming
[location1,location2] = Match_Keypoint(I1,I2,descriptors_1,descriptors_2,numOctaves_1,numOctaves_2,numLayers,0);
% figure; matchment = showMatchedFeatures(I1_o,I2_o,location1(:,1:2)/resample1,location2(:,1:2)/resample2,'montage');
matchment = Showmatch(I1_o,I2_o,location1/resample1,location2/resample2);
[H,rmse,cor2,cor1] = FSC(location2/resample2,location1/resample1,trans_form,2);
% matchment1 = Showmatch(I1_o,I2_o,cor1,cor2);
[I1_c,I2_c,I3,I4] = Transformation(I1_o,I2_o,double(H));
    str = ['�����ͼ��任����ʱ',num2str(toc),'s\n\n']; fprintf(str); tic

%% Time and Result
% t2 = toc;
% fprintf('Runtime = %6.2f seconds.\n\n',t);
figure; imshow(I3,[]); title('Fusion Form');
figure; imshow(I4,[]); title('Checkerboard Form');

%% Save images
Date = datestr(now,'yyyy-mm-dd_HH-MM-SS__');
str=['.\save_image\',Date,'1 Matching Result','.jpg']; saveas(matchment,str);
str=['.\save_image\',Date,'2 Reference Image','.jpg']; imwrite(I1_c,str);
str=['.\save_image\',Date,'3 Transformed Image','.jpg']; imwrite(I2_c,str);
str=['.\save_image\',Date,'4 Fusion of results','.jpg']; imwrite(I3,str);
str=['.\save_image\',Date,'5 Checkerboard of results','.jpg']; imwrite(I4,str);
str = ['��׼����Ѿ������ڳ����Ŀ¼�µ�save_image�ļ����У�\n��ʱ',num2str(toc),'s\n']; fprintf(str);
% end