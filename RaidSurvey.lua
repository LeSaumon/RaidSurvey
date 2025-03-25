local addonName, RaidSurvey = ...
RaidSurvey.version = "1.0"
-- TODO : 
--      - Réparer l'affichage des réponses dans le résultat du sondage
--      - Tester la reception des message et l'affichage côté membres du raid

function RaidSurvey:Initialize()
    self.Communication:Initialize()

    self.surveys = {}
    self.activeSurvey = nil
    self.responses = {}
    self:SetupSlashCommands()

    print("|cFF00FF00RaidSurvey loaded|r")
end

function RaidSurvey:SetupSlashCommands()
    SLASH_RSURVEY1 = "/rs"
    SlashCmdList["RSURVEY"] = function(msg)
        if not msg or msg == "" or msg == "help" then
            print("|cFF00FF00RaidSurvey|r - Avaimable commands:")
            print("|cFFFFFFFF/rs start|r - Open Survey Form.")
            print("|cFFFFFFFF/rsurvey end|r - End current survey and show results.")
            print("|cFFFFFFFF/rsurvey help|r - Print help.")
        elseif msg == "end" then
            if self.activeSurvey and self.Utils:HasPermission() then
                self.Utils:DistributeResults(self.activeSurvey)
                print("Survey is over, results are on their way.")
            else
                print("|cFFFF0000Error:|r No actives survey or you don't have permission.")
            end
        elseif msg == "start" then
            if self.Utils:HasPermission() then
                self.UI:Initialize()
                self.UI.surveyFrame:Show()
                self.UI:UpdatePermissionStatus()
            else
                print("|cFFFF0000Erreur:|r Only assists or raid leaders can create surveys.")
            end
        end
    end
end

function RaidSurvey:OnLoad()
    self:Initialize()
end

RaidSurvey:OnLoad()
