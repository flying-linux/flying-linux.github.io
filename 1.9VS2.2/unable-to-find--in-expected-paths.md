### 问题：
![](/assets/location_error.png)


### 表象：
Templates stored under  shared role are failing to be deployed from tasks in other roles.

This used to work fine in Ansible 1.9 and it's currently a major problem to migrate because of high number of templates we deploy that way , if we change that in our shared role it means once we update to Ansible v2 it will break the compatibility to run palybooks with version 1. .



### 原因：

 1.9 did some incorrect pathing that was never intended, proper pathing is the following:

src=<file> will search in order:

#if in role:
  rolename/templates/<file>

  rolename/tasks/<file>

  rolename/<file>
# always
play_dir/templates/<file>


play_dir/<file>

### 解决：

move the config file to proper path as above advised 

