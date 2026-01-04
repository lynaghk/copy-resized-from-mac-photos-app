# Imagetron

I vibe-coded this app so I could copy images out of MacOS Photos.app and have them be automatically resized to 1600px and optimized so I can put them on my blog.

<!-- see /demo.mp4 -->
<https://github.com/user-attachments/assets/14f6b354-6d3d-4ea2-81a9-a3b54a497c26>

This is trickier than expected, since when you press ⌘C Photos.app only puts a 1024 pixel-wide "preview image" onto the pasteboard rather than the full image data or a path to the original file.
Claude extracts the UUID embedded in the preview image filename to retrieve the full image data via PhotoKit, then resizes this and passes to `jpegoptim`.


## Install

    sudo port install jpegoptim # or sudo brew install jpegoptim
    ./build.sh

There are no settings. If you want to change the resize width or compression settings, edit the source and recompile.

This app works for me on:

- a 2020 M1 Air laptop, MacOS 14.8.3
- a 2024 M4 Mac Mini, MacOS 15.7.3

## Alternatives

[Clop](https://lowtechguys.com/clop/), has a lot of resizing, compression, and file-format options. I couldn't figure out how to get an automatic bulk workflow to work, which is why I vibed this app.
