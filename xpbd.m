classdef xpbd
    properties
        g = -9.81;
        dt = 0.01;
        ground = -10;
        friction = 0.0;

        filename = 'videos/importoutput01.mp4';
        meshname = 'meshes/sphere4.obj';

        iters = 5;
        frs= 1000;
        alpha = 0.000001;
        scale = 3;

        vol_k = 0.95;
        k = 0.95;
        volalpha = 1/0.95;
        restitution = 0.5;

        x = [];
        faces = [];
        v = [];
        a = [];
        m = [];
        num = [];

        thetax = [];
        thetay = [];
        thetaz = [];

        vol_constraints = [];
        constraints = [];

        edgecolor = 'k';
    end
    methods
        function obj = xpbd(g,dt,ground,friction,filename,meshname,iters,frs,k,scale,vol_k,restitution, thetax, thetay, thetaz, surface, edgecolor)
            obj.g = g;

            obj.ground = ground;
            obj.friction = friction;
            obj.filename = filename;
            obj.meshname = meshname;

            obj.iters = iters;
            obj.frs = frs;

            obj.dt = dt/obj.iters;

            obj.k = k;
            obj.alpha = 0;
            if k
                obj.alpha = 1/k;
            end

            obj.scale = scale;


            obj.vol_k = vol_k;
            obj.volalpha = 0;

            if vol_k
                obj.volalpha = 1/vol_k;
            end

            obj.restitution = restitution^(1/iters);

            obj.thetax = thetax;
            obj.thetay = thetay;
            obj.thetaz = thetaz;

            obj.edgecolor = edgecolor;

            [~,~,ext] = fileparts(obj.meshname);

            if surface
                if strcmpi(ext, '.obj')
                    [obj.x, obj.faces] = loadMeshObj(obj.meshname);
                    obj.num = size(obj.x,2);
                    obj.x = (obj.x * scale);
                    obj.constraints = [];
                    for i = 1:size(obj.faces,1)
                        p1 = obj.x(:,obj.faces(i,1));
                        p2 = obj.x(:,obj.faces(i,2));
                        p3 = obj.x(:,obj.faces(i,3));
                        obj.constraints = [obj.constraints; obj.faces(i,1) obj.faces(i,2) norm(p1-p2)];
                        obj.constraints = [obj.constraints; obj.faces(i,1) obj.faces(i,3) norm(p1-p3)];
                        obj.constraints = [obj.constraints; obj.faces(i,2) obj.faces(i,3) norm(p2-p3)];
                    end

                    [~, uniqueIdx] = unique(sort(obj.constraints(:, 1:2), 2), 'rows', 'stable');
                    obj.constraints = obj.constraints(uniqueIdx, :);

                    DT = delaunayTriangulation(obj.x');
                    T = DT.ConnectivityList;

                    obj.vol_constraints = zeros(size(T,1), 5);

                    for i = 1:size(T,1)
                        p = T(i,:);

                        v1 = obj.x(:, p(2)) - obj.x(:, p(1));
                        v2 = obj.x(:, p(3)) - obj.x(:, p(1));
                        v3 = obj.x(:, p(4)) - obj.x(:, p(1));

                        vol = (1/6) * det([v1, v2, v3]);

                        obj.vol_constraints(i,:) = [p, vol];
                    end

                    obj.vol_constraints = unique(obj.vol_constraints,"rows");

                    saveMesh(obj.x, obj.faces, obj.constraints, obj.vol_constraints, [obj.meshname, '.txt']);
                elseif strcmpi(ext, '.txt')
                    [obj.x, obj.faces, obj.constraints, obj.vol_constraints] = readMesh(meshname);
                    obj.num = size(obj.x,2);
                else
                    error("Incompatible file format.")
                end
            else
                if strcmpi(ext, '.obj')
                    [obj.x, obj.faces] = loadMeshObj(obj.meshname);
                    obj.num = size(obj.x,2);

                    obj.x = (obj.x * scale);

                    DT = delaunayTriangulation(obj.x');
                    T = DT.ConnectivityList;
                    tetramesh(DT,'FaceAlpha',1);
                    title('Delaunay Triangulation')

                    %{
                    shp = alphaShape(obj.x');
                    alpha_critical = criticalAlpha(shp,"one-region");
                    shp.Alpha = alpha_critical*1.1;
                    
                    [T, ~] = alphaTriangulation(shp);
                    plot(shp)
                    title('Delaunay Triangulation')
                    %}

                    obj.vol_constraints = zeros(size(T,1), 5);
                    obj.constraints = [];

                    for i = 1:size(T,1)
                        p = T(i,:);

                        v1 = obj.x(:, p(2)) - obj.x(:, p(1));
                        v2 = obj.x(:, p(3)) - obj.x(:, p(1));
                        v3 = obj.x(:, p(4)) - obj.x(:, p(1));
                        v4 = obj.x(:, p(3)) - obj.x(:, p(2));
                        v5 = obj.x(:, p(4)) - obj.x(:, p(2));
                        v6 = obj.x(:, p(4)) - obj.x(:, p(3));

                        obj.constraints = [obj.constraints; [p(1), p(2), norm(v1)]];
                        obj.constraints = [obj.constraints; [p(1), p(3), norm(v2)]];
                        obj.constraints = [obj.constraints; [p(1), p(4), norm(v3)]];
                        obj.constraints = [obj.constraints; [p(2), p(3), norm(v4)]];
                        obj.constraints = [obj.constraints; [p(2), p(4), norm(v5)]];
                        obj.constraints = [obj.constraints; [p(3), p(4), norm(v6)]];

                        vol = (1/6) * det([v1, v2, v3]);

                        obj.vol_constraints(i,:) = [p, vol];
                    end

                    for i = 1:size(obj.constraints, 1)
                        if obj.constraints(i, 1) > obj.constraints(i, 2)
                            temp = obj.constraints(i, 1);
                            obj.constraints(i, 1) = obj.constraints(i, 2);
                            obj.constraints(i, 2) = temp;
                        end
                    end

                    obj.constraints = unique(obj.constraints,"rows");
                    obj.vol_constraints = unique(obj.vol_constraints,"rows");

                    saveMesh(obj.x, obj.faces, obj.constraints, obj.vol_constraints, [obj.meshname, '.txt']);
                elseif strcmpi(ext, '.txt')
                    [obj.x, obj.faces, obj.constraints, obj.vol_constraints] = readMesh(meshname);
                    obj.num = size(obj.x,2);
                end
            end

            R_x = [1 0 0; 0 cos(thetax) -sin(thetax); 0 sin(thetax) cos(thetax)];
            R_y = [cos(thetay) 0 sin(thetay); 0 1 0; -sin(thetay) 0 cos(thetay)];
            R_z = [cos(thetaz) -sin(thetaz) 0; sin(thetaz) cos(thetaz) 0; 0 0 1];
            R = R_z * R_y * R_x;
            obj.x = R * obj.x;
            
            obj.v = [zeros(1,obj.num);zeros(1,obj.num);zeros(1,obj.num)];
            obj.a = zeros(3, obj.num);
            obj.m = ones(1, obj.num);
        end
        
        function simulate(obj)

            vid = VideoWriter(obj.filename, 'MPEG-4');
            vid.FrameRate = 60;
            open(vid);

            fig = figure('Units', 'pixels', 'Position', [100, 100, 1024, 768]);
            figure(fig);
            title("XPBD Soft-body Physics")
            grid on;
            view(3);
            hold on;
            ab = abs(obj.ground);
            light('Position', [-ab -ab ab], 'Style', 'local');
            lighting phong;
            shading interp;
            axis([-ab ab -ab ab -ab ab]);
            xlabel('X'); ylabel('Y'); zlabel('Z');

            ptch = gobjects(size(obj.faces, 1), 1);
            ptch(:) = patch('Vertices', obj.x', 'Faces', obj.faces(:, :), 'FaceColor', 'y', 'FaceAlpha', 1, 'LineWidth', 0.01, 'EdgeColor', obj.edgecolor);

            patch('Vertices',[-ab -ab -ab; ab -ab -ab; ab ab -ab; -ab ab -ab], 'Faces', [1 2 3 4], 'FaceColor', [0.5, 0.5, 0.5]);

            frame_txt = text(-0.05, 0.18, 0, '..', 'Units', 'normalized', 'Color','k', 'FontSize', 12, 'LineWidth', 2);
            text(-0.05, 0.14, 0, ['Tris: ', num2str(size(obj.faces,1))], 'Units', 'normalized', 'Color','k', 'FontSize', 12, 'LineWidth', 2);
            text(-0.05, 0.10, 0, ['Verts: ', num2str(size(obj.x,2))], 'Units', 'normalized', 'Color','k', 'FontSize', 12, 'LineWidth', 2);
            text(-0.05, 0.06, 0, ['Volume Constraints: ', num2str(size(obj.vol_constraints,1))], 'Units', 'normalized', 'Color','k', 'FontSize', 12, 'LineWidth', 2);
            text(-0.05, 0.02, 0, ['Edge Constraints: ', num2str(size(obj.constraints,1))], 'Units', 'normalized', 'Color','k', 'FontSize', 12, 'LineWidth', 2);
            str = sprintf('k: %.4f, volume k: %.4f', obj.k, obj.vol_k);
            text(-0.05, -0.02, 0, str, 'Units', 'normalized', 'Color','k', 'FontSize', 12, 'LineWidth', 2);
            text(-0.05, -0.06, 0, ['dt: ', num2str(obj.dt*obj.iters)], 'Units', 'normalized', 'Color','k', 'FontSize', 12, 'LineWidth', 2);

            adtdt= obj.alpha/(obj.dt*obj.dt);
            vdtdt= obj.volalpha/(obj.dt*obj.dt);

            p1 = obj.constraints(:,1);
            p2 = obj.constraints(:,2);
            l = obj.constraints(:,3);

            p3 = obj.vol_constraints(:,1);
            p4 = obj.vol_constraints(:,2);
            p5 = obj.vol_constraints(:,3);
            p6 = obj.vol_constraints(:,4);
            v_r = obj.vol_constraints(:,5);
            m_inv = 1./obj.m;

            obj.a(3,:) = ones(1,obj.num) * obj.g;
            for fr = 1:obj.frs
               for iter = 1:obj.iters
                obj.v = obj.v + obj.dt * obj.a;
                x_old = obj.x;
                obj.x = obj.x + obj.dt * obj.v;
                below_ground = obj.x(3,:) <= obj.ground;
                obj.x(3,below_ground) = obj.ground;
                    for j = 1:size(obj.constraints,1)
                        distance = obj.x(:,p1(j))-obj.x(:,p2(j));
                        normdist = norm(distance);
                        if normdist == 0
                            continue;
                        end
    
                        cx = normdist - l(j);
    
                        dcx1 = distance/normdist;
                        dcx2 = -dcx1;
    
                        deltalambda = (-cx)/(norm(dcx1)^2*m_inv(p1(j))+norm(dcx2)^2*m_inv(p2(j))+adtdt);
    
                        obj.x(:,p1(j)) = obj.x(:,p1(j)) + m_inv(p1(j)) * dcx1 * deltalambda;
                        obj.x(:,p2(j)) = obj.x(:,p2(j)) + m_inv(p2(j)) * dcx2 * deltalambda;
                    end
                    for j = 1:size(obj.vol_constraints,1)
                        v1 = obj.x(:, p6(j)) - obj.x(:, p4(j));
                        v2 = obj.x(:, p5(j)) - obj.x(:, p4(j));
                        v3 = obj.x(:, p5(j)) - obj.x(:, p3(j));
                        v4 = obj.x(:, p6(j)) - obj.x(:, p3(j));
                        v5 = obj.x(:, p4(j)) - obj.x(:, p3(j));

                        cross_prod = cross(v5, v3);

                        vol = ((1/6) * dot(cross_prod, v4));
                        cx = 6*(vol-v_r(j));

                        dcx1 = cross(v1, v2);
                        dcx2 = cross(v3, v4);
                        dcx3 = cross(v4, v5);
                        dcx4 = cross(v5, v2);

                        denom = (norm(dcx1)^2*m_inv(p3(j)) + norm(dcx2)^2*m_inv(p4(j)) + norm(dcx3)^2*m_inv(p5(j)) + norm(dcx4)^2*m_inv(p6(j)) + vdtdt);
                        if denom == 0
                            continue
                        end
                        deltalambda = (-cx) / denom;

                        obj.x(:,p3(j)) = obj.x(:,p3(j)) + m_inv(p3(j)) * dcx1 * deltalambda;
                        obj.x(:,p4(j)) = obj.x(:,p4(j)) + m_inv(p4(j)) * dcx2 * deltalambda;
                        obj.x(:,p5(j)) = obj.x(:,p5(j)) + m_inv(p5(j)) * dcx3 * deltalambda;
                        obj.x(:,p6(j)) = obj.x(:,p6(j)) + m_inv(p6(j)) * dcx4 * deltalambda;
                    end
                obj.v = (obj.x - x_old)/obj.dt;
                below_ground = obj.x(3,:) <= obj.ground + 1e-3;
                obj.v(3,below_ground) = -obj.v(3,below_ground);
                obj.v([1 2],below_ground) = obj.v([1 2],below_ground)*obj.friction;
               end
                set(frame_txt, 'String', ['Frame: ', num2str(fr)]);
                set(ptch(:), 'Vertices', obj.x');
                drawnow;
                frame = getframe(fig);
                writeVideo(vid, frame);
            end
            close(vid);
            msgbox('XPBD Simulation Completed', 'Notification');
        end
    end
end