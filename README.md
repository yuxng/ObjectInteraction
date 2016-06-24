# ObjectInteraction
Object Detection by 3D Aspectlets and Occlusion Reasoning

Created by Yu Xiang at CVGL at Stanford University.

### Introduction

We propose a novel framework for detecting multiple objects from a single image and reasoning about occlusions between objects. We address this problem from a 3D perspective in order to handle various occlusion patterns which can take place between objects. We introduce the concept of “3D aspectlets” based on a piecewise planar object representation. A 3D aspectlet represents a portion of the object
which provides evidence for partial observation of the object. A new probabilistic model (which we called spatial layout model) is proposed to combine the bottom-up evidence from 3D aspectlets and the top-down occlusion reasoning to help object detection. Experiments are conducted on two new challenging datasets with various degrees of occlusions to demonstrate that, by contextualizing objects in their 3D geometric configuration with respect to the observer, our method is able to obtain competitive detection results even in the presence of severe occlusions. Moreover, we demonstrate the ability of the model to estimate the locations of objects in 3D and predict the occlusion order between objects in images.

### License

ObjectInteraction is released under the MIT License (refer to the LICENSE file for details).

### Citing

If you find ObjectInteraction useful in your research, please consider citing:

    @incollection{xiang2013object,
        author = {Xiang, Yu and Savarese, Silvio},
        title = {Object detection by 3d aspectlets and occlusion reasoning},
        booktitle = {IEEE International Conference on Computer Vision Workshops (ICCVW)},
        pages = {530--537},
        year = {2013}
    }
