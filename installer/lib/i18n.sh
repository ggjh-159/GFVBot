#!/usr/bin/env bash
# i18n.sh — bilingual message catalog (en / zh) for the GFVBot installer.
#
# Language resolution, first hit wins:
#   GFVBOT_LANG > project config ($PWD/.gfvbot/config) >
#   global config (~/.gfvbot/config) > LC_ALL > LC_MESSAGES > LANG
# any en* value selects English; everything else — zh* locales, C/POSIX,
# unset — defaults to Chinese.
# Config files carry a `lang=<en|zh>` line; they are user content and survive
# territory reclaim on uninstall.
#
# Usage:  t <key> [printf-args...]   → prints the message
# Table headers and state tokens stay English on purpose: CJK characters are
# double-width and would break printf column alignment.

T_LANG=zh
T_LANG_SRC=default

_gfvbot_config_lang() {  # <config-file> → prints value, or returns 1
  [ -f "$1" ] || return 1
  local v
  v=$(sed -n 's/^lang=//p' "$1" | tail -n 1)
  [ -n "$v" ] || return 1
  printf '%s' "$v"
}

_gfvbot_apply_lang() {  # <value> <source-token>
  case "$1" in
    en*) T_LANG=en ;;
    *)   T_LANG=zh ;;
  esac
  T_LANG_SRC=$2
}

_gfvbot_detect_lang() {
  local v
  if [ -n "${GFVBOT_LANG:-}" ]; then
    _gfvbot_apply_lang "$GFVBOT_LANG" env
    return
  fi
  if v=$(_gfvbot_config_lang "$PWD/.gfvbot/config" 2>/dev/null); then
    _gfvbot_apply_lang "$v" "project:$PWD/.gfvbot/config"
    return
  fi
  if v=$(_gfvbot_config_lang "$HOME/.gfvbot/config" 2>/dev/null); then
    _gfvbot_apply_lang "$v" "global:$HOME/.gfvbot/config"
    return
  fi
  for v in "${LC_ALL:-}" "${LC_MESSAGES:-}" "${LANG:-}"; do
    [ -n "$v" ] || continue
    _gfvbot_apply_lang "$v" "locale:$v"
    return
  done
}
_gfvbot_detect_lang

declare -A MSG_EN=() MSG_ZH=()

# --- generic / lib/common.sh -------------------------------------------------
MSG_EN[err_source_missing]='source missing: %s'
MSG_ZH[err_source_missing]='源缺失: %s'
MSG_EN[warn_diverged]='destination diverged, backing up: %s -> %s'
MSG_ZH[warn_diverged]='目标内容与源不一致，先备份: %s -> %s'
MSG_EN[dry_install]='[dry-run] install %s -> %s'
MSG_ZH[dry_install]='[dry-run]安装%s -> %s'
MSG_EN[dry_link]='[dry-run] link %s -> %s'
MSG_ZH[dry_link]='[dry-run]链接%s -> %s'
MSG_EN[dry_update_sec]='[dry-run] update section in %s'
MSG_ZH[dry_update_sec]='[dry-run]更新节: %s'
MSG_EN[dry_append_sec]='[dry-run] append section to %s'
MSG_ZH[dry_append_sec]='[dry-run]追加节到: %s'
MSG_EN[dry_remove_sec]='[dry-run] remove section from %s'
MSG_ZH[dry_remove_sec]='[dry-run]移除节: %s'
MSG_EN[dry_create_index]='[dry-run] create index %s'
MSG_ZH[dry_create_index]='[dry-run]创建索引%s'
MSG_EN[dry_write_record]='[dry-run] write record %s'
MSG_ZH[dry_write_record]='[dry-run]写安装记录%s'
MSG_EN[dry_remove]='[dry-run] remove %s'
MSG_ZH[dry_remove]='[dry-run]删除%s'
MSG_EN[removed]='removed %s: %s'
MSG_ZH[removed]='已删除%s: %s'
MSG_EN[lbl_file]='file'
MSG_ZH[lbl_file]='文件'
MSG_EN[lbl_record]='record'
MSG_ZH[lbl_record]='记录'
MSG_EN[lbl_index]='index'
MSG_ZH[lbl_index]='索引'
MSG_EN[lbl_entry]='empty entry file'
MSG_ZH[lbl_entry]='空入口文件'
MSG_EN[lbl_records_root]='records root'
MSG_ZH[lbl_records_root]='记录根目录'
MSG_EN[dry_remove_settings]='[dry-run] remove agent-teams keys from %s'
MSG_ZH[dry_remove_settings]='[dry-run]移除%s中的agent teams键'
MSG_EN[lbl_settings_empty]='empty settings file'
MSG_ZH[lbl_settings_empty]='空settings文件'

