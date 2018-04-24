function tracks = detectMarkersCat(fname)    
    settings = getDefaultSettings();
    
    obj = setupSystemObjects(fname);
    tracks = initializeTracks(); 
    
    nextId = 1; 

    while hasFrame(obj.reader)
        frame = readFrame(obj.reader);
        [centroids, bboxes, mask] = detectObjects(frame);
        predictNewLocationsOfTracks();
        [assignments, unassignedTracks, unassignedDetections] = ...
            detectionToTrackAssignment();

        updateAssignedTracks();
        updateUnassignedTracks();
        deleteLostTracks();
        createNewTracks();

        displayTrackingResults();
    end
    
    function settings = getDefaultSettings()
        settings = struct();
        settings.colorCoefs = [1 -0.5 -0.5]; % red default
        settings.colorThreshold = 40;
        settings.blobSize = 200;        
    end

    function obj = setupSystemObjects(fname)
        % ?????????????? ??????/?????? ????? + blobAnalyzer ??? ???????
        % ?????????

        obj.reader = VideoReader(fname);

        obj.maskPlayer = vision.VideoPlayer('Position', [740, 400, 700, 400]);
        obj.videoPlayer = vision.VideoPlayer('Position', [20, 400, 700, 400]);

        obj.blobAnalyser = vision.BlobAnalysis('BoundingBoxOutputPort', true, ...
            'AreaOutputPort', true, 'CentroidOutputPort', true, ...
            'MinimumBlobArea', settings.blobSize);
    end

     function tracks = initializeTracks()
        tracks = struct(...
            'id', {}, ...
            'bbox', {}, ...
            'kalmanFilter', {}, ...
            'age', {}, ...
            'totalVisibleCount', {}, ...
            'consecutiveInvisibleCount', {}, ...
            'history', cell({}), ...
            'name', 'unnamed');
     end

    function mask = detectWithColor(img)
        % ? ?????? ?????? ???????? ??????? ???????? ??????
        % ????????? ????? ??? ??? ??????? ? ???????.
        r = double(img(:,:,1));
        g = double(img(:,:,2));
        b = double(img(:,:,3));

        justRed = r*settings.colorCoefs(1) + ...
                  g*settings.colorCoefs(2) + ...
                  b*settings.colorCoefs(3);

        mask = justRed > settings.colorThreshold;
    end

    function [centroids, bboxes, mask] = detectObjects(frame)
        % ?????????????? ?????, ?????????? ?????? ?? ??????
        mask = detectWithColor(frame);

        % ??????? ???
        mask = imopen(mask, strel('rectangle', [6, 6]));
        mask = imclose(mask, strel('rectangle', [50, 50]));
        mask = imfill(mask, 'holes');

        % ??????? ??????????
        [~, centroids, bboxes] = obj.blobAnalyser.step(mask);
    end

    function predictNewLocationsOfTracks()
        for i = 1:length(tracks)
            bbox = tracks(i).bbox;

            predictedCentroid = predict(tracks(i).kalmanFilter);

            % ???????? ??????? ??????? ? ??????????????
            predictedCentroid = int32(predictedCentroid) - bbox(3:4) / 2;
            tracks(i).history{end + 1} = tracks(i).bbox;
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
                'history', cell({bbox}), ...
                'name', string(nextId));
            
            newTrack.history = cell({bbox});
            tracks(end + 1) = newTrack;

            nextId = nextId + 1;
        end
    end

    function displayTrackingResults()
        % ????? ?????? ???? uint8, ? ?? ???????
        mask = uint8(repmat(mask, [1, 1, 3])) .* 255;

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
            end
        end
        
        obj.maskPlayer.step(mask);
        obj.videoPlayer.step(frame);
    end
end