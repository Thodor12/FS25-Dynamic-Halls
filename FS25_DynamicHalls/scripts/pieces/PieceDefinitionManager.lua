DynamicHallsPieceDefinitionManager = {}
local DynamicHallsPieceDefinitionManager_mt = Class(DynamicHallsPieceDefinitionManager, AbstractManager)

g_xmlManager:addCreateSchemaFunction(function()
    DynamicHallsPieceDefinitionManager.xmlSchema = XMLSchema.new("piece")
end)
g_xmlManager:addInitSchemaFunction(function()
    DynamicHallsPieceDefinition.registerXMLPaths(DynamicHallsPieceDefinitionManager.xmlSchema, "piece")
end)

---Creates a new piece definition manager.
-- @param table customMt optional metatable to use instead of the default
function DynamicHallsPieceDefinitionManager.new(customMt)
    local self = AbstractManager.new(customMt or DynamicHallsPieceDefinitionManager_mt)
    return self
end

---Initializes the manager's data structures. Called by AbstractManager before loadMapData.
function DynamicHallsPieceDefinitionManager:initDataStructures()
    self.pieces = {}
end

---Scans the mod's own pieces/*.xml folder (not the map/savegame) and loads every piece definition
-- found there.
function DynamicHallsPieceDefinitionManager:loadMapData()
    DynamicHallsPieceDefinitionManager:superClass().loadMapData(self)

    local piecesDirectory = DynamicHallsConstants.MOD_DIRECTORY .. "pieces/"

    local filenames = {}
    local callbackTarget = {}
    function callbackTarget.onPieceFile(_, filename, isDirectory)
        if not isDirectory and filename:match("%.xml$") then
            table.insert(filenames, filename)
        end
    end
    getFiles(piecesDirectory, "onPieceFile", callbackTarget)

    for _, filename in ipairs(filenames) do
        local key = Utils.getFilenameInfo(filename, false)
        local filePath = piecesDirectory .. filename
        local xmlFile = XMLFile.load("piece", filePath, DynamicHallsPieceDefinitionManager.xmlSchema)
        if xmlFile ~= nil then
            local customEnvironment = Utils.getModNameAndBaseDirectory(filePath)
            local piece = DynamicHallsPieceDefinition.new()
            piece.key = key
            if piece:loadFromXMLFile(xmlFile, "piece", DynamicHallsConstants.MOD_DIRECTORY, customEnvironment) then
                self.pieces[key] = piece
            end
            xmlFile:delete()
        end
    end

    return true
end

---Returns the piece definition for the given key, or nil if none exists.
-- @param string key piece key (its xml filename without extension)
function DynamicHallsPieceDefinitionManager:getPieceByKey(key)
    return self.pieces[key]
end

---Returns all loaded piece definitions, keyed by piece key.
function DynamicHallsPieceDefinitionManager:getPieces()
    return self.pieces
end

g_dynamicHallsPieceDefinitionManager = DynamicHallsPieceDefinitionManager.new()

DynamicHallsPieceDefinitionManagerEventListener = {}

function DynamicHallsPieceDefinitionManagerEventListener:loadMap(mapNode)
    g_dynamicHallsPieceDefinitionManager:loadMapData()
end

addModEventListener(DynamicHallsPieceDefinitionManagerEventListener)
