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



## 第八章: 透明效果（渲染顺序，混合，Cull、ZWrite） 

**本质是和Framebuffer中已经渲染的值做个混合**

#### 1.两个概念：
a. **透明度测试** ：即 clip 函数 ，透明度小于某个阈值直接干掉该片元像素

b. **透明度混合**：半透效果 Blend, ZWrite 命令和已经在FrameBuffer中颜色做混合



#### 2. 渲染思想：（即利用渲染顺序，先渲染，后混合）
先渲染不透明物体（结果存储到framebuffer中），后渲染半透物体，通过Blend 命令和之前的渲染结果做混合。（ZWrite 根据实际场景需要选择打开或关闭，如42半透在水里的效果）


    a. unity中有个Queue的Tag ,可设置物体的渲染顺序 (索引越小越早被提前渲染)
    b. 不透明物体渲染顺序不重要，因为会有early-z等各种优化，弊端是overdraw 都9012年了，不透明物体可以不考虑顺序
    c. Queue Alphatest 、Transparent 

https://docs.unity3d.com/ScriptReference/Rendering.RenderQueue.html

![alt text](https://github.com/AvatarGuo/shader-book-learn/blob/main/pictures/8-0.png)



#### 有个问题，水体半透渲染的问题 。（水上水下的问题）
![alt text](https://github.com/AvatarGuo/shader-book-learn/blob/main/pictures/8-1.png)
![alt text](https://github.com/AvatarGuo/shader-book-learn/blob/main/pictures/8-2.png)


#### 3.  半透明物体自身的遮挡相关。（本书第一次双pass实践，即第一个pass写深度 ColorMask 过滤掉其他，第二个pass 正常渲染）

**单Pass** ,alpha混合的结果
![alt text](https://github.com/AvatarGuo/shader-book-learn/blob/main/pictures/8-3.png)

**双pass**。开启了深度写入效果。（注意的是：第一个pass写了深度，模型自身的透明效果看不到了）
![alt text](https://github.com/AvatarGuo/shader-book-learn/blob/main/pictures/8-4.png)

    ZWrite On
    ColorMask 0


![alt text](https://github.com/AvatarGuo/shader-book-learn/blob/main/pictures/8-5.png)


#### 4. 混合命令（正片叠底，线性减淡，就是PhotoShop里面的图层混合）
    0. 混合命令
        SrcXXX 指的是当前的颜色
        Dxx 指的是当前Framebuffer中已经有的颜色。

    1.  在Unity中只使用Blend命令就行（除了Blend off 外）. 
        openGL中 要使用glEnable(GL_BLEND)来开启混合。

    2.  混合是逐片元的操作。不可编程。高度可配置，
        （正片叠底等ps的乱七八糟的效果）
        
        常用的 如：
            Blend SrcAplha OneMinusSrcAlpha
            Blend One One 

#### 5.Cull 在透明度相关的注意
默认是会Cull Back的。不透明物体需要看情况 Cull off

    1.透明度测试，要想显示clip 后的pixel ，要设置Cull off
    2.透明度混合，如果要显示模型后面的，可以双pass ，
        pass 1 : Cull Front 
        pass 2:  Cull Back 

![alt text](https://github.com/AvatarGuo/shader-book-learn/blob/main/pictures/8-6.png)
![alt text](https://github.com/AvatarGuo/shader-book-learn/blob/main/pictures/8-7.png)


![alt text](https://github.com/AvatarGuo/shader-book-learn/blob/main/pictures/8-8.png)




## 第九章：光照（Forward , defferd 的处理 ）

Forward 光源的优化思想  Blend 双Pass ,LUT 衰减




#####  渲染路径（LightMode）
1.三种渲染路径：


    前向渲染路径(Forward Rendering)
    延迟渲染路径：defferd rendering：新旧两种，目前主要是新的。
    顶点照明(vertex rendering path)：已废弃。

前向渲染，延迟渲染：

言简意赅 一个PPT 就懂了 ，本质是写引擎底层的思想 

（本质降低复杂度的m*n 的骚操作）
http://download.nvidia.com/developer/presentations/2004/6800_Leagues/6800_Leagues_Deferred_Shading.pdf

defferd shading的缺点（也可以通过其他方法规避掉）
    
    a. 不支持真正意义上的AA(AA 本质是先模糊后采样，模糊即平均（求卷积) 多个点求平均即为模糊）
    b. 半透明物体
    c. MRT必须支持。


#### 2 Forward Rendering:

    a. 多种LightMode ForwardBase、ForwardAdd  (Defferd、ShadowCaster)
    b.三种处理光照方法：逐顶点处理、逐像素处理、球谐函数（SH）处理。
        1. Light的property 的Render Mode 的 important 属性
        按照规则选择对应处理方式
 	    not important 会逐顶点或者SH处理。

        2. ForwardBase 只会在中最重要的那一个“ 平行光 ” 逐像素处理，
                    剩下的4个逐顶点处理，剩下的其他按照SH处理。 
        （有个QualitySetting 中可以设置逐像素光源的数量）
        
        3.ForwardAdd会把剩下的import 光源按照逐偏片元去计算

大概总结如下图：

http://candycat1992.github.io/unity_shaders_book/unity_shaders_book_images.html

![alt text](https://github.com/AvatarGuo/shader-book-learn/blob/main/pictures/9-1.png)


#### 注意：
    1. 编译指令可以优化正确效果（实验证明）：例如光照衰减系数(也被坑过)
    #pragma multi_compile_fwdbase  
    #pragma multi_compile_fwdadd

    2. bass pass 左边是支持一些光照特性， 例如 BasePase 可以访问光照纹理（LightMap）
      （add pass 也可以通过统一衰减计算光照衰减和shadow 衰减）

    3. 阴影，base pass 平行光默认支持阴影，additional 需要更多的宏才能打开阴影。!
        就是那个#pragma multi_compile_fwadd_fullshadows

    4. 环境光 自发光都在base计算(add pass 本质是叠加混合)。

    5. add pass 本质是混合，所以开启Blend ，一般使用Blend One One


#### 3.Unity中的延迟渲染

新旧两种，旧版本只是不支持PBR相关计算。

    双Pass,第一个渲染Gbuffer,第二个光照计算。
    RT 有多种格式，RT0,RT1,RT2,RT3（normal 可以按照之前弥赛亚的方法压缩 R8G8A8 存储x,y，反推Z值）
    可访问的变量 _LightColor,_LightMatrix0 (采样cookie 和光照衰减纹理（_LightTexture0）)

#### 4.  Unity中代码的实践。(本书的第二次双pass实践)
1.ForwardBase Pass : 

    环境光 ambient + 漫反射 diffuse + 高光 specular + 自发光
    base pass中 处理场景最重要的平行光，且一定是平行光。
    （如果没有平行光base pass中全黑光源处理）
    所以base pass 都可以按照平行光的属性去计算，如衰减，_LightColor0 ，_WorldSpaceLightPos0

![alt text](https://github.com/AvatarGuo/shader-book-learn/blob/main/pictures/9-2.png)

（如果没有平行光base pass中全黑光源处理，如下图，关了平行光源打开了点光源）

![alt text](https://github.com/AvatarGuo/shader-book-learn/blob/main/pictures/9-2-1.png)

2. add pass ,去掉环境光,自发光的计算:

        a. 颜色仍然可以使用_LightColor0
        b.衰减 使用了LUT表,减少开根号，如games202的球形衰减
        (有个宏区分是平行光源，还是非平行光源：USING_DIRECTIONAL_lIGHT)

        具体计算方法：
        //先计算出来改wordpos在光照贴图上的uv
        fixed3 lightCoordUV = mul(unity_WorldToLight , fixed4( i.worldPos ,1.0)) 
        //光照贴图是Ramp 贴图，进行采样去计算衰减系数 atten 

        注意点乘是一个数字，所以下面用了 (dot (xx)).rr ，即取值两次。
        fixed atten = tex2D( _LightTexture0 ,dot(lightCoord,lightCoord).rr).UNITY_ATTEN_CHANNEL;

在FrameBuffer中的调试：

多个光源按照重要度做排序了， 重要度是距离+远近 +衰减强度共同决定的。

![alt text](https://github.com/AvatarGuo/shader-book-learn/blob/main/pictures/9-3.png)


3. 注意的是： unity中的光照衰减。(离开光照范围内会发生突变，因为底层不会执行additional pass )
    
        a. 查找表的衰减，纹理贴图本身的大小格式会影响效率。_LightTexture0 
        有利有弊，快速， Look up table (LUT)

        若对光源使用cookie则使用： _LightTextureB0 
         (如下图，SPOT中计算衰减系数中有用到_LightTextureB0 )
          （另外也要注意下spot 和point 光源的处理）

![alt text](https://github.com/AvatarGuo/shader-book-learn/blob/main/pictures/9-4.png)


##  第九章：光照第二部分（ shadow ）

两种shadow 方法： 传统的lightmap + Screen Space Shadow Map (MRT 延迟渲染的一种技术)

#### 1. Unity中的阴影原理。 

    1.games201中讲的双pass ，(即传统的阴影方法)。(本质都是对比z值)
        第一个pass ，把物体顶点信息变换到光源空间中， 输出到texture中。
            x,y分量采样，得到深度信息，两者比较
        第二个pass ，从摄像机角度出发，每一个点，和上面一样的变换矩阵A
        然后在shadowMap上采样，对比z值。
        （一些描述还要撸一遍）

    2.unity中简单的shadow map 技术，即摄像机放到光源的位置，看不到的地方就是阴影
        a.前置条件（Light 要开启阴影）
        （soft shadow (pcf类似，Bias偏移，vssm 等概率sdf阴影),hard shadow ）
        
        b. ShadowCaster pass :
        额外的一类光照Pass : LightMode = ShadowCaster 的 pass，目标不是Frambuffer ，而是ZBuffer（更新深度值）
        
        传统光栅化本质就是渲染两个buffer (FrameBuffer + ZBuffer） 
        (可以用ForwardBase,ForwardAdd去做z深度计算,为了性能只用计算深度即可，Unity单独用了 ShadowCaster 的pass)
        (即引擎底层获取所有object的 ShadowCaster pass 去计算)

    3. Unity5中更新的 ShadowMap:Screen Shadow Map (本质延迟渲染产物，需要MRT设备支持)
        （设置LightMode= "ShadowCaster"后）
        1.  两个纹理，光源处的深度纹理 +  摄像机的深度纹理
        2. 采样贴图的两个点比较Z值，Z值小的才能被光源看到 ，即没在阴影里面.
        3.如果想要在物体上显示阴影，需要在shader里面对阴影贴图进行采样处理。

    引擎底层本质：如果一个 Light 开启阴影的话，
    摄像机放在该Light的位置，遍历范围内的物体，
    找到shader (FallBack)中LightMode = ShadowCaster的 模型，执行一次pass ，
    输出到一个ZBuffer 贴图里。


#### 2 阴影的代码实践（投射阴影、接收阴影）

1.物体投射阴影（引擎收集ShadowCater的pass）
    
    a. Mesh 中的CastShadow + Receive Shadow  
    需要shader中有 ShadowCaster的Pass （ 或者 FallBack的“VertexLit” ）

    mesh 中投影有个two sided 双面投影属性。

2.物体接收阴影（ shader中的计算）（源码都在AutoLight.cginc） 

    a. v2f寄存器中定义 ： SHADOW_COORDS(X) 
        下一个可用寄存器的值！！ ,如上一个是TEXCOORD2 ,X 需要取3 

    b. vertex shadow 中的计算
        TRANSFER_SHADOW(o)

    c. ps 中采样LUT 采样衰减 
    SHADOW_ATTENUATION()

注意：1 . v2f 中不能用vertex 关键字,否则会有下面的trace!，而且SV_POSITION 的名字一定要是pos

![alt text](https://github.com/AvatarGuo/shader-book-learn/blob/main/pictures/9-5.png)

![alt text](https://github.com/AvatarGuo/shader-book-learn/blob/main/pictures/9-6.png)
![alt text](https://github.com/AvatarGuo/shader-book-learn/blob/main/pictures/9-7.png)


渲染分析，四个部分，先更新深度 ，然后绘制。


![alt text](https://github.com/AvatarGuo/shader-book-learn/blob/main/pictures/9-8.png)




#### 问unity的两种阴影技术，怎么在 Frame Debug上看呢？
待更

3.  可以统一管理阴影和光照衰减。（源码也在AutoLight.cginc里面）

        1. bass pass ,add pass 可以使用一样的光照计算和阴影计算代码了
        (前面的SHADOW_COORDS 和 TRANSFER_SHADOW 定义和计算不变，只是计算衰减统一了)
        UNITY_LIGHT_ATTENUATION （）函数统一计算，在base pass，和addition pass 光照计算代码可以统一。

        2. 唯一的不同，需要将
        #pragma multi_compile_fwdadd 替换成 
        #pragma multi_compile_fwdadd_fullshadows
        （前面光照那一个图片实际也显示了）


#### 3. 透明度物体的阴影处理
分为两种情况：

1.透明度测试的情况。 核心（clip函数）
    
    a.需要合适的Fallback Fallback = "Transparent/Cutoff/VertexLit"才可以
    b. Properties ： 需要增加一个_Cutoff 属性，才可以被正确的 Fallback 
    c.正确的#pragma，否则会看不到部分效果！  #pragma multi_compile_fwdadd 、 #pragma multi_compile_fwbase 、 #pragma multi_compile_fwdadd_fullshadows


    如果#pragma 不正常就会有问题。(坑了几十分钟)

![alt text](https://github.com/AvatarGuo/shader-book-learn/blob/main/pictures/9-9.png)
![alt text](https://github.com/AvatarGuo/shader-book-learn/blob/main/pictures/9-10.png)


2. 透明度混合（ 实际用 dirty trick 的方法去处理的。）
(对透明度混合来说，底层没计算阴影，所以需要用工程方法去做)

        1 显示阴影，
        Queue 不能设置成Transparent 否则显示不出来阴影(也是坑了几十分钟)
        (冯乐乐的方法是shader 里面TransParent 但是在场景里设置了Alphatest)

![alt text](https://github.com/AvatarGuo/shader-book-learn/blob/main/pictures/9-11.png)
![alt text](https://github.com/AvatarGuo/shader-book-learn/blob/main/pictures/9-12.png)
![alt text](https://github.com/AvatarGuo/shader-book-learn/blob/main/pictures/9-13.png)
![alt text](https://github.com/AvatarGuo/shader-book-learn/blob/main/pictures/9-14.png)


2 投射阴影：

    Transparent/VertexLit 不行
    可以Fallback  VertexLit 设置。

写shader的话统一光照和阴影的衰减方便一些 ，定义和计算都一样，只是ps里面换了个更统一的函数。


