-- One pack's name/icon and the piece definitions it contains, as defined in its own xml file.
DynamicHallsPackDefinition = {}
local DynamicHallsPackDefinition_mt = Class(DynamicHallsPackDefinition)

---Registers the xml schema for a pack definition file.
-- @param table schema XMLSchema to register into
function DynamicHallsPackDefinition.registerXMLPaths(schema)
    schema:register(XMLValueType.L10N_STRING, "pack.name", "Name of the pack")
    schema:register(XMLValueType.FILENAME, "pack.icon", "Path to the pack's group icon image")
    DynamicHallsPieceDefinition.registerXMLPaths(schema, "pack.pieces.piece(?)")
end

---Creates a new, empty pack definition.
-- @param table customMt optional metatable to use instead of the default
function DynamicHallsPackDefinition.new(customMt)
    local self = setmetatable({}, customMt or DynamicHallsPackDefinition_mt)
    self.key = nil
    self.name = nil
    self.icon = nil
    self.pieces = {}
    return self
end

---Loads this pack's fields and pieces from its xml file. Returns false if the file is invalid.
-- @param table xmlFile XMLFile to read from
-- @param string baseDirectory base directory for resolving filename fields
-- @param table customEnvironment l10n environment for resolving l10n fields
function DynamicHallsPackDefinition:loadFromXMLFile(xmlFile, baseDirectory, customEnvironment)
    self.name = xmlFile:getValue("pack.name", nil, customEnvironment)
    self.icon = xmlFile:getValue("pack.icon", nil, baseDirectory)

    self.pieces = {}
    xmlFile:iterate("pack.pieces.piece", function(_, pieceKey)
        local piece = DynamicHallsPieceDefinition.new()
        if piece:loadFromXMLFile(xmlFile, pieceKey, baseDirectory, customEnvironment) then
            if self.pieces[piece.key] ~= nil then
                Logging.xmlWarning(xmlFile, "Duplicate piece id '%s' in '%s'", piece.key, pieceKey)
            else
                self.pieces[piece.key] = piece
            end
        end
    end)

    return true
end
