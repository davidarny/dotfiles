[user]
    email = arutiunian666@gmail.com
;   signingkey = 290919B3A12CDD545A28E5D034A691143EA37346
    signingkey = ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGf6d4mihLXm97inbtY0vlhaTmJe3BzMfcq6lTRFnSdg

[gpg]
    format = ssh

[gpg "ssh"]
    program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"

[commit]
    gpgsign = true