# --- install.sh ---------------------------------------------------------------
MSG_EN[err_needs_value]='%s needs a value'
MSG_ZH[err_needs_value]='%s需要一个值'
MSG_EN[err_unknown_arg]='unknown argument or plugin not found: %s'
MSG_ZH[err_unknown_arg]='未知参数或插件不存在: %s'
MSG_EN[err_no_prompt]='plugin has no task prompt template: %s'
MSG_ZH[err_no_prompt]='插件没有任务prompt模板: %s'
MSG_EN[err_task_tool_required]='generating a prompt requires --tool <claude|opencode>'
MSG_ZH[err_task_tool_required]='生成prompt需要--tool <claude|opencode>'
MSG_EN[err_prompt_write]='cannot write task prompt file: %s'
MSG_ZH[err_prompt_write]='无法写入任务prompt文件: %s'
MSG_EN[msg_prompt_written]='task prompt written to %s'
MSG_ZH[msg_prompt_written]='任务prompt已写入%s'
MSG_EN[err_agent_cli_missing]='%s CLI not found on this machine'
MSG_ZH[err_agent_cli_missing]='本机未找到%s CLI'
MSG_EN[msg_generating]='generating task prompt via %s ...'
MSG_ZH[msg_generating]='正在通过%s生成任务prompt...'
MSG_EN[prompt_gen_intro]='You are generating a task prompt for a development scenario. First read %s/workflow.md to learn the workflow stages and gates of this scenario; then browse %s/docs/ and skills/, decide for yourself which of them are relevant to the task, and read those.'
MSG_ZH[prompt_gen_intro]='你在为一个开发场景生成任务prompt。先读%s/workflow.md了解该场景的工作流阶段与门禁；再浏览%s/docs/与skills/，自行判断哪些与任务相关并读取相关的。'
MSG_EN[prompt_gen_template_label]='Template:'
MSG_ZH[prompt_gen_template_label]='模板：'
MSG_EN[prompt_gen_task_label]='Task description from the user:'
MSG_ZH[prompt_gen_task_label]='用户的任务描述：'
MSG_EN[prompt_gen_rules]='The current directory is the target project; to ground the prompt in the actual code, you may read relevant source files in it. Fill the placeholders with this priority of information sources: the user task description > the plugin docs > the project source > sensible defaults (defaults must be marked as assumptions). The generated prompt targets a project with only this GFVBot plugin installed: beyond the plugin itself, do not reference any skills, agents, or tool names. Output only the filled prompt, nothing else.'
MSG_ZH[prompt_gen_rules]='当前目录即目标项目；为使prompt贴合业务，可读取项目内相关源文件。按模板填写占位符，信息来源优先级：用户任务描述>插件文档>项目源码>合理默认（默认必须标注为假设）。生成的prompt面向只安装了该GFVBot插件的目标项目环境：除插件自身外，不得引用任何skills、agents或工具名。只输出填好的prompt，不要输出其他内容。'
MSG_EN[err_shared_missing]='shared/ not found under repo root: %s'
MSG_ZH[err_shared_missing]='仓库根目录下缺少shared/: %s'
MSG_EN[ui_avail_plugins]='Available plugins:'
MSG_ZH[ui_avail_plugins]='可安装的插件:'
MSG_EN[ui_select_tool]='Select target AI Agent:'
MSG_ZH[ui_select_tool]='选择目标AI Agent:'
MSG_EN[err_bad_tool]='unsupported tool: %s (expected one of: %s)'
MSG_ZH[err_bad_tool]='不支持的AI Agent: %s（可选: %s）'
MSG_EN[err_target_missing]='target directory does not exist: %s'
MSG_ZH[err_target_missing]='目标目录不存在: %s'
MSG_EN[err_no_plugin]='no plugin selected'
MSG_ZH[err_no_plugin]='未选择任何插件'
MSG_EN[err_adapter]='adapter not found: %s'
MSG_ZH[err_adapter]='适配器不存在: %s'
MSG_EN[err_manifest]='plugin manifest not found: %s'
MSG_ZH[err_manifest]='插件清单不存在: %s'
MSG_EN[err_name_mismatch]='manifest name != directory name: %s'
MSG_ZH[err_name_mismatch]='清单name与目录名不一致: %s'
MSG_EN[err_workflow_field]='%s: workflow field must be workflow.md'
MSG_ZH[err_workflow_field]='%s: workflow字段必须为workflow.md'
MSG_EN[err_workflow_missing]='%s: workflow.md not found'
MSG_ZH[err_workflow_missing]='%s:缺少workflow.md'
MSG_EN[err_unit_missing]='manifest of %s declares missing %s: %s'
MSG_ZH[err_unit_missing]='%s的清单声明了不存在的%s: %s'
MSG_EN[msg_skip]='%s: already installed, source unchanged — skip'
MSG_ZH[msg_skip]='%s:已安装且源未变化，跳过'
MSG_EN[step_install]='install plugin: %s [%s] tool=%s target=%s lang=%s'
MSG_ZH[step_install]='安装插件: %s [%s] AI Agent=%s目标=%s语言=%s'
MSG_EN[link_mode_suffix]=' (link mode)'
MSG_ZH[link_mode_suffix]='（链接模式）'
MSG_EN[msg_stale]='removed stale: %s'
MSG_ZH[msg_stale]='已清除过期文件: %s'
MSG_EN[dry_remove_stale]='[dry-run] remove stale %s'
MSG_ZH[dry_remove_stale]='[dry-run]清除过期文件%s'
MSG_EN[err_health_missing]='health check: missing %s'
MSG_ZH[err_health_missing]='健康检查:缺失%s'
MSG_EN[err_health_failed]='%s: health check failed'
MSG_ZH[err_health_failed]='%s:健康检查未通过'
MSG_EN[msg_health_ok]='%s: health check passed (%s landed paths)'
MSG_ZH[msg_health_ok]='%s:健康检查通过（落盘%s项）'
MSG_EN[step_done]='done: %s plugin(s) -> %s @ %s'
MSG_ZH[step_done]='完成: %s个插件-> %s @ %s'

