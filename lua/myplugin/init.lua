local myplugin = {}

local checkbox_pattern = "%- %[%s*%]%s+(.*)"
local todo_bin = "/home/marc/Code/mrcrgl/todo/target/debug/todo"

function myplugin.create_and_link_todo()
  -- Is it a checkbox?
  local line = vim.api.nvim_get_current_line()
  local todo_title = line:match(checkbox_pattern)
  if todo_title then
    local _, new_todo_link = myplugin.create_todo_file(todo_title)

    if new_todo_link then
      vim.api.nvim_set_current_line("- [ ] [" .. todo_title .. "](" .. new_todo_link .. ")")
    end
    return
  end

  -- It is marked?
  -- Get the current buffer number
  local buf = vim.api.nvim_get_current_buf()

  -- Get the range of the visual selection
  local start_line, start_col = unpack(vim.fn.getpos("'<"), 2, 3)
  local end_line, end_col = unpack(vim.fn.getpos("'>"), 2, 3)

  if start_line ~= end_line and start_col ~= end_col then
    -- Get the selected text
    local lines = vim.api.nvim_buf_get_lines(buf, start_line - 1, end_line, false)
    if #lines == 0 then return end

    -- Extract the text
    local selected_text = lines[1]:sub(start_col, end_col)

    -- Replace the selected text with a Markdown link (use a placeholder link)
    local markdown_link = "[" .. selected_text .. "](your-link-here)"
    vim.api.nvim_buf_set_text(buf, start_line - 1, start_col - 1, end_line - 1, end_col, { markdown_link })
    return
  end


  -- Create new file and open buffer
  vim.ui.input({ prompt = "New Todo Title: " }, function(input)
    local new_todo_link, _ = myplugin.create_todo_file(input)
    local filename = vim.fn.getcwd() .. "/" .. vim.fn.trim(new_todo_link)

    if vim.fn.filereadable(filename) == 1 then
      vim.api.nvim_command('edit ' .. vim.fn.fnameescape(filename))
      -- clear the status bar
      vim.api.nvim_echo({}, false, {})
    else
      print("Error: failed to open file " .. filename)
    end
  end)
end


function myplugin.create_todo_file(todo_title)
  local command = todo_bin .. " --data-dir " .. vim.fn.getcwd() .. " new --title \"" .. todo_title .. "\""
  -- Call the external binary with the todo title
  local result = vim.fn.system(command)
  -- Process result, extract filename or link
  local new_todo_link, new_link_filename = string.match(result, "^(%S+)%s(%S+)\n$")
  if new_todo_link and new_link_filename then
    return new_todo_link, new_link_filename
  else
    print("Error: Could not create todo")
  end
end

-- Function to open a split window with context
function myplugin.show_context(bufnr)
  -- Call the external binary to get context for the current file
  local current_file = vim.api.nvim_buf_get_name(bufnr)
  local context_output = vim.fn.system("/home/marc/Documents/Todo/fetch-context.sh " .. vim.fn.shellescape(current_file))

  -- Open a vertical split and set it to display context
  local buf = vim.api.nvim_create_buf(false, true) -- Create a new buffer
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(context_output, "\n"))

  vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')

  -- Open the new buffer in a vertical split window
  vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = math.floor(vim.o.columns / 3),
    height = math.floor(vim.o.lines / 2),
    col = vim.o.columns - math.floor(vim.o.columns / 3),
    row = math.floor(vim.o.lines / 4),
    style = 'minimal',
    border = 'rounded'
  })
end

-- Extract front matter and load buffer content
function myplugin.on_buf_read()
  -- Get the current buffer number and file path
  local buf = vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(buf)

  -- Read the entire file content
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local content = table.concat(lines, "\n")

  -- Extract the front matter using a pattern (assuming TOML format)
  local front_matter_pattern = "^%+%+%+\n(.-)\n%+%+%+\n(.*)$"
  local front_matter, main_content = content:match(front_matter_pattern)
  if front_matter then
    -- Store the front matter in a buffer variable
    vim.api.nvim_buf_set_var(buf, 'front_matter', front_matter)

    -- Replace the buffer content with just the main content
    local main_lines = vim.split(main_content, "\n")
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, main_lines)
    vim.api.nvim_buf_set_option(buf, 'modified', false)
  end

  myplugin.show_frontmatter(buf)
  myplugin.show_context(buf)
end

-- Foo
function myplugin.show_frontmatter(bufnr)
  -- get front_matter
  local front_matter = vim.api.nvim_buf_get_var(bufnr, 'front_matter')

  -- Open a vertical split and set it to display context
  local buf = vim.api.nvim_create_buf(false, true) -- Create a new buffer
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(front_matter, "\n"))


  vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')

  -- Open the new buffer in a vertical split window
  vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = math.floor(vim.o.columns / 3),
    height = math.floor(vim.o.lines / 4),
    col = vim.o.columns - math.floor(vim.o.columns / 3),
    row = 0,
    style = 'minimal',
    border = 'rounded'
  })
end

-- Insert front matter back into buffer before saving
function myplugin.on_buf_write()
  -- Get the current buffer
  local buf = vim.api.nvim_get_current_buf()

  -- Check if the buffer has stored front matter
  local status, front_matter = pcall(vim.api.nvim_buf_get_var, buf, 'front_matter')
  if status and front_matter then
    -- Get the current buffer content
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local main_content = table.concat(lines, "\n")

    -- Combine the front matter and main content
    local combined_content = "+++\n" .. front_matter .. "\n+++\n" .. main_content
    local combined_lines = vim.split(combined_content, "\n")

    -- Replace the buffer content with the combined content
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, combined_lines)
  end
end

-- Autocommand to trigger the todo creation
--vim.api.nvim_create_autocmd("BufWritePost", {
--  pattern = "*.todo.md",
--  callback = myplugin.create_todo,
--})


function myplugin.setup()
  -- BufNewFile new file
  --
  vim.api.nvim_create_autocmd('BufReadPost', {
    pattern = '*.todo.md',
    callback = myplugin.on_buf_read,
  })

  vim.api.nvim_create_autocmd('BufWritePre', {
    pattern = '*.todo.md',
    callback = myplugin.on_buf_write,
  })

  vim.api.nvim_create_autocmd('BufWritePost', {
    pattern = '*.todo.md',
    callback = myplugin.on_buf_read,
  })

  vim.api.nvim_create_user_command('TodoCreate', function()
    myplugin.create_and_link_todo()
  end, {})

  vim.api.nvim_set_keymap('n', '<leader>tn', ':TodoCreate<CR>', { noremap = true, silent = true })
  vim.api.nvim_set_keymap('v', '<leader>tn', ':TodoCreate<CR>', { noremap = true, silent = true })
end

return myplugin
