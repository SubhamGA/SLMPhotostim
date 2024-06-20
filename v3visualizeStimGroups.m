function v3visualizeStimGroups(stimGrps, fovMap)
    % Visualizes stimulus groups with their centroids and connections between centroids and stimulus points.

    figure;
    imshow(label2rgb(fovMap, 'jet', 'k', 'shuffle')); % Display the fovMap with distinct colors
    hold on;

    % Define colors for each group (ensure enough colors for all groups)
    numGroups = max(arrayfun(@(x) numel(x.subGroups), stimGrps));
    colors = lines(max(20, numGroups));

    % Loop through each stimulus in stimGrps
    for jStim = 1:numel(stimGrps)
        % Access the group details
        group = stimGrps(jStim);

        % Loop through each map in the group
        for iMaps = 1:size(group.subGroups, 1)
            % Loop through each centroid/subgroup in the current map
            for iSub = 1:size(group.subGroups, 2)
                if isempty(group.subGroups{iMaps, iSub})
                    continue; % Skip if no points for this subgroup
                end
                
                % Extract the subgroup
                subgroup = group.subGroups{iMaps, iSub};

                % Draw stimulus points
                pts = subgroup.points;
                scatter(pts(:,2), pts(:,1), 36, colors(iSub, :), 'filled'); % Use iSub to ensure distinct colors per subgroup

                % Draw centroid if available
                if ~isempty(group.stimCtrs{iMaps, iSub})
                    ctr = group.stimCtrs{iMaps, iSub};
                    scatter(ctr(2), ctr(1), 100, colors(iSub, :), 's', 'filled'); % Large square for the centroid

                    % Draw lines from centroid to each point
                    for k = 1:size(pts, 1)
                        plot([ctr(2), pts(k,2)], [ctr(1), pts(k,1)], 'Color', colors(iSub, :));
                    end
                end
            end
        end
    end

    hold off;
    title('Visualization of Stimulus Groups and Centroids');
end
