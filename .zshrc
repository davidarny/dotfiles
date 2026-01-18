# Cache directory for generated Zsh files
export ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
mkdir -p "$ZSH_CACHE_DIR" 2>/dev/null

# Track startup timing for interactive shells
if [[ -o interactive ]]; then
  zmodload zsh/datetime 2>/dev/null
  ZSH_STARTUP_EPOCH=$EPOCHREALTIME
fi

# Fast startup for interactive -c runs (opt out with ZSH_FAST_STARTUP=0)
if [[ -n "${ZSH_EXECUTION_STRING:-}" && -z "${ZSH_FAST_STARTUP:-}" ]]; then
  export ZSH_FAST_STARTUP=1
fi

# Source configuration modules in order (numbered files first)
for config_file in ~/.config/zsh/*.zsh; do
  # Skip the main zshrc file itself to avoid infinite loop
  [[ "$config_file" != *"/zshrc" ]] && [[ -f "$config_file" ]] && source "$config_file"
done

# Load completion-dependent tools after completion system is set up
if [[ $_OP_COMPLETION_AVAILABLE ]]; then
  op_completion_cache="${ZSH_CACHE_DIR}/op-completion.zsh"
  _zsh_load_op_completion() {
    if [[ -s "$op_completion_cache" ]]; then
      source "$op_completion_cache"
    else
      op completion zsh >| "$op_completion_cache" 2>/dev/null
      [[ -s "$op_completion_cache" ]] && source "$op_completion_cache"
    fi
  }
  if typeset -p _zsh_post_compinit_hooks >/dev/null 2>&1; then
    _zsh_post_compinit_hooks+=("_zsh_load_op_completion")
  else
    _zsh_load_op_completion
  fi
fi

# Pretty startup timing output
if [[ -o interactive && -n "${ZSH_STARTUP_EPOCH:-}" ]]; then
  typeset _zsh_startup_ms _zsh_startup_s _zsh_startup_s_fmt _zsh_startup_ms_fmt
  _zsh_startup_ms=$(( (EPOCHREALTIME - ZSH_STARTUP_EPOCH) * 1000.0 ))
  if (( _zsh_startup_ms >= 1000 )); then
    _zsh_startup_s=$(( _zsh_startup_ms / 1000.0 ))
    _zsh_startup_s_fmt=$(printf "%.1f" "$_zsh_startup_s")
    _zsh_startup_time="${_zsh_startup_s_fmt} s"
  else
    _zsh_startup_ms_fmt=$(printf "%.2f" "$_zsh_startup_ms")
    _zsh_startup_time="${_zsh_startup_ms_fmt}ms"
  fi

  typeset _zsh_pagesize _zsh_free_pages _zsh_inactive_pages
  typeset _zsh_mem_free_bytes _zsh_mem_free_human
  _zsh_pagesize=$(sysctl -n hw.pagesize 2>/dev/null)
  if [[ -n "$_zsh_pagesize" ]]; then
    read -r _zsh_free_pages _zsh_inactive_pages < <(vm_stat 2>/dev/null | awk '
      /Pages free/ {gsub("\\.","",$3); free=$3}
      /Pages inactive/ {gsub("\\.","",$3); inactive=$3}
      END {printf "%s %s", free, inactive}
    ')
    if [[ -n "$_zsh_free_pages" && -n "$_zsh_inactive_pages" ]]; then
      _zsh_mem_free_bytes=$(( (_zsh_free_pages + _zsh_inactive_pages) * _zsh_pagesize ))
      _zsh_mem_free_human=$(printf "%.1fG" $(( _zsh_mem_free_bytes / 1024.0 / 1024.0 / 1024.0 )))
    fi
  fi

  typeset _zsh_cpu_model _zsh_cpu_cores _zsh_cpu_usage
  _zsh_cpu_model=$(sysctl -n machdep.cpu.brand_string 2>/dev/null)
  _zsh_cpu_cores=$(sysctl -n hw.ncpu 2>/dev/null)
  _zsh_cpu_usage=$(ps -A -o %cpu= 2>/dev/null | awk '{s+=$1} END {printf "%.1f%%%%", s}')

  typeset _zsh_boot_sec _zsh_uptime_sec _zsh_uptime
  _zsh_boot_sec=$(sysctl -n kern.boottime 2>/dev/null | awk -F'[=,]' '{print $2}' | tr -d ' ')
  if [[ -n "$_zsh_boot_sec" ]]; then
    _zsh_uptime_sec=$(( EPOCHSECONDS - _zsh_boot_sec ))
    typeset _zsh_uptime_days _zsh_uptime_hours _zsh_uptime_mins
    _zsh_uptime_days=$(( _zsh_uptime_sec / 86400 ))
    _zsh_uptime_hours=$(( (_zsh_uptime_sec % 86400) / 3600 ))
    _zsh_uptime_mins=$(( (_zsh_uptime_sec % 3600) / 60 ))
    if (( _zsh_uptime_days > 0 )); then
      _zsh_uptime="${_zsh_uptime_days}d ${_zsh_uptime_hours}h ${_zsh_uptime_mins}m"
    elif (( _zsh_uptime_hours > 0 )); then
      _zsh_uptime="${_zsh_uptime_hours}h ${_zsh_uptime_mins}m"
    else
      _zsh_uptime="${_zsh_uptime_mins}m"
    fi
  fi

  print -P "%F{cyan} Startup:%f %F{green}${_zsh_startup_time}%f"
  if [[ -n "$_zsh_mem_free_human" ]]; then
    print -P "%F{cyan}󰑭 Mem:%f %F{green}${_zsh_mem_free_human} free%f"
  fi
  if [[ -n "$_zsh_uptime" ]]; then
    print -P "%F{cyan}󰅐 Uptime:%f %F{green}${_zsh_uptime}%f"
  fi
  if [[ -n "$_zsh_cpu_model" || -n "$_zsh_cpu_usage" ]]; then
    typeset _zsh_cpu_line=""
    [[ -n "$_zsh_cpu_model" ]] && _zsh_cpu_line="$_zsh_cpu_model"
    if [[ -n "$_zsh_cpu_cores" ]]; then
      [[ -n "$_zsh_cpu_line" ]] && _zsh_cpu_line+=" · "
      _zsh_cpu_line+="${_zsh_cpu_cores} cores"
    fi
    if [[ -n "$_zsh_cpu_usage" ]]; then
      [[ -n "$_zsh_cpu_line" ]] && _zsh_cpu_line+=" · "
      _zsh_cpu_line+="CPU ${_zsh_cpu_usage}"
    fi
    print -P "%F{cyan}󰍛 CPU:%f %F{green}${_zsh_cpu_line}%f"
  fi
fi
