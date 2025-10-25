## Setup Tmux

### Resources
- https://github.com/tmux-plugins/tpm (Plugin manager)
- https://github.com/catppuccin/tmux (Theme)

### Install Fonts (Optional) 
- https://www.nerdfonts.com/font-downloads and download Nerd Font
- Unzip the downloaded (e.g. Hack.zip) and move or copy the directory to `~/.local/share/fonts`
- Run `fc-cache -fv` to refresh the font cache.

### Setup

- Install Tmux:

```shell
sudo dnf install tmux
```

- Install xclip:

```shell
sudo dnf install xclip
```

- Configuration:

```shell
## Setup Tmux Plugin Manager
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

## Setup Tmux
mkdir -p ~/.config/tmux
touch ~/.config/tmux/tmux.conf

cat <<EOF > ~/.config/tmux/tmux.conf
# Enable Mouse
set -g mouse on

# VIM motions
set-window-option -g mode-keys vi
bind-key -T copy-mode-vi 'v' send -X begin-selection
bind-key -T copy-mode-vi 'y' send -X copy-pipe-and-cancel "xclip -selection clipboard"

# Enable Mouse Dragging
unbind -T copy-mode-vi MouseDragEnd1Pane

# Status Line Position
set-option -g status-position top

set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'crhistoomey/vim-tmux-navigator'
set -g @plugin 'tmux-plugins/tmux-resurrect'

run '~/.tmux/plugins/tpm/tpm'
EOF
```

- Enter to Tmux

```shell
tmux
```

### Commands

#### Windows
- <prefix> c => New Windows
  - <prefix> 3 => Switch to windows number 3
  - <prefix> n => Switch Next windows
  - <prefix> p => Switch Previous windows
  - <prefix> & => Delete Current windows

#### Panels
- <prefix> % => Split horizontal
- <prefix> " => Split vertical
- <prefix> ←↑→↓ => Move between panels
- <prefix> {} => Move panel position
- <prefix> q => Select panel by number
- <prefix> z => Focus on current panel
- <prefix> ! => Turn panel into a windows
- <prefix> x => Close panel

#### Sessions
- tmux new -s my-session => Creates new session
- tmux ls => List sessions
- tmux attach => Attach to the most recent session
- tmux attach -t my-session => Attach to session
- <prefix> s => Select session


