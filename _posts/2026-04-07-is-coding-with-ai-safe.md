---
layout: post
title: Is Coding with AI Safe?
permalink: /posts/:year/:month/:slug
tags:
  - coding
  - ai
---

## The Question You Asked

Dear M,

Recently you asked me the question of "Is it safe to code with AI?". Initially I was going to give a brief but detailed answer, but I got a bit out of hand. Thus, I'm going to provide you with two formats. A short answer and a long answer.

## The Short Answer

If you know what you’re doing, yes.

## The Long Answer

I have the feeling you've been looking at "Claude Code", the "Agentic Coding" app that Anthropic made that is the most popular in the world for this category of software. Coding with AI is really popular right now and something I've been doing heavily for over a year now. Around 2-3 years ago the best AI could manage was act as a fancy coding auto complete. That's all changed now as they've become smart enough to handle coding entire projects/apps from scratch with the user not needing to type a single line of code, all they have to do is converse normally with the AI via a chatbox. Using AI in this manner even has a name: "vibe coding".

In my case, I've been vibe coding almost all of my work with Cyberknight and by my rough estimate almost 90%+ of Cyberknight code is AI generated while having a speed up of 2x compared to me just hand writing it! Not to mention (as much as it pains me to admit it) AI is better than I am at certain work and can generate results better than I can! To be clear, this is in areas that aren't my specialty (I hate making webpages with forms) but even in things I am well versed in it demonstrates remarkable knowledge and skill.

The big advantage AI has in coding is that code can either run properly or not. If there's a bug or error, the AI can catch it and fix it. What vibe coding looks like is that you'll tell AI to code something, it'll run it, check for errors (known as debugging), fix them, run again, and report back if all is well. This loop is what enables AI to be code things in a safe manner. With regards to Cyberknight, I spent nearly a month working on getting the tools for Claude to debug things properly, and while it took longer than I would have liked the ability for AI to autonomously edit code is both impressive and well worth the effort.

Now that said, I have noticed core deficiencies with modern AIs for coding. My main concern is that they are bad at architecting (designing things for the long term) and left unchecked, they will generate code that over the course of a year or two would result in an unmaintainable and a near impossible to edit project. In my case, I have the knowledge to know exactly what changes I want AI to make so as to keep my codebases small and maintainable. For someone who doesn't know how to code properly I fear that for larger and more complex projects, they would struggle.

Additionally I've noticed the "style" of the webpages they make isn't to my liking. To be clear, from a purely practical standpoint they succeed in conveying the information and serving the forms that they were designed for. Where they will fail is in the subjective part of their task, the "feeling" that they are meant to convey. I get the feeling that the next couple of years in AI research is going to be driven in this area of "taste" and tasks that don't have a boolean true/false outcome. 

## Local AI Is the Future

On a more personal note, something I've been doing recently instead is downloading AI models onto my laptop (which I must thank you for again!) and running them locally. I was planning on writing a post on that soon either way so I'll text you a link once I post it.

As your wallet recalls, I have a MacBook with 36GB of RAM which limits the size of the AI models I can run to roughly 30GB (I need a bit of breathing room for my operating system and the other apps I have open). Currently I've settled on using Qwen 3.5 (or to be more exact: qwen3.5-35b-a3b) which barely squeezes in that limit. By comparison, Claude Sonnet (the version of Claude you probably use the most) is estimated to be around 300 Billion parameters (it's not exact, but this is roughly 300GB).

That said, the risk is much bigger with these smaller models. Because they inherently contain less information they are "less smart" and more prone to making mistakes. For instance, I'll ask it to perform a task and while it might do well at first, eventually it'll make an obvious mistake or just stop randomly for no reason. Despite these issues, I am of the opinion that the Qwen model I can now run on my laptop is far smarter and faster than even GPT-4 from just a couple of years ago! While I do not trust using local AIs run on my laptop to handle key parts of Cyberknight's code, I do trust it enough to handle basic webpages or my personal projects such as this website you're on right now.

Local AI is something I am increasingly interested in especially since I have growing concerns around the management, unrealistic revenue expectations, potential liquidity issues, political concerns and rising costs associated with using Claude/GPT/Gemini and other major AIs run in the cloud. At this time, I don't believe these issues are enough for me to stop relying on these services, but I do foresee stormy clouds on the horizon...

To counter all that, I personally believe that within a decade (possibly it may take as many as 15 years though), AI models and the means to run them will become commoditized for the most part. For the vast bulk of AI tasks your layman performs, phones and laptops will be able to process them locally for free, offline, and at a comparable speed to current models. For more advanced tasks like coding, people will have two options. Either stick to cheaper on device models (like I've been experimenting with) or pay for more capable AI models running in the cloud. The difference compared to now is that in the future the gap between what is possible locally vs in the cloud will be far smaller compared to today.
