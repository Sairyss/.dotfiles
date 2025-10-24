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
        [[
        function <name>(<args>): <returns> {
          <body>
        }
        ]],
        { name = i(1, "name"), args = i(2, "args"), returns = i(3, "returns"), body = i(4) }
      ),
      fmta(
        [[
        async function <name>(<args>): Promise<<<returns>>> {
          <body>
        }
        ]],
        { name = i(1, "name"), args = i(2, "args"), returns = i(3, "returns"), body = i(4) }
      ),
      fmta(
        [[
        export function <name>(<args>): <returns> {
          <body>
        }]],
        { name = i(1, "name"), args = i(2, "args"), returns = i(3, "returns"), body = i(4) }
      ),
      fmta(
        [[
        export async function <name>(<args>): Promise<<<returns>>> {
          <body>
        }
        ]],
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

luasnip.add_snippets("typescript", { func, lambda, class })
