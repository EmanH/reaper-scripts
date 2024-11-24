-- Get cursor (playhead) position in seconds
local cursor_pos = reaper.GetCursorPosition()

-- Get count of selected items
local num_selected_items = reaper.CountSelectedMediaItems(0)

-- Loop through all selected items
for i = 0, num_selected_items - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    
    -- Here you can work with each item
    -- For example, to get item position:
    local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local item_length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    
    -- Print info to REAPER console (for debugging)
    reaper.ShowConsoleMsg(string.format("Item %d: Position = %.2f, Length = %.2f\n", i, item_pos, item_length))
end
