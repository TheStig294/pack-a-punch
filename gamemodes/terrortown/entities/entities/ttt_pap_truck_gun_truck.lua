AddCSLuaFile()

local targetDamageCvar = CreateConVar("pap_truck_gun_target_damage", "10000", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Damage to target player", 0)

local nonTargetDamageCvar = CreateConVar("pap_truck_gun_non_target_damage", "50", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Damage to other players", 0)

local speedCvar = CreateConVar("pap_truck_gun_speed", "120", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Truck speed", 1, 1000)

local scaleCvar = CreateConVar("pap_truck_gun_scale", "1", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Truck size scale", 0.3, 10)

local rangeCvar = CreateConVar("pap_truck_gun_range", "4000", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Truck range", 10, 10000)

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
ENT.WheelOffset = 300

if SERVER then
    util.AddNetworkString("TTTPAPCarGunVictimPopup")
end

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
        self.Wheels:SetPos(truckpos + Vector(0, 0, self.WheelOffset))
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

        if IsValid(self.Wheels) then
            self.Wheels:Remove()
        end

        self:Remove()

        return
    end

    local set = pos + forward
    self:SetPos(set)

    if SERVER then
        self.Wheels:SetAngles(self:GetAngles())
        -- (self.WheelOffset - (self.WheelOffset * (self.Dist / self.DistToTarget))) --- lerps from 300 to 0 (wheel offset to 0 as truck gets closer)
        -- (- self.WheelOffset / 2) --- To make up for truck being a large model, entity has to travel slightly less distance to hit the player
        local wheelOffset = self.WheelOffset - self.WheelOffset * self.Dist / self.DistToTarget - self.WheelOffset / 2

        if wheelOffset < 0 then
            wheelOffset = 0
        end

        pos.z = pos.z + wheelOffset
        self.Wheels:SetPos(pos)
    end
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

        ent:TakeDamageInfo(dmg)
        ent:EmitSound("ttt_pack_a_punch/truck_gun/honkhonk.mp3")
        net.Start("TTTPAPCarGunVictimPopup")
        net.Send(ent)
    end
end

if CLIENT then
    net.Receive("TTTPAPCarGunVictimPopup", function()
        local mat = Material("ttt_pack_a_punch/truck_gun/trucking_tuesday.png")
        local width = ScrW() / 2
        local height = ScrH() / 2
        local x = ScrW() / 4
        local y = ScrH() / 4
        local currentY = -height
        local unitMovement = (y + height) / 100
        unitMovement = unitMovement * 4

        hook.Add("HUDPaint", "TTTPAPCarGunVictimPopup", function()
            surface.SetDrawColor(255, 255, 255, 255)
            surface.SetMaterial(mat)
            surface.DrawTexturedRect(x, currentY, width, height)
        end)

        timer.Create("TTTPAPCarGunPopupInMove", 0.01, 100, function()
            if currentY < y then
                currentY = currentY + unitMovement
            end
        end)

        timer.Create("TTTPAPCarGunPopupOut", 1.5, 1, function()
            timer.Create("TTTPAPCarGunPopupOutMove", 0.01, 100, function()
                currentY = currentY - unitMovement
            end)
        end)

        timer.Create("TTTPAPCarGunVictimPopup", 6, 1, function()
            hook.Remove("HUDPaint", "TTTPAPCarGunVictimPopup")
        end)
    end)
end