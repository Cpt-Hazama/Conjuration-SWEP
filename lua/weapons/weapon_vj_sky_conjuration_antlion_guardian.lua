if (!file.Exists("autorun/vj_base_autorun.lua","LUA")) then return end
---------------------------------------------------------------------------------------------------------------------------------------------
SWEP.Base 						= "weapon_vj_sky_conjuration"
SWEP.PrintName					= "Conjure Antlion Guardian"
SWEP.Author 					= "Cpt. Hazama"
SWEP.Contact					= "http://steamcommunity.com/groups/vrejgaming"
SWEP.Purpose					= ""
SWEP.Instructions				= ""
SWEP.Category					= "VJ Base - Spells"

SWEP.Spawnable					= true
SWEP.AdminSpawnable				= false

SWEP.SummonEntity = "npc_vj_hlr2_antlion_guardian"
SWEP.SummonName = "Antlion Guardian"
SWEP.SummonTime = 60

SWEP.Instructions				= "Conjures a" .. SWEP.SummonName .. " for " .. SWEP.SummonTime .. " seconds to fight by your side."