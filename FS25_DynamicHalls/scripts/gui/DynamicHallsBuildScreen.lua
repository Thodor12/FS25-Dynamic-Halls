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
    self.placementRotation = 0
    self.previewNodeId = nil
    self.camera = GuiTopDownCamera.new()
    self.cursor = GuiTopDownCursor.new()
    return self
end

---Deletes this screen's top-down camera/cursor.
function DynamicHallsBuildScreen:delete()
    self.camera:delete()
    self.cursor:delete()
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

---Selects the first sub-category and activates the top-down camera/cursor over the placeable.
function DynamicHallsBuildScreen:onOpen()
    DynamicHallsBuildScreen:superClass().onOpen(self)
    self:setCurrentSubCategory(1)

    self.camera:setTerrainRootNode(g_terrainNode)
    self.camera:activate()
    if self.placeable ~= nil then
        local x, _, z = self.placeable:getPosition()
        self.camera:setCameraPosition(x, z)
    end

    self.cursor:setTerrainOnly(false)
    self.cursor:setShape(GuiTopDownCursor.SHAPES.NONE)
    self.cursor:setRotationEnabled(true)
    self.cursor:setSnapAngle(math.rad(90))
    self.cursor:activate()

    local _, eventId = g_inputBinding:registerActionEvent(InputAction.CONSTRUCTION_ACTION_PRIMARY, self,
        self.onPlaceAccept, false, true, false, true)
    self.placeAcceptEventId = eventId
end

---Deactivates the top-down camera/cursor, removes the preview clone, and unregisters placement
-- input.
function DynamicHallsBuildScreen:onClose()
    self.camera:deactivate()
    self.cursor:deactivate()
    self:removePreview()
    g_inputBinding:removeActionEventsByTarget(self)
    DynamicHallsBuildScreen:superClass().onClose(self)
end

---Forwards real mouse position/click events to the camera and cursor, and tracks whether the
-- mouse is currently over a menu panel (rather than the 3D world) so placement input can ignore
-- clicks meant for the UI.
-- @param float posX normalized mouse X position
-- @param float posY normalized mouse Y position
-- @param bool isDown whether this event is a mouse-button-down event
-- @param bool isUp whether this event is a mouse-button-up event
-- @param integer button which mouse button, if any
function DynamicHallsBuildScreen:mouseEvent(posX, posY, isDown, isUp, button)
    DynamicHallsBuildScreen:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)

    self.isMouseInMenu = GuiUtils.checkOverlayOverlap(posX, posY, self.contentContainer.absPosition[1],
        self.contentContainer.absPosition[2], self.contentContainer.absSize[1], self.contentContainer.absSize[2])
    if not self.isMouseInMenu then
        self.isMouseInMenu = GuiUtils.checkOverlayOverlap(posX, posY, self.categoryContainer.absPosition[1],
            self.categoryContainer.absPosition[2], self.categoryContainer.absSize[1], self.categoryContainer.absSize[2])
    end
    self.camera.mouseDisabled = self.isMouseInMenu
    self.cursor.mouseDisabled = self.isMouseInMenu

    self.camera:mouseEvent(posX, posY, isDown, isUp, button)
    self.cursor:mouseEvent(posX, posY, isDown, isUp, button)
end

---Updates the top-down camera/cursor and the placement preview, and draws the grid overlay.
-- @param integer dt frame delta time in ms
function DynamicHallsBuildScreen:update(dt)
    DynamicHallsBuildScreen:superClass().update(self, dt)
    self.camera:update(dt)
    self.cursor:setCameraRay(self.camera:getPickRay())
    self.cursor:update(dt)
    self:updatePreview()
    self:drawGrid()
end

---Draws a green grid line over every row/column of the current placeable's placement grid.
function DynamicHallsBuildScreen:drawGrid()
    if self.placeable == nil then
        return
    end

    local spec = self.placeable["spec_FS25_DynamicHalls.dynamicHallsPlaceable"]
    local rootNode = self.placeable.rootNode
    local cellSize = DynamicHallsConstants.PIECE_CELL_SIZE
    local halfWidth = spec.width / 2
    local halfLength = spec.length / 2

    for column = 0, spec.width / cellSize do
        local localX = -halfWidth + column * cellSize
        local x1, y1, z1 = localToWorld(rootNode, localX, 0, -halfLength)
        local x2, y2, z2 = localToWorld(rootNode, localX, 0, halfLength)
        drawDebugLine(x1, y1, z1, 0, 1, 0, x2, y2, z2, 0, 1, 0, false)
    end

    for row = 0, spec.length / cellSize do
        local localZ = -halfLength + row * cellSize
        local x1, y1, z1 = localToWorld(rootNode, -halfWidth, 0, localZ)
        local x2, y2, z2 = localToWorld(rootNode, halfWidth, 0, localZ)
        drawDebugLine(x1, y1, z1, 0, 1, 0, x2, y2, z2, 0, 1, 0, false)
    end
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

