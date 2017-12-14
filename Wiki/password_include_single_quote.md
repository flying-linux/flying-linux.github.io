#### 问题发现
某局点在使用DMK部署某个任务，当任务创建成功后，部署日志显示“playbook not generated, or missing”。
跟同事通过代码走读、日志定位，初步认为可能原因为：部署机器的`密码包含某个不能被expect正常处理的特殊字符`

#### 问题复现
DMK部署远端机器的认证过程采用`expect`方式，密码中包含特殊字符,使用`单引号包裹密码`传递给expect，能够`解决特殊字符转义`造成认证失败。若单引号包裹的密码中包含单引号，密码就早早被切断，就会引起问题吧。

将本地机器密码修改为`Test12'@123`，问题复现。

#### 问题确认
至此，问题转化为：expect交互如何传递特殊字符的密码？

#### 问题解决
针对单引号，增加反转义，提示鉴权错误，证明加完反转义后，密码变了。
同事建议：转义的密码前，加`$`号，完美解决。
shell中`$''`表示：引用内容展开，执行单引号的转义内容。
```
> echo $'Test\'12#$'
Test'12#$
```
测试过程中，再发现问题，若密码中包含`\'`或者`\\`组合，依旧有问题。需要再为'\'加反转义。

ruby写的转义函数：
```
def escape(passwd)
  if passwd.present?
     passwd = passwd.gsub(%q(\\), %q(\&\&))
     passwd = passwd.gsub("'", %q(\\\'))
   end
     passwd
end
```

#### 自动化测试 - ruby代码
[随机生成密码，修改部署节点密码，测试expect和Ansible执行](http://code.huawei.com/snippets/802)


#### 附
[shell下随机密码生成](https://unix.stackexchange.com/questions/182382/generating-a-random-password-why-isnt-this-portable)：
```
dmk@DMK01:~> passwd=`</dev/urandom LC_ALL=C tr -dc '[:print:]' | head -c 30`
dmk@DMK01:~> echo $passwd
8u4br*7LC1h!t#iq*<Wm3q76=^Y@e~
```


