function stimGrps = makeStimGrps(stimBit,fovMap,minDist)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The purpose of this script is to make stim groups based on a provided
% mask image

% Inputs:
% - stimBit         = stimulus bitmap matrix
% - fovMap          = map of regions e.g. microzones

% Outputs:
% - stimGrps      = cell array containing masked stim maps and data points

% Dimitar Kostadinov 2024-05-10
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Loop through and do indexing using AND operator
stimGrps = struct;

mapIdx = unique(fovMap);
for iMaps = 1:numel(mapIdx)
    mapPts = fovMap == mapIdx(iMaps);
    
    for jStim = 1:size(stimBit,3)
        stimPageAll = stimBit(:,:,jStim) > 0;
        stimPage = stimPageAll & mapPts;
        [stimPtsX, stimPtsY] = ind2sub(size(stimPage),find(stimPage));
        
        stimGrps(jStim).stimPageAll = stimPageAll;
        stimGrps(jStim).mapPts(:,:,iMaps) = mapPts;
        stimGrps(jStim).stimMap(:,:,iMaps) = stimPage;
        stimGrps(jStim).stimPts{iMaps,1} = [stimPtsX stimPtsY];
        
        % Generate centroids
        if numel(stimPtsX) == 1 % Deal with a single point
            % Move x points towards center
            reCtrX = [stimPtsX-size(fovMap,1)/2];
            if reCtrX > 0 %#ok<BDSCI>
                stimCtrX = stimPtsX - sqrt(2)/2*minDist;
            else
                stimCtrX = stimPtsX + sqrt(2)/2*minDist;
            end
            % Move y points towards center
            reCtrY = [stimPtsY-size(fovMap,2)/2];
            if reCtrY > 0 %#ok<BDSCI>
                stimCtrY = stimPtsY - sqrt(2)/2*minDist;
            else
                stimCtrY = stimPtsY + sqrt(2)/2*minDist;
            end
        elseif numel(stimPtsX) == 2 % deal with 2 points
            stimCtrX = mean(stimPtsX);
            stimCtrY = mean(stimPtsY);
            allDists = pdist2([stimCtrX stimCtrY], [stimPtsX stimPtsY])';
            
            if any(allDists < minDist)
                % Calculate angle between 2 points and move orthogonally
                % towards the center
                closestDist = min(allDists);
                dist2Mov = sqrt(minDist^2-closestDist^2);
                theta = atan(diff(stimPtsY)/diff(stimPtsX)); if theta < 0; theta = theta + pi()/2; end
                orthTheta = theta + pi()/2;
                xMov = dist2Mov*cos(orthTheta);
                yMov = dist2Mov*sin(orthTheta);
                reCtrX = [stimCtrX-size(fovMap,1)/2];
                reCtrY = [stimCtrY-size(fovMap,2)/2];
                
                % Move x points towards center
                if reCtrX > 0
                    stimCtrX = stimCtrX - xMov;
                else
                    stimCtrX = stimCtrX + xMov;
                end
                % Move x points towards center
                if reCtrY > 0
                    stimCtrY = stimCtrY - yMov;
                else
                    stimCtrY = stimCtrY + yMov;
                end
            end
            
        elseif numel(stimPtsX) >= 3
                [stimCtrX, stimCtrY] = centroid(polyshape(stimPtsX, stimPtsY));
                allDists = pdist2([stimCtrX, stimCtrY], [stimPtsX, stimPtsY]);

                % Iterative adjustment with boundary and minimum distance checks
                maxIter = 100;  % Prevent infinite loops by setting a maximum number of iterations
                iter = 0;
                while any(allDists < minDist) && iter < maxIter
                    idx = find(allDists < minDist, 1);
                    tooCloseX = stimPtsX(idx);
                    tooCloseY = stimPtsY(idx);

                    % Calculate direction to move the centroid
                    dirX = sign(stimCtrX - tooCloseX);
                    dirY = sign(stimCtrY - tooCloseY);

                    % Boundary and direction check
                    if (stimCtrX + dirX * minDist > 512 || stimCtrX + dirX * minDist < 1)
                        dirX = -dirX;  % Reverse direction if out of bounds
                    end
                    if (stimCtrY + dirY * minDist > 512 || stimCtrY + dirY * minDist < 1)
                        dirY = -dirY;  % Reverse direction if out of bounds
                    end

                    % Update the centroid position
                    stimCtrX = stimCtrX + dirX * (minDist - allDists(idx) + 0.1);
                    stimCtrY = stimCtrY + dirY * (minDist - allDists(idx) + 0.1);

                    % Update distances
                    allDists = pdist2([stimCtrX, stimCtrY], [stimPtsX, stimPtsY]);
                    iter = iter + 1;  % Increment iteration counter
                end

            stimGrps(jStim).stimCtrs{iMaps, 1} = [round(stimCtrX), round(stimCtrY)];
        end
        stimGrps(jStim).stimCtrs{iMaps,1} = [round(stimCtrX) round(stimCtrY)];
    end
end