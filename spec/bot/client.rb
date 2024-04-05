def csettings()
  {
    client: {
      web_client: {
        users_list: [
          { team_id: "TJGMKRXQ9", name: "example", id: "UMSRCRTAR", tz_offset: 0, deleted: false, profile: { display_name: "example" } }, #smart-bot #example
          { team_id: "TJGMKRXQ9", name: "marioruizs", id: "UJP2EK400", tz_offset: 0, deleted: false, profile: { display_name: "Mario Ruiz Sánchez" } },
          { team_id: "TJGMKRXQ9", name: "smartbotuser1", id: "UNDE229T9", tz_offset: 0, deleted: false, profile: { display_name: "user1" } },
          { team_id: "TJGMKRXQ9", name: "smartbotuser2", id: "UMYQS8E7L", tz_offset: 0, deleted: false, profile: { display_name: "user2" } },
          { team_id: "TJGMKRXQ9", name: "xxx", id: "UXXXXXXXX", tz_offset: 0, deleted: true, profile: { display_name: "userx" } },
          { team_id: "XTERNALTEAM", name: "peterloop", id: "UYYYYYYXX", tz_offset: 0, deleted: false, profile: { display_name: "peter" } },
          { team_id: "XTERNALTEAM", name: "marioruizs", id: "UZZZZZZXX", tz_offset: 0, deleted: false, profile: { display_name: "Mario External" } },
        ],
        users_info: {
          UMSRCRTAR: { user: { team_id: "TJGMKRXQ9", name: "example", id: "UMSRCRTAR", deleted: false, tz_offset: 0, profile: { display_name: "example", status_text: "", status_emoji: "", expiration: "" } } }, #smart-bot #example
          UJP2EK400: { user: { team_id: "TJGMKRXQ9", name: "marioruizs", id: "UJP2EK400", deleted: false, tz_offset: 0, profile: { display_name: "Mario Ruiz Sánchez", status_text: "on vacation", status_emoji: ":palm_tree:", expiration: "" } } },
          UNDE229T9: { user: { team_id: "TJGMKRXQ9", name: "smartbotuser1", id: "UNDE229T9", deleted: false, tz_offset: 0, profile: { display_name: "user1", status_text: "", status_emoji: ":boy:", expiration: "" } } },
          UMYQS8E7L: { user: { team_id: "TJGMKRXQ9", name: "smartbotuser2", id: "UMYQS8E7L", deleted: false, tz_offset: 0, profile: { display_name: "user2", status_text: "", status_emoji: "", expiration: "" } } },
          UXXXXXXXX: { user: { team_id: "TJGMKRXQ9", name: "xxx", id: "UXXXXXXXX", deleted: true, tz_offset: 0, profile: { display_name: "userx", status_text: "", status_emoji: "", expiration: "" } } },
          UYYYYYYXX: { user: { team_id: "XTERNALTEAM", name: "peterloop", id: "UYYYYYYXX", deleted: false, tz_offset: 0, profile: { display_name: "peter", status_text: "", status_emoji: "", expiration: "" } } },
          UZZZZZZXX: { user: { team_id: "XTERNALTEAM", name: "marioruizs", id: "UZZZZZZXX", deleted: false, tz_offset: 0, profile: { display_name: "Mario External", status_text: "", status_emoji: "", expiration: "" } } },
        },
        users_get_presence: {
          UMSRCRTAR: { team_id: "TJGMKRXQ9", name: "example", presence: "active" }, #smart-bot #example
          UJP2EK400: { team_id: "TJGMKRXQ9", name: "marioruizs", presence: "active" },
          UNDE229T9: { team_id: "TJGMKRXQ9", name: "smartbotuser1", presence: "active" },
          UMYQS8E7L: { team_id: "TJGMKRXQ9", name: "smartbotuser2", presence: "away" },
          UYYYYYYXX: { team_id: "XTERNALTEAM", name: "peterloop", presence: "away" },
          UZZZZZZXX: { team_id: "XTERNALTEAM", name: "marioruizs", presence: "active" },
        },
        conversations_members: {
          CN0595D50: { id: "CN0595D50", name: "bot1cm", creator: "UJP2EK400", members: ["UMSRCRTAR", "UJP2EK400", "UNDE229T9", "UZZZZZZXX"] }, #bot1cm
          CN1EFTKQB: { id: "CN1EFTKQB", name: "bot2cu", creator: "UNDE229T9", members: ["UMSRCRTAR", "UJP2EK400", "UNDE229T9", "UMYQS8E7L"] }, #bot2cu
          CNC60J25U: { id: "CNC60J25U", name: "master_channel", creator: "UJP2EK400", members: ["UMSRCRTAR", "UJP2EK400", "UNDE229T9", "UMYQS8E7L"] }, #master_channel
          CP28CTWSD: { id: "CP28CTWSD", name: "external_channel", creator: "UNDE229T9", members: ["UMSRCRTAR", "UJP2EK400", "UNDE229T9", "UYYYYYYXX"] }, #external_channel
          CN1E84BRR: { id: "CN1E84BRR", name: "extended1", creator: "UJP2EK400", members: ["UMSRCRTAR", "UJP2EK400", "UNDE229T9", "UMYQS8E7L"] }, #extended1 extended from cbot1cm
          GNCU7JC6L: { id: "GNCU7JC6L", name: "private1", members: ["UMSRCRTAR", "UJP2EK400", "UNDE229T9"] }, #private1
          GN6G77CUR: { id: "GN6G77CUR", name: "privextended", members: ["UMSRCRTAR", "UJP2EK400", "UNDE229T9"] }, #privextended, private and extended from cbot1cm
          CNM7T8G8P: { id: "CNM7T8G8P", name: "channel_bot_not_invited", members: ["UJP2EK400"] }, #channel_bot_not_invited
          CPA5GVAF7: { id: "CPA5GVAF7", name: "external_channel_no_user1", members: ["UMYQS8E7L"] },
          DNB4GTK2Q: { id: "DNB4GTK2Q", name: "DNB4GTK2Q", members: ["UMSRCRTAR", "UNDE229T9"] },
          C02B4EF3WH4: { id: "C02B4EF3WH4", name: "smartbot-status", creator: "UJP2EK400", members: ["UMSRCRTAR", "UJP2EK400", "UNDE229T9"] },
          C049BGYNDFU: { id: "C049BGYNDFU", name: "smartbot-stats", creator: "UJP2EK400", members: ["UMSRCRTAR", "UJP2EK400", "UNDE229T9"] },
        },
      },
    },
  }
end
