local UPGRADE = {}
UPGRADE.id = "mini_mush"
UPGRADE.class = "giantsupermariomushroom"
UPGRADE.name = "Mini Mush"
UPGRADE.desc = "1/3 size + floaty jump"
UPGRADE.noSound = true
local playerQueue = {}

function UPGRADE:Apply(SWEP)
    SWEP.PAPOldPrimaryAttack = SWEP.PrimaryAttack

    function SWEP:PrimaryAttack()
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        local mult = 0.33
        local modelScale = owner:GetModelScale()
        local viewOffset = owner:GetViewOffset()
        local viewOffsetDucked = owner:GetViewOffsetDucked()
        local gravity = owner:GetGravity()
        -- Fix for when TTT2 is not installed
        owner.GetSubRoleModel = owner.GetSubRoleModel or function(ply) return ply:GetModel() end

        owner.SetSubRoleModel = owner.SetSubRoleModel or function(ply, model)
            UPGRADE:SetModel(ply, model)
        end

        self:PAPOldPrimaryAttack()
        -- The base weapon should reset these on its own, except for gravity
        owner:SetModelScale(modelScale * mult, 2)
        owner:SetViewOffset(viewOffset * mult)
        owner:SetViewOffsetDucked(viewOffsetDucked * mult)
        owner:SetGravity(gravity * mult)
        owner.TTTPAPMiniMushGravity = gravity
        table.insert(playerQueue, owner)
    end

    -- Yet another global function...
    -- (But hey, at least this makes making upgrades easier?)
    local oldMarioRestore = marioRestore

    function marioRestore()
        oldMarioRestore()
        -- This function doesn't get the player to restore passed to it (lol)
        -- So we have to use a queue just to keep track of which player to restore when this gets called...
        if table.IsEmpty(playerQueue) then return end
        local ply = playerQueue[1]
        table.remove(playerQueue, 1)

        if IsValid(ply) and ply.TTTPAPMiniMushGravity then
            ply:SetGravity(ply.TTTPAPMiniMushGravity)
            ply.TTTPAPMiniMushGravity = nil
        end
    end
end

function UPGRADE:Reset()
    for _, ply in player.Iterator() do
        if ply.TTTPAPMiniMushGravity then
            ply:SetGravity(ply.TTTPAPMiniMushGravity)
            ply.TTTPAPMiniMushGravity = nil
        end
    end
end

TTTPAP:Register(UPGRADE)