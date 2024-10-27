AddCSLuaFile()

if CLIENT then
    SWEP.PrintName = "Remove Tool"
    SWEP.Slot = 7
    SWEP.Icon = "vgui/ttt/icon_fulton"
    SWEP.ViewModelFlip = false
    SWEP.ViewModelFOV = 72
end

SWEP.Base = "weapon_tttbase"
SWEP.HoldType = "pistol"
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_toolgun.mdl"
SWEP.WorldModel = "models/weapons/w_toolgun.mdl"
SWEP.Kind = WEAPON_EQUIP2
SWEP.AutoSpawnable = false
SWEP.AllowDrop = true
SWEP.NoSights = true
SWEP.Primary.ClipMax = -1
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "AirboatGun"
SWEP.Primary.Sound = "Airboat.FireGunRevDown"
SWEP.HighlightedEnt = {}

function SWEP:Initialize()
    timer.Simple(0.2, function()
        self.Primary.ClipMax = -1
        self.Primary.ClipSize = -1
        self.Primary.DefaultClip = -1
        self:SetClip1(-1)
    end)

    if CLIENT then
        local client = LocalPlayer()

        hook.Add("PreDrawHalos", "TTTPAPRemoveToolHighlight", function()
            self.HighlightedEnt = self.HighlightedEnt or {}
            local wep = client:GetActiveWeapon()
            if not IsValid(wep) or WEPS.GetClass(wep) ~= "ttt_pap_remove_tool" then return end
            halo.Add(self.HighlightedEnt, COLOR_WHITE, 2, 2, 2, true, false)
        end)

        hook.Add("TTTPrepareRound", "TTTPAPRemoveToolReset", function()
            hook.Remove("PreDrawHalos", "TTTPAPRemoveToolHighlight")
            hook.Remove("TTTPrepareRound", "TTTPAPRemoveToolReset")
        end)
    end

    if SERVER then
        hook.Add("TTTOnCorpseCreated", "TTTPAPRemoveToolRemovePlayer", function(rag, ply)
            if ply.TTTPAPRemoveToolDissolveBody then
                rag:Dissolve(0, 10)
                ply.TTTPAPRemoveToolDissolveBody = false
            end
        end)

        hook.Add("TTTPrepareRound", "TTTPAPRemoveToolReset", function()
            for _, ply in player.Iterator() do
                ply.TTTPAPRemoveToolDissolveBody = nil
            end

            hook.Remove("TTTOnCorpseCreated", "TTTPAPRemoveToolRemovePlayer")
            hook.Remove("TTTPrepareRound", "TTTPAPRemoveToolReset")
        end)
    end

    return self.BaseClass.Initialize(self)
end

if CLIENT then
    function SWEP:Think()
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        local ent = self:GetLookedAtEntity()

        if IsValid(ent) then
            if ent:IsPlayer() and (not ent:Alive() or ent:IsSpec()) then return end

            self.HighlightedEnt = {ent}
        else
            self.HighlightedEnt = {}
        end
    end

    function SWEP:Holster()
        self.HighlightedEnt = {}
    end

    function SWEP:OnRemove()
        self.HighlightedEnt = {}
    end
end

-- Modified from Gmod's base tool gun SWEP
local toolmask = bit.bor(CONTENTS_SOLID, CONTENTS_MOVEABLE, CONTENTS_MONSTER, CONTENTS_WINDOW, CONTENTS_DEBRIS, CONTENTS_GRATE, CONTENTS_AUX)

function SWEP:GetLookedAtEntity()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    local tr = util.GetPlayerTrace(owner)
    tr.mask = toolmask
    tr.mins = vector_origin
    tr.maxs = tr.mins
    local trace = util.TraceLine(tr)

    if not trace.Hit then
        trace = util.TraceHull(tr)
    end

    if not trace.Hit then return end

    return trace.Entity, trace
end

function SWEP:PrimaryAttack()
    local owner = self:GetOwner()
    local ent, trace = self:GetLookedAtEntity(owner)

    if IsValid(ent) then
        local effectData = EffectData()
        effectData:SetOrigin(ent:GetPos())
        effectData:SetEntity(ent)
        util.Effect("ttt_pap_remove_tool", effectData, true, true)

        if SERVER then
            SafeRemoveEntity(ent)

            if ent:IsPlayer() and ent:Alive() and not ent:IsSpec() then
                local dmg = DamageInfo()
                dmg:SetDamage(10000)
                dmg:SetDamageType(DMG_ENERGYBEAM)
                dmg:SetInflictor(self)
                dmg:SetAttacker(owner)
                ent.TTTPAPRemoveToolDissolveBody = true
                ent:TakeDamageInfo(dmg)
                self:Remove()
                owner:ConCommand("lastinv")

                timer.Simple(0.1, function()
                    if ent:Alive() and not ent:IsSpec() then
                        ent:Kill()
                    end
                end)
            end
        end
    end

    self:DoShootEffect(trace.HitPos, trace.HitNormal, trace.Entity, trace.PhysicsBone)
end

function SWEP:DoShootEffect(hitpos, hitnormal, entity, physbone)
    local owner = self:GetOwner()
    self:EmitSound(self.Primary.Sound)
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    owner:SetAnimation(PLAYER_ATTACK1)
    if not IsFirstTimePredicted() then return end
    local effectData = EffectData()
    effectData:SetOrigin(hitpos)
    effectData:SetStart(owner:GetShootPos())
    effectData:SetAttachment(1)
    effectData:SetEntity(self)
    util.Effect("ToolTracer", effectData)
end