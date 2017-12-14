### 问题：
timeout, ssh closed 

### 表象：

### 原因：
单个task执行时间比较长，ssh会断开

### 解决：
1. 设置Timeout值          

修改执行的脚本，比如install.sh，在脚本第二行增加：export ANSIBLE_TIMEOUT=300



2. 对于long task，设置async

```
- name: untar
  shell: xxxxxx
  async: 1800     #1800秒，可根据实际情况估算此任务所用时间
  poll: 30        #30秒，返回一次结果
```


![](/assets/long_task.png)


>建议使用第二种方法
