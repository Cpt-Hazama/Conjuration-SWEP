if (!file.Exists("autorun/vj_base_autorun.lua","LUA")) then return end
---------------------------------------------------------------------------------------------------------------------------------------------
SWEP.Base 						= "weapon_vj_base"
SWEP.PrintName					= "Master Conjuration"
SWEP.Author 					= "Cpt. Hazama"
SWEP.Contact					= "http://steamcommunity.com/groups/vrejgaming"
SWEP.Purpose					= ""
SWEP.Instructions				= ""
SWEP.Category					= "VJ Base - Spells"
	-- Client Settings ---------------------------------------------------------------------------------------------------------------------------------------------
if CLIENT then
	SWEP.Slot						= 1 -- Which weapon slot you want your SWEP to be in? (1 2 3 4 5 6) 
	SWEP.SlotPos					= 1 -- Which part of that slot do you want the SWEP to be in? (1 2 3 4 5 6)
	SWEP.SwayScale 					= 2 -- Default is 1, The scale of the viewmodel sway
	SWEP.UseHands					= true
	SWEP.ViewModelFOV				= 80

	local matConj = Material("cpthazama/conjured")
	net.Receive("VJ_ConjureEffects",function(len)
		local ent = net.ReadEntity()

		if !IsValid(ent) then return end

		function ent:RenderOverride()
			local tmCur = UnPredictedCurTime()
			local ent = self
			local a = 1
			local d = 4
			local posEye = EyePos()
			cam.Start3D(posEye,EyeAngles())
				self:DrawModel()
			cam.End3D()
			render.SetColorModulation(1,1,1)
			cam.Start3D(posEye,EyeAngles())
				render.SetBlend(1)
				render.MaterialOverride(matConj)
					self:DrawModel()
				render.MaterialOverride(0)
				render.SetBlend(1)
			cam.End3D()
		end
	end)
end
	-- Main Settings ---------------------------------------------------------------------------------------------------------------------------------------------
SWEP.ViewModel					= "models/cpthazama/skyrim/weapons/c_conjuration.mdl"
SWEP.WorldModel					= "models/weapons/w_bugbait.mdl"
SWEP.HoldType 					= "knife"
SWEP.Spawnable					= true
SWEP.AdminSpawnable				= true
	-- Primary Fire ---------------------------------------------------------------------------------------------------------------------------------------------
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"

SWEP.Primary.DisableBulletCode	= true -- The bullet won't spawn, this can be used when creating a projectile-based weapon
SWEP.PrimaryEffects_MuzzleAttachment = 1
SWEP.PrimaryEffects_SpawnShells = false
SWEP.PrimaryEffects_MuzzleFlash = false
SWEP.PrimaryEffects_SpawnDynamicLight = false
	-- Deployment Settings ---------------------------------------------------------------------------------------------------------------------------------------------
SWEP.DelayOnDeploy 				= 0.6 -- Time until it can shoot again after deploying the weapon
	-- Idle Settings ---------------------------------------------------------------------------------------------------------------------------------------------
SWEP.HasIdleAnimation			= true -- Does it have a idle animation?
SWEP.AnimTbl_Idle				= {ACT_VM_IDLE}
SWEP.NextIdle_Deploy			= 0.5 -- How much time until it plays the idle animation after the weapon gets deployed
SWEP.NextIdle_PrimaryAttack		= 0.5 -- How much time until it plays the idle animation after attacking(Primary)

SWEP.WorldModel_UseCustomPosition = true -- Should the gun use custom position? This can be used to fix guns that are in the crotch
SWEP.WorldModel_CustomPositionAngle = Vector(0,0,180)
SWEP.WorldModel_CustomPositionOrigin = Vector(-5,5,0)
---------------------------------------------------------------------------------------------------------------------------------------------
SWEP.ChargeT = 0
SWEP.ViewModelAdjust = {
	Pos = {x=0,y=0,z=-2},
	Ang = {r=0,p=0,y=0},
}
SWEP.MaxSummons = 2
---------------------------------------------------------------------------------------------------------------------------------------------
if SERVER then
	util.AddNetworkString("VJ_ConjureEffects")
end
---------------------------------------------------------------------------------------------------------------------------------------------
local defAng = Angle(0,0,0)
--
function SWEP:PostDrawViewModel(vm,weapon,ply)
	for i = 1,vm:GetBoneCount() -1 do
		if string.find(vm:GetBoneName(i),"Finger") then
			local rand = AngleRand()
			if vm:GetSequenceName(vm:GetSequence()) == "idle" then
				rand.x = rand.x * 0.1
				rand.y = rand.y * 0.2
				rand.z = rand.z * 0.1
			else
				rand = defAng
			end
			vm:ManipulateBoneAngles(i,LerpAngle(FrameTime() *1,vm:GetManipulateBoneAngles(i),rand))
		end
	end
