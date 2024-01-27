---
layout: post
title: Optimizing Variable Fonts For Web
permalink: /posts/:year/:month/:slug
tags:
  - webdev
description: I used to take pride that my blog was beneath a certain size, but that changed when I used a variable font. However, I managed to optimize it to be even smaller than before!
---
## Why Worry About Website Size?

A while back I added this blog to an online list of websites called the [512KB club](https://512kb.club/). As the name implies, all of the sites on this list when loaded require under 512KB of resources. Within this overall list, sites are separated into various "clubs" based on what site they manage to stay under:

```
Green Club  < 100KB
Orange Club < 250KB
Blue Club   < 500KB
```

Reaching the Blue Club is super easy as long as you're not using a website builder. In my personal experience, Wix websites load a minimum of 2MB+ which is made worse by the fact that they don't automatically compress/convert images to web optimized formats.

The orange club is slightly harder to get into since it requires you to limit the amount of images and JavaScript libraries you use with your site. I'd argue that limiting the amount of images is a good thing since it allows for a bigger focus on the actual content you're trying to convey.

However, it is exceptionally tough to make a site within the Green Club's requirements. Even the 512KB Club's own site is not in this club due to the sheer amount of HTML it has from listing all the members. Having your site look good by modern standards and maintain a size beneath this threshold is an achievement that worth commending. 

While this might seem like a list for just something kinda dumb, I'd argue it encourages something in dire need nowadays. In the year 2024 the web is increasingly mobile driven and unlike with a desktop at home/work, you can't guarantee the strength and speed of your connection to the internet. If you have an internet based business it is critical that your connection to your consumers is as resistant to poor networks as possible or else you might lose out on valuable profits. Additionally, by lowering the amount of time spent by devices transferring and receiving data some amount of energy is saved helping contribute towards reducing climate change. At an individual level this is a tiny amount of energy, but at the level of billions upon billions of requests made online per year this adds up significantly.

As such, I was beyond proud when I added my site to this club and had it join the Green Club despite having a look and feel like no other site I had encountered. However that soon changed...

## The Lure of Variable Fonts

It was sometime in November/December 2023 when I had decided to change the fonts I used on my site. I didn't think its previous look was bad, but it just wasn't distinctive enough for what I wanted.

While searching for replacements I had read about about variable fonts, but I hadn't understood their appeal. That was the case until I read an article on [how to use them with basic CSS](https://www.digitalocean.com/community/tutorials/css-variable-fonts) that had some great CodePen examples, then it clicked for me. 

Immediately I searched through [Google Font's selection of variable fonts](https://fonts.google.com/?vfonly=true) and settled upon [Red Hat Display](https://fonts.google.com/specimen/Red+Hat+Display?query=red+hat+&vfonly=true). Despite some of my misgivings about the company, it was free/open-source in addition to being simple yet futuristic. Adding it and implementing some of the features shown off in that article to my site made it glimmer to my eyes.

There was just one problem... Instead of the ~30kb or so my old fonts took up, I was now looking at 200kb! This knocked me clear off the 512KB green team and onto the edge of the blue team.
## Optimizing a Variable .tff font

Simply put, subsetting a font is removing all the characters you don't need from it. Professional fonts contain hundreds of characters for various languages, mathematical notations, special symbols, and various other reasons. For a blog such as mine that is written with just standard English words, does not use characters for special features, and has a need for being lightweight, it's only natural to use subsetting.

<picture>
    <source srcset="https://ik.imagekit.io/jlo64/www_julianlopez_net/2024-01-16-Pasted_image_aai9my4IX?tr=w-720,f-webp," type="image/webp">
    <img src="https://ik.imagekit.io/jlo64/www_julianlopez_net/2024-01-16-Pasted_image_aai9my4IX?tr=w-480" alt="A screenshot of FontForge displaying various characters within a font." class="blog_image" title="A screenshot of FontForge displaying various characters within a font.">
    <figcaption style="text-align:center">I can guarantee that I will never most of the characters in this image.</figcaption>
</picture>

Initially I tried using [this method to remove characters](https://www.grantojanen.com/videos/pg/optimize-fonts.html) I didn’t need, but 
despite successfully using it in the past I couldn't get it to work with this type of font. It seems that FontForge doesn’t work with variable fonts directly. Instead, (I think) you have to separate the font you’re working with into different files for various thickness and italic styles then combine them later via another method (Python seems to be popular).

Thankfully I found this [blog post by Richard Rutter](https://clagnut.com/blog/2418/) that details exactly what I needed to do with a single Python command.

### Step 1: Install the Dependancies

```
pip3 install fonttools brotli
```

fontTools is a library for manipulating fonts, that can work with TrueType, OpenType, AFM and to an extent Type 1 and some Mac-specific formats. If I ever wanted to work with fonts more often I have a feeling I'd be using it a bunch.

Brotli is a lot more interesting to me. It's a general purpose lossless compression algorithm that uses some fancy stuff I'm pretty sure an actual CS person would recognize. It provides better compression ratios than Gzip and deflate speeds are comparable. However, brotli compressing is slower which isn't an issue for web stuff (which only focuses on decompression), but I suspect is why it isn't used often in Linux/server settings (which require both efficient compression / decompression). It was initially developed for the WOFF2 font standard, but was so efficient that it was also adopted into HTTP providing improvements for all web data transfers! It even [won an Emmy](https://www.w3.org/news/2022/w3c-to-receive-emmy-award-for-standardizing-font-technology/) somehow!

### Step 2: Run the Command

```
pyftsubset FontName.ttf --unicodes="U+0000-007F" --layout-features='*' --flavor="woff2" --output-file="FontName.woff2"
```

`unicodes` specifies what [Unicode blocks](https://en.m.wikipedia.org/wiki/Unicode_block#List_of_blocks) should be included in the file you’re generating. Since I only ever write in English and don’t use wacky characters on my site, I chose to limit myself to only the ”Basic Latin” block (`U+0020-007`). 

`layout-features` specifies what OpenType layout features to include. If I’m being honest this is something I don’t know anything about. If subsetting a variable font isn’t enough to reduce your filesize, I would suggest looking into modifying this argument.

Something I found out the hard way was that this command will throw an [error if you use one dash (-)](https://github.com/fonttools/fonttools/issues/2900) versus two dashes (--) for the CLI arguments. Richard Rutter has only one dash in the example on his post, so that’s something to be aware of.

## Check For Italics

While testing the results of subsetting a font I accidentally discovered something amazing. Despite only having one variable font file, not only were all the font-weights being rendered correctly but so were italics! This was shocking since in the zip file from Google Fonts there were two separate files, one with and the other supposedly without italics. As it turns out, this particular variable font has support for italics baked into one file (not all support this feature). This singular feature halved the amount of data I had to transfer!

## The Results

To be frank, I was flabbergasted when I saw the results of all this. I went from two 95kb files to a single 19.2kb file!!! Logically this makes sense since I’m removing the vast majority of the content within this file. However, when I worked with regular WOFF2 font files in the past, 20KB was roughly the same size as one of those files that were locked to one font thickness and italic type! For the same size, I'm getting wayyyyyy more now. I firmly believe that as many sites as possible should be using variable fonts not just for the features they allow but the savings in bandwidth they can come with.

If anything I am excited for the future of web fonts. Color fonts seem to be the next big thing (within Google Font’s filter options they’re placed right next to variable fonts) and I’ve seen [some great demos]([https://nabla.typearture.com](https://nabla.typearture.com/)) of them. However, the current variety of them in 2024 is somewhat lacking and [Safari still has yet to support them](https://caniuse.com/colr-v1) (I fully expect Apple to take over a year to do so). 

Hopefully the next decade will have plenty of more great stuff in store for fonts on the web!
