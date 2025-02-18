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
    end
    methods
        function obj = xpbd(g,dt,ground,friction,filename,meshname,iters,frs,alpha,scale,k,restitution, thetax, thetay, thetaz)
            obj.g = g;
            obj.dt = dt;

            obj.ground = ground;
            obj.friction = friction;
            obj.filename = filename;
            obj.meshname = meshname;

            obj.iters = iters;
            obj.frs = frs;

            obj.alpha = alpha;
            obj.scale = scale;

            obj.k = k;
            obj.volalpha = 1/k;
            obj.restitution = restitution;

            obj.thetax = thetax;
            obj.thetay = thetay;
            obj.thetaz = thetaz;

            [obj.x, obj.faces] = loadMeshObj(obj.meshname);
            obj.num = size(obj.x,2);

            obj.x = (obj.x * scale);

            R_x = [1 0 0; 0 cos(thetax) -sin(thetax); 0 sin(thetax) cos(thetax)];
            R_y = [cos(thetay) 0 sin(thetay); 0 1 0; -sin(thetay) 0 cos(thetay)];
            R_z = [cos(thetaz) -sin(thetaz) 0; sin(thetaz) cos(thetaz) 0; 0 0 1];
            R = R_z * R_y * R_x;
            obj.x = R * obj.x;

            obj.v = [zeros(1,obj.num);zeros(1,obj.num);zeros(1,obj.num)];
            obj.a = zeros(3, obj.num);
            obj.m = ones(1, obj.num);

            DT = delaunayTriangulation(obj.x');
            T = DT.ConnectivityList;

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
        ptch(:) = patch('Vertices', obj.x', 'Faces', obj.faces(:, :), 'FaceColor', 'y', 'FaceAlpha', 1, 'LineWidth', 0.01);

        patch('Vertices',[-ab -ab -ab; ab -ab -ab; ab ab -ab; -ab ab -ab], 'Faces', [1 2 3 4], 'FaceColor', [0.5, 0.5, 0.5]);

        frame_txt = text(-0.05, 0.18, 0, '..', 'Units', 'normalized', 'Color','k', 'FontSize', 12, 'LineWidth', 2);
        text(-0.05, 0.14, 0, ['Tris: ', num2str(size(obj.faces,1))], 'Units', 'normalized', 'Color','k', 'FontSize', 12, 'LineWidth', 2);
        text(-0.05, 0.10, 0, ['Verts: ', num2str(size(obj.x,2))], 'Units', 'normalized', 'Color','k', 'FontSize', 12, 'LineWidth', 2);
        text(-0.05, 0.06, 0, ['Volume Constraints: ', num2str(size(obj.vol_constraints,1))], 'Units', 'normalized', 'Color','k', 'FontSize', 12, 'LineWidth', 2);
        text(-0.05, 0.02, 0, ['Edge Constraints: ', num2str(size(obj.constraints,1))], 'Units', 'normalized', 'Color','k', 'FontSize', 12, 'LineWidth', 2);
        text(-0.05, -0.02, 0, ['Distance Compliance: ', num2str(obj.alpha)], 'Units', 'normalized', 'Color','k', 'FontSize', 12, 'LineWidth', 2);
        text(-0.05, -0.06, 0, ['k: ', num2str(obj.k)], 'Units', 'normalized', 'Color','k', 'FontSize', 12, 'LineWidth', 2);
        text(-0.05, -0.10, 0, ['dt: ', num2str(obj.dt)], 'Units', 'normalized', 'Color','k', 'FontSize', 12, 'LineWidth', 2);

        for fr = 1:obj.frs
            obj.a(3,:) = ones(1,obj.num) * obj.g;
            obj.v = obj.v + obj.dt * obj.a;
            x_old = obj.x;
            obj.x = obj.x + obj.dt * obj.v;
            below_ground = obj.x(3,:) <= obj.ground;
            obj.x(3,below_ground) = obj.ground + obj.dt * -obj.v(3,below_ground) * obj.restitution;
            for iter = 1:obj.iters
                for j = 1:size(obj.constraints,1)
                    p1 = obj.constraints(j,1);
                    p2 = obj.constraints(j,2);
                    l = obj.constraints(j,3);

                    distance = obj.x(:,p1)-obj.x(:,p2);
                    normdist = norm(distance);
                    if normdist == 0
                        normdist = 1e-8;
                    end

                    cx = normdist - l;

                    dcx1 = distance/normdist;
                    dcx2 = -distance/normdist;

                    lambda = (-cx)/(norm(dcx1)^2/obj.m(p1)+norm(dcx2)^2/obj.m(p2)+obj.alpha/(obj.dt*obj.dt));

                    obj.x(:,p1) = obj.x(:,p1) + 1/obj.m(p1) * dcx1 * lambda;
                    obj.x(:,p2) = obj.x(:,p2) + 1/obj.m(p2) * dcx2 * lambda;
                end
                for j = 1:size(obj.vol_constraints,1)
                    p1 = obj.vol_constraints(j,1);
                    p2 = obj.vol_constraints(j,2);
                    p3 = obj.vol_constraints(j,3);
                    p4 = obj.vol_constraints(j,4);
                    v_r = obj.vol_constraints(j,5);

                    v1 = obj.x(:, p4) - obj.x(:, p2);
                    v2 = obj.x(:, p3) - obj.x(:, p2);
                    v3 = obj.x(:, p3) - obj.x(:, p1);
                    v4 = obj.x(:, p4) - obj.x(:, p1);
                    v5 = obj.x(:, p2) - obj.x(:, p1);

                    cross_prod = cross(v5, v3);

                    vol = ((1/6) * dot(cross_prod, v4));
                    cx = 6*(vol-v_r);

                    if abs(cx) < 1e-8
                        continue
                    end

                    dcx1 = cross(v1, v2);
                    dcx2 = cross(v3, v4);
                    dcx3 = cross(v4, v5);
                    dcx4 = cross(v5, v2);

                    lambda = (-cx) / (norm(dcx1)^2/obj.m(p1) + norm(dcx2)^2/obj.m(p2) + norm(dcx3)^2/obj.m(p3) + norm(dcx4)^2/obj.m(p4) + obj.volalpha/(obj.dt*obj.dt));

                    obj.x(:,p1) = obj.x(:,p1) + 1/obj.m(p1) * dcx1 * lambda;
                    obj.x(:,p2) = obj.x(:,p2) + 1/obj.m(p2) * dcx2 * lambda;
                    obj.x(:,p3) = obj.x(:,p3) + 1/obj.m(p3) * dcx3 * lambda;
                    obj.x(:,p4) = obj.x(:,p4) + 1/obj.m(p4) * dcx4 * lambda;
                end
            end
            obj.v = (obj.x - x_old)/obj.dt;
            below_ground = obj.x(3,:) <= obj.ground + 1e-3;
            obj.v(3,below_ground) = -obj.v(3,below_ground);
            obj.v([1 2],below_ground) = obj.v([1 2],below_ground)*obj.friction;
            set(frame_txt, 'String', ['Frame: ', num2str(fr)]);
            set(ptch(:), 'Vertices', obj.x');
            drawnow;
            frame = getframe(fig);
            writeVideo(vid, frame);
        end
        close(vid);
        close(fig);
        end
    end
end