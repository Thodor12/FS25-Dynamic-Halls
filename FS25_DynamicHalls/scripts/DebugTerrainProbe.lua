-- TEMPORARY DEBUG TOOL — not part of the mod's real functionality.
-- Registers a console command to test whether a spot 1m in front of the player is
-- protected from terrain deformation by an already-placed placeable's leveling area.
-- Usage (in FS25's dev console): dhProbeDeform
-- Stand facing the spot you want to test, then run the command. Logs the deformation
-- result (success / blocked, and by what) instead of guessing from visual inspection.

DebugTerrainProbe = {}

function DebugTerrainProbe.consoleCommandProbeDeform()
    if g_localPlayer == nil then
        Logging.info("DebugTerrainProbe: no local player found")
        return
    end

    local px, _, pz = g_localPlayer:getPosition()
    local dirX, _, dirZ = localDirectionToWorld(g_localPlayer.rootNode, 0, 0, 1)
    local x = px + dirX * 1
    local z = pz + dirZ * 1
    local y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)

    local deformationObject = TerrainDeformation.new(g_terrainNode)

    -- Same as PlaceableLeveling:getDeformationObjects - without setting the blocked area map,
    -- the deformation query has nothing to check existing blocks against at all.
    if g_densityMapHeightManager.placementCollisionMap ~= nil then
        deformationObject:setBlockedAreaMap(g_densityMapHeightManager.placementCollisionMap, 0)
    else
        Logging.info("DebugTerrainProbe: placementCollisionMap is nil - block detection will not work")
    end

    -- IMPORTANT: a flat area at the CURRENT terrain height produces volume=0 "SUCCESS" whether
    -- or not the spot is actually blocked, since there's nothing to displace either way. Request
    -- a real 1m-deep pit instead so a SUCCESS result can only mean genuinely unblocked.
    local halfSize = 0.5
    local pitDepth = 1.0
    deformationObject:addArea(
        x - halfSize, y - pitDepth, z - halfSize,
        1, 0, 0,
        0, 0, 1,
        -1,
        false
    )

    local target = {}
    target.callback = function(_, errorCode, displacedVolume, blockedObjectName)
        if errorCode == TerrainDeformation.STATE_SUCCESS then
            Logging.info("DebugTerrainProbe: SUCCESS at (%.2f, %.2f) - deformation would be ALLOWED (volume=%s)", x, z,
                tostring(displacedVolume))
        else
            Logging.info("DebugTerrainProbe: BLOCKED at (%.2f, %.2f) - errorCode=%s blockedObjectName=%s", x, z,
                tostring(errorCode), tostring(blockedObjectName))
        end
        deformationObject:delete()
    end

    g_terrainDeformationQueue:queueJob(deformationObject, true, "callback", target)
end

function DebugTerrainProbe.consoleCommandProbeCollisionMap()
    if g_localPlayer == nil then
        Logging.info("DebugTerrainProbe: no local player found")
        return
    end

    local px, _, pz = g_localPlayer:getPosition()
    local dirX, _, dirZ = localDirectionToWorld(g_localPlayer.rootNode, 0, 0, 1)
    local x = px + dirX * 1
    local z = pz + dirZ * 1

    local map = g_densityMapHeightManager.placementCollisionMap
    if map == nil then
        Logging.info("DebugTerrainProbe: placementCollisionMap is nil")
        return
    end

    local value = getDensityAtWorldPos(map, x, 0, z)
    Logging.info("DebugTerrainProbe: placementCollisionMap value at (%.2f, %.2f) = %s", x, z, tostring(value))
end

