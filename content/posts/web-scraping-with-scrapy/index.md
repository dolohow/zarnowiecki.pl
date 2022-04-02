---
title: "Web Scraping with Scrapy"
date: 2021-05-06T13:53:07+02:00
summary: "There are many ways to get data out of websites, but _Scrapy_
          is my favourite."
---
## Abstract
There are many ways you can get data out of websites. This is called web
scraping. The tool that really stands out is _Scrapy_. My go-to solution
for any web scraping project.

## Why?
You may ask why on Earth you want to scrape websites. One example that
comes to my mind is analysis. Let's say you want to get the average
price of AMG Mercedes from 2005. Perhaps there are websites that could
potentially give you this information. However, data could be outdated,
behind paywall or inaccurate. My solution is to take the most popular
website that sells cars, scrape it and perform my calculations.

Another example is when you want to buy a cheap, good car. I know,
impossible, but leveraging scraping you can be notified when an
interesting car is available. Honestly... Possibilities are endless.

## Evaluation of solution
Every time I want to achieve something, I would spend a significant
amount of time researching for already made solution. I hate reinventing
the wheel. If the project is promising, and it lacks features that I
need, I would work with the developer to make it better, so everybody
can benefit.  If we as society want to move forward, we need to
collaborate and solve problems that are yet to be solved or at least
improve existing solutions.

Web scraping is really boring, so a tool must be
  * elegant,
  * easy to use,
  * easy to debug,
  * allow other developers to extend it.

The last point is very important. If the project does that, and it is
quite popular, third party developers would make useful, general purpose
plugins.  For instance, when you scrape, you want to store it somewhere.
Perhaps it is out of scope for the project to do that, but someone else
could already make a plugin for it.

Enough talking, let's get some work done.

## Installing
NOTE: Always consult bellow commands with [official
documentation](https://docs.scrapy.org/en/latest/index.html) due to
nature of software development.

Create python virtual environment:
```
python -m venv venv
```

Activate it:
```
. venv/bin/activate
```

Install _Scrapy_:
```
pip install Scrapy
```

## Car scraping project
Let's create it, _Scrapy_ comes with built-in command to kick-start your
project:
```
scrapy startproject otomoto
```

Now it's time to generate spider:
```
scrapy genspider otomoto.pl otomoto.pl
```

This would create a spider from base template in
__otomoto/spiders/otomoto_pl.py__.

Now, I won't go into details of how to implement that particular spider,
because this is really well covered in [Scrapy
documentation](https://docs.scrapy.org/en/latest/index.html). But you
can visit my [scrapy-otomoto](https://github.com/dolohow/scrapy-otomoto)
project where I actually did just that. Actual spider implementation is
[here](https://github.com/dolohow/scrapy-otomoto/blob/master/otomoto/spiders/otomoto.py).

Nevertheless, I want to show you a few nice things about _Scrapy_
spiders.

You can use
[ItemLoaders](https://docs.scrapy.org/en/latest/topics/loaders.html)
in order to trim items or other kind of transformations

```python
def remove_spaces(x):
    return x.replace(' ', '')

def convert_to_integer(x):
    return int(x)

class OtomotoCarLoader(ItemLoader):
    price_out = Compose(remove_spaces, convert_to_integer)
```

The above example would take price, remove spaces and convert value to
integer.  What it does essentially it invokes every function in
_Compose_ with scraped price and feed output to next function like
compose pattern. Neat!

Another thing is to feed _follow_all_ with selector containing desired
links to parse that specific website under URL:
```python
yield from response.follow_all(css='.blog-posts a', callback=self.blog_post)
```
It would go to links in that css selector and fire method _blog_post_
with _response_ argument.

Then you can yield any data you want from it in that callback.

Want to quickly debug your selectors, run
```
scrapy shell <link to website>
```
and you will get a _response_ object on which you can experiment and when
you are certain that your selectors are working fine, paste them into
your code.

## Plug-ins
There are plenty of useful plug-ins also called middlewares in _Scrapy_
nomenclature that extends its functionality without you writing any
code.

Two most commonly used by me are
[scrapy-deltafetch](https://github.com/scrapy-plugins/scrapy-deltafetch) and
[scrapy-mongodb](https://github.com/sebdah/scrapy-mongodb).

Imagine a situation when you scraped some cars, and you would like to
run your crawler next day. You would end up with duplicates, and you
would need to filter them out somehow. With a bit of help from
_scrapy-deltafetch_ you can solve your problem without writing any
single line of code. All you have to do is:
```
pip install scrapy-deltafetch
```
And in your __setings.py__:
```python
SPIDER_MIDDLEWARES = {
    'scrapy_deltafetch.DeltaFetch': 100,
}

DELTAFETCH_ENABLED = True
```

And you are done.

The same applies to _scrapy-mongodb_, add one line to settings, and you
are done. All your data is now in _Mongo_ database and in order to run
_Mongo_ instance all you have to do is execute one _podman/docker_
command:
```
podman run -p 127.0.0.1:27017:27017 mongo
```
NOTE: I do not recommend running _Mongo_ like that in production.

## Conclusion
As the above examples show, you don't have to do much to have a nicely
working scraping solution with storage. Working with _Scrapy_ is a
breeze and provided abstractions, tools, plug-ins for commonly used
tasks prove to be a great solution for web scraping projects.
