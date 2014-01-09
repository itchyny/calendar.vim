# A calendar application for Vim
### Vim meets a next generation application

![calendar.vim](https://raw.github.com/wiki/itchyny/calendar.vim/image/image.png)

Press E key to view the event list, and T key to view the task list.

![calendar.vim](https://raw.github.com/wiki/itchyny/calendar.vim/image/views.png)

## Basic Usage

    :Calendar

![calendar.vim](https://raw.github.com/wiki/itchyny/calendar.vim/image/image0.png)

    :Calendar 2000 1 1

![calendar.vim](https://raw.github.com/wiki/itchyny/calendar.vim/image/image1.png)

    :Calendar -view=year

![calendar.vim](https://raw.github.com/wiki/itchyny/calendar.vim/image/image2.png)

    :Calendar -view=year -split=vertical -width=27

![calendar.vim](https://raw.github.com/wiki/itchyny/calendar.vim/image/image3.png)

    :Calendar -view=year -split=horizontal -position=below -height=12

![calendar.vim](https://raw.github.com/wiki/itchyny/calendar.vim/image/image4.png)

    :Calendar -first_day=monday

![calendar.vim](https://raw.github.com/wiki/itchyny/calendar.vim/image/image5.png)

    :Calendar -view=clock

![calendar.vim](https://raw.github.com/wiki/itchyny/calendar.vim/image/image6.png)

You can switch between views with &lt; and &gt; keys.

## Concept
This is a calendar which is ...

### Comfortable
The key mappings are designed to match the default mappings of Vim.

### Powerful
The application can be connected to Google Calendar and used in your life.

### Elegant
The appearance is carefully designed, dropping any unnecessary information.

### Interesting
You can choose the calendar in Julian calendar or in Gregorian calendar.

### Useful
To conclude, very useful.

## Author
itchyny (https://github.com/itchyny)

## License
MIT License

## Installation
### Manually
1. Put all the files under $VIM/

### pathogen-vim (https://github.com/tpope/vim-pathogen)
1. Execute the following command.

        git clone https://github.com/itchyny/calendar.vim ~/.vim/bundle/calendar.vim

### Vundle (https://github.com/gmarik/vundle)
1. Add the following configuration to your vimrc.

        Bundle 'itchyny/calendar.vim'

2. Install with `:BundleInstall`.

### NeoBundle (https://github.com/Shougo/neobundle.vim)
1. Add the following configuration to your vimrc.

        NeoBundle 'itchyny/calendar.vim'

2. Install with `:NeoBundleInstall`.

## Google Calendar and Google Task
In order to view and edit calendars on Google Calendar, or task on Google Task,
add the following configurations to your vimrc file.
```vim
let g:calendar_google_calendar = 1
let g:calendar_google_task = 1
```
It requires `wget` or `curl`.


## Terms of Use
Under no circumstances we are liable for any damages (including but not limited to damages for loss of business, loss of profits, interruption or the like) arising from use of this software.
This software deals with your events and tasks.
We are not liable for any circumstances; leakage of trade secrets due to the cache files of this software, loss of important events and tasks due to any kind of bugs and absence from important meetings due to any kind of failures of this software.
This software downloads your events from Google Calendar, and your tasks from Google Task.
DO NOT use this software with important events and tasks.
This software downloads your events or tasks to the cache directory.
Please be careful with the cache directory; DO NOT share the directory with any cloud storage softwares.
This software also uploads your events and tasks to Google APIs.
While it uses https, but DO NOT use this software for confidential matters.
This software NEVER uploads your events and tasks to any other server except Google's.
However, if `wget` or `curl` command are replaced with malicious softwares, your events or tasks can be uploaded to other sites.
Please use the official softwares for the commands.
