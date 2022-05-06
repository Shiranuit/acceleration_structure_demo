# acceleration_structure_demo
Basic demo of an acceleration structure used for rendering thousands of entities

This Demo shows the impact of acceleration structures for rendering / updating large amount of entities.

Up to 10 000 000 of rectangles are drawn inside the camera view.

The naïve method is testing for each rectangle if the rectangle is inside the camera view before drawing it to the screen

The other method is using a basic quad tree as an acceleration structure which helps reducing the number of tests done on each rectagles per frames

## Requirements
This demo is meant to be executed with [Love2d](https://love2d.org/) a Lua game framework

## Controls

- Move by dragging the mouse with the left click
- Zoom using the scroll wheel
- Press B to switch activate / deactivate the usage of acceleration structure
