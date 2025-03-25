local addonName, RaidSurvey = ...

RaidSurvey.Utils = {}
local Utils = RaidSurvey.Utils

Utils.PREFIX = "RaidSurvey"
Utils.COMMANDS = {
    SHOW = "SHOW",
    SUBMIT = "SUBMIT",
    RESULTS = "RESULTS"
}
Utils.PLAYER_RANKS = {
    MEMBER = 0,
    ASSISTANT = 1,
    LEADER = 2
}

function Utils:HasPermission()
    if IsInRaid() then
        local rank =
            UnitIsGroupLeader("player") and Utils.PLAYER_RANKS.LEADER or
            UnitIsGroupAssistant("player") and Utils.PLAYER_RANKS.ASSISTANT or
            Utils.PLAYER_RANKS.MEMBER
        return rank > 0
    elseif IsInGroup() then
        return UnitIsGroupLeader("player")
    else
        -- TODO: Remove when pushing to production, this is used to debug
        return true
    end
end

function Utils:CountTableEntries(table)
    local count = 0
    for _ in pairs(table) do
        count = count + 1
    end
    return count
end

function Utils:SubmitResponse(surveyId, selectedOption)
    if not surveyId or not selectedOption then
        return false
    end
    local message = Utils.COMMANDS.SUBMIT .. ":" .. surveyId .. ":" .. selectedOption
    C_ChatInfo.SendAddonMessage(Utils.PREFIX, message, IsInRaid() and "RAID" or "PARTY")
    return true
end

function Utils:ProcessSurveyResponse(data, sender)
    local surveyId, option = strsplit(",", data)
    surveyId = tonumber(surveyId)
    option = tonumber(option)

    if not surveyId or not option then
        return
    end

    for _, survey in ipairs(self.surveys) do
        if survey.id == surveyId then
            survey.responses[sender] = option
            local totalMembers = GetNumGroupMembers()
            local responsesCount = self:CountTableEntries(survey.responses)

            if responsesCount >= totalMembers then
                self:DistributeResults(survey)
            end
        end
    end
end

function Utils:DistributeResults(survey)
    local results = {}

    for i = 1, survey.numOptions do
        results[i] = 0
    end

    for _, option in pairs(survey.responses) do
        results[option] = results[option] + 1
    end
    local serializedResults = self:SerializeResults(survey.id, survey.question, results)
    local message = Utils.COMMANDS.RESULTS .. ":" .. serializedResults
    C_ChatInfo.SendAddonMessage(Utils.PREFIX, message, IsInRaid() and "RAID" or "PARTY")
    -- Also show results for the leader

    RaidSurvey.UI:ShowResults(
        {
            id = survey.id,
            question = survey.question,
            results = results,
            totalVotes = self:CountTableEntries(survey.responses)
        }
    )
end

function Utils:DeserializeResults(data)
    print(data)
    local parts = {strsplit(",", data)}
    local id = tonumber(parts[1])
    local question = parts[2]
    local results = {}
    local totalVotes = 0

    for i = 3, #parts do
        local count = tonumber(parts[i])
        results[i - 2] = count
        totalVotes = totalVotes + count
    end

    return {
        id = id,
        question = question,
        results = results,
        totalVotes = totalVotes
    }
end

function Utils:SerializeResults(id, question, results)
    local resultStr = id .. "," .. question
    for i, count in ipairs(results) do
        resultStr = resultStr .. "," .. count
    end
    return resultStr
end
