    local obs = obslua
    local ffi = require("ffi")

    ffi.cdef[[
    typedef unsigned long XID;
    typedef XID Window;
    typedef XID Drawable;
    typedef struct _XDisplay Display;
    Display *XOpenDisplay(const char *display_name);
    int XQueryPointer(Display *display, Window w, Window *root_return, Window *child_return, int *root_x_return, int *root_y_return, int *win_x_return, int *win_y_return, unsigned int *mask_return);
    Window XDefaultRootWindow(Display *display);
    ]]

    local x11 = ffi.load("X11")
    local display = x11.XOpenDisplay(nil)
    local root_window = x11.XDefaultRootWindow(display)

    local root_return = ffi.new("Window[1]")
    local child_return = ffi.new("Window[1]")
    local root_x_return = ffi.new("int[1]")
    local root_y_return = ffi.new("int[1]")
    local win_x_return = ffi.new("int[1]")
    local win_y_return = ffi.new("int[1]")
    local mask_return = ffi.new("unsigned int[1]")

    local sim_x = 0
    local sim_dir = 10

    local function get_mouse_pos()
        x11.XQueryPointer(display, root_window, root_return, child_return, root_x_return, root_y_return, win_x_return, win_y_return, mask_return)
        local real_mx, real_my = tonumber(root_x_return[0]), tonumber(root_y_return[0])
        
        if real_mx == 0 and real_my == 0 then
            sim_x = sim_x + sim_dir
            if sim_x > 1920 then sim_dir = -10 end
            if sim_x < 0 then sim_dir = 10 end
            return sim_x, 540
        end
        
        return real_mx, real_my
    end

    local source_name = ""
    local filter_name = "VerticalCrop"
    local follow_speed = 0.1
    local cur_cx = 1920 / 2

    local function update_crop()
        local source = obs.obs_get_source_by_name(source_name)
        if not source then return end

        local src_w = 1920
        local src_h = 1080
        if src_w == 0 or src_h == 0 then
            obs.obs_source_release(source)
            return
        end

        local aspect = 1080 / 1920
        local view_h = src_h
        local crop_w = math.floor(view_h * aspect)

        local mx, my = get_mouse_pos()
        
        cur_cx = cur_cx + (mx - cur_cx) * follow_speed

        local min_cx = crop_w / 2
        local max_cx = src_w - (crop_w / 2)
        if cur_cx < min_cx then cur_cx = min_cx end
        if cur_cx > max_cx then cur_cx = max_cx end
        
        if not _G.frame_counter then _G.frame_counter = 0 end
        _G.frame_counter = _G.frame_counter + 1
        if _G.frame_counter >= 60 then
            print(string.format("DEBUG: mx=%d, my=%d | cur_cx=%.1f | limits=(%.1f - %.1f)", mx, my, cur_cx, min_cx, max_cx))
            _G.frame_counter = 0
        end

        local left = math.floor(cur_cx - (crop_w / 2))
        local right = src_w - left - crop_w

        local filter = obs.obs_source_get_filter_by_name(source, filter_name)
        if not filter then
            filter = obs.obs_source_create("crop_filter", filter_name, nil, nil)
            obs.obs_source_filter_add(source, filter)
            obs.obs_source_release(filter)
            filter = obs.obs_source_get_filter_by_name(source, filter_name)
        end

        local settings = obs.obs_data_create()
        obs.obs_data_set_int(settings, "left", left)
        obs.obs_data_set_int(settings, "right", right)
        obs.obs_data_set_int(settings, "top", 0)
        obs.obs_data_set_int(settings, "bottom", 0)

        obs.obs_source_update(filter, settings)
        
        obs.obs_data_release(settings)
        obs.obs_source_release(filter)
        obs.obs_source_release(source)
    end

    function script_tick(seconds)
        if source_name ~= "" then
            update_crop()
        end
    end

    function script_properties()
        local props = obs.obs_properties_create()
        
        local p = obs.obs_properties_add_list(props, "source_name", "Source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
        local sources = obs.obs_enum_sources()
        if sources ~= nil then
            for _, source in ipairs(sources) do
                local name = obs.obs_source_get_name(source)
                obs.obs_property_list_add_string(p, name, name)
            end
        end
        obs.source_list_release(sources)
        
        obs.obs_properties_add_float_slider(props, "follow_speed", "Follow Speed", 0.01, 1.0, 0.01)
        
        return props
    end

    function script_update(settings)
        source_name = obs.obs_data_get_string(settings, "source_name")
        follow_speed = obs.obs_data_get_double(settings, "follow_speed")
    end

    function script_defaults(settings)
        obs.obs_data_set_default_double(settings, "follow_speed", 0.1)
    end
