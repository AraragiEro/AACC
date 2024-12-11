local basalt = require("basalt") -- Loads Basalt into our project

local main = basalt.createFrame() -- Creates a base frame. On that frame, we are able to add objects
    :setTheme({
        FrameBG = colors.black,
        FrameFG = colors.white,
        FrameText = colors.white,
        InputBG = colors.gray,
        InputText = colors.black,
    })

local monitor = peripheral.wrap("left") -- Assuming a monitor is on the top side
local monitorFrame = basalt.addMonitor()
monitorFrame:setMonitor(monitor)

-- create back thread
local myThread = main:addThread()

-- Here we would add additional objects
-- 黄绿反转 1开0关 colors.lime
-- 淡蓝 动力转换 1开0关 colors.lightBlue
-- 淡灰色离合 1动0停 colors.lightGray
-- [黄绿， 淡蓝， 淡灰]
-- {1, 0, 0} 向上
-- {0, 0, 0} 向下
-- {0, 1, 0} 向内
-- {1, 1, 0} 向外
-- {0, 0, 1} 停止

local status_up = {1, 0, 0}
local status_down = {0, 0, 0}
local status_close = {1, 1, 0}
local status_out = {0, 1, 0}
local status_stop = {0, 0, 1}

local function set_status(status)
    local value = 0
    if status[1] == 1 then
        value = value + colors.lime
        --redstone.setBundledOutput("back", colors.lime)
    end
    if status[2] == 1 then
        value = value + colors.lightBlue
        --redstone.setBundledOutput("back", colors.lightBlue)
    end
    if status[3] == 1 then
        value = value + colors.lightGray
        --redstone.setBundledOutput("back", colors.lightGray)
    end
    redstone.setBundledOutput("back", value)
end

-- 向上
local function up()
    redstone.setBundledOutput("back", 0)
    set_status(status_up)
end

-- 向下
local function down()
    redstone.setBundledOutput("back", 0)
    set_status(status_down)
end

-- 向内
local function close()
    redstone.setBundledOutput("back", 0)
    set_status(status_close)
end

-- 向外
local function out()
    redstone.setBundledOutput("back", 0)
    set_status(status_out)
end

local function stop()
    redstone.setBundledOutput("back", 0)
    set_status(status_stop)
end

local frame_x = 2
local frame_y = 2

local subframe = main:addFrame():setSize("parent.w-2", "parent.h-2"):setPosition(2,2)

-- add farm settings
-- inputspeed
local use_y = frame_y
subframe:addLabel()
    :setPosition(frame_x + 0, use_y + 0)
    :setText("input speed:")
local speedInput = subframe:addInput()
    :setInputType("number")
    :setDefaultText("16")    --输入转速
    :setInputLimit(3)
    :setPosition(frame_x + string.len("input speed:") , use_y)
use_y = use_y + 1

-- farm floor
subframe:addLabel()
    :setPosition(frame_x + 0, use_y + 0)
    :setText("farm floor:")
local farmFloorInput = subframe:addInput()
    :setInputType("number")
    :setDefaultText("3")    --输入转速
    :setInputLimit(2)
    :setPosition(frame_x + string.len("farm floor:") , use_y)
use_y = use_y + 1

-- farm height each floor
subframe:addLabel()
    :setPosition(frame_x + 0, use_y + 0)
    :setText("farm height each floor:")
local farmHeightEachFloorInput = subframe:addInput()
    :setInputType("number")
    :setDefaultText("4")    --输入转速
    :setInputLimit(2)
    :setPosition(frame_x + string.len("farm height each floor:") , use_y)
use_y = use_y + 1

-- farm length
subframe:addLabel()
    :setPosition(frame_x + 0, use_y + 0)
    :setText("farm length:")
local farmlengthInput = subframe:addInput()
    :setInputType("number")
    :setDefaultText("15")    --输入转速
    :setInputLimit(2) 
    :setPosition(frame_x + string.len("farm length:") , use_y)
use_y = use_y + 1

-- auto farm loop sleep
subframe:addLabel()
    :setPosition(frame_x + 0, use_y + 0)
    :setText("time between each loop:")
local farmSleepLoopInput = subframe:addInput()
    :setInputType("number")
    :setDefaultText("600")    --输入转速
    :setInputLimit(3) 
    :setPosition(frame_x + string.len("time between each loop:") , use_y)
use_y = use_y + 1

local function one_step()
    local speed = speedInput:getValue()
    if speed == nil or speed == "" then
        speed = speedInput.getDefaultText()
    end
    local one_step_time = 26 / speed
    return one_step_time
end

local function get_value(input)
    local value = input:getValue()
    if value == nil or value == "" then
        value = input.getDefaultText()
    end
    return value
end

local moni_x = 2
local moni_y = 2
use_y = moni_y
-- add init farm Button
local function init_farm()
    close()
    sleep(one_step() * get_value(farmlengthInput))
    down()
    sleep(one_step() * get_value(farmHeightEachFloorInput) * get_value(farmFloorInput))
    stop()
end

monitorFrame:addButton()
    :setPosition(moni_x ,use_y)
    :setSize(string.len("init farm") + 2, 1)
    :setText("init farm")
    :onClick(function ()
        myThread:stop()
        myThread:start(init_farm)
    end)
use_y = use_y + 1

-- add auto farm button
local function auto_farm()
    while true do
        -- stop movement
        close()

        -- first step out and close
        out()
        sleep(one_step() * get_value(farmlengthInput))
        close()
        sleep(one_step() * get_value(farmlengthInput))

        -- go up floor util top with each floor out and close
        for i = 1, get_value(farmFloorInput) - 1 do
            up()
            sleep(one_step() * get_value(farmHeightEachFloorInput))
            out()
            sleep(one_step() * get_value(farmlengthInput))
            close()
            sleep(one_step() * get_value(farmlengthInput))
        end

        -- back to bottom, 10s for item transform.
        down()
        sleep(one_step() * get_value(farmHeightEachFloorInput) * get_value(farmFloorInput) + 10)
        stop()
        -- loop sleep
        sleep(get_value(farmSleepLoopInput))
    end
end

monitorFrame:addButton()
    :setPosition(moni_x ,use_y)
    :setSize(string.len("auto farm") + 2, 1)
    :setText("auto farm")
    :onClick(function ()
        myThread:stop()
        myThread:start(auto_farm)
    end)

use_y = use_y + 1

stop()

basalt.autoUpdate() -- Starts listening to incoming events and draw stuff on the screen. This should nearly always be the last line.