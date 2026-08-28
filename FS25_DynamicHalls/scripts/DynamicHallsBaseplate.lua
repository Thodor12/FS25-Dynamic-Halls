DynamicHallsBaseplate = {}

function DynamicHallsBaseplate.prerequisitesPresent(specializations)
    return true
end

function DynamicHallsBaseplate.initSpecialization()
    g_placeableConfigurationManager:addConfigurationType("dynamicHallsWidth", "Width", "dynamicHallsWidth", PlaceableConfigurationItem)
    g_placeableConfigurationManager:addConfigurationType("dynamicHallsLength", "Length", "dynamicHallsLength", PlaceableConfigurationItem)
end

function DynamicHallsBaseplate.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", DynamicHallsBaseplate)
end

function DynamicHallsBaseplate.registerXMLPaths(schema, basePath)
    local widthConfigPath = basePath .. ".dynamicHallsWidth.dynamicHallsWidthConfigurations.dynamicHallsWidthConfiguration(?)"
    schema:register(XMLValueType.FLOAT, widthConfigPath .. "#value", "Footprint width in meters")

    local lengthConfigPath = basePath .. ".dynamicHallsLength.dynamicHallsLengthConfigurations.dynamicHallsLengthConfiguration(?)"
    schema:register(XMLValueType.FLOAT, lengthConfigPath .. "#value", "Footprint length in meters")
end

