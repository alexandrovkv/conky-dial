--[[

]]--


require 'cairo'

local status, cairo_xlib = pcall(require, 'cairo_xlib')
if not status then
    cairo_xlib = setmetatable({}, { __index = _G })
end




colors = {
    {0.0, 0.0, 1.0},
    {0.0, 0.1, 1.0},
    {0.0, 0.2, 1.0},
    {0.0, 0.3, 1.0},
    {0.0, 0.4, 1.0},
    {0.0, 0.5, 1.0},
    {0.0, 0.6, 1.0},
    {0.0, 0.7, 1.0},
    {0.0, 0.8, 1.0},
    {0.0, 0.9, 1.0},
    {0.0, 1.0, 1.0},
    {0.0, 1.0, 0.9},
    {0.0, 1.0, 0.8},
    {0.0, 1.0, 0.7},
    {0.0, 1.0, 0.6},
    {0.0, 1.0, 0.5},
    {0.0, 1.0, 0.4},
    {0.0, 1.0, 0.3},
    {0.0, 1.0, 0.2},
    {0.0, 1.0, 0.1},
    {0.0, 1.0, 0.0},
    {0.1, 1.0, 0.0},
    {0.2, 1.0, 0.0},
    {0.3, 1.0, 0.0},
    {0.4, 1.0, 0.0},
    {0.5, 1.0, 0.0},
    {0.6, 1.0, 0.0},
    {0.7, 1.0, 0.0},
    {0.8, 1.0, 0.0},
    {0.9, 1.0, 0.0},
    {1.0, 1.0, 0.0},
    {1.0, 0.9, 0.0},
    {1.0, 0.8, 0.0},
    {1.0, 0.7, 0.0},
    {1.0, 0.6, 0.0},
    {1.0, 0.5, 0.0},
    {1.0, 0.4, 0.0},
    {1.0, 0.3, 0.0},
    {1.0, 0.2, 0.0},
    {1.0, 0.1, 0.0},
    {1.0, 0.0, 0.0}
}
n_cpus = 4
margin = 5



local function get_conky_value(name, arg, is_num)
    if arg then
        t = string.format("${%s %s}", name, arg)
    else
        t = string.format("${%s}", name)
    end

    local val = conky_parse(t)

    if is_num then
        return tonumber(val)
    end

    return val
end

local function get_cpu_load(cpu)
    if cpu ~= nil then
        cpu = "cpu" .. cpu
    end

    return get_conky_value("cpu", cpu, true)
end


local function draw_cpu_dial(cr, cpu, cx, cy, radius, clk)
    local cpu_load = get_cpu_load(cpu)
    local idx = math.floor(cpu_load * (#colors - 1) / 100)
    local ticks_length = 20
    local sector = math.rad(300)
    local sector_length = sector * radius
    local n_ticks = sector_length / 8
    local angle = -sector / n_ticks
    local rotate = -math.rad(210)

    cairo_set_source_rgba(cr, 0, 0, 0, 1)
    cairo_arc(cr, cx, cy, radius, 0, 2 * math.pi)
    cairo_fill(cr)

    cairo_set_source_rgba(cr, 0.75, 0.75, 0.75, 1)
    cairo_set_line_width(cr, 2)
    cairo_arc(cr, cx, cy, radius, 0, 2 * math.pi)
    cairo_stroke(cr)

    cairo_set_line_width(cr, 4)

    for i = 0, n_ticks do
        local sin = math.sin(angle * i + rotate)
        local cos = math.cos(angle * i + rotate)
        local x1 = sin * (radius - margin)
        local y1 = cos * (radius - margin)
        local x2 = sin * (radius - ticks_length)
        local y2 = cos * (radius - ticks_length)
        local color_idx = math.floor(i * #colors / n_ticks)
        local color = colors[color_idx + 1]

        if idx < color_idx then alpha = 0.4 else alpha = 1 end

        cairo_set_source_rgba(cr, color[1], color[2], color[3], alpha)
        cairo_move_to(cr, cx - x1, cy - y1)
        cairo_line_to(cr, cx - x2, cy - y2)
        cairo_stroke(cr)
    end

    cairo_set_source_rgba(cr, 1, 0, 0, 1)
    cairo_set_line_width(cr, 4)
    local a = -math.rad(cpu_load * 300 / 100)
    local x = math.sin(a + rotate) * (radius - ticks_length)
    local y = math.cos(a + rotate) * (radius - ticks_length)
    cairo_move_to(cr, cx, cy)
    cairo_line_to(cr, cx - x, cy - y)
    cairo_stroke(cr)

    cairo_set_source_rgba(cr, 0.4, 0.4, 0.4, 1)
    cairo_arc(cr, cx, cy, 40, 0, 2 * math.pi)
    cairo_fill(cr)

    local k = 10 - math.floor(cpu_load / 12)
    if (clk % k) == 0 then
        local color = colors[idx + 1]
        cairo_set_source_rgba(cr, color[1], color[2], color[3], 1)
        cairo_arc(cr, cx, cy + 30, 3, 0, 2 * math.pi)
        cairo_fill(cr)
    end

    cairo_select_font_face(cr, "neuropol", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
    local te = cairo_text_extents_t:create()
    cairo_set_source_rgba(cr, 1, 1, 1, 1)

    text = cpu_load .. " %"
    cairo_set_font_size(cr, 17)
    cairo_text_extents(cr, text, te)
    cairo_move_to(cr, cx - te.width / 2, cy + te.height / 2)
    cairo_show_text(cr, text)

    text = "Core " .. (cpu + 1)
    cairo_set_font_size(cr, 10)
    cairo_text_extents(cr, text, te)
    cairo_move_to(cr, cx - te.width / 2, cy + te.height * 2.5)
    cairo_show_text(cr, text)

    cairo_stroke(cr)
end



function conky_main()
    if conky_window == nil then return end

    local updates = conky_parse('${updates}')
    local n_updates = tonumber(updates)

    if n_updates < 1 then return end

    local cs = cairo_xlib_surface_create (conky_window.display,
                                          conky_window.drawable,
                                          conky_window.visual,
                                          conky_window.width,
                                          conky_window.height)
    local cr = cairo_create (cs)

    local width = conky_window.width
    local height = conky_window.height
    local diameter = 130
    local radius = diameter / 2
    local cy = height / 2
    local delta = width / n_cpus
    for i = 0, n_cpus - 1 do
        local cx = i * delta + radius + margin
        draw_cpu_dial(cr, i, cx, cy, radius, n_updates)
    end

    cairo_destroy (cr)
    cairo_surface_destroy (cs) 
end

