return {
  {
    "zbirenbaum/copilot.lua",
    opts = {
      filetypes = {
        gitcommit = true,
        yaml = true,
        markdown = true,
      },
    },
  },
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      { "zbirenbaum/copilot.lua" },
      { "nvim-lua/plenary.nvim", branch = "master" }, -- for curl, log and async functions
    },
    opts = {
      model = "o3-mini",
      -- default prompts
      -- see config/prompts.lua for implementation
      prompts = {
        Explain = {
          prompt = "選択したコードの説明を段落として書いてください。",
          system_prompt = "COPILOT_EXPLAIN",
        },
        Review = {
          prompt = "選択したコードをレビューしてください。",
          system_prompt = "COPILOT_REVIEW",
        },
        Fix = {
          prompt = "このコードには問題があります。問題を特定し、修正を加えてコードを書き直してください。何が問題だったのか、そしてあなたの変更がどのように問題を解決するかを説明してください。",
        },
        Optimize = {
          prompt = "選択したコードを最適化して、パフォーマンスと可読性を向上させてください。最適化戦略と変更の利点を説明してください。",
        },
        Docs = {
          prompt = "選択したコードにドキュメントコメントを追加してください。",
        },
        Tests = {
          prompt = "コードのテストを生成してください。",
        },
        Commit = {
          prompt = "コミットメッセージをコミットゼンの規約に従って書いてください。タイトルは50文字以内にし、メッセージは72文字で折り返してください。gitcommitコードブロックとしてフォーマットしてください。",
          context = "git:staged",
        },
      },
    },
  },
}
