def csettings()

    {
        client: {
            web_client: {
                users_list: [
                    { name: 'example', id: 'UMSRCRTAR', profile: {display_name: 'example'}}, #smart-bot #example
                    { name: 'marioruizs', id: 'UJP2EK400', profile: {display_name: 'Mario Ruiz Sánchez'} }, 
                    { name: 'smartbotuser1', id: 'UNDE229T9', profile: {display_name: 'user1'}},
                    { name: 'smartbotuser2', id: 'UMYQS8E7L', profile: {display_name: 'user2'}} 
                ],
                users_info: {
                    UMSRCRTAR: { user: { name: 'example', id: 'UMSRCRTAR', profile: {display_name: 'example', status_text: '', status_emoji: '', expiration: ''}}}, #smart-bot #example
                    UJP2EK400: { user: { name: 'marioruizs', id: 'UJP2EK400', profile: {display_name: 'Mario Ruiz Sánchez', status_text: 'on vacation', status_emoji: ':palm_tree:', expiration: ''} } }, 
                    UNDE229T9: { user: { name: 'smartbotuser1', id: 'UNDE229T9', profile: {display_name: 'user1', status_text: '', status_emoji: ':boy:', expiration: ''}} },
                    UMYQS8E7L: { user: { name: 'smartbotuser2', id: 'UMYQS8E7L', profile: {display_name: 'user2', status_text: '', status_emoji: '', expiration: ''}} }
                },
                conversations_members: {
                    CN0595D50: { id: 'CN0595D50', name: 'bot1cm', creator: 'UJP2EK400', members: ['UMSRCRTAR','UJP2EK400', 'UNDE229T9']}, #bot1cm
                    CN1EFTKQB: { id: 'CN1EFTKQB', name: 'bot2cu', creator: 'UJP2EK400', members: ['UMSRCRTAR','UJP2EK400', 'UNDE229T9', 'UMYQS8E7L']}, #bot2cu
                    CNC60J25U: { id: 'CNC60J25U', name: 'master_channel', creator: 'UJP2EK400', members: ['UMSRCRTAR','UJP2EK400', 'UNDE229T9', 'UMYQS8E7L']}, #master_channel
                    CP28CTWSD: { id: 'CP28CTWSD', name: 'external_channel', creator: 'UJP2EK400', members: ['UMSRCRTAR','UJP2EK400', 'UNDE229T9']}, #external_channel
                    CN1E84BRR: { id: 'CN1E84BRR', name: 'extended1', members: ['UMSRCRTAR','UJP2EK400', 'UNDE229T9', 'UMYQS8E7L']}, #extended1 extended from cbot1cm
                    GNCU7JC6L: { id: 'GNCU7JC6L', name: 'private1', members: ['UMSRCRTAR','UJP2EK400', 'UNDE229T9']}, #private1
                    GN6G77CUR: { id: 'GN6G77CUR', name: 'privextended', members: ['UMSRCRTAR','UJP2EK400', 'UNDE229T9']}, #privextended, private and extended from cbot1cm
                    CNM7T8G8P: { id: 'CNM7T8G8P', name: 'channel_bot_not_invited', members: ['UJP2EK400']}, #channel_bot_not_invited
                    CPA5GVAF7: { id: 'CPA5GVAF7', name: 'external_channel_no_user1', members: ['UMYQS8E7L']},
                    DNB4GTK2Q: { id: 'DNB4GTK2Q', name: 'DNB4GTK2Q', members: ['UMSRCRTAR','UNDE229T9']}
                }
            }
        }
    }
end
