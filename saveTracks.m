function saveTracks(tracks, fname)
    getCentroid = @(bbox) [bbox(1) + bbox(3)/2 bbox(2) + bbox(4)/2];
    centroids = {};
    
    for i = 1:numel(tracks)
        centroids{i} = cellfun(getCentroid, tracks(i).history, 'UniformOutput', 0);
    end
    
    fid = fopen(fname, 'w');
    
    if fid < 0
        error('Wtf, cannot open the file!');
        return;
    end
    
    fprintf(fid, "sep=;\n");
    
    for i = 1:numel(tracks) - 1
        fprintf(fid,'%d;',tracks(i).name);
    end
    fprintf(fid, '%d\n', tracks(end).name);
    
    for i = 1:numel(centroids{1})
        for j = 1:numel(centroids) - 1
            fprintf(fid, "%.3f,%.3f;", centroids{j}{i}(1), centroids{j}{i}(2));
        end
        fprintf(fid, "%.3f,%.3f\n", centroids{end}{i}(1), centroids{end}{i}(2));
    end
    
    fclose(fid);
end