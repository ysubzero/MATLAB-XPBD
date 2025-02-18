function saveMesh(x, faces, constraints, vol_constraints, filename)
    [rows, cols] = size(x);

    fileID = fopen(filename, 'w');

    if fileID == -1
        error('Could not open file for writing.');
    end

    for i = 1:cols
        fprintf(fileID, 'x ');
        for j = 1:rows
            fprintf(fileID, '%g ', x(j, i));
        end
        fprintf(fileID, '\n');
    end

    [rows, cols] = size(faces);

    for i = 1:rows
        fprintf(fileID, 'f ');
        for j = 1:cols
            fprintf(fileID, '%g ', faces(i, j));
        end
        fprintf(fileID, '\n');
    end

    [rows, cols] = size(constraints);

    for i = 1:rows
        fprintf(fileID, 'c ');
        for j = 1:cols
            fprintf(fileID, '%g ', constraints(i, j));
        end
        fprintf(fileID, '\n');
    end

    [rows, cols] = size(vol_constraints);

    for i = 1:rows
        fprintf(fileID, 'v ');
        for j = 1:cols
            fprintf(fileID, '%g ', vol_constraints(i, j));
        end
        fprintf(fileID, '\n');
    end

    fclose(fileID);
end