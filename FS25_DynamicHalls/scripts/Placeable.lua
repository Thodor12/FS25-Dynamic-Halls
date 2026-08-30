-- The DynamicHallsPlaceable specialization for the baseplate placeable. Reads the player's chosen
-- width/length configuration, then repositions every area marker that scales with the footprint
-- (leveling, testArea, tipOcclusionArea, collision floor) and builds the warning-stripe border.
-- Real vanilla base specializations (PlaceableLeveling, PlaceablePlacement, PlaceableTipOcclusionAreas)
-- run their own onLoad BEFORE this one and cache area data from the i3d's default (pre-resize) node
-- positions - each update* function below both repositions the relevant nodes AND forces that
-- cached data to be recomputed, or the area would silently keep using the wrong (default) size.
DynamicHallsPlaceable = {}

function DynamicHallsPlaceable.prerequisitesPresent(specializations)
    return true
end

function DynamicHallsPlaceable.initSpecialization()
    g_placeableConfigurationManager:addConfigurationType("dynamicHallsWidth", "Width", "dynamicHallsWidth",
        PlaceableConfigurationItem)
    g_placeableConfigurationManager:addConfigurationType("dynamicHallsLength", "Length", "dynamicHallsLength",
        PlaceableConfigurationItem)
end

function DynamicHallsPlaceable.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "updateLevelingArea", DynamicHallsPlaceable.updateLevelingArea)
    SpecializationUtil.registerFunction(placeableType, "updateTestArea", DynamicHallsPlaceable.updateTestArea)
    SpecializationUtil.registerFunction(placeableType, "updateTipOcclusionArea", DynamicHallsPlaceable.updateTipOcclusionArea)
    SpecializationUtil.registerFunction(placeableType, "updateCollisionFloor", DynamicHallsPlaceable.updateCollisionFloor)
end

function DynamicHallsPlaceable.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", DynamicHallsPlaceable)
end

function DynamicHallsPlaceable.registerXMLPaths(schema, basePath)
    local widthConfigPath = basePath ..
        ".dynamicHallsWidth.dynamicHallsWidthConfigurations.dynamicHallsWidthConfiguration(?)"
    schema:register(XMLValueType.FLOAT, widthConfigPath .. "#value", "Footprint width in meters")

    local lengthConfigPath = basePath ..
        ".dynamicHallsLength.dynamicHallsLengthConfigurations.dynamicHallsLengthConfiguration(?)"
    schema:register(XMLValueType.FLOAT, lengthConfigPath .. "#value", "Footprint length in meters")
end

function DynamicHallsPlaceable:onLoad(savegame)
    local spec = self["spec_FS25_DynamicHalls.dynamicHallsPlaceable"]

    local widthConfigurationId = Utils.getNoNil(self.configurations["dynamicHallsWidth"], 1)
    local widthConfigKey = string.format(
        "placeable.dynamicHallsWidth.dynamicHallsWidthConfigurations.dynamicHallsWidthConfiguration(%d)",
        widthConfigurationId - 1)
    spec.width = self.xmlFile:getValue(widthConfigKey .. "#value", 10)

    local lengthConfigurationId = Utils.getNoNil(self.configurations["dynamicHallsLength"], 1)
    local lengthConfigKey = string.format(
        "placeable.dynamicHallsLength.dynamicHallsLengthConfigurations.dynamicHallsLengthConfiguration(%d)",
        lengthConfigurationId - 1)
    spec.length = self.xmlFile:getValue(lengthConfigKey .. "#value", 10)

    self:updateLevelingArea(spec.width, spec.length)
    self:updateTestArea(spec.width, spec.length)
    self:updateTipOcclusionArea()
    self:updateCollisionFloor(spec.width, spec.length)

    DynamicHallsWarningStripe.build(self, spec.width, spec.length)
end

