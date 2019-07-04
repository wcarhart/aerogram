# [aerogram](https://en.wikipedia.org/wiki/Aerogram)
Serverless chat via ssh - send messages via ssh without the pain of setting up a server.

### Demo
![GIF of demo](demo.gif)

### Usage
```
$ ./aerogram.sh -h
Send messages to remote users via SSH/SCP

Usage:
  aerogram.sh RECEIVER@IP [-h/--help] [-p/--port PORT] [-u/--user USER] [-r/--recv] [-d/--disp NAME]

Required arguments:
  RECEIVER        - the username for the user you'd like to chat with
  IP              - the IP address for the user you'd like to chat with

Optional arguments:
  -h, --help      - display this help menu and exit
  -p, --port PORT - the port to use (default is '22')
  -u, --user USER - the name of the user you'd like to ssh login as 
                    (default is your username)
  -r, --recv      - run aerogram in receive-only mode, where you can only receive messages
  -d, --disp NAME - your display name (default is your username)

Notes:
  - both you and the RECEIVER must be running aerogram.sh
  - you don't need to know RECEIVER's ssh credentials, but you do need to know
    USER's ssh credentials
  - it is HIGHLY recommended that you add your SSH keys to your RECEIVER so you
    don't have to type in your password every time you send a message
```

### Examples
Send messages to user *Mike* at IP address 147.0.28.48:
```
./aerogram.sh Mike@147.0.28.48
```
`ssh` into the recipient machine as a different user than the current one when sending messages:
```
./aerogram.sh user@123.4.53.23 --user wcarhart
```
Send messages using port 1022 (instead of the default port 22 for `ssh`):
```
./aerogram.sh user@123.4.53.23 --port 1022
```
Run `aerogram` in *receive-only* mode:
```
./aerogram.sh user@123.4.53.23 -r
```

### Chat commands
`/color COLOR` - Change your color in the chat (supported colors are *red*, *blue*, *green*, *yellow*, *pink*, *teal*, *white*, *grey*, and *help*.

`/help` - Display the supported chat commands.

`/exit` - Quit the chat.

### Install
1. Clone this repo with: `git clone https://github.com/wcarhart/aerogram.gif`
2. Run `./aerogram.gif` for the above help menu.

### FAQs
**How do I send messages between two machines?**

The basic syntax is: `aerogram.sh USER@IP`, where `USER` is the user you'd like to chat with at IP address `IP`.

**What is necessary for sending messages between two machines with `aerogram`?**

If you can `ssh` into another machine, `aerogram` will function properly. Note that for two machines to be able to send messages to each other, they will *both* have to be able to `ssh` into each other.

**What setup is required?**

No setup! `aerogram` will alert you if your environment isn't configured correctly, and how to fix it. It is **highly** suggested that you add your `ssh` keys via `ssh-keygen` to the desired host so you don't have to enter your password every time you send a message. If you don't know how to do this, follow [this tutorial](https://askubuntu.com/a/46935/838525).

**Yes, but what are the *actual* requirements?**
* Only supported for *Bash* on *MacOS* or *Linux*.
* Recipient machine must have directory `~/.aerogram`, created when the recipient runs `aerogram`.
* `~/.aerogram` directory on the recipient machine must be readable and writeable for the other (xx6 or xx7).
* `ssh` must be enabled on the recipient machine for the sending user on the local machine (the user specified via `--user`).
* `aerogram.sh` must have execute permissions for the current user.
* `aerogram_renderer.sh` must have execute permissions for the current user.
* `aerogram_listener.sh` must have execute permissions for the current user.
* **highly recommended**: using passwordless `ssh` via RSA keys.

**What if I want to log into the recipient machine as a user other than my current one?**

`aerogram` supports this. Use the `-u USER` or `--user USER` option. The default is the output of `whoami`, or the current user on your local machine.

**What if my username is very long? Can I shorten it during the chat?**

Yes, use the `-d NAME` or `--disp NAME` option to set your desired display name.

**What if I only want to receive messages, and not send them?**

`aerogram` supports this as well. Use the *receive-only* mode by specifying the `-r` or `--recv` option, like so: `aerogram.sh -r`.

**Are there any commands in the chat?**

Yes, the currently supported commands are `/color`, `/help`, and `/exit`.

**How does `aerogram` work?**

`aerogram` piggybacks off the capabilities of `scp` to send messages. The actual program spins up a listener in the background and a renderer in the foreground. When messages are sent and received, each message moves through one of three states: *new*, *ready*, and *done*. As the messages are processeed, the renderer displays the contents in the chat and moves the messages to the *done* state.

**What is an aerogram?**

Traditionally, an [aerogram](https://en.wikipedia.org/wiki/Aerogram) is a thin, lightweight piece of foldable paper for writing a letter for transit via airmail, in which the letter and envelope are one and the same. Given that `aerogram` is lightweight and requires no server, I thought this was an apt name for the program.
