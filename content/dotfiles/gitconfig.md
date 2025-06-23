+++
date = '2025-06-23T19:23:10-03:00'
draft = false
title = 'Gitconfig'
summary =  'My git config file'
[params]
    dotfile = true
+++

```git
[user]
    email         = <email>
    name          = <githubname>
    signingkey    = <sign_key_id>
[alias]
    unstage       = restore --staged
    sdiff         = diff --staged
    rbc           = rebase --continue
    amd           = commit --amend --no-edit
    amde          = commit --amend --edit
    pl            = pull
    psf           = push --force
    pst           = push --tags
    pstf          = push --tags --force
    psd           = push -n
    cp            = cherry-pick
    cpc           = cherry-pick --continue
    ps            = push
    rmt           = remote
    aa            = add --all
    co            = checkout
    mc            = merge --continue
    m             = merge
    br            = branch
    b             = branch
    bra           = branch --all
    cmt           = commit -m
    st            = status
    lg            = log
    l             = log --graph --decorate --pretty='format: %C(auto)%h %Cgreen%ah%Creset %cn %C(auto)%d %s %Creset'
    ls            = log --graph --decorate --first-parent --pretty='format: %C(auto)%h %Cgreen%<(17)%ah%Cblue %<(10,trunc)%cn %Creset%s%Creset%C(auto)%d'
    lsa           = log --graph --decorate --first-parent --pretty='format: %C(auto)%h %Cgreen%<(17)%ah%Cblue %<(10,trunc)%cn %Creset%s%Creset%C(auto)%d' --all
    la            = log --graph --decorate --all
    gr            = log --graph --decorate
    grs           = log --graph --first-parent
    gra           = log --graph --decorate --all
    h             = help
    a             = add
    t             = tag -s
    prl           = "!export GITHUB_TOKEN=$(<get_token_command>); gh pr list"
    dev           = "!mergedev() { BRANCH=$(git branch --show-current); git checkout development; git pull; git merge --no-edit $BRANCH; git push; git checkout $BRANCH; }; mergedev"
    rel           = "!export GITHUB_TOKEN=$(<get_token_command>); gh pr create -fB release"
    stg           = "!export GITHUB_TOKEN=$(<get_token_command>); gh pr create -fB staging"
    prod          = "!export GITHUB_TOKEN=$(<get_token_command>); gh pr create -fB production"
    qa            = "!export GITHUB_TOKEN=$(<get_token_command>); gh pr create -fB qa"
    c             = "!commit() { CMT=$1; shift; BRANCH=$(git branch --show-current); MESSAGE=\"$BRANCH: $CMT\"; git commit -m \"$MESSAGE\" $@; }; commit"
    psn           = "!git push -u origin $(git branch --show-current);"
    psnf          = "!git push -u origin $(git branch --show-current) --force;"
    nb            = "!newbranch() { if [ -z $1 ]; then echo 'missing branch name'; exit 1; fi; BRANCH=$1; git checkout production; git pull; git checkout -b $BRANCH; }; newbranch"
    cmtd          = "!git commit -m $(date -u +%s);"
[pretty]
    customoneline = format: %C(auto)%h %Cgreen%<(17)%ah%Cblue %<(10,trunc)%cn %Creset%s%Creset%C(auto)%d
    customfull    = format:%C(auto)%h %D%Creset %n  %s%n    Parents: %p%n	%Cgreen%ad%C(auto) %aN <%aE>%n    %Cblue  %G? %GS [%GF]%n
[format]
    pretty        = customoneline
[commit]
    gpgsign       = true
[gpg]
    program       = gpg2
[blame]
    date          = human
```
