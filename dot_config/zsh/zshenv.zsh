# Keep this file safe for every zsh invocation: no external commands or output.
# Interactive shells later activate mise fully; these shims cover non-interactive
# zsh processes that need a stable executable path.
typeset -U path

mise_data_dir=${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}
mise_shims_dir="${mise_data_dir}/shims"
if [[ -d ${mise_shims_dir} ]]; then
  path=("${mise_shims_dir}" $path)
fi

unset mise_data_dir mise_shims_dir
