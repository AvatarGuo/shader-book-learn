# shader-book-learn 总结篇
引擎最近开发了两年左右了，准备系统的过一遍，先把shader入门精要在过一遍，记录下过程笔记。

</br> 
#概括笔记  </br>  
##  第四章（数学公式推导）
<br/>
一些推导细节可以看下games101的几节视频讲的比较透彻 。 

法线利用约束求变换，还有mul() 可以利用矩阵的左乘或者又乘 减少一次主动的矩阵转置。  
mul（UNITY_MATRIX_MVP,X））是又乘的，因为unity内置的矩阵都是按照**列**方式存储的 p90 (p*v*m)*x  
  
<br/>
课后有几个问题比较有意思  
 a. 在一个圆弧范围内判断两点关系。  如点 A,B 构成向量AB -> B减去A,获得向量，求模，判断在没在圆形范围内，根据向量点乘法，获得arcos 值，反推角度。   
 b. 判断一个点在三角形内还是三角形外:    
     简单方法 ABC 按照这个顺序和对应点P求cross ，符号一致即在三角形内部，不一致三角形外部。  
     games101也有一个简化方法 重心法
c.三角形重心坐标，即模型的三个顶点覆盖的那个像素，通过重心坐标求平均值。    
 
 <br/>
## 第五章(基础shader篇)
<br/>
subshader 类似 direct X 中的 techniques 一样，在多pass种找到最合适的那一个。  
### 1 subshader 和 pass 不区分大小写，但是为了规范还是写成SubShader 和 Pass  
测试发现SV_POSITION 和 SV_Target 大小写也不影响。  
### 2.pass 写几个就会执行几次，如之前错误的在一个pass后面又写了一个pass，导致材质球最后是白的。

![alt text](https://github.com/AvatarGuo/shader-book-learn/blob/main/pictures/chapter5-1.png)
 Fallback 紧跟着SubShader后面    


### 3.如果定义v2f的话，vert shader 不用加一个SV_POSITION语义了，DX10新出的（因为函数返回值是个v2f自定义的数据结构，而该数据结构内部已定义好语义）
<br/>
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
<br/>
vs shading 也叫Gouraud shading .(高洛德着色)
ps shading 也将Phong shading. 
<br/>
### 5.切线空间（顶点自带一个tangent 属性，利用tangent 切线和法线垂直约束推导法线变换矩阵）。  
a. **法线变换矩阵** 法线也是在模型空间的，不能和模型一样的变换矩阵，否则不垂直。（但是切线tangent可以，因为切线本质就是顶点的属性，切线可以用和顶点一样的矩阵做变换,可以利用切线变换后和法线垂直的特性来算出法线变换矩阵）   
http://candycat1992.github.io/unity_shaders_book/unity_shaders_book_chapter_4.pdf  55-p93

法线变换矩阵推导原理为 **向量点乘可以换成两个矩阵的乘法,第一个向量转置成一个矩阵**，然后按照约束条件，<br/>
大概可参考这个 **https://zhuanlan.zhihu.com/p/86442304**


### 6.调试部分和平台差异。
  a. 假色彩图像，每个值都除以2（具体的写法是x 0.5)然后在加0.5 就把值限制在了0-1之间了。**（这里可以认为 appdata传到vs里面的值都被限制到了0-1之间了，这样就都约束都限制在0-1了）**  
  b. opengl 和directX 一个左下角（0,0）一个右上角（0,0），unity 有个宏可以区分 UNITY_UV_AT_TOP 宏区分开 ，如果渲染到屏幕上： unity自身会做处理。
    渲染到rendertexture上，单张贴图：graphic.blit 无需考虑。   
    **多张贴图需要考虑这个问题**（mrt技术，即可以渲染多张贴图的技术）   

  c. **tex2d函数采样**。**directx9/11** 只能在ps中用，不能在vs用，如果vs确实想采样图片，可以使用tex2dlod函数代替，需要开启#pragma target3.0 编译选项才可以  **p116**。  
  d. 慎用if 等语句，gpu的设计情况有关系，GI book 讲的也比较清晰。




## 第六章（基础光照）

#### 1. 经验模型（不考虑brdf）：
    color = ambient + diffuse + specular + emission (自发光) ，最简单的光照公式，各向同性。
 但是通过什么保证这几个数相加小于等于1的呢 ？(当前还没有证明)

 

#### 2. Tags标记(即Unity中引擎处理forward渲染管线的一些思想): 
    a.LightMode, 前向渲染有两个，ForwardBase 和 ForwardAdd。 两个标记分别unity的一个优化，ForwardBase 只有最亮的第一个光源ps执行，其他 VS/SH 球谐函数计算，然后在执行ForwardAdd的pass。
    
    本质思想：减少 m*n的减少复杂度 （光源是m,物体是n）
      1.引擎层收集所有Tag标记为 ForwardBase/ForwardAdd的 Object.形成两个std::vector<object>
      2.先拿出场景中最亮的那1个灯光，然后和ForwardBase的那个std::vector<object>做一次循环即
      3.在拿剩下的最多n个光源 和ForwardAdd的std::vector<object> 做第二个循环,然后结果相加。 

    其实优化思想和defferd shading 差不多一样（高斯模糊N*N  变成水平N+竖直N）下面 参考链接
   
    
