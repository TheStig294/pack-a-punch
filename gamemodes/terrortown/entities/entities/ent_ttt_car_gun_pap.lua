AddCSLuaFile()

local targetDamageCvar = CreateConVar("ttt_pap_car_gun_target_damage", "10000", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "How much damage the target receives, not players in the way of the truck", 0)

local nonTargetDamageCvar = CreateConVar("ttt_pap_car_gun_non_target_damage", "50", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "How much damage players in the way of the truck receive, not the target", 0)

local speedCvar = CreateConVar("ttt_pap_car_gun_speed", "120", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Speed of the truck prop", 1)

local scaleCvar = CreateConVar("ttt_pap_car_gun_scale", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Size scale of the truck prop", 0.3)

local rangeCvar = CreateConVar("ttt_pap_car_gun_range", "4000", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Range of the truck before it automatically disappears", 10)

ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.PrintName = "Truck"
ENT.AutomaticFrameAdvance = true
ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.TruckTargetDamage = targetDamageCvar:GetInt()
ENT.TruckDamage = nonTargetDamageCvar:GetInt()
ENT.TruckSpeed = speedCvar:GetInt()
ENT.TruckScale = scaleCvar:GetFloat()
ENT.TruckRange = rangeCvar:GetInt()
ENT.ToRemove = false
ENT.Dist = 0
ENT.Target = nil
ENT.DistToTarget = 0
ENT.Wheels = nil

function ENT:Initialize()
    self.TruckTargetDamage = targetDamageCvar:GetInt()
    self.TruckDamage = nonTargetDamageCvar:GetInt()
    self.TruckSpeed = speedCvar:GetInt()
    self.TruckScale = scaleCvar:GetFloat()
    self.TruckRange = rangeCvar:GetInt()
    self:SetModel("models/ttt_pack_a_punch/semitruck/semitruck.mdl")
    self:SetMaterial("models/ttt_pack_a_punch/semitruck/semitruck")
    self:SetModelScale(self.TruckScale)
    self:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)
    self:SetSolid(SOLID_OBB)

    if SERVER then
        self.Trail = util.SpriteTrail(self, 0, Color(200, 200, 200), false, 50, 0, 2, 0.005, "trails/smoke")
        self:SetTrigger(true)
        local ang = self:GetAngles()
        ang:RotateAroundAxis(ang:Up(), -2)
        self:SetAngles(ang)
        local truckpos = self:GetPos()

        if IsValid(self.Target) then
            local targetPos = self.Target:GetPos()
            self.DistToTarget = math.Distance(truckpos.x, truckpos.y, targetPos.x, targetPos.y)
        end

        -- Create separate wheels entity to parent to the truck
        self.Wheels = ents.Create("prop_dynamic")
        self.Wheels:SetModel("models/ttt_pack_a_punch/semitruck/semitruck_wheels.mdl")
        self.Wheels:SetMaterial("models/ttt_pack_a_punch/semitruck/semitruck")
        self.Wheels:SetModelScale(self.TruckScale)
        self.Wheels:SetAngles(self:GetAngles())
        self.Wheels:SetPos(truckpos + Vector(0, 0, 200))
        self.Wheels:SetParent(self)
        self.Wheels:Spawn()
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
    local forward = ang:Forward() * self.TruckSpeed * deltaTime
    self.Dist = self.Dist + forward:Length()

    if self.Dist > self.TruckRange then
        self.ToRemove = true
    end

    self.startPos = self.startPos or pos

    if self.ToRemove then
        if CLIENT then return end
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
        local inflictWep = ents.Create("weapon_ttt_car_gun_pap")
        local dmg = DamageInfo()
        dmg:SetInflictor(inflictWep)

        if IsValid(owner) then
            dmg:SetAttacker(owner)
        end

        dmg:SetDamageType(DMG_VEHICLE)

        -- Target is insta-killed, other players in the way take damage
        if ent == self.Target then
            ent:UnLock()
            dmg:SetDamage(self.TruckTargetDamage)

            timer.Simple(1, function()
                if IsValid(ent) and (ent:IsFrozen() or ent:HasGodMode()) then
                    ent:UnLock()
                end
            end)

            self.ToRemove = true
        else
            dmg:SetDamage(self.TruckDamage)
        end

        -- ent:TakeDamageInfo(dmg)
        self:EmitSound("ttt_pack_a_punch/car_gun/honkhonk.mp3")
    end
end