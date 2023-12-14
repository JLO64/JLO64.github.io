---
layout: post
title: Bringing My Old Website Back From The Dead
permalink: /posts/:year/:month/:slug
tags:
  - webdev
  - jekyll
  - blogging
  - AWS
---

## My Assignment

At the start of this year I took a Japanese class as is required of all majors at USC Dornsife (don't ask what grade I got). A big part of this class was a blogging project where students had to create and comment on posts in Japanese. The instructions had us use Blogger, but this wasn't appealing to me. The interface was bad, posts looked terrible, the blogs looked bland, and there was not enough customization for me. So I decided to search for an alternative.

I didn't want to rent a server since I wanted to spend as little cash as possible on this (I'm a broke college student) which immediately ruled out running a [WordPress site](https://wordpress.com). If I had my current home server back then (this was months before I built it) I probably would have looked this more, but then I found out about static websites. 

Prior to looking into this, I thought all websites required a server to run 24/7 in order to serve files and process user queries. This is kinda half true. Website information can be precompiled and stored on a publicly accessible file system without the need for any computational resources. Sites that are made this way are called "Static Websites". Since I wasn't doing anything fancy I decided to go with this opinion which still left me with many choices for where to store these files. To my surprise, you can actually configure an [AWS S3 bucket](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html) to host a website which was great since I had used this service plenty of times before.

{% include blog_image.html url="https://ik.imagekit.io/jlo64/www_julianlopez_net/2023-12-9-Bringing-My-Old-Website-Back-From-The-Dead/_aws-static-settings_mh5-44oep.png" caption="This page is within the settings of an S3 bucket." alt="A screenshot of AWS S3 static website hosting settings." %}

To actually create and generate this blog I decided to go with [Jekyll](https://jekyllrb.com/) which is probably one of the most popular and thus best documented options out there. Plus, there are a bunch of free to use themes to customize the way your site looks. I went with [windows-95](https://github.com/h01000110/windows-95) which has a retro look that I like and works surprisingly well on mobile!

{% include blog_image.html url="https://ik.imagekit.io/jlo64/www_julianlopez_net/2023-12-9-Bringing-My-Old-Website-Back-From-The-Dead/_mobile-website_Oo7ad8a0Z.jpeg" caption="Here's how it looks on my phone." alt="A screenshot taken from an iPhone of a website with a Windows 95 theme." %}

All I needed to do to add a post was to create a markdown file in the `_posts` directory, build the site by running the command `bundle exec jekyll build` in the root directory of the website, then sync said directory to my S3 bucket. Just with that [I had something good enough for my class](http://julian-lopez-usc-jpn3-blog.s3.us-west-2.amazonaws.com/index.html)!

{% include blog_image.html url="https://ik.imagekit.io/jlo64/www_julianlopez_net/2023-12-9-Bringing-My-Old-Website-Back-From-The-Dead/_old_website_UhH4agVL2.png" caption="I like the way my current blog looks, but I have to admit this looks awesome." alt="A screenshot of a website with a Windows 95 theme." %}

## Commenting Was Required

However, the assignment didn't involve just writing and posting blogs. We were required to write comments on other's posts which was fun since it forced us to read each other's blogs. However, there was a catch. According to the rubric, users had to be able to submit comments without creating or signing in to an account. While this seems relatively simple, most embeddable comment services require users to login to something (typically a Google/Facebook account) as an anti spam measure. I initially used [CommentBox](https://commentbox.io) (which worked great) but they require an account login. I had to switch to [Cusdis](https://cusdis.com/#pricing) which surprisingly fit well with my site theme. Both of these options are free up to a certain point (100+ comments per month) which is great since my site got nowhere near that limit

{% include blog_image.html url="https://ik.imagekit.io/jlo64/www_julianlopez_net/2023-12-9-Bringing-My-Old-Website-Back-From-The-Dead/_comments_iR7CiP3wO.png" caption="It kinda looks as if it is a part of the theme." alt="A screenshot of Cusdis comments." %}

I'm still not fully content with having to rely on a 3rd party service like this (especially one that I doubt will exist for years to come) but it's something I can't really bother myself to change. I doubt I'll ever make any effort to save these comments, buttttttttt who knows.

## Switching To GitHub

Now this is the part where I admit that the title is clickbait. The original website I made for this assignment is still live and reachable on S3. However, it's not exactly up to my current standards. For one, the url is just terrible ([https://julian-lopez-usc-jpn3-blog.s3.us-west-2.amazonaws.com/index.html](https://julian-lopez-usc-jpn3-blog.s3.us-west-2.amazonaws.com/index.html)). I have since purchased a domain (julianlopez.net) and have been using that for a bunch of other sites I have ([as I outlined in this blog post](2023-11-20-setting-up-my-domain)). Switching the domain of this website to that is a no brainer. Additionally, HTTPS is something that I believe all websites should have for security reasons. However, I didn't know about it back then and didn't set it up for that site. 

Both of these issues can be fixed on an S3 hosted website, but the process isn't exactly easy. While S3 is great for just file storage, it's not exactly something made with websites in mind. What they have in place is only good for just the bare minimum of static website hosting.

By chance, I found out (no joke, I got it from the URL of a [manga fan page](https://hiatus-hiatus.github.io)) that GitHub has a service called [GitHub Pages](https://pages.github.com) to host static websites. It is wayyyyy better than using an S3 bucket, automatically provides HTTPS, has support for custom domains, and has version history through Git. Ever since I The only issue with it is that the source files have to be on a GitHub repository, which are public unless you pony up the $4/month for a GitHub Pro subscription. I'm fine with the [source files of my blog being public](https://github.com/JLO64/JLO64.github.io), but I'd rather not have others snoop around the source files of my other sites.

{% include blog_image.html url="https://ik.imagekit.io/jlo64/www_julianlopez_net/2023-12-9-Bringing-My-Old-Website-Back-From-The-Dead/_github-pages_38keHiWpd.png" caption="These are my GitHub Pages settings for this blog." alt="A screenshot of the GitHub Pages settings for a website." %}

(As it turns out, Netlify also supports auto HTTPS, custom domains, and pushing files via Git. This is in addition to being easier to work with for hosting multiple websites and not requiring a subscription to hide source files. This has made me seriously consider switching to them for hosting my all my websites.)

## How Special This Site Is To Me

I know it doesn't seem this way, by far this is the most important website I have (and perhaps will) **ever** make. This might seem like an exaggeration, but it's not. Making this site got me get into web development as a hobby, and it was thanks to this that I met someone very special who changed my life forever. Plus who knows, this might even become a bit of a career for me!