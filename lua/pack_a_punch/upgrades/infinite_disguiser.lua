local UPGRADE = {}
UPGRADE.id = "infinite_disguiser"
UPGRADE.class = "weapon_ttt_prop_disguiser"
UPGRADE.name = "Infinite Disguiser"
UPGRADE.desc = "Unlimited disguise! Play a taunt after a delay"

UPGRADE.convars = {
    {
        name = "pap_infinite_disguiser_taunt_delay",
        type = "int"
    }
}

local tauntDelayCvar = CreateConVar("pap_infinite_disguiser_taunt_delay", 15, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds between taunt sounds", 5, 120)

function UPGRADE:Apply(SWEP)
    SWEP.PAPOldPropDisguise = SWEP.PropDisguise

    function SWEP:PropDisguise()
        local oldTime = GetGlobalInt("ttt_prop_disguiser_time")
        SetGlobalInt("ttt_prop_disguiser_time", 99999)
        self:PAPOldPropDisguise()
        SetGlobalInt("ttt_prop_disguiser_time", oldTime)

        if SERVER then
            local owner = self:GetOwner()
            local timername = "TTTPAPInfiniteDisguiser" .. owner:SteamID64()

            local soundNumbers = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}

            table.Shuffle(soundNumbers)
            local soundIndex = 1

            timer.Create(timername, tauntDelayCvar:GetInt(), 0, function()
                if IsValid(owner) and IsValid(self) and owner:GetNWBool("PD_Disguised") then
                    local randomSound = "ttt_pack_a_punch/shouting_credit_printer/quote" .. soundNumbers[soundIndex] .. ".mp3"
                    owner:EmitSound(randomSound)
                    owner:EmitSound(randomSound)
                    soundIndex = soundIndex + 1

                    if soundIndex > 11 then
                        soundIndex = 1
                        table.Shuffle(soundNumbers)
                    end
                else
                    timer.Remove(timername)
                end
            end)
        end
    end
end

TTTPAP:Register(UPGRADE)