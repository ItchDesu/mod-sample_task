-- Simple WebRTC voice chat example for Luanti

local http = minetest.request_http_api()
local signaling_url = minetest.settings:get("voicechat_signaling_url") or "http://localhost:8080"

local function show_link(player, link)
    local name = player:get_player_name()
    minetest.chat_send_player(name, "[voicechat] Open this link in a browser to join: " .. link)
end

local function start_voice_chat(player)
    if not http then
        minetest.chat_send_player(player:get_player_name(), "[voicechat] HTTP API not available")
        return
    end

    local name = player:get_player_name()
    http.fetch({
        url = signaling_url .. "/session?name=" .. minetest.urlencode_component(name),
        method = "GET"
    }, function(result)
        if result.succeeded then
            local data = minetest.parse_json(result.data)
            if data and data.url then
                show_link(player, data.url)
            else
                minetest.chat_send_player(name, "[voicechat] Invalid response from signaling server")
            end
        else
            minetest.chat_send_player(name, "[voicechat] Failed to contact signaling server")
        end
    end)
end

minetest.register_on_joinplayer(function(player)
    minetest.chat_send_player(player:get_player_name(), "Use /voice to start a WebRTC call.")
end)

minetest.register_chatcommand("voice", {
    description = "Start a WebRTC voice chat session",
    privs = {},
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if player then
            start_voice_chat(player)
        end
    end
})

