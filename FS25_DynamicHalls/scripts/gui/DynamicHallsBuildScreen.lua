-- The build screen: lets the player browse pieces and place them on the current baseplate.
DynamicHallsBuildScreen = {}
local DynamicHallsBuildScreen_mt = Class(DynamicHallsBuildScreen, ScreenElement)

---Shows the build screen for the given placeable.
-- @param table placeable the placeable instance
function DynamicHallsBuildScreen.show(placeable)
    g_dynamicHallsBuildScreen:setPlaceable(placeable)
    g_gui:showGui("dynamicHallsBuildScreen")
end

---Creates a new build screen controller.
-- @param table custom_mt optional metatable to use instead of the default
function DynamicHallsBuildScreen.new(custom_mt)
    local self = ScreenElement.new(nil, custom_mt or DynamicHallsBuildScreen_mt)
    self.currentSubCategory = 1
    self.items = {}
    self.selectedItem = nil
    self.camera = GuiTopDownCamera.new()
    return self
end

---Deletes this screen's top-down camera.
function DynamicHallsBuildScreen:delete()
    self.camera:delete()
    DynamicHallsBuildScreen:superClass().delete(self)
end

---Sets the placeable this screen builds pieces onto.
-- @param table placeable the placeable instance
function DynamicHallsBuildScreen:setPlaceable(placeable)
    self.placeable = placeable
end

---Wires up the item list's data source and the sub-category dot selector.
function DynamicHallsBuildScreen:onGuiSetupFinished()
    DynamicHallsBuildScreen:superClass().onGuiSetupFinished(self)
    self.itemList:setDataSource(self)

    local subCategoryTitles = {}
    for index, category in ipairs(DynamicHallsConstants.PIECE_CATEGORIES) do
        table.insert(subCategoryTitles, g_i18n:getText(category.titleKey))

        local dot = self.subCategoryDotTemplate:clone(self.subCategoryDotBox)
        function dot.getIsSelected()
            return self.currentSubCategory == index
        end
    end
    self.subCategorySelector:setTexts(subCategoryTitles)
    self.subCategoryDotBox:invalidateLayout()
end

---Selects the first sub-category and activates the top-down camera over the placeable.
function DynamicHallsBuildScreen:onOpen()
    DynamicHallsBuildScreen:superClass().onOpen(self)
    self:setCurrentSubCategory(1)

    self.camera:setTerrainRootNode(g_terrainNode)
    self.camera:activate()
    if self.placeable ~= nil then
        local x, _, z = self.placeable:getPosition()
        self.camera:setCameraPosition(x, z)
    end
end

---Deactivates the top-down camera.
function DynamicHallsBuildScreen:onClose()
    self.camera:deactivate()
    DynamicHallsBuildScreen:superClass().onClose(self)
end

---Updates the top-down camera.
-- @param integer dt frame delta time in ms
function DynamicHallsBuildScreen:update(dt)
    DynamicHallsBuildScreen:superClass().update(self, dt)
    self.camera:update(dt)
end

---Draws the context-sensitive input-hint HUD overlay.
function DynamicHallsBuildScreen:draw()
    DynamicHallsBuildScreen:superClass().draw(self)
    g_currentMission.hud:drawInputHelp(self.helpDisplay.position[1], self.helpDisplay.position[2])
end

---Switches the item list to the given sub-category and selects its first item.
-- @param integer index 1-based index into DynamicHallsConstants.PIECE_CATEGORIES
function DynamicHallsBuildScreen:setCurrentSubCategory(index)
    self.currentSubCategory = index
    self.subCategorySelector:setState(index, false)

    local category = DynamicHallsConstants.PIECE_CATEGORIES[index].value
    self.items = {}
    for packKey, pack in pairs(g_dynamicHallsPackDefinitionManager:getPacks()) do
        for _, piece in pairs(pack.pieces) do
            if piece.category == category then
                table.insert(self.items, { packKey = packKey, piece = piece })
            end
        end
    end
    table.sort(self.items, function(a, b)
        return a.piece.name < b.piece.name
    end)

    self.itemList:reloadData()
    if 0 < #self.items then
        self.itemList:setSelectedIndex(1)
    else
        self:setSelectedItem(nil)
    end
end

---Handles the sub-category dot selector changing.
-- @param integer index 1-based index into DynamicHallsConstants.PIECE_CATEGORIES
function DynamicHallsBuildScreen:onSubCategoryChanged(index)
    self:setCurrentSubCategory(index)
end

---Returns the number of items in the current sub-category's item list.
-- @param table list the SmoothList requesting the count
-- @param integer section list section index
function DynamicHallsBuildScreen:getNumberOfItemsInSection(list, section)
    return #self.items
end

---Fills an item list cell with its piece's icon.
-- @param table list the SmoothList requesting the cell
-- @param integer section list section index
-- @param integer index item index within the section
-- @param table cell the cell element to populate
function DynamicHallsBuildScreen:populateCellForItemInSection(list, section, index, cell)
    local item = self.items[index]
    cell:getAttribute("icon"):setImageFilename(item.piece.icon)
end

---Handles the item list's selection changing.
-- @param table list the SmoothList that changed selection
-- @param integer section list section index
-- @param integer index newly selected item index within the section
function DynamicHallsBuildScreen:onListSelectionChanged(list, section, index)
    self:setSelectedItem(self.items[index])
end

---Sets the currently selected item and updates the details box.
-- @param table item the selected { packKey, piece } entry, or nil for none
function DynamicHallsBuildScreen:setSelectedItem(item)
    self.selectedItem = item
    self.itemDetailsName:setText(item ~= nil and item.piece.name or "")
end

---Handles clicking an item in the list.
function DynamicHallsBuildScreen:onClickItem()
end

---Closes the build screen.
function DynamicHallsBuildScreen:onClickBack()
    self:changeScreen(nil)
end