---Sets the currently selected item, updates the details box, and removes any stale preview clone
-- so it gets rebuilt for the new item.
-- @param table item the selected { packKey, piece } entry, or nil for none
function DynamicHallsBuildScreen:setSelectedItem(item)
    self.selectedItem = item
    self.itemDetailsName:setText(item ~= nil and item.piece.name or "")
    self:removePreview()
end

---Handles clicking an item in the list.
function DynamicHallsBuildScreen:onClickItem()
end

---Removes the current preview clone, if any.
function DynamicHallsBuildScreen:removePreview()
    if self.previewNodeId ~= nil then
        delete(self.previewNodeId)
        self.previewNodeId = nil
    end
end

---Computes the cursor's snapped grid position for the current placeable. Returns nil (with no
-- further values) if the cursor isn't over anything, or no placeable/piece is selected; otherwise
-- returns row, column, and whether that position fits the grid.
function DynamicHallsBuildScreen:getSnappedGridPosition()
    if self.placeable == nil or self.selectedItem == nil then
        return nil
    end

    local worldX, worldY, worldZ = self.cursor:getPosition()
    if worldX == nil then
        return nil
    end

    local localX, _, localZ = worldToLocal(self.placeable.rootNode, worldX, worldY, worldZ)
    local spec = self.placeable["spec_FS25_DynamicHalls.dynamicHallsPlaceable"]

    local rawColumn = (localX + spec.width / 2) / DynamicHallsConstants.PIECE_CELL_SIZE
    local rawRow = (localZ + spec.length / 2) / DynamicHallsConstants.PIECE_CELL_SIZE
    local column = MathUtil.round(rawColumn)
    local row = MathUtil.round(rawRow)

    local gridWidth = spec.width / DynamicHallsConstants.PIECE_CELL_SIZE
    local gridLength = spec.length / DynamicHallsConstants.PIECE_CELL_SIZE
    local isValid = self.selectedItem.piece.placement:isWithinGridBounds(row, column, self.placementRotation,
        gridWidth, gridLength)

    return row, column, isValid
end

---Moves/rotates the preview clone to the cursor's current snapped grid position, creating it (or
-- loading its template) the first time a piece is selected, and colors the cursor/details box to
-- reflect whether the current position is a valid placement.
function DynamicHallsBuildScreen:updatePreview()
    if self.selectedItem == nil then
        self:removePreview()
        return
    end

    self.placementRotation = MathUtil.round(math.deg(self.cursor:getRotation()) / 90) * 90 % 360

    local row, column, isValid = self:getSnappedGridPosition()
    if row == nil then
        self:removePreview()
        return
    end

    self.cursor:setColorMode(isValid and GuiTopDownCursor.SHAPES_COLORS.SUCCESS or GuiTopDownCursor.SHAPES_COLORS.ERROR)
    if not isValid then
        self.cursor:setErrorMessage(g_i18n:getText("dynamichalls_placementOutsideGrid"))
    end

    if self.previewNodeId == nil then
        local rootNodeMapping = self.placeable.i3dMappings["pieces"]
        if rootNodeMapping == nil then
            return
        end
        DynamicHallsPiecePlacement.getOrLoadTemplateNodeId(self.placeable, self.selectedItem.packKey,
            self.selectedItem.piece, function(templateNodeId)
                self.previewNodeId = DynamicHallsPiecePlacement.cloneAtGridPosition(self.selectedItem.piece,
                    templateNodeId, rootNodeMapping.nodeId, self.placeable, row, column, self.placementRotation)
            end)
        return
    end

    DynamicHallsPiecePlacement.updateNodePosition(self.selectedItem.piece, self.previewNodeId, self.placeable, row,
        column, self.placementRotation)
end

---Commits the current preview placement, if valid, as a new permanent piece.
function DynamicHallsBuildScreen:onPlaceAccept()
    if self.isMouseInMenu then
        return
    end

    local row, column, isValid = self:getSnappedGridPosition()
    if row == nil or not isValid then
        return
    end

    local spec = self.placeable["spec_FS25_DynamicHalls.dynamicHallsPlaceable"]
    local placementType = self.selectedItem.piece.placement

    local placedPiece
    if placementType:isa(DynamicHallsEdgePiecePlacementType) then
        placedPiece = DynamicHallsPlacedEdgePiece.new()
        table.insert(spec.edgePieces, placedPiece)
    else
        placedPiece = DynamicHallsPlacedTilePiece.new()
        table.insert(spec.tilePieces, placedPiece)
    end

    placedPiece.packKey = self.selectedItem.packKey
    placedPiece.pieceKey = self.selectedItem.piece.key
    placedPiece.row = row
    placedPiece.column = column
    placedPiece.rotation = self.placementRotation

    DynamicHallsPiecePlacement.spawn(self.placeable, placedPiece)
end

---Closes the build screen.
function DynamicHallsBuildScreen:onClickBack()
    self:changeScreen(nil)
end