# --- adapters/claude.sh -------------------------------------------------------
MSG_EN[dry_write_settings]='[dry-run] write agent-teams defaults to %s'
MSG_ZH[dry_write_settings]='[dry-run]写入agent teams默认值: %s'
MSG_EN[msg_settings_done]='agent-teams defaults in place: %s'
MSG_ZH[msg_settings_done]='agent teams默认值已写入: %s'
MSG_EN[warn_no_tmux]='tmux not found: teammateMode left unset (teammates still run, shown via /tasks instead of panes)'
MSG_ZH[warn_no_tmux]='未找到tmux，暂不设置teammateMode（teammate仍可运行，经/tasks观察而非分屏）'
MSG_EN[warn_settings_user]='settings.json keeps user value %s=%s, gfvbot default not applied'
MSG_ZH[warn_settings_user]='settings.json保留用户值%s=%s，未覆盖为gfvbot默认值'
MSG_EN[warn_settings_invalid]='%s is not valid JSON, agent-teams defaults not applied'
MSG_ZH[warn_settings_invalid]='%s不是合法JSON，未写入agent teams默认值'

# --- uninstall.sh -------------------------------------------------------------
MSG_EN[err_no_plugin_given]='no plugin given (see --help)'
MSG_ZH[err_no_plugin_given]='未指定插件（见--help）'
MSG_EN[err_no_records]='no GFVBot install records under %s'
MSG_ZH[err_no_records]='%s下没有GFVBot安装记录'
MSG_EN[warn_no_record]='%s: no install record under %s, skipping'
MSG_ZH[warn_no_record]='%s: 在 %s下没有安装记录，跳过'
MSG_EN[err_nothing]='nothing to uninstall'
MSG_ZH[err_nothing]='没有可卸载的插件'
MSG_EN[ui_pick_title]='Select installs to remove:'
MSG_ZH[ui_pick_title]='选择要卸载的安装:'
MSG_EN[ui_pick_hint]='(up/down: move  space: toggle  enter: confirm  q: cancel)'
MSG_ZH[ui_pick_hint]='（上下键:移动 空格:切换 回车:确认 q:取消）'
MSG_EN[env_title]='Environment check'
MSG_ZH[env_title]='环境检查'
MSG_EN[env_missing]='%s: not found'
MSG_ZH[env_missing]='%s：未找到'
MSG_EN[env_group_missing]='%s: missing members: %s'
MSG_ZH[env_group_missing]='%s：缺失项: %s'
MSG_EN[env_java_home_unset]='JAVA_HOME: not set or not a usable JDK'
MSG_ZH[env_java_home_unset]='JAVA_HOME：未设置或不是可用的JDK'
MSG_EN[env_java_home_hint]='set JAVA_HOME manually (e.g. in ~/.bashrc); it is never set automatically'
MSG_ZH[env_java_home_hint]='请手动设置JAVA_HOME（如写入~/.bashrc），不会自动设置'
MSG_EN[env_saved]='archived to %s'
MSG_ZH[env_saved]='已归档到%s'
MSG_EN[env_all_present]='all dependencies present'
MSG_ZH[env_all_present]='依赖齐全'
MSG_EN[env_noninteractive]='non-interactive terminal; to install missing packages run: %s'
MSG_ZH[env_noninteractive]='非交互终端；安装缺失依赖请执行: %s'
MSG_EN[env_installing_jq]='installing jq (required by the environment check) ...'
MSG_ZH[env_installing_jq]='正在安装jq（环境检查自身依赖）...'
MSG_EN[env_installing_jq_static]='no jq package in the repos; downloading static binary from %s ...'
MSG_ZH[env_installing_jq_static]='源内无jq包，下载静态二进制%s...'
MSG_EN[env_jq_manual]='jq is required: install it with your package manager, then rerun gfvbot env'
MSG_ZH[env_jq_manual]='需要jq：请先用包管理器安装jq，再重新运行gfvbot env'
MSG_EN[env_ask_install]='install missing dependencies now? [y/N]'
MSG_ZH[env_ask_install]='现在安装缺失依赖？[y/N]'
MSG_EN[env_run_setup]='to install later, run: %s'
MSG_ZH[env_run_setup]='后续安装请执行: %s'
MSG_EN[env_os_unsupported]='no dependency installer for this OS yet: %s; install the missing packages manually'
MSG_ZH[env_os_unsupported]='该OS暂无依赖安装脚本: %s，请手动安装缺失依赖'
MSG_EN[env_repos_broken]='yum repos unreachable (CentOS 7 is EOL, upstream mirrors are gone)'
MSG_ZH[env_repos_broken]='yum源不可用（CentOS 7已停止维护，官方镜像已下线）'
MSG_EN[env_ask_fix_repos]='switch yum repos to archive mirror %s? [y/N]'
MSG_ZH[env_ask_fix_repos]='切换yum源到归档镜像%s？[y/N]'
MSG_EN[env_repos_fixed]='yum repos switched to %s (original saved as %s)'
MSG_ZH[env_repos_fixed]='yum源已切换到%s（原文件备份为%s）'
MSG_EN[env_repos_fix_failed]='yum repos left unchanged; configure an archive mirror manually if needed'
MSG_ZH[env_repos_fix_failed]='yum源未修复；如需安装请手动配置归档镜像'
MSG_EN[env_repos_noninteractive]='non-interactive terminal; run %s in a TTY to fix the repos first'
MSG_ZH[env_repos_noninteractive]='非交互终端；请先在交互终端运行%s修复yum源'
MSG_EN[env_dl_jdk17]='downloading Temurin JDK 17 from %s ...'
MSG_ZH[env_dl_jdk17]='正在从%s下载Temurin JDK 17...'
MSG_EN[env_jdk17_done]='JDK 17 installed at %s'
MSG_ZH[env_jdk17_done]='JDK 17已安装到%s'
MSG_EN[env_jdk17_failed]='failed to install JDK 17; download a Temurin 17 tarball from https://adoptium.net manually'
MSG_ZH[env_jdk17_failed]='JDK 17安装失败；请从https://adoptium.net手动下载Temurin 17压缩包'
MSG_EN[env_dl_flink]='downloading flink from %s ...'
MSG_ZH[env_dl_flink]='正在从%s下载flink...'
MSG_EN[env_flink_done]='flink ready at %s (consider exporting FLINK_HOME=%s)'
MSG_ZH[env_flink_done]='flink已就绪：%s（建议设置FLINK_HOME=%s）'
MSG_EN[env_flink_failed]='failed to install flink; download the tarball from https://flink.apache.org manually'
MSG_ZH[env_flink_failed]='flink安装失败；请从https://flink.apache.org手动下载发行包'
MSG_EN[env_nexmark_clone]='cloning nexmark source from %s ...'
MSG_ZH[env_nexmark_clone]='正在从%s克隆nexmark源码...'
MSG_EN[env_nexmark_clone_failed]='cloning nexmark source failed after retries; check network access to github.com'
MSG_ZH[env_nexmark_clone_failed]='多次重试后仍无法克隆nexmark源码；请检查到github.com的网络'
MSG_EN[env_nexmark_build]='building nexmark-flink with JAVA_HOME=%s (log: /tmp/gfvbot-nexmark-build.log) ...'
MSG_ZH[env_nexmark_build]='使用JAVA_HOME=%s构建nexmark-flink（日志：/tmp/gfvbot-nexmark-build.log）...'
MSG_EN[env_nexmark_tree]='laying out the nexmark benchmark tree under %s ...'
MSG_ZH[env_nexmark_tree]='正在%s铺设nexmark基准运行树...'
MSG_EN[env_nexmark_done]='nexmark jar deployed: %s (benchmark tree: %s)'
MSG_ZH[env_nexmark_done]='nexmark jar已部署：%s（基准运行树：%s）'
MSG_EN[env_nexmark_failed]='nexmark build failed; see /tmp/gfvbot-nexmark-build.log'
MSG_ZH[env_nexmark_failed]='nexmark构建失败；请查看/tmp/gfvbot-nexmark-build.log'
MSG_EN[env_nexmark_needs_mvn]='nexmark needs maven: tick mvn in the list and rerun'
MSG_ZH[env_nexmark_needs_mvn]='nexmark构建需要maven：请在列表勾选mvn后重试'
MSG_EN[env_nexmark_needs_jdk]='nexmark needs a JDK: tick jdk-17 in the list and rerun'
MSG_ZH[env_nexmark_needs_jdk]='nexmark构建需要JDK：请在列表勾选jdk-17后重试'
MSG_EN[env_apt_update]='refreshing package lists ...'
MSG_ZH[env_apt_update]='正在刷新软件包列表...'
MSG_EN[env_no_pm]='no supported package manager (dnf/yum/apt-get); install missing packages manually'
MSG_ZH[env_no_pm]='未找到支持的包管理器（dnf/yum/apt-get），请手动安装缺失依赖'
MSG_EN[env_pick_title]='Select dependencies to install:'
MSG_ZH[env_pick_title]='选择要安装的依赖:'
MSG_EN[env_install_cancelled]='install cancelled'
MSG_ZH[env_install_cancelled]='已取消安装'
MSG_EN[env_install_none]='nothing selected'
MSG_ZH[env_install_none]='未选择任何项'
MSG_EN[env_installing]='installing %s ...'
MSG_ZH[env_installing]='正在安装%s...'
MSG_EN[env_install_failed]='failed to install %s; install it manually'
MSG_ZH[env_install_failed]='%s安装失败，请手动安装'
MSG_EN[env_rescan]='re-scan after install'
MSG_ZH[env_rescan]='安装后重新扫描'
MSG_EN[env_enable_epel_crb]='enabling EPEL and CRB repos (ninja/ccache live there) ...'
MSG_ZH[env_enable_epel_crb]='正在启用EPEL与CRB源（ninja/ccache在其中）...'
MSG_EN[err_envinit_no_os]='cannot detect the OS (/etc/os-release missing); run the env-init script under installer/env-init/ manually'
MSG_ZH[err_envinit_no_os]='无法识别操作系统（缺/etc/os-release）；请手动执行installer/env-init/下的安装脚本'
MSG_EN[err_envinit_unsupported]='no dependency installer for this OS yet: %s; install the missing packages manually'
MSG_ZH[err_envinit_unsupported]='该OS暂无依赖安装脚本: %s，请手动安装缺失依赖'
MSG_EN[clone_title]='Cloning GFV source repos'
MSG_ZH[clone_title]='克隆GFV源码仓库'
MSG_EN[clone_skip]='%s: already exists, skipping (manage it with git directly)'
MSG_ZH[clone_skip]='%s：已存在，跳过（版本管理请直接用git）'
MSG_EN[clone_cloning]='cloning %s (%s, branch %s) ...'
MSG_ZH[clone_cloning]='正在克隆%s（%s，分支%s）...'
MSG_EN[clone_done]='%s cloned to %s'
MSG_ZH[clone_done]='%s已克隆到%s'
MSG_EN[clone_failed]='failed to clone %s'
MSG_ZH[clone_failed]='%s克隆失败'
MSG_EN[clone_all_done]='all requested repos ready under %s'
MSG_ZH[clone_all_done]='请求的仓库已就绪于%s'
MSG_EN[clone_retry]='clone of %s failed (%s/%s), retrying in %ss...'
MSG_ZH[clone_retry]='%s克隆失败（%s/%s），%s秒后重试...'
MSG_EN[clone_failed_summary]='some repos failed to clone: %s. Re-run the same command to retry them; completed repos are skipped'
MSG_ZH[clone_failed_summary]='以下仓克隆失败：%s。重跑同一命令即续补（已完成的仓自动跳过）'
MSG_EN[clone_env_recorded]='repo paths recorded in %s'
MSG_ZH[clone_env_recorded]='仓库路径已记录到%s'
MSG_EN[clone_source_deps_hint]='next: the source-built C++ libraries (boost, the folly chain, ...) are not system packages — run "gfvbot env-init" and tick "source-deps" to install them (only offered when the velox checkout exists)'
MSG_ZH[clone_source_deps_hint]='下一步：源码级C++库（boost、folly链等）不是系统包——运行gfvbot env-init并勾选source-deps安装（仅在velox仓已克隆时提供该项）'
MSG_EN[env_repos_hint]='repo paths not set for: %s — run gfvbot clone, or edit the repos section in .gfvbot/env.json by hand'
MSG_ZH[env_repos_hint]='仓库路径未设置：%s——可执行gfvbot clone克隆，或直接编辑.gfvbot/env.json的repos节'
MSG_EN[err_unknown_repo]='unknown repo: %s (known: velox velox4j gluten flink)'
MSG_ZH[err_unknown_repo]='未知仓库: %s（可用: velox velox4j gluten flink）'
MSG_EN[sd_title]='Installing Velox source-built C++ libraries to /usr/local'
MSG_ZH[sd_title]='安装Velox源码级C++库到/usr/local'
MSG_EN[sd_no_velox]='repos/velox not found under the target — run gfvbot clone first (the install functions and the library list come from the velox checkout), then rerun env-init and tick source-deps'
MSG_ZH[sd_no_velox]='目标目录下未找到repos/velox——请先执行gfvbot clone（安装函数与库清单都来自velox仓自身），然后重跑env-init勾选source-deps'
MSG_EN[sd_os_unsupported]='Error: this OS has no usable velox setup script (CentOS 7 vault repos are unsupported).'
MSG_ZH[sd_os_unsupported]='错误：本OS没有可用的velox安装脚本（CentOS 7的vault源不支持）。'
MSG_EN[sd_parse_failed]='Error: no install entries parsed from %s — the velox setup script layout changed; the parser needs an update.'
MSG_ZH[sd_parse_failed]='错误：未能从%s解析出安装项——velox安装脚本结构有变，解析逻辑需要跟进。'
MSG_EN[sd_skip]='%s: already under /usr/local, skipping'
MSG_ZH[sd_skip]='%s：已在/usr/local，跳过'
MSG_EN[sd_building]='building %s ...'
MSG_ZH[sd_building]='正在构建%s...'
MSG_EN[sd_stale_wipe]='%s: leftover partial download in the cache, wiping before rebuild'
MSG_ZH[sd_stale_wipe]='%s：缓存里留有下载残缺目录，清除后重建'
MSG_EN[sd_failed]='failed to build %s (see the output above; fix and rerun env-init with source-deps ticked)'
MSG_ZH[sd_failed]='%s构建失败（见上方输出；修复后重跑env-init勾选source-deps）'
MSG_EN[sd_all_present]='all source-built libraries already present'
MSG_ZH[sd_all_present]='源码级库已全部就绪'
MSG_EN[sd_done]='source-built libraries installed'
MSG_ZH[sd_done]='源码级库安装完成'
MSG_EN[err_no_git]='git not found; run "gfvbot env-init" to install it first'
MSG_ZH[err_no_git]='未找到git；请先运行gfvbot env-init安装'
MSG_EN[clone_installing_git]='git is required by clone but not installed; installing it via the package manager'
MSG_ZH[clone_installing_git]='clone需要git但未安装，正在通过包管理器安装'
MSG_EN[msg_uninstall_cancelled]='uninstall cancelled'
MSG_ZH[msg_uninstall_cancelled]='已取消卸载'
MSG_EN[msg_noninteractive_all]='non-interactive terminal: removing installs of all tools'
MSG_ZH[msg_noninteractive_all]='非交互终端:将卸载全部工具的安装'
MSG_EN[step_uninstall]='uninstall plugin: %s [tool=%s]'
MSG_ZH[step_uninstall]='卸载插件: %s [AI Agent=%s]'
MSG_EN[msg_file_kept]='kept %s: still referenced by a surviving install'
MSG_ZH[msg_file_kept]='已保留%s:仍被其它存活安装引用'
MSG_EN[step_reclaim_tool]='territory reclaim: last plugin of %s removed'
MSG_ZH[step_reclaim_tool]='领地回收: %s下最后一个插件已移除'
MSG_EN[msg_tool_reclaimed]='territory of %s reclaimed'
MSG_ZH[msg_tool_reclaimed]='%s的领地已回收'
MSG_EN[msg_remaining]='remaining plugins: %s'
MSG_ZH[msg_remaining]='剩余插件: %s'
MSG_EN[step_reclaim]='territory reclaim: last plugin removed'
MSG_ZH[step_reclaim]='领地回收:最后一个插件已移除'
MSG_EN[msg_reclaimed]='territory reclaimed, zero residue'
MSG_ZH[msg_reclaimed]='领地已回收，零残留'

