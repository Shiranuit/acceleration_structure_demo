# acceleration_structure_demo
Basic demo of an acceleration structure used for rendering thousands of entities

This Demo shows the impact of acceleration structures for rendering / updating large amount of entities.

Up to 10 000 000 rectangles are drawn inside the camera view.

The naïve method is testing for each rectangle if the rectangle is inside the camera view before drawing it to the screen

The other method is using a basic quad tree as an acceleration structure which helps reducing the number of tests done on each rectagles per frames

## Requirements

This demo is meant to be executed with [Love2d](https://love2d.org/) a Lua game framework

## Controls

- Move by dragging the mouse with the left click
- Zoom using the scroll wheel or the up and down arrows
- Press F to switch activate / deactivate the usage of acceleration structure
- Press B to switch show / hide the regions boundaries of the acceleration structure

## Note

If the demo is not starting and crashes with a memory error, you may want to reduce the total number of rectangles in the code

![image](https://user-images.githubusercontent.com/19224148/167372028-1ea01830-18de-4f1e-ae36-cb4a3e6b2b63.png)
