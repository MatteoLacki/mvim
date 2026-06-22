return {
  {
    "milanglacier/minuet-ai.nvim",
    enabled = vim.env.OPENAI_API_KEY ~= nil and vim.env.OPENAI_API_KEY ~= "",
    event = "InsertEnter",
    opts = {
      provider = "openai",
      provider_options = {
        openai = {
          model = "gpt-5.4-mini",
        },
      },
    },
  },
}