end
---------------------------------------------------------------------------------------------------------------------------------------------
function SWEP:GetViewModelPosition(pos,ang)
	pos:Add(ang:Right() *(self.ViewModelAdjust.Pos.x))
	pos:Add(ang:Forward() *(self.ViewModelAdjust.Pos.y))
	pos:Add(ang:Up() *(self.ViewModelAdjust.Pos.z))
	ang:RotateAroundAxis(ang:Right(),self.ViewModelAdjust.Ang.r)
	ang:RotateAroundAxis(ang:Forward(),self.ViewModelAdjust.Ang.p)
	ang:RotateAroundAxis(ang:Up(),self.ViewModelAdjust.Ang.y)

	return pos,ang
end
---------------------------------------------------------------------------------------------------------------------------------------------
function SWEP:CustomOnInitialize()
	self.Stage = 0 -- 0 = Idle, 1 = Charging, 2 = Charged, 3 = Casting
	self.NextPrimaryAnimT = 0
	self.HoldDownThreshold = 0
	self.NextReloadTime = 0

	self.ChargeSound = CreateSound(self,"cpthazama/skyrim/mag/mag_conjure_ready_lp.wav")
	self.ChargeSound:SetSoundLevel(65)
end
---------------------------------------------------------------------------------------------------------------------------------------------
function SWEP:CustomOnThink()
	local stage = self.Stage
	local owner = self.Owner
	local vm = self.Owner:GetViewModel()
	local atk = owner:KeyDown(IN_ATTACK)

	if atk then
		self.HoldDownThreshold = self.HoldDownThreshold +0.1
		if self.HoldDownThreshold < 1 then return end
		if CurTime() <= self.NextPrimaryAnimT then return end
		if stage == 0 then
			self.ChargeSound:Stop()
			self.ViewModelAdjust.Pos.z = -1
			self:SendWeaponAnim(ACT_VM_RECOIL1)
			self.NextPrimaryAnimT = CurTime() +VJ_GetSequenceDuration(vm,ACT_VM_RECOIL1)
			VJ_CreateSound(self,"cpthazama/skyrim/mag/mag_conjuration_charge_050.wav",65)
			timer.Simple(VJ_GetSequenceDuration(vm,ACT_VM_PRIMARYATTACK) -0.1, function()
				if IsValid(self) && IsValid(owner) && owner:GetActiveWeapon() == self then
					self.Stage = 1
					self.ChargeSound:Play()
				end
			end)
		elseif stage == 1 then
			self:SendWeaponAnim(ACT_VM_RECOIL2)
			self.NextPrimaryAnimT = CurTime() +VJ_GetSequenceDuration(vm,ACT_VM_RECOIL2)
		end
	else
		self.HoldDownThreshold = 0
		if stage == 1 then
			self.ChargeSound:Stop()
			self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
			self.NextPrimaryAnimT = CurTime() +VJ_GetSequenceDuration(vm,ACT_VM_PRIMARYATTACK)
			self.Stage = 0
			VJ_CreateSound(self,"cpthazama/skyrim/mag/mag_conjure_fire.wav",75)
			timer.Simple(0.5, function()
				if IsValid(self) && IsValid(owner) then
					self:Summon(owner)
				end
			end)
			timer.Simple(VJ_GetSequenceDuration(vm,ACT_VM_PRIMARYATTACK), function()
				if IsValid(self) then
					self:DoIdleAnimation()
					self.ViewModelAdjust.Pos.z = -2
				end
			end)
		end
	end
