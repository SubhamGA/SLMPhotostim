function fovMap = createFovMap(matrixSize, numRegions)
    % This function creates a fovMap for a given matrix size divided into
    % a specified number of square regions (must be a perfect square number).
    
    if sqrt(numRegions) ~= round(sqrt(numRegions))
        error('Number of regions must be a perfect square');
    end
    
    regionsPerSide = sqrt(numRegions);
    regionSize = matrixSize / regionsPerSide;
    
    fovMap = zeros(matrixSize); % Initialize the fovMap matrix
    
    % Assign unique labels to each region
    label = 0;
    for row = 1:regionsPerSide
        for col = 1:regionsPerSide
            label = label + 1;
            xStart = (row-1) * regionSize + 1;
            yStart = (col-1) * regionSize + 1;
            xEnd = row * regionSize;
            yEnd = col * regionSize;
            fovMap(xStart:xEnd, yStart:yEnd) = label;
        end
    end
    
    % If needed, adjust to use different numbering or labeling.
end

% Create the fovMap
fovMap = createFovMap(512, 4);

% Display the fovMap in grayscale
figure;
imagesc(fovMap);
colormap(gray(4)); % Using 4 shades of gray for 4 regions