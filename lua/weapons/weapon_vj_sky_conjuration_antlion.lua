if (!file.Exists("autorun/vj_base_autorun.lua","LUA")) then return end
---------------------------------------------------------------------------------------------------------------------------------------------
SWEP.Base 						= "weapon_vj_sky_conjuration"
SWEP.PrintName					= "Conjure Antlion Soldier"
SWEP.Author 					= "Cpt. Hazama"
SWEP.Contact					= "http://steamcommunity.com/groups/vrejgaming"
SWEP.Purpose					= ""
SWEP.Category					= "VJ Base - Spells"

SWEP.Spawnable					= true
SWEP.AdminSpawnable				= false

SWEP.SummonEntity = "npc_vj_hlr2_antlion"
SWEP.SummonName = "Antlion Soldier"
SWEP.SummonTime = 30

SWEP.Instructions				= "Conjures a" .. SWEP.SummonName .. " for " .. SWEP.SummonTime .. " seconds to fight by your side."