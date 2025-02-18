function [vertices, faces] = loadMeshObj(filename)
    fileID = fopen(filename, 'r');
    vertices = [];
    faces = [];

    line = fgetl(fileID);
    while ischar(line)
        if startsWith(line, 'v ')
            coords = sscanf(line,'v %f %f %f');
            vertices = [vertices, coords];
        elseif startsWith(line, 'f ')
            indices = sscanf(line,'f %d %d %d');
            faces = [faces; indices'];
        end
        line = fgetl(fileID);
    end
    fclose(fileID);

end