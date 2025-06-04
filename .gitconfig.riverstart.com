
[user]
    email = d.arutyunyan@riverstart.ru
    signingkey = ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE1HOMjn3t6j+l9Kep93uNjLb6won5SCntbpptrERc2S

[gpg]
    format = ssh

[gpg "ssh"]
    program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"

[commit]
    gpgsign = true
