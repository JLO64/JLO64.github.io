---
layout: post
title: Stealing From Websites
permalink: /posts/:year/:month/:slug
tags:
  - webdev
  - html
  - css
  - javascript
description: True, I did yoink some lines of code for this. Worth it though!
---

The term "steal" has a bunch of negative connotations, but I feel that taking HTML/CSS/JS from other's websites be viewed as a bad thing. Personally, I would feel more than pleased to learn that someone decided to steal code from my site for their own use! However, instead of just copying other's websites, I've decided to showcase where I've been sourcing stuff from. That way, people looking to copy my code can compare against its origin.

In order to better illustrate what I will be talking about, I have included CodePen samples. Feel free to directly copy what I've typed up!

## [Underlined Links(Chris Coyier)](https://chriscoyier.net/)

Out of all the RSS feeds I read, I probably click on Chris Coyier's posts the most. He has a great mix of random tech stuff, things going on in his life, and new things in the webdev world. So it only makes sense that his website would have have stuff worth copying from!

Immediately, when you first visit his website you notice that a bunch of links are underlined with a gold color. That’s neat, but when you hover over them with your cursor the line changes color! 

<p class="codepen" data-height="300" data-theme-id="dark" data-default-tab="css,result" data-slug-hash="eYxqWdb" data-user="JLO64" style="height: 300px; box-sizing: border-box; display: flex; align-items: center; justify-content: center; border: 2px solid; margin: 1em 0; padding: 1em;">
  <span>See the Pen <a href="https://codepen.io/JLO64/pen/eYxqWdb">
  Underline Links Hover</a> by Julian Lopez (<a href="https://codepen.io/JLO64">@JLO64</a>)
  on <a href="https://codepen.io">CodePen</a>.</span>
</p>
<script async src="https://cpwebassets.codepen.io/assets/embed/ei.js"></script>

This is a small thing, but it adds such a layer of interactivity to websites and I'm surprised it's not more common.

## [Text Glowing(Robin Rendle)](https://robinrendle.com/)

This site has three themes: Light, Dark, and Communist (seriously lol). Under the Communist theme the title text flickers. My first assumption was that the title text was a gif on loop. However, the text could be highlighted meaning that this wasn't the case. Instead, there was an animation being applied to that element and all it was doing was changing the `text-shadow` property.

<p class="codepen" data-height="300" data-theme-id="dark" data-default-tab="css,result" data-slug-hash="KKJOmQG" data-user="JLO64" style="height: 300px; box-sizing: border-box; display: flex; align-items: center; justify-content: center; border: 2px solid; margin: 1em 0; padding: 1em;">
  <span>See the Pen <a href="https://codepen.io/JLO64/pen/KKJOmQG">
  Untitled</a> by Julian Lopez (<a href="https://codepen.io/JLO64">@JLO64</a>)
  on <a href="https://codepen.io">CodePen</a>.</span>
</p>
<script async src="https://cpwebassets.codepen.io/assets/embed/ei.js"></script>

Unfortunately this effect doesn't work that well on a white background. Still, I think it's a neat effect to add to my links.

## [Random Posts(512kb Club)](https://512kb.club/)

So for the longest time I've been meaning to add a way to read a random post. Initially I thought I couldn't add a way to do this on a static site. I had thoughts about using an external service to do this, like having an AWS Lambda function that had an array containing links to all the posts on my site and returning one of them at random. Then I came across the implementation of this site.

<p class="codepen" data-height="300" data-theme-id="dark" data-default-tab="js,result" data-slug-hash="oNmKVBW" data-user="JLO64" style="height: 300px; box-sizing: border-box; display: flex; align-items: center; justify-content: center; border: 2px solid; margin: 1em 0; padding: 1em;">
  <span>See the Pen <a href="https://codepen.io/JLO64/pen/oNmKVBW">
  Random &lt;a&gt; Link</a> by Julian Lopez (<a href="https://codepen.io/JLO64">@JLO64</a>)
  on <a href="https://codepen.io">CodePen</a>.</span>
</p>
<script async src="https://cpwebassets.codepen.io/assets/embed/ei.js"></script>

I’m going to be honest. I was kinda pissed off when I saw this solution working with minimal effort and code. I was prepared to go all out and try to use cloud solutions for this. Seeing this work made me feel stupid!

## [Email link(Garrit Franke)](https://garrit.xyz/)

At the bottom of all posts on this website I noticed there was a link to "Reply via E-Mail". Clicking on it created a draft email in my personal inbox on the web. I thought that there would be a bunch of complicated JavaScript behind this, but it was just one line of HTML!

```
<a href="mailto:admin@example.net?subject=Re: An Example Subject">Email Link</a>
```

Out of all the things I've shown off here, this is the one that is the simplest, yet adds the most functionality to my site. I don't really like the idea of adding comments to my site since I know that they will be something that is hardly ever used and that I can not control effectively. Besides, I'd have to rely on a third party service [like I did on my old site](2023-12-9-Bringing-My-Old-Website-Back-From-The-Dead.md) which I'd rather not do for my blog. This eliminates those concerns by using a simple tool that we all have.

## Website Icons(YouTube)
Typically in the description of their videos YouTubers put links to their social media. To the left of these links, icons representing the sites they point towards have been added. From a user perspective, these are great since they help show where you are being sent to.

<p class="codepen" data-height="300" data-theme-id="dark" data-default-tab="css,result" data-slug-hash="YzBmgxY" data-user="JLO64" style="height: 300px; box-sizing: border-box; display: flex; align-items: center; justify-content: center; border: 2px solid; margin: 1em 0; padding: 1em;">
  <span>See the Pen <a href="https://codepen.io/JLO64/pen/YzBmgxY">
  Untitled</a> by Julian Lopez (<a href="https://codepen.io/JLO64">@JLO64</a>)
  on <a href="https://codepen.io">CodePen</a>.</span>
</p>
<script async src="https://cpwebassets.codepen.io/assets/embed/ei.js"></script>

 While the method YouTube and I use are different, the results are the same. Before looking into this, I had no clue that you could edit what comes before a link or any element with just CSS. You can even use this to add a mail icon to the email links I highlighted above!

That said, this is a manual process so not all of the external links on my site have an icon. I've thought about automating this but then I would lose control over the exact Favicon and color being used for links. 

## Using This Code Effectively

Individually, these are all neat effects and tricks but when combined well they result in something worth being proud of. There is no single thing on my site that I can point to and say "this makes my website look good". It's the combination of a bunch of little details that makes anything in life look good. As such, I have to thank the people who took the time to make their websites look pretty which made mine better as well.