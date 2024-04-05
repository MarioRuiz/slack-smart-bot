SIMULATE = ENV["SIMULATE"].to_s == "true"

require "slack-smart-bot"
ENV["SLEEP_AFTER_SEND"] ||= "2"
CMASTER = "CNC60J25U" #master_channel
CBOT1CM = "CN0595D50" #bot1cm bot created by admin
CBOT2CU = "CN1EFTKQB" #bot2cu bot created by user
CEXTERNAL = "CP28CTWSD" #external_channel
CEXT1 = "CN1E84BRR" #extended1 extended from cbot1cm
CPRIV1 = "GNCU7JC6L" #private1
CPRIVEXT = "GN6G77CUR" #privextended, private and extended from cbot1cm
CBOTNOTINVITED = "CNM7T8G8P" #channel_bot_not_invited
CNOUSER1 = "CPA5GVAF7" #external_channel_no_user1
CSTATUS = "C02B4EF3WH4" #smartbot-status
CSTATS = "C049BGYNDFU" #smartbot-stats

UBOT = "UMSRCRTAR" #example
UBOT2 = "UNA5W6PE1" #unormal
UADMIN = "UJP2EK400" #marioruizs
UADMIN_NAME = "marioruizs"
USER1 = "UNDE229T9" #user1
USER2 = "UMYQS8E7L" #user2
USERX = "UXXXXXXXX" #userx (deleted/deactivated)
UEXTERNAL = "UYYYYYYXX" #peterloop external user from other workspace
UEXTERNAL2 = "UZZZZZZXX" #marioruizs external user from other workspace with same name as UADMIN

DIRECT = {
  :uadmin => { :ubot => "DMV17MUTG" },
  :user1 => { :ubot => "DNB4GTK2Q" },
  :user2 => { :ubot => "DNDQBA4NA" },
  :UJP2EK400 => { :ubot => "DMV17MUTG" },
  :UNDE229T9 => { :ubot => "DNB4GTK2Q" },
  :UMYQS8E7L => { :ubot => "DNDQBA4NA" },
}
