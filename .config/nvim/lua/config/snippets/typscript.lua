local luasnip = require("luasnip")
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta

local s = luasnip.snippet
local t = luasnip.text_node
local i = luasnip.insert_node
local c = luasnip.choice_node

local func = s(
  { trig = "f", dscr = "function" },
  fmt(
    "{}",
    c(1, {
      fmta(
        "function <name>(<args>): <returns> { <body> }",
        { name = i(1, "name"), args = i(2, "args"), returns = i(3, "returns"), body = i(4) }
      ),
      fmta(
        "async function <name>(<args>): Promise<<<returns>>> { <body> }",
        { name = i(1, "name"), args = i(2, "args"), returns = i(3, "returns"), body = i(4) }
      ),
      fmta(
        "export function <name>(<args>): <returns> { <body> }",
        { name = i(1, "name"), args = i(2, "args"), returns = i(3, "returns"), body = i(4) }
      ),
      fmta(
        "export async function <name>(<args>): Promise<<<returns>>> { <body> }",
        { name = i(1, "name"), args = i(2, "args"), returns = i(3, "returns"), body = i(4) }
      ),
    })
  )
)

local lambda = s(
  { trig = "l", dscr = "lambda function" },
  fmt(
    "{}",
    c(1, {
      t("() => "),
      t("(i) => i"),
      t("async () => "),
      t("async (i) => i"),
    })
  )
)

local class = s(
  { trig = "c", dscr = "class" },
  fmt(
    "{}",
    c(1, {
      fmta(
        [[
export class <name> {
  <body>
};
]],
        { name = i(1, "name"), body = i(2) }
      ),
      fmta(
        [[
export class <name> {
  constructor(
    private readonly <prop>;
  ) {}

  <body>
};
]],
        { name = i(1, "name"), prop = i(2, "prop"), body = i(3) }
      ),
    })
  )
)

local constructor = s(

  { trig = "con", dscr = "constructor" },
  t(
    [[
constructor(
  private readonly {};
) {}
]],
    i(1, "prop")
  )
)

-- local fn = s(
--   { trig = "fn", dscr = "function", snippetType = "autosnippet" },
--   fmta(
--     [[
-- function <name>(<args>): <return_type> {
--   <body>
-- }
-- ]],
--     {
--       name = i(1, "name"),
--       args = c(2, {
--         t(""),
--         fmta("<arg>:<type>", {
--           arg = i(1, "arg"),
--           type = i(2, "type"),
--         }),
--         fmta("<arg1>:<type1>, <arg2>:<type2>", {
--           arg1 = i(1, "arg1"),
--           type1 = i(2, "type1"),
--           arg2 = i(3, "arg2"),
--           type2 = i(4, "type2"),
--         }),
--         fmta("<arg1>:<type1>, <arg2>:<type2>, <arg3>:<type3>", {
--           arg1 = i(1, "arg1"),
--           type1 = i(2, "type1"),
--           arg2 = i(3, "arg2"),
--           type2 = i(4, "type2"),
--           arg3 = i(5, "arg3"),
--           type3 = i(6, "type3"),
--         }),
--       }),
--       return_type = i(3, "return_type"),
--       body = i(4),
--     }
--   )
-- )
--
-- local afn = s(
--   { trig = "afn", dscr = "async function", snippetType = "autosnippet" },
--   fmta(
--     [[
-- async function <name>(<args>): <return_type> {
--   <body>
-- }
-- ]],
--     {
--       name = i(1, "name"),
--       args = c(2, {
--         t(""),
--         fmta("<arg>:<type>", {
--           arg = i(1, "arg"),
--           type = i(2, "type"),
--         }),
--         fmta("<arg1>:<type1>, <arg2>:<type2>", {
--           arg1 = i(1, "arg1"),
--           type1 = i(2, "type1"),
--           arg2 = i(3, "arg2"),
--           type2 = i(4, "type2"),
--         }),
--         fmta("<arg1>:<type1>, <arg2>:<type2>, <arg3>:<type3>", {
--           arg1 = i(1, "arg1"),
--           type1 = i(2, "type1"),
--           arg2 = i(3, "arg2"),
--           type2 = i(4, "type2"),
--           arg3 = i(5, "arg3"),
--           type3 = i(6, "type3"),
--         }),
--       }),
--       return_type = c(3, {
--         fmt("Promise<{}>", i(1)),
--         t("Promise<void>"),
--       }),
--       body = i(4),
--     }
--   )
-- )
--
-- local lfn = s(
--   { trig = "lfn", dscr = "lambda function", snippetType = "autosnippet" },
--   fmta(
--     [[
-- (<args>)<return_type> =>> <body>
-- ]],
--     {
--       args = c(1, {
--         t(""),
--         fmta("<arg>:<type>", {
--           arg = i(1, "arg"),
--           type = i(2, "type"),
--         }),
--         fmta("<arg1>:<type1>, <arg2>:<type2>", {
--           arg1 = i(1, "arg1"),
--           type1 = i(2, "type1"),
--           arg2 = i(3, "arg2"),
--           type2 = i(4, "type2"),
--         }),
--         fmta("<arg1>:<type1>, <arg2>:<type2>, <arg3>:<type3>", {
--           arg1 = i(1, "arg1"),
--           type1 = i(2, "type1"),
--           arg2 = i(3, "arg2"),
--           type2 = i(4, "type2"),
--           arg3 = i(5, "arg3"),
--           type3 = i(6, "type3"),
--         }),
--       }),
--       return_type = c(2, {
--         t(""),
--         fmt(": {}", i(1, "<return_type>")),
--       }),
--       body = c(3, {
--         fmt("{}", i(1, "<body>")),
--         fmta("{ <body> }", { body = i(1, "<body>") }),
--       }),
--     }
--   )
-- )
--
-- local alfn = s(
--   { trig = "alfn", dscr = "async lambda function", snippetType = "autosnippet" },
--   fmta(
--     [[
-- async (<args>)<return_type> =>> <body>
-- ]],
--     {
--       args = c(1, {
--         t(""),
--         fmta("<arg>:<type>", {
--           arg = i(1, "arg"),
--           type = i(2, "type"),
--         }),
--         fmta("<arg1>:<type1>, <arg2>:<type2>", {
--           arg1 = i(1, "arg1"),
--           type1 = i(2, "type1"),
--           arg2 = i(3, "arg2"),
--           type2 = i(4, "type2"),
--         }),
--         fmta("<arg1>:<type1>, <arg2>:<type2>, <arg3>:<type3>", {
--           arg1 = i(1, "arg1"),
--           type1 = i(2, "type1"),
--           arg2 = i(3, "arg2"),
--           type2 = i(4, "type2"),
--           arg3 = i(5, "arg3"),
--           type3 = i(6, "type3"),
--         }),
--       }),
--       return_type = c(2, {
--         t(""),
--         fmt(": Promise<{}>", i(1, "<return_type>")),
--       }),
--       body = c(3, {
--         fmt("{}", i(1, "<body>")),
--         fmta("{ <body> }", { body = i(1, "<body>") }),
--       }),
--     }
--   )
-- )

luasnip.add_snippets("typescript", { func, lambda, class })
