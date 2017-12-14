#### 问题：
```
ssh connection closed waiting for a priviledge escalation password prompt
```

#### 原因：

* sudo/su等提权操作要有系统密码交互过程，切至root失败

* sudoers文件配置错误，导致`sudo su - root`无法切换至root用户


#### 解决：

登录host机器，并尝试切换至root用户，查看是否提示输入root密码，并能切换成功。

#### [账号验证](/dmk/validate_user_guide.md)成功了吗？
