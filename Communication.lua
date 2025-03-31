local addonName, RaidSurvey = ...

RaidSurvey.Communication = {}
local Communication = RaidSurvey.Communication

function Communication:Initialize()
    -- Used to communicate between multiple users
    C_ChatInfo.RegisterAddonMessagePrefix(RaidSurvey.Utils.PREFIX)

    local frame = CreateFrame("Frame")
    frame:RegisterEvent("CHAT_MSG_ADDON")
    frame:RegisterEvent("GROUP_ROSTER_UPDATE")

    frame:SetScript(
        "OnEvent",
        function(_, event, ...)
            if event == "CHAT_MSG_ADDON" then
                self:OnAddonMessage(...)
            end
        end
    )
end

-- Message being COMMAND:DATA
function Communication:OnAddonMessage(prefix, message, sender)
    -- Early return when getting other addon messages
    if prefix ~= RaidSurvey.Utils.PREFIX then
        return
    end
    local command, data = strsplit(":", message)
    if command == RaidSurvey.Utils.COMMANDS.SHOW then
        local surveyData = self:DeserializeSurvey(data)
        RaidSurvey.UI:ShowSurvey(surveyData, sender)
    elseif command == RaidSurvey.Utils.COMMANDS.SUBMIT then
        if RaidSurvey.activeSurvey and RaidSurvey.activeSurvey.creator then
            RaidSurvey.Utils:ProcessSurveyResponse(data, sender)
        end
    elseif command == RaidSurvey.Utils.COMMANDS.RESULTS then
        local resultsData = RaidSurvey.Utils:DeserializeResults(data)
        RaidSurvey.UI:ShowResults(resultsData)
    end
end

function Communication:SendSurvey(surveyData)
    if not RaidSurvey.Utils:HasPermission() then
        print("|cFFFF0000Erreur:|r Vous devez être dans un groupe ou raid pour envoyer un sondage.")
        return false
    end

    surveyData.creator = UnitName("player")
    -- Using timestamp as id, not clean but it works
    surveyData.id = time()
    surveyData.responses = {}
 
    local serializedData = self:SerializeSurvey(surveyData)
    local message = RaidSurvey.Utils.COMMANDS.SHOW .. ":" .. serializedData
    C_ChatInfo.SendAddonMessage(RaidSurvey.Utils.PREFIX, message, IsInRaid() and "RAID" or "PARTY")

    RaidSurvey.activeSurvey = surveyData
    table.insert(RaidSurvey.surveys, surveyData)
    return true
end

function Communication:SerializeSurvey(surveyData)
    -- Format : id,creator,question,labels,numOptions
    return surveyData.id .. "," .. surveyData.creator .. "," .. surveyData.labels .. "," .. surveyData.question .. "," .. surveyData.numOptions

end

function Communication:DeserializeSurvey(data)
    local id, creator, question, labels ,numOptions = strsplit(",", data, 5)

    return {
        id = tonumber(id),
        creator = creator,
        question = question,
        numOptions = tonumber(numOptions),
        labels = labels
        -- responses = {}
    }
end