#### 3.cg中的 reflect(input,normal)函数
    约定方向是以 -_WorldSpaceLightPos0.xyz ，从光源方向看向原点的方向计算的。 原理为（都转化到了世界空间，所以可以看成在坐标原点的计算）
    （简单来说，得到入射光线的负方向，然后矢量加法做个推导得出）
    
    更多的时候光照specular用了blinn-phong思想（即 normallize(viewDir + lightDir)）

#### 4. specular 计算 viewDir(之前看书没实践忽略的一个地方)
    worldViewDir =_WorldSpaceCameraPos.xyz - i.vertexWord (对于vs/ps来说，各个处理单位有自己独立的一个视角方向 顶点的方向到相机的方向) 。这个之前忽略的一点。
### 当前的光照模型简单概括下：

#### Color = ambient + diffuse + specular 
    其中：
        a. ambient  环境光，直接取最亮的环境光即可，unity中的为 UNITY_LIGHTMODEL_AMBIENT.xyz
        b. diffuse  漫反射项目（和观察角度无关，各向同性）:
            b.1 通用的lambert 光照模型：  lightColor * _Diffuse.xyz * saturate( dot(normal , lightViewDir));
                和视角无关，注意的是 需要 saturate(dot) 或者max(0,dot) 注意负角度。
            
            b.2 value公司的half-lambert模型（cs的那个模型）
            diffuse = （ lightColor * _Diffuse.xyz ）* （0.5 * dot(normal,lightViewDir) + 0.5) 
        
        c. specular 高光项（视角有关、两种模型）
            c.1 phong 光照模型（利用reflect函数计算反射角，需要考虑负角度问题）
                反射方向：reflectDir = reflect( -lightDir , normal)
                视角方向：specular = lightColor * _Specular.xyz * pow ( max( 0 , dot( viewDir , reflectionDir )) , _Gloss )
            
            c.2 blinn-phong 光照模型：简化了反射方向(不需要计算反射了)
                半程向量 ：half = normalize( viewDir + lightDir )
                最终高光：specular = lightColor * _Specular.xyz * pow(max(0, dot( half, normal )) , _Gloss )

#### 5.一个重要的数学变换：法线变换矩阵
worldNormal = normalize( mul( v.normal , unity_WorldToObject)); 

即顶点法线需要乘以：objectToWorld的逆转矩阵（这里有一个技巧，就是mul 交换位置，可以省下来一次矩阵转置（简单的矩阵乘法特性））

