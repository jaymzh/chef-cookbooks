fb_ssh Cookbook
===============
Installs and configures openssh

Requirements
------------

Attributes
----------
* node['fb_ssh']['manage_packages']
* node['fb_ssh']['sshd_config'][$CONFIG]
* node['fb_ssh']['ssh_config'][$CONFIG]
* node['fb_ssh']['enable_central_authorized_keys']
* node['fb_ssh']['authorized_keys_users']
* node['fb_ssh']['enable_central_authorized_principals']
* node['fb_ssh']['authorized_principals'][$USER][$KEYNAME]
* node['fb_ssh']['authorized_principals_users']

Usage
-----
### Packages
By default `fb_ssh` will install and keep updated both client and server
packages for ssh.

You can skip package management if you have local packages or otherwise need to
do your own management by setting `manage_packages` to false.

### Server configuration (sshd_config)
The `sshd_config` hash holds configs that go into `/etc/ssh/sshd_config`. In
general each key can have one of three types, bool, string/ints, or array.

Bools are translated into `yes`/`no` when emitted into the config file. These
are straight-forward:

```
node.default['fb_ssh']['sshd_config']['PubkeyAuthentication'] = true
```

Becomes:
```
PubkeyAuthentication yes
```

Strings and ints are always treated like normal strings:

```
node.default['fb_ssh']['sshd_config']['ClientAliveInterval'] = 0
node.default['fb_ssh']['sshd_config']['ForceCommand'] = '/bin/false'
```

Becomes:
```
ClientAliveInterval 0
ForceCommand /bin/false
```

Arrays will be joined by spaces. It's worth noting that while this feature is
here to make management easy, one could clearly take a multi-value value key
and make it a string and it would work, but we support arrays to make modifying
the value later in the runlist easier. For example:

```
node.default['fb_ssh']['sshd_config']['AuthorizedKeysFile'] = [
  '.ssh/authorized_keys',
  '.ssh/authorized_keys2',
]
```

Means later it's easy for someone to do:

```
node.default['fb_ssh']['sshd_config']['AuthorizedKeysFile'].
  delete('.ssh/authorized_keys2')
```

or:
```
node.default['fb_ssh']['sshd_config']['AuthorizedKeysFile'] <<
  '/etc/ssh/authorized_keys/%u'
```

So be careful to be consistent about this.

### Match Values
All match rules in sshd must come at the end, because Match blocks take effect
until the next match block, or the end of the file - indentation is irrelevant.

You can use Match rules as normal. This cookbook will automatically move them
to the end of the file and keep them in the order that the users specified
them.

This means that unlike the other keys which are sorted for easier diffing,
these are not sorted. As such, changing the order of your cookbooks could
change the order of your match statements, so be careful.

Match statements are the exception to the datatype rule above - their value is
a hash, and that hash is treated the same as the top-level sshd_config hash:

```
node.default['fb_ssh']['sshd_config']['Match Address 1.2.3.4'] => {
  'PasswordAuthentication' => true,
}
```

#### Authorized Principals

If you set `enable_central_authorized_principals` to true, then two things will
happen:
1. Your AuthorizedPrincipalsFile will be set to `/etc/ssh/authorized_princs/%u`,
   regardless of what you set it to
2. The contents of `node['fb_ssh']['authorized_principals']` will be used
   to populate `/etc/ssh/authorized_princs/` with one file for each
   user. To limit which users are populated, simply populate the list
   `node['fb_ssh']['authorized_principals_users']`. The format of the
   `authorized_principals` attribute is:

```
node.default['fb_ssh']['authorized_principals'][$USER] = ['one', 'two']
```

#### Authorized Keys

These work similarly to Authorized Principals. If you set
`enable_central_authorized_keys` to true, then two things will happen:
1. Your AuthorizedKeysFile will be set to `/etc/ssh/authorized_keys/%u`,
   regardless of what you set it to
2. The contents of the databag `fb_ssh_authorized_keys`
   will be used to populate `/etc/ssh/authorized_keys/` with key files for each
   user. To limit which keys go on a user, simply populate the list
   `node['fb_ssh']['authorized_keys_users']`. The format of the items
   in databag is:

```
{
  'id': $USER,
  'keyname1': $KEY1,
  'keyname2': $KEY2,
  ...
}
```
    
There should be one item for each user, as many keys as you'd like may
be in that item.

### Client config (ssh_config)
The client config works the same as the server config, except the special-case
is `Host` keys instead of `Match` keys. As an example:

```
node.default['fb_ssh']['ssh_config']['ForwardAgent'] = true
node.default['fb_ssh']['ssh_config']['Host *.cool.com'] = {
  'ForwardX11' => true,
}
```