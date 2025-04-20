clc, clear, close all;

filename = 'meshes/tetgen/donut2.1';
name = "meshes/a.txt";

scale = 1;

x = readmatrix ([filename '.node'],'FileType','text');
x = x(2:end-1,2:4);
x = x' * scale;

faces = readmatrix ([filename '.face'],'FileType','text');
faces = faces(1:end-1, 2:4);

tets = readmatrix ([filename '.ele'],'FileType','text');
tets = tets(1:end-1, 2:5);

edges = readmatrix ([filename '.edge'],'FileType','text');
edges = edges(1:end-1, 2:3);

edgeconstraints = [];
tetstraint = []

for i = 1:size(tets,1)
    p1_idx = tets(i,1);
    p2_idx = tets(i,2);
    p3_idx = tets(i,3);
    p4_idx = tets(i,4);

    v1 = x(:, p2_idx) - x(:, p1_idx);
    v2 = x(:, p3_idx) - x(:, p1_idx);
    v3 = x(:, p4_idx) - x(:, p1_idx);
    v4 = x(:, p3_idx) - x(:, p2_idx);
    v5 = x(:, p4_idx) - x(:, p2_idx);
    v6 = x(:, p4_idx) - x(:, p3_idx);
    
    vol = (1/6) * det([v1, v2, v3]);

    edgeconstraints = [edgeconstraints; [p1_idx, p2_idx, norm(v1)]];
    edgeconstraints = [edgeconstraints; [p1_idx, p3_idx, norm(v2)]];
    edgeconstraints = [edgeconstraints; [p1_idx, p4_idx, norm(v3)]];
    edgeconstraints = [edgeconstraints; [p2_idx, p3_idx, norm(v4)]];
    edgeconstraints  = [edgeconstraints; [p2_idx, p4_idx, norm(v5)]];
    edgeconstraints = [edgeconstraints; [p3_idx, p4_idx, norm(v6)]];

    tetstraint = [tetstraint; vol];
end

tets = [tets,tetstraint]

for i = 1:size(edgeconstraints, 1)
    if edgeconstraints(i, 1) > edgeconstraints(i, 2)
        temp = edgeconstraints(i, 1);
        edgeconstraints(i, 1) = edgeconstraints(i, 2);
        edgeconstraints(i, 2) = temp;
    end
end
edgeconstraints = unique(edgeconstraints,"rows");
saveMesh(x,faces,edgeconstraints,tets,name)

figure;
tetramesh(tets, x');
title('Tetrahedral Mesh');
xlabel('X');
ylabel('Y');
zlabel('Z');