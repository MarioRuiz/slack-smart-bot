require_relative "commands/general/hi_bot"
require_relative "commands/general/bye_bot"
require_relative "commands/general/bot_help"
require_relative "commands/on_bot/general/suggest_command"
require_relative "commands/on_bot/ruby_code"
require_relative "commands/on_bot/repl"
require_relative "commands/on_bot/repl_client"
require_relative "commands/on_bot/get_repl"
require_relative "commands/on_bot/run_repl"
require_relative "commands/on_bot/kill_repl"
require_relative "commands/on_bot/delete_repl"
require_relative "commands/on_bot/see_repls"
require_relative "commands/on_bot/general/whats_new"
require_relative "commands/on_bot/general/use_rules"
require_relative "commands/on_bot/general/stop_using_rules"
require_relative "commands/on_master/admin_master/exit_bot"
require_relative "commands/on_master/admin_master/notify_message"
require_relative "commands/on_master/admin/kill_bot_on_channel"
require_relative "commands/on_master/create_bot"
require_relative "commands/on_master/where_smartbot"
require_relative "commands/on_bot/admin/add_routine"
require_relative "commands/on_bot/admin/start_bot"
require_relative "commands/on_bot/admin/pause_bot"
require_relative "commands/on_bot/admin/remove_routine"
require_relative "commands/on_bot/admin/see_result_routine"
require_relative "commands/on_bot/admin/run_routine"
require_relative "commands/on_bot/admin/pause_routine"
require_relative "commands/on_bot/admin/start_routine"
require_relative "commands/on_bot/admin/see_routines"
require_relative "commands/on_bot/admin/extend_rules"
require_relative "commands/on_bot/admin/stop_using_rules_on"
require_relative "commands/on_bot/general/bot_status"
require_relative "commands/on_bot/add_shortcut"
require_relative "commands/on_bot/delete_shortcut"
require_relative "commands/on_bot/see_shortcuts"
require_relative "commands/on_extended/bot_rules"
require_relative "commands/on_bot/admin_master/get_bot_logs"
require_relative "commands/on_bot/admin_master/send_message"
require_relative "commands/on_bot/admin_master/delete_message"
require_relative "commands/on_bot/admin_master/update_message"
require_relative "commands/on_bot/admin_master/react_to"
require_relative "commands/on_bot/general/bot_stats"
require_relative "commands/on_bot/general/leaderboard"
require_relative "commands/general/add_announcement"
require_relative "commands/general/delete_announcement"
require_relative "commands/general/see_announcements"
require_relative "commands/general/see_statuses"
require_relative "commands/general/see_favorite_commands"
require_relative "commands/on_master/admin_master/publish_announcements"
require_relative "commands/on_master/admin_master/set_maintenance"
require_relative "commands/on_master/admin_master/set_general_message"
require_relative "commands/general_bot_commands"
require_relative "commands/general/share_messages"
require_relative "commands/general/see_shares"
require_relative "commands/general/delete_share"
require_relative "commands/general/see_admins"
require_relative "commands/general/add_admin"
require_relative "commands/general/remove_admin"
require_relative "commands/general/see_command_ids"
require_relative "commands/general/poster"
require_relative "commands/general/see_access"
require_relative "commands/general/allow_access"
require_relative "commands/general/deny_access"
require_relative "commands/general/teams/add_team"
require_relative "commands/general/teams/memos/add_memo_team"
require_relative "commands/general/teams/memos/set_memo_status"
require_relative "commands/general/teams/memos/delete_memo_team"
require_relative "commands/general/teams/memos/see_memos_team"
require_relative "commands/general/teams/see_teams"
require_relative "commands/general/teams/update_team"
require_relative "commands/general/teams/ping_team"
require_relative "commands/general/teams/delete_team"
require_relative "commands/general/add_vacation"
require_relative "commands/general/remove_vacation"
require_relative "commands/general/see_vacations"
require_relative "commands/general/teams/see_vacations_team"
require_relative "commands/general/public_holidays"
require_relative "commands/general/set_public_holidays"
require_relative "commands/general/personal_settings"
require_relative "commands/general/teams/memos/add_memo_team_comment"
require_relative "commands/general/teams/memos/see_memo_team"
require_relative 'commands/general/ai/open_ai/open_ai_chat'
require_relative 'commands/general/ai/open_ai/open_ai_generate_image'
require_relative 'commands/general/ai/open_ai/open_ai_variations_image'
require_relative 'commands/general/ai/open_ai/open_ai_edit_image'
require_relative 'commands/general/ai/open_ai/open_ai_models'
require_relative 'commands/general/ai/open_ai/open_ai_whisper'

class SlackSmartBot
    include SlackSmartBot::Commands::General::AI::OpenAI
    include SlackSmartBot::Commands::General::Teams
    include SlackSmartBot::Commands::General::Teams::Memos
end
