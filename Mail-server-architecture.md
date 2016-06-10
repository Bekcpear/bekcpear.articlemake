---
title-meta: 以Postfix为例详解邮件服务器
author-meta: Bekcpear
subject-meta: Linux服务器
keywords-meta: postfix, server
createdate-meta: 2016-06-04
---
## Postfix结构图解
```
                                                                                          MECHANISMS:
                                                                                  via_mail_transform_agent,
                                                                                   via_mail_delivery_agent,
                                                                          direct_delivery_to_an_mbox_formatted_mailbox,
                                                                             direct_delivery_to_a_maildir_directory,
                                                                                        standard_output
                                                                                              |
  MUA ---------------------------------- MTA(push) -----...----- MTA(pull) -- MDA =========> MRA ==== MUA
        main.cf:smtpd_client_restrictions-|                       |-smtpd_sender_restricitons
     main.cf:smtpd_recipient_restrictions-|
        main.cf:smtpd_replay_restrictions-|
```