end
---------------------------------------------------------------------------------------------------------------------------------------------
function SWEP:Summon(owner)
	if CLIENT then return end

	owner.VJ_SummonA = owner.VJ_SummonA or nil
	owner.VJ_SummonB = owner.VJ_SummonB or nil

	if IsValid(owner.VJ_SummonA) && IsValid(owner.VJ_SummonB) then
		local v = owner.VJ_SummonA
		owner.VJ_SummonA = owner.VJ_SummonB
		v:SetHealth(0)
		v:TakeDamage(999999999,v,v)
		v:Remove()
	end

	local tr = util.TraceLine({
		start = owner:GetShootPos(),
		endpos = owner:GetShootPos() +owner:GetAimVector() *750,
		filter = owner,
		mask = MASK_SHOT_HULL
	})
	local ent = ents.Create(self.SummonEntity or GetConVarString("vj_conjuration_ent") or "npc_vj_hlr2_zombie")
	ent:SetPos(tr.HitPos +tr.HitNormal *5)
	ent:SetAngles(owner:GetAngles())
	ent:Spawn()
	ent.AllowPrintingInChat = false
	ent.FriendsWithAllPlayerAllies = true
	ent.DeathCorpseFade = true
	ent.DeathCorpseFadeTime = 0.1
	local ownerTbl = owner.VJ_NPC_Class
	if ownerTbl == nil or #ownerTbl <= 0 then
		owner.VJ_NPC_Class = {"CLASS_" .. owner:Nick()}
	end
	ent.VJ_NPC_Class = owner.VJ_NPC_Class
	local time = self.SummonTime or false
	local hpMax = ent:GetMaxHealth()
	if !time then
		if hpMax <= 200 then
			time = 30
		elseif hpMax > 200 && hpMax <= 500 then
			time = 60
		elseif hpMax > 500 then
			time = 120
		end
	end
	if !IsValid(owner.VJ_SummonA) then
		owner.VJ_SummonA = ent
	else
		owner.VJ_SummonB = ent
	end
	ent.VJ_SummonTime = CurTime() +time
	VJ_CreateSound(ent,"cpthazama/skyrim/mag/mag_conjure_impact_01.wav",75)
	sound.Play("cpthazama/skyrim/mag/mag_conjure_portal.wav",ent:GetPos(),85)
	sound.Play("cpthazama/skyrim/mag/mag_conjure_portal_open_2d.wav",ent:GetPos(),150)
	owner:PrintMessage( HUD_PRINTTALK,ent:GetName() .. " has been summoned for " .. time .. " seconds!")

	net.Start("VJ_ConjureEffects")
		net.WriteEntity(ent)
	net.Broadcast()

	local hookName = "VJ_Conjuration_" .. ent:EntIndex()
	hook.Add("Think",hookName,function()
		if !IsValid(ent) or !IsValid(owner) then
			if IsValid(ent) then
				ent:SetHealth(0)
				ent:TakeDamage(999999999,ent,ent)
				ent:Remove()
			end
			hook.Remove("Think",hookName)
			return
		end

		local enemy = ent:GetEnemy()
		ent.FollowingPlayer = !IsValid(enemy)
		ent.FollowPlayer_Entity = owner
		ent.GuardingPosition = nil
		ent.GuardingFacePosition = nil
		if IsValid(owner) && owner:Health() <= 0 && IsValid(ent) or CurTime() > ent.VJ_SummonTime then
			ent:SetHealth(0)
			ent:TakeDamage(999999999,ent,ent)
			ent:Remove()
		end
	end)
end
---------------------------------------------------------------------------------------------------------------------------------------------
function SWEP:PrimaryAttack()
	return false
end
---------------------------------------------------------------------------------------------------------------------------------------------
function SWEP:SecondaryAttack()
	return false
end
---------------------------------------------------------------------------------------------------------------------------------------------
function SWEP:CustomOnHolster(newWep)
	self.Stage = 0
	self.ChargeSound:Stop()
	return true
end
---------------------------------------------------------------------------------------------------------------------------------------------
function SWEP:Reload()
	if self.SummonEntity then return end
	if CurTime() <= self.NextReloadTime then return end
	self:GetOwner():ConCommand("vj_conjuration_opennpcselect")
	self.NextReloadTime = CurTime() +1
	return false
end
---------------------------------------------------------------------------------------------------------------------------------------------
function SWEP:CustomOnRemove()
	self.ChargeSound:Stop()
