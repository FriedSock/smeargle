
##About
git-off-my-lawn is a plugin for the vim text editor that allows
line-based choropleth mapping of the editor background, based on
statistics mined from the file's git repository.

##Installation

This plugin has been designed for compatability with
[fugitive](https://github.com/tpope/vim-fugitive) and
[vundle](https://github.com/gmarik/Vundle.vim) package managers — it
is highly recommended you use one if you do not already.

If you don't use either of those, simply clone the repository

    git clone http://github.com/FriedSock/git-off-my-lawn.git ~/.vim/bundle/git-off-my-lawn

And add the directory to your runtime path by adding this line to your
`.vimrc` file

    set rtp+=~/.vim/bundle/git-off-my-lawn
    
## Usage

By default — toggling of colouring schemes is mapped using the <leader> key.

To toggle the heat map use `<leader>l`, the jenks colouring scheme is mapped to `<leader>c` and colouring based on the commit author is mapped to `<leader>a`.

## Configuration

If you would like to change the default key bindings, it is easy to do so by adding a mapping to your .vimrc file. eg.

	nnoremap <leader>h :call HighlightAllLinesHeat()<cr>

The functions of interest for each mode are `HighlightAllLinesHeat()`, `HighlightAllLinesJenks()` and `HighlightAllLinesAuthor()` for the heatmap, jenks and author schemes respecitvely.
