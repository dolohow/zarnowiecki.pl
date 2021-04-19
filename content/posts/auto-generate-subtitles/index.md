---
title: "How-to quickly create subtitles from ground zero"
summary: "Often times you will find yourself having a need for
          subtitles. Let us find out the quickest and the least painful
          way to do it."
date: 2021-04-18T21:44:43+02:00
draft: false
---
## Abstract
Often times you will find yourself having a need for subtitles. Either
it is for your YouTube video or... I don't know.

The old way was to create an empty file and with help of some program
start making subtitles. Writing down the text. Manually selecting
starting and ending position. Going back and forth for adjusting.
Translating. It was very mundane work.

Fear not, we have a 21st century, and you can help yourself with modern
AI.

## Prerequisites
  * Linux (most likely)
  * ffmpeg
  * Python
  * PIP

It should also be possible on Windows, but you are on your own.

## Software installation
We will use _autosub_ for AI and _subtitleeditor_ for some final cuts.

_autosub_:
```
pip install git+https://github.com/BingLingGroup/autosub.git@alpha ffmpeg-normalize langcodes
```

_subtitleeditor_ should be in your repo, in my case I use Arch BTW, so:
```
pacman -S subtitleeditor
```

Will do the trick.


## Auto generating subtitles from movie file
This will generate polish subtitles from video file with polish audio
source. Just type:
```
~/.local/bin/autosub -i MOVIE_FILE -S pl
```
And the magic begins.  Subtitles will be auto generated and place along
your __MOVIE_FILE__.

## Adjusting
Now open new project with _subtitleeditor_ and begin editing. To help
yourself with identifying speech regions, which could be mixed up,
generate waveforms.

When you select subtitle line click on waveform with your left mouse
button, and you will adjust the start of subtitles while right-clicking
will set the end time. If you want to delete a particular line,
_ctrl+delete_ will do the trick.

{{< figure src="subtitleeditor.png" link="subtitleeditor.png" title="Subtitle Editor" >}}

Once you are done, save the file.

## Translating
Now we want to translate to English. That is easy as:
```
~/.local/bin/autosub -i SUBTITLE_FILE -SRC pl -D en
```

## Adjusting translation
Now there are two ways I can do it that I like. First, you can open
translation with _subtitleeditor_ (_ctrl+t_) and edit there or use vim
with side-to-side view of Polish and English subtitles.

### Subtitleeditor workflow
{{< figure src="subtitleeditor_translation.png" link="subtitleeditor_translation.png" title="Subtitle Editor translation view" >}}
Can't be easier than that.

### Vim workflow
Note: If you do not know vim, just use _subtitleeditor_.

First, let's open both files:
```
vim POLISH_SUB ENGLISH_SUB
```
Now execute _ctrl+w v_ and it will open side-by-side.  In both windows
it is a good idea to enable spellchecking. You can jump between windows
using _ctrl+w w_

```
:set spell
:set spelllang=pl
```

Last thing, let's enable synchronisation scrolling between windows. In
both, execute:
```
:set scrollbind
```

## Summary
Some really cool projects can make the life of subtitle creators much easier
with the help of new technologies. Having subtitles can enable people with
disabilities to enjoy content around the globe that would be in the other case
unreachable. Once your content is ready, you can put little effort into making
it more accessible.

