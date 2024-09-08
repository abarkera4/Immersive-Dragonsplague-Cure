-- Mr. Boobie Buyer --

local re = re
local sdk = sdk
local log = log
local json = json

-- Log Functions
local WriteInfoLogs = false  -- Set to true to enable info logging

local function log_info(info_message)
    if WriteInfoLogs then
        log.info("[Mr. Boobie Buyer > Immersive Dragonsplague Cure]: " .. info_message)
    end
end

local function log_error(error_message)
    log.error("[Mr. Boobie Buyer > Immersive Dragonsplague Cure]: " .. error_message)
end

log_info("Loaded")

local CurativeItemDefinitions = {
    ["67"] = "Panacea",
    ["70"] = "Allheal Elixir"

}

local DeletableCureItemDefinitions = {
    ["175"] = "Emergent Vitality",
    ["176"] = "Governing Soul"

}

local Config = {
    CurativeItems = {},
    DeletableCureItems = {},
    EnableSpecificCure = false,
    EnableSpaCure = true
}

for id, name in pairs(CurativeItemDefinitions) do
    Config.CurativeItems[id] = {name = name, cureEnabled = false}
end
for id, name in pairs(DeletableCureItemDefinitions) do
    Config.DeletableCureItems[id] = {name = name, cureEnabled = false}
end

local ConfigFilePath = "Mr. Boobie\\Immersive Dragonsplague Cure.json"

local preBrineStatus = {}

local function save_config()
    local isSuccess, errorReason = pcall(json.dump_file, ConfigFilePath, Config)
    if not isSuccess then
        log_error("Error saving configuration: " .. tostring(errorReason))
    end
end

local function load_config()
    local status, data = pcall(json.load_file, ConfigFilePath)
    if not status or not data then
        save_config()
        return
    end

    if type(data) == "table" then
        for id, _ in pairs(CurativeItemDefinitions) do
            if data.CurativeItems and data.CurativeItems[id] then
                Config.CurativeItems[id].cureEnabled = data.CurativeItems[id].cureEnabled
            end
        end
        for id, _ in pairs(DeletableCureItemDefinitions) do
            if data.DeletableCureItems and data.DeletableCureItems[id] then
                Config.DeletableCureItems[id].cureEnabled = data.DeletableCureItems[id].cureEnabled
            end
        end
        Config.EnableSpecificCure = data.EnableSpecificCure ~= nil and data.EnableSpecificCure or Config.EnableSpecificCure
        Config.EnableSpaCure = data.EnableSpaCure ~= nil and data.EnableSpaCure or true  
    end

    save_config()
end

load_config()

local function get_pawn_status()
    local pawnManager = sdk.get_managed_singleton("app.PawnManager")
    local statusList = {}

    if pawnManager then
        local characterList = pawnManager:get_PawnCharacterList()
        if characterList then
            for i = 0, characterList:get_Count() - 1 do
                local pawnCharacter = characterList:get_Item(i)
                if pawnCharacter then
                    local pawnDataContextDefine = sdk.find_type_definition("app.PawnDataContext")
                    local typeOfPawnDataContext = pawnDataContextDefine:get_runtime_type()
                    local generateInfo = pawnCharacter:get_GenerateInfo()
                    if generateInfo then
                        local contextHolder = generateInfo:get_Context()
                        if contextHolder then
                            local pawnDataContextInfo = contextHolder.Contexts[typeOfPawnDataContext]
                            if pawnDataContextInfo then
                                local pawnDataContext = pawnDataContextInfo:get_CurrentContext()
                                if pawnDataContext then
                                    local name = pawnDataContext:get_field("_Name")
                                    local possessionLevel = pawnDataContext:get_field("_PossessionLv")
                                    table.insert(statusList, {name = name, possessionLevel = possessionLevel})
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return statusList
end

local function cure_pawns()
    log_info("Initiating cure process...")
    local pawnDataContextDefine = sdk.find_type_definition("app.PawnDataContext")
    local typeOfPawnDataContext = pawnDataContextDefine:get_runtime_type()
    local pawnManager = sdk.get_managed_singleton("app.PawnManager")
    local characterList = pawnManager:get_PawnCharacterList()
    local listSize = characterList:get_Count()

    for i = 0, listSize - 1 do
        local pawnCharacter = characterList:get_Item(i)
        local pawnCharacterId = pawnCharacter:get_CharaIDString()

        if not Config.EnableSpecificCure or (Config.EnableSpecificCure and pawnCharacterId == "ch100000_00") then
            local generateInfo = pawnCharacter:get_GenerateInfo()
            local contextHolder = generateInfo:get_Context()
            local pawnDataContextInfo = contextHolder.Contexts[typeOfPawnDataContext]

            if pawnDataContextInfo ~= nil then
                local pawnDataContext = pawnDataContextInfo:get_CurrentContext()
                pawnDataContext:set_field("_PossessionLv", 0)
                log_info("Cured pawn with ID: " .. tostring(pawnCharacterId))
            end
        end
    end
