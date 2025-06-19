+++
date = '2025-06-14T16:51:33-03:00'
draft = false
title = 'SSH Ask Pass: using passwords seamlessly'
image = '/img/posts/ssh-ask-pass.png'
summary =  'This article explains how to set up automatic decryption of SSH keys and how to encrypt them'
tags = [
    "linux",
    "security",
    "ssh",
    "gpg",
]
+++

# How to set up automatic ssh passwords

## SSH Keys vs Passwords

There is an ongoing/settled debate between SSH keys and passwords, though it is fairly widespread the
notion that SSH keys are more secure. I'm not going to go that deep into that debate, I don't really
have anything to contribute. Suffice it to say that I use keys, not passwords.

And I assume you use them too.

## Why have a password on a key?

On the three paradigms of "Something you know, something you have, something you are", SSH keys fall
on the second category, meaning anyone with that key can log into your server. By adding a password
to it, you are adding one more category: "Something you know".

Furthermore, if that password comes from another 'secure program'(whatever that means), like `gpg`,
you are adding another ring to the chain.

For example: Imagine that you manage you passwords using
GPG smartcard with your private key inside, and you use that private key to encrypt the SSH password,
you will have then:
```
(Smth you know)       (Smth you have)   (Smth you(can) know)  (Smth you have)
Your GPG password --> Smartcard ------> SSH Password -------> SSH Key -------> Server Access
                      (Maybe something
                      you are, if using
                      biometrics)
```

Ultimately, this setup is very extensible/customizable, you and add or remove layers as you see fit.

## Managing the key automatically

To manage the keys we will need 3 steps:
- ASKPASS script
- Environment variables to control SSH
- Encrypt the keys

After the first 2 steps, every time that you try to decrypt/encrypt a key SSH will use your program, meaning that
you wont have to type it.

### Creating an ASKPASS script
Now, let us create a script to retrieve the ssh password.

The only thing it needs to do is print out the password, so it could be any password manager `decrypt`
command or even a `gpg --decrypt`. In any case, create a script with that command:
```
#!/bin/sh
<command>
```
Drop it in your `$PATH` and remember its name (I'll call it `sshpass`).

Also, in my case `pass` is the password manager of choice, so the `command` here is: `pass <path>`.

### Setting up environment variables

Now that we have a program in place we need to set 2 variables:
```
# Drop it in you .bashrc(or equivalent)
export SSH_ASKPASS="sshpass"
export SSH_ASKPASS_REQUIRE=prefer
```
From the documentation:
```
       SSH_ASKPASS           If  ssh  needs a passphrase, it will read the passphrase from the current terminal if it was run
                             from a terminal.  If ssh does not have a terminal associated with it but DISPLAY and SSH_ASKPASS
                             are set, it will execute the program specified by SSH_ASKPASS and open an X11 window to read the
                             passphrase.  This is particularly useful when calling ssh from a .xsession  or  related  script.
                             (Note  that  on  some  machines it may be necessary to redirect the input from /dev/null to make
                             this work.)

       SSH_ASKPASS_REQUIRE   Allows further control over the use of an askpass program.  If this variable is set  to  “never”
                             then  ssh  will never attempt to use one.  If it is set to “prefer”, then ssh will prefer to use
                             the askpass program instead of the TTY when requesting passwords.  Finally, if the  variable  is
                             set  to  “force”,  then  the askpass program will be used for all passphrase input regardless of
                             whether DISPLAY is set.
```

Unfortunately, `SSH_ASKPASS` doesn't take any arguments, it has to be only the script name.

Note: the manual for those variables can be accessed using: `man ssh`.

### How to check if its encrypted

Given that your ssh is configured to automatically retrieve the password, and you have those two variables
set into `.bashrc`, use this to disable them temporarily:
```
unset SSH_ASKPASS
unset SSH_ASKPASS_REQUIRE
```

Now use this command to check if a key has a password:
```
ssh-keygen -y -f <key>
```
The `-y` flag prints out the public key part, if the private has a password the program will open a prompt,
if not the public key will just go to stdout.

### How to encrypt a key

To encrypt a key use this command:
```
ssh-keygen -p -f <key>
```
If you went through the previous steps, no password prompt is required, SSH will automatically retrieve the
password.

