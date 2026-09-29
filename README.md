# Image and Video Tagging and Processing Using Bash Command Line Tools

Author: Michael Dear 
 
Created: May 2026  
Updated: 2026-07-10

## About

This project uses Bash command-line tools - *ExifTool*, *ImageMagick*, *ffmpeg* - to label and process JPEG photographic images and video files.
The imgfuncs.sh file contains *Bash* functions for renaming files using metadata, writing 
keywords and titles to metadata, rotating and resizing images, and converting videos to *.mp4* to enable compression and metadata tagging. The functions have been developed using Bash on Ubuntu Linux (WSL). 

## Functions

The Functions Summary Table lists the functions and their purpose. Calling a function without parameters will print the function's usage.


| Name | Purpose |
|------|---------|
| img_rename | Rename images using image metadata. Output format *(camera model)-yyyymmdd_hhmmss_(sequence number).jpg* . A sequential number will be added to the end of filename collisions. |
| img_group | Copies jpeg images from the input directory into subdirectories of the output directory grouped by create date and a user-provided time interval in minutes e.g. 2026-05-05_17/30min/ |
| img_desc | Writes a title and keywords to all jpeg images in the input directory. |
| img_cp | Copy all jpeg images from the input directory to the ouput directory. |
| img_rm | Delete all jpeg images and empty directories recursively from the input directory.|
| img_gps_cp | Copy GPS latitude, longitude - both in decimal degrees - and altitude (metres) from a reference image to all jpeg images in the input directory. |
| img_exif_to_csv | Extract Title, Keywords, and GPS-related tags from images in a given directory recursively and write to CSV.  |
| img_exif_from_csv | Import Title, Keywords, and GPS-related tags from a CSV into images in a given directory.  |
| img_dt_shift | Shift the datetime tags and set the timezone of a directory of images recursively. |
| img_resize | Resizes all jpeg images in the input directory to a given pixel width or percentage of original size. Writes resized images to the output directory. |
| img_rotate | Rotates all jpeg images in the input directory n degrees clockwise. Writes rotated images to the output directory. |
| img_tint | Adds a tint to all jpeg images in the input directory. Writes tinted images to the output directory.|
| vid_conv | Convert a video to .mp4 format and copy metadata tags from a tagged reference image. |
| vid_batch_conv | Same as vid_conv, but takes a directory of video files as input. |

: Functions Summary Table  


## Tools

| Tool | Use |
|------|---------|
| [Git Bash (5.2.26(1)-release x86_64-pc-msys)](https://git-scm.com/) | Shell: executing the functions in imgfuncs.sh; copying and deleting files  |
| [ExifTool (13.45)](https://exiftool.org/)  | Accessing image metadata: reading, writing, and file renaming. |
| [ImageMagick (7.1.2-17 Q16-HDRI x64)](https://imagemagick.org/) | Image manipulation: resizing and rotating. |
| [ffmpeg 8.0.1-3ubuntu2](https://www.ffmpeg.org/) |

: Tools Summary Table


## Workflow 

Although the functions can be used independently, they are best used as a part of an media processing workflow. My typical workflow follows the steps in the Media Processing Workflow table.

| Step | Command |
|------|---------|
| Load `imgfuncs.sh` | `source imgfuncs.sh` (assuming `imgfuncs.sh` is in the current directory) |
| Make temporary directories | `mkdir photos photos/original` |
| Change to the `photos` directory | `cd photos` |
| Camera dump into `original` directory | Drag-and-drop or your preferred method |
| Manual review - delete unwanted images | File manager or photo organiser GUI |
| Rename images | `img_rename original output/renamed` |
| Group images | `img_group output/renamed output/grouped` |
| Manual review, then write title and keywords | `img_desc output/grouped/date_hour/mins "Image title" "kwd1; kwd2; kwd3"` |
| Copy to image archive | `img_cp output/grouped archive_dir` |
| Process videos using tagged reference images | `vid_conv vid.avi ref_img.jpg 18`  |
| Clean up | `img_rm output` |
| Copy processed videos to video archive | This is currently a manual process. A vid_cp function to be added in a future version. | 

: Media Processing Workflow

Additional steps to be completed as required:

* adjust image date/time and timezone
* rotate images
* resize images
* copy GPS information from a reference image to non-GPS images
* extract metadata from a directory of images to csv for import into a GIS
* copy metadata into images from a csv
* tint images