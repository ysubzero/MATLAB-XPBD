function [x, faces, constraints, vol_constraints] = readMesh(filename)
    fileID = fopen(filename, 'r');
    x = [];
    faces = [];
    constraints = [];
    vol_constraints = [];

    line = fgetl(fileID);
    while ischar(line)
        if startsWith(line, 'x ')
            coords = sscanf(line,'x %f %f %f');
            x = [x, coords];
        elseif startsWith(line, 'f ')
            indices = sscanf(line,'f %d %d %d');
            faces = [faces; indices'];
        elseif startsWith(line, 'c ')
            constrain = sscanf(line,'c %d %d %g');
            constraints = [constraints; constrain'];
        elseif startsWith(line, 'v ')
            volconstrain = sscanf(line,'v %d %d %d %d %g');
            vol_constraints = [vol_constraints; volconstrain'];
        end
        line = fgetl(fileID);
    end
    fclose(fileID);
end
