DynamicHallsPieceDefinition = {}
local DynamicHallsPieceDefinition_mt = Class(DynamicHallsPieceDefinition)

---Registers the xml schema for a piece definition file under basePath.
-- @param table schema XMLSchema to register into
-- @param string basePath xml path prefix
function DynamicHallsPieceDefinition.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.L10N_STRING, basePath .. ".name", "Name of the piece")
    schema:register(XMLValueType.FLOAT, basePath .. ".price", "Price of the piece")
    schema:register(XMLValueType.FILENAME, basePath .. ".icon", "Path to the piece's shop icon image")
    schema:register(XMLValueType.STRING, basePath .. ".category",
        "Shop category the piece is listed under (wall, roof, floor, ...)")
    schema:register(XMLValueType.STRING, basePath .. ".materials.material(?)#fillType", "Fill type name")
    schema:register(XMLValueType.FLOAT, basePath .. ".materials.material(?)#amount", "Amount in liters")
    schema:register(XMLValueType.STRING, basePath .. ".placementType", "How the piece is placed (wall or tile)")
    schema:register(XMLValueType.FILENAME, basePath .. ".i3dFilename", "Path to the piece's i3d file")
end

---Creates a new, empty piece definition.
-- @param table customMt optional metatable to use instead of the default
function DynamicHallsPieceDefinition.new(customMt)
    local self = setmetatable({}, customMt or DynamicHallsPieceDefinition_mt)
    self.key = nil
    self.name = nil
    self.price = 0
    self.icon = nil
    self.category = nil
    self.materials = {}
    self.placementType = nil
    self.i3dFilename = nil
    return self
end

---Loads this piece's fields from its xml file. Returns false if the file is invalid.
-- @param table xmlFile XMLFile to read from
-- @param string key xml path to the piece element
-- @param string baseDirectory base directory for resolving filename fields
-- @param table customEnvironment l10n environment for resolving the name field
function DynamicHallsPieceDefinition:loadFromXMLFile(xmlFile, key, baseDirectory, customEnvironment)
    self.name = xmlFile:getValue(key .. ".name", nil, customEnvironment)
    self.price = xmlFile:getValue(key .. ".price", self.price)
    self.icon = xmlFile:getValue(key .. ".icon", nil, baseDirectory)

    self.category = xmlFile:getValue(key .. ".category")
    if DynamicHallsUtils.findByValue(DynamicHallsConstants.PIECE_CATEGORIES, self.category) == nil then
        Logging.xmlWarning(xmlFile, "Unknown category '%s' in '%s'", self.category, key)
        return false
    end

    self.materials = {}
    xmlFile:iterate(key .. ".materials.material", function(_, materialKey)
        local fillTypeName = xmlFile:getValue(materialKey .. "#fillType")
        local fillType = g_fillTypeManager:getFillTypeByName(fillTypeName)
        if fillType == nil then
            Logging.xmlWarning(xmlFile, "Unknown fillType '%s' in '%s'", fillTypeName, materialKey)
            return
        end

        local amount = xmlFile:getValue(materialKey .. "#amount", 0)
        table.insert(self.materials, { fillType = fillType, amount = amount })
    end)
    table.sort(self.materials, function(a, b)
        return a.fillType.name < b.fillType.name
    end)

    self.placementType = xmlFile:getValue(key .. ".placementType")
    if DynamicHallsUtils.findByValue(DynamicHallsConstants.PIECE_PLACEMENT_TYPES, self.placementType) == nil then
        Logging.xmlWarning(xmlFile, "Unknown placementType '%s' in '%s'", self.placementType, key)
        return false
    end

    self.i3dFilename = xmlFile:getValue(key .. ".i3dFilename", nil, baseDirectory)

    return true
end