# --- setup.sh -----------------------------------------------------------------
MSG_EN[msg_setup_already]='already set up (%s contains the gfvbot block)'
MSG_ZH[msg_setup_already]='已配置过（%s已包含gfvbot块）'
MSG_EN[msg_setup_added]='added gfvbot block to %s'
MSG_ZH[msg_setup_added]='已向%s添加gfvbot块'
MSG_EN[msg_setup_next]='restart your shell (or: source %s), then use: gfvbot install <plugin>'
MSG_ZH[msg_setup_next]='重启shell（或执行source %s）后即可使用: gfvbot install <插件名>'

# --- adapters -----------------------------------------------------------------
MSG_EN[err_no_skill_md]='skill unit without SKILL.md: %s'
MSG_ZH[err_no_skill_md]='skill单元缺少SKILL.md: %s'
MSG_EN[dsh_hint]='dsh: point instructionFileCandidates at %s in your dsh config to load the workflows'
MSG_ZH[dsh_hint]='dsh:请在dsh配置中把instructionFileCandidates指向%s以加载工作流'

# --- gfvbot CLI ---------------------------------------------------------------
MSG_EN[list_target]='Target: %s'
MSG_ZH[list_target]='目标: %s'
MSG_EN[list_installed]='Installed (%s)'
MSG_ZH[list_installed]='已安装(%s)'
MSG_EN[list_available]='Available (%s)'
MSG_ZH[list_available]='可安装(%s)'
MSG_EN[list_none]='(none)'
MSG_ZH[list_none]='（无）'
MSG_EN[err_unsupported_shell]='unsupported shell: %s (expected bash or zsh)'
MSG_ZH[err_unsupported_shell]='不支持的shell: %s（支持bash或zsh）'

