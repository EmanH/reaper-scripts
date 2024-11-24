- Get count of selected items
local num_selected_items = reaper.CountSelectedMediaItems(0)

-- Loop through all selected items
for i = 0, num_selected_items - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local take = reaper.GetActiveTake(item)
    
    if take then
        local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        reaper.ShowConsoleMsg(string.format("\nItem %d at position %.2f:\n", i, item_pos))
        
        -- Get media source from take
        local source = reaper.GetMediaItemTake_Source(take)
        
        -- Check if it's a WAV file
        local filename = reaper.GetMediaSourceFileName(source, "")
        local file = io.open(filename, "rb")
        
        if file then
            -- Check WAV header
            file:seek("cur", 4) -- Skip RIFF header
            local file_size_buf = file:read(4)
            local file_size = string.unpack("I", file_size_buf)
            local wave_header = file:read(4)
            
            if string.lower(wave_header) == "wave" then
                -- Search for cue and list chunks
                while file:seek() < file_size do
                    local chunk_header = file:read(4)
                    local chunk_size_buf = file:read(4)
                    local chunk_size = string.unpack("I", chunk_size_buf)
                    
                    if string.lower(chunk_header) == "cue " then
                        -- Read number of cue points
                        local cue_points_cnt = string.unpack("I", file:read(4))
                        reaper.ShowConsoleMsg(string.format("Found %d cue points:\n", cue_points_cnt))
                        
                        -- Read each cue point
                        for cp = 1, cue_points_cnt do
                            local ID = string.unpack("I", file:read(4))
                            file:seek("cur", 16)
                            local Sample_Offset = string.unpack("I", file:read(4))
                            
                            -- Convert sample offset to time position relative to item
                            local samplerate = reaper.GetMediaSourceSampleRate(source)
                            local cue_time = Sample_Offset / samplerate
                            local item_cue_pos = item_pos + cue_time
                            
                            -- Check for existing markers within 200ms
                            local marker_exists = false
                            local threshold = 0.2 -- 200ms
                            local marker_count = reaper.GetTakeNumStretchMarkers(take)
                            
                            for m = 0, marker_count - 1 do
                                local _, pos = reaper.GetTakeStretchMarker(take, m)
                                if math.abs(pos - cue_time) < threshold then
                                    marker_exists = true
                                    break
                                end
                            end
                            
                            if not marker_exists then
                                reaper.SetTakeStretchMarker(take, -1, cue_time)
                                reaper.ShowConsoleMsg(string.format("  Added stretch marker at %f seconds\n", cue_time))
                            end
                        end
                    else
                        -- Skip other chunks
                        file:seek("cur", chunk_size)
                    end
                end
            else
                reaper.ShowConsoleMsg("Not a WAV file\n")
            end
            file:close()
        end
    end
end