end
--[[
local function restore_post_brine_status()
    local pawnManager = sdk.get_managed_singleton("app.PawnManager")
    if pawnManager then
        local characterList = pawnManager:get_PawnCharacterList()
        if characterList then
            for i = 0, characterList:get_Count() - 1 do
                local pawnCharacter = characterList:get_Item(i)
                if pawnCharacter then
                    local pawnDataContextDefine = sdk.find_type_definition("app.PawnDataContext")
                    local typeOfPawnDataContext = pawnDataContextDefine:get_runtime_type()
                    local generateInfo = pawnCharacter:get_GenerateInfo()
                    if generateInfo then
                        local contextHolder = generateInfo:get_Context()
                        if contextHolder then
                            local pawnDataContextInfo = contextHolder.Contexts[typeOfPawnDataContext]
                            if pawnDataContextInfo then
                                local pawnDataContext = pawnDataContextInfo:get_CurrentContext()
                                if pawnDataContext then
                                    local name = pawnDataContext:get_field("_Name")
                                    if preBrineStatus[name] and (not Config.EnableSpecificCure or (Config.EnableSpecificCure and pawnCharacter:get_CharaIDString() == "ch100000_00")) then
                                        pawnDataContext:set_field("_PossessionLv", preBrineStatus[name])
                                        log_info("Restored pawn " .. name .. " to possession level " .. tostring(preBrineStatus[name]) .. " after brine.")
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

local function record_pre_brine_status()
    local pawnsStatus = get_pawn_status()
    preBrineStatus = {}
    for _, pawn in ipairs(pawnsStatus) do
        preBrineStatus[pawn.name] = pawn.possessionLevel
    end
end
]]
sdk.hook(sdk.find_type_definition("app.ItemManager"):get_method("useItem"),
    function(args)
        local itemId = tostring(sdk.to_int64(args[3]))

        if Config.CurativeItems[itemId] and Config.CurativeItems[itemId].cureEnabled then
            cure_pawns()
        end
    end,
    nil
)

sdk.hook(sdk.find_type_definition("app.ItemManager"):get_method("deleteItem"),
    function(args)
        local itemDeleted = sdk.to_int64(args[3])
        log_info("deleteItem called for ItemID: "..itemDeleted)
        if Config.DeletableCureItems[tostring(itemDeleted)] and Config.DeletableCureItems[tostring(itemDeleted)].cureEnabled then
            log_info("ItemID: "..itemDeleted.." Deletion triggered cure")
            cure_pawns()
        end
    end)



sdk.hook(sdk.find_type_definition("app.SpaManager"):get_method("activateSpa"),
    function(args)
        if Config.EnableSpaCure then
            cure_pawns()
        end
    end,
    nil
)
--[[]
sdk.hook(sdk.find_type_definition("app.Human"):get_method("Chara_KilledByBrineHandler"),
    function()
        log_info("Chara_KilledByBrineHandler called.")
        record_pre_brine_status()
        -- Original function is called after this pre-hook function.
    end,
    function()
        -- This post-hook function is called after the original function returns.
        restore_post_brine_status()
        log_info("Pawn Infection Level Reset")
        return
    end
)
]]
re.on_draw_ui(function()
    if imgui.tree_node("Immersive Dragonsplague Cure") then

        -- Pawn Status Section
        if imgui.tree_node("Pawn Status") then
            local pawnsStatus = get_pawn_status()
            if #pawnsStatus > 0 then
                for _, pawn in ipairs(pawnsStatus) do
                    imgui.text(pawn.name .. "'s Infection Level: " .. tostring(pawn.possessionLevel))

                end
            else
                imgui.text("No pawns found.")
            end
            imgui.new_line()
            imgui.tree_pop()
        end

        if imgui.tree_node("Cure Configuration") then

            imgui.text("Main Settings:")

        -- Checkbox for "Enable Main Pawn Only"
        local mainPawnCheckboxChanged, newEnableSpecificCure = imgui.checkbox("Enable Main Pawn Only", Config.EnableSpecificCure)
        if mainPawnCheckboxChanged then
            Config.EnableSpecificCure = newEnableSpecificCure
            save_config()
        end
        if imgui.is_item_hovered() then
            imgui.set_tooltip("When enabled, all cure methods will be restricted to the Main Pawn.")
        end

            imgui.new_line()

            imgui.text("Select Items to Cure Dragonsplague:")

            -- Curative Items
            for itemId, itemData in pairs(Config.CurativeItems) do
                local itemChanged, isCureEnabled = imgui.checkbox(itemData.name, itemData.cureEnabled)
                if itemChanged then
                    Config.CurativeItems[itemId].cureEnabled = isCureEnabled
                    save_config()
                end
            end

            -- Deletable Cure Items
            for itemId, itemData in pairs(Config.DeletableCureItems) do
                if not Config.CurativeItems[itemId] then
                    local itemChanged, isCureEnabled = imgui.checkbox(itemData.name, itemData.cureEnabled)
                    if itemChanged then
                        Config.DeletableCureItems[itemId].cureEnabled = isCureEnabled
                        save_config()
                    end
                end
            end
            imgui.new_line()

            imgui.text("Select Unique Methods to Cure Dragonsplague:")

            -- Checkbox for "Enable Spa Cure"
            local spaCureCheckboxChanged, newEnableSpaCure = imgui.checkbox("Enable Spa Cure", Config.EnableSpaCure)
            if spaCureCheckboxChanged then
                Config.EnableSpaCure = newEnableSpaCure
                save_config()
            end

            imgui.tree_pop()
        end

        imgui.tree_pop()
    end
end)