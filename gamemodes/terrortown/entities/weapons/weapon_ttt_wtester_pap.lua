-- DNA Scanner
AddCSLuaFile()
DEFINE_BASECLASS"weapon_tttbase"
SWEP.HoldType = "normal"

if CLIENT then
    SWEP.PrintName = "Traitor Tester"
    SWEP.Slot = 8
    SWEP.ViewModelFOV = 10
    SWEP.DrawCrosshair = false

    SWEP.EquipMenuData = {
        type = "item_weapon",
        desc = "dna_desc"
    }

    SWEP.Icon = "vgui/ttt/icon_wtester"
end

SWEP.Base = "weapon_tttbase"
SWEP.ViewModel = "models/weapons/v_crowbar.mdl"
SWEP.WorldModel = "models/props_lab/huladoll.mdl"
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Delay = 1
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.Delay = 2
SWEP.Kind = WEAPON_ROLE
SWEP.CanBuy = nil -- no longer a buyable thing
SWEP.WeaponID = AMMO_WTESTER
SWEP.InLoadoutFor = nil
SWEP.AutoSpawnable = false
SWEP.NoSights = true
SWEP.Range = 175
SWEP.ItemSamples = {}
SWEP.NowRepeating = nil
SWEP.PAPDesc = "Use on someone to test them! Takes longer to test with each use"
local MAX_ITEM = 30
SWEP.MaxItemSamples = MAX_ITEM
local MAX_CHARGE = 1250
AccessorFuncDT(SWEP, "charge", "Charge")
AccessorFuncDT(SWEP, "last_scanned", "LastScanned")
SWEP.NextCharge = 0

function SWEP:Initialize()
    self:SetCharge(MAX_CHARGE)
    self:SetLastScanned(-1)

    return self.BaseClass.Initialize(self)
end

local beep_miss = Sound("player/suit_denydevice.wav")
SWEP.TestDelay = 30
SWEP.TestInProgress = false

function SWEP:PrimaryAttack()
    -- Checking if item use is valid
    if CLIENT then return end
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    -- Preventing multiple uses of the tester at once
    if self.TestInProgress then
        owner:PrintMessage(HUD_PRINTCENTER, "You can only test 1 player at a time!")
        owner:PrintMessage(HUD_PRINTTALK, "You can only test 1 player at a time!")
        self:EmitSound(beep_miss)

        return
    end

    -- Finding the hit player
    local spos = self:GetOwner():GetShootPos()
    local sdest = spos + (self:GetOwner():GetAimVector() * self.Range)

    local tr = util.TraceLine({
        start = spos,
        endpos = sdest,
        filter = {self:GetOwner()},
        mask = MASK_SHOT
    })

    local hitent = tr.Entity
    if not IsValid(hitent) or not hitent:IsPlayer() then return end
    if not hitent:Alive() or hitent:IsSpec() then return end
    self:EmitSound(beep_miss)
    print("Hit player:", hitent)
    -- Displaying a message to the player to be tested
    local message
    local displayedDelay = self.TestDelay

    if displayedDelay > 60 then
        displayedDelay = math.Round(self.TestDelay / 60) .. " minutes!"
    else
        displayedDelay = self.TestDelay .. " seconds!"
    end

    message = "You'll be traitor-tested in " .. displayedDelay
    hitent:PrintMessage(HUD_PRINTCENTER, message)
    hitent:PrintMessage(HUD_PRINTTALK, message)
    -- Displaying a message to the owner
    message = hitent:Nick() .. " will be tested in " .. displayedDelay
    owner:PrintMessage(HUD_PRINTCENTER, message)
    owner:PrintMessage(HUD_PRINTTALK, message)
    -- Finding if the player is a traitor
    local role = hitent:GetRole()
    local isTraitor = false

    if role == ROLE_TRAITOR or (hitent.IsTraitorTeam and hitent:IsTraitorTeam()) then
        isTraitor = true
    end

    self.TestInProgress = true

    timer.Create("PaPDnaScannerTest" .. owner:SteamID64(), self.TestDelay, 1, function()
        self.TestInProgress = false

        if IsValid(hitent) then
            self.TestDelay = self.TestDelay * 2
            local msg = hitent:Nick() .. " is "

            if isTraitor then
                msg = msg .. "a traitor!"
            else
                msg = msg .. "not a traitor..."
            end

            owner:PrintMessage(HUD_PRINTCENTER, msg)
            owner:PrintMessage(HUD_PRINTTALK, msg)
        end
    end)
end

hook.Add("TTTPrepareRound", "PaPDnaScannerReset", function()
    for _, ply in ipairs(player.GetAll()) do
        timer.Remove("PaPDnaScannerTest" .. ply:SteamID64())
    end
end)

function SWEP:SecondaryAttack()
end

if CLIENT then
    function SWEP:DrawHUD()
        local spos = self:GetOwner():GetShootPos()
        local sdest = spos + (self:GetOwner():GetAimVector() * self.Range)

        local tr = util.TraceLine({
            start = spos,
            endpos = sdest,
            filter = self:GetOwner(),
            mask = MASK_SHOT
        })

        local length = 20
        local gap = 6
        local can_sample = false
        local ent = tr.Entity

        if IsValid(ent) then
            -- weapon or dropped equipment
            if ((ent:IsWeapon() or ent.CanHavePrints) or ent:GetNWBool("HasPrints", false) or (ent:GetClass() == "prop_ragdoll" and CORPSE.GetPlayerNick(ent, false) and CORPSE.GetFound(ent, false))) then
                -- knife in corpse, or a ragdoll
                surface.SetDrawColor(0, 255, 0, 255)
                gap = 0
                can_sample = true
            else
                surface.SetDrawColor(255, 0, 0, 200)
                gap = 0
            end
        else
            surface.SetDrawColor(255, 255, 255, 200)
        end

        local x = ScrW() / 2.0
        local y = ScrH() / 2.0
        surface.DrawLine(x - length, y, x - gap, y)
        surface.DrawLine(x + length, y, x + gap, y)
        surface.DrawLine(x, y - length, x, y - gap)
        surface.DrawLine(x, y + length, x, y + gap)
    end
end

function SWEP:OnRemove()
end

function SWEP:OnDrop()
end

function SWEP:PreDrop()
    if IsValid(self:GetOwner()) then
        self:GetOwner().scanner_weapon = nil
        timer.Remove("PaPDnaScannerTest" .. owner:SteamID64())
        self.TestInProgress = false
    end
end

function SWEP:Reload()
    return false
end

function SWEP:Deploy()
    if SERVER and IsValid(self:GetOwner()) then
        self:GetOwner():DrawViewModel(false)
        self:GetOwner().scanner_weapon = self
    end

    return true
end

if CLIENT then
    function SWEP:DrawWorldModel()
        if not IsValid(self:GetOwner()) then
            self:DrawModel()
        end
    end
end