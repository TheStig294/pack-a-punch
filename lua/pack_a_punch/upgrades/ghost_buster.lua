local UPGRADE = {}
UPGRADE.id = "ghost_buster"
UPGRADE.class = "weapon_pha_exorcism"
UPGRADE.name = "Ghost Buster"
UPGRADE.desc = "Removes all haunting phantoms,\nand kills all phantom players without them haunting you!"

function UPGRADE:Apply(SWEP)
    SWEP.PAPOldOnSuccess = SWEP.OnSuccess

    function SWEP:OnSuccess()
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        local killCount = 0
        local cleanseCount = 0

        for _, ply in player.Iterator() do
            if not ply:Alive() or ply:IsSpec() then continue end

            -- Cleanse all players of being haunted by a phantom
            if ply:GetNWBool("PhantomHaunted", false) then
                cleanseCount = cleanseCount + 1
            end

            self:PAPOldOnSuccess(ply)

            -- Kill all phantoms, and mediums if their haunting enhancement from the enhanced detectives mod is enabled
            if ply:IsPhantom() or (ply:IsMedium() and cvars.Bool("ttt_medium_killer_haunt")) then
                ply:Kill()
                ply:QueueMessage(MSG_PRINTBOTH, owner:Nick() .. " cleansed you with an upgraded Exorcism Device!")
                killCount = killCount + 1
            end
        end

        local message

        if killCount == 0 then
            message = "No players were killed"
        elseif killCount == 1 then
            message = "1 player was killed"
        else
            message = killCount .. " players were killed"
        end

        if cleanseCount == 0 then
            message = message .. ", no players were cleansed!"
        elseif cleanseCount == 1 then
            message = message .. ", 1 player was cleansed!"
        else
            message = message .. ", " .. cleanseCount .. " players were cleansed!"
        end

        owner:QueueMessage(MSG_PRINTBOTH, message)
    end

    function SWEP:GetTarget()
        return self:GetOwner(), nil
    end

    function SWEP:IsCurrentTargetValid()
        local owner = self:GetOwner()

        return IsValid(self:GetOwner()) and (owner:KeyDown(IN_ATTACK) or owner:KeyDown(IN_ATTACK2))
    end

    function SWEP:GetProgressMessage()
        return "CLEANSING EVERYONE"
    end
end

TTTPAP:Register(UPGRADE)