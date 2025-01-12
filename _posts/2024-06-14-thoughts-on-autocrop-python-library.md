---
layout: post
title: Thoughts On Autocrop Python Library
permalink: /posts/:year/:month/:slug
tags:
  - python
# description: While using Autocrop for my service does have some issues, it is the best option I currently have. 
---

[Autocrop](https://github.com/leblancfg/autocrop) is a python library that automatically crops faces in images. this is exactly what I want for profile photos, since I want there to be consistency among all the photos uploaded and publicly displayed. Performing this locally in the container is more than doable, however I am slightly concerned about the performance impact this could have. On my MacBook it is nearly instantaneous, but I suspect on production hardware it will take more than five seconds. During these five seconds all other functions and customers using can experience extreme performance degradation.  When a new group of customers joins this service and uploads a bunch of photos all at once, this could cause serious issues. Thus, running it on separate hardware is best. 

That said, I have noticed some issues with the quality of facial detection. Hats and glasses seem to be an issue, and only faces in profile work. Still, given the context of "professional" photos that are expected to be uploaded this shouldn't be a problem. If anything, I can sell this as a feature that check for professional photos. From almost day one, implementing a solution like this has been an objective of mine. However, if the facial recognition becomes too poor/problematic, I can just switch this function to just perform a crop on the center and covert the result to WEBP.

The biggest issue I ran into was the lack of support Autocrop has for HEIF/HEIC. These file formats are what Apple devices natively use to store photos in. Converting these files to a PNG format is complicated by the fact that you can not write files directly to the filesystem on an Azure Function (you can write to Tempfiles tho). I decided to stop working on converting these images since it was too time consuming and I'm 70% certain that iPhones upload/share images as a JPEG.

Additionally, the last release/commit for this library was 2 years ago. For now it seems to be working perfectly fine with the latest version of Python (not so for pyScss, another library I'm using but have issues with) so I feel confident using it for the foreseeable future. In the event something happens though, it should be easy-ish to switch to a similar facial recognition library.