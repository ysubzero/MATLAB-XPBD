clc, clear, close all;
main();

function main

params = {
    'g', -9.81;
    'dt', 0.01;
    'ground level', -10;
    'friction', 0.0;
    'filename', 'videos/importoutput15.mp4';
    'meshname', 'meshes/sphere4.obj';
    'substeps', 20;
    'frames', 1200;
    'alpha', 0.001;
    'scale (do not use for .txt)', 3;
    'k', 0.95;
    'restitution', 0.5;
    'rotation angle x', pi/4;
    'rotation angle y', pi/4;
    'rotation angle y', pi/4
};

prompts = params(:,1);
defaults = cellfun(@(x) num2str(x), params(:,2), 'UniformOutput', false);

user_in = inputdlg(prompts, 'Matlab XPBD', [1 100], defaults);

if size(user_in) ~= 15
    return
end

g = str2num(user_in{1});
dt = str2num(user_in{2});
ground = str2num(user_in{3});
friction = str2num(user_in{4});

filename = user_in{5};
meshname = user_in{6};

iters = str2num(user_in{7});
frs= str2num(user_in{8});
alpha = str2num(user_in{9});
scale = str2num(user_in{10});

k = str2num(user_in{11});
restitution = str2num(user_in{12});

thetax = str2num(user_in{13});
thetay = str2num(user_in{14});
thetaz = str2num(user_in{15});

sim = xpbd(g,dt,ground,friction,filename,meshname,iters,frs,alpha,scale,k,restitution, thetax, thetay, thetaz);
sim.simulate();
end