# --- gfvbot lang ----------------------------------------------------------------
MSG_EN[lang_current]='current language: %s (source: %s)'
MSG_ZH[lang_current]='当前语言: %s（来源: %s）'
MSG_EN[lang_src_env]='environment variable GFVBOT_LANG'
MSG_ZH[lang_src_env]='环境变量GFVBOT_LANG'
MSG_EN[lang_src_project]='project config %s'
MSG_ZH[lang_src_project]='项目配置%s'
MSG_EN[lang_src_global]='global config %s'
MSG_ZH[lang_src_global]='全局配置%s'
MSG_EN[lang_src_locale]='system locale %s'
MSG_ZH[lang_src_locale]='系统locale %s'
MSG_EN[lang_src_default]='default'
MSG_ZH[lang_src_default]='默认'
MSG_EN[lang_set_project]='project language set to %s: %s'
MSG_ZH[lang_set_project]='项目级语言已设为%s: %s'
MSG_EN[lang_set_global]='global language set to %s: %s'
MSG_ZH[lang_set_global]='全局级语言已设为%s: %s'
MSG_EN[err_bad_lang]='expected en or zh: %s'
MSG_ZH[err_bad_lang]='只支持en或zh: %s'
MSG_EN[msg_config_kept]='kept user config: %s'
MSG_ZH[msg_config_kept]='已保留用户配置: %s'

t() {
  local k=$1; shift
  local fmt="${MSG_EN[$k]:-}"
  [ "$T_LANG" = zh ] && fmt="${MSG_ZH[$k]:-$fmt}"
  [ -n "$fmt" ] || fmt="$k"
  if [ $# -gt 0 ]; then printf "$fmt" "$@"; else printf '%s' "$fmt"; fi
}
