------------------------------------------------------------
--  modules/injector.lua | Inject Metadata + Rarity Fallback
--  Dibangunkan oleh PokjadStuff
------------------------------------------------------------

------------------------------------------------------------
-- IMPORT MODULE
------------------------------------------------------------
local Inventory = require 'modules.inventory.server'
local Items     = require 'modules.items.server'
local Shared    = rawget(_G, 'shared') or {}

------------------------------------------------------------
-- DEFAULT CONFIG
------------------------------------------------------------
local DEFAULT_RARITY = 'common' -- fallback rarity

------------------------------------------------------------
-- SIMPAN ASAL FUNCTION
------------------------------------------------------------
local OriginalAddItem = Inventory.AddItem

------------------------------------------------------------
-- DAPATKAN DATA WEAPON DARI SHARED.WEAPONS
------------------------------------------------------------
---@param name string
---@return table|nil
local function GetWeaponData(name)
    if Shared.weapons and Shared.weapons[name] then
        return Shared.weapons[name]
    end
    return nil
end

------------------------------------------------------------
-- INJECT METADATA ITEM / WEAPON + RARITY
------------------------------------------------------------
---@param metadata table?       -- metadata semasa / nil
---@param item     table?       -- data item (optional)
---@param name     string       -- nama item
---@return table                -- metadata akhir
local function InjectMetadata(metadata, item, name)
    metadata = metadata or {}

    -- benarkan panggilan InjectMetadata(item, metadata)
    if type(name) == 'table' then
        item = name
        name = item.name
    end

    if not name or type(name) ~= 'string' then
        print('Invalid item name in InjectMetadata:', name)
        return metadata
    end

    -- metadata asal item
    item = item or Items(name)
    if item and item.metadata then
        for k, v in pairs(item.metadata) do
            if metadata[k] == nil then
                metadata[k] = v
            end
        end
    end

    -- metadata senjata
    if name:find('WEAPON_') then
        local weapon = GetWeaponData(name)
        if weapon and weapon.metadata then
            for k, v in pairs(weapon.metadata) do
                if metadata[k] == nil then
                    metadata[k] = v
                end
            end
        end
    end

    ------------------------------------------------------------
    -- FALLBACK RARITY JIKA TIADA: COMMON
    ------------------------------------------------------------
    if metadata.rarity == nil then
        metadata.rarity = DEFAULT_RARITY
    end

    return metadata
end

------------------------------------------------------------
-- OVERRIDE FUNGSI ADDITEM UTAMA
------------------------------------------------------------
---@param inventory table
---@param name      string
---@param count     number
---@param metadata  table?
---@return boolean, string?     -- berjaya?, ralat?
function Inventory.AddItem(inventory, name, count, metadata)
    metadata = InjectMetadata(metadata, nil, name)
    return OriginalAddItem(inventory, name, count, metadata)
end

------------------------------------------------------------
-- EXPORT FUNGSI UNTUK RESOURCE LAIN
------------------------------------------------------------
exports('AddItem', function(target, name, count, metadata)
    metadata = InjectMetadata(metadata, nil, name)
    return Inventory.AddItem(target, name, count, metadata)
end)

------------------------------------------------------------
-- RETURN MODULE
------------------------------------------------------------
return {
    InjectMetadata = InjectMetadata
}