法线变换矩阵的推导利用了和tangent的正交性质进行的推导：（参考3、4）
![alt text](https://github.com/AvatarGuo/shader-book-learn/blob/main/pictures/6-1.png)

### 参考链接
1.延迟渲染本质减少m*n 和 shader复杂度的
  
[http://download.nvidia.com/developer/presentations/2004/6800_Leagues/6800_Leagues_Deferred_Shading.pdf](http://download.nvidia.com/developer/presentations/2004/6800_Leagues/6800_Leagues_Deferred_Shading.pdf)

2reflect 函数: 负方向三角函数相加

[https://zhuanlan.zhihu.com/p/152561125](https://zhuanlan.zhihu.com/p/152561125)

3.法线变换矩阵的推导：利用和tangent的约束推导

http://candycat1992.github.io/unity_shaders_book/unity_shaders_book_chapter_4.pdf ： 55 P93

https://zhuanlan.zhihu.com/p/86442304



## 第七章：基础纹理（abedo,normal,ramp,mask）

#### 1 纹理坐标(左上角还是右上角是(0,0)的那个)
    
    a.除了屏幕空间区分，MRT外 ，普通的贴图也要考虑这个概念。
    unity使用纹理坐标是openGL的传统保持一致，即左下角为（0，0）点。

#### 2 图片的采样格式(unity中的贴图格式)
    a. point: 最邻近点采样，各种情况下只取最近的那一个元素。（像素风游戏等。
    b. Bilinear ：四点插值
    c. Triliner ：考虑了Mipmap，若贴图不开启mipmap 则两者几乎相同。

![alt text](https://github.com/AvatarGuo/shader-book-learn/blob/main/pictures/7-1.png)![alt text](https://github.com/AvatarGuo/shader-book-learn/blob/main/pictures/7-2.png)

#### 3.图片的tilling和scale (TRANSFORM_TEX 多图片可以看情况共用一个XXX_ST,节省寄存器）
    a.问 同样的512x512贴图，为什么有的可以拉伸，有的必须要repeat模式呢？
    
        设置XXX_ST 在shader里面。
        每个properties 定义的贴图，在inspect界面都会有_ST，但是可以共用一个，减少寄存器使用。
         
        很简答的思想：因为uv计算好之后乘以 XXX_ST.xy + XXX_ST.zw 本质就是把小的放大了，设置图片格式后才有对应的超边界情况。
![alt text](https://github.com/AvatarGuo/shader-book-learn/blob/main/pictures/7-3.png)
![alt text](https://github.com/AvatarGuo/shader-book-learn/blob/main/pictures/7-4.png)

#### 4. mipmap采样层数计算相关
（202中也讲过）

    1. 光栅化最小处理单元 ddx ddy 对应贴图采样。 获取。
    2. log2N 的方式求mipmap的指定层数， 如1.2 则在两层lerp 在线性求个lerp 即可计算出，

#### 4. 法线贴图，重点注意！！！
    0.  unity 给法线初始化有个特殊的优化 即 "bump" {} ，贴图导入也要选择NormalMap ，才可以使用UnpackNormal等函数
        如_BumpMap("normal map",2D) = "bump" {}


    1. 存储空间问题： 存储到了切线空间，更容易保存和压缩，如利用 sqrt(1-dot(xy,xy))反推出来z
    
    2. 压缩范围问题, 贴图存储范围是[0-1],发现范围是[-1,1]所以要做个 unpack操作
        即 xy*2 -1 做个unpack
        通过还有bumpScale, 
            tangentNoraml.xy = tangentMormal.xy * bumpScale;
            //所以在反推z轴
            tangentNoraml.z  = sqrt(1-dot(tangentNoraml.xy,tangentMormal.xy));

    （h42有个优化，去掉了顶点的副切线）

    法线的值存储到贴图上也要考虑这个问题：*0.5 + 0.5 转化到[0-1]范围
    https://answers.unity.com/questions/1698762/why-does-the-example-normal-shader-multiply-by-05.html

    3. normal 法线 转tangent space 还是world space的问题。子和父空间变换问题
        通常转tangentSpace计算，因为ps中可以直接采样normal,直接结算。
        否则的话 需要在ps中做一次矩阵转化 ，将tangentNoram 转化到世界空间上。

    4. defferd shading中 GBuffer的 简单的normal 压缩。
        Unity 中有一个DXT5nm的纹理格式，只用a通道和g通道，其他通道会被过滤掉的方式去对normal map 本身的四通道进行一个类似压缩。
        (在UnityCG的UnpackNormal() 函数中也可以看到展开方式)


![alt text](https://github.com/AvatarGuo/shader-book-learn/blob/main/pictures/7-5.png)


#### 5. ramp 贴图（做二次元常用的大块区域一个色块）
    本质就是按照某种规则生成UV,然后按照这个UV去采样ramp贴图。 
    x轴和y轴的值对应的贴图上的值都是一样的。

    这里手撸了个 half-lambert diffuse的，即 0.5 * dot(normal,lightDir) + 0.5 来限制到[0,1]范围内
    光线和法线夹角越小，值越大，使用ramp贴图越后面的值，从而过渡色块。


#### 6. mask贴图（多张贴图采样问题）

1.多张贴图采样

    可以根据需求，如normal /mask /abedo 共用一个uv的话（具体情况具体分析，即顶点携带几套贴图，按需用）
        只用 _MainTexture_ST ，在vert阶段算好一个uv
        ps 阶段 ，用相同的uv采样其他texture.(可以节省寄存器)
        （另外以 OpelGL 举例子的话，多个贴图，在bind的时候根据模型属性，比较灵活，不用想的那么死）


#### 7 重要的矩阵变换（子空间和父空间的坐标轴变换）
(核心多读几遍这个 4.6.2)
http://candycat1992.github.io/unity_shaders_book/unity_shaders_book_chapter_4.pdf  (4.6.2  p73) 

    理解之后比较简单的一个推导是(包括顶点动画，之前项目的横版特效功能)：
    1.  所有坐标轴都是相对于父物体的。 如x轴 = (1,0,0) 是在世界坐标轴下的，所有坐标轴都是嵌套的（骨骼动画树，比较明显）

    2.  比如 世界坐标转tangent 坐标 （等于tangent 转世界的逆矩阵）只考虑x,y,z的话。
        
        求出x轴，y轴，z轴 在世界空间的表示( tangent,binormal ,normal) 
        (切线，副切线，法线顺序不能变，因为有cross,还要考虑tangent.w)
        
        worldNormal = UnityObjectToWorldNormal(v.normal);
        worldTangent  = UnityObjectToWorldDir(v.tangent.xyz);    
        worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w; 

        切线转世界空间的三个坐标轴都已经有了
        （所以切线转世界，等于三个坐标轴按照列展开）
        （世界转切线等于其逆矩阵，等于三个坐标轴按行展开）

        tangentToWorldMatrix =  fixed3x3 ( worldTangent.x , worldBinormal.x , worldNormal.x,
                                          worldTangent.y , worldBinormal.y , worldNormal.y,
                                          worldTangent.z , worldBinormal.z . worldNormal.z)
                                          
        worldToTangent = fixed3x3(  worldTangent ,
                                    worldBinormal,
                                    worldNormal )

    3 另外unity中可以定义宏去写通用代码，如 TANGENT_SPACE_ROTATION 

![alt text](https://github.com/AvatarGuo/shader-book-learn/blob/main/pictures/7-6.png)
![alt text](https://github.com/AvatarGuo/shader-book-learn/blob/main/pictures/7-7.png) 

