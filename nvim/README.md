# Neovim

- Install Neovim

```shell
sudo dnf install neovim
```

- Install helpers

```shell
sudo dnf install luarocks fzf ripgrep
```

- Setup configuration

```shell
git clone git@github.com:carlosthe19916/nvim.git ~/.config/nvim
```

### Install Fonts

Based on https://blog.khmersite.net/p/installing-nerd-font-on-fedora/

- Download Fonts from [NerdFonts Download](https://www.nerdfonts.com/font-downloads)
- Unzip the file and move the content to `~/.local/share/fonts`
- Refresh the font cache `fc-cache -fv`
- Verify the installed fonts `fc-list : family style | grep -i nerd`

```shell
curl -o /tmp/Hack.zip -L https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip
curl -o /tmp/Icons.zip -L https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/NerdFontsSymbolsOnly.zip 
unzip /tmp/Hack.zip -d ~/.local/share/fonts/
unzip /tmp/Icons.zip -d ~/.local/share/fonts/
fc-cache -fv
```

### Commands
- `:Lazy`: See plugins

