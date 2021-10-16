# shader-book-learn
引擎最近开发了两年左右了，准备系统的过一遍，先把shader入门精要在过一遍，记录下过程笔记。


概括笔记  
##  第四章（数学公式推导）
一些推导细节可以看下games101的几节视频讲的比较透彻 。 

法线利用约束求变换，还有mul() 可以利用矩阵的左乘或者又乘 减少一次主动的矩阵转置。  
mul（UNITY_MATRIX_MVP,X））是又乘的，因为unity内置的矩阵都是按照**列**方式存储的 p90 (p*v*m)*x  
  

课后有几个问题比较有意思  
 a. 在一个圆弧范围内判断两点关系。  如点 A,B 构成向量AB -> B减去A,获得向量，求模，判断在没在圆形范围内，根据向量点乘法，获得arcos 值，反推角度。   
 b. 判断一个点在三角形内还是三角形外:    
     简单方法 ABC 按照这个顺序和对应点P求cross ，符号一致即在三角形内部，不一致三角形外部。  
     games101也有一个简化方法 重心法
c.三角形重心坐标，即模型的三个顶点覆盖的那个像素，通过重心坐标求平均值。    
 
 
## 第五章(基础shader篇)
subshader 类似 direct X 中的 techniques 一样，在多pass种找到最合适的那一个。  
### 1 subshader 和 pass 不区分大小写，但是为了规范还是写成SubShader 和 Pass  
测试发现SV_POSITION 和 SV_Target 大小写也不影响。  
### 2.pass 写几个就会执行几次，如之前错误的在一个pass后面又写了一个pass，导致材质球最后是白的。

![alt text](https://github.com/AvatarGuo/shader-book-learn/blob/main/pictures/chapter5-1.png)
 Fallback 紧跟着SubShader后面    


### 3.如果定义v2f的话，vert shader 不用加一个SV_POSITION语义了，DX10新出的（因为函数返回值是个v2f自定义的数据结构，而该数据结构内部已定义好语义）

https://stackoverflow.com/questions/58543318/invalid-output-semantic-sv-position-legal-indices-are-in-0-0

![alt text](https://github.com/AvatarGuo/shader-book-learn/blob/main/pictures/chapter5-3.png)

反之下面这种则需要加上SV_POSITION的语义  

![alt text](https://github.com/AvatarGuo/shader-book-learn/blob/main/pictures/chapter5-3-2.png)


--

### 4 vs和ps中的一些数值计算，需要注意ps的数值是平均数值。（ndc变换那一坨，除以那个w的操作）  
在vs中只进行mvp变化，变换后仍是线性空间。（因为vs中需要保持线性空间，vs和ps的桥梁是光栅化，光栅化会把vs中算出的值平均到ps中，所以vs要保持线性数值）  
在ps中才进行ndc变换，即除以 w分量  才会变换到[-1,1]范围内 （dirextX z的范围为[0,1]）
**vs 和 ps 的一个不同就是，vs中所有数值都在线性空间里面，而ps里面如果要确保各个值都是线性的，需要慎重进行归一化  **  

一般不在vs中进行ndc变换，(只做mvp变换，在写引擎的时候可以考虑下这个问题)  
1 .因为z轴变换后是非线性的了。  
2 .vs算出来的值 会平均给到vs，都归一化之后的平均会有问题。 
 **纸质书第一版p92页**  http://candycat1992.github.io/unity_shaders_book/unity_shaders_book_chapter_4.pdf 61-p99

vs shading 也叫ground shading 
ps shading 也将phong shading. 

### 5.切线空间（顶点自带一个tangent 属性，利用tangent 切线和法线垂直约束推导法线变换矩阵）。  
a. **法线变换矩阵** 法线也是在模型空间的，不能和模型一样的变换矩阵，否则不垂直。（但是切线tangent可以，因为切线本质就是顶点的属性，切线可以用和顶点一样的矩阵做变换,可以利用切线变换后和法线垂直的特性来算出法线变换矩阵）   
http://candycat1992.github.io/unity_shaders_book/unity_shaders_book_chapter_4.pdf  55-p93

法线变换矩阵推导原理为 **向量点乘可以换成两个矩阵的乘法,第一个向量转置成一个矩阵**，然后按照约束条件，大概可参考这个 **https://zhuanlan.zhihu.com/p/86442304**


### 6.调试部分和平台差异。
a. 假色彩图像，每个值都除以2（具体的写法是x 0.5)然后在加0.5 就把值限制在了0-1之间了。**（这里可以认为 appdata传到vs里面的值都被限制到了0-1之间了，这样就都约束都限制在0-1了）**  
b. opengl 和directX 一个左下角（0,0）一个右上角（0,0），unity 有个宏可以区分 UNITY_UV_AT_TOP 宏区分开  
c. **tex2d函数采样**。**directx9/11** 只能在ps中用，不能在vs用，如果vs确实想采样图片，可以使用tex2dlod函数代替，需要开启#pragma target3.0 编译选项才可以 p116 ,
d. 慎用if 等语句，gpu的设计情况有关系，GIbook 讲的也比较清晰。

