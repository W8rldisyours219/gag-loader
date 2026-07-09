local K = "https://keys.w8rldisyours.com"
assert(type(loadstring) == "function", "[W8rldisyours219] loadstring is not available in this executor")
local function H()
	local o, i = pcall(function() if gethwid then return tostring(gethwid()) end return tostring(game:GetService("RbxAnalyticsService"):GetClientId()) end)
	return (o and i and tostring(i) ~= "") and i or "unknown-hwid"
end
local function Q(v)
	return tostring(v or ""):gsub("([^%w%-_%.~])", function(c) return string.format("%%%02X", string.byte(c)) end)
end
local function W(k)
	local hw = H()
	local oe, p = pcall(function() return game:GetService("HttpService"):JSONEncode({ key = k, hwid = hw }) end)
	assert(oe, "[W8rldisyours219] Failed to build the license request")
	local rb, le = nil, "no reachable key server"
	local rf = (syn and syn.request) or (http and http.request) or http_request or request or (fluxus and fluxus.request)
	if rf then
		local o, rs = pcall(function() return rf({ Url = K .. "/script/fetch", Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = p }) end)
		if o and type(rs) == "table" then
			local sc = tonumber(rs.StatusCode or rs.Status or rs.statusCode) or 0
			if sc >= 200 and sc < 300 then
				rb = rs.Body or rs.body
			else
				local dok, dc = pcall(function() return game:GetService("HttpService"):JSONDecode(rs.Body or rs.body or "") end)
				le = (dok and dc and dc.error) or ("HTTP " .. tostring(sc))
			end
		end
	end
	if not rb then
		local u = K .. "/script/fetch?payload=" .. Q(p)
		local o, tx = pcall(function() return game:HttpGet(u) end)
		if o and type(tx) == "string" and tx ~= "" then
			local lk = tx:sub(1, 1) == "{"
			if lk then
				local dok, dc = pcall(function() return game:GetService("HttpService"):JSONDecode(tx) end)
				le = (dok and dc and dc.error) or "invalid response"
			else
				rb = tx
			end
		end
	end
	return rb, le
end
local function F()
	-- The ONLY accepted way to supply a key is getgenv().key (the legacy
	-- W8rldisyours219Key alias still works). No in-game prompt UI, no cached
	-- key file — if it isn't set, the loader stops with a clear message.
	local e = (getgenv and getgenv()) or _G
	local k = tostring(e["key"] or e["W8rldisyours219Key"] or ""):gsub("^%s+", ""):gsub("%s+$", "")
	assert(k ~= "", "[W8rldisyours219] No key set. Run:  getgenv().key = \"YOUR-KEY\"  before this loader.")
	e["key"] = k
	local rb, le = W(k)
	assert(rb, "[W8rldisyours219] License check failed: " .. tostring(le))
	return rb
end
local ok, source = pcall(F)
assert(ok, tostring(source))
assert(type(source) == "string" and source ~= "", "[W8rldisyours219] Empty script source received")
local chunk, compileError = loadstring(source)
assert(chunk, "[W8rldisyours219] compile failed: " .. tostring(compileError))
return chunk()
