# My Dotfiles

These are my main configs currently

## How to use

```
git clone --recurse-submodules
```

Personal note: `git push --recurse-submodules`

---

Useful commands:

List Unused
```
pacman -Qtdq
```

Remove Unused
```
sudo pacman -R $(pacman -Qtdq)
```

Update Default Directories
```
xdg-user-dirs-update --set DOWNLOAD ~/dl
```
*and others*
