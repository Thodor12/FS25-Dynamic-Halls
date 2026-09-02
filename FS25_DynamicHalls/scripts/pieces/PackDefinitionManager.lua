-- Loads every pack definition from the mod's own packs/*.xml folder.
DynamicHallsPackDefinitionManager = {}
local DynamicHallsPackDefinitionManager_mt = Class(DynamicHallsPackDefinitionManager, AbstractManager)

g_xmlManager:addCreateSchemaFunction(function()
    DynamicHallsPackDefinitionManager.xmlSchema = XMLSchema.new("pack")
end)
g_xmlManager:addInitSchemaFunction(function()
    DynamicHallsPackDefinition.registerXMLPaths(DynamicHallsPackDefinitionManager.xmlSchema)
end)

---Creates a new pack definition manager.
-- @param table customMt optional metatable to use instead of the default
function DynamicHallsPackDefinitionManager.new(customMt)
    local self = AbstractManager.new(customMt or DynamicHallsPackDefinitionManager_mt)
    return self
end

---Initializes the manager's data structures. Called by AbstractManager before loadMapData.
function DynamicHallsPackDefinitionManager:initDataStructures()
    self.packs = {}
end

---Scans the mod's own packs/*.xml folder (not the map/savegame) and loads every pack definition
-- found there.
function DynamicHallsPackDefinitionManager:loadMapData()
    DynamicHallsPackDefinitionManager:superClass().loadMapData(self)

    local packsDirectory = DynamicHallsConstants.MOD_DIRECTORY .. "packs/"

    local filenames = {}
    local callbackTarget = {}
    function callbackTarget.onPackFile(_, filename, isDirectory)
        if not isDirectory and filename:match("%.xml$") then
            table.insert(filenames, filename)
        end
    end
    getFiles(packsDirectory, "onPackFile", callbackTarget)

    for _, filename in ipairs(filenames) do
        local key = Utils.getFilenameInfo(filename, false)
        local filePath = packsDirectory .. filename
        local xmlFile = XMLFile.load("pack", filePath, DynamicHallsPackDefinitionManager.xmlSchema)
        if xmlFile ~= nil then
            local customEnvironment = Utils.getModNameAndBaseDirectory(filePath)
            local pack = DynamicHallsPackDefinition.new()
            pack.key = key
            if pack:loadFromXMLFile(xmlFile, DynamicHallsConstants.MOD_DIRECTORY, customEnvironment) then
                self.packs[key] = pack
            end
            xmlFile:delete()
        end
    end

    return true
end

---Returns the pack definition for the given key, or nil if none exists.
-- @param string packKey pack key (its xml filename without extension)
function DynamicHallsPackDefinitionManager:getPackByKey(packKey)
    return self.packs[packKey]
end

---Returns all loaded pack definitions, keyed by pack key.
function DynamicHallsPackDefinitionManager:getPacks()
    return self.packs
end

---Returns the piece definition for the given pack/piece key pair, or nil if either doesn't exist.
-- @param string packKey pack key
-- @param string pieceKey piece key, unique within that pack
function DynamicHallsPackDefinitionManager:getPieceByKey(packKey, pieceKey)
    local pack = self.packs[packKey]
    if pack == nil then
        return nil
    end
    return pack.pieces[pieceKey]
end

---Returns all piece definitions in the given pack, keyed by piece key.
-- @param string packKey pack key
function DynamicHallsPackDefinitionManager:getPieces(packKey)
    local pack = self.packs[packKey]
    if pack == nil then
        return {}
    end
    return pack.pieces
end

g_dynamicHallsPackDefinitionManager = DynamicHallsPackDefinitionManager.new()

DynamicHallsPackDefinitionManagerEventListener = {}

function DynamicHallsPackDefinitionManagerEventListener:loadMap(mapNode)
    g_dynamicHallsPackDefinitionManager:loadMapData()
end

addModEventListener(DynamicHallsPackDefinitionManagerEventListener)
