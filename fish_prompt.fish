# Initialize glyphs to be used in the prompt.
set -q chain_prompt_glyph
  or set -g chain_prompt_glyph ">"
set -q chain_git_branch_glyph
  or set -g chain_git_branch_glyph "⎇"
set -q chain_git_dirty_glyph
  or set -g chain_git_dirty_glyph "*"
set -q chain_git_staged_glyph
  or set -g chain_git_staged_glyph "~"
set -q chain_git_stashed_glyph
  or set -g chain_git_stashed_glyph '$'
set -q chain_git_behind_glyph
  or set -g chain_git_behind_glyph '↓'
set -q chain_git_ahead_glyph
  or set -g chain_git_ahead_glyph '↑'
set -q chain_git_behind_and_ahead_glyph
  or set -g chain_git_behind_and_ahead_glyph '↕'
set -q chain_git_new_glyph
  or set -g chain_git_new_glyph "…"
set -q chain_su_glyph
  or set -g chain_su_glyph "⚡"

function __chain_prompt_segment
  set_color $argv[1]
  echo -n -s "[" $argv[2..-1] "]─"
  set_color normal
end

function __chain_git_branch_name
  echo (command git symbolic-ref HEAD ^/dev/null | sed -e 's|^refs/heads/||')
end

function __chain_is_git_dirty
  not command git diff --no-ext-diff --quiet --exit-code
end

function __chain_is_git_staged
  not command git diff --cached --no-ext-diff --quiet --exit-code
end

function __chain_is_git_stashed
  command git rev-parse --verify --quiet refs/stash >/dev/null
end

function __chain_is_git_behind
  for line in (command git rev-list --left-right '@{upstream}...HEAD' ^/dev/null)
    switch "$line"
      case '<*'
        return 0
    end
  end
  return 1
end

function __chain_is_git_ahead
  for line in (command git rev-list --left-right '@{upstream}...HEAD' ^/dev/null)
    switch "$line"
      case '>*'
        return 0
    end
  end
  return 1
end

function __chain_is_git_new
  test (echo (command git ls-files --other --exclude-standard --directory --no-empty-directory))
end

function __chain_prompt_root
  set -l uid (id -u $USER)
  if test $uid -eq 0
    __chain_prompt_segment yellow $chain_su_glyph
  end
end

function __chain_prompt_dir
  __chain_prompt_segment cyan (prompt_pwd)
end

function __chain_prompt_git
  if test (__chain_git_branch_name)
    set -l git_branch (__chain_git_branch_name)
    __chain_prompt_segment blue "$chain_git_branch_glyph $git_branch"

    __chain_is_git_behind; and set -l is_git_behind 1
    __chain_is_git_ahead; and set -l is_git_ahead 1

    set -l glyphs ''
    __chain_is_git_dirty; and set -l is_git_dirty 1; and set glyphs "$glyphs$chain_git_dirty_glyph"
    __chain_is_git_staged; and set -l is_git_staged 1; and set glyphs "$glyphs$chain_git_staged_glyph"
    __chain_is_git_stashed; and set -l is_git_stashed 1; and set glyphs "$glyphs$chain_git_stashed_glyph"
    if test "$is_git_behind" -a "$is_git_ahead"
      set glyphs "$glyphs$chain_git_behind_and_ahead_glyph"
    else if test "$is_git_behind"
      set glyphs "$glyphs$chain_git_behind_glyph"
    else if test "$is_git_ahead"
      set glyphs "$glyphs$chain_git_ahead_glyph"
    end
    __chain_is_git_new; and set -l is_git_new 1; and set glyphs "$glyphs$chain_git_new_glyph"

    set -l color green
    if test "$is_git_dirty" -o "$is_git_staged"
      set color red
    else if test "$is_git_stashed" -o "$is_git_behind" -o "$is_git_ahead"
      set color yellow
    end

    if test -n "$glyphs"
      __chain_prompt_segment $color $glyphs
    end
  end
end

function __chain_prompt_arrow
  if test $last_status = 0
    set_color green
  else
    set_color red
    echo -n "($last_status)-"
  end

  echo -n "$chain_prompt_glyph "
end

function fish_prompt
  set -g last_status $status

  __chain_prompt_root
  __chain_prompt_dir
  type -q git; and __chain_prompt_git
  __chain_prompt_arrow

  set_color normal
end
