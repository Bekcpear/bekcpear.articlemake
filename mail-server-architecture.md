---
title-meta: 以Postfix为例详解邮件服务器
author-meta: Bekcpear
subject-meta: Linux服务器
keywords-meta: postfix, server
createdate-meta: 2016-06-10
---
邮件系统中的单元往往会有相互重复的功能，对于初学者的我来说，肯定是需要好好整理归纳的。本文会以传统的邮件收发模式为模型，结合Postfix这个邮件服务器实现来说明其结构原理。会穿插一些DNS的相关知识，正解和反解对于邮件服务器是比较重要的，对于如何处理垃圾邮件、病毒也有会说明。希望整理出一个适用的小型邮件服务器实例。

##邮件组成
+ 符合RFC5322的邮件头和邮件主体，就邮件头而言：
  1. 针对收信端的*To*直接收信者、*Cc*抄送者、*Bcc*暗送者
  2. 针对发送端的*From*最原始发信者、*Sender*其他发信者、*Reply-To*设置回信地址非原始地址。
+ 符合[MIME](https://en.wikipedia.org/wiki/MIME)规范的非文本附件

##明确邮件代理
**MUA（Mail User Agent）**：一个用于收发并管理邮件的用户客户端，仅仅在用户运行它的时候才会运作，一般运行在个人电脑（本地）上，
当发信时，MUA会去主动连接MSA或者MTA以处理用户的发信请求，MSA和MTA都采用了smtp协议，但是又有少许不同，比如MSA使用的是587端口而MTA使用的是25号端口。现在的验证模式基本不会由邮件服务器来直接管理允许发信者的IP地址，因为在公网IP资源不够用总是动态分配的情况下，这是不合理的。所以验证的工作会要求MUA提供用户名和密码在服务器端校验。当然也有一个非标准的SSL加密smtp协议，走的是465端口，但是兼容性很差，不予考虑。
当收信时，信件由MTA预先保留到mailbox下（一般是以mbox格式保存在用户家目录下），当MDA检测到MUA可以通讯的时候便将信件发送到客户端。客户端下载信件有两种独立的方法：一个是POP（Post Office Protocol），这种方法每当邮件从服务器下下载下来之后，服务器上不再保留邮件，只能下载一次，意味着不能多终端查看邮件，且无法对邮件标记为已查看、已回复或者已转发；另一种方法是IMAP（Internet Message Access Protocl），这个可以保留邮件到服务器上，那么上述的弊端就不见了。

**MSA（Mail Submission Agent）**：一个用户接收从MUA提交的电子邮件，并协助MTA做邮件传递工作的程序。目前很多的MTA已经包含了MSA的功能,*MSA处理发信的请求，MTA处理收信的请求*,这句话我査了很久，还是没有明白它们两个到底是如何分工的，MSA是否可以不依赖于MTA而单独工作，根据目前查到的信息来看，MSA仅仅是分立出来以获取以下几点好处，本身还是需要依赖MTA传递邮件的：

+ 因为MSA直接与MUA交互，所以可以修正邮件的一些格式上的错误，比如日期、邮件ID、收件人信息等。并且或许可以马上给写信人也就是客户端报告错误而不需要等到MTA已经把邮件发送完毕后才发现错误再向写信人报告，我认为这个是非常有用的。
+ 很多ISP和机构网络环境为了抑制垃圾邮件而限制了连接远程MTA上25端口的功能，MSA因为可以使用587端口，从而使得网络使用的灵活性大大提升。
+ MSA和MTA的分工工作方式可以让MTA拒绝邮件转发变得更加简单，只需要将收件人非指向本地服务域名的邮件当作垃圾处理即可。与此同时，MSA就需要接受发往互联网上任何收件地址的信息，好在可以设置仅接受已经验证过的发信客户端。
+ 还有就是MSA和MTA可以设置不同的策略用于屏蔽垃圾邮件。大多数的MSA需要完整的用户名和密码验证，通过这样子的机制就可以很轻易地发现发信者是谁，这样子如果有人发送了垃圾邮件，肯定是要为其负责的。因为在随机域名间建立信赖关系基本上是不可能的，也无法像上述通过用户和密码来验证不同域名间的用户关系（不然这个世界只要一个用户名就可以走天下了），所以被设置为收信的MTA就需要建立一个完整的垃圾邮件屏蔽机制（往往依赖本地的一些规则或者第三方的鉴定机构），为了区别垃圾邮件和合法邮件，同时也需要一个排错机制，毕竟系统有时候可能也会因为本地规则不完善或者第三方机构误收录而出错。这一点真的很重要，MSA和MTA分立后可以通过用户名密码验证基本忽略邮件提交程序的垃圾邮件检测。

**MTA（Mail Tansfer Agent）**：这个可以说是整个邮件系统的核心了，DNS下的MX记录也是指的提供MTA服务的主机。MTA可以从另一个MTA、一个MSA或者直接从MUA下获取邮件，通过SMTP协议传输邮件。当信件的收件人邮箱并非本机管理的时候，这个邮件就会被转发到另一个MTA（黑函可能就是这样子出现的），每转发一次，就会在邮件头信息添加一个跟踪记录（Received，越后添加的越靠前）。如何选择下一跳的MTA服务器是由SMTP协议描述的，不过MTA服务器本身也可以指定自定义路由。


##传统Mail Server结构图解(结合Postfix设置)
```
从发邮件到目的MTA收件：

                                        [smtp:25] 
MUA --------------MSA------------------- MTA:push --- ... --- MTA:pull
        main.cf:smtpd_client_restrictions-|                    |-main.cf:smtpd_sender_restricitons
     main.cf:smtpd_recipient_restrictions-|
        main.cf:smtpd_replay_restrictions-|
```

```
目的MTA分发邮件：

                                            MECHANISMS:
                                     via_mail_transform_agent,
                                     via_mail_delivery_agent,
                           direct_delivery_to_an_mbox_formatted_mailbox,
                              direct_delivery_to_a_maildir_directory,
                                          standard_output
                                                 |
(pull)MTA ------- MDA +++++++++++++++++++++++++ MRA ++++ MUA
                   |
       be_usually_invoked_by_MTA/MRA
```
