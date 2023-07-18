AddCSLuaFile()

local targetDamageCvar = CreateConVar("ttt_car_gun_target_damage", "10000", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "How much damage the target receives, not players in the way of the car", 0)

local nonTargetDamageCvar = CreateConVar("ttt_car_gun_non_target_damage", "50", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "How much damage players in the way of the car receive, not the target", 0)

local speedCvar = CreateConVar("ttt_car_gun_speed", "150", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Speed of the car prop", 1)

local scaleCvar = CreateConVar("ttt_car_gun_scale", "0.75", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Size scale of the car prop", 0.3)

local rangeCvar = CreateConVar("ttt_car_gun_range", "4000", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Range of the car before it automatically disappears", 10)

ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.PrintName = "Truck"
ENT.AutomaticFrameAdvance = true
ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.Sound = Sound("ttt_car_gun/mycar.mp3")
ENT.CarTargetDamage = targetDamageCvar:GetInt()
ENT.CarDamage = nonTargetDamageCvar:GetInt()
ENT.CarSpeed = speedCvar:GetInt()
ENT.CarScale = scaleCvar:GetFloat()
ENT.CarRange = rangeCvar:GetInt()
ENT.ToRemove = false
ENT.Dist = 0
ENT.Target = nil

local carModels = {"models/props_vehicles/car001a_hatchback.mdl", "models/props_vehicles/car001b_hatchback.mdl", "models/props_vehicles/car002a.mdl", "models/props_vehicles/car002b.mdl", "models/props_vehicles/car003a.mdl", "models/props_vehicles/car003b.mdl", "models/props_vehicles/car004a.mdl", "models/props_vehicles/car004b.mdl", "models/props_vehicles/car005a.mdl", "models/props_vehicles/car005b.mdl"}

function ENT:Initialize()
    self.CarTargetDamage = targetDamageCvar:GetInt()
    self.CarDamage = nonTargetDamageCvar:GetInt()
    self.CarSpeed = speedCvar:GetInt()
    self.CarScale = scaleCvar:GetFloat()
    self.CarRange = rangeCvar:GetInt()
    self:SetModel("models/ttt_pack_a_punch/semitruck/semitruck.mdl")
    self:SetModelScale(self.CarScale)
    self:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)
    self:SetSolid(SOLID_OBB)

    if SERVER then
        self.Trail = util.SpriteTrail(self, 0, Color(200, 200, 200), false, 50, 0, 2, 0.005, "trails/smoke")
        self:SetTrigger(true)
        local ang = self:GetAngles()
        ang:RotateAroundAxis(ang:Up(), -2)
        self:SetAngles(ang)
        self:EmitSound(self.Sound)
        self:EmitSound(self.Sound)
    end
end

function ENT:Think()
    local time = CurTime()
    self.time = self.time or time
    local deltaTime = time - self.time
    self.time = time
    self.runTime = self.runTime or 0 + deltaTime
    local pos = self:GetPos()
    local ang = self:GetAngles()
    ang:RotateAroundAxis(ang:Up(), 2)
    local forward = ang:Forward() * self.CarSpeed * deltaTime
    self.Dist = self.Dist + forward:Length()

    if self.Dist > self.CarRange then
        self.ToRemove = true
    end

    self.startPos = self.startPos or pos

    if self.ToRemove then
        if CLIENT then return end
        self:StopSound(self.Sound)
        self:StopSound(self.Sound)
        SafeRemoveEntity(self.Trail)

        if IsValid(self.Target) and (self.Target:IsFrozen() or self.Target:HasGodMode()) then
            self.Target:UnLock()
        end

        self:Remove()

        return
    end

    local set = pos + forward
    self:SetPos(set)
end

function ENT:StartTouch(ent)
    if not IsValid(ent) or not ent:IsPlayer() then return end
    local owner = self:GetOwner()
    if ent == owner then return end

    if ent:Alive() and not ent:IsSpec() then
        local inflictWep = ents.Create("weapon_ttt_car_gun")
        local dmg = DamageInfo()
        dmg:SetInflictor(inflictWep)

        if IsValid(owner) then
            dmg:SetAttacker(owner)
        end

        dmg:SetDamageType(DMG_VEHICLE)

        -- Target is insta-killed, other players in the way take damage
        if ent == self.Target then
            ent:UnLock()
            dmg:SetDamage(self.CarTargetDamage)

            timer.Simple(1, function()
                if IsValid(ent) and (ent:IsFrozen() or ent:HasGodMode()) then
                    ent:UnLock()
                end
            end)

            self.ToRemove = true
        else
            dmg:SetDamage(self.CarDamage)
        end

        ent:TakeDamageInfo(dmg)
        self:EmitSound("ttt_car_gun/beepbeep.mp3")
    end
end