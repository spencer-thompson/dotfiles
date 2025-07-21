<<<<<<< HEAD
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

See all TOIlet fonts:

```zsh
for font in $(ls -1 /usr/share/figlet/ | sed -r '/_/d; s/\..*//'); do echo $font; toilet -f "$font" -F rainbow "Spencer"; done
```
||||||| empty tree
=======
# My Dotfiles

they will probably not work on your machine


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

See all TOIlet fonts:

```zsh
for font in $(ls -1 /usr/share/figlet/ | sed -r '/_/d; s/\..*//'); do echo $font; toilet -f "$font" -F rainbow "Spencer"; done
```
>>>>>>> 9de3a8cb845c7a96487c8868b6ede854ca853f11
