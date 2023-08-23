SWEP.Base = "weapon_cup_bow"
SWEP.PrintName = "Love Prevails"
SWEP.PAPDesc = "Lovers aren't soul-linked, you win if even 1 lover survives!"

if SERVER then
    util.AddNetworkString("TTTPAPCupidBow")
end

function SWEP:Initialize()
    if CLIENT then return end

    hook.Add("TTTCupidShouldLoverSurvive", "TTTPAPCupidBow", function(ply, lover)
        local cupid = player.GetBySteamID64(ply:GetNWString("TTTCupidShooter"))
        if not IsValid(cupid) then return end
        local PAPBow = cupid:GetWeapon("weapon_cup_bow_pap")

        -- If the lover's cupid has a Pack-a-Punched bow, let them live!
        if not IsValid(PAPBow) then
            return
        else
            return true
        end
    end)

    hook.Add("TTTCheckForWin", "TTTPAPCupidWinOverride", function()
        local cupidWin = true
        local loverAlive = false

        for _, v in pairs(player.GetAll()) do
            if not v:Alive() or v:IsSpec() then continue end
            local lover = v:GetNWString("TTTCupidLover", "")

            if lover ~= "" then
                -- This is the part that checks if a lover has died, we want to skip that!
                -- 
                -- local loverPly = player.GetBySteamID64(lover)
                -- if not IsPlayer(loverPly) or not loverPly:IsActive() then
                --     cupidWin = false
                --     break
                -- end
                loverAlive = true
            elseif not v:IsCupid() and not v:ShouldActLikeJester() and not ROLE_HAS_PASSIVE_WIN[v:GetRole()] then
                cupidWin = false
                break
            end
        end

        if cupidWin and loverAlive then return WIN_CUPID end
    end)

    net.Start("TTTPAPCupidBow")
    net.Broadcast()

    hook.Add("TTTPrepareRound", "TTTPAPCupidBowReset", function()
        hook.Remove("TTTCupidShouldLoverSurvive", "TTTPAPCupidBow")
        hook.Remove("TTTCheckForWin", "TTTPAPCupidWinOverride")
        hook.Remove("TTTPrepareRound", "TTTPAPCupidBowReset")
    end)
end

if CLIENT then
    net.Receive("TTTPAPCupidBow", function()
        hook.Add("TTTScoringSecondaryWins", "TTTPAPCupidBowWin", function(wintype, secondaryWins)
            if wintype == WIN_CUPID then return end

            for _, p in ipairs(player.GetAll()) do
                local lover = p:GetNWString("TTTCupidLover", "")

                if p:Alive() and not p:IsSpec() and lover ~= "" then
                    local loverPly = player.GetBySteamID64(lover)

                    -- Flipping the check for if a lover has died so we only add the secondary "and the Lovers win" if one lover HAS died...
                    -- (Else 2 "and the Lovers win" rows are shown...)
                    if not (IsPlayer(loverPly) and loverPly:Alive() and not loverPly:IsSpec()) then
                        table.insert(secondaryWins, {
                            rol = ROLE_CUPID,
                            txt = LANG.GetTranslation("hilite_lovers_secondary"),
                            col = ROLE_COLORS[ROLE_CUPID]
                        })
                    end

                    return
                end
            end
        end)
    end)
end