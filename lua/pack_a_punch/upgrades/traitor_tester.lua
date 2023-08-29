local UPGRADE = {}
UPGRADE.id = "traitor_tester"
UPGRADE.class = "weapon_ttt_wtester"
UPGRADE.name = "Traitor Tester"
UPGRADE.desc = "Use on someone while standing next to them to test them!\nTesting delay time doubles with each use"

UPGRADE.convars = {
    {
        name = "pap_traitor_tester_initial_seconds",
        type = "int"
    }
}

local secsCvar = CreateConVar("pap_traitor_tester_initial_seconds", "30", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Initial testing delay in seconds", 1, 60)

local beep_miss = Sound("player/suit_denydevice.wav")

function UPGRADE:Apply(SWEP)
    SWEP.TestDelay = secsCvar:GetInt()
    SWEP.TestInProgress = false

    function SWEP:PrimaryAttack()
        -- Checking if item use is valid
        if CLIENT then return end
        local owner = self:GetOwner()
        if not IsValid(owner) then return end

        -- Preventing multiple uses of the tester at once
        if self.TestInProgress then
            owner:PrintMessage(HUD_PRINTCENTER, "You can only test 1 player at a time!")
            self:EmitSound(beep_miss)

            return
        end

        -- Finding the hit player
        local spos = self:GetOwner():GetShootPos()
        local sdest = spos + self:GetOwner():GetAimVector() * self.Range

        local tr = util.TraceLine({
            start = spos,
            endpos = sdest,
            filter = {self:GetOwner()},
            mask = MASK_SHOT
        })

        local hitent = tr.Entity

        if not IsValid(hitent) or not hitent:IsPlayer() then
            owner:PrintMessage(HUD_PRINTCENTER, "You must get near a player to test them!")
            self:EmitSound(beep_miss)

            return
        end

        if not hitent:Alive() or hitent:IsSpec() then return end
        self:EmitSound(beep_miss)
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

        if role == ROLE_TRAITOR or hitent.IsTraitorTeam and hitent:IsTraitorTeam() then
            isTraitor = true
        end

        self.TestInProgress = true

        timer.Create("PAPDNAScannerTest" .. owner:SteamID64(), self.TestDelay, 1, function()
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

    function SWEP:PreDrop()
        local owner = self:GetOwner()

        if IsValid(owner) then
            owner.scanner_weapon = nil
            timer.Remove("PAPDNAScannerTest" .. owner:SteamID64())
            self.TestInProgress = false
        end
    end

    function SWEP:SecondaryAttack()
    end
end

function UPGRADE:Reset()
    for _, ply in ipairs(player.GetAll()) do
        local id = ply:SteamID64()

        if id then
            timer.Remove("PAPDNAScannerTest" .. id)
        end
    end
end

TTTPAP:Register(UPGRADE)