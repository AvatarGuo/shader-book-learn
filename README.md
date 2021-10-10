# shader-book-learn
graph learn 

汇总笔记

## 第五章
subshader 类似 direct X 中的techniques 一样，在多pass种找到最合适的那一个。

1 subshader 和 pass 不区分大小写，但是为了规范还是写成SubShader 和 Pass
测试发现SV_POSITION 和 SV_Target 大小写也不影响。
2. pass 写几个就会执行几次，如之前错误的在一个pass后面又写了一个pass，导致材质球最后是白的。
![images](https://github.com/AvatarGuo/shader-book-learn/blob/main/pictures/chapter5-1.png）


3.如果定义v2f的话，vert shader 不用加一个SV_POSITION语义了，DX10新出的（可以考虑输出的是一个v2f 自定义的数据结构，而自定义的数据结构内部已经定义好了语义）
https://stackoverflow.com/questions/58543318/invalid-output-semantic-sv-position-legal-indices-are-in-0-0


反之下面这种则需要加上SV_POSITION的语义



####
4 .关于vs中的顶点变换相关。（ndc变换那一坨，除以那个w的操作）
在vs中只进行mvp变化，变换后仍是线性空间。（因为vs中需要保持线性空间，而vs和ps桥梁是光栅化，光栅化会把vs中算出的值平均到ps中，所以vs要保持线性数值。）

在ps中处于w 变换到ndc 即[-1,1]范围内
一般不在vs中进行ndc变换，(只做mvp变换，在写引擎的时候需要考虑这个问题)
1 .因为z轴变换后是非线性的了。
 2 .vs算出来的值 会平均给到vs，一个非线性的平均会出问题
 入门精要p92页

5.计算副切线方法。
a. 法线也是在模型空间的，不能和模型一样的变换矩阵，否则不垂直。（但是切线可以，因为切线本质就是顶点的属性，切线可以用和顶点一样的矩阵做变换）
