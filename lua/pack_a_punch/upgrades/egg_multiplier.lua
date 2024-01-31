local UPGRADE = {}
UPGRADE.id = "egg_multiplier"
UPGRADE.class = "weapon_ttt_chickenator"
UPGRADE.name = "Egg Multiplier"
UPGRADE.desc = "Spawned chickens lay more eggs!"
UPGRADE.Timers = {}

function UPGRADE:Apply(SWEP)
    SWEP.PAPOldPrimaryAttack = SWEP.PrimaryAttack

    function SWEP:PrimaryAttack()
        self:PAPOldPrimaryAttack()
        local owner = self:GetOwner()
        if CLIENT or not IsValid(owner) then return end
        local timername = "TTTPAPEggMultiplier" .. owner:SteamID64()
        table.insert(UPGRADE.Timers, timername)

        timer.Create(timername, 15, 0, function()
            if #ents.FindByClass("ttt_chickent") > 40 then return end

            for _, chicken in ipairs(ents.FindByClass("ttt_chickent")) do
                local egg = ents.Create("sent_eggt")
                egg:SetPos(chicken:GetPos())
                egg:Spawn()
                egg:Activate()
            end
        end)
    end
end

function UPGRADE:Reset()
    for _, timername in ipairs(self.Timers) do
        timer.Remove(timername)
    end
end

TTTPAP:Register(UPGRADE)