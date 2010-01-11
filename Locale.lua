
local myname, ns = ...

ns.L = setmetatable(GetLocale() == "deDE" and {
	["(.*) won: (.+)"]                               = "(.*) gewinnt: (.+)",
	["%s|Hgreedbeacon:%d|h[%s roll]|h|r %s won %s "] = "%s|Hgreedbeacon:%d|h[%s roll]|h|r %s gewinnt: %s",
	["(.*) has?v?e? selected (.+) for: (.+)"]        = "(.+) hab?t für (.+) '(.+)' ausgewählt",
	["(.+) Roll . (%d+) for (.+) by (.+)"]           = "Wurf für (.*): (%d+) für (.*) von (.*)",
	[" passed on: "]                                 = " würfelt nicht für: ",
	[" automatically passed on: "]                   = " passt automatisch bei ",
	["You passed on: "]                              = "Ihr habt gepasst bei: ",
	["Everyone passed on: "]                         = "Alle haben gepasst bei: ",
	["Greed"]                                        = GREED,
	["Need"]                                         = NEED,
} or GetLocale() == "ruRU" and {
	["(.*) won: (.+)"]                               = "(.*) выигрывает: (.+)",
	["%s|Hgreedbeacon:%d|h[%s roll]|h|r %s won %s "] = "%s|Hgreedbeacon:%d|h[%s roll]|h|r %s выигрывает: %s",
	["(.*) has?v?e? selected (.+) for: (.+)"]        = "Разыгрывается предмет: (.+). (.*) говорит: (.+)",
	["(.+) Roll . (%d+) for (.+) by (.+)"]           = "Результат броска (.*) за предмет (.*): (%d+)",
	[" passed on: "]                                 = " отказывается от предмета: ",
	[" automatically passed on: "]                   = " поскольку не может его забрать.",
	["You passed on: "]                              = "Вы отказались от предмета: ",
	["Everyone passed on: "]                         = ": предмет никому не нужен.",
	["Greed"]                                        = GREED,
	["Need"]                                         = NEED,
} or GetLocale() == "esES" and {
	["(.*) won: (.+)"]                               = "(.*) ha ganado: (.+)",
	["%s|Hgreedbeacon:%d|h[%s roll]|h|r %s won %s "] = "%s|Hgreedbeacon:%d|h[%s roll]|h|r %s ha ganado: %s",
	["(.*) has?v?e? selected (.+) for: (.+)"]        = "(.*) ha seleccionado (.+) para: (.+)",
	["(.+) Roll . (%d+) for (.+) by (.+)"]           = "Tiro por (.+): (%d+) para (.+) por (.+)",
	[" passed on: "]                                 = " ha pasado de: ",
	[" automatically passed on: "]                   = " ha pasado automáticamente de: ",
	["You passed on: "]                              = "Has pasado de: ",
	["Everyone passed on: "]                         = "Todos han pasado de: ",
	["Greed"]                                        = GREED,
	["Need"]                                         = NEED,
} or {}, {__index = function(t,i) return i end})
