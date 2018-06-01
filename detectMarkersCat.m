function tracks = detectMarkersCat(fname, options)
    if ~isfield(options, 'use_pixels'), options.use_pixels=true; end
    if ~isfield(options, 'play_video'), options.play_video=true; end
    if ~isfield(options, 'use_morphology'), options.use_morphology=true; end
    
%     textprogressbar(fname);
    
    settings = fillSettings(options);
    
    [obj, blobs] = setupSystemObjects(fname);
    tracks = initializeTracks();    
    
    nextId = 1; 
    frameCount = 0;
    
    while hasFrame(obj.reader)
        frame = readFrame(obj.reader);
        frameCount = frameCount + 1;
        
        [centroids, bboxes, mask] = detectObjects(frame);
        predictNewLocationsOfTracks();
        [assignments, unassignedTracks, unassignedDetections] = ...
            detectionToTrackAssignment();
        
        updateAssignedTracks();
        updateUnassignedTracks();
        deleteLostTracks();
        createNewTracks();
        
        if options.play_video
            displayTrackingResults();
        end
        
%         textprogressbar(obj.reader.CurrentTime/obj.reader.Duration*100);
    end
    
    saveTracks(tracks, fname);
    fprintf('video %s processed!\n', fname);
%     textprogressbar('done');
   
    function settings=fillSettings(options)
        settings = struct();
        
        reader = VideoReader(fname);
        frame = readFrame(reader);
        
        if ~options.use_pixels
            settings.sizeRatio = setSize(frame);
        else
            settings.sizeRatio = 1.;
        end
        
        if isfield(options, 'detectorSettings')
            settings.detectorSettings = options.detectorSettings;
        else
            settings.detectorSettings = selectThreshold(reader);
        end
    end

    function [obj, blobs] = setupSystemObjects(fname)
        % ?????????????? ??????/?????? ????? + blobAnalyzer ??? ???????
        % ?????????

        obj.reader = VideoReader(fname);
        
        if options.play_video
            obj.maskPlayer = vision.VideoPlayer('Position', [740, 400, 700, 400]);
            obj.videoPlayer = vision.VideoPlayer('Position', [20, 400, 700, 400]);
        end
        
        blobs = cell({});
        
        for i = 1:numel(settings.detectorSettings)
             blobAnalyser = vision.BlobAnalysis('BoundingBoxOutputPort', true, ...
                                'AreaOutputPort', true, 'CentroidOutputPort', true, ...
                                'MinimumBlobArea', settings.detectorSettings{i}.minBlobSize, ...
                                'MaximumBlobArea', settings.detectorSettings{i}.maxBlobSize);
                            
             blobs{i} = blobAnalyser;
        end


    end

    function tracks = initializeTracks()
        tracks = struct(...
            'id', {}, ...
            'bbox', {}, ...
            'kalmanFilter', {}, ...
            'age', {}, ...
            'totalVisibleCount', {}, ...
            'consecutiveInvisibleCount', {}, ...
            'history', [], ...
            'name', 'unnamed');
    end

    function mask = detectWithColor(img, params)
        % ? ?????? ?????? ???????? ??????? ???????? ??????
        % ????????? ????? ??? ??? ??????? ? ???????.      
        r = double(img(:,:,1));
        g = double(img(:,:,2));
        b = double(img(:,:,3));
     
        curr_color = params.colorCoefs(1)*r + ...
                      params.colorCoefs(2)*g + ...
                      params.colorCoefs(3)*b;    

        mask = curr_color > params.colorThreshold;
    end

    function [centroids, bboxes, mask] = detectObjects(frame)
        % ?????????????? ?????, ?????????? ?????? ?? ??????
        
        centroids = [];
        bboxes = [];
        mask = zeros(size(frame, 1), size(frame, 2), 'uint8');
        
        for i = 1:numel(settings.detectorSettings)
            curr_mask = detectWithColor(frame, settings.detectorSettings{i});

            % ??????? ???
            if options.use_morphology
                curr_mask = imopen(curr_mask, strel('rectangle', [6, 6]));
                curr_mask = imclose(curr_mask, strel('rectangle', [50, 50]));
                curr_mask = imfill(curr_mask, 'holes');
            end

            % ??????? ??????????
            [~, curr_centroids, curr_bboxes] = blobs{i}.step(curr_mask);
            
            centroids = vertcat(centroids, curr_centroids);
            bboxes = vertcat(bboxes, curr_bboxes);
            
            mask = mask | curr_mask;
        end
    end

    function predictNewLocationsOfTracks()
        for i = 1:length(tracks)
            bbox = tracks(i).bbox;

            predictedCentroid = predict(tracks(i).kalmanFilter);

            % ???????? ??????? ??????? ? ??????????????
            predictedCentroid = int32(predictedCentroid) - bbox(3:4) / 2;
            tracks(i).history = vertcat(tracks(i).history, tracks(i).bbox);
            tracks(i).bbox = [predictedCentroid, bbox(3:4)];
        end
    end

    function [assignments, unassignedTracks, unassignedDetections] = ...
            detectionToTrackAssignment()

        nTracks = length(tracks);
        nDetections = size(centroids, 1);

        cost = zeros(nTracks, nDetections);
        for i = 1:nTracks
            cost(i, :) = distance(tracks(i).kalmanFilter, centroids);
        end
        
        % ?????? ???? ??? ????? ??????
        costOfNonAssignment = 20;
        [assignments, unassignedTracks, unassignedDetections] = ...
            assignDetectionsToTracks(cost, costOfNonAssignment);
    end

    function updateAssignedTracks()
        numAssignedTracks = size(assignments, 1);
        for i = 1:numAssignedTracks
            trackIdx = assignments(i, 1);
            detectionIdx = assignments(i, 2);
            centroid = centroids(detectionIdx, :);
            bbox = bboxes(detectionIdx, :);

            correct(tracks(trackIdx).kalmanFilter, centroid);

            tracks(trackIdx).bbox = bbox;
            tracks(trackIdx).age = tracks(trackIdx).age + 1;
            tracks(trackIdx).totalVisibleCount = ...
                tracks(trackIdx).totalVisibleCount + 1;
            tracks(trackIdx).consecutiveInvisibleCount = 0;
        end
    end

    function updateUnassignedTracks()
        for i = 1:length(unassignedTracks)
            ind = unassignedTracks(i);
            tracks(ind).age = tracks(ind).age + 1;
            tracks(ind).consecutiveInvisibleCount = ...
                tracks(ind).consecutiveInvisibleCount + 1;
        end
    end

    function deleteLostTracks()
        if isempty(tracks)
            return;
        end

        invisibleForTooLong = 20;
        ageThreshold = 8;

        ages = [tracks(:).age];
        totalVisibleCounts = [tracks(:).totalVisibleCount];
        visibility = totalVisibleCounts ./ ages;

        lostInds = (ages < ageThreshold & visibility < 0.6) | ...
            [tracks(:).consecutiveInvisibleCount] >= invisibleForTooLong;

        tracks = tracks(~lostInds);
    end

    function createNewTracks()
        centroids = centroids(unassignedDetections, :);
        bboxes = bboxes(unassignedDetections, :);

        for i = 1:size(centroids, 1)

            centroid = centroids(i,:);
            bbox = bboxes(i, :);

            % Create a Kalman filter object.
            kalmanFilter = configureKalmanFilter('ConstantVelocity', ...
                centroid, [200, 50], [100, 25], 100);

            % Create a new track.
            newTrack = struct(...
                'id', nextId, ...
                'bbox', bbox, ...
                'kalmanFilter', kalmanFilter, ...
                'age', 1, ...
                'totalVisibleCount', 1, ...
                'consecutiveInvisibleCount', 0, ...
                'history', bbox, ...
                'name', int2str(nextId));
            
            tracks(end + 1) = newTrack;

            nextId = nextId + 1;
        end
    end

    function displayTrackingResults()
        % ????? ?????? ???? uint8, ? ?? ???????
        mask = uint8(repmat(mask, [1, 1, 3])) .* 255;
        
        mask_detected = mask;
        frame_detected = frame;
        
        minVisibleCount = 8;
        if ~isempty(tracks)
            reliableTrackInds = ...
                [tracks(:).totalVisibleCount] > minVisibleCount;
            reliableTracks = tracks(reliableTrackInds);

            if ~isempty(reliableTracks)
                bboxes = cat(1, reliableTracks.bbox);

                ids = int32([reliableTracks(:).id]);
                labels = cellstr(int2str(ids'));
                predictedTrackInds = ...
                    [reliableTracks(:).consecutiveInvisibleCount] > 0;
                isPredicted = cell(size(labels));
                isPredicted(predictedTrackInds) = {' predicted'};
                labels = strcat(labels, isPredicted);

                frame = insertObjectAnnotation(frame, 'rectangle', ...
                    bboxes, labels);
                mask = insertObjectAnnotation(mask, 'rectangle', ...
                    bboxes, labels);
                
                if options.debug
                    if any(predictedTrackInds)
                        correctIdx = find(cellfun(@(c) ~isempty(c), isPredicted));

                        frame_detected = insertObjectAnnotation(frame_detected, 'rectangle', ...
                            bboxes(correctIdx, :), labels(correctIdx));
                        mask_detected = insertObjectAnnotation(mask_detected, 'rectangle', ...
                            bboxes(correctIdx, :), labels(correctIdx));

                        imwrite(frame_detected, sprintf('%s_%d_frame.png', fname, frameCount));
                        imwrite(mask_detected, sprintf('%s_%d_mask.png', fname, frameCount));
                    end
                end
            end
        end
                
        obj.maskPlayer.step(mask);
        obj.videoPlayer.step(frame);
    end

    function saveTracks(tracks, fname)
        getCentroid = @(bbox) [bbox(1) + bbox(3)/2 bbox(2) + bbox(4)/2]*settings.sizeRatio;
        centroids = {};

        for i = 1:numel(tracks)
            centroids{i} = cellfun(getCentroid, num2cell(tracks(i).history, 2), 'UniformOutput', 0);
        end

        save(strcat(fname, '_centroids', 'centroids'));
    end
end