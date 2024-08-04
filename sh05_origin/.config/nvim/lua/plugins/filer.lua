require('neo-tree').setup {
    filesystem = {
        filtered_items = {
            visible = true,  -- Show hidden files
            hide_dotfiles = false,  -- Do not hide dotfiles
            hide_gitignored = true,  -- Optionally hide gitignored files
        },
    },
}