function DynamicHallsBaseplate:onLoad(savegame)
    local spec = self["spec_FS25_DynamicHalls.dynamicHallsBaseplate"]

    local widthConfigurationId = Utils.getNoNil(self.configurations["dynamicHallsWidth"], 1)
    local widthConfigKey = string.format("placeable.dynamicHallsWidth.dynamicHallsWidthConfigurations.dynamicHallsWidthConfiguration(%d)", widthConfigurationId - 1)
    spec.width = self.xmlFile:getValue(widthConfigKey .. "#value", 10)

    local lengthConfigurationId = Utils.getNoNil(self.configurations["dynamicHallsLength"], 1)
    local lengthConfigKey = string.format("placeable.dynamicHallsLength.dynamicHallsLengthConfigurations.dynamicHallsLengthConfiguration(%d)", lengthConfigurationId - 1)
    spec.length = self.xmlFile:getValue(lengthConfigKey .. "#value", 10)

    local startNode = self.xmlFile:getValue("placeable.leveling.levelAreas.levelArea(0)#startNode", nil, self.components, self.i3dMappings)
    local widthNode = self.xmlFile:getValue("placeable.leveling.levelAreas.levelArea(0)#widthNode", nil, self.components, self.i3dMappings)
    local heightNode = self.xmlFile:getValue("placeable.leveling.levelAreas.levelArea(0)#heightNode", nil, self.components, self.i3dMappings)

    local levelingPad = 2
    local halfWidth = spec.width / 2
    local halfLength = spec.length / 2

    -- levelWidth/levelHeight are children of levelStart (matching real vanilla convention,
    -- confirmed against 10 real placeable i3d files), so their translations are LOCAL OFFSETS
    -- from levelStart, not absolute/parent-relative positions.
    if startNode ~= nil then
        setTranslation(startNode, -halfWidth - levelingPad, 0, -halfLength - levelingPad)
    end

    if widthNode ~= nil then
        setTranslation(widthNode, 0, 0, spec.length + 2 * levelingPad)
    end

    if heightNode ~= nil then
        setTranslation(heightNode, spec.width + 2 * levelingPad, 0, 0)
    end

    -- Mirror the testAreas fix below: force PlaceableLeveling to recompute anything it may have
    -- cached from the levelArea nodes' default (pre-resize) positions.
    local levelingSpec = self.spec_leveling
    if levelingSpec ~= nil and levelingSpec.levelAreas ~= nil then
        for i, area in ipairs(levelingSpec.levelAreas) do
            local key = string.format("placeable.leveling.levelAreas.levelArea(%d)", i - 1)
            self:loadLevelArea(self.xmlFile, key, area)
        end
    end

    local testAreaStartMapping = self.i3dMappings["testAreaStart"]
    local testAreaEndMapping = self.i3dMappings["testAreaEnd"]
    local testAreaHeight = 10

    if testAreaStartMapping ~= nil then
        setTranslation(testAreaStartMapping.nodeId, -halfWidth, 0, -halfLength)
    end

    if testAreaEndMapping ~= nil then
        setTranslation(testAreaEndMapping.nodeId, spec.width, testAreaHeight, spec.length)
    end

    -- PlaceablePlacement:onLoad already cached spec_placement.testAreas[*].size/center from the
    -- i3d's default (un-resized) node positions, BEFORE the setTranslation calls above ran. The
    -- overlap check (getHasOverlap/overlapBox) only ever reads that cached data, never live node
    -- transforms, so we have to force a recompute now that the nodes are correctly positioned.
    local placementSpec = self.spec_placement
    if placementSpec ~= nil and placementSpec.testAreas ~= nil then
        for i, area in ipairs(placementSpec.testAreas) do
            local key = string.format("placeable.placement.testAreas.testArea(%d)", i - 1)
            self:loadTestArea(self.xmlFile, key, area)
        end
    end

    -- tipOcclusionUpdateAreas is what ACTUALLY registers post-placement protection against the
    -- terrain sculpting tool (confirmed empirically - this is unrelated to PlaceableLeveling /
    -- placementCollisionMap, despite its schema description sounding like it's only about
    -- tip-pile/material dumping). It reuses levelWidth/levelHeight (already repositioned above)
    -- as its two opposing corners, so it covers the padded leveling footprint rather than the
    -- tighter testArea footprint - no dedicated nodes needed.

    -- Same caching bug as testAreas: PlaceableTipOcclusionAreas:onLoad already ran (base specs
    -- load before ours) and cached area.center/area.size from the nodes' default (pre-resize)
    -- positions via loadTipOcclusionArea's localToLocal call. Force a recompute now that the
    -- nodes are correctly positioned.
    local tipOcclusionAreasSpec = self.spec_tipOcclusionAreas
    if tipOcclusionAreasSpec ~= nil and tipOcclusionAreasSpec.areas ~= nil then
        for i, area in ipairs(tipOcclusionAreasSpec.areas) do
            local key = string.format("placeable.tipOcclusionUpdateAreas.tipOcclusionUpdateArea(%d)", i - 1)
            self:loadTipOcclusionArea(self.xmlFile, key, area)
        end
    end

    local stripThickness = 0.5
    local stripHeight = 0.01
    local tileLength = 10
    local outerHalfWidth = halfWidth + stripThickness / 2
    local outerHalfLength = halfLength + stripThickness / 2

    -- Extend the collision floor out to the warning stripe's outer edge (not just the bare
    -- footprint), so there's always a small buffer of visible/walkable "owned" ground between the
    -- building edge and the leveled/protected area's boundary - the building should never sit
    -- exactly on the raw edge of the terrain deformation zone.
    local collisionFloorMapping = self.i3dMappings["collisionFloor"]
    if collisionFloorMapping ~= nil then
        setTranslation(collisionFloorMapping.nodeId, 0, 0, 0)
        setScale(collisionFloorMapping.nodeId, spec.width + stripThickness * 2, 1, spec.length + stripThickness * 2)
    end

    local tileHorizontalMapping = self.i3dMappings["tileHorizontal"]
    local tileVerticalMapping = self.i3dMappings["tileVertical"]
    local tileCornerMapping = self.i3dMappings["tileCorner"]
    local tileCornerInvertedMapping = self.i3dMappings["tileCornerInverted"]

    if tileHorizontalMapping ~= nil and tileVerticalMapping ~= nil and tileCornerMapping ~= nil and tileCornerInvertedMapping ~= nil then
        local rootNodeId = getParent(tileHorizontalMapping.nodeId)
        local numTilesWidth = spec.width / tileLength
        local numTilesLength = spec.length / tileLength

        local function placeClone(templateNodeId, x, z, rotateY)
            local nodeId = clone(templateNodeId, false, false, false)
            link(rootNodeId, nodeId)
            setTranslation(nodeId, x, stripHeight, z)
            if rotateY then
                setRotation(nodeId, 0, math.pi, 0)
            end
        end

        -- Top and bottom rows (horizontal tiles running along X, spanning exactly spec.width, sitting just outside the footprint)
        for i = 0, numTilesWidth - 1 do
            local tileX = -halfWidth + tileLength / 2 + i * tileLength
            placeClone(tileHorizontalMapping.nodeId, tileX, outerHalfLength, true)
            placeClone(tileHorizontalMapping.nodeId, tileX, -outerHalfLength, false)
        end

        -- Left and right columns (vertical tiles running along Z, spanning exactly spec.length, sitting just outside the footprint)
        for i = 0, numTilesLength - 1 do
            local tileZ = -halfLength + tileLength / 2 + i * tileLength
            placeClone(tileVerticalMapping.nodeId, -outerHalfWidth, tileZ, true)
            placeClone(tileVerticalMapping.nodeId, outerHalfWidth, tileZ, false)
        end

        -- 4 corner tiles filling the small gap left between the horizontal and vertical runs
        -- Top-right and bottom-left use the inverted variant; top-left and bottom-right use the normal one
        placeClone(tileCornerMapping.nodeId, -outerHalfWidth, outerHalfLength, false)
        placeClone(tileCornerInvertedMapping.nodeId, outerHalfWidth, outerHalfLength, false)
        placeClone(tileCornerInvertedMapping.nodeId, -outerHalfWidth, -outerHalfLength, false)
        placeClone(tileCornerMapping.nodeId, outerHalfWidth, -outerHalfLength, false)

        delete(tileHorizontalMapping.nodeId)
        delete(tileVerticalMapping.nodeId)
        delete(tileCornerMapping.nodeId)
        delete(tileCornerInvertedMapping.nodeId)
    end
end