end
---------------------------------------------------------------------------------------------------------------------------------------------
function SWEP:CalcViewModelView(ViewModel, OldEyePos, OldEyeAng, EyePos, EyeAng) -- Credits to Rex for the sway code, he did a really good job on it. Used without permission but he loves Daddy so I'm sure he won't mind ;)
	local EyePos, EyeAng = self:GetViewModelPosition(OldEyePos, OldEyeAng)
	local ply = self:GetOwner()
	local EyePos = OldEyePos
	local EyeAng = OldEyeAng

	local realspeed = ply:GetVelocity():Length2D() /ply:GetRunSpeed()
	local speed = math.Clamp(ply:GetVelocity():Length2DSqr() /ply:GetRunSpeed(), 0.25, 1)

	local bob_x_val = CurTime()*8
	local bob_y_val = CurTime()*16
	
	local bob_x = math.sin(bob_x_val*0.15)*0.3
	local bob_y = math.sin(bob_y_val*0.15)*0.2
	EyePos = EyePos + EyeAng:Right()*bob_x
	EyePos = EyePos + EyeAng:Up()*bob_y
	EyeAng:RotateAroundAxis(EyeAng:Forward(), 5 *bob_x)
	
	local speed_mul = 2.5
	if self:GetOwner():IsOnGround() && realspeed > 0.1 then
		local bobspeed = math.Clamp(realspeed*0.7, 0, 1)
		local bob_x = math.sin(bob_x_val*1*speed)*0.2*bobspeed
		local bob_y = math.cos(bob_y_val*1*speed)*0.1*bobspeed
		EyePos = EyePos + EyeAng:Right()*bob_x*speed_mul *0.65
		EyePos = EyePos + EyeAng:Up() *bob_y *speed_mul *1.5
	end

	if FrameTime() < 0.04 then
		if !self.SwayPos then self.SwayPos = Vector() end
		local vel = ply:GetVelocity()
		vel.x = math.Clamp(vel.x /150, -5, 5)
		vel.y = math.Clamp(vel.y /150, -5, 5)
		vel.z = math.Clamp(vel.z /300, -1, 0.5)
		
		self.SwayPos = LerpVector(FrameTime()*20, self.SwayPos, -vel)
		EyePos = EyePos + self.SwayPos
	end

	local EyePos, EyeAng = self:GetViewModelPosition(EyePos, EyeAng)
	return EyePos, EyeAng
end
---------------------------------------------------------------------------------------------------------------------------------------------
usableList = usableList or {}
if #usableList == 0 then
	for x,v in pairs(list.Get("NPC")) do
		if !string.find(x,"_vj_") then
			continue
		end
		local icon = file.Exists("materials/vgui/entities/" .. x .. ".vmt","GAME") && "vgui/entities/" .. x or file.Exists("materials/entities/" .. x .. ".png","GAME") && "entities/" .. x .. ".png" or nil
		if icon == nil then
			icon = "vgui/hand"
		end
		usableList[x] = icon
	end
end
--
function SWEP:DrawHUD()
	local ply = self.Owner
	if ply != LocalPlayer() then return end

	local smooth = 8
	local posX = 0.465
	local posY = 0.87
	local bX = 160
	local bY = 160
	draw.RoundedBox(1,ScrW() *posX,ScrH() *posY,bX,bY,Color(20,20,20,225))

	surface.SetDrawColor(255,255,255,255)
	surface.SetMaterial(Material(self.SummonEntity == nil && usableList[GetConVarString("vj_conjuration_ent")] or "entities/" .. self:GetClass() .. ".png"))
	-- surface.SetMaterial(Material(usableList["npc_vj_hlr2_zombie"]))
	surface.DrawTexturedRect(ScrW() *posX +bX/2 -(bX *0.95) /2,ScrH() *posY +bY/2 -(bY *0.95) /2,bX *0.95,bY *0.95)
end
---------------------------------------------------------------------------------------------------------------------------------------------
CreateClientConVar("vj_conjuration_entname","Zombie",true,false)
CreateClientConVar("vj_conjuration_ent","npc_vj_hlr2_zombie",true,false)
--
if CLIENT then
	concommand.Add("vj_conjuration_opennpcselect",function(ply,cmd,args)
		local MenuFrame = vgui.Create('DFrame')
		MenuFrame:SetSize(420, 440)
		MenuFrame:SetPos(ScrW() *0.6, ScrH() *0.1)
		MenuFrame:SetTitle("Select Conjuration")
		MenuFrame:SetBackgroundBlur(true)
		MenuFrame:SetFocusTopLevel(true)
		MenuFrame:SetSizable(true)
		MenuFrame:ShowCloseButton(true)
		MenuFrame:MakePopup()
		
		local CheckList = vgui.Create("DListView")
			CheckList:SetTooltip(false)
			CheckList:SetParent(MenuFrame)
			CheckList:SetPos(10,30)
			CheckList:SetSize(400,400) -- Size
			CheckList:SetMultiSelect(false)
			CheckList:AddColumn("Name")
			CheckList:AddColumn("Class")
			CheckList:AddColumn("Category")
			function CheckList:DoDoubleClick(lineID,line)
				LocalPlayer():ConCommand("vj_conjuration_entname "..line:GetValue(1))
				LocalPlayer():ConCommand("vj_conjuration_ent "..line:GetValue(2))
				MenuFrame:Close()
			end

		for _,v in pairs(list.Get("NPC")) do
			if !string.find(v.Class,"_vj_") then
				continue
			end
			getcat = v.Category
			if v.Category == "" then getcat = "Unknown" end
			CheckList:AddLine(v.Name,v.Class,getcat)
		end
		CheckList:SortByColumn(1,false)
	end)
end