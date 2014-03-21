dinoSparseRing data set -- 16 views sampled on a ring

The object is an untextured, matte, ceramic dinosaur against a black background.
Note that the object is partially outside the field of view in some images.  Also, there are some dark shadows on the object--be conservative if using thresholding to detect background pixels.

The (tight) bounding box for the dino model is
(-0.061897 -0.018874 -0.057845)
(0.010897 0.068227 0.015495)

--------------------------
Created by Steve Seitz, James Diebel, Daniel Scharstein, Brian Curless, and Rick Szeliski

This directory contains images with camera calibration parameters.

The images were captured using the Stanford spherical light field gantry, and calibrated by the above people.

*.png:  images in png format
*_par.txt:  camera parameters.  There is one line for each image.  The format for each line is:
	"imgname.png k11 k12 k13 k21 k22 k23 k31 k32 k33 r11 r12 r13 r21 r22 r23 r31 r32 r33 t1 t2 t3"
	The projection matrix for that image is given by K*[R t]
	The image origin is top-left, with x increasing horizontally, y vertically
*_ang.txt:  latitude, longitude angles for each image.  Not needed to compute scene->image mapping, but may be helpful for visualization.  
*_good_silhouette_images.txt: list of images that we could process to get good silhouettes.

Note that (lat, lon) corresponds to the same image as (-lat, 180 + lon), rotated 180 degrees in the image plane.  While it would therefore be sufficient in principle to capture only positive latitude images, in practice some images are not useable because of shadows where the gantry occludes the light source.  Because the gantry is in a different configuration for positive vs. negative latitude images, this gives us two chances to capture each viewpoint without shadows.  It is for this reason that some images may have positive and others negative latitudes.  This also explains why some images may appear to be "upside-down" (in fact they're rotated 180 degrees).

Some multiview stereo algorithms start from the visual hull after extracting per-image silhouettes.  In our own experiments, we had success computing conservative visual hulls using the *_good_silhouette_images.txt images.  To extract silhouettes from these images, we

  1. thresholded at 0.19 (where color values range from 0 to 1),
  2. dilated by 10 pixels
  3. eroded by 7 pixels

All of these operations are straightforward in Matlab.  You are free to use this recipe.

