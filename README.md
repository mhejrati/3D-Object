## 3D Object Detection and Reconstruction

This is the code for the method described in:

[Analyzing 3D Objects in Cluttered Images, M. Hejrati, D. Ramanan.](http://www.ics.uci.edu/~shejrati/files/car.pdf)

Neural Info. Proc. Systems (NIPS), Lake Tahoe, NV, Dec 2012.

This library is written in Matlab, and is based on the following two works:
* [Articluated Pose Estimation with Flexible Mixtures of Parts](http://www.ics.uci.edu/~dramanan/software/pose/)
* [Learning Non-Rigid 3D Shape from 2D Motion] (http://movement.stanford.edu/learning-nr-shape/)


---- 

## Quick start guide

This code is tested on Linux. Also pre-compiled Mex files for Linux is inlcuded.

### Prerequsite: Install PASCAL VOC 2011 trainval and development kit
``` sh
$ mkdir ~/data/VOC/VOC2011/
$ cd ~/data/VOC/VOC2011/
$ wget http://pascallin.ecs.soton.ac.uk/challenges/VOC/voc2011/VOCtrainval_25-May-2011.tar
$ wget http://pascallin.ecs.soton.ac.uk/challenges/VOC/voc2011/VOCdevkit_25-May-2011.tar
$ tar xf VOCtrainval_25-May-2011.tar
$ tar xf VOCdevkit_25-May-2011.tar
$ mv TrainVal/VOCdevkit/VOC2011 VOCdevkit
``` 
You can also get the VOC PASCAL 2011 dataset from [HERE](http://pascallin.ecs.soton.ac.uk/challenges/VOC/voc2011).


### Download and compile
``` sh
$ cd ~/
$ git clone git://github.com/mhejrati/3D-Object.git
$ cd ~/3D-Object/
$ matlab
>> compile
```

### Run detection demo using pre-trained model
``` sh
$ cd ~/3D-Object/
$ matlab
>> demo_detection
```

### Run full demo inlcuding learning, testing and evaluation
``` sh
$ cd ~/3D-Object/
$ matlab
>> demo_full
```



----

### Issues, Questions, Congratulations, etc

Please report issues here on the github page or contact "shejrati @ ics.uci.edu"

--- -
**Copyright (C) 2013 Mohsen Hejrati, Deva Ramanan**

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

