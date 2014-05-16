
##About
smeargle is a plugin for the vim text editor that allows
line-based choropleth mapping of the editor background, based on
statistics mined from the file's git repository.

##Installation

This plugin has been designed for compatability with
[Pathogen](https://github.com/tpope/vim-pathogen) and
[Vundle](https://github.com/gmarik/Vundle.vim) package managers — it
is highly recommended you use one if you do not already.

If you don't use either of those, simply clone the repository

    git clone http://github.com/FriedSock/smeargle.git ~/.vim/bundle/smeargle

And add the directory to your runtime path by adding this line to your
`.vimrc` file

    set rtp+=~/.vim/bundle/smeargle

## Usage

By default — toggling of colouring schemes is mapped using the `<leader>` key.

To toggle the heat map use `<leader>h`, the jenks colouring scheme is mapped to `<leader>j` and colouring based on the commit author is mapped to `<leader>a`. Or to just clear any current colouring: hit `<leader>c`


## Configuration

If you would like to change the default key bindings, it is easy to do so by adding a mapping to your .vimrc file. eg.

	let g:smeargle_heat_map   = '<c-h>'

The functions of interest for each mode are `g:smeargle_heat_map`, `g:smeargle_jenks_map` and `g:smeargle_author_map` for the heatmap, jenks and author schemes respecitvely.

Note: If you already have existing mappings for `<leader>h`, `<leader>j` then the plugin will not overwrite them, so you **will** need to add these mappings to your `.vimrc` file.

Alternatively you can add the mapping explicitly such as:

	nnoremap <silent><c-h> :SmeargleHeatToggle<cr>
Which will work also. The commands of interest are `:SmeargleHeatToggle`, `:SmeargleJenksToggle` and`:SmeargleAuthorToggle`

###Load
By default, smeargle will load up the jenks colour scheme on file open. You may change this functionality with the `g:smeargle_colouring_scheme` option. With `'jenks'`, `'heat'` or `'author'` as the possible options. You may also choose to not have a colour scheme load on file open, by setting the option to empty string.

	let g:smeargle_colouring_scheme = ''

###Timeout

Sometimes for very large files, it may take a number of seconds to generate the colouring scheme you want (This is particularly true of the jenks natural breaks). By default, smeargle will timeout the computation after 1 second of waiting. If you think this is too long or too short, this is configurable with the `g:smeargle_colour_timeout` option.