-- Self-test: write a block at the probe spot (writeBlockedAreaMap=true), then immediately
-- re-probe the SAME spot. If our own probe correctly detects a BLOCKED result on the second
-- call, that proves the write+detect mechanism works at all, isolating whether real placeables
-- ever actually produce a detectable block versus our own tooling being unable to see one.
function DebugTerrainProbe.consoleCommandSelfTest()
    if g_localPlayer == nil then
        Logging.info("DebugTerrainProbe: no local player found")
        return
    end

    local px, _, pz = g_localPlayer:getPosition()
    local dirX, _, dirZ = localDirectionToWorld(g_localPlayer.rootNode, 0, 0, 1)
    local x = px + dirX * 1
    local z = pz + dirZ * 1
    local y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
    local halfSize = 0.5

    -- isPreview is threaded through separately from writeBlock: a preview job (as used by
    -- dhProbeDeform for read-only checks) plausibly never commits a permanent write to
    -- placementCollisionMap, since previews aren't supposed to have persistent side effects.
    -- So the "write" pass here uses isPreview=false (matching how a real placeable's
    -- non-preview applyDeformation call would behave), while the "re-probe" pass uses
    -- isPreview=true (matching dhProbeDeform's read-only check).
    local function probe(writeBlock, isPreview, label)
        local deformationObject = TerrainDeformation.new(g_terrainNode)
        if g_densityMapHeightManager.placementCollisionMap ~= nil then
            deformationObject:setBlockedAreaMap(g_densityMapHeightManager.placementCollisionMap, 0)
        else
            Logging.info("DebugTerrainProbe: [%s] placementCollisionMap is nil - block detection will not work", label)
        end
        -- Real 1m-deep pit, not a flat area at current terrain height - a flat area produces
        -- volume=0 "SUCCESS" whether or not it's blocked, since there's nothing to displace.
        local pitDepth = 1.0
        deformationObject:addArea(
            x - halfSize, y - pitDepth, z - halfSize,
            1, 0, 0,
            0, 0, 1,
            -1,
            writeBlock
        )

        local target = {}
        target.callback = function(_, errorCode, displacedVolume, blockedObjectName)
            Logging.info("DebugTerrainProbe: [%s] isPreview=%s writeBlock=%s errorCode=%s (SUCCESS=%s) blockedObjectName=%s", label,
                tostring(isPreview), tostring(writeBlock),
                tostring(errorCode), tostring(errorCode == TerrainDeformation.STATE_SUCCESS), tostring(blockedObjectName))
            deformationObject:delete()

            if writeBlock then
                probe(false, true, "re-probe after write")
            end
        end

        g_terrainDeformationQueue:queueJob(deformationObject, isPreview, "callback", target)
    end

    probe(true, false, "first write (non-preview)")
end

-- Finds the nearest placed placeable to the player and dumps whether it has the
-- PlaceableLeveling specialization active, and what its levelAreas/requiresLeveling look like.
-- This tells us directly whether our custom placeableType is even granted PlaceableLeveling,
-- rather than inferring it indirectly from deformation probe results.
function DebugTerrainProbe.consoleCommandDumpNearestPlaceable()
    if g_localPlayer == nil then
        Logging.info("DebugTerrainProbe: no local player found")
        return
    end

    if g_currentMission == nil or g_currentMission.placeableSystem == nil then
        Logging.info("DebugTerrainProbe: no placeableSystem found")
        return
    end

    local px, py, pz = g_localPlayer:getPosition()

    local nearest = nil
    local nearestDist = math.huge
    for _, placeable in ipairs(g_currentMission.placeableSystem.placeables) do
        local ok, x, y, z = pcall(getWorldTranslation, placeable.rootNode)
        if ok then
            local dist = MathUtil.vector3Length(x - px, y - py, z - pz)
            if dist < nearestDist then
                nearestDist = dist
                nearest = placeable
            end
        end
    end

    if nearest == nil then
        Logging.info("DebugTerrainProbe: no placeables found at all")
        return
    end

    Logging.info("DebugTerrainProbe: nearest placeable is '%s' (typeName=%s) at distance %.2fm",
        tostring(nearest.configFileName or nearest:getName()), tostring(nearest.typeName), nearestDist)

    local levelingSpec = nearest.spec_leveling
    if levelingSpec == nil then
        Logging.info("DebugTerrainProbe: nearest placeable has NO spec_leveling (PlaceableLeveling specialization not active)")
    else
        Logging.info("DebugTerrainProbe: nearest placeable spec_leveling.requiresLeveling=%s, #levelAreas=%s, #paintAreas=%s",
            tostring(levelingSpec.requiresLeveling), tostring(levelingSpec.levelAreas and #levelingSpec.levelAreas),
            tostring(levelingSpec.paintAreas and #levelingSpec.paintAreas))
    end
end

-- Same deformation probe as dhProbeDeform, but targets the exact world position of the
-- nearest placed placeable's rootNode instead of "1m in front of the player" - eliminates
-- any positioning error when testing whether a specific building's footprint is blocked.
function DebugTerrainProbe.consoleCommandProbeNearestPlaceable()
    if g_localPlayer == nil then
        Logging.info("DebugTerrainProbe: no local player found")
        return
    end

    if g_currentMission == nil or g_currentMission.placeableSystem == nil then
        Logging.info("DebugTerrainProbe: no placeableSystem found")
        return
    end

    local px, py, pz = g_localPlayer:getPosition()

    local nearest = nil
    local nearestDist = math.huge
    local nx, ny, nz
    for _, placeable in ipairs(g_currentMission.placeableSystem.placeables) do
        local ok, x, y, z = pcall(getWorldTranslation, placeable.rootNode)
        if ok then
            local dist = MathUtil.vector3Length(x - px, y - py, z - pz)
            if dist < nearestDist then
                nearestDist = dist
                nearest = placeable
                nx, ny, nz = x, y, z
            end
        end
    end

    if nearest == nil then
        Logging.info("DebugTerrainProbe: no placeables found at all")
        return
    end

    Logging.info("DebugTerrainProbe: probing exact position of nearest placeable '%s' at (%.2f, %.2f, %.2f)",
        tostring(nearest.configFileName), nx, ny, nz)

    local deformationObject = TerrainDeformation.new(g_terrainNode)
    if g_densityMapHeightManager.placementCollisionMap ~= nil then
        deformationObject:setBlockedAreaMap(g_densityMapHeightManager.placementCollisionMap, 0)
    else
        Logging.info("DebugTerrainProbe: placementCollisionMap is nil - block detection will not work")
    end

    -- IMPORTANT: a flat area at the CURRENT terrain height produces volume=0 "SUCCESS" whether
    -- or not the spot is actually blocked, because there's nothing to displace either way - that
    -- made earlier probes indistinguishable from a real block. Request a real 1m-deep pit instead
    -- (area Y set well below actual ground) so a SUCCESS result can only mean genuinely unblocked.
    local halfSize = 0.5
    local pitDepth = 1.0
    deformationObject:addArea(
        nx - halfSize, ny - pitDepth, nz - halfSize,
        1, 0, 0,
        0, 0, 1,
        -1,
        false
    )

    local target = {}
    target.callback = function(_, errorCode, displacedVolume, blockedObjectName)
        if errorCode == TerrainDeformation.STATE_SUCCESS then
            Logging.info("DebugTerrainProbe: SUCCESS at nearest placeable position - deformation would be ALLOWED (volume=%s)",
                tostring(displacedVolume))
        else
            Logging.info("DebugTerrainProbe: BLOCKED at nearest placeable position - errorCode=%s blockedObjectName=%s",
                tostring(errorCode), tostring(blockedObjectName))
        end
        deformationObject:delete()
    end

    g_terrainDeformationQueue:queueJob(deformationObject, true, "callback", target)
end

addConsoleCommand("dhProbeDeform",
    "Tests whether the spot 1m in front of the player is protected from terrain deformation", "consoleCommandProbeDeform",
    DebugTerrainProbe)
addConsoleCommand("dhProbeCollisionMap",
    "Reads the raw placementCollisionMap value at the spot 1m in front of the player", "consoleCommandProbeCollisionMap",
    DebugTerrainProbe)
addConsoleCommand("dhProbeSelfTest",
    "Writes a block at the probe spot then re-probes it, to validate the write+detect mechanism itself",
    "consoleCommandSelfTest", DebugTerrainProbe)
addConsoleCommand("dhDumpNearestPlaceable",
    "Dumps whether the nearest placed placeable has an active PlaceableLeveling specialization",
    "consoleCommandDumpNearestPlaceable", DebugTerrainProbe)
addConsoleCommand("dhProbeNearestPlaceable",
    "Probes deformation exactly at the nearest placed placeable's world position",
    "consoleCommandProbeNearestPlaceable", DebugTerrainProbe)