---Repositions the leveling area's start/width/height marker nodes to match the given footprint
-- size (plus DynamicHallsConstants.LEVELING_PADDING on every side), then forces PlaceableLeveling
-- to recompute its cached area data. levelWidth/levelHeight are children of levelStart (matching
-- real vanilla convention, confirmed against 10 real placeable i3d files), so their translations
-- are LOCAL OFFSETS from levelStart, not absolute/parent-relative positions. The recompute is
-- needed because PlaceableLeveling:onLoad (a base spec) already ran and cached area data from the
-- nodes' default (pre-resize) i3d positions, before this onLoad's setTranslation calls run.
-- @param float width footprint width in meters
-- @param float length footprint length in meters
function DynamicHallsPlaceable:updateLevelingArea(width, length)
    local startNode = self.xmlFile:getValue("placeable.leveling.levelAreas.levelArea(0)#startNode", nil,
        self.components, self.i3dMappings)
    local widthNode = self.xmlFile:getValue("placeable.leveling.levelAreas.levelArea(0)#widthNode", nil,
        self.components, self.i3dMappings)
    local heightNode = self.xmlFile:getValue("placeable.leveling.levelAreas.levelArea(0)#heightNode", nil,
        self.components, self.i3dMappings)

    local halfWidth = width / 2
    local halfLength = length / 2

    if startNode ~= nil then
        setTranslation(startNode, -halfWidth - DynamicHallsConstants.LEVELING_PADDING, 0,
            -halfLength - DynamicHallsConstants.LEVELING_PADDING)
    end

    if widthNode ~= nil then
        setTranslation(widthNode, 0, 0, length + 2 * DynamicHallsConstants.LEVELING_PADDING)
    end

    if heightNode ~= nil then
        setTranslation(heightNode, width + 2 * DynamicHallsConstants.LEVELING_PADDING, 0, 0)
    end

    local levelingSpec = self.spec_leveling
    if levelingSpec ~= nil and levelingSpec.levelAreas ~= nil then
        for i, area in ipairs(levelingSpec.levelAreas) do
            local key = string.format("placeable.leveling.levelAreas.levelArea(%d)", i - 1)
            self:loadLevelArea(self.xmlFile, key, area)
        end
    end
end

---Repositions the testArea start/end marker nodes to match the given (unpadded) footprint size,
-- then forces PlaceablePlacement to recompute its cached area data. PlaceablePlacement:onLoad (a
-- base spec) already cached spec_placement.testAreas[*].size/center from the i3d's default
-- (un-resized) node positions, before this onLoad's setTranslation calls run - the overlap check
-- (getHasOverlap/overlapBox) only ever reads that cached data, never live node transforms, so the
-- recompute is required for placement-overlap prevention to use the correct footprint size.
-- @param float width footprint width in meters
-- @param float length footprint length in meters
function DynamicHallsPlaceable:updateTestArea(width, length)
    local testAreaStartMapping = self.i3dMappings["testAreaStart"]
    local testAreaEndMapping = self.i3dMappings["testAreaEnd"]

    if testAreaStartMapping ~= nil then
        setTranslation(testAreaStartMapping.nodeId, -width / 2, 0, -length / 2)
    end

    if testAreaEndMapping ~= nil then
        setTranslation(testAreaEndMapping.nodeId, width, DynamicHallsConstants.TEST_AREA_HEIGHT, length)
    end

    local placementSpec = self.spec_placement
    if placementSpec ~= nil and placementSpec.testAreas ~= nil then
        for i, area in ipairs(placementSpec.testAreas) do
            local key = string.format("placeable.placement.testAreas.testArea(%d)", i - 1)
            self:loadTestArea(self.xmlFile, key, area)
        end
    end
end

---Forces PlaceableTipOcclusionAreas to recompute its cached area data, after the leveling markers
-- it reuses (levelWidth/levelHeight, see updateLevelingArea) have been repositioned.
-- tipOcclusionUpdateAreas is what ACTUALLY registers post-placement protection against the
-- terrain sculpting tool (confirmed empirically - this is unrelated to PlaceableLeveling /
-- placementCollisionMap, despite its schema description sounding like it's only about tip-pile /
-- material dumping). It reuses the leveling markers as its two opposing corners so it covers the
-- padded leveling footprint rather than the tighter testArea footprint - no dedicated nodes
-- needed. Same caching bug as testArea: PlaceableTipOcclusionAreas:onLoad already ran (a base
-- spec) and cached area.center/area.size from the nodes' default (pre-resize) positions via
-- loadTipOcclusionArea's localToLocal call, before the leveling markers were repositioned.
function DynamicHallsPlaceable:updateTipOcclusionArea()
    local tipOcclusionAreasSpec = self.spec_tipOcclusionAreas
    if tipOcclusionAreasSpec ~= nil and tipOcclusionAreasSpec.areas ~= nil then
        for i, area in ipairs(tipOcclusionAreasSpec.areas) do
            local key = string.format("placeable.tipOcclusionUpdateAreas.tipOcclusionUpdateArea(%d)", i - 1)
            self:loadTipOcclusionArea(self.xmlFile, key, area)
        end
    end
end

---Scales the collision floor to extend out to the warning stripe's outer edge (not just the bare
-- footprint), so there's always a small buffer of visible/walkable "owned" ground between the
-- building edge and the leveled/protected area's boundary - the building should never sit exactly
-- on the raw edge of the terrain deformation zone.
-- @param float width footprint width in meters
-- @param float length footprint length in meters
function DynamicHallsPlaceable:updateCollisionFloor(width, length)
    local collisionFloorMapping = self.i3dMappings["collisionFloor"]
    if collisionFloorMapping ~= nil then
        setTranslation(collisionFloorMapping.nodeId, 0, 0, 0)
        setScale(collisionFloorMapping.nodeId, width + DynamicHallsConstants.STRIP_THICKNESS * 2, 1,
            length + DynamicHallsConstants.STRIP_THICKNESS * 2)
    end
end
